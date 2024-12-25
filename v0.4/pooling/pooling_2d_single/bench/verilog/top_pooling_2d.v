
    pooling_2d #(.APB_WIDTH_AD      ( APB_WIDTH_AD       )
                ,.APB_WIDTH_DA      ( APB_WIDTH_DA       )
                ,.M_AXI_WIDTH_ID    ( P_WIDTH_ID         )
                ,.M_AXI_WIDTH_AD    ( P_WIDTH_AD         )
                ,.M_AXI_WIDTH_DA    ( P_WIDTH_DA         )
                ,.DATA_TYPE         ( DATA_TYPE          )
                ,.DATA_WIDTH        ( DATA_WIDTH         )
                `ifdef DATA_FIXED_POINT
                ,.DATA_WIDTH_Q      ( DATA_WIDTH_Q       )
                `endif
                ,.KERNEL_MAX_SIZE   ( KERNEL_MAX_SIZE    )
                ,.FEATURE_FIFO_DEPTH( FEATURE_FIFO_DEPTH )
                ,.RESULT_FIFO_DEPTH ( RESULT_FIFO_DEPTH  )
                )
    u_pooling (
          .PRESETn            ( PRESETn )
        , .PCLK               ( PCLK    )
        , .S_APB_PSEL         ( PSEL    )
        , .S_APB_PENABLE      ( PENABLE )
        , .S_APB_PADDR        ( PADDR   )
        , .S_APB_PWRITE       ( PWRITE  )
        , .S_APB_PRDATA       ( PRDATA  )
        , .S_APB_PWDATA       ( PWDATA  )
        , .S_APB_PREADY       (         )
        , .S_APB_PSLVERR      (         )
        , .ARESETn            ( ARESETn      )
        , .ACLK               ( ACLK         )
        , .M_AXI_RST_AWID     ( M_AWID   [1] )
        , .M_AXI_RST_AWADDR   ( M_AWADDR [1] )
        , .M_AXI_RST_AWLEN    ( M_AWLEN  [1] )
        , .M_AXI_RST_AWSIZE   ( M_AWSIZE [1] )
        , .M_AXI_RST_AWBURST  ( M_AWBURST[1] )
        , .M_AXI_RST_AWVALID  ( M_AWVALID[1] )
        , .M_AXI_RST_AWREADY  ( M_AWREADY[1] )
        , .M_AXI_RST_WDATA    ( M_WDATA  [1] )
        , .M_AXI_RST_WSTRB    ( M_WSTRB  [1] )
        , .M_AXI_RST_WLAST    ( M_WLAST  [1] )
        , .M_AXI_RST_WVALID   ( M_WVALID [1] )
        , .M_AXI_RST_WREADY   ( M_WREADY [1] )
        , .M_AXI_RST_BID      ( M_BID    [1] )
        , .M_AXI_RST_BRESP    ( M_BRESP  [1] )
        , .M_AXI_RST_BVALID   ( M_BVALID [1] )
        , .M_AXI_RST_BREADY   ( M_BREADY [1] )
        , .M_AXI_FTU_ARID     ( M_ARID   [1] )
        , .M_AXI_FTU_ARADDR   ( M_ARADDR [1] )
        , .M_AXI_FTU_ARLEN    ( M_ARLEN  [1] )
        , .M_AXI_FTU_ARSIZE   ( M_ARSIZE [1] )
        , .M_AXI_FTU_ARBURST  ( M_ARBURST[1] )
        , .M_AXI_FTU_ARVALID  ( M_ARVALID[1] )
        , .M_AXI_FTU_ARREADY  ( M_ARREADY[1] )
        , .M_AXI_FTU_RID      ( M_RID    [1] )
        , .M_AXI_FTU_RDATA    ( M_RDATA  [1] )
        , .M_AXI_FTU_RRESP    ( M_RRESP  [1] )
        , .M_AXI_FTU_RLAST    ( M_RLAST  [1] )
        , .M_AXI_FTU_RVALID   ( M_RVALID [1] )
        , .M_AXI_FTU_RREADY   ( M_RREADY [1] )
        , .interrupt          ( interrupt    )
    );
