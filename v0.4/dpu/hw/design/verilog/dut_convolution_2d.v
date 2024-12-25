
    convolution_2d #(.APB_WIDTH_AD      ( P_APB_WIDTH_AD )
                    ,.APB_WIDTH_DA      ( P_APB_WIDTH_DA )
                    ,.M_AXI_WIDTH_ID    ( P_AXI_WIDTH_ID )
                    ,.M_AXI_WIDTH_AD    ( P_AXI_WIDTH_AD )
                    ,.M_AXI_WIDTH_DA    ( P_AXI_WIDTH_DA )
                    ,.DATA_TYPE         ( P_DATA_TYPE    )
                    ,.DATA_WIDTH        ( P_DATA_WIDTH   )
                    `ifdef DATA_FIXED_POINT
                    ,.DATA_WIDTH_Q      ( P_DATA_WIDTH_Q )
                    `endif
                    ,.KERNEL_MAX_SIZE   ( P_CONV_KERNEL_MAX_SIZE    )
                    ,.KERNEL_FIFO_DEPTH ( P_CONV_KERNEL_FIFO_DEPTH  )
                    ,.FEATURE_FIFO_DEPTH( P_CONV_FEATURE_FIFO_DEPTH )
                    ,.CHANNEL_FIFO_DEPTH( P_CONV_CHANNEL_FIFO_DEPTH )
                    ,.RESULT_FIFO_DEPTH ( P_CONV_RESULT_FIFO_DEPTH  )
                    ,.ACTIV_FUNC_BYPASS    (`ACTIV_FUNC_BYPASS     )
                    ,.ACTIV_FUNC_RELU      (`ACTIV_FUNC_RELU       )
                    ,.ACTIV_FUNC_LEAKY_RELU(`ACTIV_FUNC_LEAKY_RELU )
                    ,.ACTIV_FUNC_SIGMOID   (`ACTIV_FUNC_SIGMOID    )
                    ,.ACTIV_FUNC_TANH      (`ACTIV_FUNC_TANH       )
                    )
    u_conv (
          .PRESETn            ( PRESETn    )
        , .PCLK               ( PCLK       )
        , .S_APB_PSEL         ( PSEL    [1])
        , .S_APB_PENABLE      ( PENABLE    )
        , .S_APB_PADDR        ( PADDR      )
        , .S_APB_PWRITE       ( PWRITE     )
        , .S_APB_PRDATA       ( PRDATA  [1])
        , .S_APB_PWDATA       ( PWDATA     )
        , .S_APB_PREADY       (            )
        , .S_APB_PSLVERR      (            )
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
        , .M_AXI_CHN_ARID     ( M_ARID   [1] )
        , .M_AXI_CHN_ARADDR   ( M_ARADDR [1] )
        , .M_AXI_CHN_ARLEN    ( M_ARLEN  [1] )
        , .M_AXI_CHN_ARSIZE   ( M_ARSIZE [1] )
        , .M_AXI_CHN_ARBURST  ( M_ARBURST[1] )
        , .M_AXI_CHN_ARVALID  ( M_ARVALID[1] )
        , .M_AXI_CHN_ARREADY  ( M_ARREADY[1] )
        , .M_AXI_CHN_RID      ( M_RID    [1] )
        , .M_AXI_CHN_RDATA    ( M_RDATA  [1] )
        , .M_AXI_CHN_RRESP    ( M_RRESP  [1] )
        , .M_AXI_CHN_RLAST    ( M_RLAST  [1] )
        , .M_AXI_CHN_RVALID   ( M_RVALID [1] )
        , .M_AXI_CHN_RREADY   ( M_RREADY [1] )
        , .M_AXI_KNL_ARID     ( M_ARID   [2] )
        , .M_AXI_KNL_ARADDR   ( M_ARADDR [2] )
        , .M_AXI_KNL_ARLEN    ( M_ARLEN  [2] )
        , .M_AXI_KNL_ARSIZE   ( M_ARSIZE [2] )
        , .M_AXI_KNL_ARBURST  ( M_ARBURST[2] )
        , .M_AXI_KNL_ARVALID  ( M_ARVALID[2] )
        , .M_AXI_KNL_ARREADY  ( M_ARREADY[2] )
        , .M_AXI_KNL_RID      ( M_RID    [2] )
        , .M_AXI_KNL_RDATA    ( M_RDATA  [2] )
        , .M_AXI_KNL_RRESP    ( M_RRESP  [2] )
        , .M_AXI_KNL_RLAST    ( M_RLAST  [2] )
        , .M_AXI_KNL_RVALID   ( M_RVALID [2] )
        , .M_AXI_KNL_RREADY   ( M_RREADY [2] )
        , .M_AXI_FTU_ARID     ( M_ARID   [3] )
        , .M_AXI_FTU_ARADDR   ( M_ARADDR [3] )
        , .M_AXI_FTU_ARLEN    ( M_ARLEN  [3] )
        , .M_AXI_FTU_ARSIZE   ( M_ARSIZE [3] )
        , .M_AXI_FTU_ARBURST  ( M_ARBURST[3] )
        , .M_AXI_FTU_ARVALID  ( M_ARVALID[3] )
        , .M_AXI_FTU_ARREADY  ( M_ARREADY[3] )
        , .M_AXI_FTU_RID      ( M_RID    [3] )
        , .M_AXI_FTU_RDATA    ( M_RDATA  [3] )
        , .M_AXI_FTU_RRESP    ( M_RRESP  [3] )
        , .M_AXI_FTU_RLAST    ( M_RLAST  [3] )
        , .M_AXI_FTU_RVALID   ( M_RVALID [3] )
        , .M_AXI_FTU_RREADY   ( M_RREADY [3] )
        , .interrupt          ( interrupt_conv )
    );
    assign M_AWLOCK [1]=1'b0;
    assign M_ARLOCK [1]=1'b0;
    assign M_AWID   [2]= 'h0; // kernel read only
    assign M_AWADDR [2]= 'h0;
    assign M_AWLOCK [2]=1'b0;
    assign M_AWLEN  [2]= 'h0;
    assign M_AWSIZE [2]= 'h0;
    assign M_AWBURST[2]= 'h0;
    assign M_AWVALID[2]=1'b0;
    assign M_WDATA  [2]= 'h0;
    assign M_WSTRB  [2]= 'h0;
    assign M_WLAST  [2]= 'h0;
    assign M_WVALID [2]=1'b0;
    assign M_BREADY [2]=1'b0;
    assign M_ARLOCK [2]=1'b0;
    assign M_AWID   [3]= 'h0; // feature map read only
    assign M_AWADDR [3]= 'h0;
    assign M_AWLOCK [3]=1'b0;
    assign M_AWLEN  [3]= 'h0;
    assign M_AWSIZE [3]= 'h0;
    assign M_AWBURST[3]= 'h0;
    assign M_AWVALID[3]=1'b0;
    assign M_WDATA  [3]= 'h0;
    assign M_WSTRB  [3]= 'h0;
    assign M_WLAST  [3]= 'h0;
    assign M_WVALID [3]=1'b0;
    assign M_BREADY [3]=1'b0;
    assign M_ARLOCK [3]=1'b0;
