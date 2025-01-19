module mover_2d
     #(parameter APB_WIDTH_AD =32  // address width
               , APB_WIDTH_DA =32  // data width
               , M_AXI_WIDTH_ID =4   // ID width in bits
               , M_AXI_WIDTH_AD =32  // address width
               , M_AXI_WIDTH_DA =32  // data width
               , M_AXI_WIDTH_DS =(M_AXI_WIDTH_DA/8)
               , DATA_TYPE      ="INTEGER" // "INTEGER", "FLOATING_POINT", "FIXED_POINT"
               , DATA_WIDTH     =32 // bit-width of an item
               `ifdef DATA_FIXED_POINT
               , DATA_WIDTH_Q=(DATA_WIDTH/2) // fractional bits
               `endif
               , SRC_FIFO_DEPTH   =16 // fifo for input
               , RESULT_FIFO_DEPTH=16 // fifo for writing result
               , PROFILE_CNT_WIDTH=32,
       parameter [3:0] MOVER_COMMAND_NOP      = 4'h0,
       parameter [3:0] MOVER_COMMAND_FILL     = 4'h1,
       parameter [3:0] MOVER_COMMAND_COPY     = 4'h2,
       parameter [3:0] MOVER_COMMAND_RESIDUAL = 4'h3,// point-to-point adder
       parameter [3:0] MOVER_COMMAND_CONCAT0  = 4'h4,
       parameter [3:0] MOVER_COMMAND_CONCAT1  = 4'h5,
       parameter [3:0] MOVER_COMMAND_TRANSPOSE= 4'h6,
       parameter [3:0] ACTIV_FUNC_BYPASS    =4'h0,
       parameter [3:0] ACTIV_FUNC_RELU      =4'h1,
       parameter [3:0] ACTIV_FUNC_LEAKY_RELU=4'h2,
       parameter [3:0] ACTIV_FUNC_SIGMOID   =4'h3, // not yet
       parameter [3:0] ACTIV_FUNC_TANH      =4'h4 // not yet
               )
(
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 PRESETn RST"    *) input  wire                    PRESETn,
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_apb" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 PCLK CLK"       *) input  wire                    PCLK,
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_apb,ASSOCIATED_RESET PRESETn,CLK_DOMAIN PCLK" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 s_apb PSEL"    *) input  wire                    S_APB_PSEL,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 s_apb PENABLE" *) input  wire                    S_APB_PENABLE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 s_apb PADDR"   *) input  wire [APB_WIDTH_AD-1:0] S_APB_PADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 s_apb PWRITE"  *) input  wire                    S_APB_PWRITE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 s_apb PRDATA"  *) output wire [APB_WIDTH_DA-1:0] S_APB_PRDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 s_apb PWDATA"  *) input  wire [APB_WIDTH_DA-1:0] S_APB_PWDATA,
  //(* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 s_apb PSTRB"   *) input  wire [APB_WIDTH_DS-1:0] S_APB_PSTRB,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 s_apb PREADY"  *) output  wire                   S_APB_PREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 s_apb PSLVERR" *) output  wire                   S_APB_PSLVERR,

    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 ARESETn RST" *) input   wire                         ARESETn,
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF m_axi_rst:m_axi_src:m_axi_ftu:m_axi_chn" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 ACLK CLK"    *) input   wire                         ACLK,
     // master port for result (write-only)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF m_axi_rst,ASSOCIATED_RESET ARESETn,CLK_DOMAIN ACLK,\
                                ROTOCOL AXI4,ADDR_WIDTH 32,ID_WIDTH 4,DATA_WIDTH 32,\
                                HAS_BURST 1,MAX_BURST_LENGTH 256,\
                                HAS_WSTRB 1,HAS_BRESP 1,HAS_RRESP 1,\
                                RUSER_WIDTH 0,WUSER_WIDTH 0,ARUSER_WIDTH 0,AWUSER_WIDTH 0,\
                                HAS_CACHE 0,HAS_LOCK 0,HAS_PROT 0,HAS_QOS 0,HAS_REGION 0 " *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_rst AWID"    *) output  wire  [M_AXI_WIDTH_ID-1:0]   M_AXI_RST_AWID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_rst AWADDR"  *) output  wire  [M_AXI_WIDTH_AD-1:0]   M_AXI_RST_AWADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_rst AWLEN"   *) output  wire  [ 7:0]                 M_AXI_RST_AWLEN,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_rst AWSIZE"  *) output  wire  [ 2:0]                 M_AXI_RST_AWSIZE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_rst AWBURST" *) output  wire  [ 1:0]                 M_AXI_RST_AWBURST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_rst AWVALID" *) output  wire                         M_AXI_RST_AWVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_rst AWREADY" *) input   wire                         M_AXI_RST_AWREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_rst WDATA"   *) output  wire  [M_AXI_WIDTH_DA-1:0]   M_AXI_RST_WDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_rst WSTRB"   *) output  wire  [M_AXI_WIDTH_DS-1:0]   M_AXI_RST_WSTRB,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_rst WLAST"   *) output  wire                         M_AXI_RST_WLAST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_rst WVALID"  *) output  wire                         M_AXI_RST_WVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_rst WREADY"  *) input   wire                         M_AXI_RST_WREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_rst BID"     *) input   wire  [M_AXI_WIDTH_ID-1:0]   M_AXI_RST_BID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_rst BRESP"   *) input   wire  [ 1:0]                 M_AXI_RST_BRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_rst BVALID"  *) input   wire                         M_AXI_RST_BVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_rst BREADY"  *) output  wire                         M_AXI_RST_BREADY,
     // master port for source (read-only)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF m_axi_src,ASSOCIATED_RESET ARESETn,CLK_DOMAIN ACLK,\
                                ROTOCOL AXI4,ADDR_WIDTH 32,ID_WIDTH 4,DATA_WIDTH 32,\
                                HAS_BURST 1,MAX_BURST_LENGTH 256,\
                                HAS_WSTRB 1,HAS_BRESP 1,HAS_RRESP 1,\
                                RUSER_WIDTH 0,WUSER_WIDTH 0,ARUSER_WIDTH 0,AWUSER_WIDTH 0,\
                                HAS_CACHE 0,HAS_LOCK 0,HAS_PROT 0,HAS_QOS 0,HAS_REGION 0 " *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_src ARID"    *) output  wire  [M_AXI_WIDTH_ID-1:0]   M_AXI_SRC_ARID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_src ARADDR"  *) output  wire  [M_AXI_WIDTH_AD-1:0]   M_AXI_SRC_ARADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_src ARLEN"   *) output  wire  [ 7:0]                 M_AXI_SRC_ARLEN,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_src ARSIZE"  *) output  wire  [ 2:0]                 M_AXI_SRC_ARSIZE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_src ARBURST" *) output  wire  [ 1:0]                 M_AXI_SRC_ARBURST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_src ARVALID" *) output  wire                         M_AXI_SRC_ARVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_src ARREADY" *) input   wire                         M_AXI_SRC_ARREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_src RID"     *) input   wire  [M_AXI_WIDTH_ID-1:0]   M_AXI_SRC_RID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_src RDATA"   *) input   wire  [M_AXI_WIDTH_DA-1:0]   M_AXI_SRC_RDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_src RRESP"   *) input   wire  [ 1:0]                 M_AXI_SRC_RRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_src RLAST"   *) input   wire                         M_AXI_SRC_RLAST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_src RVALID"  *) input   wire                         M_AXI_SRC_RVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_src RREADY"  *) output  wire                         M_AXI_SRC_RREADY,
     // 
    (* X_INTERFACE_PARAMETER = "SENSITIVITY LEVEL_HIGH" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:interrupt:1.0 interrupt INTERRUPT" *)
    output wire                          interrupt // interrupt to get attention
);
/* synthesis syn_black_box black_box_pad_pin="PRESETn,PCLK,S_APB_PSEL,S_APB_PENABLE,S_APB_PADDR[31:0],S_APB_PWRITE,S_APB_PRDATA[31:0],S_APB_PWDATA[31:0],S_APB_PREADY,S_APB_PSLVERR,ARESETn,ACLK,M_AXI_RST_AWID[3:0],M_AXI_RST_AWADDR[31:0],M_AXI_RST_AWLEN[7:0],M_AXI_RST_AWSIZE[2:0],M_AXI_RST_AWBURST[1:0],M_AXI_RST_AWVALID,M_AXI_RST_AWREADY,M_AXI_RST_WDATA[31:0],M_AXI_RST_WSTRB[3:0],M_AXI_RST_WLAST,M_AXI_RST_WVALID,M_AXI_RST_WREADY,M_AXI_RST_BID[3:0],M_AXI_RST_BRESP[1:0],M_AXI_RST_BVALID,M_AXI_RST_BREADY,M_AXI_SRC_ARID[3:0],M_AXI_SRC_ARADDR[31:0],M_AXI_SRC_ARLEN[7:0],M_AXI_SRC_ARSIZE[2:0],M_AXI_SRC_ARBURST[1:0],M_AXI_SRC_ARVALID,M_AXI_SRC_ARREADY,M_AXI_SRC_RID[3:0],M_AXI_SRC_RDATA[31:0],M_AXI_SRC_RRESP[1:0],M_AXI_SRC_RLAST,M_AXI_SRC_RVALID,M_AXI_SRC_RREADY,interrupt" */;
endmodule
