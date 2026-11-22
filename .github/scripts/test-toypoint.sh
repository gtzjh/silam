#!/usr/bin/env bash
# Run inside the image built from this repository's Dockerfile:
#   bash .github/scripts/test-toypoint.sh <gnu|gnumpi> <repository> <results>
# Each invocation creates its own case and artifacts under <results>.

verify_run_log() {
    local mode=$1
    local run_log=$2
    local pattern='Serial version'
    if [[ "$mode" == gnumpi ]]; then
        pattern='MPI version running with[[:space:]]+2[[:space:]]+tasks'
    fi
    if ! grep -Eq "$pattern" "$run_log"; then
        printf 'Missing expected %s execution mode in %s\n' "$mode" "$run_log" >&2
        return 1
    fi
    if ! grep -Fq 'Finalising files after time loop' "$run_log"; then
        printf 'Missing normal time-loop completion in %s\n' "$run_log" >&2
        return 1
    fi
    if ! grep -Fq 'Final output after-step' "$run_log"; then
        printf 'Missing final output stage in %s\n' "$run_log" >&2
        return 1
    fi
    grep -E "$pattern" "$run_log"
    printf 'execution_mode=%s: PASS\nnormal_completion=PASS\n' "$mode"
}

verify_netcdf_file() {
    local output=$1
    local diagnostics=$2
    local status required_end file_size
    LC_ALL=C ncvalidator "$output" > "$diagnostics.validator.log" 2>&1 || {
        status=$?
        cat "$diagnostics.validator.log" >&2
        return "$status"
    }
    # ncvalidator can warn about truncation while returning zero; -q hides this warning.
    if grep -Eq 'file size \([0-9]+\) is less than expected \([0-9]+\)' "$diagnostics.validator.log"; then
        cat "$diagnostics.validator.log" >&2
        return 1
    fi
    LC_ALL=C ncoffsets -s -r "$output" > "$diagnostics.offsets.txt" 2>&1 || {
        status=$?
        cat "$diagnostics.offsets.txt" >&2
        return "$status"
    }
    grep -Eq '^// File format: CDF-[12]$' "$diagnostics.offsets.txt" || return "$?"
    # ncoffsets uses exclusive ends. Fixed variables include four-byte padding;
    # record ends must remain unrounded for the single-short/byte/char record case.
    required_end=$(awk '
        /^[[:space:]]*extent[[:space:]]*=/ { if ($3 > maximum) maximum = $3; seen = 1 }
        /^[[:space:]]*end[[:space:]]+file[[:space:]]+offset[[:space:]]*=/ {
            end = $5
            if ($0 !~ /record\)/) end = int((end + 3) / 4) * 4
            if (end > maximum) maximum = end
            seen = 1
        }
        END { if (!seen) exit 1; printf "%.0f\n", maximum }
    ' "$diagnostics.offsets.txt") || return "$?"
    file_size=$(stat -c '%s' "$output") || return "$?"
    if (( required_end > file_size )); then
        printf 'Truncated NetCDF data: %s, required_end=%s, file_size=%s\n' "$output" "$required_end" "$file_size" >&2
        return 1
    fi
    ncdump "$output" > /dev/null || return "$?"
}

verify_output() {
    local case_dir=$1
    local artifacts=$2
    local reference=$3
    local output="$case_dir/output/toypoint.nc"
    if [[ ! -s "$output" || -L "$output" ]]; then
        printf 'Missing or empty NetCDF output: %s\n' "$output" >&2
        return 1
    fi
    # Read all variables, not only the header, before checking the time axis.
    local netcdf_file index=0 status units values epoch origin first last
    local -a time_values
    find "$case_dir/output" -type f -name '*.nc' -print0 > "$artifacts/netcdf-files.list" || return "$?"
    while IFS= read -r -d '' netcdf_file; do
        index=$((index + 1))
        verify_netcdf_file "$netcdf_file" "$artifacts/netcdf-$index" || return "$?"
    done < "$artifacts/netcdf-files.list"
    ncdump -v time "$output" > "$artifacts/time.cdl" || return "$?"
    awk '
        /^[[:space:]]*time:units[[:space:]]*=/ {
            units = $0; sub(/^[^"]*"/, "", units); sub(/".*/, "", units); units_seen++
        }
        /^[[:space:]]*data:/ { in_data = 1; next }
        in_data && /^[[:space:]]*time[[:space:]]*=/ { reading = 1; sub(/^[^=]*=/, "") }
        reading {
            values = values $0
            if (index($0, ";")) {
                sub(/;.*/, "", values); gsub(/[[:space:]]/, "", values)
                reading = 0; values_seen++
            }
        }
        END {
            if (units_seen != 1 || values_seen != 1) exit 1
            print "units=" units; print "values=" values
        }
    ' "$artifacts/time.cdl" > "$artifacts/time.txt" || return "$?"
    if cmp -s "$reference" "$artifacts/time.txt"; then
        :
    else
        status=$?
        printf 'Time axis mismatch; observed:\n' >&2
        cat "$artifacts/time.txt" >&2
        return "$status"
    fi
    units=$(sed -n 's/^units=//p' "$artifacts/time.txt") || return "$?"
    values=$(sed -n 's/^values=//p' "$artifacts/time.txt") || return "$?"
    IFS=, read -r -a time_values <<< "$values" || return "$?"
    epoch=${units#seconds since }
    origin=$(date -u --date="$epoch" +%s) || return "$?"
    first=$(date -u --date="@$((origin + time_values[0]))" '+%Y-%m-%dT%H:%M:%S+00:00') || return "$?"
    last=$(date -u --date="@$((origin + time_values[${#time_values[@]} - 1]))" '+%Y-%m-%dT%H:%M:%S+00:00') || return "$?"
    printf 'netcdf_structure=PASS\nnetcdf_read=PASS\n'
    printf 'time_axis=PASS: %s records, units=%s, values=%s\n' "${#time_values[@]}" "$units" "$values"
    printf 'time_first=%s\ntime_last=%s\n' "$first" "$last"
}

finish() {
    local status=$1
    trap - EXIT
    set +e
    mkdir -p "$artifacts/model-logs"
    shopt -s nullglob
    local log_file
    for log_file in "$case_dir"/*.log "$case_dir"/output/*.log; do
        [[ -f "$log_file" && ! -L "$log_file" ]] || continue
        cp "$log_file" "$artifacts/model-logs/"
    done
    if (( status != 0 )) && [[ -d "$case_dir/output" ]]; then
        mkdir -p "$artifacts/output"
        (
            cd "$case_dir/output"
            find . -type f \( -name '*.nc' -o -name '*.log' -o -name '*.cdl' \) \
                -exec cp --parents -- '{}' "$artifacts/output/" \;
        )
        if [[ -f "$case_dir/output/toypoint.nc" && ! -L "$case_dir/output/toypoint.nc" ]]; then
            ncdump -v time "$case_dir/output/toypoint.nc" > "$artifacts/time.cdl" 2> "$artifacts/time-dump-error.log"
        fi
    fi
    {
        printf 'elapsed_seconds=%s\n' "$((SECONDS - started))"
        printf 'last_stage=%s\nexit_code=%s\n' "$stage" "$status"
        if (( status == 0 )); then
            printf 'result=PASS\n'
        elif (( status == 124 )); then
            printf 'result=FAIL: model exceeded the seven-minute runtime limit\n'
        else
            printf 'result=FAIL: %s exited with status %s\n' "$stage" "$status"
        fi
    } >> "$artifacts/summary.txt"
    cat "$artifacts/summary.txt"
    if (( status != 0 )); then
        case "$stage" in
            compile) tail -n 40 "$artifacts/build.log" >&2 ;;
            run) tail -n 40 "$artifacts/run.log" >&2 ;;
        esac
    fi
    exit "$status"
}

main() {
    set -euo pipefail
    umask 022
    mode=$1
    repo_root=$(cd "$2" && pwd)
    mkdir -p "$3"
    results_root=$(cd "$3" && pwd)
    run_dir=$(mktemp -d "$results_root/$mode.XXXXXX")
    # Docker runs as root; the runner's artifact action must be able to read results.
    chmod 0755 "$run_dir"
    artifacts="$run_dir/artifacts"
    case_dir="$run_dir/case"
    mkdir -p "$artifacts" "$case_dir"
    stage=prepare
    started=$SECONDS
    trap 'finish "$?"' EXIT
    export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1
    git config --global --add safe.directory "$repo_root"
    commit=$(git -C "$repo_root" rev-parse HEAD)
    {
        printf 'mode=%s\nrepository=%s\nresult_directory=%s\n' "$mode" "$repo_root" "$run_dir"
        printf 'commit=%s\n' "$commit"
        printf 'OMP_NUM_THREADS=%s\nOPENBLAS_NUM_THREADS=%s\n' "$OMP_NUM_THREADS" "$OPENBLAS_NUM_THREADS"
        printf 'model_timeout=7 minutes; TERM then KILL after 30 seconds\n'
        printf 'environment_image=%s\n' "${SILAM_ENVIRONMENT_IMAGE:-local Dockerfile image}"
        gfortran --version | sed -n '1p'
        sha256sum "$repo_root/Dockerfile"
    } > "$artifacts/summary.txt"

    stage=compile
    compile_started=$SECONDS
    printf 'Compiling %s; results: %s\n' "$mode" "$run_dir"
    make -C "$repo_root/build" SETUP="$mode" BRANCH=silam_ci RULES=full clean > "$artifacts/build.log" 2>&1
    make -C "$repo_root/build" SETUP="$mode" BRANCH=silam_ci RULES=full -j2 >> "$artifacts/build.log" 2>&1
    test -x "$repo_root/bin/silam_ci.$mode"
    printf 'compile=PASS\ncompile_seconds=%s\n' "$((SECONDS - compile_started))" >> "$artifacts/summary.txt"

    stage=prepare_case
    cp -a "$repo_root/silam-toypoint/." "$case_dir/"
    ln -sfn "$repo_root/ini" "$case_dir/ini"
    # Only remove stale results in this newly created case, never in the input tree.
    rm -rf -- "$case_dir/output"
    shopt -s nullglob
    rm -f -- "$case_dir"/*.log
    mkdir -p "$case_dir/output"
    cd "$case_dir"

    stage=run
    run_started=$SECONDS
    printf 'Running %s with a seven-minute limit\n' "$mode"
    if [[ "$mode" == gnumpi ]]; then
        timeout --kill-after=30s 7m mpirun --allow-run-as-root --oversubscribe --bind-to none -np 2 \
            "$repo_root/bin/silam_ci.$mode" toypoint_mpi.control > "$artifacts/run.log" 2>&1
    else
        timeout --kill-after=30s 7m "$repo_root/bin/silam_ci.$mode" toypoint_mpi.control > "$artifacts/run.log" 2>&1
    fi
    printf 'run=PASS\nrun_seconds=%s\n' "$((SECONDS - run_started))" >> "$artifacts/summary.txt"

    stage=verify
    verify_run_log "$mode" "$artifacts/run.log" >> "$artifacts/summary.txt" 2>&1
    verify_output "$case_dir" "$artifacts" "$repo_root/.github/scripts/toypoint-time.txt" >> "$artifacts/summary.txt" 2>&1
    stage=complete
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
