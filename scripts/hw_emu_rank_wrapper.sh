#!/bin/bash
# Invoked by mpirun — creates a unique working directory per rank
# to isolate XRT hw_emu xsim instances

RANK=${OMPI_COMM_WORLD_RANK:-${PMIX_RANK:-${PMI_RANK:-${SLURM_LOCALID:-0}}}}
BASE_DIR="$(pwd)"
RANK_DIR="${BASE_DIR}/.hw_emu_rank_${RANK}"

mkdir -p "$RANK_DIR"
ln -sf "$BASE_DIR"/aurora_flow_test_hw_emu.xclbin "$RANK_DIR"/
ln -sf "$BASE_DIR"/emconfig.json "$RANK_DIR"/
ln -sf "$BASE_DIR"/host_aurora_flow_test "$RANK_DIR"/

cd "$RANK_DIR"
exec ./host_aurora_flow_test "$@"
