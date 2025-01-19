//------------------------------------------------------------------------------
    localparam P_NUM_APB_SLAVE= 5
             , P_APB_WIDTH_AD =32
             , P_APB_WIDTH_DA =32
             , P_APB_WIDTH_DS =(P_APB_WIDTH_DA/8);
//------------------------------------------------------------------------------
`ifdef SIM
`ifdef __ICARUS__
`define NET_DELAY 
`else
`define NET_DELAY  #(1)
`endif
`else
`define NET_DELAY 
`endif
//------------------------------------------------------------------------------
              wire                                   PRESETn = ARESETn;
              wire                                   PCLK    = ACLK   ;
              wire [P_APB_WIDTH_AD-1:0]  `NET_DELAY  PADDR   ;
              wire                       `NET_DELAY  PENABLE ;
              wire                       `NET_DELAY  PWRITE  ;
              wire [P_APB_WIDTH_DA-1:0]  `NET_DELAY  PWDATA  ;
              wire [P_NUM_APB_SLAVE-1:0] `NET_DELAY  PSEL    ;
              wire [P_APB_WIDTH_DA-1:0]  `NET_DELAY  PRDATA  [P_NUM_APB_SLAVE-1:0];
              wire [P_NUM_APB_SLAVE-1:0] `NET_DELAY  PREADY  ;
              wire [P_NUM_APB_SLAVE-1:0] `NET_DELAY  PSLVERR ;
//------------------------------------------------------------------------------
    axi_to_apb_s5 #(.AXI_WIDTH_SID (S_AXI_WIDTH_ID  )
                   ,.AXI_WIDTH_AD  (S_AXI_WIDTH_AD  )
                   ,.AXI_WIDTH_DA  (S_AXI_WIDTH_DA  )
                   ,.NUM_PSLAVE    (P_NUM_APB_SLAVE )
                   ,.WIDTH_PAD     (P_APB_WIDTH_AD  )
                   ,.WIDTH_PDA     (P_APB_WIDTH_DA  )
                   ,.ADDR_PBASE0(P_ADDR_BASE_CONF  ),.ADDR_PLENGTH0($clog2(P_SIZE_CONF ))
                   ,.ADDR_PBASE1(P_ADDR_BASE_CONV  ),.ADDR_PLENGTH1($clog2(P_SIZE_CONV ))
                   ,.ADDR_PBASE2(P_ADDR_BASE_POOL  ),.ADDR_PLENGTH2($clog2(P_SIZE_POOL ))
                   ,.ADDR_PBASE3(P_ADDR_BASE_LINEAR),.ADDR_PLENGTH3($clog2(P_SIZE_LINEAR))
                   ,.ADDR_PBASE4(P_ADDR_BASE_MOVER ),.ADDR_PLENGTH4($clog2(P_SIZE_MOVER ))
                   ,.CLOCK_RATIO  (2'b00) // 0=1:1, 3=async
                   )
    u_axi_to_apb (
                                        .ARESETn   ( ARESETn       )
     ,                                  .ACLK      ( ACLK          )
     ,                                  .AWID      ( s_axi_AWID    )
     ,                                  .AWADDR    ( s_axi_AWADDR  )
     ,                                  .AWLEN     ( s_axi_AWLEN   )
     ,                                  .AWLOCK    ( 1'b0          )
     ,                                  .AWSIZE    ( s_axi_AWSIZE  )
     ,                                  .AWBURST   ( s_axi_AWBURST )
     ,                                  .AWVALID   ( s_axi_AWVALID )
     ,                                  .AWREADY   ( s_axi_AWREADY )
     ,                                  .WDATA     ( s_axi_WDATA   )
     ,                                  .WSTRB     ( s_axi_WSTRB   )
     ,                                  .WLAST     ( s_axi_WLAST   )
     ,                                  .WVALID    ( s_axi_WVALID  )
     ,                                  .WREADY    ( s_axi_WREADY  )
     ,                                  .BID       ( s_axi_BID     )
     ,                                  .BRESP     ( s_axi_BRESP   )
     ,                                  .BVALID    ( s_axi_BVALID  )
     ,                                  .BREADY    ( s_axi_BREADY  )
     ,                                  .ARID      ( s_axi_ARID    )
     ,                                  .ARADDR    ( s_axi_ARADDR  )
     ,                                  .ARLEN     ( s_axi_ARLEN   )
     ,                                  .ARLOCK    ( 1'b0          )
     ,                                  .ARSIZE    ( s_axi_ARSIZE  )
     ,                                  .ARBURST   ( s_axi_ARBURST )
     ,                                  .ARVALID   ( s_axi_ARVALID )
     ,                                  .ARREADY   ( s_axi_ARREADY )
     ,                                  .RID       ( s_axi_RID     )
     ,                                  .RDATA     ( s_axi_RDATA   )
     ,                                  .RRESP     ( s_axi_RRESP   )
     ,                                  .RLAST     ( s_axi_RLAST   )
     ,                                  .RVALID    ( s_axi_RVALID  )
     ,                                  .RREADY    ( s_axi_RREADY  )
     ,                                  .PRESETn   ( PRESETn    )
     ,                                  .PCLK      ( PCLK       )
     ,                                  .S_PADDR   ( PADDR      )
     ,                                  .S_PENABLE ( PENABLE    )
     ,                                  .S_PWRITE  ( PWRITE     )
     ,                                  .S_PWDATA  ( PWDATA     )
     ,                                  .S0_PSEL   ( PSEL    [0])
     ,                                  .S0_PRDATA ( PRDATA  [0])
     ,                                  .S1_PSEL   ( PSEL    [1])
     ,                                  .S1_PRDATA ( PRDATA  [1])
     ,                                  .S2_PSEL   ( PSEL    [2])
     ,                                  .S2_PRDATA ( PRDATA  [2])
     ,                                  .S3_PSEL   ( PSEL    [3])
     ,                                  .S3_PRDATA ( PRDATA  [3])
     ,                                  .S4_PSEL   ( PSEL    [4])
     ,                                  .S4_PRDATA ( PRDATA  [4])
     ,                                  .S0_PREADY ( PREADY  [0])
     ,                                  .S0_PSLVERR( PSLVERR [0])
     ,                                  .S1_PREADY ( PREADY  [1])
     ,                                  .S1_PSLVERR( PSLVERR [1])
     ,                                  .S2_PREADY ( PREADY  [2])
     ,                                  .S2_PSLVERR( PSLVERR [2])
     ,                                  .S3_PREADY ( PREADY  [3])
     ,                                  .S3_PSLVERR( PSLVERR [3])
     ,                                  .S4_PREADY ( PREADY  [4])
     ,                                  .S4_PSLVERR( PSLVERR [4])
    );
