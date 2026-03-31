#!/bin/bash
set -e

BUILD_DIR="${1:-_x_aurora_flow_test_hw_emu}"
DPI_SRC="$(realpath rtl/aurora_flow_dpi.c)"

XSIM_DIR=$(find "$BUILD_DIR" -path "*/behav_waveform/xsim" -type d | head -1)
if [ -z "$XSIM_DIR" ]; then
    echo "Error: xsim directory not found in $BUILD_DIR"
    exit 1
fi

echo "Compiling DPI-C for hw_emu..."
echo "  xsim dir: $XSIM_DIR"
echo "  dpi src:  $DPI_SRC"

cd "$XSIM_DIR"
xsc "$DPI_SRC" -o aurora_dpi
echo "DPI-C compiled: $(find . -name 'aurora_dpi*' -type f)"
