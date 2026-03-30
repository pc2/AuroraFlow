#!/bin/bash
set -e

PIPE_DIR="${AURORA_PIPE_DIR:?AURORA_PIPE_DIR must be set}"
NUM_RANKS="${1:?usage: configure_ring_sw_emu.sh <num_ranks>}"

for ((r=0; r<NUM_RANKS; r++)); do
    p0=$((2*r))
    p1=$((2*r+1))
    mkfifo "${PIPE_DIR}/aurora_${p0}_tx"
    mkfifo "${PIPE_DIR}/aurora_${p1}_tx"
done

for ((r=0; r<NUM_RANKS; r++)); do
    p0=$((2*r))
    p1=$((2*r+1))
    next=$(( (r+1) % NUM_RANKS ))
    prev=$(( (r-1+NUM_RANKS) % NUM_RANKS ))
    next_p0=$((2*next))
    prev_p1=$((2*prev+1))
    ln -s "${PIPE_DIR}/aurora_${prev_p1}_tx" "${PIPE_DIR}/aurora_${p0}_rx"
    ln -s "${PIPE_DIR}/aurora_${next_p0}_tx" "${PIPE_DIR}/aurora_${p1}_rx"
done
