`ifndef SIM_DEFINE_V
`define SIM_DEFINE_V
//-----------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki
// All rights reserved.
//-----------------------------------------------------------------------
`undef  SIM      // define this for simulation case if you are not sure
`define SYN      // undefine this for simulation case
`undef  VCD      // define this for VCD waveform dump
`undef  DEBUG
`undef  RIGOR
//-----------------------------------------------------------------------
`define DATA_TYPE      TYPE_DATA
`define AXI_WIDTH_DA   128
`define DATA_WIDTH     32
//-----------------------------------------------------------------------
`endif
