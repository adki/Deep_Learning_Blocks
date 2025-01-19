`ifndef SIM_DEFINE_V
`define SIM_DEFINE_V
//-----------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki
// All rights reserved.
//-----------------------------------------------------------------------
`define SIM      // define this for simulation case if you are not sure
`undef  SYN      // undefine this for simulation case
`define VCD      // define this for VCD waveform dump
`undef  DEBUG
`define RIGOR
`undef  COSIM_BFM
//-----------------------------------------------------------------------
`include "defines_system.v"
//-----------------------------------------------------------------------
`endif
