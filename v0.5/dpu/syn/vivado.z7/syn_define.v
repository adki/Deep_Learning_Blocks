`ifndef SYN_DEFINE_V
`define SYN_DEFINE_V
//-----------------------------------------------------------------------
`undef  SIM      // define this for simulation case if you are not sure
`define SYN      // undefine this for simulation case
`define VCD      // define this for VCD waveform dump
`define DEBUG
`define RIGOR
//-----------------------------------------------------------------------
`include "defines_system.v"
//-----------------------------------------------------------------------
`define XILINX
//-----------------------------------------------------------------------
// define board type: ML605, ZC706, SP605, VCU108
`undef  BOARD_SP605
`undef  BOARD_ML605
`undef  BOARD_VCU108
`undef  BOARD_ZC706
`undef  BOARD_ZC702
`define BOARD_ZED
`undef  BOARD_ZCU111

`ifdef  BOARD_ML605
`define FPGA_FAMILY     "VIRTEX6"
`define ISE
`elsif  BOARD_SP605
`define FPGA_FAMILY     "SPARTAN6"
`define ISE
`elsif  BOARD_VCU108
`define FPGA_FAMILY     "VirtexUS"
`define VIVADO
`elsif  BOARD_ZC706
`define FPGA_FAMILY     "ZYNQ7000"
`define VIVADO
`elsif  BOARD_ZC702
`define FPGA_FAMILY     "ZYNQ7000"
`define VIVADO
`elsif  BOARD_ZED
`define FPGA_FAMILY     "ZYNQ7000"
`define VIVADO
`elsif  BOARD_ZCU111
`define FPGA_FAMILY     "ZynqUSP"
`define VIVADO
`else
`define FPGA_FAMILY     "ARTIX7"
`define ISE
`endif
//-----------------------------------------------------------------------
`define AMBA_AXI4
`undef  AMBA_AXI_CACHE
`undef  AMBA_AXI_PROT
`undef  AMBA_QOS
`undef  AMBA_AXI_AWUSER
`undef  AMBA_AXI_WUSER
`undef  AMBA_AXI_BUSER
`undef  AMBA_AXI_ARUSER
`undef  AMBA_AXI_RUSER
`define AMBA_APB3
`undef  AMBA_APB4
`endif
