`ifndef SIM_DEFINE_V
`define SIM_DEFINE_V
//-----------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki
// All rights reserved.
//-----------------------------------------------------------------------
`define SIM      // define this for simulation case if you are not sure
`undef  SYN      // undefine this for simulation case
`undef  VCD      // define this for VCD waveform dump
`undef  DEBUG
`define RIGOR
//-----------------------------------------------------------------------
`define AXI_WIDTH_AD  32 // bit-width of address bus
`define AXI_WIDTH_DA  64 // bit-width of data bus
`define DATA_WIDTH    32 // bit-width of data-item
//-----------------------------------------------------------------------
`endif
