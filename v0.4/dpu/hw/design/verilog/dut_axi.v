//------------------------------------------------------------------------------
    localparam P_NUM_AXI_MASTER  = 8; // should not be changed
    localparam P_NUM_AXI_SLAVE   = 2; // should not be changed
    localparam P_AXI_WIDTH_CID   =$clog2(P_NUM_AXI_MASTER);// ID width in bits
    localparam P_AXI_WIDTH_ID    = 4;                   // ID width in bits
    localparam P_AXI_WIDTH_DS    =(P_AXI_WIDTH_DA/8); // data strobe width
    localparam P_AXI_WIDTH_SID   =(P_AXI_WIDTH_CID+P_AXI_WIDTH_ID);// ID for slave
    `ifdef AMBA_AXI_AWUSER
    localparam P_AXI_WIDTH_AWUSER= 1;// Write-address user path
    `endif
    `ifdef AMBA_AXI_WUSER
    localparam P_AXI_WIDTH_WUSER = 1;// Write-data user path
    `endif
    `ifdef AMBA_AXI_BUSER
    localparam P_AXI_WIDTH_BUSER = 1;// Write-response user path
    `endif
    `ifdef AMBA_AXI_ARUSER
    localparam P_AXI_WIDTH_ARUSER= 1;// read-address user path
    `endif
    `ifdef AMBA_AXI_RUSER
    localparam P_AXI_WIDTH_RUSER = 1;// read-data user path
    `endif
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
               wire                                     ARESETn; // see dut_bfm.v
               wire                                     ACLK   ; // see dut_bfm.v
               wire  [P_AXI_WIDTH_ID-1:0]      `NET_DELAY   M_AWID      [P_NUM_AXI_MASTER-1:0];
               wire  [P_AXI_WIDTH_AD-1:0]      `NET_DELAY   M_AWADDR    [P_NUM_AXI_MASTER-1:0];
               wire  [ 7:0]                    `NET_DELAY   M_AWLEN     [P_NUM_AXI_MASTER-1:0];
               wire  [P_NUM_AXI_MASTER-1:0]    `NET_DELAY   M_AWLOCK    ;
               wire  [ 2:0]                    `NET_DELAY   M_AWSIZE    [P_NUM_AXI_MASTER-1:0];
               wire  [ 1:0]                    `NET_DELAY   M_AWBURST   [P_NUM_AXI_MASTER-1:0];
     `ifdef  AMBA_AXI_CACHE
               wire  [ 3:0]                    `NET_DELAY   M_AWCACHE   [P_NUM_AXI_MASTER-1:0];
     `endif
     `ifdef AMBA_AXI_PROT
               wire  [ 2:0]                    `NET_DELAY   M_AWPROT    [P_NUM_AXI_MASTER-1:0];
     `endif
               wire  [P_NUM_AXI_MASTER-1:0]    `NET_DELAY   M_AWVALID   ;
               wire  [P_NUM_AXI_MASTER-1:0]    `NET_DELAY   M_AWREADY   ;
     `ifdef AMBA_QOS
               wire  [ 3:0]                    `NET_DELAY   M_AWQOS     [P_NUM_AXI_MASTER-1:0];
               wire  [ 3:0]                    `NET_DELAY   M_AWREGION  [P_NUM_AXI_MASTER-1:0];
     `endif
     `ifdef AMBA_AXI_AWUSER
               wire  [P_AXI_WIDTH_AWUSER-1:0]  `NET_DELAY   M_AWUSER    [P_NUM_AXI_MASTER-1:0];
     `endif
               wire  [P_AXI_WIDTH_DA-1:0]      `NET_DELAY   M_WDATA     [P_NUM_AXI_MASTER-1:0];
               wire  [P_AXI_WIDTH_DS-1:0]      `NET_DELAY   M_WSTRB     [P_NUM_AXI_MASTER-1:0];
               wire  [P_NUM_AXI_MASTER-1:0]    `NET_DELAY   M_WLAST     ;
               wire  [P_NUM_AXI_MASTER-1:0]    `NET_DELAY   M_WVALID    ;
               wire  [P_NUM_AXI_MASTER-1:0]    `NET_DELAY   M_WREADY    ;
     `ifdef AMBA_AXI_WUSER
               wire  [P_AXI_WIDTH_WUSER-1:0]   `NET_DELAY   M_WUSER     [P_NUM_AXI_MASTER-1:0];
     `endif
               wire  [P_AXI_WIDTH_ID-1:0]      `NET_DELAY   M_BID       [P_NUM_AXI_MASTER-1:0];
               wire  [ 1:0]                    `NET_DELAY   M_BRESP     [P_NUM_AXI_MASTER-1:0];
               wire  [P_NUM_AXI_MASTER-1:0]    `NET_DELAY   M_BVALID    ;
               wire  [P_NUM_AXI_MASTER-1:0]    `NET_DELAY   M_BREADY    ;
     `ifdef AMBA_AXI_BUSER
               wire  [P_AXI_WIDTH_BUSER-1:0]   `NET_DELAY   M_BUSER     [P_NUM_AXI_MASTER-1:0];
     `endif
               wire  [P_AXI_WIDTH_ID-1:0]      `NET_DELAY   M_ARID      [P_NUM_AXI_MASTER-1:0];
               wire  [P_AXI_WIDTH_AD-1:0]      `NET_DELAY   M_ARADDR    [P_NUM_AXI_MASTER-1:0];
               wire  [ 7:0]                    `NET_DELAY   M_ARLEN     [P_NUM_AXI_MASTER-1:0];
               wire  [P_NUM_AXI_MASTER-1:0]    `NET_DELAY   M_ARLOCK    ;
               wire  [ 2:0]                    `NET_DELAY   M_ARSIZE    [P_NUM_AXI_MASTER-1:0];
               wire  [ 1:0]                    `NET_DELAY   M_ARBURST   [P_NUM_AXI_MASTER-1:0];
     `ifdef  AMBA_AXI_CACHE
               wire  [ 3:0]                    `NET_DELAY   M_ARCACHE   [P_NUM_AXI_MASTER-1:0];
     `endif
     `ifdef AMBA_AXI_PROT
               wire  [ 2:0]                    `NET_DELAY   M_ARPROT    [P_NUM_AXI_MASTER-1:0];
     `endif
               wire  [P_NUM_AXI_MASTER-1:0]    `NET_DELAY   M_ARVALID   ;
               wire  [P_NUM_AXI_MASTER-1:0]    `NET_DELAY   M_ARREADY   ;
     `ifdef AMBA_QOS
               wire  [ 3:0]                    `NET_DELAY   M_ARQOS     [P_NUM_AXI_MASTER-1:0];
               wire  [ 3:0]                    `NET_DELAY   M_ARREGION  [P_NUM_AXI_MASTER-1:0];
     `endif
     `ifdef AMBA_AXI_ARUSER
               wire  [P_AXI_WIDTH_ARUSER-1:0]  `NET_DELAY   M_ARUSER    [P_NUM_AXI_MASTER-1:0];
     `endif
               wire  [P_AXI_WIDTH_ID-1:0]      `NET_DELAY   M_RID       [P_NUM_AXI_MASTER-1:0];
               wire  [P_AXI_WIDTH_DA-1:0]      `NET_DELAY   M_RDATA     [P_NUM_AXI_MASTER-1:0];
               wire  [ 1:0]                    `NET_DELAY   M_RRESP     [P_NUM_AXI_MASTER-1:0];
               wire  [P_NUM_AXI_MASTER-1:0]    `NET_DELAY   M_RLAST     ;
               wire  [P_NUM_AXI_MASTER-1:0]    `NET_DELAY   M_RVALID    ;
               wire  [P_NUM_AXI_MASTER-1:0]    `NET_DELAY   M_RREADY    ;
     `ifdef AMBA_AXI_RUSER
               wire  [P_AXI_WIDTH_RUSER-1:0]   `NET_DELAY   M_RUSER     [P_NUM_AXI_MASTER-1:0];
     `endif
//--------------------------------------------------------------------------------------
               wire   [P_AXI_WIDTH_SID-1:0]    `NET_DELAY   S_AWID      [P_NUM_AXI_SLAVE-1:0];
               wire   [P_AXI_WIDTH_AD-1:0]     `NET_DELAY   S_AWADDR    [P_NUM_AXI_SLAVE-1:0];
               wire   [ 7:0]                   `NET_DELAY   S_AWLEN     [P_NUM_AXI_SLAVE-1:0];
               wire                            `NET_DELAY   S_AWLOCK    [P_NUM_AXI_SLAVE-1:0];
               wire   [ 2:0]                   `NET_DELAY   S_AWSIZE    [P_NUM_AXI_SLAVE-1:0];
               wire   [ 1:0]                   `NET_DELAY   S_AWBURST   [P_NUM_AXI_SLAVE-1:0];
     `ifdef  AMBA_AXI_CACHE
               wire   [ 3:0]                   `NET_DELAY   S_AWCACHE   [P_NUM_AXI_SLAVE-1:0];
     `endif
     `ifdef AMBA_AXI_PROT
               wire   [ 2:0]                   `NET_DELAY   S_AWPROT    [P_NUM_AXI_SLAVE-1:0];
     `endif
               wire                            `NET_DELAY   S_AWVALID   [P_NUM_AXI_SLAVE-1:0];
               wire                            `NET_DELAY   S_AWREADY   [P_NUM_AXI_SLAVE-1:0];
     `ifdef AMBA_QOS
               wire   [ 3:0]                   `NET_DELAY   S_AWQOS     [P_NUM_AXI_SLAVE-1:0];
               wire   [ 3:0]                   `NET_DELAY   S_AWREGION  [P_NUM_AXI_SLAVE-1:0];
     `endif
     `ifdef AMBA_AXI_AWUSER
               wire   [P_AXI_WIDTH_AWUSER-1:0] `NET_DELAY   S_AWUSER    [P_NUM_AXI_SLAVE-1:0];
     `endif
               wire   [P_AXI_WIDTH_DA-1:0]     `NET_DELAY   S_WDATA     [P_NUM_AXI_SLAVE-1:0];
               wire   [P_AXI_WIDTH_DS-1:0]     `NET_DELAY   S_WSTRB     [P_NUM_AXI_SLAVE-1:0];
               wire                            `NET_DELAY   S_WLAST     [P_NUM_AXI_SLAVE-1:0];
               wire                            `NET_DELAY   S_WVALID    [P_NUM_AXI_SLAVE-1:0];
               wire                            `NET_DELAY   S_WREADY    [P_NUM_AXI_SLAVE-1:0];
     `ifdef AMBA_AXI_WUSER
               wire   [P_AXI_WIDTH_WUSER-1:0]  `NET_DELAY   S_WUSER     [P_NUM_AXI_SLAVE-1:0];
     `endif
               wire   [P_AXI_WIDTH_SID-1:0]    `NET_DELAY   S_BID       [P_NUM_AXI_SLAVE-1:0];
               wire   [ 1:0]                   `NET_DELAY   S_BRESP     [P_NUM_AXI_SLAVE-1:0];
               wire                            `NET_DELAY   S_BVALID    [P_NUM_AXI_SLAVE-1:0];
               wire                            `NET_DELAY   S_BREADY    [P_NUM_AXI_SLAVE-1:0];
     `ifdef AMBA_AXI_BUSER
               wire   [P_AXI_WIDTH_BUSER-1:0]  `NET_DELAY   S_BUSER     [P_NUM_AXI_SLAVE-1:0];
     `endif
               wire   [P_AXI_WIDTH_SID-1:0]    `NET_DELAY   S_ARID      [P_NUM_AXI_SLAVE-1:0];
               wire   [P_AXI_WIDTH_AD-1:0]     `NET_DELAY   S_ARADDR    [P_NUM_AXI_SLAVE-1:0];
               wire   [ 7:0]                   `NET_DELAY   S_ARLEN     [P_NUM_AXI_SLAVE-1:0];
               wire                            `NET_DELAY   S_ARLOCK    [P_NUM_AXI_SLAVE-1:0];
               wire   [ 2:0]                   `NET_DELAY   S_ARSIZE    [P_NUM_AXI_SLAVE-1:0];
               wire   [ 1:0]                   `NET_DELAY   S_ARBURST   [P_NUM_AXI_SLAVE-1:0];
     `ifdef  AMBA_AXI_CACHE
               wire   [ 3:0]                   `NET_DELAY   S_ARCACHE   [P_NUM_AXI_SLAVE-1:0];
     `endif
     `ifdef AMBA_AXI_PROT
               wire   [ 2:0]                   `NET_DELAY   S_ARPROT    [P_NUM_AXI_SLAVE-1:0];
     `endif
               wire                            `NET_DELAY   S_ARVALID   [P_NUM_AXI_SLAVE-1:0];
               wire                            `NET_DELAY   S_ARREADY   [P_NUM_AXI_SLAVE-1:0];
     `ifdef AMBA_QOS
               wire   [ 3:0]                   `NET_DELAY   S_ARQOS     [P_NUM_AXI_SLAVE-1:0];
               wire   [ 3:0]                   `NET_DELAY   S_ARREGION  [P_NUM_AXI_SLAVE-1:0];
     `endif
     `ifdef AMBA_AXI_ARUSER
               wire   [P_AXI_WIDTH_ARUSER-1:0] `NET_DELAY   S_ARUSER    [P_NUM_AXI_SLAVE-1:0];
     `endif
               wire   [P_AXI_WIDTH_SID-1:0]    `NET_DELAY   S_RID       [P_NUM_AXI_SLAVE-1:0];
               wire   [P_AXI_WIDTH_DA-1:0]     `NET_DELAY   S_RDATA     [P_NUM_AXI_SLAVE-1:0];
               wire   [ 1:0]                   `NET_DELAY   S_RRESP     [P_NUM_AXI_SLAVE-1:0];
               wire                            `NET_DELAY   S_RLAST     [P_NUM_AXI_SLAVE-1:0];
               wire                            `NET_DELAY   S_RVALID    [P_NUM_AXI_SLAVE-1:0];
               wire                            `NET_DELAY   S_RREADY    [P_NUM_AXI_SLAVE-1:0];
     `ifdef AMBA_AXI_RUSER
               wire   [WIDTH_RUSER-1:0]        `NET_DELAY   S_RUSER     [P_NUM_AXI_SLAVE-1:0];
     `endif
//------------------------------------------------------------------------------
    amba_axi_m8s2 #(.WIDTH_ID    (P_AXI_WIDTH_ID )
                   ,.WIDTH_AD    (P_AXI_WIDTH_AD )
                   ,.WIDTH_DA    (P_AXI_WIDTH_DA )
                   ,.WIDTH_DS    (P_AXI_WIDTH_DS )
                   ,.WIDTH_SID   (P_AXI_WIDTH_SID)
                   `ifdef AMBA_AXI_AWUSER
                   ,.WIDTH_AWUSER(P_AXI_WIDTH_AWUSER)
                   `endif
                   `ifdef AMBA_AXI_WUSER
                   ,.WIDTH_WUSER (P_AXI_WIDTH_WUSER)
                   `endif
                   `ifdef AMBA_AXI_BUSER
                   ,.WIDTH_BUSER (P_AXI_WIDTH_BUSER)
                   `endif
                   `ifdef AMBA_AXI_ARUSER
                   ,.WIDTH_ARUSER(P_AXI_WIDTH_ARUSER)
                   `endif
                   `ifdef AMBA_AXI_RUSER
                   ,.WIDTH_RUSER (P_AXI_WIDTH_RUSER)
                   `endif
                   ,.SLAVE_EN0(1),.ADDR_BASE0(P_ADDR_BASE_MEM),.ADDR_LENGTH0($clog2(P_SIZE_MEM))
                   ,.SLAVE_EN1(1),.ADDR_BASE1(P_ADDR_BASE_DPU),.ADDR_LENGTH1($clog2(P_SIZE_DPU))
                   )
    u_axi (
                             .ARESETn      ( ARESETn      )
     ,                       .ACLK         ( ACLK         )
     ,                       .M0_AWID      ( M_AWID    [0])
     ,                       .M0_AWADDR    ( M_AWADDR  [0])
     ,                       .M0_AWLEN     ( M_AWLEN   [0])
     ,                       .M0_AWLOCK    ( M_AWLOCK  [0])
     ,                       .M0_AWSIZE    ( M_AWSIZE  [0])
     ,                       .M0_AWBURST   ( M_AWBURST [0])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M0_AWCACHE   ( M_AWCACHE [0])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M0_AWPROT    ( M_AWPROT  [0])
     `endif
     ,                       .M0_AWVALID   ( M_AWVALID [0])
     ,                       .M0_AWREADY   ( M_AWREADY [0])
     `ifdef AMBA_QOS
     ,                       .M0_AWQOS     ( M_AWQOS   [0])
     ,                       .M0_AWREGION  ( M_AWREGION[0])
     `endif
     `ifdef AMBA_AXI_AWUSER
     ,                       .M0_AWUSER    ( M_AWUSER  [0])
     `endif
     ,                       .M0_WDATA     ( M_WDATA   [0])
     ,                       .M0_WSTRB     ( M_WSTRB   [0])
     ,                       .M0_WLAST     ( M_WLAST   [0])
     ,                       .M0_WVALID    ( M_WVALID  [0])
     ,                       .M0_WREADY    ( M_WREADY  [0])
     `ifdef AMBA_AXI_WUSER
                             .M0_WUSER     ( M_WUSER   [0])
     `endif
     ,                       .M0_BID       ( M_BID     [0])
     ,                       .M0_BRESP     ( M_BRESP   [0])
     ,                       .M0_BVALID    ( M_BVALID  [0])
     ,                       .M0_BREADY    ( M_BREADY  [0])
     `ifdef AMBA_AXI_BUSER
                             .M0_BUSER     ( M_BUSER   [0])
     `endif
     ,                       .M0_ARID      ( M_ARID    [0])
     ,                       .M0_ARADDR    ( M_ARADDR  [0])
     ,                       .M0_ARLEN     ( M_ARLEN   [0])
     ,                       .M0_ARLOCK    ( M_ARLOCK  [0])
     ,                       .M0_ARSIZE    ( M_ARSIZE  [0])
     ,                       .M0_ARBURST   ( M_ARBURST [0])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M0_ARCACHE   ( M_ARCACHE [0])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M0_ARPROT    ( M_ARPROT  [0])
     `endif
     ,                       .M0_ARVALID   ( M_ARVALID [0])
     ,                       .M0_ARREADY   ( M_ARREADY [0])
     `ifdef AMBA_QOS
     ,                       .M0_ARQOS     ( M_ARQOS   [0])
     ,                       .M0_ARREGION  ( M_ARREGION[0])
     `endif
     `ifdef AMBA_AXI_ARUSER
     ,                       .M0_ARUSER    ( M_ARUSER  [0])
     `endif
     ,                       .M0_RID       ( M_RID     [0])
     ,                       .M0_RDATA     ( M_RDATA   [0])
     ,                       .M0_RRESP     ( M_RRESP   [0])
     ,                       .M0_RLAST     ( M_RLAST   [0])
     ,                       .M0_RVALID    ( M_RVALID  [0])
     ,                       .M0_RREADY    ( M_RREADY  [0])
     `ifdef AMBA_AXI_RUSER
     ,                       .M0_RUSER     ( M_RUSER   [0])
     `endif
     ,                       .M1_AWID      ( M_AWID    [1])
     ,                       .M1_AWADDR    ( M_AWADDR  [1])
     ,                       .M1_AWLEN     ( M_AWLEN   [1])
     ,                       .M1_AWLOCK    ( M_AWLOCK  [1])
     ,                       .M1_AWSIZE    ( M_AWSIZE  [1])
     ,                       .M1_AWBURST   ( M_AWBURST [1])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M1_AWCACHE   ( M_AWCACHE [1])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M1_AWPROT    ( M_AWPROT  [1])
     `endif
     ,                       .M1_AWVALID   ( M_AWVALID [1])
     ,                       .M1_AWREADY   ( M_AWREADY [1])
     `ifdef AMBA_QOS                       (           [ ])
     ,                       .M1_AWQOS     ( M_AWQOS   [1])
     ,                       .M1_AWREGION  ( M_AWREGION[1])
     `endif
     `ifdef AMBA_AXI_AWUSER
     ,                       .M1_AWUSER    ( M_AWUSER  [1])
     `endif
     ,                       .M1_WDATA     ( M_WDATA   [1])
     ,                       .M1_WSTRB     ( M_WSTRB   [1])
     ,                       .M1_WLAST     ( M_WLAST   [1])
     ,                       .M1_WVALID    ( M_WVALID  [1])
     ,                       .M1_WREADY    ( M_WREADY  [1])
     `ifdef AMBA_AXI_WUSER
     ,                       .M1_WUSER     ( M_WUSER   [1])
     `endif
     ,                       .M1_BID       ( M_BID     [1])
     ,                       .M1_BRESP     ( M_BRESP   [1])
     ,                       .M1_BVALID    ( M_BVALID  [1])
     ,                       .M1_BREADY    ( M_BREADY  [1])
     `ifdef AMBA_AXI_BUSER
     ,                       .M1_BUSER     ( M_BUSER   [1])
     `endif
     ,                       .M1_ARID      ( M_ARID    [1])
     ,                       .M1_ARADDR    ( M_ARADDR  [1])
     ,                       .M1_ARLEN     ( M_ARLEN   [1])
     ,                       .M1_ARLOCK    ( M_ARLOCK  [1])
     ,                       .M1_ARSIZE    ( M_ARSIZE  [1])
     ,                       .M1_ARBURST   ( M_ARBURST [1])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M1_ARCACHE   ( M_ARCACHE [1])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M1_ARPROT    ( M_ARPROT  [1])
     `endif
     ,                       .M1_ARVALID   ( M_ARVALID [1])
     ,                       .M1_ARREADY   ( M_ARREADY [1])
     `ifdef AMBA_QOS
     ,                       .M1_ARQOS     ( M_ARQOS   [1])
     ,                       .M1_ARREGION  ( M_ARREGION[1])
     `endif
     `ifdef AMBA_AXI_ARUSER
     ,                       .M1_ARUSER    ( M_ARUSER  [1])
     `endif
     ,                       .M1_RID       ( M_RID     [1])
     ,                       .M1_RDATA     ( M_RDATA   [1])
     ,                       .M1_RRESP     ( M_RRESP   [1])
     ,                       .M1_RLAST     ( M_RLAST   [1])
     ,                       .M1_RVALID    ( M_RVALID  [1])
     ,                       .M1_RREADY    ( M_RREADY  [1])
     `ifdef AMBA_AXI_RUSER
     ,                       .M1_RUSER     ( M_RUSER   [1])
     `endif
     ,                       .M2_AWID      ( M_AWID    [2])
     ,                       .M2_AWADDR    ( M_AWADDR  [2])
     ,                       .M2_AWLEN     ( M_AWLEN   [2])
     ,                       .M2_AWLOCK    ( M_AWLOCK  [2])
     ,                       .M2_AWSIZE    ( M_AWSIZE  [2])
     ,                       .M2_AWBURST   ( M_AWBURST [2])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M2_AWCACHE   ( M_AWCACHE [2])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M2_AWPROT    ( M_AWPROT  [2])
     `endif
     ,                       .M2_AWVALID   ( M_AWVALID [2])
     ,                       .M2_AWREADY   ( M_AWREADY [2])
     `ifdef AMBA_QOS
     ,                       .M2_AWQOS     ( M_AWQOS   [2])
     ,                       .M2_AWREGION  ( M_AWREGION[2])
     `endif
     `ifdef AMBA_AXI_AWUSER
     ,                       .M2_AWUSER    ( M_AWUSER  [2])
     `endif
     ,                       .M2_WDATA     ( M_WDATA   [2])
     ,                       .M2_WSTRB     ( M_WSTRB   [2])
     ,                       .M2_WLAST     ( M_WLAST   [2])
     ,                       .M2_WVALID    ( M_WVALID  [2])
     ,                       .M2_WREADY    ( M_WREADY  [2])
     `ifdef AMBA_AXI_WUSER
                             .M2_WUSER     ( M_WUSER   [2])
     `endif
     ,                       .M2_BID       ( M_BID     [2])
     ,                       .M2_BRESP     ( M_BRESP   [2])
     ,                       .M2_BVALID    ( M_BVALID  [2])
     ,                       .M2_BREADY    ( M_BREADY  [2])
     `ifdef AMBA_AXI_BUSER
                             .M2_BUSER     ( M_BUSER   [2])
     `endif
     ,                       .M2_ARID      ( M_ARID    [2])
     ,                       .M2_ARADDR    ( M_ARADDR  [2])
     ,                       .M2_ARLEN     ( M_ARLEN   [2])
     ,                       .M2_ARLOCK    ( M_ARLOCK  [2])
     ,                       .M2_ARSIZE    ( M_ARSIZE  [2])
     ,                       .M2_ARBURST   ( M_ARBURST [2])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M2_ARCACHE   ( M_ARCACHE [2])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M2_ARPROT    ( M_ARPROT  [2])
     `endif
     ,                       .M2_ARVALID   ( M_ARVALID [2])
     ,                       .M2_ARREADY   ( M_ARREADY [2])
     `ifdef AMBA_QOS
     ,                       .M2_ARQOS     ( M_ARQOS   [2])
     ,                       .M2_ARREGION  ( M_ARREGION[2])
     `endif
     `ifdef AMBA_AXI_ARUSER
     ,                       .M2_ARUSER    ( M_ARUSER  [2])
     `endif
     ,                       .M2_RID       ( M_RID     [2])
     ,                       .M2_RDATA     ( M_RDATA   [2])
     ,                       .M2_RRESP     ( M_RRESP   [2])
     ,                       .M2_RLAST     ( M_RLAST   [2])
     ,                       .M2_RVALID    ( M_RVALID  [2])
     ,                       .M2_RREADY    ( M_RREADY  [2])
     `ifdef AMBA_AXI_RUSER
     ,                       .M2_RUSER     ( M_RUSER   [2])
     `endif
     ,                       .M3_AWID      ( M_AWID    [3])
     ,                       .M3_AWADDR    ( M_AWADDR  [3])
     ,                       .M3_AWLEN     ( M_AWLEN   [3])
     ,                       .M3_AWLOCK    ( M_AWLOCK  [3])
     ,                       .M3_AWSIZE    ( M_AWSIZE  [3])
     ,                       .M3_AWBURST   ( M_AWBURST [3])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M3_AWCACHE   ( M_AWCACHE [3])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M3_AWPROT    ( M_AWPROT  [3])
     `endif
     ,                       .M3_AWVALID   ( M_AWVALID [3])
     ,                       .M3_AWREADY   ( M_AWREADY [3])
     `ifdef AMBA_QOS           3           (           [3])
     ,                       .M3_AWQOS     ( M_AWQOS   [3])
     ,                       .M3_AWREGION  ( M_AWREGION[3])
     `endif
     `ifdef AMBA_AXI_AWUSER
     ,                       .M3_AWUSER    ( M_AWUSER  [3])
     `endif
     ,                       .M3_WDATA     ( M_WDATA   [3])
     ,                       .M3_WSTRB     ( M_WSTRB   [3])
     ,                       .M3_WLAST     ( M_WLAST   [3])
     ,                       .M3_WVALID    ( M_WVALID  [3])
     ,                       .M3_WREADY    ( M_WREADY  [3])
     `ifdef AMBA_AXI_WUSER
     ,                       .M3_WUSER     ( M_WUSER   [3])
     `endif
     ,                       .M3_BID       ( M_BID     [3])
     ,                       .M3_BRESP     ( M_BRESP   [3])
     ,                       .M3_BVALID    ( M_BVALID  [3])
     ,                       .M3_BREADY    ( M_BREADY  [3])
     `ifdef AMBA_AXI_BUSER
     ,                       .M3_BUSER     ( M_BUSER   [3])
     `endif
     ,                       .M3_ARID      ( M_ARID    [3])
     ,                       .M3_ARADDR    ( M_ARADDR  [3])
     ,                       .M3_ARLEN     ( M_ARLEN   [3])
     ,                       .M3_ARLOCK    ( M_ARLOCK  [3])
     ,                       .M3_ARSIZE    ( M_ARSIZE  [3])
     ,                       .M3_ARBURST   ( M_ARBURST [3])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M3_ARCACHE   ( M_ARCACHE [3])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M3_ARPROT    ( M_ARPROT  [3])
     `endif
     ,                       .M3_ARVALID   ( M_ARVALID [3])
     ,                       .M3_ARREADY   ( M_ARREADY [3])
     `ifdef AMBA_QOS
     ,                       .M3_ARQOS     ( M_ARQOS   [3])
     ,                       .M3_ARREGION  ( M_ARREGION[3])
     `endif
     `ifdef AMBA_AXI_ARUSER
     ,                       .M3_ARUSER    ( M_ARUSER  [3])
     `endif
     ,                       .M3_RID       ( M_RID     [3])
     ,                       .M3_RDATA     ( M_RDATA   [3])
     ,                       .M3_RRESP     ( M_RRESP   [3])
     ,                       .M3_RLAST     ( M_RLAST   [3])
     ,                       .M3_RVALID    ( M_RVALID  [3])
     ,                       .M3_RREADY    ( M_RREADY  [3])
     `ifdef AMBA_AXI_RUSER
     ,                       .M3_RUSER     ( M_RUSER   [3])
     `endif
     ,                       .M4_AWID      ( M_AWID    [4])
     ,                       .M4_AWADDR    ( M_AWADDR  [4])
     ,                       .M4_AWLEN     ( M_AWLEN   [4])
     ,                       .M4_AWLOCK    ( M_AWLOCK  [4])
     ,                       .M4_AWSIZE    ( M_AWSIZE  [4])
     ,                       .M4_AWBURST   ( M_AWBURST [4])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M4_AWCACHE   ( M_AWCACHE [4])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M4_AWPROT    ( M_AWPROT  [4])
     `endif
     ,                       .M4_AWVALID   ( M_AWVALID [4])
     ,                       .M4_AWREADY   ( M_AWREADY [4])
     `ifdef AMBA_QOS
     ,                       .M4_AWQOS     ( M_AWQOS   [4])
     ,                       .M4_AWREGION  ( M_AWREGION[4])
     `endif
     `ifdef AMBA_AXI_AWUSER
     ,                       .M4_AWUSER    ( M_AWUSER  [4])
     `endif
     ,                       .M4_WDATA     ( M_WDATA   [4])
     ,                       .M4_WSTRB     ( M_WSTRB   [4])
     ,                       .M4_WLAST     ( M_WLAST   [4])
     ,                       .M4_WVALID    ( M_WVALID  [4])
     ,                       .M4_WREADY    ( M_WREADY  [4])
     `ifdef AMBA_AXI_WUSER
                             .M4_WUSER     ( M_WUSER   [4])
     `endif
     ,                       .M4_BID       ( M_BID     [4])
     ,                       .M4_BRESP     ( M_BRESP   [4])
     ,                       .M4_BVALID    ( M_BVALID  [4])
     ,                       .M4_BREADY    ( M_BREADY  [4])
     `ifdef AMBA_AXI_BUSER
                             .M4_BUSER     ( M_BUSER   [4])
     `endif
     ,                       .M4_ARID      ( M_ARID    [4])
     ,                       .M4_ARADDR    ( M_ARADDR  [4])
     ,                       .M4_ARLEN     ( M_ARLEN   [4])
     ,                       .M4_ARLOCK    ( M_ARLOCK  [4])
     ,                       .M4_ARSIZE    ( M_ARSIZE  [4])
     ,                       .M4_ARBURST   ( M_ARBURST [4])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M4_ARCACHE   ( M_ARCACHE [4])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M4_ARPROT    ( M_ARPROT  [4])
     `endif
     ,                       .M4_ARVALID   ( M_ARVALID [4])
     ,                       .M4_ARREADY   ( M_ARREADY [4])
     `ifdef AMBA_QOS
     ,                       .M4_ARQOS     ( M_ARQOS   [4])
     ,                       .M4_ARREGION  ( M_ARREGION[4])
     `endif
     `ifdef AMBA_AXI_ARUSER
     ,                       .M4_ARUSER    ( M_ARUSER  [4])
     `endif
     ,                       .M4_RID       ( M_RID     [4])
     ,                       .M4_RDATA     ( M_RDATA   [4])
     ,                       .M4_RRESP     ( M_RRESP   [4])
     ,                       .M4_RLAST     ( M_RLAST   [4])
     ,                       .M4_RVALID    ( M_RVALID  [4])
     ,                       .M4_RREADY    ( M_RREADY  [4])
     `ifdef AMBA_AXI_RUSER
     ,                       .M4_RUSER     ( M_RUSER   [4])
     `endif
     ,                       .M5_AWID      ( M_AWID    [5])
     ,                       .M5_AWADDR    ( M_AWADDR  [5])
     ,                       .M5_AWLEN     ( M_AWLEN   [5])
     ,                       .M5_AWLOCK    ( M_AWLOCK  [5])
     ,                       .M5_AWSIZE    ( M_AWSIZE  [5])
     ,                       .M5_AWBURST   ( M_AWBURST [5])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M5_AWCACHE   ( M_AWCACHE [5])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M5_AWPROT    ( M_AWPROT  [5])
     `endif
     ,                       .M5_AWVALID   ( M_AWVALID [5])
     ,                       .M5_AWREADY   ( M_AWREADY [5])
     `ifdef AMBA_QOS           5           (           [5])
     ,                       .M5_AWQOS     ( M_AWQOS   [5])
     ,                       .M5_AWREGION  ( M_AWREGION[5])
     `endif
     `ifdef AMBA_AXI_AWUSER
     ,                       .M5_AWUSER    ( M_AWUSER  [5])
     `endif
     ,                       .M5_WDATA     ( M_WDATA   [5])
     ,                       .M5_WSTRB     ( M_WSTRB   [5])
     ,                       .M5_WLAST     ( M_WLAST   [5])
     ,                       .M5_WVALID    ( M_WVALID  [5])
     ,                       .M5_WREADY    ( M_WREADY  [5])
     `ifdef AMBA_AXI_WUSER
     ,                       .M5_WUSER     ( M_WUSER   [5])
     `endif
     ,                       .M5_BID       ( M_BID     [5])
     ,                       .M5_BRESP     ( M_BRESP   [5])
     ,                       .M5_BVALID    ( M_BVALID  [5])
     ,                       .M5_BREADY    ( M_BREADY  [5])
     `ifdef AMBA_AXI_BUSER
     ,                       .M5_BUSER     ( M_BUSER   [5])
     `endif
     ,                       .M5_ARID      ( M_ARID    [5])
     ,                       .M5_ARADDR    ( M_ARADDR  [5])
     ,                       .M5_ARLEN     ( M_ARLEN   [5])
     ,                       .M5_ARLOCK    ( M_ARLOCK  [5])
     ,                       .M5_ARSIZE    ( M_ARSIZE  [5])
     ,                       .M5_ARBURST   ( M_ARBURST [5])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M5_ARCACHE   ( M_ARCACHE [5])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M5_ARPROT    ( M_ARPROT  [5])
     `endif
     ,                       .M5_ARVALID   ( M_ARVALID [5])
     ,                       .M5_ARREADY   ( M_ARREADY [5])
     `ifdef AMBA_QOS
     ,                       .M5_ARQOS     ( M_ARQOS   [5])
     ,                       .M5_ARREGION  ( M_ARREGION[5])
     `endif
     `ifdef AMBA_AXI_ARUSER
     ,                       .M5_ARUSER    ( M_ARUSER  [5])
     `endif
     ,                       .M5_RID       ( M_RID     [5])
     ,                       .M5_RDATA     ( M_RDATA   [5])
     ,                       .M5_RRESP     ( M_RRESP   [5])
     ,                       .M5_RLAST     ( M_RLAST   [5])
     ,                       .M5_RVALID    ( M_RVALID  [5])
     ,                       .M5_RREADY    ( M_RREADY  [5])
     `ifdef AMBA_AXI_RUSER
     ,                       .M5_RUSER     ( M_RUSER   [5])
     `endif
     ,                       .M6_AWID      ( M_AWID    [6])
     ,                       .M6_AWADDR    ( M_AWADDR  [6])
     ,                       .M6_AWLEN     ( M_AWLEN   [6])
     ,                       .M6_AWLOCK    ( M_AWLOCK  [6])
     ,                       .M6_AWSIZE    ( M_AWSIZE  [6])
     ,                       .M6_AWBURST   ( M_AWBURST [6])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M6_AWCACHE   ( M_AWCACHE [6])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M6_AWPROT    ( M_AWPROT  [6])
     `endif
     ,                       .M6_AWVALID   ( M_AWVALID [6])
     ,                       .M6_AWREADY   ( M_AWREADY [6])
     `ifdef AMBA_QOS
     ,                       .M6_AWQOS     ( M_AWQOS   [6])
     ,                       .M6_AWREGION  ( M_AWREGION[6])
     `endif
     `ifdef AMBA_AXI_AWUSER
     ,                       .M6_AWUSER    ( M_AWUSER  [6])
     `endif
     ,                       .M6_WDATA     ( M_WDATA   [6])
     ,                       .M6_WSTRB     ( M_WSTRB   [6])
     ,                       .M6_WLAST     ( M_WLAST   [6])
     ,                       .M6_WVALID    ( M_WVALID  [6])
     ,                       .M6_WREADY    ( M_WREADY  [6])
     `ifdef AMBA_AXI_WUSER
                             .M6_WUSER     ( M_WUSER   [6])
     `endif
     ,                       .M6_BID       ( M_BID     [6])
     ,                       .M6_BRESP     ( M_BRESP   [6])
     ,                       .M6_BVALID    ( M_BVALID  [6])
     ,                       .M6_BREADY    ( M_BREADY  [6])
     `ifdef AMBA_AXI_BUSER
                             .M6_BUSER     ( M_BUSER   [6])
     `endif
     ,                       .M6_ARID      ( M_ARID    [6])
     ,                       .M6_ARADDR    ( M_ARADDR  [6])
     ,                       .M6_ARLEN     ( M_ARLEN   [6])
     ,                       .M6_ARLOCK    ( M_ARLOCK  [6])
     ,                       .M6_ARSIZE    ( M_ARSIZE  [6])
     ,                       .M6_ARBURST   ( M_ARBURST [6])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M6_ARCACHE   ( M_ARCACHE [6])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M6_ARPROT    ( M_ARPROT  [6])
     `endif
     ,                       .M6_ARVALID   ( M_ARVALID [6])
     ,                       .M6_ARREADY   ( M_ARREADY [6])
     `ifdef AMBA_QOS
     ,                       .M6_ARQOS     ( M_ARQOS   [6])
     ,                       .M6_ARREGION  ( M_ARREGION[6])
     `endif
     `ifdef AMBA_AXI_ARUSER
     ,                       .M6_ARUSER    ( M_ARUSER  [6])
     `endif
     ,                       .M6_RID       ( M_RID     [6])
     ,                       .M6_RDATA     ( M_RDATA   [6])
     ,                       .M6_RRESP     ( M_RRESP   [6])
     ,                       .M6_RLAST     ( M_RLAST   [6])
     ,                       .M6_RVALID    ( M_RVALID  [6])
     ,                       .M6_RREADY    ( M_RREADY  [6])
     `ifdef AMBA_AXI_RUSER
     ,                       .M6_RUSER     ( M_RUSER   [6])
     `endif
     ,                       .M7_AWID      ( M_AWID    [7])
     ,                       .M7_AWADDR    ( M_AWADDR  [7])
     ,                       .M7_AWLEN     ( M_AWLEN   [7])
     ,                       .M7_AWLOCK    ( M_AWLOCK  [7])
     ,                       .M7_AWSIZE    ( M_AWSIZE  [7])
     ,                       .M7_AWBURST   ( M_AWBURST [7])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M7_AWCACHE   ( M_AWCACHE [7])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M7_AWPROT    ( M_AWPROT  [7])
     `endif
     ,                       .M7_AWVALID   ( M_AWVALID [7])
     ,                       .M7_AWREADY   ( M_AWREADY [7])
     `ifdef AMBA_QOS           7           (           [7])
     ,                       .M7_AWQOS     ( M_AWQOS   [7])
     ,                       .M7_AWREGION  ( M_AWREGION[7])
     `endif
     `ifdef AMBA_AXI_AWUSER
     ,                       .M7_AWUSER    ( M_AWUSER  [7])
     `endif
     ,                       .M7_WDATA     ( M_WDATA   [7])
     ,                       .M7_WSTRB     ( M_WSTRB   [7])
     ,                       .M7_WLAST     ( M_WLAST   [7])
     ,                       .M7_WVALID    ( M_WVALID  [7])
     ,                       .M7_WREADY    ( M_WREADY  [7])
     `ifdef AMBA_AXI_WUSER
     ,                       .M7_WUSER     ( M_WUSER   [7])
     `endif
     ,                       .M7_BID       ( M_BID     [7])
     ,                       .M7_BRESP     ( M_BRESP   [7])
     ,                       .M7_BVALID    ( M_BVALID  [7])
     ,                       .M7_BREADY    ( M_BREADY  [7])
     `ifdef AMBA_AXI_BUSER
     ,                       .M7_BUSER     ( M_BUSER   [7])
     `endif
     ,                       .M7_ARID      ( M_ARID    [7])
     ,                       .M7_ARADDR    ( M_ARADDR  [7])
     ,                       .M7_ARLEN     ( M_ARLEN   [7])
     ,                       .M7_ARLOCK    ( M_ARLOCK  [7])
     ,                       .M7_ARSIZE    ( M_ARSIZE  [7])
     ,                       .M7_ARBURST   ( M_ARBURST [7])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M7_ARCACHE   ( M_ARCACHE [7])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M7_ARPROT    ( M_ARPROT  [7])
     `endif
     ,                       .M7_ARVALID   ( M_ARVALID [7])
     ,                       .M7_ARREADY   ( M_ARREADY [7])
     `ifdef AMBA_QOS
     ,                       .M7_ARQOS     ( M_ARQOS   [7])
     ,                       .M7_ARREGION  ( M_ARREGION[7])
     `endif
     `ifdef AMBA_AXI_ARUSER
     ,                       .M7_ARUSER    ( M_ARUSER  [7])
     `endif
     ,                       .M7_RID       ( M_RID     [7])
     ,                       .M7_RDATA     ( M_RDATA   [7])
     ,                       .M7_RRESP     ( M_RRESP   [7])
     ,                       .M7_RLAST     ( M_RLAST   [7])
     ,                       .M7_RVALID    ( M_RVALID  [7])
     ,                       .M7_RREADY    ( M_RREADY  [7])
     `ifdef AMBA_AXI_RUSER
     ,                       .M7_RUSER     ( M_RUSER   [7])
     `endif
     ,                       .S0_AWID      ( S_AWID    [0])
     ,                       .S0_AWADDR    ( S_AWADDR  [0])
     ,                       .S0_AWLEN     ( S_AWLEN   [0])
     ,                       .S0_AWLOCK    ( S_AWLOCK  [0])
     ,                       .S0_AWSIZE    ( S_AWSIZE  [0])
     ,                       .S0_AWBURST   ( S_AWBURST [0])
     `ifdef  AMBA_AXI_CACHE
     ,                       .S0_AWCACHE   ( S_AWCACHE [0])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .S0_AWPROT    ( S_AWPROT  [0])
     `endif
     ,                       .S0_AWVALID   ( S_AWVALID [0])
     ,                       .S0_AWREADY   ( S_AWREADY [0])
     `ifdef AMBA_QOS
     ,                       .S0_AWQOS     ( S_AWQOS   [0])
     ,                       .S0_AWREGION  ( S_AWREGION[0])
     `endif
     `ifdef AMBA_AXI_AWUSER
     ,                       .S0_AWUSER    ( S_AWUSER  [0])
     `endif
     ,                       .S0_WDATA     ( S_WDATA   [0])
     ,                       .S0_WSTRB     ( S_WSTRB   [0])
     ,                       .S0_WLAST     ( S_WLAST   [0])
     ,                       .S0_WVALID    ( S_WVALID  [0])
     ,                       .S0_WREADY    ( S_WREADY  [0])
     `ifdef AMBA_AXI_WUSER
     ,                       .S0_WUSER     ( S_WUSER   [0])
     `endif
     ,                       .S0_BID       ( S_BID     [0])
     ,                       .S0_BRESP     ( S_BRESP   [0])
     ,                       .S0_BVALID    ( S_BVALID  [0])
     ,                       .S0_BREADY    ( S_BREADY  [0])
     `ifdef AMBA_AXI_BUSER
     ,                       .S0_BUSER     ( S_BUSER   [0])
     `endif
     ,                       .S0_ARID      ( S_ARID    [0])
     ,                       .S0_ARADDR    ( S_ARADDR  [0])
     ,                       .S0_ARLEN     ( S_ARLEN   [0])
     ,                       .S0_ARLOCK    ( S_ARLOCK  [0])
     ,                       .S0_ARSIZE    ( S_ARSIZE  [0])
     ,                       .S0_ARBURST   ( S_ARBURST [0])
     `ifdef  AMBA_AXI_CACHE
     ,                       .S0_ARCACHE   ( S_ARCACHE [0])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .S0_ARPROT    ( S_ARPROT  [0])
     `endif
     ,                       .S0_ARVALID   ( S_ARVALID [0])
     ,                       .S0_ARREADY   ( S_ARREADY [0])
     `ifdef AMBA_QOS
     ,                       .S0_ARQOS     ( S_ARQOS   [0])
     ,                       .S0_ARREGION  ( S_ARREGION[0])
     `endif
     `ifdef AMBA_AXI_ARUSER
     ,                       .S0_ARUSER    ( S_ARUSER  [0])
     `endif
     ,                       .S0_RID       ( S_RID     [0])
     ,                       .S0_RDATA     ( S_RDATA   [0])
     ,                       .S0_RRESP     ( S_RRESP   [0])
     ,                       .S0_RLAST     ( S_RLAST   [0])
     ,                       .S0_RVALID    ( S_RVALID  [0])
     ,                       .S0_RREADY    ( S_RREADY  [0])
     `ifdef AMBA_AXI_RUSER
     ,                       .S0_RUSER     ( S_RUSER   [0])
     `endif
     ,                       .S1_AWID      ( S_AWID    [1])
     ,                       .S1_AWADDR    ( S_AWADDR  [1])
     ,                       .S1_AWLEN     ( S_AWLEN   [1])
     ,                       .S1_AWLOCK    ( S_AWLOCK  [1])
     ,                       .S1_AWSIZE    ( S_AWSIZE  [1])
     ,                       .S1_AWBURST   ( S_AWBURST [1])
     `ifdef  AMBA_AXI_CACHE
     ,                       .S1_AWCACHE   ( S_AWCACHE [1])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .S1_AWPROT    ( S_AWPROT  [1])
     `endif
     ,                       .S1_AWVALID   ( S_AWVALID [1])
     ,                       .S1_AWREADY   ( S_AWREADY [1])
     `ifdef AMBA_QOS
     ,                       .S1_AWQOS     ( S_AWQOS   [1])
     ,                       .S1_AWREGION  ( S_AWREGION[1])
     `endif
     `ifdef AMBA_AXI_AWUSER
     ,                       .S1_AWUSER    ( S_AWUSER  [1])
     `endif
     ,                       .S1_WDATA     ( S_WDATA   [1])
     ,                       .S1_WSTRB     ( S_WSTRB   [1])
     ,                       .S1_WLAST     ( S_WLAST   [1])
     ,                       .S1_WVALID    ( S_WVALID  [1])
     ,                       .S1_WREADY    ( S_WREADY  [1])
     `ifdef AMBA_AXI_WUSER
     ,                       .S1_WUSER     ( S_WUSER   [1])
     `endif
     ,                       .S1_BID       ( S_BID     [1])
     ,                       .S1_BRESP     ( S_BRESP   [1])
     ,                       .S1_BVALID    ( S_BVALID  [1])
     ,                       .S1_BREADY    ( S_BREADY  [1])
     `ifdef AMBA_AXI_BUSER
     ,                       .S1_BUSER     ( S_BUSER   [1])
     `endif
     ,                       .S1_ARID      ( S_ARID    [1])
     ,                       .S1_ARADDR    ( S_ARADDR  [1])
     ,                       .S1_ARLEN     ( S_ARLEN   [1])
     ,                       .S1_ARLOCK    ( S_ARLOCK  [1])
     ,                       .S1_ARSIZE    ( S_ARSIZE  [1])
     ,                       .S1_ARBURST   ( S_ARBURST [1])
     `ifdef  AMBA_AXI_CACHE
     ,                       .S1_ARCACHE   ( S_ARCACHE [1])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .S1_ARPROT    ( S_ARPROT  [1])
     `endif
     ,                       .S1_ARVALID   ( S_ARVALID [1])
     ,                       .S1_ARREADY   ( S_ARREADY [1])
     `ifdef AMBA_QOS
     ,                       .S1_ARQOS     ( S_ARQOS   [1])
     ,                       .S1_ARREGION  ( S_ARREGION[1])
     `endif
     `ifdef AMBA_AXI_ARUSER
     ,                       .S1_ARUSER    ( S_ARUSER  [1])
     `endif
     ,                       .S1_RID       ( S_RID     [1])
     ,                       .S1_RDATA     ( S_RDATA   [1])
     ,                       .S1_RRESP     ( S_RRESP   [1])
     ,                       .S1_RLAST     ( S_RLAST   [1])
     ,                       .S1_RVALID    ( S_RVALID  [1])
     ,                       .S1_RREADY    ( S_RREADY  [1])
     `ifdef AMBA_AXI_RUSER
     ,                       .S1_RUSER     ( S_RUSER   [1])
     `endif
    );
