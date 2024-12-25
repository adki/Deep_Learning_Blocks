
`ifdef DPU_MOVER_2D
    mover_2d #(.APB_WIDTH_AD      ( P_APB_WIDTH_AD )
              ,.APB_WIDTH_DA      ( P_APB_WIDTH_DA )
              ,.M_AXI_WIDTH_ID    ( P_AXI_WIDTH_ID )
              ,.M_AXI_WIDTH_AD    ( P_AXI_WIDTH_AD )
              ,.M_AXI_WIDTH_DA    ( P_AXI_WIDTH_DA )
              ,.DATA_TYPE         ( P_DATA_TYPE    )
              ,.DATA_WIDTH        ( P_DATA_WIDTH   )
              `ifdef DATA_FIXED_POINT
              ,.DATA_WIDTH_Q      ( P_DATA_WIDTH_Q )
              `endif
              ,.SRC_FIFO_DEPTH    ( P_MOVER_SRC_FIFO_DEPTH    )
              ,.RESULT_FIFO_DEPTH ( P_MOVER_RESULT_FIFO_DEPTH )
              ,.MOVER_COMMAND_NOP       (`MOVER_COMMAND_NOP       )
              ,.MOVER_COMMAND_FILL      (`MOVER_COMMAND_FILL      )
              ,.MOVER_COMMAND_COPY      (`MOVER_COMMAND_COPY      )
              ,.MOVER_COMMAND_RESIDUAL  (`MOVER_COMMAND_RESIDUAL  )
              ,.MOVER_COMMAND_CONCAT0   (`MOVER_COMMAND_CONCAT0   )
              ,.MOVER_COMMAND_CONCAT1   (`MOVER_COMMAND_CONCAT1   )
              ,.MOVER_COMMAND_TRANSPOSE (`MOVER_COMMAND_TRANSPOSE )
              ,.ACTIV_FUNC_BYPASS    (`ACTIV_FUNC_BYPASS     )
              ,.ACTIV_FUNC_RELU      (`ACTIV_FUNC_RELU       )
              ,.ACTIV_FUNC_LEAKY_RELU(`ACTIV_FUNC_LEAKY_RELU )
              ,.ACTIV_FUNC_SIGMOID   (`ACTIV_FUNC_SIGMOID    )
              ,.ACTIV_FUNC_TANH      (`ACTIV_FUNC_TANH       )
              )
    u_mover (
          .PRESETn            ( PRESETn    )
        , .PCLK               ( PCLK       )
        , .S_APB_PSEL         ( PSEL    [4])
        , .S_APB_PENABLE      ( PENABLE    )
        , .S_APB_PADDR        ( PADDR      )
        , .S_APB_PWRITE       ( PWRITE     )
        , .S_APB_PRDATA       ( PRDATA  [4])
        , .S_APB_PWDATA       ( PWDATA     )
        , .S_APB_PREADY       (            )
        , .S_APB_PSLVERR      (            )
        , .ARESETn            ( ARESETn      )
        , .ACLK               ( ACLK         )
        , .M_AXI_RST_AWID     ( M_AWID   [7] )
        , .M_AXI_RST_AWADDR   ( M_AWADDR [7] )
        , .M_AXI_RST_AWLEN    ( M_AWLEN  [7] )
        , .M_AXI_RST_AWSIZE   ( M_AWSIZE [7] )
        , .M_AXI_RST_AWBURST  ( M_AWBURST[7] )
        , .M_AXI_RST_AWVALID  ( M_AWVALID[7] )
        , .M_AXI_RST_AWREADY  ( M_AWREADY[7] )
        , .M_AXI_RST_WDATA    ( M_WDATA  [7] )
        , .M_AXI_RST_WSTRB    ( M_WSTRB  [7] )
        , .M_AXI_RST_WLAST    ( M_WLAST  [7] )
        , .M_AXI_RST_WVALID   ( M_WVALID [7] )
        , .M_AXI_RST_WREADY   ( M_WREADY [7] )
        , .M_AXI_RST_BID      ( M_BID    [7] )
        , .M_AXI_RST_BRESP    ( M_BRESP  [7] )
        , .M_AXI_RST_BVALID   ( M_BVALID [7] )
        , .M_AXI_RST_BREADY   ( M_BREADY [7] )
        , .M_AXI_SRC_ARID     ( M_ARID   [7] )
        , .M_AXI_SRC_ARADDR   ( M_ARADDR [7] )
        , .M_AXI_SRC_ARLEN    ( M_ARLEN  [7] )
        , .M_AXI_SRC_ARSIZE   ( M_ARSIZE [7] )
        , .M_AXI_SRC_ARBURST  ( M_ARBURST[7] )
        , .M_AXI_SRC_ARVALID  ( M_ARVALID[7] )
        , .M_AXI_SRC_ARREADY  ( M_ARREADY[7] )
        , .M_AXI_SRC_RID      ( M_RID    [7] )
        , .M_AXI_SRC_RDATA    ( M_RDATA  [7] )
        , .M_AXI_SRC_RRESP    ( M_RRESP  [7] )
        , .M_AXI_SRC_RLAST    ( M_RLAST  [7] )
        , .M_AXI_SRC_RVALID   ( M_RVALID [7] )
        , .M_AXI_SRC_RREADY   ( M_RREADY [7] )
        , .interrupt          ( interrupt_mover )
    );
`else
    assign M_AWID   [7]= 'h0;
    assign M_AWADDR [7]= 'h0;
    assign M_AWLOCK [7]=1'b0;
    assign M_AWLEN  [7]= 'h0;
    assign M_AWSIZE [7]= 'h0;
    assign M_AWBURST[7]= 'h0;
    assign M_AWVALID[7]=1'b0;
    assign M_WDATA  [7]= 'h0;
    assign M_WSTRB  [7]= 'h0;
    assign M_WLAST  [7]= 'h0;
    assign M_WVALID [7]=1'b0;
    assign M_BREADY [7]=1'b0;
    assign M_ARID   [7]= 'h0;
    assign M_ARADDR [7]= 'h0;
    assign M_ARLOCK [7]=1'b0;
    assign M_ARLEN  [7]= 'h0;
    assign M_ARSIZE [7]= 'h0;
    assign M_ARBURST[7]= 'h0;
    assign M_ARVALID[7]=1'b0;
    assign M_RREADY [7]=1'b1;
`endif

    assign M_AWLOCK[7] = 1'b0;
    assign M_ARLOCK[7] = 1'b0;
