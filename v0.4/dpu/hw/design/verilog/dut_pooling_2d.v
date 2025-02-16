
    pooling_2d #(.APB_WIDTH_AD      ( P_APB_WIDTH_AD )
                ,.APB_WIDTH_DA      ( P_APB_WIDTH_DA )
                ,.M_AXI_WIDTH_ID    ( P_AXI_WIDTH_ID )
                ,.M_AXI_WIDTH_AD    ( P_AXI_WIDTH_AD )
                ,.M_AXI_WIDTH_DA    ( P_AXI_WIDTH_DA )
                ,.DATA_TYPE         ( P_DATA_TYPE    )
                ,.DATA_WIDTH        ( P_DATA_WIDTH   )
                `ifdef DATA_FIXED_POINT
                ,.DATA_WIDTH_Q      ( P_DATA_WIDTH_Q )
                `endif
                ,.KERNEL_MAX_SIZE   ( P_POOL_KERNEL_MAX_SIZE    )
                ,.FEATURE_FIFO_DEPTH( P_POOL_FEATURE_FIFO_DEPTH )
                ,.RESULT_FIFO_DEPTH ( P_POOL_RESULT_FIFO_DEPTH  )
                ,.POOLING_NOP(`POOLING_NOP )
                ,.POOLING_MAX(`POOLING_MAX )
                ,.POOLING_AVG(`POOLING_AVG )
                )
    u_pooling (
          .PRESETn            ( PRESETn    )
        , .PCLK               ( PCLK       )
        , .S_APB_PSEL         ( PSEL    [2])
        , .S_APB_PENABLE      ( PENABLE    )
        , .S_APB_PADDR        ( PADDR      )
        , .S_APB_PWRITE       ( PWRITE     )
        , .S_APB_PRDATA       ( PRDATA  [2])
        , .S_APB_PWDATA       ( PWDATA     )
        , .S_APB_PREADY       (            )
        , .S_APB_PSLVERR      (            )
        , .ARESETn            ( ARESETn      )
        , .ACLK               ( ACLK         )
        , .M_AXI_RST_AWID     ( M_AWID   [4] )
        , .M_AXI_RST_AWADDR   ( M_AWADDR [4] )
        , .M_AXI_RST_AWLEN    ( M_AWLEN  [4] )
        , .M_AXI_RST_AWSIZE   ( M_AWSIZE [4] )
        , .M_AXI_RST_AWBURST  ( M_AWBURST[4] )
        , .M_AXI_RST_AWVALID  ( M_AWVALID[4] )
        , .M_AXI_RST_AWREADY  ( M_AWREADY[4] )
        , .M_AXI_RST_WDATA    ( M_WDATA  [4] )
        , .M_AXI_RST_WSTRB    ( M_WSTRB  [4] )
        , .M_AXI_RST_WLAST    ( M_WLAST  [4] )
        , .M_AXI_RST_WVALID   ( M_WVALID [4] )
        , .M_AXI_RST_WREADY   ( M_WREADY [4] )
        , .M_AXI_RST_BID      ( M_BID    [4] )
        , .M_AXI_RST_BRESP    ( M_BRESP  [4] )
        , .M_AXI_RST_BVALID   ( M_BVALID [4] )
        , .M_AXI_RST_BREADY   ( M_BREADY [4] )
        , .M_AXI_FTU_ARID     ( M_ARID   [4] )
        , .M_AXI_FTU_ARADDR   ( M_ARADDR [4] )
        , .M_AXI_FTU_ARLEN    ( M_ARLEN  [4] )
        , .M_AXI_FTU_ARSIZE   ( M_ARSIZE [4] )
        , .M_AXI_FTU_ARBURST  ( M_ARBURST[4] )
        , .M_AXI_FTU_ARVALID  ( M_ARVALID[4] )
        , .M_AXI_FTU_ARREADY  ( M_ARREADY[4] )
        , .M_AXI_FTU_RID      ( M_RID    [4] )
        , .M_AXI_FTU_RDATA    ( M_RDATA  [4] )
        , .M_AXI_FTU_RRESP    ( M_RRESP  [4] )
        , .M_AXI_FTU_RLAST    ( M_RLAST  [4] )
        , .M_AXI_FTU_RVALID   ( M_RVALID [4] )
        , .M_AXI_FTU_RREADY   ( M_RREADY [4] )
        , .interrupt          ( interrupt_pool )
    );

    assign M_AWLOCK[4] = 1'b0;
    assign M_ARLOCK[4] = 1'b0;
