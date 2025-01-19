//------------------------------------------------------------------------------
    localparam P_NUM_AXI_MASTER  = 8; // should not be changed
    localparam P_NUM_AXI_SLAVE   = 2; // should not be changed
    localparam P_AXI_WIDTH_CID   =$clog2(P_NUM_AXI_MASTER);// ID width in bits
    localparam P_AXI_WIDTH_ID    = 4;                   // ID width in bits
    localparam P_AXI_WIDTH_AD    =`AMBA_AXI_WIDTH_AD;
    localparam P_AXI_WIDTH_DA    =`AMBA_AXI_WIDTH_DA;
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
               wire  [P_AXI_WIDTH_ID-1:0]      `NET_DELAY   m_axi_AWID      [P_NUM_AXI_MASTER-1:0];
               wire  [P_AXI_WIDTH_AD-1:0]      `NET_DELAY   m_axi_AWADDR    [P_NUM_AXI_MASTER-1:0];
               wire  [ 7:0]                    `NET_DELAY   m_axi_AWLEN     [P_NUM_AXI_MASTER-1:0];
               wire  [P_NUM_AXI_MASTER-1:0]    `NET_DELAY   m_axi_AWLOCK    ;
               wire  [ 2:0]                    `NET_DELAY   m_axi_AWSIZE    [P_NUM_AXI_MASTER-1:0];
               wire  [ 1:0]                    `NET_DELAY   m_axi_AWBURST   [P_NUM_AXI_MASTER-1:0];
     `ifdef  AMBA_AXI_CACHE
               wire  [ 3:0]                    `NET_DELAY   m_axi_AWCACHE   [P_NUM_AXI_MASTER-1:0];
     `endif
     `ifdef AMBA_AXI_PROT
               wire  [ 2:0]                    `NET_DELAY   m_axi_AWPROT    [P_NUM_AXI_MASTER-1:0];
     `endif
               wire  [P_NUM_AXI_MASTER-1:0]    `NET_DELAY   m_axi_AWVALID   ;
               wire  [P_NUM_AXI_MASTER-1:0]    `NET_DELAY   m_axi_AWREADY   ;
     `ifdef AMBA_QOS
               wire  [ 3:0]                    `NET_DELAY   m_axi_AWQOS     [P_NUM_AXI_MASTER-1:0];
               wire  [ 3:0]                    `NET_DELAY   m_axi_AWREGION  [P_NUM_AXI_MASTER-1:0];
     `endif
     `ifdef AMBA_AXI_AWUSER
               wire  [P_AXI_WIDTH_AWUSER-1:0]  `NET_DELAY   m_axi_AWUSER    [P_NUM_AXI_MASTER-1:0];
     `endif
               wire  [P_AXI_WIDTH_DA-1:0]      `NET_DELAY   m_axi_WDATA     [P_NUM_AXI_MASTER-1:0];
               wire  [P_AXI_WIDTH_DS-1:0]      `NET_DELAY   m_axi_WSTRB     [P_NUM_AXI_MASTER-1:0];
               wire  [P_NUM_AXI_MASTER-1:0]    `NET_DELAY   m_axi_WLAST     ;
               wire  [P_NUM_AXI_MASTER-1:0]    `NET_DELAY   m_axi_WVALID    ;
               wire  [P_NUM_AXI_MASTER-1:0]    `NET_DELAY   m_axi_WREADY    ;
     `ifdef AMBA_AXI_WUSER
               wire  [P_AXI_WIDTH_WUSER-1:0]   `NET_DELAY   m_axi_WUSER     [P_NUM_AXI_MASTER-1:0];
     `endif
               wire  [P_AXI_WIDTH_ID-1:0]      `NET_DELAY   m_axi_BID       [P_NUM_AXI_MASTER-1:0];
               wire  [ 1:0]                    `NET_DELAY   m_axi_BRESP     [P_NUM_AXI_MASTER-1:0];
               wire  [P_NUM_AXI_MASTER-1:0]    `NET_DELAY   m_axi_BVALID    ;
               wire  [P_NUM_AXI_MASTER-1:0]    `NET_DELAY   m_axi_BREADY    ;
     `ifdef AMBA_AXI_BUSER
               wire  [P_AXI_WIDTH_BUSER-1:0]   `NET_DELAY   m_axi_BUSER     [P_NUM_AXI_MASTER-1:0];
     `endif
               wire  [P_AXI_WIDTH_ID-1:0]      `NET_DELAY   m_axi_ARID      [P_NUM_AXI_MASTER-1:0];
               wire  [P_AXI_WIDTH_AD-1:0]      `NET_DELAY   m_axi_ARADDR    [P_NUM_AXI_MASTER-1:0];
               wire  [ 7:0]                    `NET_DELAY   m_axi_ARLEN     [P_NUM_AXI_MASTER-1:0];
               wire  [P_NUM_AXI_MASTER-1:0]    `NET_DELAY   m_axi_ARLOCK    ;
               wire  [ 2:0]                    `NET_DELAY   m_axi_ARSIZE    [P_NUM_AXI_MASTER-1:0];
               wire  [ 1:0]                    `NET_DELAY   m_axi_ARBURST   [P_NUM_AXI_MASTER-1:0];
     `ifdef  AMBA_AXI_CACHE
               wire  [ 3:0]                    `NET_DELAY   m_axi_ARCACHE   [P_NUM_AXI_MASTER-1:0];
     `endif
     `ifdef AMBA_AXI_PROT
               wire  [ 2:0]                    `NET_DELAY   m_axi_ARPROT    [P_NUM_AXI_MASTER-1:0];
     `endif
               wire  [P_NUM_AXI_MASTER-1:0]    `NET_DELAY   m_axi_ARVALID   ;
               wire  [P_NUM_AXI_MASTER-1:0]    `NET_DELAY   m_axi_ARREADY   ;
     `ifdef AMBA_QOS
               wire  [ 3:0]                    `NET_DELAY   m_axi_ARQOS     [P_NUM_AXI_MASTER-1:0];
               wire  [ 3:0]                    `NET_DELAY   m_axi_ARREGION  [P_NUM_AXI_MASTER-1:0];
     `endif
     `ifdef AMBA_AXI_ARUSER
               wire  [P_AXI_WIDTH_ARUSER-1:0]  `NET_DELAY   m_axi_ARUSER    [P_NUM_AXI_MASTER-1:0];
     `endif
               wire  [P_AXI_WIDTH_ID-1:0]      `NET_DELAY   m_axi_RID       [P_NUM_AXI_MASTER-1:0];
               wire  [P_AXI_WIDTH_DA-1:0]      `NET_DELAY   m_axi_RDATA     [P_NUM_AXI_MASTER-1:0];
               wire  [ 1:0]                    `NET_DELAY   m_axi_RRESP     [P_NUM_AXI_MASTER-1:0];
               wire  [P_NUM_AXI_MASTER-1:0]    `NET_DELAY   m_axi_RLAST     ;
               wire  [P_NUM_AXI_MASTER-1:0]    `NET_DELAY   m_axi_RVALID    ;
               wire  [P_NUM_AXI_MASTER-1:0]    `NET_DELAY   m_axi_RREADY    ;
     `ifdef AMBA_AXI_RUSER
               wire  [P_AXI_WIDTH_RUSER-1:0]   `NET_DELAY   m_axi_RUSER     [P_NUM_AXI_MASTER-1:0];
     `endif
//--------------------------------------------------------------------------------------
               wire   [P_AXI_WIDTH_SID-1:0]    `NET_DELAY   s_axi_AWID      [P_NUM_AXI_SLAVE-1:0];
               wire   [P_AXI_WIDTH_AD-1:0]     `NET_DELAY   s_axi_AWADDR    [P_NUM_AXI_SLAVE-1:0];
               wire   [ 7:0]                   `NET_DELAY   s_axi_AWLEN     [P_NUM_AXI_SLAVE-1:0];
               wire                            `NET_DELAY   s_axi_AWLOCK    [P_NUM_AXI_SLAVE-1:0];
               wire   [ 2:0]                   `NET_DELAY   s_axi_AWSIZE    [P_NUM_AXI_SLAVE-1:0];
               wire   [ 1:0]                   `NET_DELAY   s_axi_AWBURST   [P_NUM_AXI_SLAVE-1:0];
     `ifdef  AMBA_AXI_CACHE
               wire   [ 3:0]                   `NET_DELAY   s_axi_AWCACHE   [P_NUM_AXI_SLAVE-1:0];
     `endif
     `ifdef AMBA_AXI_PROT
               wire   [ 2:0]                   `NET_DELAY   s_axi_AWPROT    [P_NUM_AXI_SLAVE-1:0];
     `endif
               wire                            `NET_DELAY   s_axi_AWVALID   [P_NUM_AXI_SLAVE-1:0];
               wire                            `NET_DELAY   s_axi_AWREADY   [P_NUM_AXI_SLAVE-1:0];
     `ifdef AMBA_QOS
               wire   [ 3:0]                   `NET_DELAY   s_axi_AWQOS     [P_NUM_AXI_SLAVE-1:0];
               wire   [ 3:0]                   `NET_DELAY   s_axi_AWREGION  [P_NUM_AXI_SLAVE-1:0];
     `endif
     `ifdef AMBA_AXI_AWUSER
               wire   [P_AXI_WIDTH_AWUSER-1:0] `NET_DELAY   s_axi_AWUSER    [P_NUM_AXI_SLAVE-1:0];
     `endif
               wire   [P_AXI_WIDTH_DA-1:0]     `NET_DELAY   s_axi_WDATA     [P_NUM_AXI_SLAVE-1:0];
               wire   [P_AXI_WIDTH_DS-1:0]     `NET_DELAY   s_axi_WSTRB     [P_NUM_AXI_SLAVE-1:0];
               wire                            `NET_DELAY   s_axi_WLAST     [P_NUM_AXI_SLAVE-1:0];
               wire                            `NET_DELAY   s_axi_WVALID    [P_NUM_AXI_SLAVE-1:0];
               wire                            `NET_DELAY   s_axi_WREADY    [P_NUM_AXI_SLAVE-1:0];
     `ifdef AMBA_AXI_WUSER
               wire   [P_AXI_WIDTH_WUSER-1:0]  `NET_DELAY   s_axi_WUSER     [P_NUM_AXI_SLAVE-1:0];
     `endif
               wire   [P_AXI_WIDTH_SID-1:0]    `NET_DELAY   s_axi_BID       [P_NUM_AXI_SLAVE-1:0];
               wire   [ 1:0]                   `NET_DELAY   s_axi_BRESP     [P_NUM_AXI_SLAVE-1:0];
               wire                            `NET_DELAY   s_axi_BVALID    [P_NUM_AXI_SLAVE-1:0];
               wire                            `NET_DELAY   s_axi_BREADY    [P_NUM_AXI_SLAVE-1:0];
     `ifdef AMBA_AXI_BUSER
               wire   [P_AXI_WIDTH_BUSER-1:0]  `NET_DELAY   s_axi_BUSER     [P_NUM_AXI_SLAVE-1:0];
     `endif
               wire   [P_AXI_WIDTH_SID-1:0]    `NET_DELAY   s_axi_ARID      [P_NUM_AXI_SLAVE-1:0];
               wire   [P_AXI_WIDTH_AD-1:0]     `NET_DELAY   s_axi_ARADDR    [P_NUM_AXI_SLAVE-1:0];
               wire   [ 7:0]                   `NET_DELAY   s_axi_ARLEN     [P_NUM_AXI_SLAVE-1:0];
               wire                            `NET_DELAY   s_axi_ARLOCK    [P_NUM_AXI_SLAVE-1:0];
               wire   [ 2:0]                   `NET_DELAY   s_axi_ARSIZE    [P_NUM_AXI_SLAVE-1:0];
               wire   [ 1:0]                   `NET_DELAY   s_axi_ARBURST   [P_NUM_AXI_SLAVE-1:0];
     `ifdef  AMBA_AXI_CACHE
               wire   [ 3:0]                   `NET_DELAY   s_axi_ARCACHE   [P_NUM_AXI_SLAVE-1:0];
     `endif
     `ifdef AMBA_AXI_PROT
               wire   [ 2:0]                   `NET_DELAY   s_axi_ARPROT    [P_NUM_AXI_SLAVE-1:0];
     `endif
               wire                            `NET_DELAY   s_axi_ARVALID   [P_NUM_AXI_SLAVE-1:0];
               wire                            `NET_DELAY   s_axi_ARREADY   [P_NUM_AXI_SLAVE-1:0];
     `ifdef AMBA_QOS
               wire   [ 3:0]                   `NET_DELAY   s_axi_ARQOS     [P_NUM_AXI_SLAVE-1:0];
               wire   [ 3:0]                   `NET_DELAY   s_axi_ARREGION  [P_NUM_AXI_SLAVE-1:0];
     `endif
     `ifdef AMBA_AXI_ARUSER
               wire   [P_AXI_WIDTH_ARUSER-1:0] `NET_DELAY   s_axi_ARUSER    [P_NUM_AXI_SLAVE-1:0];
     `endif
               wire   [P_AXI_WIDTH_SID-1:0]    `NET_DELAY   s_axi_RID       [P_NUM_AXI_SLAVE-1:0];
               wire   [P_AXI_WIDTH_DA-1:0]     `NET_DELAY   s_axi_RDATA     [P_NUM_AXI_SLAVE-1:0];
               wire   [ 1:0]                   `NET_DELAY   s_axi_RRESP     [P_NUM_AXI_SLAVE-1:0];
               wire                            `NET_DELAY   s_axi_RLAST     [P_NUM_AXI_SLAVE-1:0];
               wire                            `NET_DELAY   s_axi_RVALID    [P_NUM_AXI_SLAVE-1:0];
               wire                            `NET_DELAY   s_axi_RREADY    [P_NUM_AXI_SLAVE-1:0];
     `ifdef AMBA_AXI_RUSER
               wire   [WIDTH_RUSER-1:0]        `NET_DELAY   s_axi_RUSER     [P_NUM_AXI_SLAVE-1:0];
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
     ,                       .M0_AWID      ( m_axi_AWID    [0])
     ,                       .M0_AWADDR    ( m_axi_AWADDR  [0])
     ,                       .M0_AWLEN     ( m_axi_AWLEN   [0])
     ,                       .M0_AWLOCK    ( m_axi_AWLOCK  [0])
     ,                       .M0_AWSIZE    ( m_axi_AWSIZE  [0])
     ,                       .M0_AWBURST   ( m_axi_AWBURST [0])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M0_AWCACHE   ( m_axi_AWCACHE [0])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M0_AWPROT    ( m_axi_AWPROT  [0])
     `endif
     ,                       .M0_AWVALID   ( m_axi_AWVALID [0])
     ,                       .M0_AWREADY   ( m_axi_AWREADY [0])
     `ifdef AMBA_QOS
     ,                       .M0_AWQOS     ( m_axi_AWQOS   [0])
     ,                       .M0_AWREGION  ( m_axi_AWREGION[0])
     `endif
     `ifdef AMBA_AXI_AWUSER
     ,                       .M0_AWUSER    ( m_axi_AWUSER  [0])
     `endif
     ,                       .M0_WDATA     ( m_axi_WDATA   [0])
     ,                       .M0_WSTRB     ( m_axi_WSTRB   [0])
     ,                       .M0_WLAST     ( m_axi_WLAST   [0])
     ,                       .M0_WVALID    ( m_axi_WVALID  [0])
     ,                       .M0_WREADY    ( m_axi_WREADY  [0])
     `ifdef AMBA_AXI_WUSER
                             .M0_WUSER     ( m_axi_WUSER   [0])
     `endif
     ,                       .M0_BID       ( m_axi_BID     [0])
     ,                       .M0_BRESP     ( m_axi_BRESP   [0])
     ,                       .M0_BVALID    ( m_axi_BVALID  [0])
     ,                       .M0_BREADY    ( m_axi_BREADY  [0])
     `ifdef AMBA_AXI_BUSER
                             .M0_BUSER     ( m_axi_BUSER   [0])
     `endif
     ,                       .M0_ARID      ( m_axi_ARID    [0])
     ,                       .M0_ARADDR    ( m_axi_ARADDR  [0])
     ,                       .M0_ARLEN     ( m_axi_ARLEN   [0])
     ,                       .M0_ARLOCK    ( m_axi_ARLOCK  [0])
     ,                       .M0_ARSIZE    ( m_axi_ARSIZE  [0])
     ,                       .M0_ARBURST   ( m_axi_ARBURST [0])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M0_ARCACHE   ( m_axi_ARCACHE [0])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M0_ARPROT    ( m_axi_ARPROT  [0])
     `endif
     ,                       .M0_ARVALID   ( m_axi_ARVALID [0])
     ,                       .M0_ARREADY   ( m_axi_ARREADY [0])
     `ifdef AMBA_QOS
     ,                       .M0_ARQOS     ( m_axi_ARQOS   [0])
     ,                       .M0_ARREGION  ( m_axi_ARREGION[0])
     `endif
     `ifdef AMBA_AXI_ARUSER
     ,                       .M0_ARUSER    ( m_axi_ARUSER  [0])
     `endif
     ,                       .M0_RID       ( m_axi_RID     [0])
     ,                       .M0_RDATA     ( m_axi_RDATA   [0])
     ,                       .M0_RRESP     ( m_axi_RRESP   [0])
     ,                       .M0_RLAST     ( m_axi_RLAST   [0])
     ,                       .M0_RVALID    ( m_axi_RVALID  [0])
     ,                       .M0_RREADY    ( m_axi_RREADY  [0])
     `ifdef AMBA_AXI_RUSER
     ,                       .M0_RUSER     ( m_axi_RUSER   [0])
     `endif
     ,                       .M1_AWID      ( m_axi_AWID    [1])
     ,                       .M1_AWADDR    ( m_axi_AWADDR  [1])
     ,                       .M1_AWLEN     ( m_axi_AWLEN   [1])
     ,                       .M1_AWLOCK    ( m_axi_AWLOCK  [1])
     ,                       .M1_AWSIZE    ( m_axi_AWSIZE  [1])
     ,                       .M1_AWBURST   ( m_axi_AWBURST [1])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M1_AWCACHE   ( m_axi_AWCACHE [1])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M1_AWPROT    ( m_axi_AWPROT  [1])
     `endif
     ,                       .M1_AWVALID   ( m_axi_AWVALID [1])
     ,                       .M1_AWREADY   ( m_axi_AWREADY [1])
     `ifdef AMBA_QOS                       ( m_axi         [ ])
     ,                       .M1_AWQOS     ( m_axi_AWQOS   [1])
     ,                       .M1_AWREGION  ( m_axi_AWREGION[1])
     `endif
     `ifdef AMBA_AXI_AWUSER
     ,                       .M1_AWUSER    ( m_axi_AWUSER  [1])
     `endif
     ,                       .M1_WDATA     ( m_axi_WDATA   [1])
     ,                       .M1_WSTRB     ( m_axi_WSTRB   [1])
     ,                       .M1_WLAST     ( m_axi_WLAST   [1])
     ,                       .M1_WVALID    ( m_axi_WVALID  [1])
     ,                       .M1_WREADY    ( m_axi_WREADY  [1])
     `ifdef AMBA_AXI_WUSER
     ,                       .M1_WUSER     ( m_axi_WUSER   [1])
     `endif
     ,                       .M1_BID       ( m_axi_BID     [1])
     ,                       .M1_BRESP     ( m_axi_BRESP   [1])
     ,                       .M1_BVALID    ( m_axi_BVALID  [1])
     ,                       .M1_BREADY    ( m_axi_BREADY  [1])
     `ifdef AMBA_AXI_BUSER
     ,                       .M1_BUSER     ( m_axi_BUSER   [1])
     `endif
     ,                       .M1_ARID      ( m_axi_ARID    [1])
     ,                       .M1_ARADDR    ( m_axi_ARADDR  [1])
     ,                       .M1_ARLEN     ( m_axi_ARLEN   [1])
     ,                       .M1_ARLOCK    ( m_axi_ARLOCK  [1])
     ,                       .M1_ARSIZE    ( m_axi_ARSIZE  [1])
     ,                       .M1_ARBURST   ( m_axi_ARBURST [1])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M1_ARCACHE   ( m_axi_ARCACHE [1])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M1_ARPROT    ( m_axi_ARPROT  [1])
     `endif
     ,                       .M1_ARVALID   ( m_axi_ARVALID [1])
     ,                       .M1_ARREADY   ( m_axi_ARREADY [1])
     `ifdef AMBA_QOS
     ,                       .M1_ARQOS     ( m_axi_ARQOS   [1])
     ,                       .M1_ARREGION  ( m_axi_ARREGION[1])
     `endif
     `ifdef AMBA_AXI_ARUSER
     ,                       .M1_ARUSER    ( m_axi_ARUSER  [1])
     `endif
     ,                       .M1_RID       ( m_axi_RID     [1])
     ,                       .M1_RDATA     ( m_axi_RDATA   [1])
     ,                       .M1_RRESP     ( m_axi_RRESP   [1])
     ,                       .M1_RLAST     ( m_axi_RLAST   [1])
     ,                       .M1_RVALID    ( m_axi_RVALID  [1])
     ,                       .M1_RREADY    ( m_axi_RREADY  [1])
     `ifdef AMBA_AXI_RUSER
     ,                       .M1_RUSER     ( m_axi_RUSER   [1])
     `endif
     ,                       .M2_AWID      ( m_axi_AWID    [2])
     ,                       .M2_AWADDR    ( m_axi_AWADDR  [2])
     ,                       .M2_AWLEN     ( m_axi_AWLEN   [2])
     ,                       .M2_AWLOCK    ( m_axi_AWLOCK  [2])
     ,                       .M2_AWSIZE    ( m_axi_AWSIZE  [2])
     ,                       .M2_AWBURST   ( m_axi_AWBURST [2])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M2_AWCACHE   ( m_axi_AWCACHE [2])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M2_AWPROT    ( m_axi_AWPROT  [2])
     `endif
     ,                       .M2_AWVALID   ( m_axi_AWVALID [2])
     ,                       .M2_AWREADY   ( m_axi_AWREADY [2])
     `ifdef AMBA_QOS
     ,                       .M2_AWQOS     ( m_axi_AWQOS   [2])
     ,                       .M2_AWREGION  ( m_axi_AWREGION[2])
     `endif
     `ifdef AMBA_AXI_AWUSER
     ,                       .M2_AWUSER    ( m_axi_AWUSER  [2])
     `endif
     ,                       .M2_WDATA     ( m_axi_WDATA   [2])
     ,                       .M2_WSTRB     ( m_axi_WSTRB   [2])
     ,                       .M2_WLAST     ( m_axi_WLAST   [2])
     ,                       .M2_WVALID    ( m_axi_WVALID  [2])
     ,                       .M2_WREADY    ( m_axi_WREADY  [2])
     `ifdef AMBA_AXI_WUSER
                             .M2_WUSER     ( m_axi_WUSER   [2])
     `endif
     ,                       .M2_BID       ( m_axi_BID     [2])
     ,                       .M2_BRESP     ( m_axi_BRESP   [2])
     ,                       .M2_BVALID    ( m_axi_BVALID  [2])
     ,                       .M2_BREADY    ( m_axi_BREADY  [2])
     `ifdef AMBA_AXI_BUSER
                             .M2_BUSER     ( m_axi_BUSER   [2])
     `endif
     ,                       .M2_ARID      ( m_axi_ARID    [2])
     ,                       .M2_ARADDR    ( m_axi_ARADDR  [2])
     ,                       .M2_ARLEN     ( m_axi_ARLEN   [2])
     ,                       .M2_ARLOCK    ( m_axi_ARLOCK  [2])
     ,                       .M2_ARSIZE    ( m_axi_ARSIZE  [2])
     ,                       .M2_ARBURST   ( m_axi_ARBURST [2])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M2_ARCACHE   ( m_axi_ARCACHE [2])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M2_ARPROT    ( m_axi_ARPROT  [2])
     `endif
     ,                       .M2_ARVALID   ( m_axi_ARVALID [2])
     ,                       .M2_ARREADY   ( m_axi_ARREADY [2])
     `ifdef AMBA_QOS
     ,                       .M2_ARQOS     ( m_axi_ARQOS   [2])
     ,                       .M2_ARREGION  ( m_axi_ARREGION[2])
     `endif
     `ifdef AMBA_AXI_ARUSER
     ,                       .M2_ARUSER    ( m_axi_ARUSER  [2])
     `endif
     ,                       .M2_RID       ( m_axi_RID     [2])
     ,                       .M2_RDATA     ( m_axi_RDATA   [2])
     ,                       .M2_RRESP     ( m_axi_RRESP   [2])
     ,                       .M2_RLAST     ( m_axi_RLAST   [2])
     ,                       .M2_RVALID    ( m_axi_RVALID  [2])
     ,                       .M2_RREADY    ( m_axi_RREADY  [2])
     `ifdef AMBA_AXI_RUSER
     ,                       .M2_RUSER     ( m_axi_RUSER   [2])
     `endif
     ,                       .M3_AWID      ( m_axi_AWID    [3])
     ,                       .M3_AWADDR    ( m_axi_AWADDR  [3])
     ,                       .M3_AWLEN     ( m_axi_AWLEN   [3])
     ,                       .M3_AWLOCK    ( m_axi_AWLOCK  [3])
     ,                       .M3_AWSIZE    ( m_axi_AWSIZE  [3])
     ,                       .M3_AWBURST   ( m_axi_AWBURST [3])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M3_AWCACHE   ( m_axi_AWCACHE [3])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M3_AWPROT    ( m_axi_AWPROT  [3])
     `endif
     ,                       .M3_AWVALID   ( m_axi_AWVALID [3])
     ,                       .M3_AWREADY   ( m_axi_AWREADY [3])
     `ifdef AMBA_QOS           3           ( m_axi         [3])
     ,                       .M3_AWQOS     ( m_axi_AWQOS   [3])
     ,                       .M3_AWREGION  ( m_axi_AWREGION[3])
     `endif
     `ifdef AMBA_AXI_AWUSER
     ,                       .M3_AWUSER    ( m_axi_AWUSER  [3])
     `endif
     ,                       .M3_WDATA     ( m_axi_WDATA   [3])
     ,                       .M3_WSTRB     ( m_axi_WSTRB   [3])
     ,                       .M3_WLAST     ( m_axi_WLAST   [3])
     ,                       .M3_WVALID    ( m_axi_WVALID  [3])
     ,                       .M3_WREADY    ( m_axi_WREADY  [3])
     `ifdef AMBA_AXI_WUSER
     ,                       .M3_WUSER     ( m_axi_WUSER   [3])
     `endif
     ,                       .M3_BID       ( m_axi_BID     [3])
     ,                       .M3_BRESP     ( m_axi_BRESP   [3])
     ,                       .M3_BVALID    ( m_axi_BVALID  [3])
     ,                       .M3_BREADY    ( m_axi_BREADY  [3])
     `ifdef AMBA_AXI_BUSER
     ,                       .M3_BUSER     ( m_axi_BUSER   [3])
     `endif
     ,                       .M3_ARID      ( m_axi_ARID    [3])
     ,                       .M3_ARADDR    ( m_axi_ARADDR  [3])
     ,                       .M3_ARLEN     ( m_axi_ARLEN   [3])
     ,                       .M3_ARLOCK    ( m_axi_ARLOCK  [3])
     ,                       .M3_ARSIZE    ( m_axi_ARSIZE  [3])
     ,                       .M3_ARBURST   ( m_axi_ARBURST [3])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M3_ARCACHE   ( m_axi_ARCACHE [3])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M3_ARPROT    ( m_axi_ARPROT  [3])
     `endif
     ,                       .M3_ARVALID   ( m_axi_ARVALID [3])
     ,                       .M3_ARREADY   ( m_axi_ARREADY [3])
     `ifdef AMBA_QOS
     ,                       .M3_ARQOS     ( m_axi_ARQOS   [3])
     ,                       .M3_ARREGION  ( m_axi_ARREGION[3])
     `endif
     `ifdef AMBA_AXI_ARUSER
     ,                       .M3_ARUSER    ( m_axi_ARUSER  [3])
     `endif
     ,                       .M3_RID       ( m_axi_RID     [3])
     ,                       .M3_RDATA     ( m_axi_RDATA   [3])
     ,                       .M3_RRESP     ( m_axi_RRESP   [3])
     ,                       .M3_RLAST     ( m_axi_RLAST   [3])
     ,                       .M3_RVALID    ( m_axi_RVALID  [3])
     ,                       .M3_RREADY    ( m_axi_RREADY  [3])
     `ifdef AMBA_AXI_RUSER
     ,                       .M3_RUSER     ( m_axi_RUSER   [3])
     `endif
     ,                       .M4_AWID      ( m_axi_AWID    [4])
     ,                       .M4_AWADDR    ( m_axi_AWADDR  [4])
     ,                       .M4_AWLEN     ( m_axi_AWLEN   [4])
     ,                       .M4_AWLOCK    ( m_axi_AWLOCK  [4])
     ,                       .M4_AWSIZE    ( m_axi_AWSIZE  [4])
     ,                       .M4_AWBURST   ( m_axi_AWBURST [4])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M4_AWCACHE   ( m_axi_AWCACHE [4])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M4_AWPROT    ( m_axi_AWPROT  [4])
     `endif
     ,                       .M4_AWVALID   ( m_axi_AWVALID [4])
     ,                       .M4_AWREADY   ( m_axi_AWREADY [4])
     `ifdef AMBA_QOS
     ,                       .M4_AWQOS     ( m_axi_AWQOS   [4])
     ,                       .M4_AWREGION  ( m_axi_AWREGION[4])
     `endif
     `ifdef AMBA_AXI_AWUSER
     ,                       .M4_AWUSER    ( m_axi_AWUSER  [4])
     `endif
     ,                       .M4_WDATA     ( m_axi_WDATA   [4])
     ,                       .M4_WSTRB     ( m_axi_WSTRB   [4])
     ,                       .M4_WLAST     ( m_axi_WLAST   [4])
     ,                       .M4_WVALID    ( m_axi_WVALID  [4])
     ,                       .M4_WREADY    ( m_axi_WREADY  [4])
     `ifdef AMBA_AXI_WUSER
                             .M4_WUSER     ( m_axi_WUSER   [4])
     `endif
     ,                       .M4_BID       ( m_axi_BID     [4])
     ,                       .M4_BRESP     ( m_axi_BRESP   [4])
     ,                       .M4_BVALID    ( m_axi_BVALID  [4])
     ,                       .M4_BREADY    ( m_axi_BREADY  [4])
     `ifdef AMBA_AXI_BUSER
                             .M4_BUSER     ( m_axi_BUSER   [4])
     `endif
     ,                       .M4_ARID      ( m_axi_ARID    [4])
     ,                       .M4_ARADDR    ( m_axi_ARADDR  [4])
     ,                       .M4_ARLEN     ( m_axi_ARLEN   [4])
     ,                       .M4_ARLOCK    ( m_axi_ARLOCK  [4])
     ,                       .M4_ARSIZE    ( m_axi_ARSIZE  [4])
     ,                       .M4_ARBURST   ( m_axi_ARBURST [4])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M4_ARCACHE   ( m_axi_ARCACHE [4])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M4_ARPROT    ( m_axi_ARPROT  [4])
     `endif
     ,                       .M4_ARVALID   ( m_axi_ARVALID [4])
     ,                       .M4_ARREADY   ( m_axi_ARREADY [4])
     `ifdef AMBA_QOS
     ,                       .M4_ARQOS     ( m_axi_ARQOS   [4])
     ,                       .M4_ARREGION  ( m_axi_ARREGION[4])
     `endif
     `ifdef AMBA_AXI_ARUSER
     ,                       .M4_ARUSER    ( m_axi_ARUSER  [4])
     `endif
     ,                       .M4_RID       ( m_axi_RID     [4])
     ,                       .M4_RDATA     ( m_axi_RDATA   [4])
     ,                       .M4_RRESP     ( m_axi_RRESP   [4])
     ,                       .M4_RLAST     ( m_axi_RLAST   [4])
     ,                       .M4_RVALID    ( m_axi_RVALID  [4])
     ,                       .M4_RREADY    ( m_axi_RREADY  [4])
     `ifdef AMBA_AXI_RUSER
     ,                       .M4_RUSER     ( m_axi_RUSER   [4])
     `endif
     ,                       .M5_AWID      ( m_axi_AWID    [5])
     ,                       .M5_AWADDR    ( m_axi_AWADDR  [5])
     ,                       .M5_AWLEN     ( m_axi_AWLEN   [5])
     ,                       .M5_AWLOCK    ( m_axi_AWLOCK  [5])
     ,                       .M5_AWSIZE    ( m_axi_AWSIZE  [5])
     ,                       .M5_AWBURST   ( m_axi_AWBURST [5])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M5_AWCACHE   ( m_axi_AWCACHE [5])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M5_AWPROT    ( m_axi_AWPROT  [5])
     `endif
     ,                       .M5_AWVALID   ( m_axi_AWVALID [5])
     ,                       .M5_AWREADY   ( m_axi_AWREADY [5])
     `ifdef AMBA_QOS           5           ( m_axi         [5])
     ,                       .M5_AWQOS     ( m_axi_AWQOS   [5])
     ,                       .M5_AWREGION  ( m_axi_AWREGION[5])
     `endif
     `ifdef AMBA_AXI_AWUSER
     ,                       .M5_AWUSER    ( m_axi_AWUSER  [5])
     `endif
     ,                       .M5_WDATA     ( m_axi_WDATA   [5])
     ,                       .M5_WSTRB     ( m_axi_WSTRB   [5])
     ,                       .M5_WLAST     ( m_axi_WLAST   [5])
     ,                       .M5_WVALID    ( m_axi_WVALID  [5])
     ,                       .M5_WREADY    ( m_axi_WREADY  [5])
     `ifdef AMBA_AXI_WUSER
     ,                       .M5_WUSER     ( m_axi_WUSER   [5])
     `endif
     ,                       .M5_BID       ( m_axi_BID     [5])
     ,                       .M5_BRESP     ( m_axi_BRESP   [5])
     ,                       .M5_BVALID    ( m_axi_BVALID  [5])
     ,                       .M5_BREADY    ( m_axi_BREADY  [5])
     `ifdef AMBA_AXI_BUSER
     ,                       .M5_BUSER     ( m_axi_BUSER   [5])
     `endif
     ,                       .M5_ARID      ( m_axi_ARID    [5])
     ,                       .M5_ARADDR    ( m_axi_ARADDR  [5])
     ,                       .M5_ARLEN     ( m_axi_ARLEN   [5])
     ,                       .M5_ARLOCK    ( m_axi_ARLOCK  [5])
     ,                       .M5_ARSIZE    ( m_axi_ARSIZE  [5])
     ,                       .M5_ARBURST   ( m_axi_ARBURST [5])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M5_ARCACHE   ( m_axi_ARCACHE [5])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M5_ARPROT    ( m_axi_ARPROT  [5])
     `endif
     ,                       .M5_ARVALID   ( m_axi_ARVALID [5])
     ,                       .M5_ARREADY   ( m_axi_ARREADY [5])
     `ifdef AMBA_QOS
     ,                       .M5_ARQOS     ( m_axi_ARQOS   [5])
     ,                       .M5_ARREGION  ( m_axi_ARREGION[5])
     `endif
     `ifdef AMBA_AXI_ARUSER
     ,                       .M5_ARUSER    ( m_axi_ARUSER  [5])
     `endif
     ,                       .M5_RID       ( m_axi_RID     [5])
     ,                       .M5_RDATA     ( m_axi_RDATA   [5])
     ,                       .M5_RRESP     ( m_axi_RRESP   [5])
     ,                       .M5_RLAST     ( m_axi_RLAST   [5])
     ,                       .M5_RVALID    ( m_axi_RVALID  [5])
     ,                       .M5_RREADY    ( m_axi_RREADY  [5])
     `ifdef AMBA_AXI_RUSER
     ,                       .M5_RUSER     ( m_axi_RUSER   [5])
     `endif
     ,                       .M6_AWID      ( m_axi_AWID    [6])
     ,                       .M6_AWADDR    ( m_axi_AWADDR  [6])
     ,                       .M6_AWLEN     ( m_axi_AWLEN   [6])
     ,                       .M6_AWLOCK    ( m_axi_AWLOCK  [6])
     ,                       .M6_AWSIZE    ( m_axi_AWSIZE  [6])
     ,                       .M6_AWBURST   ( m_axi_AWBURST [6])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M6_AWCACHE   ( m_axi_AWCACHE [6])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M6_AWPROT    ( m_axi_AWPROT  [6])
     `endif
     ,                       .M6_AWVALID   ( m_axi_AWVALID [6])
     ,                       .M6_AWREADY   ( m_axi_AWREADY [6])
     `ifdef AMBA_QOS
     ,                       .M6_AWQOS     ( m_axi_AWQOS   [6])
     ,                       .M6_AWREGION  ( m_axi_AWREGION[6])
     `endif
     `ifdef AMBA_AXI_AWUSER
     ,                       .M6_AWUSER    ( m_axi_AWUSER  [6])
     `endif
     ,                       .M6_WDATA     ( m_axi_WDATA   [6])
     ,                       .M6_WSTRB     ( m_axi_WSTRB   [6])
     ,                       .M6_WLAST     ( m_axi_WLAST   [6])
     ,                       .M6_WVALID    ( m_axi_WVALID  [6])
     ,                       .M6_WREADY    ( m_axi_WREADY  [6])
     `ifdef AMBA_AXI_WUSER
                             .M6_WUSER     ( m_axi_WUSER   [6])
     `endif
     ,                       .M6_BID       ( m_axi_BID     [6])
     ,                       .M6_BRESP     ( m_axi_BRESP   [6])
     ,                       .M6_BVALID    ( m_axi_BVALID  [6])
     ,                       .M6_BREADY    ( m_axi_BREADY  [6])
     `ifdef AMBA_AXI_BUSER
                             .M6_BUSER     ( m_axi_BUSER   [6])
     `endif
     ,                       .M6_ARID      ( m_axi_ARID    [6])
     ,                       .M6_ARADDR    ( m_axi_ARADDR  [6])
     ,                       .M6_ARLEN     ( m_axi_ARLEN   [6])
     ,                       .M6_ARLOCK    ( m_axi_ARLOCK  [6])
     ,                       .M6_ARSIZE    ( m_axi_ARSIZE  [6])
     ,                       .M6_ARBURST   ( m_axi_ARBURST [6])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M6_ARCACHE   ( m_axi_ARCACHE [6])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M6_ARPROT    ( m_axi_ARPROT  [6])
     `endif
     ,                       .M6_ARVALID   ( m_axi_ARVALID [6])
     ,                       .M6_ARREADY   ( m_axi_ARREADY [6])
     `ifdef AMBA_QOS
     ,                       .M6_ARQOS     ( m_axi_ARQOS   [6])
     ,                       .M6_ARREGION  ( m_axi_ARREGION[6])
     `endif
     `ifdef AMBA_AXI_ARUSER
     ,                       .M6_ARUSER    ( m_axi_ARUSER  [6])
     `endif
     ,                       .M6_RID       ( m_axi_RID     [6])
     ,                       .M6_RDATA     ( m_axi_RDATA   [6])
     ,                       .M6_RRESP     ( m_axi_RRESP   [6])
     ,                       .M6_RLAST     ( m_axi_RLAST   [6])
     ,                       .M6_RVALID    ( m_axi_RVALID  [6])
     ,                       .M6_RREADY    ( m_axi_RREADY  [6])
     `ifdef AMBA_AXI_RUSER
     ,                       .M6_RUSER     ( m_axi_RUSER   [6])
     `endif
     ,                       .M7_AWID      ( m_axi_AWID    [7])
     ,                       .M7_AWADDR    ( m_axi_AWADDR  [7])
     ,                       .M7_AWLEN     ( m_axi_AWLEN   [7])
     ,                       .M7_AWLOCK    ( m_axi_AWLOCK  [7])
     ,                       .M7_AWSIZE    ( m_axi_AWSIZE  [7])
     ,                       .M7_AWBURST   ( m_axi_AWBURST [7])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M7_AWCACHE   ( m_axi_AWCACHE [7])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M7_AWPROT    ( m_axi_AWPROT  [7])
     `endif
     ,                       .M7_AWVALID   ( m_axi_AWVALID [7])
     ,                       .M7_AWREADY   ( m_axi_AWREADY [7])
     `ifdef AMBA_QOS           7           ( m_axi         [7])
     ,                       .M7_AWQOS     ( m_axi_AWQOS   [7])
     ,                       .M7_AWREGION  ( m_axi_AWREGION[7])
     `endif
     `ifdef AMBA_AXI_AWUSER
     ,                       .M7_AWUSER    ( m_axi_AWUSER  [7])
     `endif
     ,                       .M7_WDATA     ( m_axi_WDATA   [7])
     ,                       .M7_WSTRB     ( m_axi_WSTRB   [7])
     ,                       .M7_WLAST     ( m_axi_WLAST   [7])
     ,                       .M7_WVALID    ( m_axi_WVALID  [7])
     ,                       .M7_WREADY    ( m_axi_WREADY  [7])
     `ifdef AMBA_AXI_WUSER
     ,                       .M7_WUSER     ( m_axi_WUSER   [7])
     `endif
     ,                       .M7_BID       ( m_axi_BID     [7])
     ,                       .M7_BRESP     ( m_axi_BRESP   [7])
     ,                       .M7_BVALID    ( m_axi_BVALID  [7])
     ,                       .M7_BREADY    ( m_axi_BREADY  [7])
     `ifdef AMBA_AXI_BUSER
     ,                       .M7_BUSER     ( m_axi_BUSER   [7])
     `endif
     ,                       .M7_ARID      ( m_axi_ARID    [7])
     ,                       .M7_ARADDR    ( m_axi_ARADDR  [7])
     ,                       .M7_ARLEN     ( m_axi_ARLEN   [7])
     ,                       .M7_ARLOCK    ( m_axi_ARLOCK  [7])
     ,                       .M7_ARSIZE    ( m_axi_ARSIZE  [7])
     ,                       .M7_ARBURST   ( m_axi_ARBURST [7])
     `ifdef  AMBA_AXI_CACHE
     ,                       .M7_ARCACHE   ( m_axi_ARCACHE [7])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .M7_ARPROT    ( m_axi_ARPROT  [7])
     `endif
     ,                       .M7_ARVALID   ( m_axi_ARVALID [7])
     ,                       .M7_ARREADY   ( m_axi_ARREADY [7])
     `ifdef AMBA_QOS
     ,                       .M7_ARQOS     ( m_axi_ARQOS   [7])
     ,                       .M7_ARREGION  ( m_axi_ARREGION[7])
     `endif
     `ifdef AMBA_AXI_ARUSER
     ,                       .M7_ARUSER    ( m_axi_ARUSER  [7])
     `endif
     ,                       .M7_RID       ( m_axi_RID     [7])
     ,                       .M7_RDATA     ( m_axi_RDATA   [7])
     ,                       .M7_RRESP     ( m_axi_RRESP   [7])
     ,                       .M7_RLAST     ( m_axi_RLAST   [7])
     ,                       .M7_RVALID    ( m_axi_RVALID  [7])
     ,                       .M7_RREADY    ( m_axi_RREADY  [7])
     `ifdef AMBA_AXI_RUSER
     ,                       .M7_RUSER     ( m_axi_RUSER   [7])
     `endif
     ,                       .S0_AWID      ( s_axi_AWID    [0])
     ,                       .S0_AWADDR    ( s_axi_AWADDR  [0])
     ,                       .S0_AWLEN     ( s_axi_AWLEN   [0])
     ,                       .S0_AWLOCK    ( s_axi_AWLOCK  [0])
     ,                       .S0_AWSIZE    ( s_axi_AWSIZE  [0])
     ,                       .S0_AWBURST   ( s_axi_AWBURST [0])
     `ifdef  AMBA_AXI_CACHE
     ,                       .S0_AWCACHE   ( s_axi_AWCACHE [0])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .S0_AWPROT    ( s_axi_AWPROT  [0])
     `endif
     ,                       .S0_AWVALID   ( s_axi_AWVALID [0])
     ,                       .S0_AWREADY   ( s_axi_AWREADY [0])
     `ifdef AMBA_QOS
     ,                       .S0_AWQOS     ( s_axi_AWQOS   [0])
     ,                       .S0_AWREGION  ( s_axi_AWREGION[0])
     `endif
     `ifdef AMBA_AXI_AWUSER
     ,                       .S0_AWUSER    ( s_axi_AWUSER  [0])
     `endif
     ,                       .S0_WDATA     ( s_axi_WDATA   [0])
     ,                       .S0_WSTRB     ( s_axi_WSTRB   [0])
     ,                       .S0_WLAST     ( s_axi_WLAST   [0])
     ,                       .S0_WVALID    ( s_axi_WVALID  [0])
     ,                       .S0_WREADY    ( s_axi_WREADY  [0])
     `ifdef AMBA_AXI_WUSER
     ,                       .S0_WUSER     ( s_axi_WUSER   [0])
     `endif
     ,                       .S0_BID       ( s_axi_BID     [0])
     ,                       .S0_BRESP     ( s_axi_BRESP   [0])
     ,                       .S0_BVALID    ( s_axi_BVALID  [0])
     ,                       .S0_BREADY    ( s_axi_BREADY  [0])
     `ifdef AMBA_AXI_BUSER
     ,                       .S0_BUSER     ( s_axi_BUSER   [0])
     `endif
     ,                       .S0_ARID      ( s_axi_ARID    [0])
     ,                       .S0_ARADDR    ( s_axi_ARADDR  [0])
     ,                       .S0_ARLEN     ( s_axi_ARLEN   [0])
     ,                       .S0_ARLOCK    ( s_axi_ARLOCK  [0])
     ,                       .S0_ARSIZE    ( s_axi_ARSIZE  [0])
     ,                       .S0_ARBURST   ( s_axi_ARBURST [0])
     `ifdef  AMBA_AXI_CACHE
     ,                       .S0_ARCACHE   ( s_axi_ARCACHE [0])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .S0_ARPROT    ( s_axi_ARPROT  [0])
     `endif
     ,                       .S0_ARVALID   ( s_axi_ARVALID [0])
     ,                       .S0_ARREADY   ( s_axi_ARREADY [0])
     `ifdef AMBA_QOS
     ,                       .S0_ARQOS     ( s_axi_ARQOS   [0])
     ,                       .S0_ARREGION  ( s_axi_ARREGION[0])
     `endif
     `ifdef AMBA_AXI_ARUSER
     ,                       .S0_ARUSER    ( s_axi_ARUSER  [0])
     `endif
     ,                       .S0_RID       ( s_axi_RID     [0])
     ,                       .S0_RDATA     ( s_axi_RDATA   [0])
     ,                       .S0_RRESP     ( s_axi_RRESP   [0])
     ,                       .S0_RLAST     ( s_axi_RLAST   [0])
     ,                       .S0_RVALID    ( s_axi_RVALID  [0])
     ,                       .S0_RREADY    ( s_axi_RREADY  [0])
     `ifdef AMBA_AXI_RUSER
     ,                       .S0_RUSER     ( s_axi_RUSER   [0])
     `endif
     ,                       .S1_AWID      ( s_axi_AWID    [1])
     ,                       .S1_AWADDR    ( s_axi_AWADDR  [1])
     ,                       .S1_AWLEN     ( s_axi_AWLEN   [1])
     ,                       .S1_AWLOCK    ( s_axi_AWLOCK  [1])
     ,                       .S1_AWSIZE    ( s_axi_AWSIZE  [1])
     ,                       .S1_AWBURST   ( s_axi_AWBURST [1])
     `ifdef  AMBA_AXI_CACHE
     ,                       .S1_AWCACHE   ( s_axi_AWCACHE [1])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .S1_AWPROT    ( s_axi_AWPROT  [1])
     `endif
     ,                       .S1_AWVALID   ( s_axi_AWVALID [1])
     ,                       .S1_AWREADY   ( s_axi_AWREADY [1])
     `ifdef AMBA_QOS
     ,                       .S1_AWQOS     ( s_axi_AWQOS   [1])
     ,                       .S1_AWREGION  ( s_axi_AWREGION[1])
     `endif
     `ifdef AMBA_AXI_AWUSER
     ,                       .S1_AWUSER    ( s_axi_AWUSER  [1])
     `endif
     ,                       .S1_WDATA     ( s_axi_WDATA   [1])
     ,                       .S1_WSTRB     ( s_axi_WSTRB   [1])
     ,                       .S1_WLAST     ( s_axi_WLAST   [1])
     ,                       .S1_WVALID    ( s_axi_WVALID  [1])
     ,                       .S1_WREADY    ( s_axi_WREADY  [1])
     `ifdef AMBA_AXI_WUSER
     ,                       .S1_WUSER     ( s_axi_WUSER   [1])
     `endif
     ,                       .S1_BID       ( s_axi_BID     [1])
     ,                       .S1_BRESP     ( s_axi_BRESP   [1])
     ,                       .S1_BVALID    ( s_axi_BVALID  [1])
     ,                       .S1_BREADY    ( s_axi_BREADY  [1])
     `ifdef AMBA_AXI_BUSER
     ,                       .S1_BUSER     ( s_axi_BUSER   [1])
     `endif
     ,                       .S1_ARID      ( s_axi_ARID    [1])
     ,                       .S1_ARADDR    ( s_axi_ARADDR  [1])
     ,                       .S1_ARLEN     ( s_axi_ARLEN   [1])
     ,                       .S1_ARLOCK    ( s_axi_ARLOCK  [1])
     ,                       .S1_ARSIZE    ( s_axi_ARSIZE  [1])
     ,                       .S1_ARBURST   ( s_axi_ARBURST [1])
     `ifdef  AMBA_AXI_CACHE
     ,                       .S1_ARCACHE   ( s_axi_ARCACHE [1])
     `endif
     `ifdef AMBA_AXI_PROT
     ,                       .S1_ARPROT    ( s_axi_ARPROT  [1])
     `endif
     ,                       .S1_ARVALID   ( s_axi_ARVALID [1])
     ,                       .S1_ARREADY   ( s_axi_ARREADY [1])
     `ifdef AMBA_QOS
     ,                       .S1_ARQOS     ( s_axi_ARQOS   [1])
     ,                       .S1_ARREGION  ( s_axi_ARREGION[1])
     `endif
     `ifdef AMBA_AXI_ARUSER
     ,                       .S1_ARUSER    ( s_axi_ARUSER  [1])
     `endif
     ,                       .S1_RID       ( s_axi_RID     [1])
     ,                       .S1_RDATA     ( s_axi_RDATA   [1])
     ,                       .S1_RRESP     ( s_axi_RRESP   [1])
     ,                       .S1_RLAST     ( s_axi_RLAST   [1])
     ,                       .S1_RVALID    ( s_axi_RVALID  [1])
     ,                       .S1_RREADY    ( s_axi_RREADY  [1])
     `ifdef AMBA_AXI_RUSER
     ,                       .S1_RUSER     ( s_axi_RUSER   [1])
     `endif
    );
