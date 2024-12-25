
    linear_1d #(.APB_WIDTH_AD      ( P_APB_WIDTH_AD )
               ,.APB_WIDTH_DA      ( P_APB_WIDTH_DA )
               ,.M_AXI_WIDTH_ID    ( P_AXI_WIDTH_ID )
               ,.M_AXI_WIDTH_AD    ( P_AXI_WIDTH_AD )
               ,.M_AXI_WIDTH_DA    ( P_AXI_WIDTH_DA )
               ,.DATA_TYPE         ( P_DATA_TYPE    )
               ,.DATA_WIDTH        ( P_DATA_WIDTH   )
               `ifdef LINEAR_FIXED_POINT
               ,.DATA_WIDTH_Q      ( P_DATA_WIDTH_Q )
               `endif
               ,.INPUT_FIFO_DEPTH  ( P_LINEAR_INPUT_FIFO_DEPTH  )
               ,.WEIGHT_FIFO_DEPTH ( P_LINEAR_WEIGHT_FIFO_DEPTH )
               ,.RESULT_FIFO_DEPTH ( P_LINEAR_RESULT_FIFO_DEPTH )
               ,.ACTIV_FUNC_BYPASS    (`ACTIV_FUNC_BYPASS     )
               ,.ACTIV_FUNC_RELU      (`ACTIV_FUNC_RELU       )
               ,.ACTIV_FUNC_LEAKY_RELU(`ACTIV_FUNC_LEAKY_RELU )
               ,.ACTIV_FUNC_SIGMOID   (`ACTIV_FUNC_SIGMOID    )
               ,.ACTIV_FUNC_TANH      (`ACTIV_FUNC_TANH       )
               )
    u_linear (
          .PRESETn            ( PRESETn    )
        , .PCLK               ( PCLK       )
        , .PSEL               ( PSEL    [3])
        , .PENABLE            ( PENABLE    )
        , .PADDR              ( PADDR      )
        , .PWRITE             ( PWRITE     )
        , .PRDATA             ( PRDATA  [3])
        , .PWDATA             ( PWDATA     )
        , .ARESETn            ( ARESETn      )
        , .ACLK               ( ACLK         )
        , .M_AXI_RST_AWID         ( M_AWID   [5] )
        , .M_AXI_RST_AWADDR       ( M_AWADDR [5] )
        , .M_AXI_RST_AWLEN        ( M_AWLEN  [5] )
        , .M_AXI_RST_AWSIZE       ( M_AWSIZE [5] )
        , .M_AXI_RST_AWBURST      ( M_AWBURST[5] )
        , .M_AXI_RST_AWVALID      ( M_AWVALID[5] )
        , .M_AXI_RST_AWREADY      ( M_AWREADY[5] )
        , .M_AXI_RST_WDATA        ( M_WDATA  [5] )
        , .M_AXI_RST_WSTRB        ( M_WSTRB  [5] )
        , .M_AXI_RST_WLAST        ( M_WLAST  [5] )
        , .M_AXI_RST_WVALID       ( M_WVALID [5] )
        , .M_AXI_RST_WREADY       ( M_WREADY [5] )
        , .M_AXI_RST_BID          ( M_BID    [5] )
        , .M_AXI_RST_BRESP        ( M_BRESP  [5] )
        , .M_AXI_RST_BVALID       ( M_BVALID [5] )
        , .M_AXI_RST_BREADY       ( M_BREADY [5] )
        , .M_AXI_INPUT_ARID       ( M_ARID   [5] )
        , .M_AXI_INPUT_ARADDR     ( M_ARADDR [5] )
        , .M_AXI_INPUT_ARLEN      ( M_ARLEN  [5] )
        , .M_AXI_INPUT_ARSIZE     ( M_ARSIZE [5] )
        , .M_AXI_INPUT_ARBURST    ( M_ARBURST[5] )
        , .M_AXI_INPUT_ARVALID    ( M_ARVALID[5] )
        , .M_AXI_INPUT_ARREADY    ( M_ARREADY[5] )
        , .M_AXI_INPUT_RID        ( M_RID    [5] )
        , .M_AXI_INPUT_RDATA      ( M_RDATA  [5] )
        , .M_AXI_INPUT_RRESP      ( M_RRESP  [5] )
        , .M_AXI_INPUT_RLAST      ( M_RLAST  [5] )
        , .M_AXI_INPUT_RVALID     ( M_RVALID [5] )
        , .M_AXI_INPUT_RREADY     ( M_RREADY [5] )
        , .M_AXI_WEIGHT_ARID      ( M_ARID   [6] )
        , .M_AXI_WEIGHT_ARADDR    ( M_ARADDR [6] )
        , .M_AXI_WEIGHT_ARLEN     ( M_ARLEN  [6] )
        , .M_AXI_WEIGHT_ARSIZE    ( M_ARSIZE [6] )
        , .M_AXI_WEIGHT_ARBURST   ( M_ARBURST[6] )
        , .M_AXI_WEIGHT_ARVALID   ( M_ARVALID[6] )
        , .M_AXI_WEIGHT_ARREADY   ( M_ARREADY[6] )
        , .M_AXI_WEIGHT_RID       ( M_RID    [6] )
        , .M_AXI_WEIGHT_RDATA     ( M_RDATA  [6] )
        , .M_AXI_WEIGHT_RRESP     ( M_RRESP  [6] )
        , .M_AXI_WEIGHT_RLAST     ( M_RLAST  [6] )
        , .M_AXI_WEIGHT_RVALID    ( M_RVALID [6] )
        , .M_AXI_WEIGHT_RREADY    ( M_RREADY [6] )
        , .interrupt              ( interrupt_linear )
    );
    assign M_AWLOCK [5]=1'b0;
    assign M_ARLOCK [5]=1'b0;
    assign M_AWID   [6]= 'h0; // weight read-only
    assign M_AWADDR [6]= 'h0;
    assign M_AWLOCK [6]=1'b0;
    assign M_AWLEN  [6]= 'h0;
    assign M_AWSIZE [6]= 'h0;
    assign M_AWBURST[6]= 'h0;
    assign M_AWVALID[6]=1'b0;
    assign M_WDATA  [6]= 'h0;
    assign M_WSTRB  [6]= 'h0;
    assign M_WLAST  [6]= 'h0;
    assign M_WVALID [6]=1'b0;
    assign M_BREADY [6]=1'b0;
    assign M_ARLOCK [6]=1'b0;
