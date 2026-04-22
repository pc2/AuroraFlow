#!/bin/bash
set -e

NUM_RANKS="${1:?usage: configure_pair_emu.sh <num_ranks> <pipe_dir>}"
PIPE_DIR="${2:?usage: configure_pair_emu.sh <num_ranks> <pipe_dir>}"

for ((r=0; r<NUM_RANKS; r++)); do
    rank_dir="${PIPE_DIR}/rank${r}"
    mkdir -p "$rank_dir"
    for i in 0 1; do
        mkfifo "${rank_dir}/link_i${i}_tx"
    done
    ln -s "link_i1_tx" "${rank_dir}/link_i0_rx"
    ln -s "link_i0_tx" "${rank_dir}/link_i1_rx"
done
