//------------------------------------------------------------------------------
// Copyright (c) 2021 by Future Design Systems.
// All right reserved.
//------------------------------------------------------------------------------
// dut_bfm.v
//------------------------------------------------------------------------------
// VERSION: 2021.04.01.
//------------------------------------------------------------------------------
//      gpif2mast
//    +-----------+        +---------+        +----------+
//    |           |        |         |        |          |
//    |   CMD-FIFO+=======>|         |        |          |
//    |           |        |         |        |          |
//    |           |        |         |        |          |--->
//    |   U2F-FIFO+=======>| trx_axi |<======>| AMBA     |--->
//    |           |        |         |        |          |<---
//    |           |        |         |        |          |<---
//    |   F2U-FIFO|<=======+         |        |          |
//    |           |        |         |        |          |
//    +-----------+        +---------+        +----------+
//------------------------------------------------------------------------------

   //---------------------------------------------------------------------------
   // synthesis attribute IOB of SL_DT is "TRUE";
   wire [31:0]  SL_DT_I;
   wire [31:0]  SL_DT_O;
   wire         SL_DT_T;
   assign SL_DT_I = SL_DT;
   assign SL_DT   = (SL_DT_T==1'b0) ? SL_DT_O : 32'hZ;
   //---------------------------------------------------------------------------
   wire [15:0]              GPOUT;
   //---------------------------------------------------------------------------
   bfm_axi
   u_bfm_axi (
          .SYS_CLK_STABLE     ( SYS_CLK_STABLE )
        , .SYS_CLK            ( SYS_CLK        )
        , .SYS_RST_N          ( SYS_RST_N      )
        , .SL_RST_N           ( SL_RST_N       )
        , .SL_CS_N            ( SL_CS_N        )
        , .SL_PCLK            ( SL_PCLK        )
        , .SL_AD              ( SL_AD          )
        , .SL_FLAGA           ( SL_FLAGA       )
        , .SL_FLAGB           ( SL_FLAGB       )
        , .SL_FLAGC           ( SL_FLAGC       )
        , .SL_FLAGD           ( SL_FLAGD       )
        , .SL_RD_N            ( SL_RD_N        )
        , .SL_WR_N            ( SL_WR_N        )
        , .SL_OE_N            ( SL_OE_N        )
        , .SL_PKTEND_N        ( SL_PKTEND_N    )
        , .SL_DT_I            ( SL_DT_I        )
        , .SL_DT_O            ( SL_DT_O        )
        , .SL_DT_T            ( SL_DT_T        )
        , .SL_MODE            ( SL_MODE        )
        , .ARESETn            ( ARESETn        )
        , .ACLK               ( ACLK           )
        , .MID                ( 'h0            )
        , .AWID               ( M_AWID    [0])
        , .AWADDR             ( M_AWADDR  [0])
        , .AWLEN              ( M_AWLEN   [0])
        , .AWLOCK             ( M_AWLOCK  [0])
        , .AWSIZE             ( M_AWSIZE  [0])
        , .AWBURST            ( M_AWBURST [0])
        `ifdef AMBA_AXI_CACHE
        , .AWCACHE            ( M_AWCACHE [0])
        `endif
        `ifdef AMBA_AXI_PROT
        , .AWPROT             ( M_AWPROT  [0])
        `endif
        , .AWVALID            ( M_AWVALID [0])
        , .AWREADY            ( M_AWREADY [0])
      //`ifdef AMBA_QOS
        , .AWQOS              (              )
        , .AWREGION           (              )
      //`endif
        `ifndef AMBA_AXI4
        , .WID                ( M_WID     [0])
        `else
        , .WID                (              )
        `endif
        , .WDATA              ( M_WDATA   [0])
        , .WSTRB              ( M_WSTRB   [0])
        , .WLAST              ( M_WLAST   [0])
        , .WVALID             ( M_WVALID  [0])
        , .WREADY             ( M_WREADY  [0])
        , .BID                ( M_BID     [0])
        , .BRESP              ( M_BRESP   [0])
        , .BVALID             ( M_BVALID  [0])
        , .BREADY             ( M_BREADY  [0])
        , .ARID               ( M_ARID    [0])
        , .ARADDR             ( M_ARADDR  [0])
        , .ARLEN              ( M_ARLEN   [0])
        , .ARLOCK             ( M_ARLOCK  [0])
        , .ARSIZE             ( M_ARSIZE  [0])
        , .ARBURST            ( M_ARBURST [0])
        `ifdef AMBA_AXI_CACHE
        , .ARCACHE            ( M_ARCACHE [0])
        `endif
        `ifdef AMBA_AXI_PROT
        , .ARPROT             ( M_ARPROT  [0])
        `endif
        , .ARVALID            ( M_ARVALID [0])
        , .ARREADY            ( M_ARREADY [0])
      //`ifdef AMBA_QOS
        , .ARQOS              (              )
        , .ARREGION           (              )
      //`endif
        , .RID                ( M_RID     [0])
        , .RDATA              ( M_RDATA   [0])
        , .RRESP              ( M_RRESP   [0])
        , .RLAST              ( M_RLAST   [0])
        , .RVALID             ( M_RVALID  [0])
        , .RREADY             ( M_RREADY  [0])
        , .IRQ                ( GPOUT[0]     )
        , .FIQ                ( GPOUT[1]     )
        , .GPOUT              ( GPOUT        )
        , .GPIN               ( GPOUT        )
   );
//------------------------------------------------------------------------------
// Revision History
//
// 2021.04.01: Started by Ando Ki (adki@future-ds.com)
//------------------------------------------------------------------------------
