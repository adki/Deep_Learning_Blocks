

`ifdef COSIM_BFM
   cosim_bfm_axi #(.AXI_WIDTH_ID (P_AXI_WIDTH_ID ) // ID width in bits
                  ,.AXI_WIDTH_AD (P_AXI_WIDTH_AD ) // address width
                  ,.AXI_WIDTH_DA (P_AXI_WIDTH_DA ))// data width
   u_bfm_axi(
         .ARESETn              ( ARESETn      )
       , .ACLK                 ( ACLK         )
       , .M_AWID               ( m_axi_AWID    [0])
       , .M_AWADDR             ( m_axi_AWADDR  [0])
       , .M_AWLEN              ( m_axi_AWLEN   [0])
       , .M_AWLOCK             ( m_axi_AWLOCK  [0])
       , .M_AWSIZE             ( m_axi_AWSIZE  [0])
       , .M_AWBURST            ( m_axi_AWBURST [0])
       `ifdef AMBA_AXI_CACHE
       , .M_AWCACHE            ( m_axi_AWCACHE [0])
       `endif
       `ifdef AMBA_AXI_PROT
       , .M_AWPROT             ( m_axi_AWPROT  [0])
       `endif
       , .M_AWVALID            ( m_axi_AWVALID [0])
       , .M_AWREADY            ( m_axi_AWREADY [0])
       `ifdef AMBA_QOS
       , .M_AWQOS              ( m_axi_AWQOS   [0])
       , .M_AWREGION           ( m_axi_AWREGION[0])
       `endif
       `ifndef AMBA_AXI4
       , .M_WID                ( m_axi_WID     [0])
       `endif
       , .M_WDATA              ( m_axi_WDATA   [0])
       , .M_WSTRB              ( m_axi_WSTRB   [0])
       , .M_WLAST              ( m_axi_WLAST   [0])
       , .M_WVALID             ( m_axi_WVALID  [0])
       , .M_WREADY             ( m_axi_WREADY  [0])
       , .M_BID                ( m_axi_BID     [0])
       , .M_BRESP              ( m_axi_BRESP   [0])
       , .M_BVALID             ( m_axi_BVALID  [0])
       , .M_BREADY             ( m_axi_BREADY  [0])
       , .M_ARID               ( m_axi_ARID    [0])
       , .M_ARADDR             ( m_axi_ARADDR  [0])
       , .M_ARLEN              ( m_axi_ARLEN   [0])
       , .M_ARLOCK             ( m_axi_ARLOCK  [0])
       , .M_ARSIZE             ( m_axi_ARSIZE  [0])
       , .M_ARBURST            ( m_axi_ARBURST [0])
       `ifdef AMBA_AXI_CACHE
       , .M_ARCACHE            ( m_axi_ARCACHE [0])
       `endif
       `ifdef AMBA_AXI_PROT
       , .M_ARPROT             ( m_axi_ARPROT  [0])
       `endif
       , .M_ARVALID            ( m_axi_ARVALID [0])
       , .M_ARREADY            ( m_axi_ARREADY [0])
       `ifdef AMBA_QOS
       , .M_ARQOS              ( m_axi_ARQOS   [0])
       , .M_ARREGION           ( m_axi_ARREGION[0])
       `endif
       , .M_RID                ( m_axi_RID     [0])
       , .M_RDATA              ( m_axi_RDATA   [0])
       , .M_RRESP              ( m_axi_RRESP   [0])
       , .M_RLAST              ( m_axi_RLAST   [0])
       , .M_RVALID             ( m_axi_RVALID  [0])
       , .M_RREADY             ( m_axi_RREADY  [0])
       , .IRQ                  (              )
       , .GPIN                 ( 32'h0        )
       , .GPOUT                (              )
   );
`else
    tester_convolution_2d #(.WIDTH_ID       ( P_AXI_WIDTH_ID     )
                           ,.WIDTH_AD       ( P_AXI_WIDTH_AD     )
                           ,.WIDTH_DA       ( P_AXI_WIDTH_DA     )
                           ,.ADDR_BASE_MEM  ( P_ADDR_BASE_MEM    )
                           ,.SIZE_MEM       ( P_SIZE_MEM         )
                           ,.ADDR_BASE_CONV (`DPU_ADDR_BASE_CONV )
                           ,.SIZE_CONV      (`DPU_SIZE_CONV      )
                           ,.DATA_TYPE      ( DATA_TYPE          )
                           ,.DATA_WIDTH     ( DATA_WIDTH         )
                           ,.EN             ( 1                  ))
    u_tester (
          .ARESETn  (ARESETn             )
        , .ACLK     (ACLK                )
        , .AWID     (m_axi_AWID       [0])
        , .AWADDR   (m_axi_AWADDR     [0])
        , .AWLEN    (m_axi_AWLEN      [0])
        , .AWLOCK   (m_axi_AWLOCK     [0])
        , .AWSIZE   (m_axi_AWSIZE     [0])
        , .AWBURST  (m_axi_AWBURST    [0])
        , .AWVALID  (m_axi_AWVALID    [0])
        , .AWREADY  (m_axi_AWREADY    [0])
        , .WDATA    (m_axi_WDATA      [0])
        , .WSTRB    (m_axi_WSTRB      [0])
        , .WLAST    (m_axi_WLAST      [0])
        , .WVALID   (m_axi_WVALID     [0])
        , .WREADY   (m_axi_WREADY     [0])
        , .BID      (m_axi_BID        [0])
        , .BRESP    (m_axi_BRESP      [0])
        , .BVALID   (m_axi_BVALID     [0])
        , .BREADY   (m_axi_BREADY     [0])
        , .ARID     (m_axi_ARID       [0])
        , .ARADDR   (m_axi_ARADDR     [0])
        , .ARLEN    (m_axi_ARLEN      [0])
        , .ARLOCK   (m_axi_ARLOCK     [0])
        , .ARSIZE   (m_axi_ARSIZE     [0])
        , .ARBURST  (m_axi_ARBURST    [0])
        , .ARVALID  (m_axi_ARVALID    [0])
        , .ARREADY  (m_axi_ARREADY    [0])
        , .RID      (m_axi_RID        [0])
        , .RDATA    (m_axi_RDATA      [0])
        , .RRESP    (m_axi_RRESP      [0])
        , .RLAST    (m_axi_RLAST      [0])
        , .RVALID   (m_axi_RVALID     [0])
        , .RREADY   (m_axi_RREADY     [0])
    );
`endif
