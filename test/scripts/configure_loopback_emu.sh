#!/bin/bash
set -e

PIPE_DIR="${AURORA_PIPE_DIR:?AURORA_PIPE_DIR must be set}"
NUM_RANKS="${1:?usage: configure_loopback_emu.sh <num_ranks>}"

for ((r=0; r<NUM_RANKS; r++)); do
    for i in 0 1; do
        mkfifo "${PIPE_DIR}/aurora_r${r}_i${i}_tx"
        ln -s "${PIPE_DIR}/aurora_r${r}_i${i}_tx" "${PIPE_DIR}/aurora_r${r}_i${i}_rx"
    done
done
