
    localparam P_DELAY_WRITE_SETUP=0
             , P_DELAY_WRITE_BURST=0
             , P_DELAY_READ_SETUP =0
             , P_DELAY_READ_BURST =0;


   mem_axi_beh #(.AXI_WIDTH_SID  (P_AXI_WIDTH_SID)// Channel ID width in bits
                ,.AXI_WIDTH_AD   (P_AXI_WIDTH_AD )// address width
                ,.AXI_WIDTH_DA   (P_AXI_WIDTH_DA )// data width
                ,.P_SIZE_IN_BYTES(P_SIZE_MEM )// 
                ,.P_DELAY_WRITE_SETUP(P_DELAY_WRITE_SETUP)
                ,.P_DELAY_WRITE_BURST(P_DELAY_WRITE_BURST)
                ,.P_DELAY_READ_SETUP (P_DELAY_READ_SETUP )
                ,.P_DELAY_READ_BURST (P_DELAY_READ_BURST ))
   u_mem  (
          .ARESETn  (ARESETn             )
        , .ACLK     (ACLK                )
        , .AWID     (s_axi_AWID       [0])
        , .AWADDR   (s_axi_AWADDR     [0])
        , .AWLEN    (s_axi_AWLEN      [0])
        , .AWLOCK   (s_axi_AWLOCK     [0])
        , .AWSIZE   (s_axi_AWSIZE     [0])
        , .AWBURST  (s_axi_AWBURST    [0])
        , .AWVALID  (s_axi_AWVALID    [0])
        , .AWREADY  (s_axi_AWREADY    [0])
        , .WDATA    (s_axi_WDATA      [0])
        , .WSTRB    (s_axi_WSTRB      [0])
        , .WLAST    (s_axi_WLAST      [0])
        , .WVALID   (s_axi_WVALID     [0])
        , .WREADY   (s_axi_WREADY     [0])
        , .BID      (s_axi_BID        [0])
        , .BRESP    (s_axi_BRESP      [0])
        , .BVALID   (s_axi_BVALID     [0])
        , .BREADY   (s_axi_BREADY     [0])
        , .ARID     (s_axi_ARID       [0])
        , .ARADDR   (s_axi_ARADDR     [0])
        , .ARLEN    (s_axi_ARLEN      [0])
        , .ARLOCK   (s_axi_ARLOCK     [0])
        , .ARSIZE   (s_axi_ARSIZE     [0])
        , .ARBURST  (s_axi_ARBURST    [0])
        , .ARVALID  (s_axi_ARVALID    [0])
        , .ARREADY  (s_axi_ARREADY    [0])
        , .RID      (s_axi_RID        [0])
        , .RDATA    (s_axi_RDATA      [0])
        , .RRESP    (s_axi_RRESP      [0])
        , .RLAST    (s_axi_RLAST      [0])
        , .RVALID   (s_axi_RVALID     [0])
        , .RREADY   (s_axi_RREADY     [0])
   );

