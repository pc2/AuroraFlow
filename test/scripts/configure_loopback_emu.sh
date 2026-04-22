#!/bin/bash
set -e

NUM_RANKS="${1:?usage: configure_loopback_emu.sh <num_ranks> <pipe_dir>}"
PIPE_DIR="${2:?usage: configure_loopback_emu.sh <num_ranks> <pipe_dir>}"

for ((r=0; r<NUM_RANKS; r++)); do
    rank_dir="${PIPE_DIR}/rank${r}"
    mkdir -p "$rank_dir"
    for i in 0 1; do
        mkfifo "${rank_dir}/link_i${i}_tx"
        ln -s "link_i${i}_tx" "${rank_dir}/link_i${i}_rx"
    done
done
