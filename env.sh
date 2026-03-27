#!/usr/bin/bash
module reset

ml fpga
ml xilinx/xrt/2.16

ml tools
ml changeFPGAlinks

ml toolchain
ml gompi/2025b
