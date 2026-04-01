#!/bin/bash
set -e

PIPE_DIR="${AURORA_PIPE_DIR:?AURORA_PIPE_DIR must be set}"
NUM_RANKS="${1:?usage: configure_ring_emu.sh <num_ranks>}"

for ((r=0; r<NUM_RANKS; r++)); do
    for i in 0 1; do
        mkfifo "${PIPE_DIR}/aurora_r${r}_i${i}_tx"
    done
done

for ((r=0; r<NUM_RANKS; r++)); do
    next=$(( (r+1) % NUM_RANKS ))
    prev=$(( (r-1+NUM_RANKS) % NUM_RANKS ))
    # ch0 receives from previous rank's ch1
    ln -s "${PIPE_DIR}/aurora_r${prev}_i1_tx" "${PIPE_DIR}/aurora_r${r}_i0_rx"
    # ch1 receives from next rank's ch0
    ln -s "${PIPE_DIR}/aurora_r${next}_i0_tx" "${PIPE_DIR}/aurora_r${r}_i1_rx"
done
