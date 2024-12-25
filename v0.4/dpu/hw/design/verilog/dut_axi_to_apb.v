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
              wire                                   PRESETn ; // see dut_bfm.v
              wire                                   PCLK    ; // see dut_bfm.v
              wire [P_APB_WIDTH_AD-1:0]  `NET_DELAY  PADDR   ;
              wire                       `NET_DELAY  PENABLE ;
              wire                       `NET_DELAY  PWRITE  ;
              wire [P_APB_WIDTH_DA-1:0]  `NET_DELAY  PWDATA  ;
              wire [P_NUM_APB_SLAVE-1:0] `NET_DELAY  PSEL    ;
              wire [P_APB_WIDTH_DA-1:0]  `NET_DELAY  PRDATA  [P_NUM_APB_SLAVE-1:0];
     `ifdef AMBA_APB3
              wire [P_NUM_APB_SLAVE-1:0] `NET_DELAY  PREADY  ;
              wire [P_NUM_APB_SLAVE-1:0] `NET_DELAY  PSLVERR ;
     `endif
     `ifdef AMBA_APB4
              wire [P_APB_WIDTH_DS-1:0]  `NET_DELAY  PSTRB   ;
              wire [ 2:0]                `NET_DELAY  PPROT   ;
     `endif
//------------------------------------------------------------------------------
    axi_to_apb_s5 #(.AXI_WIDTH_SID (P_AXI_WIDTH_SID )
                   ,.AXI_WIDTH_AD  (P_AXI_WIDTH_AD  )
                   ,.AXI_WIDTH_DA  (P_AXI_WIDTH_DA  )
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
                                        .ARESETn   ( ARESETn      )
     ,                                  .ACLK      ( ACLK         )
     ,                                  .AWID      ( S_AWID    [1])
     ,                                  .AWADDR    ( S_AWADDR  [1])
     ,                                  .AWLEN     ( S_AWLEN   [1])
     ,                                  .AWLOCK    ( S_AWLOCK  [1])
     ,                                  .AWSIZE    ( S_AWSIZE  [1])
     ,                                  .AWBURST   ( S_AWBURST [1])
     `ifdef  AMBA_AXI_CACHE
     ,                                  .AWCACHE   ( S_AWCACHE [1])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                                  .AWPROT    ( S_AWPROT  [1])
     `endif
     ,                                  .AWVALID   ( S_AWVALID [1])
     ,                                  .AWREADY   ( S_AWREADY [1])
     `ifdef AMBA_QOS
     ,                                  .AWQOS     ( S_AWQOS   [1])
     ,                                  .AWREGION  ( S_AWREGION[1])
     `endif
     `ifdef AMBA_AXI_AWUSER
     ,                                  .AWUSER    ( S_AWUSER  [1])
     `endif
     ,                                  .WDATA     ( S_WDATA   [1])
     ,                                  .WSTRB     ( S_WSTRB   [1])
     ,                                  .WLAST     ( S_WLAST   [1])
     ,                                  .WVALID    ( S_WVALID  [1])
     ,                                  .WREADY    ( S_WREADY  [1])
     `ifdef AMBA_AXI_WUSER
                                        .WUSER     ( S_WUSER   [1])
     `endif
     ,                                  .BID       ( S_BID     [1])
     ,                                  .BRESP     ( S_BRESP   [1])
     ,                                  .BVALID    ( S_BVALID  [1])
     ,                                  .BREADY    ( S_BREADY  [1])
     `ifdef AMBA_AXI_BUSER
                                        .BUSER     ( S_BUSER   [1])
     `endif
     ,                                  .ARID      ( S_ARID    [1])
     ,                                  .ARADDR    ( S_ARADDR  [1])
     ,                                  .ARLEN     ( S_ARLEN   [1])
     ,                                  .ARLOCK    ( S_ARLOCK  [1])
     ,                                  .ARSIZE    ( S_ARSIZE  [1])
     ,                                  .ARBURST   ( S_ARBURST [1])
     `ifdef  AMBA_AXI_CACHE
     ,                                  .ARCACHE   ( S_ARCACHE [1])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                                  .ARPROT    ( S_ARPROT  [1])
     `endif
     ,                                  .ARVALID   ( S_ARVALID [1])
     ,                                  .ARREADY   ( S_ARREADY [1])
     `ifdef AMBA_QOS
     ,                                  .ARQOS     ( S_ARQOS   [1])
     ,                                  .ARREGION  ( S_ARREGION[1])
     `endif
     `ifdef AMBA_AXI_ARUSER
     ,                                  .ARUSER    ( S_ARUSER  [1])
     `endif
     ,                                  .RID       ( S_RID     [1])
     ,                                  .RDATA     ( S_RDATA   [1])
     ,                                  .RRESP     ( S_RRESP   [1])
     ,                                  .RLAST     ( S_RLAST   [1])
     ,                                  .RVALID    ( S_RVALID  [1])
     ,                                  .RREADY    ( S_RREADY  [1])
     `ifdef AMBA_AXI_RUSER
     ,                                  .RUSER     ( S_RUSER   [1])
     `endif
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
     `ifdef AMBA_APB3                                        
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
     `endif                                                  
     `ifdef AMBA_APB4                                        
     ,                                  .S_PSTRB   ( PSTRB    )
     ,                                  .S_PPROT   ( PPROT    )
     `endif
    );

`ifdef AMBA_APB3                                          
     assign PREADY ={P_NUM_APB_SLAVE{1'b1}};
     assign PSLVERR={P_NUM_APB_SLAVE{1'b0}};
`endif
