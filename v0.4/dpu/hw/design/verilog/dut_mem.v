//------------------------------------------------------------------------------
// Copyright (c) 2018 by Future Design Systems.
// All right reserved.
//------------------------------------------------------------------------------
// dut_axi256_mem.v
//------------------------------------------------------------------------------
// VERSION: 2018.05.01.
//------------------------------------------------------------------------------
`ifdef SIM_BEH
   mem_axi_beh #(.AXI_WIDTH_CID  (P_AXI_WIDTH_CID)// Channel ID width in bits
                ,.AXI_WIDTH_ID   (P_AXI_WIDTH_ID )// ID width in bits
                ,.AXI_WIDTH_AD   (P_AXI_WIDTH_AD )// address width
                ,.AXI_WIDTH_DA   (P_AXI_WIDTH_DA )// data width
                ,.P_SIZE_IN_BYTES(P_SIZE_MEM     )
                ,.P_DELAY_WRITE_SETUP(1)
                ,.P_DELAY_WRITE_BURST(2)
                ,.P_DELAY_READ_SETUP (1)
                ,.P_DELAY_READ_BURST (3))
   u_mem (
`elsif SIM
   mem_axi #(.AXI_WIDTH_CID  (P_AXI_WIDTH_CID)// Channel ID width in bits
            ,.AXI_WIDTH_ID   (P_AXI_WIDTH_ID )// ID width in bits
            ,.AXI_WIDTH_AD   (P_AXI_WIDTH_AD )// address width
            ,.AXI_WIDTH_DA   (P_AXI_WIDTH_DA )// data width
            ,.P_SIZE_IN_BYTES(P_SIZE_MEM     ))
   u_mem (
`else
   bram_axi #(.AXI_WIDTH_CID  (P_AXI_WIDTH_CID)// Channel ID width in bits
             ,.AXI_WIDTH_ID   (P_AXI_WIDTH_ID )// ID width in bits
             ,.AXI_WIDTH_AD   (P_AXI_WIDTH_AD )// address width
             ,.AXI_WIDTH_DA   (P_AXI_WIDTH_DA )// data width
             ,.P_SIZE_IN_BYTES(P_SIZE_MEM     ))
   u_bram (
`endif
                                      .ARESETn  (   ARESETn    )
     ,                                .ACLK     (   ACLK       )
     ,                                .AWID     ( S_AWID    [0])
     ,                                .AWADDR   ( S_AWADDR  [0])
     ,                                .AWLEN    ( S_AWLEN   [0])
     ,                                .AWLOCK   ( S_AWLOCK  [0])
     ,                                .AWSIZE   ( S_AWSIZE  [0])
     ,                                .AWBURST  ( S_AWBURST [0])
     `ifdef AMBA_AXI_CACHE
     ,                                .AWCACHE  ( S_AWCACHE [0])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                                .AWPROT   ( S_AWPROT  [0])
     `endif
     ,                                .AWVALID  ( S_AWVALID [0])
     ,                                .AWREADY  ( S_AWREADY [0])
     `ifdef AMBA_QOS
     ,                                .AWQOS    ( S_AWQOS   [0])
     ,                                .AWREGION ( S_AWREGION[0])
     `endif
     `ifndef AMBA_AXI4
     ,                                .WID      ( S_WID     [0])
     `endif
     ,                                .WDATA    ( S_WDATA   [0])
     ,                                .WSTRB    ( S_WSTRB   [0])
     ,                                .WLAST    ( S_WLAST   [0])
     ,                                .WVALID   ( S_WVALID  [0])
     ,                                .WREADY   ( S_WREADY  [0])
     ,                                .BID      ( S_BID     [0])
     ,                                .BRESP    ( S_BRESP   [0])
     ,                                .BVALID   ( S_BVALID  [0])
     ,                                .BREADY   ( S_BREADY  [0])
     ,                                .ARID     ( S_ARID    [0])
     ,                                .ARADDR   ( S_ARADDR  [0])
     ,                                .ARLEN    ( S_ARLEN   [0])
     ,                                .ARLOCK   ( S_ARLOCK  [0])
     ,                                .ARSIZE   ( S_ARSIZE  [0])
     ,                                .ARBURST  ( S_ARBURST [0])
     `ifdef AMBA_AXI_CACHE
     ,                                .ARCACHE  ( S_ARCACHE [0])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                                .ARPROT   ( S_ARPROT  [0])
     `endif
     ,                                .ARVALID  ( S_ARVALID [0])
     ,                                .ARREADY  ( S_ARREADY [0])
     `ifdef AMBA_QOS
     ,                                .ARQOS    ( S_ARQOS   [0])
     ,                                .ARREGION ( S_ARREGION[0])
     `endif
     ,                                .RID      ( S_RID     [0])
     ,                                .RDATA    ( S_RDATA   [0])
     ,                                .RRESP    ( S_RRESP   [0])
     ,                                .RLAST    ( S_RLAST   [0])
     ,                                .RVALID   ( S_RVALID  [0])
     ,                                .RREADY   ( S_RREADY  [0])
   );
//------------------------------------------------------------------------------
// Revision History
//
// 2018.05.01: Started by Ando Ki (adki@future-ds.com)
//------------------------------------------------------------------------------
