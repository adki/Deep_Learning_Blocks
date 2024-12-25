//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All right reserved.
//------------------------------------------------------------------------------
// VERSION: 2021.06.10.
//------------------------------------------------------------------------------
// Convolution 2D Core
//------------------------------------------------------------------------------
// Coding guideline
// - use capital for port name
//------------------------------------------------------------------------------
//                                       |
//                                       |<---'last' makes effective
//     kernel ___  kernel_fifo           |
//     ----->|   \  --+--+         ___   | 
//           |MUX|--->|  |--+---->|   \  |  ___
//       +-->|___/  --+--+  |     |MAC|--->|   \     ___
//       |                  | +-->|___/    |ADD|--->|   \    +----------+
//       +------------------+ |        +-->|___/    |ADD|--->|ACTIVATION|
//               feature fifo |        |        +-->|___/    +----+-----+
//     feature      --+--+    |        |        |                 |
//     -------------->|  |----+        |        |                 |
//                  --+--+             |        |                 |
//                                     |        |                 |
//               channel fifo          |        |                 |
//     channel      --+--+             |        |                 |
//     -------------->|  |-------------+        |                 |
//                  --+--+                      |                 |
//     bias                                     |                 |
//     -----------------------------------------+                 |
//               result fifo                                      |
//     result       +--+--                                        |
//     <------------|  |<-----------------------------------------+
//                  +--+--
//------------------------------------------------------------------------------
//                 |<----kernel_width x height---->|
//                  ___ ___ ___ ___ ___ ___ ___ ___     ___ ___ ___ ___ ___
//   kernel     XXXX_1_X_2_X_3_X___X___X___X___X_K_XXXXX_1_X_2_X_3_X_4_X_5_X
//                 |___________________________|___|    ___________________
//   valid      ___/                           |   \___/
//                 |                           |___|
//   last       ___|___________________________/   \______________________
//
//                  ___ ___ ___ ___ ___ ___ ___ ___     ___ ___ ___ ___ ___
//   feature    XXXX___X___X___X___X___X___X___X___XXXXX___X___X___X___X___X
//                 |___________________________|___|    ___________________
//   valid      ___/                           |   \___/
//                 |                           |___|
//   last       ___|___________________________/   \_______________________
//
//                      ___ ___ ___ ___ ___ ___ ___ ___     ___ ___ ___ ___
//   mac        XXXXXXXX___X___X___X___X___X___X___X___XXXXX___X___X___X___X
//                     |___________________________|___|    _______________
//   valid      _______/                           |   \___/
//                     |                           |___|
//   last       _______|___________________________/   \___________________
//                  ___________________________________|___________________
//   channel    XXXX___________________________________X___________________
//                  ___________________________________ ___________________
//   valid      ___/                                   X
//
// NOTE
// 'IN_KNL_LAST' : driven high for every end of kernel.
// 'IN_FTU_LAST' : driven high for every end of kernel.
// 'IN_CHN_LAST' : driven high for the end of channel.
// 'OUT_RST_LAST': driven high for the end of channel.
//------------------------------------------------------------------------------
`include "convolution_2d_fifo_sync.v"
`include "convolution_2d_activation.v"

module convolution_2d_core
     #(parameter DATA_TYPE="INTEGER" // "INTEGER", "FLOATING_POINT", "FIXED_POINT"
               , DATA_WIDTH=32
               , DATA_BYTES=(DATA_WIDTH/8)
               `ifdef DATA_FIXED_POINT
               , DATA_WIDTH_Q=(DATA_WIDTH/2) // fractional bits
               `endif
               , KERNEL_MAX_SIZE   =5
               , KERNEL_FIFO_DEPTH =1<<$clog2(KERNEL_MAX_SIZE*KERNEL_MAX_SIZE)
               , FEATURE_FIFO_DEPTH=1<<$clog2(KERNEL_MAX_SIZE*2)
               , CHANNEL_FIFO_DEPTH=1<<$clog2(KERNEL_MAX_SIZE*2)
               , RESULT_FIFO_DEPTH =1<<$clog2(KERNEL_MAX_SIZE*2)
               , KERNEL_FIFO_AW    =$clog2(KERNEL_FIFO_DEPTH )
               , FEATURE_FIFO_AW   =$clog2(FEATURE_FIFO_DEPTH)
               , CHANNEL_FIFO_AW   =$clog2(CHANNEL_FIFO_DEPTH)
               , RESULT_FIFO_AW    =$clog2(RESULT_FIFO_DEPTH )
               , PROFILE_CNT_WIDTH=32
               , ACTIV_FUNC_BYPASS    =4'h0
               , ACTIV_FUNC_RELU      =4'h1
               , ACTIV_FUNC_LEAKY_RELU=4'h2
               , ACTIV_FUNC_SIGMOID   =4'h3
               , ACTIV_FUNC_TANH      =4'h4
               )
(
      input    wire                        RESET_N
    , input    wire                        CLK
    // for kernel part of conv
    , output  reg                          IN_KNL_READY
    , input   wire                         IN_KNL_VALID
    , input   wire  [DATA_WIDTH-1:0]       IN_KNL_DATA
    , input   wire                         IN_KNL_LAST
    , output  wire  [KERNEL_FIFO_AW:0]     IN_KNL_ROOMS
    , input   wire  [ 1:0]                 IN_KNL_MODE
                                           // 00=disabled(clear), 01=fill
                                           // 10=read-out, 11=read-out-rotate
    // for feature part of conv
    , output  wire                         IN_FTU_READY
    , input   wire                         IN_FTU_VALID
    , input   wire  [DATA_WIDTH-1:0]       IN_FTU_DATA
    , input   wire                         IN_FTU_LAST
    , output  wire  [FEATURE_FIFO_AW:0]    IN_FTU_ROOMS
    // for channel part of conv
    , output  wire                         IN_CHN_READY
    , input   wire                         IN_CHN_VALID
    , input   wire  [DATA_WIDTH-1:0]       IN_CHN_DATA
    , input   wire                         IN_CHN_LAST
    , output  wire  [CHANNEL_FIFO_AW:0]    IN_CHN_ROOMS
    , input   wire                         IN_CHN_MODE
                                           // 0=disabled (not use this)
                                           // 1=enabled (use this)
    // resultant D=D+A*B+C
    , `DBG_CONV input   wire                         OUT_RST_READY
    , `DBG_CONV output  wire                         OUT_RST_VALID
    , `DBG_CONV output  wire  [DATA_WIDTH-1:0]       OUT_RST_DATA
    , `DBG_CONV output  wire                         OUT_RST_LAST
    , `DBG_CONV output  wire  [RESULT_FIFO_AW:0]     OUT_RST_ITEMS
    //
    , input   wire  [DATA_WIDTH-1:0]       BIAS
                                           // if not use, set 0
    , input   wire  [ 3:0]                 ACTIV_FUNC
                                           // if not use, set 0 for linear bypass
    , input   wire  [DATA_WIDTH-1:0]       ACTIV_PARAM
    //
    , input   wire                         CONV_INIT // synchronous initialization
    , output  wire                         CONV_READY // a pulse after CONV_INIT
    //
    , input   wire                           profile_init
    , output  reg   [PROFILE_CNT_WIDTH-1:0]  profile_mac_num
    , output  reg   [PROFILE_CNT_WIDTH-1:0]  profile_mac_overflow
    , output  reg   [PROFILE_CNT_WIDTH-1:0]  profile_channel_overflow
    , output  reg   [PROFILE_CNT_WIDTH-1:0]  profile_bias_overflow
    , output  reg   [PROFILE_CNT_WIDTH-1:0]  profile_activ_overflow
);
    //--------------------------------------------------------------------------
    `DBG_CONV wire                         mac_knl_ready; // from fifo
    `DBG_CONV reg                          mac_knl_valid;
    `DBG_CONV reg   [DATA_WIDTH-1:0]       mac_knl_data ;
    `DBG_CONV reg                          mac_knl_last ;
    `DBG_CONV wire                         mac_ftu_ready; // from fifo
    `DBG_CONV wire                         mac_ftu_valid;
    `DBG_CONV wire  [DATA_WIDTH-1:0]       mac_ftu_data ;
    `DBG_CONV wire                         mac_ftu_last ;
    `DBG_CONV wire                         mac_out_ready; // to channel adder
    `DBG_CONV wire                         mac_out_valid;
    `DBG_CONV wire  [DATA_WIDTH-1:0]       mac_out_data ;
    `DBG_CONV wire                         mac_out_last ;
    `DBG_CONV wire                         mac_out_overflow;
              wire                         mac_ready       ;
    //--------------------------------------------------------------------------
    mac_core #(.WIDTH_DATA(DATA_WIDTH)
              `ifdef DATA_FIXED_POINT
              ,.WIDTH_Q(DATA_WIDTH_Q)
              `endif
              )
    u_mac (
        .RESET_N      ( RESET_N          )
      , .CLK          ( CLK              )
      , .INIT         ( CONV_INIT        )
      , .READY        ( mac_ready        )
      , .IN_READY_A   ( mac_knl_ready    )
      , .IN_VALID_A   ( mac_knl_valid    )
      , .IN_DATA_A    ( mac_knl_data     )
      , .IN_LAST_A    ( mac_knl_last     )
      , .IN_READY_B   ( mac_ftu_ready    )
      , .IN_VALID_B   ( mac_ftu_valid    )
      , .IN_DATA_B    ( mac_ftu_data     )
      , .IN_LAST_B    ( mac_ftu_last     )
      , .OUT_READY    ( mac_out_ready    )
      , .OUT_VALID    ( mac_out_valid    )
      , .OUT_DATA     ( mac_out_data     )
      , .OUT_LAST     ( mac_out_last     )
      , .OUT_OVERFLOW ( mac_out_overflow )
    );
    //--------------------------------------------------------------------------
    wire                         add_mac_ready;
    wire                         add_mac_valid=mac_out_valid&mac_out_last;
    wire  [DATA_WIDTH-1:0]       add_mac_data =mac_out_data ;
    wire                         add_mac_last =mac_out_last ;
    wire                         add_mac_overflow=mac_out_overflow;
    `DBG_CONV wire                         add_chn_ready; // from fifo
    `DBG_CONV wire                         add_chn_valid;
    `DBG_CONV wire  [DATA_WIDTH-1:0]       add_chn_data ;
    `DBG_CONV wire                         add_chn_last ;
    `DBG_CONV wire                         add_out_ready; // to bias adder
    `DBG_CONV wire                         add_out_valid;
    `DBG_CONV wire  [DATA_WIDTH-1:0]       add_out_data ;
    `DBG_CONV wire                         add_out_last ;
    `DBG_CONV wire                         add_out_overflow;
    // Make sure mac_out_ready should be kept 1 while mac_out_last is 0.
    // Make sure add_chn_ready should be 1 when mac_out_valid & mac_out_last.
    assign mac_out_ready = (mac_out_last==1'b0) ? 1'b1 
                         : add_mac_ready & mac_out_valid & add_chn_valid;
    assign add_chn_ready = add_mac_ready & mac_out_valid & mac_out_last & add_chn_valid;
    //--------------------------------------------------------------------------
    mac_core_adder #(.N(DATA_WIDTH)
                    `ifdef DATA_FIXED_POINT
                    ,.Q(DATA_WIDTH_Q)
                    `endif
                    )
    u_add_channel (
        .reset_n      ( RESET_N          )
      , .clk          ( CLK              )
      , .in_ready     ( add_mac_ready    )
      , .in_valid     ( add_mac_valid & add_chn_valid )
      , .in_last      ( add_mac_last  & add_chn_valid )
      , .in_data_A    ( add_mac_data     )
      , .in_data_B    ( add_chn_data     )
      , .in_user      ( 'h0              )
    //, .in_overflow_A( add_mac_overflow )
    //, .in_overflow_B( 1'b0             )
      , .out_ready    ( add_out_ready    )
      , .out_valid    ( add_out_valid    )
      , .out_last     ( add_out_last     )
      , .out_data     ( add_out_data     )
      , .out_user     (                  )
      , .out_overflow ( add_out_overflow )
    );
    //--------------------------------------------------------------------------
    wire                         bia_chn_ready;
    wire                         bia_chn_valid=add_out_valid;
    wire  [DATA_WIDTH-1:0]       bia_chn_data =add_out_data ;
    wire                         bia_chn_last =add_out_last ;
    wire                         bia_chn_overflow=add_out_overflow;
    `DBG_CONV wire                         bia_bia_ready;
    `DBG_CONV wire                         bia_bia_valid=add_out_valid;
    `DBG_CONV wire  [DATA_WIDTH-1:0]       bia_bia_data =BIAS;
    `DBG_CONV wire                         bia_bia_last =add_out_last ;
    `DBG_CONV wire                         bia_out_ready   ; // to activation
    `DBG_CONV wire                         bia_out_valid   ;
    `DBG_CONV wire  [DATA_WIDTH-1:0]       bia_out_data    ;
    `DBG_CONV wire                         bia_out_last    ;
    `DBG_CONV wire                         bia_out_overflow;
    assign add_out_ready = bia_chn_ready;
    assign bia_bia_ready = bia_chn_ready;
    //--------------------------------------------------------------------------
    mac_core_adder #(.N(DATA_WIDTH)
                    `ifdef DATA_FIXED_POINT
                    ,.Q(DATA_WIDTH_Q)
                    `endif
                    )
    u_add_bias (
        .reset_n      ( RESET_N          )
      , .clk          ( CLK              )
      , .in_ready     ( bia_chn_ready    )
      , .in_valid     ( bia_chn_valid & bia_bia_valid )
      , .in_last      ( bia_chn_last  & bia_bia_last  )
      , .in_data_A    ( bia_chn_data     )
      , .in_data_B    ( bia_bia_data     )
      , .in_user      ( 'h0              )
    //, .in_overflow_A( bia_chn_overflow )
    //, .in_overflow_B( 1'b0             )
      , .out_ready    ( bia_out_ready    )
      , .out_valid    ( bia_out_valid    )
      , .out_data     ( bia_out_data     )
      , .out_user     (                  )
      , .out_last     ( bia_out_last     )
      , .out_overflow ( bia_out_overflow )
    );
    //--------------------------------------------------------------------------
    wire                         activ_bia_ready;
    wire                         activ_bia_valid=bia_out_valid;
    wire  [DATA_WIDTH-1:0]       activ_bia_data =bia_out_data ;
    wire                         activ_bia_last =bia_out_last ;
    `DBG_CONV wire                         activ_out_ready   ; // to fifo
    `DBG_CONV wire                         activ_out_valid   ;
    `DBG_CONV wire  [DATA_WIDTH-1:0]       activ_out_data    ;
    `DBG_CONV wire                         activ_out_last    ;
    `DBG_CONV wire                         activ_out_overflow;
    assign  bia_out_ready = activ_bia_ready;
    //--------------------------------------------------------------------------
    convolution_2d_activation #(.DATA_TYPE (DATA_TYPE   )
                               ,.DATA_WIDTH(DATA_WIDTH  )
                               `ifdef DATA_FIXED_POINT
                               ,.WIDTH_Q   (DATA_WIDTH_Q)
                               `endif
                               ,.USER_WIDTH(1) // not used
                               ,.ACTIV_FUNC_BYPASS    ( ACTIV_FUNC_BYPASS     )
                               ,.ACTIV_FUNC_RELU      ( ACTIV_FUNC_RELU       )
                               ,.ACTIV_FUNC_LEAKY_RELU( ACTIV_FUNC_LEAKY_RELU )
                               ,.ACTIV_FUNC_SIGMOID   ( ACTIV_FUNC_SIGMOID    )
                               ,.ACTIV_FUNC_TANH      ( ACTIV_FUNC_TANH       )
                               )
    u_activation (
        .RESET_N     ( RESET_N            )
      , .CLK         ( CLK                )
      , .ACTIV_FUNC  ( ACTIV_FUNC         )
      , .ACTIV_PARAM ( ACTIV_PARAM        )
      , .IN_READY    ( activ_bia_ready    )
      , .IN_VALID    ( activ_bia_valid    )
      , .IN_DATA     ( activ_bia_data     )
      , .IN_USER     ( 1'b0               )
      , .IN_LAST     ( activ_bia_last     )
      , .OUT_READY   ( activ_out_ready    )
      , .OUT_VALID   ( activ_out_valid    )
      , .OUT_DATA    ( activ_out_data     )
      , .OUT_USER    (                    )
      , .OUT_LAST    ( activ_out_last     )
      , .OUT_OVERFLOW( activ_out_overflow )
    );
    //--------------------------------------------------------------------------
    wire                      fifo_knl_wr_ready;
    reg                       fifo_knl_wr_valid;
    reg   [DATA_WIDTH-1:0]    fifo_knl_wr_data ;
    reg                       fifo_knl_wr_last ;
    reg                       fifo_knl_rd_ready;
    wire                      fifo_knl_rd_valid;
    wire  [DATA_WIDTH-1:0]    fifo_knl_rd_data ;
    wire                      fifo_knl_rd_last ;
    wire  [KERNEL_FIFO_AW:0]  fifo_knl_rooms   ;
    wire  [KERNEL_FIFO_AW:0]  fifo_knl_items   ;
    wire  fifo_knl_empty   ;
    wire  fifo_knl_full    ;
    reg   fifo_knl_clr      = 1'b1;
    wire  fifo_knl_clr_done = fifo_knl_wr_ready&fifo_knl_empty&~fifo_knl_full;
    //--------------------------------------------------------------------------
    convolution_2d_fifo_sync #(.FDW(1+DATA_WIDTH)
                              ,.FAW(KERNEL_FIFO_AW))
    u_fifo_kernel (
          .rstn     ( RESET_N            )
        , .clk      ( CLK                )
        , .clr      ( fifo_knl_clr|CONV_INIT)
        , .wr_rdy   ( fifo_knl_wr_ready  )
        , .wr_vld   ( fifo_knl_wr_valid  )
        , .wr_din   ({fifo_knl_wr_last,fifo_knl_wr_data})
        , .rd_rdy   ( fifo_knl_rd_ready  )
        , .rd_vld   ( fifo_knl_rd_valid  )
        , .rd_dout  ({fifo_knl_rd_last,fifo_knl_rd_data})
        , .full     ( fifo_knl_full      )
        , .empty    ( fifo_knl_empty     )
        , .item_cnt ( fifo_knl_items     )
        , .room_cnt ( fifo_knl_rooms     )
    );
    //--------------------------------------------------------------------------
    wire                       fifo_ftu_wr_ready;
    wire                       fifo_ftu_wr_valid;
    wire  [DATA_WIDTH-1:0]     fifo_ftu_wr_data ;
    wire                       fifo_ftu_wr_last ;
    wire                       fifo_ftu_rd_ready;
    wire                       fifo_ftu_rd_valid;
    wire  [DATA_WIDTH-1:0]     fifo_ftu_rd_data ;
    wire                       fifo_ftu_rd_last ;
    wire  [FEATURE_FIFO_AW:0]  fifo_ftu_rooms   ;
    wire  [FEATURE_FIFO_AW:0]  fifo_ftu_items   ;
    wire  fifo_ftu_empty   ;
    wire  fifo_ftu_full    ;
    wire  fifo_ftu_clr      = CONV_INIT;
    wire  fifo_ftu_clr_done = fifo_ftu_wr_ready&fifo_ftu_empty&~fifo_ftu_full;
    //--------------------------------------------------------------------------
    convolution_2d_fifo_sync #(.FDW(1+DATA_WIDTH)
                              ,.FAW(FEATURE_FIFO_AW))
    u_fifo_feature (
          .rstn     ( RESET_N            )
        , .clk      ( CLK                )
        , .clr      ( fifo_ftu_clr       )
        , .wr_rdy   ( fifo_ftu_wr_ready  )
        , .wr_vld   ( fifo_ftu_wr_valid  )
        , .wr_din   ({fifo_ftu_wr_last,fifo_ftu_wr_data})
        , .rd_rdy   ( fifo_ftu_rd_ready  )
        , .rd_vld   ( fifo_ftu_rd_valid  )
        , .rd_dout  ({fifo_ftu_rd_last,fifo_ftu_rd_data})
        , .full     ( fifo_ftu_full      )
        , .empty    ( fifo_ftu_empty     )
        , .item_cnt ( fifo_ftu_items     )
        , .room_cnt ( fifo_ftu_rooms     )
    );
    //--------------------------------------------------------------------------
    wire                       fifo_chn_wr_ready;
    wire                       fifo_chn_wr_valid;
    wire  [DATA_WIDTH-1:0]     fifo_chn_wr_data ;
    wire                       fifo_chn_rd_ready;
    wire                       fifo_chn_rd_valid;
    wire  [DATA_WIDTH-1:0]     fifo_chn_rd_data ;
    wire  [CHANNEL_FIFO_AW:0]  fifo_chn_rooms   ;
    wire  [CHANNEL_FIFO_AW:0]  fifo_chn_items   ;
    wire  fifo_chn_empty   ;
    wire  fifo_chn_full    ;
    wire  fifo_chn_clr      = CONV_INIT;
    wire  fifo_chn_clr_done = fifo_chn_wr_ready&fifo_chn_empty&~fifo_chn_full;
    //--------------------------------------------------------------------------
    convolution_2d_fifo_sync #(.FDW(DATA_WIDTH)
                              ,.FAW(CHANNEL_FIFO_AW))
    u_fifo_channel (
          .rstn     ( RESET_N            )
        , .clk      ( CLK                )
        , .clr      ( fifo_chn_clr       )
        , .wr_rdy   ( fifo_chn_wr_ready  )
        , .wr_vld   ( fifo_chn_wr_valid  )
        , .wr_din   ( fifo_chn_wr_data   )
        , .rd_rdy   ( fifo_chn_rd_ready  )
        , .rd_vld   ( fifo_chn_rd_valid  )
        , .rd_dout  ( fifo_chn_rd_data   )
        , .full     ( fifo_chn_full      )
        , .empty    ( fifo_chn_empty     )
        , .item_cnt ( fifo_chn_items     )
        , .room_cnt ( fifo_chn_rooms     )
    );
    //--------------------------------------------------------------------------
    wire                      fifo_rst_wr_ready;
    wire                      fifo_rst_wr_valid;
    wire  [DATA_WIDTH-1:0]    fifo_rst_wr_data ;
    wire                      fifo_rst_wr_last ;
    wire                      fifo_rst_rd_ready;
    wire                      fifo_rst_rd_valid;
    wire  [DATA_WIDTH-1:0]    fifo_rst_rd_data ;
    wire                      fifo_rst_rd_last ;
    wire  [RESULT_FIFO_AW:0]  fifo_rst_rooms   ;
    wire  [RESULT_FIFO_AW:0]  fifo_rst_items   ;
    wire  fifo_rst_empty   ;
    wire  fifo_rst_full    ;
    wire  fifo_rst_clr      = CONV_INIT;
    wire  fifo_rst_clr_done = fifo_rst_wr_ready&fifo_rst_empty&~fifo_rst_full;
    //--------------------------------------------------------------------------
    convolution_2d_fifo_sync #(.FDW(1+DATA_WIDTH)
                              ,.FAW(RESULT_FIFO_AW))
    u_fifo_result  (
          .rstn     ( RESET_N            )
        , .clk      ( CLK                )
        , .clr      ( fifo_rst_clr       )
        , .wr_rdy   ( fifo_rst_wr_ready  )
        , .wr_vld   ( fifo_rst_wr_valid  )
        , .wr_din   ({fifo_rst_wr_last,fifo_rst_wr_data})
        , .rd_rdy   ( fifo_rst_rd_ready  )
        , .rd_vld   ( fifo_rst_rd_valid  )
        , .rd_dout  ({fifo_rst_rd_last,fifo_rst_rd_data})
        , .full     ( fifo_rst_full      )
        , .empty    ( fifo_rst_empty     )
        , .item_cnt ( fifo_rst_items     )
        , .room_cnt ( fifo_rst_rooms     )
    );
    //--------------------------------------------------------------------------
    // dealing with kernle mux/fifo
    assign IN_KNL_ROOMS = fifo_knl_rooms;
    always @ ( * ) begin
    if ((RESET_N==1'b0)||(CONV_INIT==1'b1)) begin
        IN_KNL_READY      <= 1'b0;
        fifo_knl_rd_ready <= 1'b0;
        fifo_knl_wr_valid <= 1'b0;
        fifo_knl_wr_data  <=  'h0;
        fifo_knl_wr_last  <= 1'b0;
        fifo_knl_clr      <= 1'b1;
        mac_knl_valid     <= 1'b0;
        mac_knl_data      <= fifo_knl_rd_data;
        mac_knl_last      <= fifo_knl_rd_last;
    end else begin
        case (IN_KNL_MODE)
        2'b01: begin // fill
            IN_KNL_READY      <= fifo_knl_wr_ready;
            fifo_knl_rd_ready <= 1'b0;
            fifo_knl_wr_valid <= IN_KNL_VALID;
            fifo_knl_wr_data  <= IN_KNL_DATA ;
            fifo_knl_wr_last  <= IN_KNL_LAST ;
            fifo_knl_clr      <= 1'b0;
            mac_knl_valid     <= 1'b0;
            mac_knl_data      <= fifo_knl_rd_data;
            mac_knl_last      <= fifo_knl_rd_last;
            end
        2'b11: begin // read-out-rotation
            IN_KNL_READY      <= 1'b0;
            fifo_knl_rd_ready <= mac_knl_ready    ;
            fifo_knl_wr_valid <= fifo_knl_rd_valid&fifo_knl_rd_ready;
            fifo_knl_wr_data  <= fifo_knl_rd_data ;
            fifo_knl_wr_last  <= fifo_knl_rd_last ;
            fifo_knl_clr      <= 1'b0;
            mac_knl_valid     <= fifo_knl_rd_valid;
            mac_knl_data      <= fifo_knl_rd_data ;
            mac_knl_last      <= fifo_knl_rd_last ;
            end
        2'b10: begin // read-out (2'b10)
            IN_KNL_READY      <= fifo_knl_wr_ready;
            fifo_knl_rd_ready <= mac_knl_ready    ;
            fifo_knl_wr_valid <= IN_KNL_VALID;
            fifo_knl_wr_data  <= IN_KNL_DATA ;
            fifo_knl_wr_last  <= IN_KNL_LAST ;
            fifo_knl_clr      <= 1'b0;
            mac_knl_valid     <= fifo_knl_rd_valid;
            mac_knl_data      <= fifo_knl_rd_data ;
            mac_knl_last      <= fifo_knl_rd_last ;
            end
        2'b00: begin // disabled
            IN_KNL_READY      <= 1'b0;
            fifo_knl_rd_ready <= 1'b0;
            fifo_knl_wr_valid <= 1'b0;
            fifo_knl_wr_data  <=  'h0;
            fifo_knl_wr_last  <= 1'b0;
            fifo_knl_clr      <= 1'b1;
            mac_knl_valid     <= 1'b0;
            mac_knl_data      <= fifo_knl_rd_data;
            mac_knl_last      <= fifo_knl_rd_last;
            end
        endcase
    end // if
    end // always
    //--------------------------------------------------------------------------
    // dealing with feature fifo
    assign  IN_FTU_READY      = fifo_ftu_wr_ready;
    assign  fifo_ftu_wr_valid = IN_FTU_VALID     ;
    assign  fifo_ftu_wr_data  = IN_FTU_DATA      ;
    assign  fifo_ftu_wr_last  = IN_FTU_LAST      ;
    assign  fifo_ftu_rd_ready = mac_ftu_ready    ;
    assign  mac_ftu_valid     = fifo_ftu_rd_valid;
    assign  mac_ftu_data      = fifo_ftu_rd_data ;
    assign  mac_ftu_last      = fifo_ftu_rd_last ;
    assign  IN_FTU_ROOMS      = fifo_ftu_rooms   ;
    //--------------------------------------------------------------------------
    // dealing with channel fifo
    assign  IN_CHN_READY      = fifo_chn_wr_ready;
    assign  fifo_chn_wr_valid = IN_CHN_VALID     ;
    assign  fifo_chn_wr_data  = IN_CHN_DATA      ;
    assign  fifo_chn_rd_ready = (IN_CHN_MODE) ? add_chn_ready     : 1'b1;
    assign  add_chn_valid     = (IN_CHN_MODE) ? fifo_chn_rd_valid : 1'b1;
    assign  add_chn_data      = (IN_CHN_MODE) ? fifo_chn_rd_data  :  'h0;
    assign  add_chn_last      = (IN_CHN_MODE) ? fifo_chn_rd_valid : 1'b1;
    assign  IN_CHN_ROOMS      = fifo_chn_rooms   ;
    //--------------------------------------------------------------------------
    // dealing with result fifo
    assign  activ_out_ready   = fifo_rst_wr_ready;
    assign  fifo_rst_wr_valid = activ_out_valid  ;
    assign  fifo_rst_wr_data  = activ_out_data   ;
    assign  fifo_rst_wr_last  = activ_out_last   ;
    assign  fifo_rst_rd_ready = OUT_RST_READY    ;
    assign  OUT_RST_VALID     = fifo_rst_rd_valid;
    assign  OUT_RST_DATA      = fifo_rst_rd_data ;
    assign  OUT_RST_LAST      = fifo_rst_rd_last ;
    assign  OUT_RST_ITEMS     = fifo_rst_items   ;
    //--------------------------------------------------------------------------
    // a pulse with certain cycles
    assign  CONV_READY = mac_ready&
                         fifo_knl_clr_done&
                         fifo_ftu_clr_done&
                         fifo_chn_clr_done&
                         fifo_rst_clr_done;
    //--------------------------------------------------------------------------
    // profile_mac_num         : num of MAC operations
    // profile_mac_overflow    : num of overflow while MAC operations
    // profile_channel_overflow: num of overflow while adding channels
    // profile_bias_overflow   : num of overflow while adding bias
    // profile_activ_overflow  : num of overflow while activation
    always @ (posedge CLK or negedge RESET_N) begin
    if (RESET_N==1'b0) begin
        profile_mac_num          <='h0;
        profile_mac_overflow     <='h0;
        profile_channel_overflow <='h0;
        profile_bias_overflow    <='h0;
        profile_activ_overflow   <='h0;
    end else if (profile_init==1'b1) begin
        profile_mac_num          <='h0;
        profile_mac_overflow     <='h0;
        profile_channel_overflow <='h0;
        profile_bias_overflow    <='h0;
        profile_activ_overflow   <='h0;
    end else begin
        if (mac_out_valid&mac_out_ready) begin
            profile_mac_num <= profile_mac_num + 1;
        end
        if (mac_out_overflow&mac_out_valid&mac_out_ready&mac_out_last) begin
            profile_mac_overflow <= profile_mac_overflow + 1;
        end
        if (add_out_overflow&add_out_valid&add_out_ready&add_out_last) begin
            profile_channel_overflow <= profile_channel_overflow + 1;
        end
        if (bia_out_overflow&bia_out_valid&bia_out_ready&bia_out_last) begin
            profile_bias_overflow <= profile_bias_overflow + 1;
        end
        if (activ_out_overflow&activ_out_valid&activ_out_ready&activ_out_last) begin
            profile_activ_overflow <= profile_activ_overflow + 1;
        end
    end // if
    end // always
    //--------------------------------------------------------------------------
endmodule

//------------------------------------------------------------------------------
// Revision history
//
// 2021.06.10: Started by Ando Ki (andoki@gmail.com)
//------------------------------------------------------------------------------
