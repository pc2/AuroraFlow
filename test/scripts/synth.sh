#!/usr/bin/bash
#SBATCH -p normal
#SBATCH -t 12:00:00
#SBATCH -q fpgasynthesis
#SBATCH --cpus-per-task=32
#SBATCH --mem=64G
#SBATCH --mail-type=ALL

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AURORA_FLOW_DIR="${AURORA_FLOW_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

source "${AURORA_FLOW_DIR}/env.sh"

make -C "${AURORA_FLOW_DIR}/test" -j6 $@
