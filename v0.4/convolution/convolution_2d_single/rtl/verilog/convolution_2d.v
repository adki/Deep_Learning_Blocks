//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All right reserved.
//------------------------------------------------------------------------------
// VERSION: 2021.11.06.
//------------------------------------------------------------------------------
// Convolution 2D
//------------------------------------------------------------------------------
// all square matrix
//
//         kernel_width  feature_width   feature_width         result_width
//       |<----->|     |<--------->|   |<---------->|        |<------->|
//       +-------+     +-----------+   +------------+        +---------+
//       |       | *   | input     | + | feature    |  +  =  |         |
//       |       |     | feature   |   | of other   |  |     |         |
//       +-------+     |           |   | channel    |  b     |         |
//                     |           |   |            |  i     |         |
//                     +-----------+   +------------+  a     +---------+
//                                                     s
//------------------------------------------------------------------------------
//                                              +---------------------+
//                                              | -+-+-+              |
//                                              |  | | |==> kernel    |
//                                              | -+-+-+              |
//                                              | -+-+-+              |
//                                              |  | | |==> feature   |
//                                              | -+-+-+              |
//                                              | -+-+-+              |
//                                              |  | | |==> channel   |
//                                              | -+-+-+              |
//                                              |  +-+-+-             |
//                                              |  | | |<== result    |
//                                              |  +-+-+-             |
//            +-------------+                   |                     |
//       AXI4 |             |  conv_core_ready  |                     |
//      <====>| control     |<------------------| core                |
//            |             |                   |                     |
//            |             |<----------+------>|                     |
//            +-------------+           |       +---------------------+
//                |     | conv_ready    |              |
//                |     +----------+    | conv_init    |
//                |                |    |              |
//                |              +-----------+         |
//                |              |           |         |
//      APB       |              | csr       |         |
//      <=========|=============>|           |         |
//                |              |           |         |
//                |              +-----------+         |
//                |                  |                 |
// ARESETn -------+------------------+-----------------+
//
//------------------------------------------------------------------------------
`ifdef VIVADO
`define DBG_CONV (* mark_debug="true" *)
`else
`define DBG_CONV
`endif

`include "convolution_2d_csr.v"
`include "convolution_2d_core.v"
`include "convolution_2d_control.v"
`include "convolution_2d_sync.v"

module convolution_2d
     #(parameter APB_WIDTH_AD   =32  // address width
               , APB_WIDTH_DA   =32  // data width
               , M_AXI_WIDTH_ID =4   // ID width in bits
               , M_AXI_WIDTH_AD =32  // address width
               , M_AXI_WIDTH_DA =32  // data width
               , M_AXI_WIDTH_DS =(M_AXI_WIDTH_DA/8)
               , DATA_TYPE="INTEGER" // "INTEGER", "FLOATING_POINT", "FIXED_POINT"
               , DATA_WIDTH     =32 // bit-width of an item
               `ifdef DATA_FIXED_POINT
               , DATA_WIDTH_Q=(DATA_WIDTH/2) // fractional bits
               `endif
               , KERNEL_MAX_SIZE   =5
               , KERNEL_FIFO_DEPTH =1<<$clog2(KERNEL_MAX_SIZE*KERNEL_MAX_SIZE)
               , FEATURE_FIFO_DEPTH=1<<$clog2(KERNEL_MAX_SIZE*2)
               , CHANNEL_FIFO_DEPTH=1<<$clog2(KERNEL_MAX_SIZE*2)
               , RESULT_FIFO_DEPTH =1<<$clog2(KERNEL_MAX_SIZE*2)
               , PROFILE_CNT_WIDTH=32
               , ACTIV_FUNC_BYPASS    =4'h0
               , ACTIV_FUNC_RELU      =4'h1
               , ACTIV_FUNC_LEAKY_RELU=4'h2
               , ACTIV_FUNC_SIGMOID   =4'h3
               , ACTIV_FUNC_TANH      =4'h4
               )
(
       input   wire                         PRESETn
     , input   wire                         PCLK
     , input   wire                         S_APB_PSEL
     , input   wire                         S_APB_PENABLE
     , input   wire [APB_WIDTH_AD-1:0]      S_APB_PADDR
     , input   wire                         S_APB_PWRITE
     , output  wire [APB_WIDTH_DA-1:0]      S_APB_PRDATA
     , input   wire [APB_WIDTH_DA-1:0]      S_APB_PWDATA
     , output  wire                         S_APB_PREADY
     , output  wire                         S_APB_PSLVERR
     , input   wire                         ARESETn
     , input   wire                         ACLK
     // master port for result (write-only)
     , output  wire  [M_AXI_WIDTH_ID-1:0]   M_AXI_RST_AWID
     , output  wire  [M_AXI_WIDTH_AD-1:0]   M_AXI_RST_AWADDR
     , output  wire  [ 7:0]                 M_AXI_RST_AWLEN
     , output  wire  [ 2:0]                 M_AXI_RST_AWSIZE
     , output  wire  [ 1:0]                 M_AXI_RST_AWBURST
     , output  wire                         M_AXI_RST_AWVALID
     , input   wire                         M_AXI_RST_AWREADY
     , output  wire  [M_AXI_WIDTH_DA-1:0]   M_AXI_RST_WDATA
     , output  wire  [M_AXI_WIDTH_DS-1:0]   M_AXI_RST_WSTRB
     , output  wire                         M_AXI_RST_WLAST
     , output  wire                         M_AXI_RST_WVALID
     , input   wire                         M_AXI_RST_WREADY
     , input   wire  [M_AXI_WIDTH_ID-1:0]   M_AXI_RST_BID
     , input   wire  [ 1:0]                 M_AXI_RST_BRESP
     , input   wire                         M_AXI_RST_BVALID
     , output  wire                         M_AXI_RST_BREADY
     // master port for kernel (read-only)
     , output  wire  [M_AXI_WIDTH_ID-1:0]   M_AXI_KNL_ARID
     , output  wire  [M_AXI_WIDTH_AD-1:0]   M_AXI_KNL_ARADDR
     , output  wire  [ 7:0]                 M_AXI_KNL_ARLEN
     , output  wire  [ 2:0]                 M_AXI_KNL_ARSIZE
     , output  wire  [ 1:0]                 M_AXI_KNL_ARBURST
     , output  wire                         M_AXI_KNL_ARVALID
     , input   wire                         M_AXI_KNL_ARREADY
     , input   wire  [M_AXI_WIDTH_ID-1:0]   M_AXI_KNL_RID
     , input   wire  [M_AXI_WIDTH_DA-1:0]   M_AXI_KNL_RDATA
     , input   wire  [ 1:0]                 M_AXI_KNL_RRESP
     , input   wire                         M_AXI_KNL_RLAST
     , input   wire                         M_AXI_KNL_RVALID
     , output  wire                         M_AXI_KNL_RREADY
     // master port for feature (read-only)
     , output  wire  [M_AXI_WIDTH_ID-1:0]   M_AXI_FTU_ARID
     , output  wire  [M_AXI_WIDTH_AD-1:0]   M_AXI_FTU_ARADDR
     , output  wire  [ 7:0]                 M_AXI_FTU_ARLEN
     , output  wire  [ 2:0]                 M_AXI_FTU_ARSIZE
     , output  wire  [ 1:0]                 M_AXI_FTU_ARBURST
     , output  wire                         M_AXI_FTU_ARVALID
     , input   wire                         M_AXI_FTU_ARREADY
     , input   wire  [M_AXI_WIDTH_ID-1:0]   M_AXI_FTU_RID
     , input   wire  [M_AXI_WIDTH_DA-1:0]   M_AXI_FTU_RDATA
     , input   wire  [ 1:0]                 M_AXI_FTU_RRESP
     , input   wire                         M_AXI_FTU_RLAST
     , input   wire                         M_AXI_FTU_RVALID
     , output  wire                         M_AXI_FTU_RREADY
     // master port for previous-channel result (read-only)
     , output  wire  [M_AXI_WIDTH_ID-1:0]   M_AXI_CHN_ARID
     , output  wire  [M_AXI_WIDTH_AD-1:0]   M_AXI_CHN_ARADDR
     , output  wire  [ 7:0]                 M_AXI_CHN_ARLEN
     , output  wire  [ 2:0]                 M_AXI_CHN_ARSIZE
     , output  wire  [ 1:0]                 M_AXI_CHN_ARBURST
     , output  wire                         M_AXI_CHN_ARVALID
     , input   wire                         M_AXI_CHN_ARREADY
     , input   wire  [M_AXI_WIDTH_ID-1:0]   M_AXI_CHN_RID
     , input   wire  [M_AXI_WIDTH_DA-1:0]   M_AXI_CHN_RDATA
     , input   wire  [ 1:0]                 M_AXI_CHN_RRESP
     , input   wire                         M_AXI_CHN_RLAST
     , input   wire                         M_AXI_CHN_RVALID
     , output  wire                         M_AXI_CHN_RREADY
     // 
     , output wire                          interrupt // interrupt to get attention
);
    //--------------------------------------------------------------------------
    assign S_APB_PREADY=1'b1;
    assign S_APB_PSLVERR=1'b0;
    //--------------------------------------------------------------------------
    localparam DATA_BYTES     =(DATA_WIDTH/8)
             , KERNEL_FIFO_AW =$clog2(KERNEL_FIFO_DEPTH )
             , FEATURE_FIFO_AW=$clog2(FEATURE_FIFO_DEPTH)
             , CHANNEL_FIFO_AW=$clog2(CHANNEL_FIFO_DEPTH)
             , RESULT_FIFO_AW =$clog2(RESULT_FIFO_DEPTH );
    //--------------------------------------------------------------------------
    wire                       kernel_go, kernel_go_sync;
    wire                       kernel_done, kernel_done_sync;// read-done
    wire [M_AXI_WIDTH_AD-1:0]  kernel_address;
    wire [ 3:0]                kernel_width; // num of items in row
    wire [ 3:0]                kernel_height;
    wire [ 7:0]                kernel_items;
    wire [ 7:0]                kernel_leng;// AxLENG format

    wire                       feature_go, feature_go_sync;
    wire                       feature_done, feature_done_sync;// read-done
    wire [M_AXI_WIDTH_AD-1:0]  feature_address;
    wire [15:0]                feature_width;// num of items in row
    wire [15:0]                feature_height;
    wire [31:0]                feature_items;
    wire [ 3:0]                feature_padding_pre;
    wire [ 3:0]                feature_padding_post;
    wire [ 3:0]                feature_stride;
    wire [ 7:0]                feature_leng;// AxLENG format

    wire                       channel_go, channel_go_sync;
    wire                       channel_done, channel_done_sync;// read-done
    wire [M_AXI_WIDTH_AD-1:0]  channel_address;
    wire [15:0]                channel_width;// num of items in row
    wire [15:0]                channel_height;
    wire [31:0]                channel_items;// num of items whole
    wire [ 7:0]                channel_leng;// AxLENG format
    wire                       channel_mode;

    wire                       result_go, result_go_sync;
    wire                       result_done, result_done_sync;// read-done
    wire [M_AXI_WIDTH_AD-1:0]  result_address;
    wire [15:0]                result_width;// num of items in row
    wire [15:0]                result_height;
    wire [31:0]                result_items;// num of items whole
    wire [ 7:0]                result_leng;// AxLENG format
    //--------------------------------------------------------------------------
    wire [DATA_WIDTH-1:0]      conv_bias;
    wire [ 3:0]                conv_activ_func;
    wire [DATA_WIDTH-1:0]      conv_activ_param;
    wire                       conv_init, conv_init_sync; // synchronous initialization
    wire                       conv_ready, conv_ready_sync; // between csr<->control
    wire                       conv_core_ready; // signal between control<->core
    //--------------------------------------------------------------------------
    wire                         profile_init, profile_init_sync;
    wire                         profile_snapshot, profile_snapshot_sync;
    reg                          profile_done=1'b0; // done of profile_snapshot
    wire                         profile_done_sync;
    wire [PROFILE_CNT_WIDTH-1:0] profile_mac_num;
    wire [PROFILE_CNT_WIDTH-1:0] profile_mac_overflow;
    wire [PROFILE_CNT_WIDTH-1:0] profile_channel_overflow;
    wire [PROFILE_CNT_WIDTH-1:0] profile_bias_overflow;
    wire [PROFILE_CNT_WIDTH-1:0] profile_activ_overflow;
    wire [PROFILE_CNT_WIDTH-1:0] profile_cnt_read;
    wire [PROFILE_CNT_WIDTH-1:0] profile_cnt_write;
    //--------------------------------------------------------------------------
    reg  [PROFILE_CNT_WIDTH-1:0] profile_mac_num_reg='h0; // get valid value when profile_done
    reg  [PROFILE_CNT_WIDTH-1:0] profile_mac_overflow_reg='h0; // get valid value when profile_done
    reg  [PROFILE_CNT_WIDTH-1:0] profile_channel_overflow_reg='h0; // get valid value when profile_done
    reg  [PROFILE_CNT_WIDTH-1:0] profile_bias_overflow_reg='h0; // get valid value when profile_done
    reg  [PROFILE_CNT_WIDTH-1:0] profile_activ_overflow_reg='h0; // get valid value when profile_done
    reg  [PROFILE_CNT_WIDTH-1:0] profile_cnt_read_reg='h0; // get valid value when profile_done
    reg  [PROFILE_CNT_WIDTH-1:0] profile_cnt_write_reg='h0; // get valid value when profile_done
    //--------------------------------------------------------------------------
    wire                       IO_KNL_READY;
    wire                       IO_KNL_VALID;
    wire [DATA_WIDTH-1:0]      IO_KNL_DATA ;
    wire                       IO_KNL_LAST ;
    wire [KERNEL_FIFO_AW:0]    IO_KNL_ROOMS;
    wire [ 1:0]                IO_KNL_MODE ;
    wire                       IO_FTU_READY;
    wire                       IO_FTU_VALID;
    wire [DATA_WIDTH-1:0]      IO_FTU_DATA ;
    wire                       IO_FTU_LAST ;
    wire [FEATURE_FIFO_AW:0]   IO_FTU_ROOMS;
    wire                       IO_CHN_READY;
    wire                       IO_CHN_VALID;
    wire [DATA_WIDTH-1:0]      IO_CHN_DATA ;
    wire                       IO_CHN_LAST ;
    wire [CHANNEL_FIFO_AW:0]   IO_CHN_ROOMS;
    wire                       IO_CHN_MODE ;
    wire                       IO_RST_READY;
    wire                       IO_RST_VALID;
    wire [DATA_WIDTH-1:0]      IO_RST_DATA ;
    wire                       IO_RST_LAST ;
    wire [RESULT_FIFO_AW:0]    IO_RST_ITEMS;
    //--------------------------------------------------------------------------
    convolution_2d_core #(.DATA_TYPE         (DATA_TYPE         )
                         ,.DATA_WIDTH        (DATA_WIDTH        )
                         `ifdef DATA_FIXED_POINT
                         ,.DATA_WIDTH_Q      (DATA_WIDTH_Q      )
                         `endif
                         ,.KERNEL_FIFO_DEPTH (KERNEL_FIFO_DEPTH )
                         ,.FEATURE_FIFO_DEPTH(FEATURE_FIFO_DEPTH)
                         ,.CHANNEL_FIFO_DEPTH(CHANNEL_FIFO_DEPTH)
                         ,.RESULT_FIFO_DEPTH (RESULT_FIFO_DEPTH )
                         ,.PROFILE_CNT_WIDTH (PROFILE_CNT_WIDTH )
                         ,.ACTIV_FUNC_BYPASS    ( ACTIV_FUNC_BYPASS     )
                         ,.ACTIV_FUNC_RELU      ( ACTIV_FUNC_RELU       )
                         ,.ACTIV_FUNC_LEAKY_RELU( ACTIV_FUNC_LEAKY_RELU )
                         ,.ACTIV_FUNC_SIGMOID   ( ACTIV_FUNC_SIGMOID    )
                         ,.ACTIV_FUNC_TANH      ( ACTIV_FUNC_TANH       )
                         )
    u_core (
         .RESET_N        ( ARESETn      )
       , .CLK            ( ACLK         )
       , .IN_KNL_READY   ( IO_KNL_READY )
       , .IN_KNL_VALID   ( IO_KNL_VALID )
       , .IN_KNL_DATA    ( IO_KNL_DATA  )
       , .IN_KNL_LAST    ( IO_KNL_LAST  )
       , .IN_KNL_ROOMS   ( IO_KNL_ROOMS )
       , .IN_KNL_MODE    ( IO_KNL_MODE  )
       , .IN_FTU_READY   ( IO_FTU_READY )
       , .IN_FTU_VALID   ( IO_FTU_VALID )
       , .IN_FTU_DATA    ( IO_FTU_DATA  )
       , .IN_FTU_LAST    ( IO_FTU_LAST  )
       , .IN_FTU_ROOMS   ( IO_FTU_ROOMS )
       , .IN_CHN_READY   ( IO_CHN_READY )
       , .IN_CHN_VALID   ( IO_CHN_VALID )
       , .IN_CHN_DATA    ( IO_CHN_DATA  )
       , .IN_CHN_LAST    ( IO_CHN_LAST  )
       , .IN_CHN_ROOMS   ( IO_CHN_ROOMS )
       , .IN_CHN_MODE    ( IO_CHN_MODE  )
       , .OUT_RST_READY  ( IO_RST_READY )
       , .OUT_RST_VALID  ( IO_RST_VALID )
       , .OUT_RST_DATA   ( IO_RST_DATA  )
       , .OUT_RST_LAST   ( IO_RST_LAST  )
       , .OUT_RST_ITEMS  ( IO_RST_ITEMS )
       , .BIAS           ( conv_bias        ) // from CSR
       , .ACTIV_FUNC     ( conv_activ_func  ) // from CSR
       , .ACTIV_PARAM    ( conv_activ_param ) // from CSR
       , .CONV_INIT      ( conv_init_sync   ) // from controller
       , .CONV_READY     ( conv_core_ready  ) // to controller
       , .profile_init            ( profile_init_sync        )
       , .profile_mac_num         ( profile_mac_num          )
       , .profile_mac_overflow    ( profile_mac_overflow     )
       , .profile_channel_overflow( profile_channel_overflow )
       , .profile_bias_overflow   ( profile_bias_overflow    )
       , .profile_activ_overflow  ( profile_activ_overflow   )
    );
    //--------------------------------------------------------------------------
    convolution_2d_control #(.AXI_WIDTH_ID      (M_AXI_WIDTH_ID    )
                            ,.AXI_WIDTH_AD      (M_AXI_WIDTH_AD    )
                            ,.AXI_WIDTH_DA      (M_AXI_WIDTH_DA    )
                            ,.DATA_WIDTH        (DATA_WIDTH        )
                            ,.KERNEL_FIFO_DEPTH (KERNEL_FIFO_DEPTH )
                            ,.FEATURE_FIFO_DEPTH(FEATURE_FIFO_DEPTH)
                            ,.CHANNEL_FIFO_DEPTH(CHANNEL_FIFO_DEPTH)
                            ,.RESULT_FIFO_DEPTH (RESULT_FIFO_DEPTH )
                            )
    u_control (
          .ARESETn               ( ARESETn              )
        , .ACLK                  ( ACLK                 )
        , .M_AXI_KNL_ARID        ( M_AXI_KNL_ARID       )
        , .M_AXI_KNL_ARADDR      ( M_AXI_KNL_ARADDR     )
        , .M_AXI_KNL_ARLEN       ( M_AXI_KNL_ARLEN      )
        , .M_AXI_KNL_ARSIZE      ( M_AXI_KNL_ARSIZE     )
        , .M_AXI_KNL_ARBURST     ( M_AXI_KNL_ARBURST    )
        , .M_AXI_KNL_ARVALID     ( M_AXI_KNL_ARVALID    )
        , .M_AXI_KNL_ARREADY     ( M_AXI_KNL_ARREADY    )
        , .M_AXI_KNL_RID         ( M_AXI_KNL_RID        )
        , .M_AXI_KNL_RDATA       ( M_AXI_KNL_RDATA      )
        , .M_AXI_KNL_RRESP       ( M_AXI_KNL_RRESP      )
        , .M_AXI_KNL_RLAST       ( M_AXI_KNL_RLAST      )
        , .M_AXI_KNL_RVALID      ( M_AXI_KNL_RVALID     )
        , .M_AXI_KNL_RREADY      ( M_AXI_KNL_RREADY     )
        , .M_AXI_FTU_ARID        ( M_AXI_FTU_ARID       )
        , .M_AXI_FTU_ARADDR      ( M_AXI_FTU_ARADDR     )
        , .M_AXI_FTU_ARLEN       ( M_AXI_FTU_ARLEN      )
        , .M_AXI_FTU_ARSIZE      ( M_AXI_FTU_ARSIZE     )
        , .M_AXI_FTU_ARBURST     ( M_AXI_FTU_ARBURST    )
        , .M_AXI_FTU_ARVALID     ( M_AXI_FTU_ARVALID    )
        , .M_AXI_FTU_ARREADY     ( M_AXI_FTU_ARREADY    )
        , .M_AXI_FTU_RID         ( M_AXI_FTU_RID        )
        , .M_AXI_FTU_RDATA       ( M_AXI_FTU_RDATA      )
        , .M_AXI_FTU_RRESP       ( M_AXI_FTU_RRESP      )
        , .M_AXI_FTU_RLAST       ( M_AXI_FTU_RLAST      )
        , .M_AXI_FTU_RVALID      ( M_AXI_FTU_RVALID     )
        , .M_AXI_FTU_RREADY      ( M_AXI_FTU_RREADY     )
        , .M_AXI_CHN_ARID        ( M_AXI_CHN_ARID       )
        , .M_AXI_CHN_ARADDR      ( M_AXI_CHN_ARADDR     )
        , .M_AXI_CHN_ARLEN       ( M_AXI_CHN_ARLEN      )
        , .M_AXI_CHN_ARSIZE      ( M_AXI_CHN_ARSIZE     )
        , .M_AXI_CHN_ARBURST     ( M_AXI_CHN_ARBURST    )
        , .M_AXI_CHN_ARVALID     ( M_AXI_CHN_ARVALID    )
        , .M_AXI_CHN_ARREADY     ( M_AXI_CHN_ARREADY    )
        , .M_AXI_CHN_RID         ( M_AXI_CHN_RID        )
        , .M_AXI_CHN_RDATA       ( M_AXI_CHN_RDATA      )
        , .M_AXI_CHN_RRESP       ( M_AXI_CHN_RRESP      )
        , .M_AXI_CHN_RLAST       ( M_AXI_CHN_RLAST      )
        , .M_AXI_CHN_RVALID      ( M_AXI_CHN_RVALID     )
        , .M_AXI_CHN_RREADY      ( M_AXI_CHN_RREADY     )
        , .M_AXI_RST_AWID        ( M_AXI_RST_AWID       )
        , .M_AXI_RST_AWADDR      ( M_AXI_RST_AWADDR     )
        , .M_AXI_RST_AWLEN       ( M_AXI_RST_AWLEN      )
        , .M_AXI_RST_AWSIZE      ( M_AXI_RST_AWSIZE     )
        , .M_AXI_RST_AWBURST     ( M_AXI_RST_AWBURST    )
        , .M_AXI_RST_AWVALID     ( M_AXI_RST_AWVALID    )
        , .M_AXI_RST_AWREADY     ( M_AXI_RST_AWREADY    )
        , .M_AXI_RST_WDATA       ( M_AXI_RST_WDATA      )
        , .M_AXI_RST_WSTRB       ( M_AXI_RST_WSTRB      )
        , .M_AXI_RST_WLAST       ( M_AXI_RST_WLAST      )
        , .M_AXI_RST_WVALID      ( M_AXI_RST_WVALID     )
        , .M_AXI_RST_WREADY      ( M_AXI_RST_WREADY     )
        , .M_AXI_RST_BID         ( M_AXI_RST_BID        )
        , .M_AXI_RST_BRESP       ( M_AXI_RST_BRESP      )
        , .M_AXI_RST_BVALID      ( M_AXI_RST_BVALID     )
        , .M_AXI_RST_BREADY      ( M_AXI_RST_BREADY     )
        , .OUT_KNL_READY         ( IO_KNL_READY         )
        , .OUT_KNL_VALID         ( IO_KNL_VALID         )
        , .OUT_KNL_DATA          ( IO_KNL_DATA          )
        , .OUT_KNL_LAST          ( IO_KNL_LAST          )
        , .OUT_KNL_ROOMS         ( IO_KNL_ROOMS         )
        , .OUT_KNL_MODE          ( IO_KNL_MODE          )
        , .OUT_FTU_READY         ( IO_FTU_READY         )
        , .OUT_FTU_VALID         ( IO_FTU_VALID         )
        , .OUT_FTU_DATA          ( IO_FTU_DATA          )
        , .OUT_FTU_LAST          ( IO_FTU_LAST          )
        , .OUT_FTU_ROOMS         ( IO_FTU_ROOMS         )
        , .OUT_CHN_READY         ( IO_CHN_READY         )
        , .OUT_CHN_VALID         ( IO_CHN_VALID         )
        , .OUT_CHN_DATA          ( IO_CHN_DATA          )
        , .OUT_CHN_LAST          ( IO_CHN_LAST          )
        , .OUT_CHN_ROOMS         ( IO_CHN_ROOMS         )
        , .OUT_CHN_MODE          ( IO_CHN_MODE          )
        , .IN_RST_READY          ( IO_RST_READY         )
        , .IN_RST_VALID          ( IO_RST_VALID         )
        , .IN_RST_DATA           ( IO_RST_DATA          )
        , .IN_RST_LAST           ( IO_RST_LAST          )
        , .IN_RST_ITEMS          ( IO_RST_ITEMS         )
        , .kernel_go             ( kernel_go_sync       )
        , .kernel_done           ( kernel_done          )
        , .kernel_address        ( kernel_address       )
        , .kernel_width          ( kernel_width         )
        , .kernel_height         ( kernel_height        )
        , .kernel_items          ( kernel_items         )
        , .kernel_leng           ( kernel_leng          )
        , .feature_go            ( feature_go_sync      )
        , .feature_done          ( feature_done         )
        , .feature_address       ( feature_address      )
        , .feature_width         ( feature_width        )
        , .feature_height        ( feature_height       )
        , .feature_items         ( feature_items        )
        , .feature_padding_pre   ( feature_padding_pre  )
        , .feature_padding_post  ( feature_padding_post )
        , .feature_stride        ( feature_stride       )
        , .feature_leng          ( feature_leng         )
        , .channel_go            ( channel_go_sync      )
        , .channel_done          ( channel_done         )
        , .channel_address       ( channel_address      )
        , .channel_width         ( channel_width        )
        , .channel_height        ( channel_height       )
        , .channel_items         ( channel_items        )
        , .channel_leng          ( channel_leng         )
        , .channel_mode          ( channel_mode         )
        , .result_go             ( result_go_sync       )
        , .result_done           ( result_done          )
        , .result_address        ( result_address       )
        , .result_width          ( result_width         )
        , .result_height         ( result_height        )
        , .result_items          ( result_items         )
        , .result_leng           ( result_leng          )
        , .conv_init             ( conv_init_sync       )
        , .conv_ready            ( conv_ready           )
        , .conv_core_ready       ( conv_core_ready      )
        , .profile_init          ( profile_init         )
        , .profile_cnt_read      ( profile_cnt_read     )
        , .profile_cnt_write     ( profile_cnt_write    )
    );
    //--------------------------------------------------------------------------
    convolution_2d_csr #(.APB_WIDTH_AD      (APB_WIDTH_AD      )
                        ,.APB_WIDTH_DA      (APB_WIDTH_DA      )
                        ,.AXI_WIDTH_AD      (M_AXI_WIDTH_AD    )
                        ,.DATA_TYPE         (DATA_TYPE         )
                        ,.DATA_WIDTH        (DATA_WIDTH        )
                        `ifdef DATA_FIXED_POINT
                        ,.DATA_WIDTH_Q      (DATA_WIDTH_Q      )
                        `endif
                        ,.KERNEL_FIFO_DEPTH (KERNEL_FIFO_DEPTH )
                        ,.FEATURE_FIFO_DEPTH(FEATURE_FIFO_DEPTH)
                        ,.CHANNEL_FIFO_DEPTH(CHANNEL_FIFO_DEPTH)
                        ,.RESULT_FIFO_DEPTH (RESULT_FIFO_DEPTH )
                        ,.PROFILE_CNT_WIDTH (PROFILE_CNT_WIDTH )
                        )
    u_csr (
         .PRESETn             ( PRESETn       )
       , .PCLK                ( PCLK          )
       , .PSEL                ( S_APB_PSEL    )
       , .PENABLE             ( S_APB_PENABLE )
       , .PADDR               ( S_APB_PADDR   )
       , .PWRITE              ( S_APB_PWRITE  )
       , .PRDATA              ( S_APB_PRDATA  )
       , .PWDATA              ( S_APB_PWDATA  )
       , .kernel_go           ( kernel_go            )
       , .kernel_done         ( kernel_done_sync     )
       , .kernel_address      ( kernel_address       )
       , .kernel_width        ( kernel_width         )
       , .kernel_height       ( kernel_height        )
       , .kernel_items        ( kernel_items         )
       , .kernel_leng         ( kernel_leng          )
       , .feature_go          ( feature_go           )
       , .feature_done        ( feature_done_sync    )
       , .feature_address     ( feature_address      )
       , .feature_width       ( feature_width        )
       , .feature_height      ( feature_height       )
       , .feature_items       ( feature_items        )
       , .feature_padding_pre ( feature_padding_pre  )
       , .feature_padding_post( feature_padding_post )
       , .feature_stride      ( feature_stride       )
       , .feature_leng        ( feature_leng         )
       , .channel_go          ( channel_go           )
       , .channel_done        ( channel_done_sync    )
       , .channel_address     ( channel_address      )
       , .channel_width       ( channel_width        )
       , .channel_height      ( channel_height       )
       , .channel_items       ( channel_items        )
       , .channel_leng        ( channel_leng         )
       , .channel_mode        ( channel_mode         )
       , .result_go           ( result_go            )
       , .result_done         ( result_done_sync     )
       , .result_address      ( result_address       )
       , .result_width        ( result_width         )
       , .result_height       ( result_height        )
       , .result_items        ( result_items         )
       , .result_leng         ( result_leng          )
       , .conv_bias           ( conv_bias            )
       , .conv_activ_func     ( conv_activ_func      )
       , .conv_activ_param    ( conv_activ_param     )
       , .conv_init           ( conv_init            )
       , .conv_ready          ( conv_ready_sync      )
       , .profile_init            ( profile_init                 )
       , .profile_snapshot        ( profile_snapshot             )
       , .profile_done            ( profile_done_sync            )
       , .profile_mac_num         ( profile_mac_num_reg          )
       , .profile_mac_overflow    ( profile_mac_overflow_reg     )
       , .profile_channel_overflow( profile_channel_overflow_reg )
       , .profile_bias_overflow   ( profile_bias_overflow_reg    )
       , .profile_activ_overflow  ( profile_activ_overflow_reg   )
       , .profile_cnt_read        ( profile_cnt_read_reg         )
       , .profile_cnt_write       ( profile_cnt_write_reg        )
       , .interrupt               ( interrupt                    )
    );
    //--------------------------------------------------------------------------
    convolution_2d_sync u_sync_init (
          .reset_n ( ARESETn        )
        , .clk     ( ACLK           )
        , .sig_in  ( conv_init      )
        , .sig_out ( conv_init_sync )
    );
    convolution_2d_sync u_sync_profile_init (
          .reset_n ( ARESETn           )
        , .clk     ( ACLK              )
        , .sig_in  ( profile_init      )
        , .sig_out ( profile_init_sync )
    );
    convolution_2d_sync u_sync_profile_snapshot (
          .reset_n ( ARESETn               )
        , .clk     ( ACLK                  )
        , .sig_in  ( profile_snapshot      )
        , .sig_out ( profile_snapshot_sync )
    );
    convolution_2d_sync u_sync_kernel_go (
          .reset_n ( ARESETn         )
        , .clk     ( ACLK            )
        , .sig_in  ( kernel_go      )
        , .sig_out ( kernel_go_sync )
    );
    convolution_2d_sync u_sync_feature_go (
          .reset_n ( ARESETn         )
        , .clk     ( ACLK            )
        , .sig_in  ( feature_go      )
        , .sig_out ( feature_go_sync )
    );
    convolution_2d_sync u_sync_channel_go (
          .reset_n ( ARESETn         )
        , .clk     ( ACLK            )
        , .sig_in  ( channel_go      )
        , .sig_out ( channel_go_sync )
    );
    convolution_2d_sync u_sync_result_go (
          .reset_n ( ARESETn        )
        , .clk     ( ACLK           )
        , .sig_in  ( result_go      )
        , .sig_out ( result_go_sync )
    );
    //--------------------------------------------------------------------------
    convolution_2d_sync u_sync_ready (
          .reset_n ( PRESETn         )
        , .clk     ( PCLK            )
        , .sig_in  ( conv_ready      )
        , .sig_out ( conv_ready_sync )
    );
    convolution_2d_sync u_sync_profile_done ( // snapshot done
          .reset_n ( PRESETn           )
        , .clk     ( PCLK              )
        , .sig_in  ( profile_done      )
        , .sig_out ( profile_done_sync )
    );
    convolution_2d_sync u_sync_kernel_done (
          .reset_n ( PRESETn          )
        , .clk     ( PCLK             )
        , .sig_in  ( kernel_done      )
        , .sig_out ( kernel_done_sync )
    );
    convolution_2d_sync u_sync_feature_done (
          .reset_n ( PRESETn           )
        , .clk     ( PCLK              )
        , .sig_in  ( feature_done      )
        , .sig_out ( feature_done_sync )
    );
    convolution_2d_sync u_sync_channel_done (
          .reset_n ( PRESETn           )
        , .clk     ( PCLK              )
        , .sig_in  ( channel_done      )
        , .sig_out ( channel_done_sync )
    );
    convolution_2d_sync u_sync_result_done (
          .reset_n ( PRESETn          )
        , .clk     ( PCLK             )
        , .sig_in  ( result_done      )
        , .sig_out ( result_done_sync )
    );
    //--------------------------------------------------------------------------
    always @ (posedge ACLK or negedge ARESETn) begin
    if (ARESETn==1'b0) begin
        profile_done                 <=1'b0;
        profile_mac_num_reg          <= 'h0; // get valid value when profile_done
        profile_mac_overflow_reg     <= 'h0; // get valid value when profile_done
        profile_channel_overflow_reg <= 'h0; // get valid value when profile_done
        profile_bias_overflow_reg    <= 'h0; // get valid value when profile_done
        profile_activ_overflow_reg   <= 'h0; // get valid value when profile_done
        profile_cnt_read_reg         <= 'h0; // get valid value when profile_done
        profile_cnt_write_reg        <= 'h0; // get valid value when profile_done
    end else begin
        if ((profile_done==1'b0)&&(profile_snapshot_sync==1'b1)) begin
            profile_mac_num_reg          <= profile_mac_num;
            profile_mac_overflow_reg     <= profile_mac_overflow;
            profile_channel_overflow_reg <= profile_channel_overflow;
            profile_bias_overflow_reg    <= profile_bias_overflow;
            profile_activ_overflow_reg   <= profile_activ_overflow;
            profile_cnt_read_reg         <= profile_cnt_read;
            profile_cnt_write_reg        <= profile_cnt_write;
            profile_done                 <= 1'b1;
        end else begin
            if (profile_snapshot_sync==1'b0) begin
                profile_done <= 1'b0;
            end
        end
    end
    end // always
endmodule
//------------------------------------------------------------------------------
// Revision history
//
// 2021.11.06: APB interface
// 2021.06.10: Started by Ando Ki (andoki@gmail.com)
//------------------------------------------------------------------------------
