#!/bin/bash
set -e

EMU_MODE="${1:-sw_emu}"
NUM_RANKS="${2:-2}"
shift 2 2>/dev/null || shift $# 2>/dev/null || true
export AURORA_PIPE_DIR="${AURORA_PIPE_DIR:-$(pwd)/aurora_emu_$$}"
export XCL_EMULATION_MODE=$EMU_MODE

rm -rf "$AURORA_PIPE_DIR" .hw_emu_rank_* .run
mkdir -p "$AURORA_PIPE_DIR"
trap 'rm -rf "$AURORA_PIPE_DIR" .hw_emu_rank_* .run' EXIT

./scripts/configure_ring_emu.sh $NUM_RANKS

if [ "$EMU_MODE" = "hw_emu" ]; then
    mpirun -x AURORA_PIPE_DIR -x XCL_EMULATION_MODE -n $NUM_RANKS \
        scripts/hw_emu_rank_wrapper.sh -m 2 "$@"
else
    mpirun -x AURORA_PIPE_DIR -x XCL_EMULATION_MODE -n $NUM_RANKS \
        ./host_aurora_flow_test -m 2 "$@"
fi
