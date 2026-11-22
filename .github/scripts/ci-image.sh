#!/usr/bin/env bash
# Sourced by workflow steps. Package metadata distinguishes absence from API failure;
# a registry pull failure is never converted into a request to rebuild.

ci_image_digest() {
    docker image inspect --format '{{range .RepoDigests}}{{println .}}{{end}}' "$1" |
        awk -v prefix="${1%:*}@" 'index($0, prefix) == 1 && !digest { digest = $0 } END { if (!digest) exit 1; print digest }'
}

select_ci_image() {
    local recipe_hash image tag package_api package_status status needs_build=false selected
    recipe_hash=$(sha256sum Dockerfile | cut -d ' ' -f 1) || return "$?"
    image="ghcr.io/${GITHUB_REPOSITORY_OWNER,,}/silam-ci"
    tag="$image:dockerfile-$recipe_hash-linux-amd64"
    package_api="users/$GITHUB_REPOSITORY_OWNER/packages/container/silam-ci"
    selected=$tag
    if gh api --include "$package_api" > "$RUNNER_TEMP/silam-package-response.txt" 2> "$RUNNER_TEMP/silam-package-error.txt"; then
        gh api --paginate "$package_api/versions?state=active&per_page=100" \
            --jq '.[].metadata.container.tags[]?' > "$RUNNER_TEMP/silam-package-tags.txt" || return "$?"
        if grep -Fxq "${tag##*:}" "$RUNNER_TEMP/silam-package-tags.txt"; then
            docker pull --platform linux/amd64 "$tag" || return "$?"
            selected=$(ci_image_digest "$tag") || return "$?"
            printf 'Reusing qualified environment %s; image build skipped\n' "$selected"
        else
            status=$?
            if (( status != 1 )); then return "$status"; fi
            needs_build=true
            printf 'Package exists, but Dockerfile/architecture tag is absent; building %s\n' "$tag"
        fi
    else
        status=$?
        package_status=$(awk '$1 ~ /^HTTP\// { code = $2 } END { print code }' "$RUNNER_TEMP/silam-package-response.txt")
        if [[ "$package_status" != 404 ]]; then
            cat "$RUNNER_TEMP/silam-package-error.txt" >&2
            return "$status"
        fi
        needs_build=true
        printf 'Package API confirmed HTTP 404; bootstrapping %s\n' "$tag"
    fi
    {
        printf 'SILAM_RECIPE_TAG=%s\nSILAM_RECIPE_SHA256=%s\n' "$tag" "$recipe_hash"
        printf 'SILAM_IMAGE=%s\nSILAM_IMAGE_BUILD=%s\n' "$selected" "$needs_build"
    } >> "$GITHUB_ENV"
    printf 'needs_build=%s\ntag=%s\n' "$needs_build" "$tag" >> "$GITHUB_OUTPUT"
}

record_ci_image() {
    local architecture recipe source image_id selected
    architecture=$(docker image inspect --format '{{.Os}}/{{.Architecture}}' "$SILAM_IMAGE") || return "$?"
    recipe=$(docker image inspect --format '{{index .Config.Labels "io.silam.dockerfile.sha256"}}' "$SILAM_IMAGE") || return "$?"
    source=$(docker image inspect --format '{{index .Config.Labels "org.opencontainers.image.source"}}' "$SILAM_IMAGE") || return "$?"
    image_id=$(docker image inspect --format '{{.Id}}' "$SILAM_IMAGE") || return "$?"
    if [[ "$architecture" != linux/amd64 || "$recipe" != "$SILAM_RECIPE_SHA256" || "$source" != "$GITHUB_SERVER_URL/$GITHUB_REPOSITORY" ]]; then
        printf 'Environment metadata mismatch: platform=%s recipe=%s source=%s\n' "$architecture" "$recipe" "$source" >&2
        return 1
    fi
    selected=$SILAM_IMAGE
    if [[ "$SILAM_IMAGE_BUILD" == true ]]; then selected=$image_id; fi
    printf 'SILAM_IMAGE=%s\nSILAM_TEST_IMAGE_ID=%s\n' "$selected" "$image_id" >> "$GITHUB_ENV"
    printf 'Selected immutable environment: %s; image_id=%s; built=%s\n' "$selected" "$image_id" "$SILAM_IMAGE_BUILD"
    {
        printf 'Environment recipe: `%s`\n\n' "$SILAM_RECIPE_TAG"
        printf 'Selected environment: `%s`\n\nBuilt in this run: `%s`\n' "$selected" "$SILAM_IMAGE_BUILD"
    } >> "$GITHUB_STEP_SUMMARY"
}

publish_ci_image() {
    local image_id published visibility
    image_id=$(docker image inspect --format '{{.Id}}' "$SILAM_RECIPE_TAG") || return "$?"
    if [[ "$image_id" != "$SILAM_TEST_IMAGE_ID" ]]; then
        printf 'Refusing to publish an environment different from the tested image\n' >&2
        return 1
    fi
    docker push "$SILAM_RECIPE_TAG" || return "$?"
    published=$(ci_image_digest "$SILAM_RECIPE_TAG") || return "$?"
    visibility=$(gh api "users/$GITHUB_REPOSITORY_OWNER/packages/container/silam-ci" --jq '.visibility') || return "$?"
    printf 'Published qualified environment: %s; package visibility=%s\n' "$published" "$visibility"
    printf 'Published environment: `%s`\n\nPackage visibility: `%s`\n' "$published" "$visibility" >> "$GITHUB_STEP_SUMMARY"
}
