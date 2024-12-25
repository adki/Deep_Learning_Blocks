//------------------------------------------------------------------------------
// Copyright (c) 2021 by Future Design Systems.
// All right reserved.
//------------------------------------------------------------------------------
// dut_bfm_cosim.v
//------------------------------------------------------------------------------
// VERSION: 2021.04.01.
//------------------------------------------------------------------------------
//  
//  +---------+        +----------+
//  |         |        |          |
//  |         |        |          |
//  |         |        |          |
//  |         |        |          |--->
//  | cosim_  |<======>| AMBA     |--->
//  | bfm_axi |        |          |<---
//  |         |        |          |<---
//  |         |        |          |
//  |         |        |          |
//  +---------+        +----------+
//------------------------------------------------------------------------------

   //---------------------------------------------------------------------------
   assign                   SYS_RST_N=SYS_CLK_STABLE;
   wire [31:0]              GPOUT;
   //---------------------------------------------------------------------------
   cosim_bfm_axi #(.AXI_WIDTH_ID (P_AXI_WIDTH_ID ) // ID width in bits
                  ,.AXI_WIDTH_AD (P_AXI_WIDTH_AD ) // address width
                  ,.AXI_WIDTH_DA (P_AXI_WIDTH_DA ))// data width
   u_bfm_axi(
         .ARESETn              ( ARESETn      )
       , .ACLK                 ( ACLK         )
       , .M_AWID               ( M_AWID    [0])
       , .M_AWADDR             ( M_AWADDR  [0])
       , .M_AWLEN              ( M_AWLEN   [0])
       , .M_AWLOCK             ( M_AWLOCK  [0])
       , .M_AWSIZE             ( M_AWSIZE  [0])
       , .M_AWBURST            ( M_AWBURST [0])
       `ifdef AMBA_AXI_CACHE
       , .M_AWCACHE            ( M_AWCACHE [0])
       `endif
       `ifdef AMBA_AXI_PROT
       , .M_AWPROT             ( M_AWPROT  [0])
       `endif
       , .M_AWVALID            ( M_AWVALID [0])
       , .M_AWREADY            ( M_AWREADY [0])
       `ifdef AMBA_QOS
       , .M_AWQOS              ( M_AWQOS   [0])
       , .M_AWREGION           ( M_AWREGION[0])
       `endif
       `ifndef AMBA_AXI4
       , .M_WID                ( M_WID     [0])
       `endif
       , .M_WDATA              ( M_WDATA   [0])
       , .M_WSTRB              ( M_WSTRB   [0])
       , .M_WLAST              ( M_WLAST   [0])
       , .M_WVALID             ( M_WVALID  [0])
       , .M_WREADY             ( M_WREADY  [0])
       , .M_BID                ( M_BID     [0])
       , .M_BRESP              ( M_BRESP   [0])
       , .M_BVALID             ( M_BVALID  [0])
       , .M_BREADY             ( M_BREADY  [0])
       , .M_ARID               ( M_ARID    [0])
       , .M_ARADDR             ( M_ARADDR  [0])
       , .M_ARLEN              ( M_ARLEN   [0])
       , .M_ARLOCK             ( M_ARLOCK  [0])
       , .M_ARSIZE             ( M_ARSIZE  [0])
       , .M_ARBURST            ( M_ARBURST [0])
       `ifdef AMBA_AXI_CACHE
       , .M_ARCACHE            ( M_ARCACHE [0])
       `endif
       `ifdef AMBA_AXI_PROT
       , .M_ARPROT             ( M_ARPROT  [0])
       `endif
       , .M_ARVALID            ( M_ARVALID [0])
       , .M_ARREADY            ( M_ARREADY [0])
       `ifdef AMBA_QOS
       , .M_ARQOS              ( M_ARQOS   [0])
       , .M_ARREGION           ( M_ARREGION[0])
       `endif
       , .M_RID                ( M_RID     [0])
       , .M_RDATA              ( M_RDATA   [0])
       , .M_RRESP              ( M_RRESP   [0])
       , .M_RLAST              ( M_RLAST   [0])
       , .M_RVALID             ( M_RVALID  [0])
       , .M_RREADY             ( M_RREADY  [0])
       , .IRQ                  ( GPOUT[0]     )
       , .GPIN                 ( GPOUT        )
       , .GPOUT                ( GPOUT        )
   );
//------------------------------------------------------------------------------
// Revision History
//
// 2021.04.01: Started by Ando Ki (adki@future-ds.com)
//------------------------------------------------------------------------------
