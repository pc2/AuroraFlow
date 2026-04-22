#!/bin/bash
set -e

NUM_RANKS="${1:?usage: configure_ring_emu.sh <num_ranks> <pipe_dir>}"
PIPE_DIR="${2:?usage: configure_ring_emu.sh <num_ranks> <pipe_dir>}"

for ((r=0; r<NUM_RANKS; r++)); do
    rank_dir="${PIPE_DIR}/rank${r}"
    mkdir -p "$rank_dir"
    for i in 0 1; do
        mkfifo "${rank_dir}/link_i${i}_tx"
    done
done

for ((r=0; r<NUM_RANKS; r++)); do
    next=$(( (r+1) % NUM_RANKS ))
    prev=$(( (r-1+NUM_RANKS) % NUM_RANKS ))
    ln -s "../rank${prev}/link_i1_tx" "${PIPE_DIR}/rank${r}/link_i0_rx"
    ln -s "../rank${next}/link_i0_tx" "${PIPE_DIR}/rank${r}/link_i1_rx"
done
