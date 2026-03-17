#!/usr/bin/bash
module reset
ml fpga devel lib tools toolchain && ml xilinx/xrt/2.16 changeFPGAlinks gompi/2024a
