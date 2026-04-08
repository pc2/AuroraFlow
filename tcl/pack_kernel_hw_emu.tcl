#
# Copyright 2022 Xilinx, Inc.
#           2023-2026 Gerrit Pape (gerrit.pape@uni-paderborn.de)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# hw_emu variant: GT transceiver replaced with DPI-C pipe stub

##################################### Step 1: create vivado project and add design sources

# argv layout: <part> <instance> <src_dir> <build_dir>
set part      [lindex $argv 0]
set instance  [lindex $argv 1]
set src_dir   [lindex $argv 2]
set build_dir [lindex $argv 3]

create_project aurora_flow_${instance} ./aurora_flow_${instance} -part $part

add_files -norecurse -fileset sources_1 \
       [list                                          \
              ${src_dir}/rtl/aurora_flow_control_s_axi.v \
              ${build_dir}/rtl/hw_emu/aurora_flow_${instance}.v \
              ${src_dir}/rtl/aurora_flow_io.v \
              ${src_dir}/rtl/aurora_flow_nfc.v \
              ${build_dir}/rtl/hw_emu/aurora_flow_define.v \
              ${src_dir}/rtl/aurora_flow_configuration.v \
              ${src_dir}/rtl/aurora_flow_monitor.v \
              ${src_dir}/rtl/aurora_flow_gt_stub.sv \
              ${build_dir}/ip_creation/axis_data_fifo_rx/axis_data_fifo_rx.xci \
              ${build_dir}/ip_creation/axis_data_fifo_tx/axis_data_fifo_tx.xci \
              ${build_dir}/ip_creation/axis_dwidth_converter_rx/axis_dwidth_converter_rx.xci \
              ${build_dir}/ip_creation/axis_dwidth_converter_tx/axis_dwidth_converter_tx.xci \
       ]

# make `include "aurora_flow_define.v" resolve to the hw_emu variant
set_property include_dirs [list ${build_dir}/rtl/hw_emu] [get_filesets sources_1]

update_compile_order -fileset sources_1

ipx::package_project -root_dir ./aurora_flow_ip_${instance} -vendor xilinx.com -library user -taxonomy /UserIP -import_files -set_current true

# inference clock and reset signals
ipx::infer_bus_interface ap_clk xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface ap_rst_n xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]

# associate AXI/AXIS interface with clock
ipx::associate_bus_interfaces -busif s_axi_control  -clock ap_clk [ipx::current_core]
ipx::associate_bus_interfaces -busif rx_axis        -clock ap_clk [ipx::current_core]
ipx::associate_bus_interfaces -busif tx_axis        -clock ap_clk [ipx::current_core]
ipx::associate_bus_interfaces -clock ap_clk -reset ap_rst_n [ipx::current_core]

# No GT ports or refclk for hw_emu

# Set required property for Vitis kernel
set_property sdx_kernel true [ipx::current_core]
set_property sdx_kernel_type rtl [ipx::current_core]

# Packaging Vivado IP
ipx::update_source_project_archive -component [ipx::current_core]
ipx::save_core [ipx::current_core]

# Generate Vitis Kernel from Vivado IP
package_xo -force \
           -xo_path ${build_dir}/aurora_flow_hw_emu_${instance}.xo \
           -kernel_name aurora_flow_${instance} \
           -ctrl_protocol ap_ctrl_none \
           -ip_directory ./aurora_flow_ip_${instance} \
           -output_kernel_xml ${build_dir}/aurora_flow_hw_emu_${instance}.xml
