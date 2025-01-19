module pooling_2d
     #(parameter APB_WIDTH_AD   =32  // address width
               , APB_WIDTH_DA   =32  // data width
               , M_AXI_WIDTH_ID =4   // ID width in bits
               , M_AXI_WIDTH_AD =32  // address width
               , M_AXI_WIDTH_DA =32  // data width
               , M_AXI_WIDTH_DS =(M_AXI_WIDTH_DA/8)
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
     // master port for result (write-only)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 ARESETn RST" *) input   wire                         ARESETn,
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF m_axi_rst:m_axi_ftu" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 ACLK CLK"    *) input   wire                         ACLK,
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
     // master port for feature (read-only)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF m_axi_ftu,ASSOCIATED_RESET ARESETn,CLK_DOMAIN ACLK,\
                                ROTOCOL AXI4,ADDR_WIDTH 32,ID_WIDTH 4,DATA_WIDTH 32,\
                                HAS_BURST 1,MAX_BURST_LENGTH 256,\
                                HAS_WSTRB 1,HAS_BRESP 1,HAS_RRESP 1,\
                                RUSER_WIDTH 0,WUSER_WIDTH 0,ARUSER_WIDTH 0,AWUSER_WIDTH 0,\
                                HAS_CACHE 0,HAS_LOCK 0,HAS_PROT 0,HAS_QOS 0,HAS_REGION 0 " *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_ftu ARID"    *) output  wire  [M_AXI_WIDTH_ID-1:0]   M_AXI_FTU_ARID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_ftu ARADDR"  *) output  wire  [M_AXI_WIDTH_AD-1:0]   M_AXI_FTU_ARADDR,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_ftu ARLEN"   *) output  wire  [ 7:0]                 M_AXI_FTU_ARLEN,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_ftu ARSIZE"  *) output  wire  [ 2:0]                 M_AXI_FTU_ARSIZE,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_ftu ARBURST" *) output  wire  [ 1:0]                 M_AXI_FTU_ARBURST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_ftu ARVALID" *) output  wire                         M_AXI_FTU_ARVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_ftu ARREADY" *) input   wire                         M_AXI_FTU_ARREADY,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_ftu RID"     *) input   wire  [M_AXI_WIDTH_ID-1:0]   M_AXI_FTU_RID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_ftu RDATA"   *) input   wire  [M_AXI_WIDTH_DA-1:0]   M_AXI_FTU_RDATA,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_ftu RRESP"   *) input   wire  [ 1:0]                 M_AXI_FTU_RRESP,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_ftu RLAST"   *) input   wire                         M_AXI_FTU_RLAST,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_ftu RVALID"  *) input   wire                         M_AXI_FTU_RVALID,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m_axi_ftu RREADY"  *) output  wire                         M_AXI_FTU_RREADY,
     // 
    (* X_INTERFACE_PARAMETER = "SENSITIVITY LEVEL_HIGH" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:interrupt:1.0 interrupt INTERRUPT" *)
    output wire                          interrupt // interrupt to get attention
);
endmodule
