
`define DPU_MOVER_2D
`ifdef DPU_MOVER_2D
    assign module_mover=1'b1;
    mover_2d #(.APB_WIDTH_AD      ( P_APB_WIDTH_AD )
              ,.APB_WIDTH_DA      ( P_APB_WIDTH_DA )
              ,.M_AXI_WIDTH_ID    ( M_AXI_WIDTH_ID )
              ,.M_AXI_WIDTH_AD    ( M_AXI_WIDTH_AD )
              ,.M_AXI_WIDTH_DA    ( M_AXI_WIDTH_DA )
              ,.DATA_TYPE         ( P_DATA_TYPE    )
              ,.DATA_WIDTH        ( P_DATA_WIDTH   )
              `ifdef DATA_FIXED_POINT
              ,.DATA_WIDTH_Q      ( P_DATA_WIDTH_Q )
              `endif
            //,.SRC_FIFO_DEPTH    ( P_MOVER_SRC_FIFO_DEPTH    )
            //,.RESULT_FIFO_DEPTH ( P_MOVER_RESULT_FIFO_DEPTH )
            //,.MOVER_COMMAND_NOP       (P_MOVER_COMMAND_NOP       )
            //,.MOVER_COMMAND_FILL      (P_MOVER_COMMAND_FILL      )
            //,.MOVER_COMMAND_COPY      (P_MOVER_COMMAND_COPY      )
            //,.MOVER_COMMAND_RESIDUAL  (P_MOVER_COMMAND_RESIDUAL  )
            //,.MOVER_COMMAND_CONCAT0   (P_MOVER_COMMAND_CONCAT0   )
            //,.MOVER_COMMAND_CONCAT1   (P_MOVER_COMMAND_CONCAT1   )
            //,.MOVER_COMMAND_TRANSPOSE (P_MOVER_COMMAND_TRANSPOSE )
            //,.ACTIV_FUNC_BYPASS       (P_ACTIV_FUNC_BYPASS     )
            //,.ACTIV_FUNC_RELU         (P_ACTIV_FUNC_RELU       )
            //,.ACTIV_FUNC_LEAKY_RELU   (P_ACTIV_FUNC_LEAKY_RELU )
            //,.ACTIV_FUNC_SIGMOID      (P_ACTIV_FUNC_SIGMOID    )
            //,.ACTIV_FUNC_TANH         (P_ACTIV_FUNC_TANH       )
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
        , .S_APB_PREADY       ( PREADY  [4])
        , .S_APB_PSLVERR      ( PSLVERR [4])
        , .ARESETn            ( ARESETn      )
        , .ACLK               ( ACLK         )
        , .M_AXI_RST_AWID     ( m_axi_mover_AWID    )
        , .M_AXI_RST_AWADDR   ( m_axi_mover_AWADDR  )
        , .M_AXI_RST_AWLEN    ( m_axi_mover_AWLEN   )
        , .M_AXI_RST_AWSIZE   ( m_axi_mover_AWSIZE  )
        , .M_AXI_RST_AWBURST  ( m_axi_mover_AWBURST )
        , .M_AXI_RST_AWVALID  ( m_axi_mover_AWVALID )
        , .M_AXI_RST_AWREADY  ( m_axi_mover_AWREADY )
        , .M_AXI_RST_WDATA    ( m_axi_mover_WDATA   )
        , .M_AXI_RST_WSTRB    ( m_axi_mover_WSTRB   )
        , .M_AXI_RST_WLAST    ( m_axi_mover_WLAST   )
        , .M_AXI_RST_WVALID   ( m_axi_mover_WVALID  )
        , .M_AXI_RST_WREADY   ( m_axi_mover_WREADY  )
        , .M_AXI_RST_BID      ( m_axi_mover_BID     )
        , .M_AXI_RST_BRESP    ( m_axi_mover_BRESP   )
        , .M_AXI_RST_BVALID   ( m_axi_mover_BVALID  )
        , .M_AXI_RST_BREADY   ( m_axi_mover_BREADY  )
        , .M_AXI_SRC_ARID     ( m_axi_mover_ARID    )
        , .M_AXI_SRC_ARADDR   ( m_axi_mover_ARADDR  )
        , .M_AXI_SRC_ARLEN    ( m_axi_mover_ARLEN   )
        , .M_AXI_SRC_ARSIZE   ( m_axi_mover_ARSIZE  )
        , .M_AXI_SRC_ARBURST  ( m_axi_mover_ARBURST )
        , .M_AXI_SRC_ARVALID  ( m_axi_mover_ARVALID )
        , .M_AXI_SRC_ARREADY  ( m_axi_mover_ARREADY )
        , .M_AXI_SRC_RID      ( m_axi_mover_RID     )
        , .M_AXI_SRC_RDATA    ( m_axi_mover_RDATA   )
        , .M_AXI_SRC_RRESP    ( m_axi_mover_RRESP   )
        , .M_AXI_SRC_RLAST    ( m_axi_mover_RLAST   )
        , .M_AXI_SRC_RVALID   ( m_axi_mover_RVALID  )
        , .M_AXI_SRC_RREADY   ( m_axi_mover_RREADY  )
        , .interrupt          ( interrupt_mover )
    );
`else
    assign module_mover=1'b0;
    assign m_axi_mover_AWID   ={M_AXI_WIDTH_ID{1'b0}};
    assign m_axi_mover_AWADDR ={M_AXI_WIDTH_AD{1'b0}};
    assign m_axi_mover_AWLEN  =8'h0;
    assign m_axi_mover_AWSIZE =3'h0;
    assign m_axi_mover_AWBURST=2'h0;
    assign m_axi_mover_AWVALID=1'b0;
    assign m_axi_mover_WDATA  ={M_AXI_WIDTH_DA{1'b0}};
    assign m_axi_mover_WSTRB  ={M_AXI_WIDTH_DS{1'b0}};
    assign m_axi_mover_WLAST  =1'b0
    assign m_axi_mover_WVALID =1'b0;
    assign m_axi_mover_BREADY =1'b0;
    assign m_axi_mover_ARID   ={M_AXI_WIDTH_ID{1'b0}};
    assign m_axi_mover_ARADDR ={M_AXI_WIDTH_AD{1'b0}};
    assign m_axi_mover_ARLEN  =8'h0;
    assign m_axi_mover_ARSIZE =3'h0;
    assign m_axi_mover_ARBURST=2'h0;
    assign m_axi_mover_ARVALID=1'b0;
    assign m_axi_mover_RREADY =1'b1;
    assign interrupt_mover    =1'b0;
`endif
