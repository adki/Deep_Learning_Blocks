
    linear_1d #(.M_AXI_WIDTH_ID    ( P_WIDTH_ID        )
               ,.M_AXI_WIDTH_AD    ( P_WIDTH_AD        )
               ,.M_AXI_WIDTH_DA    ( P_WIDTH_DA        )
               ,.DATA_WIDTH        ( DATA_WIDTH        )
               `ifdef DATA_FIXED_POINT
               ,.DATA_WIDTH_Q      ( DATA_WIDTH_Q      )
               `endif
               ,.INPUT_FIFO_DEPTH  ( INPUT_FIFO_DEPTH  )
               ,.WEIGHT_FIFO_DEPTH ( WEIGHT_FIFO_DEPTH )
               ,.RESULT_FIFO_DEPTH ( RESULT_FIFO_DEPTH )
               )
    u_linear (
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
        , .M_AXI_RST_AWID         ( M_AWID   [1] )
        , .M_AXI_RST_AWADDR       ( M_AWADDR [1] )
        , .M_AXI_RST_AWLEN        ( M_AWLEN  [1] )
        , .M_AXI_RST_AWSIZE       ( M_AWSIZE [1] )
        , .M_AXI_RST_AWBURST      ( M_AWBURST[1] )
        , .M_AXI_RST_AWVALID      ( M_AWVALID[1] )
        , .M_AXI_RST_AWREADY      ( M_AWREADY[1] )
        , .M_AXI_RST_WDATA        ( M_WDATA  [1] )
        , .M_AXI_RST_WSTRB        ( M_WSTRB  [1] )
        , .M_AXI_RST_WLAST        ( M_WLAST  [1] )
        , .M_AXI_RST_WVALID       ( M_WVALID [1] )
        , .M_AXI_RST_WREADY       ( M_WREADY [1] )
        , .M_AXI_RST_BID          ( M_BID    [1] )
        , .M_AXI_RST_BRESP        ( M_BRESP  [1] )
        , .M_AXI_RST_BVALID       ( M_BVALID [1] )
        , .M_AXI_RST_BREADY       ( M_BREADY [1] )
        , .M_AXI_INPUT_ARID       ( M_ARID   [1] )
        , .M_AXI_INPUT_ARADDR     ( M_ARADDR [1] )
        , .M_AXI_INPUT_ARLEN      ( M_ARLEN  [1] )
        , .M_AXI_INPUT_ARSIZE     ( M_ARSIZE [1] )
        , .M_AXI_INPUT_ARBURST    ( M_ARBURST[1] )
        , .M_AXI_INPUT_ARVALID    ( M_ARVALID[1] )
        , .M_AXI_INPUT_ARREADY    ( M_ARREADY[1] )
        , .M_AXI_INPUT_RID        ( M_RID    [1] )
        , .M_AXI_INPUT_RDATA      ( M_RDATA  [1] )
        , .M_AXI_INPUT_RRESP      ( M_RRESP  [1] )
        , .M_AXI_INPUT_RLAST      ( M_RLAST  [1] )
        , .M_AXI_INPUT_RVALID     ( M_RVALID [1] )
        , .M_AXI_INPUT_RREADY     ( M_RREADY [1] )
        , .M_AXI_WEIGHT_ARID      ( M_ARID   [2] )
        , .M_AXI_WEIGHT_ARADDR    ( M_ARADDR [2] )
        , .M_AXI_WEIGHT_ARLEN     ( M_ARLEN  [2] )
        , .M_AXI_WEIGHT_ARSIZE    ( M_ARSIZE [2] )
        , .M_AXI_WEIGHT_ARBURST   ( M_ARBURST[2] )
        , .M_AXI_WEIGHT_ARVALID   ( M_ARVALID[2] )
        , .M_AXI_WEIGHT_ARREADY   ( M_ARREADY[2] )
        , .M_AXI_WEIGHT_RID       ( M_RID    [2] )
        , .M_AXI_WEIGHT_RDATA     ( M_RDATA  [2] )
        , .M_AXI_WEIGHT_RRESP     ( M_RRESP  [2] )
        , .M_AXI_WEIGHT_RLAST     ( M_RLAST  [2] )
        , .M_AXI_WEIGHT_RVALID    ( M_RVALID [2] )
        , .M_AXI_WEIGHT_RREADY    ( M_RREADY [2] )
        , .interrupt              ( interrupt    )
    );
    assign M_AWID   [2]= 'h0;
    assign M_AWADDR [2]= 'h0;
    assign M_AWLEN  [2]= 'h0;
    assign M_AWSIZE [2]= 'h0;
    assign M_AWBURST[2]= 'h0;
    assign M_AWVALID[2]=1'b0;
    assign M_WDATA  [2]= 'h0;
    assign M_WSTRB  [2]= 'h0;
    assign M_WLAST  [2]= 'h0;
    assign M_WVALID [2]=1'b0;
    assign M_BREADY [2]=1'b0;
