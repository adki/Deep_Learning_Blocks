

    tester_mover_2d #(.WIDTH_ID       ( P_WIDTH_ID       )
                     ,.WIDTH_AD       ( P_WIDTH_AD       )
                     ,.WIDTH_DA       ( P_WIDTH_DA       )
                     ,.ADDR_BASE_MEM  ( P_ADDR_BASE_MEM  )
                     ,.SIZE_MEM       ( P_SIZE_MEM       )
                     ,.ADDR_BASE_MOVER( P_ADDR_BASE_MOVER)
                     ,.SIZE_MOVER     ( P_SIZE_MOVER     )
                     ,.DATA_WIDTH     ( P_N              )
                     `ifdef DATA_FIXED_POINT
                     ,.DATA_WIDTH_Q   ( P_Q              )
                     `endif
                     ,.DATA_TYPE      ( P_DATA_TYPE      )
                     ,.EN             ( 1 )
                     ,.COMMAND_NOP       ( COMMAND_NOP        )
                     ,.COMMAND_FILL      ( COMMAND_FILL       )
                     ,.COMMAND_COPY      ( COMMAND_COPY       )
                     ,.COMMAND_RESIDUAL  ( COMMAND_RESIDUAL   )
                     ,.COMMAND_CONCAT0   ( COMMAND_CONCAT0    )
                     ,.COMMAND_CONCAT1   ( COMMAND_CONCAT1    )
                     ,.COMMAND_TRANSPOSE ( COMMAND_TRANSPOSE  )
                     ,.ACTIV_FUNC_BYPASS     ( ACTIV_FUNC_BYPASS     )
                     ,.ACTIV_FUNC_RELU       ( ACTIV_FUNC_RELU       )
                     ,.ACTIV_FUNC_LEAKY_RELU ( ACTIV_FUNC_LEAKY_RELU )
                     ,.ACTIV_FUNC_SIGMOID    ( ACTIV_FUNC_SIGMOID    )
                     ,.ACTIV_FUNC_TANH       ( ACTIV_FUNC_TANH       )
                     )
    u_tester (
          .ARESETn  (ARESETn         )
        , .ACLK     (ACLK            )
        , .AWID     (M_AWID       [0])
        , .AWADDR   (M_AWADDR     [0])
        , .AWLEN    (M_AWLEN      [0])
        , .AWLOCK   (M_AWLOCK     [0])
        , .AWSIZE   (M_AWSIZE     [0])
        , .AWBURST  (M_AWBURST    [0])
        `ifdef AMBA_AXI_CACHE
        , .AWCACHE  (M_AWCACHE    [0])
        `endif
        `ifdef AMBA_AXI_PROT
        , .AWPROT   (M_AWPROT     [0])
        `endif
        , .AWVALID  (M_AWVALID    [0])
        , .AWREADY  (M_AWREADY    [0])
        `ifdef AMBA_QOS
        , .AWQOS    (M_AWQOS      [0])
        , .AWREGION (M_AWREGION   [0])
        `endif
        `ifndef AMBA_AXI4
        , .WID      (M_WID        [0])
        `endif
        , .WDATA    (M_WDATA      [0])
        , .WSTRB    (M_WSTRB      [0])
        , .WLAST    (M_WLAST      [0])
        , .WVALID   (M_WVALID     [0])
        , .WREADY   (M_WREADY     [0])
        , .BID      (M_BID        [0])
        , .BRESP    (M_BRESP      [0])
        , .BVALID   (M_BVALID     [0])
        , .BREADY   (M_BREADY     [0])
        , .ARID     (M_ARID       [0])
        , .ARADDR   (M_ARADDR     [0])
        , .ARLEN    (M_ARLEN      [0])
        , .ARLOCK   (M_ARLOCK     [0])
        , .ARSIZE   (M_ARSIZE     [0])
        , .ARBURST  (M_ARBURST    [0])
        `ifdef AMBA_AXI_CACHE
        , .ARCACHE  (M_ARCACHE    [0])
        `endif
        `ifdef AMBA_AXI_PROT
        , .ARPROT   (M_ARPROT     [0])
        `endif
        , .ARVALID  (M_ARVALID    [0])
        , .ARREADY  (M_ARREADY    [0])
        `ifdef AMBA_QOS
        , .ARQOS    (M_ARQOS      [0])
        , .ARREGION (M_ARREGION   [0])
        `endif
        , .RID      (M_RID        [0])
        , .RDATA    (M_RDATA      [0])
        , .RRESP    (M_RRESP      [0])
        , .RLAST    (M_RLAST      [0])
        , .RVALID   (M_RVALID     [0])
        , .RREADY   (M_RREADY     [0])
    );
