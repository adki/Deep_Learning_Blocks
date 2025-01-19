
    assign module_convolution = 1'b1;
    convolution_2d #(.APB_WIDTH_AD      ( P_APB_WIDTH_AD )
                    ,.APB_WIDTH_DA      ( P_APB_WIDTH_DA )
                    ,.M_AXI_WIDTH_ID    ( M_AXI_WIDTH_ID )
                    ,.M_AXI_WIDTH_AD    ( M_AXI_WIDTH_AD )
                    ,.M_AXI_WIDTH_DA    ( M_AXI_WIDTH_DA )
                    ,.DATA_TYPE         ( P_DATA_TYPE    )
                    ,.DATA_WIDTH        ( P_DATA_WIDTH   )
                    `ifdef DATA_FIXED_POINT
                    ,.DATA_WIDTH_Q      ( P_DATA_WIDTH_Q )
                    `endif
                  //,.KERNEL_MAX_SIZE   ( P_CONV_KERNEL_MAX_SIZE    )
                  //,.KERNEL_FIFO_DEPTH ( P_CONV_KERNEL_FIFO_DEPTH  )
                  //,.FEATURE_FIFO_DEPTH( P_CONV_FEATURE_FIFO_DEPTH )
                  //,.CHANNEL_FIFO_DEPTH( P_CONV_CHANNEL_FIFO_DEPTH )
                  //,.RESULT_FIFO_DEPTH ( P_CONV_RESULT_FIFO_DEPTH  )
                  //,.ACTIV_FUNC_BYPASS    (P_ACTIV_FUNC_BYPASS     )
                  //,.ACTIV_FUNC_RELU      (P_ACTIV_FUNC_RELU       )
                  //,.ACTIV_FUNC_LEAKY_RELU(P_ACTIV_FUNC_LEAKY_RELU )
                  //,.ACTIV_FUNC_SIGMOID   (P_ACTIV_FUNC_SIGMOID    )
                  //,.ACTIV_FUNC_TANH      (P_ACTIV_FUNC_TANH       )
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
        , .S_APB_PREADY       ( PREADY  [1])
        , .S_APB_PSLVERR      ( PSLVERR [1])
        , .ARESETn            ( ARESETn      )
        , .ACLK               ( ACLK         )
        , .M_AXI_RST_AWID     ( m_axi_conv_rst_AWID    )
        , .M_AXI_RST_AWADDR   ( m_axi_conv_rst_AWADDR  )
        , .M_AXI_RST_AWLEN    ( m_axi_conv_rst_AWLEN   )
        , .M_AXI_RST_AWSIZE   ( m_axi_conv_rst_AWSIZE  )
        , .M_AXI_RST_AWBURST  ( m_axi_conv_rst_AWBURST )
        , .M_AXI_RST_AWVALID  ( m_axi_conv_rst_AWVALID )
        , .M_AXI_RST_AWREADY  ( m_axi_conv_rst_AWREADY )
        , .M_AXI_RST_WDATA    ( m_axi_conv_rst_WDATA   )
        , .M_AXI_RST_WSTRB    ( m_axi_conv_rst_WSTRB   )
        , .M_AXI_RST_WLAST    ( m_axi_conv_rst_WLAST   )
        , .M_AXI_RST_WVALID   ( m_axi_conv_rst_WVALID  )
        , .M_AXI_RST_WREADY   ( m_axi_conv_rst_WREADY  )
        , .M_AXI_RST_BID      ( m_axi_conv_rst_BID     )
        , .M_AXI_RST_BRESP    ( m_axi_conv_rst_BRESP   )
        , .M_AXI_RST_BVALID   ( m_axi_conv_rst_BVALID  )
        , .M_AXI_RST_BREADY   ( m_axi_conv_rst_BREADY  )
        , .M_AXI_CHN_ARID     ( m_axi_conv_rst_ARID    )
        , .M_AXI_CHN_ARADDR   ( m_axi_conv_rst_ARADDR  )
        , .M_AXI_CHN_ARLEN    ( m_axi_conv_rst_ARLEN   )
        , .M_AXI_CHN_ARSIZE   ( m_axi_conv_rst_ARSIZE  )
        , .M_AXI_CHN_ARBURST  ( m_axi_conv_rst_ARBURST )
        , .M_AXI_CHN_ARVALID  ( m_axi_conv_rst_ARVALID )
        , .M_AXI_CHN_ARREADY  ( m_axi_conv_rst_ARREADY )
        , .M_AXI_CHN_RID      ( m_axi_conv_rst_RID     )
        , .M_AXI_CHN_RDATA    ( m_axi_conv_rst_RDATA   )
        , .M_AXI_CHN_RRESP    ( m_axi_conv_rst_RRESP   )
        , .M_AXI_CHN_RLAST    ( m_axi_conv_rst_RLAST   )
        , .M_AXI_CHN_RVALID   ( m_axi_conv_rst_RVALID  )
        , .M_AXI_CHN_RREADY   ( m_axi_conv_rst_RREADY  )
        , .M_AXI_KNL_ARID     ( m_axi_conv_knl_ARID    )
        , .M_AXI_KNL_ARADDR   ( m_axi_conv_knl_ARADDR  )
        , .M_AXI_KNL_ARLEN    ( m_axi_conv_knl_ARLEN   )
        , .M_AXI_KNL_ARSIZE   ( m_axi_conv_knl_ARSIZE  )
        , .M_AXI_KNL_ARBURST  ( m_axi_conv_knl_ARBURST )
        , .M_AXI_KNL_ARVALID  ( m_axi_conv_knl_ARVALID )
        , .M_AXI_KNL_ARREADY  ( m_axi_conv_knl_ARREADY )
        , .M_AXI_KNL_RID      ( m_axi_conv_knl_RID     )
        , .M_AXI_KNL_RDATA    ( m_axi_conv_knl_RDATA   )
        , .M_AXI_KNL_RRESP    ( m_axi_conv_knl_RRESP   )
        , .M_AXI_KNL_RLAST    ( m_axi_conv_knl_RLAST   )
        , .M_AXI_KNL_RVALID   ( m_axi_conv_knl_RVALID  )
        , .M_AXI_KNL_RREADY   ( m_axi_conv_knl_RREADY  )
        , .M_AXI_FTU_ARID     ( m_axi_conv_ftu_ARID    )
        , .M_AXI_FTU_ARADDR   ( m_axi_conv_ftu_ARADDR  )
        , .M_AXI_FTU_ARLEN    ( m_axi_conv_ftu_ARLEN   )
        , .M_AXI_FTU_ARSIZE   ( m_axi_conv_ftu_ARSIZE  )
        , .M_AXI_FTU_ARBURST  ( m_axi_conv_ftu_ARBURST )
        , .M_AXI_FTU_ARVALID  ( m_axi_conv_ftu_ARVALID )
        , .M_AXI_FTU_ARREADY  ( m_axi_conv_ftu_ARREADY )
        , .M_AXI_FTU_RID      ( m_axi_conv_ftu_RID     )
        , .M_AXI_FTU_RDATA    ( m_axi_conv_ftu_RDATA   )
        , .M_AXI_FTU_RRESP    ( m_axi_conv_ftu_RRESP   )
        , .M_AXI_FTU_RLAST    ( m_axi_conv_ftu_RLAST   )
        , .M_AXI_FTU_RVALID   ( m_axi_conv_ftu_RVALID  )
        , .M_AXI_FTU_RREADY   ( m_axi_conv_ftu_RREADY  )
        , .interrupt          ( interrupt_conv    )
    );
    assign m_axi_conv_knl_AWID   ={M_AXI_WIDTH_ID{1'b0}}; // kernel read only
    assign m_axi_conv_knl_AWADDR ={M_AXI_WIDTH_AD{1'b0}};
    assign m_axi_conv_knl_AWLEN  =8'b0;
    assign m_axi_conv_knl_AWSIZE =3'b0;
    assign m_axi_conv_knl_AWBURST=2'b0;
    assign m_axi_conv_knl_AWVALID=1'b0;
    assign m_axi_conv_knl_WDATA  ={M_AXI_WIDTH_DA{1'b0}};
    assign m_axi_conv_knl_WSTRB  ={M_AXI_WIDTH_DS{1'b0}};
    assign m_axi_conv_knl_WLAST  =1'b0;
    assign m_axi_conv_knl_WVALID =1'b0;
    assign m_axi_conv_knl_BREADY =1'b0;
    assign m_axi_conv_ftu_AWID   ={M_AXI_WIDTH_ID{1'b0}}; // feature map read only
    assign m_axi_conv_ftu_AWADDR ={M_AXI_WIDTH_AD{1'b0}};
    assign m_axi_conv_ftu_AWLEN  =8'b0;
    assign m_axi_conv_ftu_AWSIZE =3'b0;
    assign m_axi_conv_ftu_AWBURST=2'b0;
    assign m_axi_conv_ftu_AWVALID=1'b0;
    assign m_axi_conv_ftu_WDATA  ={M_AXI_WIDTH_DA{1'b0}};
    assign m_axi_conv_ftu_WSTRB  ={M_AXI_WIDTH_DS{1'b0}};
    assign m_axi_conv_ftu_WLAST  =1'b0;
    assign m_axi_conv_ftu_WVALID =1'b0;
    assign m_axi_conv_ftu_BREADY =1'b0;
