
    localparam APB_WIDTH_AD = 32
             , APB_WIDTH_DA = 32
             , APB_WIDTH_DS = (APB_WIDTH_DA/8);

   //wire                     PRESETn;
   //wire                     PCLK   ;
     wire [APB_WIDTH_AD-1:0]  PADDR  ;
     wire                     PENABLE;
     wire                     PWRITE ;
     wire [APB_WIDTH_DA-1:0]  PWDATA ;
     wire                     PSEL   ;
     wire [APB_WIDTH_DA-1:0]  PRDATA ;
     `ifdef AMBA_APB3
     wire                     PREADY ;
     wire                     PSLVERR;
     `endif
     `ifdef AMBA_APB4
     wire [APB_WIDTH_DS-1:0]  PSTRB  ;
     wire [ 2:0]              PPROT  ;
     `endif

   axi_to_apb #(.AXI_WIDTH_CID (P_WIDTH_CID)
               ,.AXI_WIDTH_ID  (P_WIDTH_ID )
               ,.AXI_WIDTH_SID (P_WIDTH_SID)// Channel ID width in bits
               ,.AXI_WIDTH_AD  (P_WIDTH_AD )// address width
               ,.AXI_WIDTH_DA  (P_WIDTH_DA )// data width
               ,.AXI_WIDTH_DS  (P_WIDTH_DS )// data strobe width
               )
   u_axi2apb  (
          .ARESETn  (ARESETn         )
        , .ACLK     (ACLK            )
        , .AWID     (S_AWID       [1])
        , .AWADDR   (S_AWADDR     [1])
        , .AWLEN    (S_AWLEN      [1])
        , .AWLOCK   (S_AWLOCK     [1])
        , .AWSIZE   (S_AWSIZE     [1])
        , .AWBURST  (S_AWBURST    [1])
        `ifdef AMBA_AXI_CACHE
        , .AWCACHE  (S_AWCACHE    [1])
        `endif
        `ifdef AMBA_AXI_PROT
        , .AWPROT   (S_AWPROT     [1])
        `endif
        , .AWVALID  (S_AWVALID    [1])
        , .AWREADY  (S_AWREADY    [1])
        `ifdef AMBA_QOS
        , .AWQOS    (S_AWQOS      [1])
        , .AWREGION (S_AWREGION   [1])
        `endif
        `ifndef AMBA_AXI4
        , .WID      (S_WID        [1])
        `endif
        , .WDATA    (S_WDATA      [1])
        , .WSTRB    (S_WSTRB      [1])
        , .WLAST    (S_WLAST      [1])
        , .WVALID   (S_WVALID     [1])
        , .WREADY   (S_WREADY     [1])
        , .BID      (S_BID        [1])
        , .BRESP    (S_BRESP      [1])
        , .BVALID   (S_BVALID     [1])
        , .BREADY   (S_BREADY     [1])
        , .ARID     (S_ARID       [1])
        , .ARADDR   (S_ARADDR     [1])
        , .ARLEN    (S_ARLEN      [1])
        , .ARLOCK   (S_ARLOCK     [1])
        , .ARSIZE   (S_ARSIZE     [1])
        , .ARBURST  (S_ARBURST    [1])
        `ifdef AMBA_AXI_CACHE
        , .ARCACHE  (S_ARCACHE    [1])
        `endif
        `ifdef AMBA_AXI_PROT
        , .ARPROT   (S_ARPROT     [1])
        `endif
        , .ARVALID  (S_ARVALID    [1])
        , .ARREADY  (S_ARREADY    [1])
        `ifdef AMBA_QOS
        , .ARQOS    (S_ARQOS      [1])
        , .ARREGION (S_ARREGION   [1])
        `endif
        , .RID      (S_RID        [1])
        , .RDATA    (S_RDATA      [1])
        , .RRESP    (S_RRESP      [1])
        , .RLAST    (S_RLAST      [1])
        , .RVALID   (S_RVALID     [1])
        , .RREADY   (S_RREADY     [1])
        , .PRESETn  ( PRESETn )
        , .PCLK     ( PCLK    )
        , .PADDR    ( PADDR   )
        , .PENABLE  ( PENABLE )
        , .PWRITE   ( PWRITE  )
        , .PWDATA   ( PWDATA  )
        , .PSEL     ( PSEL    )
        , .PRDATA   ( PRDATA  )
        `ifdef AMBA_APB3
        , .PREADY   ( PREADY )
        , .PSLVERR  ( PSLAVERR )
        `endif
        `ifdef AMBA_APB4
        , .PSTRB    ( PSTRB )
        , .PPROT    ( PPROT )
        `endif
   );

