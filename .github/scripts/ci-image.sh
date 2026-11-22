#!/usr/bin/env bash
# Sourced by the workflow to select the package for the checked-out Dockerfile.

select_ci_image() {
    local sha256 package image response body status needs_build
    sha256=$(sha256sum Dockerfile) || return "$?"
    package="silam-${sha256%% *}"
    image="ghcr.io/gtzjh/$package"

    if ! response=$(curl --disable --silent --show-error --max-time 30 \
        --header 'Accept: application/vnd.github+json' \
        --header "Authorization: Bearer $GH_TOKEN" \
        --header 'X-GitHub-Api-Version: 2022-11-28' \
        --write-out $'\n%{http_code}' \
        "$GITHUB_API_URL/users/gtzjh/packages/container/$package"); then
        printf 'GitHub Packages query failed for %s\n' "$image" >&2
        return 1
    fi
    status=${response##*$'\n'}
    body=${response%$'\n'*}

    case "$status" in
        200)
            if ! needs_build=$(jq -ers '
                select(length == 1) | .[0] | objects | .version_count | numbers
                | select(. >= 0 and floor == .) | (. == 0 | tostring)
            ' <<< "$body"); then
                printf 'Invalid GitHub Packages metadata for %s\n' "$image" >&2
                return 1
            fi
            ;;
        404)
            if ! jq -es 'length == 1 and (.[0] | objects | .message | strings | length > 0)' \
                <<< "$body" > /dev/null; then
                printf 'Invalid GitHub Packages HTTP 404 response for %s\n' "$image" >&2
                return 1
            fi
            needs_build=true
            ;;
        *)
            printf 'GitHub Packages returned HTTP %s for %s\n' "$status" "$image" >&2
            return 1
            ;;
    esac

    if [[ "$needs_build" == true ]]; then
        printf 'No published version of %s (HTTP %s); building and validating the environment.\n' "$image" "$status"
    else
        printf 'Image %s already exists; skipping the build and environment validation.\n' "$image"
    fi
    printf 'image=%s\nneeds_build=%s\n' "$image" "$needs_build" >> "$GITHUB_OUTPUT"
}
