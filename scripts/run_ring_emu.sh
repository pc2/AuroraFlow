#!/bin/bash
set -e

EMU_MODE=${1:-sw_emu}; shift 2>/dev/null || true
NUM_RANKS=${1:-2}; shift 2>/dev/null || true
export AURORA_PIPE_DIR="${AURORA_PIPE_DIR:-$(pwd)/aurora_emu_$$}"
export XCL_EMULATION_MODE=$EMU_MODE

mkdir -p "$AURORA_PIPE_DIR"
trap 'rm -rf "$AURORA_PIPE_DIR"' EXIT

./scripts/configure_ring_sw_emu.sh $NUM_RANKS
mpirun -n $NUM_RANKS ./host_aurora_flow_test -m 2 -p aurora_flow_test_${EMU_MODE}.xclbin "$@"
