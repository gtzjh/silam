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
    local netcdf_file
    find "$case_dir/output" -type f -name '*.nc' -print0 > "$artifacts/netcdf-files.list" || return "$?"
    while IFS= read -r -d '' netcdf_file; do
        ncdump "$netcdf_file" > /dev/null || return "$?"
    done < "$artifacts/netcdf-files.list"
    ncdump -v time "$output" > "$artifacts/time.cdl" || return "$?"
    TOYPOINT_NETCDF_FILES="$artifacts/netcdf-files.list" TOYPOINT_TIME_DUMP="$artifacts/time.cdl" TOYPOINT_TIME_REFERENCE="$reference" python3 <<'PY'
import datetime
import json
import math
import os
import pathlib
import re
import struct


def verify_netcdf_extent(path):
    # ncdump can succeed on a truncated classic file. Check declared data extents.
    # https://docs.unidata.ucar.edu/netcdf-c/current/file_format_specifications.html
    type_sizes = {1: 1, 2: 1, 3: 2, 4: 4, 5: 4, 6: 8}
    file_size = path.stat().st_size
    with path.open('rb') as stream:
        def read(size):
            data = stream.read(size)
            if len(data) != size:
                raise SystemExit(f'Truncated NetCDF header: {path}')
            return data

        def integer(code='>I'):
            return struct.unpack(code, read(struct.calcsize(code)))[0]

        def skip(size):
            if stream.tell() + size > file_size:
                raise SystemExit(f'Truncated NetCDF header: {path}')
            stream.seek(size, 1)

        def name():
            size = integer()
            value = read(size).decode('utf-8')
            skip(-size % 4)
            return value

        def count(expected_tag):
            tag, length = integer(), integer()
            if (tag, length) == (0, 0):
                return 0
            if tag != expected_tag:
                raise SystemExit(f'Invalid NetCDF header list in {path}: tag={tag}')
            return length

        def attributes():
            for _ in range(count(12)):
                name()
                kind, length = integer(), integer()
                size = type_sizes[kind] * length
                skip(size + (-size % 4))

        magic = read(4)
        if magic not in (b'CDF\x01', b'CDF\x02'):
            raise SystemExit(f'Expected CDF1/CDF2 NetCDF3 output: {path}')
        num_records = integer()
        if num_records == 0xffffffff:
            raise SystemExit(f'Indeterminate record count in completed output: {path}')
        dimensions = []
        for _ in range(count(10)):
            name()
            dimensions.append(integer())
        attributes()
        variables = []
        for _ in range(count(11)):
            variable_name = name()
            shape = [dimensions[integer()] for _ in range(integer())]
            is_record = bool(shape) and shape[0] == 0
            attributes()
            kind, allocated = integer(), integer()
            begin = integer('>Q' if magic == b'CDF\x02' else '>I')
            size = math.prod(shape[1:] if is_record else shape) * type_sizes[kind]
            padded = size + (-size % 4)
            if allocated != min(padded, 0xffffffff):
                raise SystemExit(f'Invalid NetCDF variable size in {path}: {variable_name}')
            variables.append((variable_name, is_record, begin, size, padded, kind))

        header_end = stream.tell()
        record_variables = [variable for variable in variables if variable[1]]
        record_stride = sum(variable[4] for variable in record_variables)
        if len(record_variables) == 1 and record_variables[0][5] in (1, 2, 3):
            record_stride = record_variables[0][3]
        for variable_name, is_record, begin, size, padded, _ in variables:
            if is_record and num_records == 0:
                continue
            end = begin + ((num_records - 1) * record_stride + size if is_record else padded)
            if begin < header_end or end > file_size:
                raise SystemExit(f'Truncated or invalid NetCDF data: {path}, variable={variable_name}, required_end={end}, file_size={file_size}')


netcdf_paths = pathlib.Path(os.environ['TOYPOINT_NETCDF_FILES']).read_bytes().split(b'\0')
for file_path in filter(None, netcdf_paths):
    verify_netcdf_extent(pathlib.Path(os.fsdecode(file_path)))
print(f'netcdf_structure=PASS')

dump = pathlib.Path(os.environ['TOYPOINT_TIME_DUMP']).read_text()
reference = json.loads(pathlib.Path(os.environ['TOYPOINT_TIME_REFERENCE']).read_text())
units_match = re.search(r'\btime:units\s*=\s*"([^"]+)"\s*;', dump)
values_match = re.search(r'\bdata:\s.*?\btime\s*=\s*([^;]+);', dump, re.DOTALL)
if units_match is None or values_match is None:
    raise SystemExit('Cannot read the NetCDF time units and values')
units = units_match.group(1)
values = [float(item.strip()) for item in values_match.group(1).split(',')]
if units != reference['units'] or values != reference['values']:
    raise SystemExit(f'Time axis mismatch: expected {reference}, got units={units!r}, values={values}')
unit, epoch = units.split(' since ', 1)
seconds_per_unit = {'seconds': 1, 'minutes': 60, 'hours': 3600}[unit]
origin = datetime.datetime.fromisoformat(epoch.removesuffix(' UTC')).replace(tzinfo=datetime.timezone.utc)
times = [origin + datetime.timedelta(seconds=value * seconds_per_unit) for value in values]
if any((right - left).total_seconds() != 3600 for left, right in zip(times, times[1:])):
    raise SystemExit(f'Non-hourly or non-increasing time axis: {times}')
print(f'netcdf_read=PASS')
print(f'time_axis=PASS: {len(times)} records, units={units!r}, values={values}')
print(f'time_first={times[0].isoformat()}')
print(f'time_last={times[-1].isoformat()}')
PY
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
    verify_output "$case_dir" "$artifacts" "$repo_root/.github/scripts/toypoint-time.json" >> "$artifacts/summary.txt" 2>&1
    stage=complete
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
