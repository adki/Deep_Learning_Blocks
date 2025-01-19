//------------------------------------------------------------------------------
// Copyright (c) 2025 by Future Design Systems.
// All right reserved.
//------------------------------------------------------------------------------
// dpu.v
//------------------------------------------------------------------------------
// VERSION: 2025.01.10.
//------------------------------------------------------------------------------
//                                 DPU
//                                +----------------------+
//    +--------+     +--------+   |  +-------+           |
//    | BFM    |<===>|S0    M1|<==|=>|AXI2APB|====\\     |
//    |        |     |        |   |  |       |    ||     |
//    +--------+     |        |   |  +-------+    ||     |
//    +--------+     |        |   |  +-------+    ||     |
//    | MEM    |<===>|M0    S1|<==|=>| CONV  |<===// S0  |
//    |        |     |      S2|   |  |       |    ||     |
//    +--------+     |      S3|   |  +-------+    ||     |
//                   |        |   |  +-------+    ||     |
//                   |      S4|<==|=>| POOL  |<===// S1  |
//                   |        |   |  |       |    ||     |
//                   |        |   |  +-------+    ||     |
//                   |        |   |  +-------+    ||     |
//                   |      S5|<==|=>| LINEAR|<===// S2  |
//                   |      S6|   |  |       |    ||     |
//                   |        |   |  +-------+    ||     |
//                   |        |   |  +-------+    ||     |
//                   |      S7|<==|=>| MOVER |<===// S3  |
//                   |        |   |  |       |           |
//                   +--------+   |  +-------+           |
//                                +----------------------+
//------------------------------------------------------------------------------

module dpu
     #(parameter P_DATA_TYPE       ="FLOATING_POINT" // "INTEGER", "FLOATING_POINT", "FIXED_POINT"
               , P_DATA_WIDTH      = 32
               `ifdef DATA_FIXED_POINT
               , P_DATA_WIDTH_Q    = P_DATA_WIDTH/2
               `endif
               , S_AXI_WIDTH_ID    = 4
               , S_AXI_WIDTH_AD    =32 // AMBA AXI address width
               , S_AXI_WIDTH_DA    =32 // AMBA AXI data width
               , S_AXI_WIDTH_DS    =(S_AXI_WIDTH_DA/8)
               , M_AXI_WIDTH_ID    = 4
               , M_AXI_WIDTH_AD    =32 // AMBA AXI address width
               , M_AXI_WIDTH_DA    =32 // AMBA AXI data width
               , M_AXI_WIDTH_DS    =(M_AXI_WIDTH_DA/8)
               , P_ADDR_BASE_CONF  =32'hC000_0000, P_SIZE_CONF  =( 4*1024)
               , P_ADDR_BASE_CONV  =32'hC000_1000, P_SIZE_CONV  =( 4*1024)
               , P_ADDR_BASE_POOL  =32'hC000_2000, P_SIZE_POOL  =( 4*1024)
               , P_ADDR_BASE_LINEAR=32'hC000_3000, P_SIZE_LINEAR=( 4*1024)
               , P_ADDR_BASE_MOVER =32'hC000_4000, P_SIZE_MOVER =( 4*1024)
               , P_ADDR_BASE_DPU   =P_ADDR_BASE_CONF, P_SIZE_DPU=(P_ADDR_BASE_MOVER+P_SIZE_MOVER-P_ADDR_BASE_DPU)
               )
(
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW"                *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 ARESETn RST" *) input  wire   ARESETn,
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axi_rst:s_axi_knl:s_axi_ftu"   *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 ACLK CLK"    *) input  wire   ACLK,
    
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axi_,ASSOCIATED_RESET ARESETn,CLK_DOMAIN ACLK,\
                                MAX_BURST_LENGTH 256,RUSER_WIDTH 0,WUSER_WIDTH 0,ARUSER_WIDTH 0,\
                                AWUSER_WIDTH 0,ADDR_WIDTH 64,ID_WIDTH 4,ROTOCOL AXI4,DATA_WIDTH 512,\
                                HAS_BURST 1,HAS_CACHE 0,HAS_LOCK 0,HAS_PROT 0,HAS_QOS 0,HAS_REGION 0,\
                                HAS_WSTRB 1,HAS_BRESP 1,HAS_RRESP 1" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_ AWID"    *) input  wire [S_AXI_WIDTH_ID-1:0] s_axi_AWID, // axi-to-apb
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_ AWADDR"  *) input  wire [S_AXI_WIDTH_AD-1:0] s_axi_AWADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_ AWLEN"   *) input  wire [ 7:0]               s_axi_AWLEN,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_ AWSIZE"  *) input  wire [ 2:0]               s_axi_AWSIZE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_ AWBURST" *) input  wire [ 1:0]               s_axi_AWBURST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_ AWVALID" *) input  wire                      s_axi_AWVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_ AWREADY" *) output wire                      s_axi_AWREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_ WDATA"   *) input  wire [S_AXI_WIDTH_DA-1:0] s_axi_WDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_ WSTRB"   *) input  wire [S_AXI_WIDTH_DS-1:0] s_axi_WSTRB,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_ WLAST"   *) input  wire                      s_axi_WLAST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_ WVALID"  *) input  wire                      s_axi_WVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_ WREADY"  *) output wire                      s_axi_WREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_ BID"     *) output wire [S_AXI_WIDTH_ID-1:0] s_axi_BID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_ BRESP"   *) output wire [ 1:0]               s_axi_BRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_ BVALID"  *) output wire                      s_axi_BVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_ BREADY"  *) input  wire                      s_axi_BREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_ ARID"    *) input  wire [S_AXI_WIDTH_ID-1:0] s_axi_ARID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_ ARADDR"  *) input  wire [S_AXI_WIDTH_AD-1:0] s_axi_ARADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_ ARLEN"   *) input  wire [ 7:0]               s_axi_ARLEN,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_ ARSIZE"  *) input  wire [ 2:0]               s_axi_ARSIZE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_ ARBURST" *) input  wire [ 1:0]               s_axi_ARBURST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_ ARVALID" *) input  wire                      s_axi_ARVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_ ARREADY" *) output wire                      s_axi_ARREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_ RID"     *) output wire [S_AXI_WIDTH_ID-1:0] s_axi_RID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_ RDATA"   *) output wire [S_AXI_WIDTH_DA-1:0] s_axi_RDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_ RRESP"   *) output wire [ 1:0]               s_axi_RRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_ RLAST"   *) output wire                      s_axi_RLAST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_ RVALID"  *) output wire                      s_axi_RVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi_ RREADY"  *) input  wire                      s_axi_RREADY,
    // convolution_2d (result and channel shared bus)
    // master port for previous-channel result (read-only)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF m_axi_conv_rst,ASSOCIATED_RESET ARESETn,CLK_DOMAIN ACLK,\
                                ROTOCOL AXI4,ADDR_WIDTH 32,ID_WIDTH 4,DATA_WIDTH 32,\
                                HAS_BURST 1,MAX_BURST_LENGTH 256,\
                                HAS_WSTRB 1,HAS_BRESP 1,HAS_RRESP 1,\
                                RUSER_WIDTH 0,WUSER_WIDTH 0,ARUSER_WIDTH 0,AWUSER_WIDTH 0,\
                                HAS_CACHE 0,HAS_LOCK 0,HAS_PROT 0,HAS_QOS 0,HAS_REGION 0 " *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_rst AWID"    *) output  wire  [M_AXI_WIDTH_ID-1:0]   m_axi_conv_rst_AWID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_rst AWADDR"  *) output  wire  [M_AXI_WIDTH_AD-1:0]   m_axi_conv_rst_AWADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_rst AWLEN"   *) output  wire  [ 7:0]                 m_axi_conv_rst_AWLEN,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_rst AWSIZE"  *) output  wire  [ 2:0]                 m_axi_conv_rst_AWSIZE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_rst AWBURST" *) output  wire  [ 1:0]                 m_axi_conv_rst_AWBURST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_rst AWVALID" *) output  wire                         m_axi_conv_rst_AWVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_rst AWREADY" *) input   wire                         m_axi_conv_rst_AWREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_rst WDATA"   *) output  wire  [M_AXI_WIDTH_DA-1:0]   m_axi_conv_rst_WDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_rst WSTRB"   *) output  wire  [M_AXI_WIDTH_DS-1:0]   m_axi_conv_rst_WSTRB,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_rst WLAST"   *) output  wire                         m_axi_conv_rst_WLAST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_rst WVALID"  *) output  wire                         m_axi_conv_rst_WVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_rst WREADY"  *) input   wire                         m_axi_conv_rst_WREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_rst BID"     *) input   wire  [M_AXI_WIDTH_ID-1:0]   m_axi_conv_rst_BID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_rst BRESP"   *) input   wire  [ 1:0]                 m_axi_conv_rst_BRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_rst BVALID"  *) input   wire                         m_axi_conv_rst_BVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_rst BREADY"  *) output  wire                         m_axi_conv_rst_BREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_rst ARID"    *) output  wire  [M_AXI_WIDTH_ID-1:0]   m_axi_conv_rst_ARID, // for channel
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_rst ARADDR"  *) output  wire  [M_AXI_WIDTH_AD-1:0]   m_axi_conv_rst_ARADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_rst ARLEN"   *) output  wire  [ 7:0]                 m_axi_conv_rst_ARLEN,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_rst ARSIZE"  *) output  wire  [ 2:0]                 m_axi_conv_rst_ARSIZE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_rst ARBURST" *) output  wire  [ 1:0]                 m_axi_conv_rst_ARBURST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_rst ARVALID" *) output  wire                         m_axi_conv_rst_ARVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_rst ARREADY" *) input   wire                         m_axi_conv_rst_ARREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_rst RID"     *) input   wire  [M_AXI_WIDTH_ID-1:0]   m_axi_conv_rst_RID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_rst RDATA"   *) input   wire  [M_AXI_WIDTH_DA-1:0]   m_axi_conv_rst_RDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_rst RRESP"   *) input   wire  [ 1:0]                 m_axi_conv_rst_RRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_rst RLAST"   *) input   wire                         m_axi_conv_rst_RLAST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_rst RVALID"  *) input   wire                         m_axi_conv_rst_RVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_rst RREADY"  *) output  wire                         m_axi_conv_rst_RREADY,
    // master port for kernel (read-only)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF m_axi_conv_knl,ASSOCIATED_RESET ARESETn,CLK_DOMAIN ACLK,\
                                ROTOCOL AXI4,ADDR_WIDTH 32,ID_WIDTH 4,DATA_WIDTH 32,\
                                HAS_BURST 1,MAX_BURST_LENGTH 256,\
                                HAS_WSTRB 1,HAS_BRESP 1,HAS_RRESP 1,\
                                RUSER_WIDTH 0,WUSER_WIDTH 0,ARUSER_WIDTH 0,AWUSER_WIDTH 0,\
                                HAS_CACHE 0,HAS_LOCK 0,HAS_PROT 0,HAS_QOS 0,HAS_REGION 0 " *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_knl AWID"    *) output  wire  [M_AXI_WIDTH_ID-1:0]   m_axi_conv_knl_AWID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_knl AWADDR"  *) output  wire  [M_AXI_WIDTH_AD-1:0]   m_axi_conv_knl_AWADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_knl AWLEN"   *) output  wire  [ 7:0]                 m_axi_conv_knl_AWLEN,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_knl AWSIZE"  *) output  wire  [ 2:0]                 m_axi_conv_knl_AWSIZE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_knl AWBURST" *) output  wire  [ 1:0]                 m_axi_conv_knl_AWBURST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_knl AWVALID" *) output  wire                         m_axi_conv_knl_AWVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_knl AWREADY" *) input   wire                         m_axi_conv_knl_AWREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_knl WDATA"   *) output  wire  [M_AXI_WIDTH_DA-1:0]   m_axi_conv_knl_WDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_knl WSTRB"   *) output  wire  [M_AXI_WIDTH_DS-1:0]   m_axi_conv_knl_WSTRB,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_knl WLAST"   *) output  wire                         m_axi_conv_knl_WLAST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_knl WVALID"  *) output  wire                         m_axi_conv_knl_WVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_knl WREADY"  *) input   wire                         m_axi_conv_knl_WREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_knl BID"     *) input   wire  [M_AXI_WIDTH_ID-1:0]   m_axi_conv_knl_BID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_knl BRESP"   *) input   wire  [ 1:0]                 m_axi_conv_knl_BRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_knl BVALID"  *) input   wire                         m_axi_conv_knl_BVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_knl BREADY"  *) output  wire                         m_axi_conv_knl_BREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_knl ARID"    *) output  wire  [M_AXI_WIDTH_ID-1:0]   m_axi_conv_knl_ARID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_knl ARADDR"  *) output  wire  [M_AXI_WIDTH_AD-1:0]   m_axi_conv_knl_ARADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_knl ARLEN"   *) output  wire  [ 7:0]                 m_axi_conv_knl_ARLEN,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_knl ARSIZE"  *) output  wire  [ 2:0]                 m_axi_conv_knl_ARSIZE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_knl ARBURST" *) output  wire  [ 1:0]                 m_axi_conv_knl_ARBURST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_knl ARVALID" *) output  wire                         m_axi_conv_knl_ARVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_knl ARREADY" *) input   wire                         m_axi_conv_knl_ARREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_knl RID"     *) input   wire  [M_AXI_WIDTH_ID-1:0]   m_axi_conv_knl_RID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_knl RDATA"   *) input   wire  [M_AXI_WIDTH_DA-1:0]   m_axi_conv_knl_RDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_knl RRESP"   *) input   wire  [ 1:0]                 m_axi_conv_knl_RRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_knl RLAST"   *) input   wire                         m_axi_conv_knl_RLAST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_knl RVALID"  *) input   wire                         m_axi_conv_knl_RVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_knl RREADY"  *) output  wire                         m_axi_conv_knl_RREADY,
    // master port for feature (read-only)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF m_axi_conv_ftu,ASSOCIATED_RESET ARESETn,CLK_DOMAIN ACLK,\
                                ROTOCOL AXI4,ADDR_WIDTH 32,ID_WIDTH 4,DATA_WIDTH 32,\
                                HAS_BURST 1,MAX_BURST_LENGTH 256,\
                                HAS_WSTRB 1,HAS_BRESP 1,HAS_RRESP 1,\
                                RUSER_WIDTH 0,WUSER_WIDTH 0,ARUSER_WIDTH 0,AWUSER_WIDTH 0,\
                                HAS_CACHE 0,HAS_LOCK 0,HAS_PROT 0,HAS_QOS 0,HAS_REGION 0 " *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_ftu AWID"    *) output  wire  [M_AXI_WIDTH_ID-1:0]   m_axi_conv_ftu_AWID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_ftu AWADDR"  *) output  wire  [M_AXI_WIDTH_AD-1:0]   m_axi_conv_ftu_AWADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_ftu AWLEN"   *) output  wire  [ 7:0]                 m_axi_conv_ftu_AWLEN,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_ftu AWSIZE"  *) output  wire  [ 2:0]                 m_axi_conv_ftu_AWSIZE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_ftu AWBURST" *) output  wire  [ 1:0]                 m_axi_conv_ftu_AWBURST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_ftu AWVALID" *) output  wire                         m_axi_conv_ftu_AWVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_ftu AWREADY" *) input   wire                         m_axi_conv_ftu_AWREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_ftu WDATA"   *) output  wire  [M_AXI_WIDTH_DA-1:0]   m_axi_conv_ftu_WDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_ftu WSTRB"   *) output  wire  [M_AXI_WIDTH_DS-1:0]   m_axi_conv_ftu_WSTRB,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_ftu WLAST"   *) output  wire                         m_axi_conv_ftu_WLAST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_ftu WVALID"  *) output  wire                         m_axi_conv_ftu_WVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_ftu WREADY"  *) input   wire                         m_axi_conv_ftu_WREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_ftu BID"     *) input   wire  [M_AXI_WIDTH_ID-1:0]   m_axi_conv_ftu_BID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_ftu BRESP"   *) input   wire  [ 1:0]                 m_axi_conv_ftu_BRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_ftu BVALID"  *) input   wire                         m_axi_conv_ftu_BVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_ftu BREADY"  *) output  wire                         m_axi_conv_ftu_BREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_ftu ARID"    *) output  wire  [M_AXI_WIDTH_ID-1:0]   m_axi_conv_ftu_ARID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_ftu ARADDR"  *) output  wire  [M_AXI_WIDTH_AD-1:0]   m_axi_conv_ftu_ARADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_ftu ARLEN"   *) output  wire  [ 7:0]                 m_axi_conv_ftu_ARLEN,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_ftu ARSIZE"  *) output  wire  [ 2:0]                 m_axi_conv_ftu_ARSIZE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_ftu ARBURST" *) output  wire  [ 1:0]                 m_axi_conv_ftu_ARBURST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_ftu ARVALID" *) output  wire                         m_axi_conv_ftu_ARVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_ftu ARREADY" *) input   wire                         m_axi_conv_ftu_ARREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_ftu RID"     *) input   wire  [M_AXI_WIDTH_ID-1:0]   m_axi_conv_ftu_RID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_ftu RDATA"   *) input   wire  [M_AXI_WIDTH_DA-1:0]   m_axi_conv_ftu_RDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_ftu RRESP"   *) input   wire  [ 1:0]                 m_axi_conv_ftu_RRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_ftu RLAST"   *) input   wire                         m_axi_conv_ftu_RLAST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_ftu RVALID"  *) input   wire                         m_axi_conv_ftu_RVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_conv_ftu RREADY"  *) output  wire                         m_axi_conv_ftu_RREADY,
    // 
    (* X_INTERFACE_PARAMETER = "SENSITIVITY LEVEL_HIGH" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:interrupt:1.0 interrupt_conv INTERRUPT" *)
    output wire                          interrupt_conv,// interrupt to get attention
    // pooling_2d (result and feature shared bus)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF m_axi_pool,ASSOCIATED_RESET ARESETn,CLK_DOMAIN ACLK,\
                                ROTOCOL AXI4,ADDR_WIDTH 32,ID_WIDTH 4,DATA_WIDTH 32,\
                                HAS_BURST 1,MAX_BURST_LENGTH 256,\
                                HAS_WSTRB 1,HAS_BRESP 1,HAS_RRESP 1,\
                                RUSER_WIDTH 0,WUSER_WIDTH 0,ARUSER_WIDTH 0,AWUSER_WIDTH 0,\
                                HAS_CACHE 0,HAS_LOCK 0,HAS_PROT 0,HAS_QOS 0,HAS_REGION 0 " *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_pool AWID"    *) output  wire  [M_AXI_WIDTH_ID-1:0]   m_axi_pool_AWID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_pool AWADDR"  *) output  wire  [M_AXI_WIDTH_AD-1:0]   m_axi_pool_AWADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_pool AWLEN"   *) output  wire  [ 7:0]                 m_axi_pool_AWLEN,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_pool AWSIZE"  *) output  wire  [ 2:0]                 m_axi_pool_AWSIZE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_pool AWBURST" *) output  wire  [ 1:0]                 m_axi_pool_AWBURST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_pool AWVALID" *) output  wire                         m_axi_pool_AWVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_pool AWREADY" *) input   wire                         m_axi_pool_AWREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_pool WDATA"   *) output  wire  [M_AXI_WIDTH_DA-1:0]   m_axi_pool_WDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_pool WSTRB"   *) output  wire  [M_AXI_WIDTH_DS-1:0]   m_axi_pool_WSTRB,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_pool WLAST"   *) output  wire                         m_axi_pool_WLAST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_pool WVALID"  *) output  wire                         m_axi_pool_WVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_pool WREADY"  *) input   wire                         m_axi_pool_WREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_pool BID"     *) input   wire  [M_AXI_WIDTH_ID-1:0]   m_axi_pool_BID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_pool BRESP"   *) input   wire  [ 1:0]                 m_axi_pool_BRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_pool BVALID"  *) input   wire                         m_axi_pool_BVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_pool BREADY"  *) output  wire                         m_axi_pool_BREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_pool ARID"    *) output  wire  [M_AXI_WIDTH_ID-1:0]   m_axi_pool_ARID, // for channel
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_pool ARADDR"  *) output  wire  [M_AXI_WIDTH_AD-1:0]   m_axi_pool_ARADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_pool ARLEN"   *) output  wire  [ 7:0]                 m_axi_pool_ARLEN,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_pool ARSIZE"  *) output  wire  [ 2:0]                 m_axi_pool_ARSIZE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_pool ARBURST" *) output  wire  [ 1:0]                 m_axi_pool_ARBURST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_pool ARVALID" *) output  wire                         m_axi_pool_ARVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_pool ARREADY" *) input   wire                         m_axi_pool_ARREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_pool RID"     *) input   wire  [M_AXI_WIDTH_ID-1:0]   m_axi_pool_RID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_pool RDATA"   *) input   wire  [M_AXI_WIDTH_DA-1:0]   m_axi_pool_RDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_pool RRESP"   *) input   wire  [ 1:0]                 m_axi_pool_RRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_pool RLAST"   *) input   wire                         m_axi_pool_RLAST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_pool RVALID"  *) input   wire                         m_axi_pool_RVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_pool RREADY"  *) output  wire                         m_axi_pool_RREADY,

    (* X_INTERFACE_PARAMETER = "SENSITIVITY LEVEL_HIGH" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:interrupt:1.0 interrupt_pool INTERRUPT" *)
    output wire                          interrupt_pool,// interrupt to get attention
    // linear_1d (result and input shared bus)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF m_axi_linear_rst,ASSOCIATED_RESET ARESETn,CLK_DOMAIN ACLK,\
                                ROTOCOL AXI4,ADDR_WIDTH 32,ID_WIDTH 4,DATA_WIDTH 32,\
                                HAS_BURST 1,MAX_BURST_LENGTH 256,\
                                HAS_WSTRB 1,HAS_BRESP 1,HAS_RRESP 1,\
                                RUSER_WIDTH 0,WUSER_WIDTH 0,ARUSER_WIDTH 0,AWUSER_WIDTH 0,\
                                HAS_CACHE 0,HAS_LOCK 0,HAS_PROT 0,HAS_QOS 0,HAS_REGION 0 " *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_rst AWID"    *) output  wire  [M_AXI_WIDTH_ID-1:0]   m_axi_linear_rst_AWID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_rst AWADDR"  *) output  wire  [M_AXI_WIDTH_AD-1:0]   m_axi_linear_rst_AWADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_rst AWLEN"   *) output  wire  [ 7:0]                 m_axi_linear_rst_AWLEN,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_rst AWSIZE"  *) output  wire  [ 2:0]                 m_axi_linear_rst_AWSIZE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_rst AWBURST" *) output  wire  [ 1:0]                 m_axi_linear_rst_AWBURST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_rst AWVALID" *) output  wire                         m_axi_linear_rst_AWVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_rst AWREADY" *) input   wire                         m_axi_linear_rst_AWREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_rst WDATA"   *) output  wire  [M_AXI_WIDTH_DA-1:0]   m_axi_linear_rst_WDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_rst WSTRB"   *) output  wire  [M_AXI_WIDTH_DS-1:0]   m_axi_linear_rst_WSTRB,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_rst WLAST"   *) output  wire                         m_axi_linear_rst_WLAST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_rst WVALID"  *) output  wire                         m_axi_linear_rst_WVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_rst WREADY"  *) input   wire                         m_axi_linear_rst_WREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_rst BID"     *) input   wire  [M_AXI_WIDTH_ID-1:0]   m_axi_linear_rst_BID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_rst BRESP"   *) input   wire  [ 1:0]                 m_axi_linear_rst_BRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_rst BVALID"  *) input   wire                         m_axi_linear_rst_BVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_rst BREADY"  *) output  wire                         m_axi_linear_rst_BREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_rst ARID"    *) output  wire  [M_AXI_WIDTH_ID-1:0]   m_axi_linear_rst_ARID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_rst ARADDR"  *) output  wire  [M_AXI_WIDTH_AD-1:0]   m_axi_linear_rst_ARADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_rst ARLEN"   *) output  wire  [ 7:0]                 m_axi_linear_rst_ARLEN,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_rst ARSIZE"  *) output  wire  [ 2:0]                 m_axi_linear_rst_ARSIZE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_rst ARBURST" *) output  wire  [ 1:0]                 m_axi_linear_rst_ARBURST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_rst ARVALID" *) output  wire                         m_axi_linear_rst_ARVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_rst ARREADY" *) input   wire                         m_axi_linear_rst_ARREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_rst RID"     *) input   wire  [M_AXI_WIDTH_ID-1:0]   m_axi_linear_rst_RID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_rst RDATA"   *) input   wire  [M_AXI_WIDTH_DA-1:0]   m_axi_linear_rst_RDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_rst RRESP"   *) input   wire  [ 1:0]                 m_axi_linear_rst_RRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_rst RLAST"   *) input   wire                         m_axi_linear_rst_RLAST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_rst RVALID"  *) input   wire                         m_axi_linear_rst_RVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_rst RREADY"  *) output  wire                         m_axi_linear_rst_RREADY,
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF m_axi_linear_weight,ASSOCIATED_RESET ARESETn,CLK_DOMAIN ACLK,\
                                ROTOCOL AXI4,ADDR_WIDTH 32,ID_WIDTH 4,DATA_WIDTH 32,\
                                HAS_BURST 1,MAX_BURST_LENGTH 256,\
                                HAS_WSTRB 1,HAS_BRESP 1,HAS_RRESP 1,\
                                RUSER_WIDTH 0,WUSER_WIDTH 0,ARUSER_WIDTH 0,AWUSER_WIDTH 0,\
                                HAS_CACHE 0,HAS_LOCK 0,HAS_PROT 0,HAS_QOS 0,HAS_REGION 0 " *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_weight AWID"    *) output  wire  [M_AXI_WIDTH_ID-1:0]   m_axi_linear_weight_AWID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_weight AWADDR"  *) output  wire  [M_AXI_WIDTH_AD-1:0]   m_axi_linear_weight_AWADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_weight AWLEN"   *) output  wire  [ 7:0]                 m_axi_linear_weight_AWLEN,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_weight AWSIZE"  *) output  wire  [ 2:0]                 m_axi_linear_weight_AWSIZE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_weight AWBURST" *) output  wire  [ 1:0]                 m_axi_linear_weight_AWBURST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_weight AWVALID" *) output  wire                         m_axi_linear_weight_AWVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_weight AWREADY" *) input   wire                         m_axi_linear_weight_AWREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_weight WDATA"   *) output  wire  [M_AXI_WIDTH_DA-1:0]   m_axi_linear_weight_WDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_weight WSTRB"   *) output  wire  [M_AXI_WIDTH_DS-1:0]   m_axi_linear_weight_WSTRB,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_weight WLAST"   *) output  wire                         m_axi_linear_weight_WLAST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_weight WVALID"  *) output  wire                         m_axi_linear_weight_WVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_weight WREADY"  *) input   wire                         m_axi_linear_weight_WREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_weight BID"     *) input   wire  [M_AXI_WIDTH_ID-1:0]   m_axi_linear_weight_BID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_weight BRESP"   *) input   wire  [ 1:0]                 m_axi_linear_weight_BRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_weight BVALID"  *) input   wire                         m_axi_linear_weight_BVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_weight BREADY"  *) output  wire                         m_axi_linear_weight_BREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_weight ARID"    *) output  wire  [M_AXI_WIDTH_ID-1:0]   m_axi_linear_weight_ARID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_weight ARADDR"  *) output  wire  [M_AXI_WIDTH_AD-1:0]   m_axi_linear_weight_ARADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_weight ARLEN"   *) output  wire  [ 7:0]                 m_axi_linear_weight_ARLEN,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_weight ARSIZE"  *) output  wire  [ 2:0]                 m_axi_linear_weight_ARSIZE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_weight ARBURST" *) output  wire  [ 1:0]                 m_axi_linear_weight_ARBURST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_weight ARVALID" *) output  wire                         m_axi_linear_weight_ARVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_weight ARREADY" *) input   wire                         m_axi_linear_weight_ARREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_weight RID"     *) input   wire  [M_AXI_WIDTH_ID-1:0]   m_axi_linear_weight_RID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_weight RDATA"   *) input   wire  [M_AXI_WIDTH_DA-1:0]   m_axi_linear_weight_RDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_weight RRESP"   *) input   wire  [ 1:0]                 m_axi_linear_weight_RRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_weight RLAST"   *) input   wire                         m_axi_linear_weight_RLAST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_weight RVALID"  *) input   wire                         m_axi_linear_weight_RVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_linear_weight RREADY"  *) output  wire                         m_axi_linear_weight_RREADY,

    (* X_INTERFACE_PARAMETER = "SENSITIVITY LEVEL_HIGH" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:interrupt:1.0 interrupt_pool INTERRUPT" *)
    output wire                          interrupt_linear,// interrupt to get attention
    // mover_2d
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF m_axi_mover,ASSOCIATED_RESET ARESETn,CLK_DOMAIN ACLK,\
                                ROTOCOL AXI4,ADDR_WIDTH 32,ID_WIDTH 4,DATA_WIDTH 32,\
                                HAS_BURST 1,MAX_BURST_LENGTH 256,\
                                HAS_WSTRB 1,HAS_BRESP 1,HAS_RRESP 1,\
                                RUSER_WIDTH 0,WUSER_WIDTH 0,ARUSER_WIDTH 0,AWUSER_WIDTH 0,\
                                HAS_CACHE 0,HAS_LOCK 0,HAS_PROT 0,HAS_QOS 0,HAS_REGION 0 " *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_mover AWID"    *) output  wire  [M_AXI_WIDTH_ID-1:0]   m_axi_mover_AWID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_mover AWADDR"  *) output  wire  [M_AXI_WIDTH_AD-1:0]   m_axi_mover_AWADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_mover AWLEN"   *) output  wire  [ 7:0]                 m_axi_mover_AWLEN,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_mover AWSIZE"  *) output  wire  [ 2:0]                 m_axi_mover_AWSIZE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_mover AWBURST" *) output  wire  [ 1:0]                 m_axi_mover_AWBURST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_mover AWVALID" *) output  wire                         m_axi_mover_AWVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_mover AWREADY" *) input   wire                         m_axi_mover_AWREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_mover WDATA"   *) output  wire  [M_AXI_WIDTH_DA-1:0]   m_axi_mover_WDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_mover WSTRB"   *) output  wire  [M_AXI_WIDTH_DS-1:0]   m_axi_mover_WSTRB,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_mover WLAST"   *) output  wire                         m_axi_mover_WLAST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_mover WVALID"  *) output  wire                         m_axi_mover_WVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_mover WREADY"  *) input   wire                         m_axi_mover_WREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_mover BID"     *) input   wire  [M_AXI_WIDTH_ID-1:0]   m_axi_mover_BID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_mover BRESP"   *) input   wire  [ 1:0]                 m_axi_mover_BRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_mover BVALID"  *) input   wire                         m_axi_mover_BVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_mover BREADY"  *) output  wire                         m_axi_mover_BREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_mover ARID"    *) output  wire  [M_AXI_WIDTH_ID-1:0]   m_axi_mover_ARID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_mover ARADDR"  *) output  wire  [M_AXI_WIDTH_AD-1:0]   m_axi_mover_ARADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_mover ARLEN"   *) output  wire  [ 7:0]                 m_axi_mover_ARLEN,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_mover ARSIZE"  *) output  wire  [ 2:0]                 m_axi_mover_ARSIZE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_mover ARBURST" *) output  wire  [ 1:0]                 m_axi_mover_ARBURST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_mover ARVALID" *) output  wire                         m_axi_mover_ARVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_mover ARREADY" *) input   wire                         m_axi_mover_ARREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_mover RID"     *) input   wire  [M_AXI_WIDTH_ID-1:0]   m_axi_mover_RID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_mover RDATA"   *) input   wire  [M_AXI_WIDTH_DA-1:0]   m_axi_mover_RDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_mover RRESP"   *) input   wire  [ 1:0]                 m_axi_mover_RRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_mover RLAST"   *) input   wire                         m_axi_mover_RLAST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_mover RVALID"  *) input   wire                         m_axi_mover_RVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_mover RREADY"  *) output  wire                         m_axi_mover_RREADY,

    (* X_INTERFACE_PARAMETER = "SENSITIVITY LEVEL_HIGH" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:interrupt:1.0 interrupt_mover INTERRUPT" *)
    output wire                          interrupt_mover // interrupt to get attention
);
   //---------------------------------------------------------------------------
   wire  module_convolution;
   wire  module_pooling;
   wire  module_linear;
   wire  module_mover;
   //---------------------------------------------------------------------------
   `include "dpu_axi_to_apb.v"
   `include "dpu_dpu_configuration.v"
   `include "dpu_convolution_2d.v"
   `include "dpu_pooling_2d.v"
   `include "dpu_linear_1d.v"
   `include "dpu_mover_2d.v"
   //---------------------------------------------------------------------------
endmodule
//------------------------------------------------------------------------------
// Revision History
//
// 2025.01.10: Started by Ando Ki (adki@future-ds.com)
//------------------------------------------------------------------------------
