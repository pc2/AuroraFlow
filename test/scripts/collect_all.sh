#!/usr/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AURORA_FLOW_DIR="${AURORA_FLOW_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

source "${AURORA_FLOW_DIR}/env.sh"

make -C "${AURORA_FLOW_DIR}/test" clean

# Collect xclbins produced by synth_all.sh from the per-config repo copies
base_path="${AURORA_FLOW_DIR}"
target_dir="${AURORA_FLOW_DIR}/test"

for mode in 0 1; do
    for width in 32 64; do
        path=${base_path}_${mode}_${width}
        cp ${path}/test/aurora_flow_test_hw.xclbin ${target_dir}/aurora_flow_test_hw_${mode}_${width}.xclbin
    done
done
