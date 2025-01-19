
    assign module_linear=1'b1;
    linear_1d #(.APB_WIDTH_AD      ( P_APB_WIDTH_AD )
               ,.APB_WIDTH_DA      ( P_APB_WIDTH_DA )
               ,.M_AXI_WIDTH_ID    ( M_AXI_WIDTH_ID )
               ,.M_AXI_WIDTH_AD    ( M_AXI_WIDTH_AD )
               ,.M_AXI_WIDTH_DA    ( M_AXI_WIDTH_DA )
               ,.DATA_TYPE         ( P_DATA_TYPE    )
               ,.DATA_WIDTH        ( P_DATA_WIDTH   )
               `ifdef LINEAR_FIXED_POINT
               ,.DATA_WIDTH_Q      ( P_DATA_WIDTH_Q )
               `endif
             //,.INPUT_FIFO_DEPTH  ( P_LINEAR_INPUT_FIFO_DEPTH  )
             //,.WEIGHT_FIFO_DEPTH ( P_LINEAR_WEIGHT_FIFO_DEPTH )
             //,.RESULT_FIFO_DEPTH ( P_LINEAR_RESULT_FIFO_DEPTH )
             //,.ACTIV_FUNC_BYPASS    (P_ACTIV_FUNC_BYPASS     )
             //,.ACTIV_FUNC_RELU      (P_ACTIV_FUNC_RELU       )
             //,.ACTIV_FUNC_LEAKY_RELU(P_ACTIV_FUNC_LEAKY_RELU )
             //,.ACTIV_FUNC_SIGMOID   (P_ACTIV_FUNC_SIGMOID    )
             //,.ACTIV_FUNC_TANH      (P_ACTIV_FUNC_TANH       )
               )
    u_linear (
          .PRESETn            ( PRESETn    )
        , .PCLK               ( PCLK       )
        , .S_APB_PSEL         ( PSEL    [3])
        , .S_APB_PENABLE      ( PENABLE    )
        , .S_APB_PADDR        ( PADDR      )
        , .S_APB_PWRITE       ( PWRITE     )
        , .S_APB_PRDATA       ( PRDATA  [3])
        , .S_APB_PWDATA       ( PWDATA     )
        , .S_APB_PREADY       ( PREADY  [3])
        , .S_APB_PSLVERR      ( PSLVERR [3])
        , .ARESETn            ( ARESETn      )
        , .ACLK               ( ACLK         )
        , .M_AXI_RST_AWID         ( m_axi_linear_rst_AWID       )
        , .M_AXI_RST_AWADDR       ( m_axi_linear_rst_AWADDR     )
        , .M_AXI_RST_AWLEN        ( m_axi_linear_rst_AWLEN      )
        , .M_AXI_RST_AWSIZE       ( m_axi_linear_rst_AWSIZE     )
        , .M_AXI_RST_AWBURST      ( m_axi_linear_rst_AWBURST    )
        , .M_AXI_RST_AWVALID      ( m_axi_linear_rst_AWVALID    )
        , .M_AXI_RST_AWREADY      ( m_axi_linear_rst_AWREADY    )
        , .M_AXI_RST_WDATA        ( m_axi_linear_rst_WDATA      )
        , .M_AXI_RST_WSTRB        ( m_axi_linear_rst_WSTRB      )
        , .M_AXI_RST_WLAST        ( m_axi_linear_rst_WLAST      )
        , .M_AXI_RST_WVALID       ( m_axi_linear_rst_WVALID     )
        , .M_AXI_RST_WREADY       ( m_axi_linear_rst_WREADY     )
        , .M_AXI_RST_BID          ( m_axi_linear_rst_BID        )
        , .M_AXI_RST_BRESP        ( m_axi_linear_rst_BRESP      )
        , .M_AXI_RST_BVALID       ( m_axi_linear_rst_BVALID     )
        , .M_AXI_RST_BREADY       ( m_axi_linear_rst_BREADY     )
        , .M_AXI_INPUT_ARID       ( m_axi_linear_rst_ARID       )
        , .M_AXI_INPUT_ARADDR     ( m_axi_linear_rst_ARADDR     )
        , .M_AXI_INPUT_ARLEN      ( m_axi_linear_rst_ARLEN      )
        , .M_AXI_INPUT_ARSIZE     ( m_axi_linear_rst_ARSIZE     )
        , .M_AXI_INPUT_ARBURST    ( m_axi_linear_rst_ARBURST    )
        , .M_AXI_INPUT_ARVALID    ( m_axi_linear_rst_ARVALID    )
        , .M_AXI_INPUT_ARREADY    ( m_axi_linear_rst_ARREADY    )
        , .M_AXI_INPUT_RID        ( m_axi_linear_rst_RID        )
        , .M_AXI_INPUT_RDATA      ( m_axi_linear_rst_RDATA      )
        , .M_AXI_INPUT_RRESP      ( m_axi_linear_rst_RRESP      )
        , .M_AXI_INPUT_RLAST      ( m_axi_linear_rst_RLAST      )
        , .M_AXI_INPUT_RVALID     ( m_axi_linear_rst_RVALID     )
        , .M_AXI_INPUT_RREADY     ( m_axi_linear_rst_RREADY     )
        , .M_AXI_WEIGHT_ARID      ( m_axi_linear_weight_ARID    )
        , .M_AXI_WEIGHT_ARADDR    ( m_axi_linear_weight_ARADDR  )
        , .M_AXI_WEIGHT_ARLEN     ( m_axi_linear_weight_ARLEN   )
        , .M_AXI_WEIGHT_ARSIZE    ( m_axi_linear_weight_ARSIZE  )
        , .M_AXI_WEIGHT_ARBURST   ( m_axi_linear_weight_ARBURST )
        , .M_AXI_WEIGHT_ARVALID   ( m_axi_linear_weight_ARVALID )
        , .M_AXI_WEIGHT_ARREADY   ( m_axi_linear_weight_ARREADY )
        , .M_AXI_WEIGHT_RID       ( m_axi_linear_weight_RID     )
        , .M_AXI_WEIGHT_RDATA     ( m_axi_linear_weight_RDATA   )
        , .M_AXI_WEIGHT_RRESP     ( m_axi_linear_weight_RRESP   )
        , .M_AXI_WEIGHT_RLAST     ( m_axi_linear_weight_RLAST   )
        , .M_AXI_WEIGHT_RVALID    ( m_axi_linear_weight_RVALID  )
        , .M_AXI_WEIGHT_RREADY    ( m_axi_linear_weight_RREADY  )
        , .interrupt              ( interrupt_linear )
    );
    assign m_axi_linear_weight_AWID   ={M_AXI_WIDTH_ID{1'b0}}; // weight read-only
    assign m_axi_linear_weight_AWADDR ={M_AXI_WIDTH_AD{1'b0}};
    assign m_axi_linear_weight_AWLEN  =8'h0;
    assign m_axi_linear_weight_AWSIZE =3'h0;
    assign m_axi_linear_weight_AWBURST=2'h0;
    assign m_axi_linear_weight_AWVALID=1'b0;
    assign m_axi_linear_weight_WDATA  ={M_AXI_WIDTH_DA{1'b0}};
    assign m_axi_linear_weight_WSTRB  ={M_AXI_WIDTH_DS{1'b0}};
    assign m_axi_linear_weight_WLAST  =1'b0;
    assign m_axi_linear_weight_WVALID =1'b0;
    assign m_axi_linear_weight_BREADY =1'b0;
