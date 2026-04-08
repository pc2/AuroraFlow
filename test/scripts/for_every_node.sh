#!/usr/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -z $1 ]]; then
    echo "pass arguments as first argument"
    exit
fi

for node in $("${SCRIPT_DIR}/print_available_nodes.sh"); do
    sbatch -w $node $@
done