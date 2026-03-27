#!/bin/bash
set -e

PIPE_DIR="${AURORA_PIPE_DIR:-/tmp}"
export AURORA_PIPE_DIR="$PIPE_DIR"
export XCL_EMULATION_MODE=sw_emu

cleanup() {
    rm -f "${PIPE_DIR}"/aurora_*_tx "${PIPE_DIR}"/aurora_*_rx
}
trap cleanup EXIT

for i in 0 1; do
    mkfifo "${PIPE_DIR}/aurora_${i}_tx"
    ln -s "${PIPE_DIR}/aurora_${i}_tx" "${PIPE_DIR}/aurora_${i}_rx"
done

./host_aurora_flow_test -d 0 "$@"
