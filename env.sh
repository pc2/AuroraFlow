#!/usr/bin/bash
module reset

ml fpga
ml xilinx/xrt/2.16
export XILINX_LOCAL_USER_DATA=no

ml tools
ml changeFPGAlinks

ml toolchain
ml gompi/2025b
