#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# All build artifacts (host binary, xclbin, emconfig.json) live in the test
# build directory. cd into it so ./host_aurora_flow_test and the hw_emu rank
# wrapper find them.
BUILD_DIR="${BUILD_DIR:-${SCRIPT_DIR}/../build}"
cd "$BUILD_DIR"

EMU_MODE="${1:-sw_emu}"
NUM_RANKS="${2:-2}"
shift 2 2>/dev/null || shift $# 2>/dev/null || true
export AURORA_PIPE_DIR="${AURORA_PIPE_DIR:-$(pwd)/aurora_emu_$$}"
export XCL_EMULATION_MODE=$EMU_MODE

rm -rf "$AURORA_PIPE_DIR" .hw_emu_rank_* .run
mkdir -p "$AURORA_PIPE_DIR"
trap 'rm -rf "$AURORA_PIPE_DIR" .hw_emu_rank_* .run' EXIT

"${SCRIPT_DIR}/configure_loopback_emu.sh" $NUM_RANKS

if [ "$EMU_MODE" = "hw_emu" ]; then
    mpirun -x AURORA_PIPE_DIR -x XCL_EMULATION_MODE -n $NUM_RANKS \
        "${SCRIPT_DIR}/hw_emu_rank_wrapper.sh" -m 0 "$@"
else
    mpirun -x AURORA_PIPE_DIR -x XCL_EMULATION_MODE -n $NUM_RANKS \
        ./host_aurora_flow_test -m 0 "$@"
fi
