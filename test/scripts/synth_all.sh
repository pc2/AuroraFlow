#!/usr/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AURORA_FLOW_DIR="${AURORA_FLOW_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

source "${AURORA_FLOW_DIR}/env.sh"

make -C "${AURORA_FLOW_DIR}/test" clean

# Copy the entire repo (library + test app) for each configuration to allow
# parallel synthesis runs without stepping on each other's build artifacts.
base_path="${AURORA_FLOW_DIR}"

for mode in 0 1; do
    for width in 32 64; do
        path=${base_path}_${mode}_${width}
        rm -rf ${path}
        cp -r ${base_path} ${path}

        cd ${path}/test
        sbatch ./scripts/synth.sh xclbin USE_FRAMING=${mode} FIFO_WIDTH=${width}
    done
done
