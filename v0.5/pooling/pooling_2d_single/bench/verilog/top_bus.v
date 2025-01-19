//------------------------------------------------------------------------------
    localparam P_NUM_MASTER  = 2; // should not be changed
    localparam P_NUM_SLAVE   = 2; // should not be changed
    localparam P_WIDTH_CID   =$clog2(P_NUM_MASTER);// ID width in bits
    localparam P_WIDTH_ID    = 4;                   // ID width in bits
    localparam P_WIDTH_AD    =32;// address width
    localparam P_WIDTH_DA    =32;// data width
    localparam P_WIDTH_DS    =(P_WIDTH_DA/8); // data strobe width
    localparam P_WIDTH_SID   =(P_WIDTH_CID+P_WIDTH_ID);// ID for slave
    `ifdef AMBA_AXI_AWUSER
    localparam P_WIDTH_AWUSER= 1;// Write-address user path
    `endif
    `ifdef AMBA_AXI_WUSER
    localparam P_WIDTH_WUSER = 1;// Write-data user path
    `endif
    `ifdef AMBA_AXI_BUSER
    localparam P_WIDTH_BUSER = 1;// Write-response user path
    `endif
    `ifdef AMBA_AXI_ARUSER
    localparam P_WIDTH_ARUSER= 1;// read-address user path
    `endif
    `ifdef AMBA_AXI_RUSER
    localparam P_WIDTH_RUSER = 1;// read-data user path
    `endif
//------------------------------------------------------------------------------
`ifdef __ICARUS__
`define NET_DELAY 
`else
`define NET_DELAY  #(1)
`endif
//------------------------------------------------------------------------------
               wire  [P_WIDTH_ID-1:0]      `NET_DELAY   M_AWID      [P_NUM_MASTER-1:0];
               wire  [P_WIDTH_AD-1:0]      `NET_DELAY   M_AWADDR    [P_NUM_MASTER-1:0];
               wire  [ 7:0]                `NET_DELAY   M_AWLEN     [P_NUM_MASTER-1:0];
               wire  [P_NUM_MASTER-1:0]    `NET_DELAY   M_AWLOCK='h0;
               wire  [ 2:0]                `NET_DELAY   M_AWSIZE    [P_NUM_MASTER-1:0];
               wire  [ 1:0]                `NET_DELAY   M_AWBURST   [P_NUM_MASTER-1:0];
     `ifdef  AMBA_AXI_CACHE
               wire  [ 3:0]                `NET_DELAY   M_AWCACHE   [P_NUM_MASTER-1:0];
     `endif
     `ifdef AMBA_AXI_PROT
               wire  [ 2:0]                `NET_DELAY   M_AWPROT    [P_NUM_MASTER-1:0];
     `endif
               wire  [P_NUM_MASTER-1:0]    `NET_DELAY   M_AWVALID   ;
               wire  [P_NUM_MASTER-1:0]    `NET_DELAY   M_AWREADY   ;
     `ifdef AMBA_QOS
               wire  [ 3:0]                `NET_DELAY   M_AWQOS     [P_NUM_MASTER-1:0];
               wire  [ 3:0]                `NET_DELAY   M_AWREGION  [P_NUM_MASTER-1:0];
     `endif
     `ifdef AMBA_AXI_AWUSER
               wire  [P_WIDTH_AWUSER-1:0]  `NET_DELAY   M_AWUSER    [P_NUM_MASTER-1:0];
     `endif
               wire  [P_WIDTH_DA-1:0]      `NET_DELAY   M_WDATA     [P_NUM_MASTER-1:0];
               wire  [P_WIDTH_DS-1:0]      `NET_DELAY   M_WSTRB     [P_NUM_MASTER-1:0];
               wire  [P_NUM_MASTER-1:0]    `NET_DELAY   M_WLAST     ;
               wire  [P_NUM_MASTER-1:0]    `NET_DELAY   M_WVALID    ;
               wire  [P_NUM_MASTER-1:0]    `NET_DELAY   M_WREADY    ;
     `ifdef AMBA_AXI_WUSER
               wire  [P_WIDTH_WUSER-1:0]   `NET_DELAY   M_WUSER     [P_NUM_MASTER-1:0];
     `endif
               wire  [P_WIDTH_ID-1:0]      `NET_DELAY   M_BID       [P_NUM_MASTER-1:0];
               wire  [ 1:0]                `NET_DELAY   M_BRESP     [P_NUM_MASTER-1:0];
               wire  [P_NUM_MASTER-1:0]    `NET_DELAY   M_BVALID    ;
               wire  [P_NUM_MASTER-1:0]    `NET_DELAY   M_BREADY    ;
     `ifdef AMBA_AXI_BUSER
               wire  [P_WIDTH_BUSER-1:0]   `NET_DELAY   M_BUSER     [P_NUM_MASTER-1:0];
     `endif
               wire  [P_WIDTH_ID-1:0]      `NET_DELAY   M_ARID      [P_NUM_MASTER-1:0];
               wire  [P_WIDTH_AD-1:0]      `NET_DELAY   M_ARADDR    [P_NUM_MASTER-1:0];
               wire  [ 7:0]                `NET_DELAY   M_ARLEN     [P_NUM_MASTER-1:0];
               wire  [P_NUM_MASTER-1:0]    `NET_DELAY   M_ARLOCK    ='h0;
               wire  [ 2:0]                `NET_DELAY   M_ARSIZE    [P_NUM_MASTER-1:0];
               wire  [ 1:0]                `NET_DELAY   M_ARBURST   [P_NUM_MASTER-1:0];
     `ifdef  AMBA_AXI_CACHE
               wire  [ 3:0]                `NET_DELAY   M_ARCACHE   [P_NUM_MASTER-1:0];
     `endif
     `ifdef AMBA_AXI_PROT
               wire  [ 2:0]                `NET_DELAY   M_ARPROT    [P_NUM_MASTER-1:0];
     `endif
               wire  [P_NUM_MASTER-1:0]    `NET_DELAY   M_ARVALID   ;
               wire  [P_NUM_MASTER-1:0]    `NET_DELAY   M_ARREADY   ;
     `ifdef AMBA_QOS
               wire  [ 3:0]                `NET_DELAY   M_ARQOS     [P_NUM_MASTER-1:0];
               wire  [ 3:0]                `NET_DELAY   M_ARREGION  [P_NUM_MASTER-1:0];
     `endif
     `ifdef AMBA_AXI_ARUSER
               wire  [P_WIDTH_ARUSER-1:0]  `NET_DELAY   M_ARUSER    [P_NUM_MASTER-1:0];
     `endif
               wire  [P_WIDTH_ID-1:0]      `NET_DELAY   M_RID       [P_NUM_MASTER-1:0];
               wire  [P_WIDTH_DA-1:0]      `NET_DELAY   M_RDATA     [P_NUM_MASTER-1:0];
               wire  [ 1:0]                `NET_DELAY   M_RRESP     [P_NUM_MASTER-1:0];
               wire  [P_NUM_MASTER-1:0]    `NET_DELAY   M_RLAST     ;
               wire  [P_NUM_MASTER-1:0]    `NET_DELAY   M_RVALID    ;
               wire  [P_NUM_MASTER-1:0]    `NET_DELAY   M_RREADY    ;
     `ifdef AMBA_AXI_RUSER
               wire  [P_WIDTH_RUSER-1:0]   `NET_DELAY   M_RUSER     [P_NUM_MASTER-1:0];
     `endif
//-----------------------------------------`NET_DELAY  ---------------------------------
               wire   [P_WIDTH_SID-1:0]    `NET_DELAY   S_AWID      [P_NUM_SLAVE-1:0];
               wire   [P_WIDTH_AD-1:0]     `NET_DELAY   S_AWADDR    [P_NUM_SLAVE-1:0];
               wire   [ 7:0]               `NET_DELAY   S_AWLEN     [P_NUM_SLAVE-1:0];
               wire                        `NET_DELAY   S_AWLOCK    [P_NUM_SLAVE-1:0];
               wire   [ 2:0]               `NET_DELAY   S_AWSIZE    [P_NUM_SLAVE-1:0];
               wire   [ 1:0]               `NET_DELAY   S_AWBURST   [P_NUM_SLAVE-1:0];
     `ifdef  AMBA_AXI_CACHE
               wire   [ 3:0]               `NET_DELAY   S_AWCACHE   [P_NUM_SLAVE-1:0];
     `endif
     `ifdef AMBA_AXI_PROT
               wire   [ 2:0]               `NET_DELAY   S_AWPROT    [P_NUM_SLAVE-1:0];
     `endif
               wire                        `NET_DELAY   S_AWVALID   [P_NUM_SLAVE-1:0];
               wire                        `NET_DELAY   S_AWREADY   [P_NUM_SLAVE-1:0];
     `ifdef AMBA_QOS
               wire   [ 3:0]               `NET_DELAY   S_AWQOS     [P_NUM_SLAVE-1:0];
               wire   [ 3:0]               `NET_DELAY   S_AWREGION  [P_NUM_SLAVE-1:0];
     `endif
     `ifdef AMBA_AXI_AWUSER
               wire   [P_WIDTH_AWUSER-1:0] `NET_DELAY   S_AWUSER    [P_NUM_SLAVE-1:0];
     `endif
               wire   [P_WIDTH_DA-1:0]     `NET_DELAY   S_WDATA     [P_NUM_SLAVE-1:0];
               wire   [P_WIDTH_DS-1:0]     `NET_DELAY   S_WSTRB     [P_NUM_SLAVE-1:0];
               wire                        `NET_DELAY   S_WLAST     [P_NUM_SLAVE-1:0];
               wire                        `NET_DELAY   S_WVALID    [P_NUM_SLAVE-1:0];
               wire                        `NET_DELAY   S_WREADY    [P_NUM_SLAVE-1:0];
     `ifdef AMBA_AXI_WUSER
               wire   [P_WIDTH_WUSER-1:0]  `NET_DELAY   S_WUSER     [P_NUM_SLAVE-1:0];
     `endif
               wire   [P_WIDTH_SID-1:0]    `NET_DELAY   S_BID       [P_NUM_SLAVE-1:0];
               wire   [ 1:0]               `NET_DELAY   S_BRESP     [P_NUM_SLAVE-1:0];
               wire                        `NET_DELAY   S_BVALID    [P_NUM_SLAVE-1:0];
               wire                        `NET_DELAY   S_BREADY    [P_NUM_SLAVE-1:0];
     `ifdef AMBA_AXI_BUSER
               wire   [P_WIDTH_BUSER-1:0]  `NET_DELAY   S_BUSER     [P_NUM_SLAVE-1:0];
     `endif
               wire   [P_WIDTH_SID-1:0]    `NET_DELAY   S_ARID      [P_NUM_SLAVE-1:0];
               wire   [P_WIDTH_AD-1:0]     `NET_DELAY   S_ARADDR    [P_NUM_SLAVE-1:0];
               wire   [ 7:0]               `NET_DELAY   S_ARLEN     [P_NUM_SLAVE-1:0];
               wire                        `NET_DELAY   S_ARLOCK    [P_NUM_SLAVE-1:0];
               wire   [ 2:0]               `NET_DELAY   S_ARSIZE    [P_NUM_SLAVE-1:0];
               wire   [ 1:0]               `NET_DELAY   S_ARBURST   [P_NUM_SLAVE-1:0];
     `ifdef  AMBA_AXI_CACHE
               wire   [ 3:0]               `NET_DELAY   S_ARCACHE   [P_NUM_SLAVE-1:0];
     `endif
     `ifdef AMBA_AXI_PROT
               wire   [ 2:0]               `NET_DELAY   S_ARPROT    [P_NUM_SLAVE-1:0];
     `endif
               wire                        `NET_DELAY   S_ARVALID   [P_NUM_SLAVE-1:0];
               wire                        `NET_DELAY   S_ARREADY   [P_NUM_SLAVE-1:0];
     `ifdef AMBA_QOS
               wire   [ 3:0]               `NET_DELAY   S_ARQOS     [P_NUM_SLAVE-1:0];
               wire   [ 3:0]               `NET_DELAY   S_ARREGION  [P_NUM_SLAVE-1:0];
     `endif
     `ifdef AMBA_AXI_ARUSER
               wire   [P_WIDTH_ARUSER-1:0] `NET_DELAY   S_ARUSER    [P_NUM_SLAVE-1:0];
     `endif
               wire   [P_WIDTH_SID-1:0]    `NET_DELAY   S_RID       [P_NUM_SLAVE-1:0];
               wire   [P_WIDTH_DA-1:0]     `NET_DELAY   S_RDATA     [P_NUM_SLAVE-1:0];
               wire   [ 1:0]               `NET_DELAY   S_RRESP     [P_NUM_SLAVE-1:0];
               wire                        `NET_DELAY   S_RLAST     [P_NUM_SLAVE-1:0];
               wire                        `NET_DELAY   S_RVALID    [P_NUM_SLAVE-1:0];
               wire                        `NET_DELAY   S_RREADY    [P_NUM_SLAVE-1:0];
     `ifdef AMBA_AXI_RUSER
               wire   [WIDTH_RUSER-1:0]    `NET_DELAY   S_RUSER     [P_NUM_SLAVE-1:0];
     `endif
//------------------------------------------------------------------------------
    amba_axi_m2s2 #(.WIDTH_ID    (P_WIDTH_ID )
                   ,.WIDTH_AD    (P_WIDTH_AD )
                   ,.WIDTH_DA    (P_WIDTH_DA )
                   ,.WIDTH_DS    (P_WIDTH_DS )
                   ,.WIDTH_SID   (P_WIDTH_SID)
                   `ifdef AMBA_AXI_AWUSER
                   ,.WIDTH_AWUSER(P_WIDTH_AWUSER)
                   `endif
                   `ifdef AMBA_AXI_WUSER
                   ,.WIDTH_WUSER (P_WIDTH_WUSER)
                   `endif
                   `ifdef AMBA_AXI_BUSER
                   ,.WIDTH_BUSER (P_WIDTH_BUSER)
                   `endif
                   `ifdef AMBA_AXI_ARUSER
                   ,.WIDTH_ARUSER(P_WIDTH_ARUSER)
                   `endif
                   `ifdef AMBA_AXI_RUSER
                   ,.WIDTH_RUSER (P_WIDTH_RUSER)
                   `endif
                   ,.SLAVE_EN0(1),.ADDR_BASE0(P_ADDR_BASE_MEM),.ADDR_LENGTH0($clog2(P_SIZE_MEM))
                   ,.SLAVE_EN1(1),.ADDR_BASE1(P_ADDR_BASE_POOL),.ADDR_LENGTH1($clog2(P_SIZE_POOL))
                   )
    u_bus (
                                        .ARESETn      ( ARESETn      )
     ,                                  .ACLK         ( ACLK         )
     ,                                  .M0_AWID      ( M_AWID    [0])
     ,                                  .M0_AWADDR    ( M_AWADDR  [0])
     ,                                  .M0_AWLEN     ( M_AWLEN   [0])
     ,                                  .M0_AWLOCK    ( M_AWLOCK  [0])
     ,                                  .M0_AWSIZE    ( M_AWSIZE  [0])
     ,                                  .M0_AWBURST   ( M_AWBURST [0])
     `ifdef  AMBA_AXI_CACHE
     ,                                  .M0_AWCACHE   ( M_AWCACHE [0])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                                  .M0_AWPROT    ( M_AWPROT  [0])
     `endif
     ,                                  .M0_AWVALID   ( M_AWVALID [0])
     ,                                  .M0_AWREADY   ( M_AWREADY [0])
     `ifdef AMBA_QOS
     ,                                  .M0_AWQOS     ( M_AWQOS   [0])
     ,                                  .M0_AWREGION  ( M_AWREGION[0])
     `endif
     `ifdef AMBA_AXI_AWUSER
     ,                                  .M0_AWUSER    ( M_AWUSER  [0])
     `endif
     ,                                  .M0_WDATA     ( M_WDATA   [0])
     ,                                  .M0_WSTRB     ( M_WSTRB   [0])
     ,                                  .M0_WLAST     ( M_WLAST   [0])
     ,                                  .M0_WVALID    ( M_WVALID  [0])
     ,                                  .M0_WREADY    ( M_WREADY  [0])
     `ifdef AMBA_AXI_WUSER
                                        .M0_WUSER     ( M_WUSER   [0])
     `endif
     ,                                  .M0_BID       ( M_BID     [0])
     ,                                  .M0_BRESP     ( M_BRESP   [0])
     ,                                  .M0_BVALID    ( M_BVALID  [0])
     ,                                  .M0_BREADY    ( M_BREADY  [0])
     `ifdef AMBA_AXI_BUSER
                                        .M0_BUSER     ( M_BUSER   [0])
     `endif
     ,                                  .M0_ARID      ( M_ARID    [0])
     ,                                  .M0_ARADDR    ( M_ARADDR  [0])
     ,                                  .M0_ARLEN     ( M_ARLEN   [0])
     ,                                  .M0_ARLOCK    ( M_ARLOCK  [0])
     ,                                  .M0_ARSIZE    ( M_ARSIZE  [0])
     ,                                  .M0_ARBURST   ( M_ARBURST [0])
     `ifdef  AMBA_AXI_CACHE
     ,                                  .M0_ARCACHE   ( M_ARCACHE [0])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                                  .M0_ARPROT    ( M_ARPROT  [0])
     `endif
     ,                                  .M0_ARVALID   ( M_ARVALID [0])
     ,                                  .M0_ARREADY   ( M_ARREADY [0])
     `ifdef AMBA_QOS
     ,                                  .M0_ARQOS     ( M_ARQOS   [0])
     ,                                  .M0_ARREGION  ( M_ARREGION[0])
     `endif
     `ifdef AMBA_AXI_ARUSER
     ,                                  .M0_ARUSER    ( M_ARUSER  [0])
     `endif
     ,                                  .M0_RID       ( M_RID     [0])
     ,                                  .M0_RDATA     ( M_RDATA   [0])
     ,                                  .M0_RRESP     ( M_RRESP   [0])
     ,                                  .M0_RLAST     ( M_RLAST   [0])
     ,                                  .M0_RVALID    ( M_RVALID  [0])
     ,                                  .M0_RREADY    ( M_RREADY  [0])
     `ifdef AMBA_AXI_RUSER
     ,                                  .M0_RUSER     ( M_RUSER   [0])
     `endif
     ,                                  .M1_AWID      ( M_AWID    [1])
     ,                                  .M1_AWADDR    ( M_AWADDR  [1])
     ,                                  .M1_AWLEN     ( M_AWLEN   [1])
     ,                                  .M1_AWLOCK    ( M_AWLOCK  [1])
     ,                                  .M1_AWSIZE    ( M_AWSIZE  [1])
     ,                                  .M1_AWBURST   ( M_AWBURST [1])
     `ifdef  AMBA_AXI_CACHE
     ,                                  .M1_AWCACHE   ( M_AWCACHE [1])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                                  .M1_AWPROT    ( M_AWPROT  [1])
     `endif
     ,                                  .M1_AWVALID   ( M_AWVALID [1])
     ,                                  .M1_AWREADY   ( M_AWREADY [1])
     `ifdef AMBA_QOS                                  (           [ ])
     ,                                  .M1_AWQOS     ( M_AWQOS   [1])
     ,                                  .M1_AWREGION  ( M_AWREGION[1])
     `endif
     `ifdef AMBA_AXI_AWUSER
     ,                                  .M1_AWUSER    ( M_AWUSER  [1])
     `endif
     ,                                  .M1_WDATA     ( M_WDATA   [1])
     ,                                  .M1_WSTRB     ( M_WSTRB   [1])
     ,                                  .M1_WLAST     ( M_WLAST   [1])
     ,                                  .M1_WVALID    ( M_WVALID  [1])
     ,                                  .M1_WREADY    ( M_WREADY  [1])
     `ifdef AMBA_AXI_WUSER
     ,                                  .M1_WUSER     ( M_WUSER   [1])
     `endif
     ,                                  .M1_BID       ( M_BID     [1])
     ,                                  .M1_BRESP     ( M_BRESP   [1])
     ,                                  .M1_BVALID    ( M_BVALID  [1])
     ,                                  .M1_BREADY    ( M_BREADY  [1])
     `ifdef AMBA_AXI_BUSER
     ,                                  .M1_BUSER     ( M_BUSER   [1])
     `endif
     ,                                  .M1_ARID      ( M_ARID    [1])
     ,                                  .M1_ARADDR    ( M_ARADDR  [1])
     ,                                  .M1_ARLEN     ( M_ARLEN   [1])
     ,                                  .M1_ARLOCK    ( M_ARLOCK  [1])
     ,                                  .M1_ARSIZE    ( M_ARSIZE  [1])
     ,                                  .M1_ARBURST   ( M_ARBURST [1])
     `ifdef  AMBA_AXI_CACHE
     ,                                  .M1_ARCACHE   ( M_ARCACHE [1])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                                  .M1_ARPROT    ( M_ARPROT  [1])
     `endif
     ,                                  .M1_ARVALID   ( M_ARVALID [1])
     ,                                  .M1_ARREADY   ( M_ARREADY [1])
     `ifdef AMBA_QOS
     ,                                  .M1_ARQOS     ( M_ARQOS   [1])
     ,                                  .M1_ARREGION  ( M_ARREGION[1])
     `endif
     `ifdef AMBA_AXI_ARUSER
     ,                                  .M1_ARUSER    ( M_ARUSER  [1])
     `endif
     ,                                  .M1_RID       ( M_RID     [1])
     ,                                  .M1_RDATA     ( M_RDATA   [1])
     ,                                  .M1_RRESP     ( M_RRESP   [1])
     ,                                  .M1_RLAST     ( M_RLAST   [1])
     ,                                  .M1_RVALID    ( M_RVALID  [1])
     ,                                  .M1_RREADY    ( M_RREADY  [1])
     `ifdef AMBA_AXI_RUSER
     ,                                  .M1_RUSER     ( M_RUSER   [1])
     `endif
     ,                                  .S0_AWID      ( S_AWID    [0])
     ,                                  .S0_AWADDR    ( S_AWADDR  [0])
     ,                                  .S0_AWLEN     ( S_AWLEN   [0])
     ,                                  .S0_AWLOCK    ( S_AWLOCK  [0])
     ,                                  .S0_AWSIZE    ( S_AWSIZE  [0])
     ,                                  .S0_AWBURST   ( S_AWBURST [0])
     `ifdef  AMBA_AXI_CACHE
     ,                                  .S0_AWCACHE   ( S_AWCACHE [0])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                                  .S0_AWPROT    ( S_AWPROT  [0])
     `endif
     ,                                  .S0_AWVALID   ( S_AWVALID [0])
     ,                                  .S0_AWREADY   ( S_AWREADY [0])
     `ifdef AMBA_QOS
     ,                                  .S0_AWQOS     ( S_AWQOS   [0])
     ,                                  .S0_AWREGION  ( S_AWREGION[0])
     `endif
     `ifdef AMBA_AXI_AWUSER
     ,                                  .S0_AWUSER    ( S_AWUSER  [0])
     `endif
     ,                                  .S0_WDATA     ( S_WDATA   [0])
     ,                                  .S0_WSTRB     ( S_WSTRB   [0])
     ,                                  .S0_WLAST     ( S_WLAST   [0])
     ,                                  .S0_WVALID    ( S_WVALID  [0])
     ,                                  .S0_WREADY    ( S_WREADY  [0])
     `ifdef AMBA_AXI_WUSER
     ,                                  .S0_WUSER     ( S_WUSER   [0])
     `endif
     ,                                  .S0_BID       ( S_BID     [0])
     ,                                  .S0_BRESP     ( S_BRESP   [0])
     ,                                  .S0_BVALID    ( S_BVALID  [0])
     ,                                  .S0_BREADY    ( S_BREADY  [0])
     `ifdef AMBA_AXI_BUSER
     ,                                  .S0_BUSER     ( S_BUSER   [0])
     `endif
     ,                                  .S0_ARID      ( S_ARID    [0])
     ,                                  .S0_ARADDR    ( S_ARADDR  [0])
     ,                                  .S0_ARLEN     ( S_ARLEN   [0])
     ,                                  .S0_ARLOCK    ( S_ARLOCK  [0])
     ,                                  .S0_ARSIZE    ( S_ARSIZE  [0])
     ,                                  .S0_ARBURST   ( S_ARBURST [0])
     `ifdef  AMBA_AXI_CACHE
     ,                                  .S0_ARCACHE   ( S_ARCACHE [0])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                                  .S0_ARPROT    ( S_ARPROT  [0])
     `endif
     ,                                  .S0_ARVALID   ( S_ARVALID [0])
     ,                                  .S0_ARREADY   ( S_ARREADY [0])
     `ifdef AMBA_QOS
     ,                                  .S0_ARQOS     ( S_ARQOS   [0])
     ,                                  .S0_ARREGION  ( S_ARREGION[0])
     `endif
     `ifdef AMBA_AXI_ARUSER
     ,                                  .S0_ARUSER    ( S_ARUSER  [0])
     `endif
     ,                                  .S0_RID       ( S_RID     [0])
     ,                                  .S0_RDATA     ( S_RDATA   [0])
     ,                                  .S0_RRESP     ( S_RRESP   [0])
     ,                                  .S0_RLAST     ( S_RLAST   [0])
     ,                                  .S0_RVALID    ( S_RVALID  [0])
     ,                                  .S0_RREADY    ( S_RREADY  [0])
     `ifdef AMBA_AXI_RUSER
     ,                                  .S0_RUSER     ( S_RUSER   [0])
     `endif
     ,                                  .S1_AWID      ( S_AWID    [1])
     ,                                  .S1_AWADDR    ( S_AWADDR  [1])
     ,                                  .S1_AWLEN     ( S_AWLEN   [1])
     ,                                  .S1_AWLOCK    ( S_AWLOCK  [1])
     ,                                  .S1_AWSIZE    ( S_AWSIZE  [1])
     ,                                  .S1_AWBURST   ( S_AWBURST [1])
     `ifdef  AMBA_AXI_CACHE
     ,                                  .S1_AWCACHE   ( S_AWCACHE [1])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                                  .S1_AWPROT    ( S_AWPROT  [1])
     `endif
     ,                                  .S1_AWVALID   ( S_AWVALID [1])
     ,                                  .S1_AWREADY   ( S_AWREADY [1])
     `ifdef AMBA_QOS
     ,                                  .S1_AWQOS     ( S_AWQOS   [1])
     ,                                  .S1_AWREGION  ( S_AWREGION[1])
     `endif
     `ifdef AMBA_AXI_AWUSER
     ,                                  .S1_AWUSER    ( S_AWUSER  [1])
     `endif
     ,                                  .S1_WDATA     ( S_WDATA   [1])
     ,                                  .S1_WSTRB     ( S_WSTRB   [1])
     ,                                  .S1_WLAST     ( S_WLAST   [1])
     ,                                  .S1_WVALID    ( S_WVALID  [1])
     ,                                  .S1_WREADY    ( S_WREADY  [1])
     `ifdef AMBA_AXI_WUSER
     ,                                  .S1_WUSER     ( S_WUSER   [1])
     `endif
     ,                                  .S1_BID       ( S_BID     [1])
     ,                                  .S1_BRESP     ( S_BRESP   [1])
     ,                                  .S1_BVALID    ( S_BVALID  [1])
     ,                                  .S1_BREADY    ( S_BREADY  [1])
     `ifdef AMBA_AXI_BUSER
     ,                                  .S1_BUSER     ( S_BUSER   [1])
     `endif
     ,                                  .S1_ARID      ( S_ARID    [1])
     ,                                  .S1_ARADDR    ( S_ARADDR  [1])
     ,                                  .S1_ARLEN     ( S_ARLEN   [1])
     ,                                  .S1_ARLOCK    ( S_ARLOCK  [1])
     ,                                  .S1_ARSIZE    ( S_ARSIZE  [1])
     ,                                  .S1_ARBURST   ( S_ARBURST [1])
     `ifdef  AMBA_AXI_CACHE
     ,                                  .S1_ARCACHE   ( S_ARCACHE [1])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                                  .S1_ARPROT    ( S_ARPROT  [1])
     `endif
     ,                                  .S1_ARVALID   ( S_ARVALID [1])
     ,                                  .S1_ARREADY   ( S_ARREADY [1])
     `ifdef AMBA_QOS
     ,                                  .S1_ARQOS     ( S_ARQOS   [1])
     ,                                  .S1_ARREGION  ( S_ARREGION[1])
     `endif
     `ifdef AMBA_AXI_ARUSER
     ,                                  .S1_ARUSER    ( S_ARUSER  [1])
     `endif
     ,                                  .S1_RID       ( S_RID     [1])
     ,                                  .S1_RDATA     ( S_RDATA   [1])
     ,                                  .S1_RRESP     ( S_RRESP   [1])
     ,                                  .S1_RLAST     ( S_RLAST   [1])
     ,                                  .S1_RVALID    ( S_RVALID  [1])
     ,                                  .S1_RREADY    ( S_RREADY  [1])
     `ifdef AMBA_AXI_RUSER
     ,                                  .S1_RUSER     ( S_RUSER   [1])
     `endif
    );
