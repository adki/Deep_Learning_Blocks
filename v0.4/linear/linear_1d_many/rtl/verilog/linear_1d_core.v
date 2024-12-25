//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All right reserved.
//------------------------------------------------------------------------------
// VERSION: 2021.06.10.
//------------------------------------------------------------------------------
// Linear 1D Core
//------------------------------------------------------------------------------
//              +------------------------------------------------+
//              | linear_1d_core                                 |
//              | +------------------------------------+         |
//              | |  +---    tree_mac_bias             |         |
// input[]  ========>|MUL\                             |         |
//              | |  |   |   +----+   +-----+          |         |
//              | |  |   |==>|ADD |   |A    |          |         |
// weight[] ========>|   /   |TREE|   |c    |          |         |
//              | |  +---    |    |   |c    |          |         |
//            ..........     |    |==>|u    |          |         |
//              | |  +---    |    |   |m    |          |         |
// input[]  ========>|MUL\   |    |   |u    |   +----+ |  +----+ | +--+
//              | |  |   |==>|    |   |l    |==>|ADD | |  |ACT | | |P |
//              | |  |   |   +----+   +-----+   |    |===>|    |==>|O |====>result
// weight[] ========>|   /                      |    | |  |    | | |P |
//              | |  +---                       |    | |  |    | | |  |
//              | |                             |    | |  +----+ | +--+
// bias[]   ===================================>|    | |         |
//              | |                             +----+ |         |
//              | +------------------------------------+         |
//              +------------------------------------------------+
//------------------------------------------------------------------------------
`include "linear_1d_activation.v"

module linear_1d_core
     #(parameter AXI_WIDTH_DA    =32
               , AXI_WIDTH_DS    =(AXI_WIDTH_DA/8)
               , DATA_TYPE="INTEGER" // "INTEGER", "FLOATING_POINT", "FIXED_POINT"
               , DATA_WIDTH=32
               , DATA_BYTES=(DATA_WIDTH/8)
               `ifdef DATA_FIXED_POINT
               , DATA_WIDTH_Q=(DATA_WIDTH/2) // fractional bits
               `endif
               , INPUT_FIFO_DEPTH =32
               , WEIGHT_FIFO_DEPTH=32
               , RESULT_FIFO_DEPTH=32
               , INPUT_FIFO_AW    =$clog2(INPUT_FIFO_DEPTH )
               , WEIGHT_FIFO_AW   =$clog2(WEIGHT_FIFO_DEPTH)
               , RESULT_FIFO_AW   =$clog2(RESULT_FIFO_DEPTH )
               , PROFILE_CNT_WIDTH    =32
               , ACTIV_FUNC_BYPASS    =4'h0
               , ACTIV_FUNC_RELU      =4'h1
               , ACTIV_FUNC_LEAKY_RELU=4'h2
               , ACTIV_FUNC_SIGMOID   =4'h3
               , ACTIV_FUNC_TANH      =4'h4
               )
(
      input    wire                        RESET_N
    , input    wire                        CLK
    // for bias or previous-result
    , output  wire                         IN_BIAS_READY
    , input   wire                         IN_BIAS_VALID
    , input   wire  [DATA_WIDTH-1:0]       IN_BIAS_DATA // for only one data item
    , input   wire                         IN_BIAS_LAST // indicates end of bias
    // for input-feature
    , output  wire                         IN_INPUT_READY
    , input   wire                         IN_INPUT_VALID
    , input   wire  [AXI_WIDTH_DA-1:0]     IN_INPUT_DATA // justified
    , input   wire  [AXI_WIDTH_DS-1:0]     IN_INPUT_STRB // justified
    , input   wire                         IN_INPUT_LAST // indicates end of line
    , input   wire                         IN_INPUT_EMPTY
    // for weight
    , output  wire                         IN_WEIGHT_READY
    , input   wire                         IN_WEIGHT_VALID
    , input   wire  [AXI_WIDTH_DA-1:0]     IN_WEIGHT_DATA // justified
    , input   wire  [AXI_WIDTH_DS-1:0]     IN_WEIGHT_STRB // justified
    , input   wire                         IN_WEIGHT_LAST // indicates end of line
    , input   wire                         IN_WEIGHT_EMPTY
    // resultant D=D+A*B+C
    , input   wire                         OUT_RST_READY
    , output  wire                         OUT_RST_VALID // it should be interpreted along with OUT_RST_LAST
    , output  wire  [DATA_WIDTH-1:0]       OUT_RST_DATA // justified
    , output  wire  [DATA_BYTES-1:0]       OUT_RST_STRB // justified
    , output  wire                         OUT_RST_LAST // indicates effective mac result
    //
    , input   wire  [ 3:0]                 ACTIV_FUNC
                                           // if not use, set 0 for linear bypass
    , input   wire  [DATA_WIDTH-1:0]       ACTIV_PARAM
    //
    , input   wire                         linear_init
    , output  wire                         linear_ready
    //
    , input   wire                           profile_init
    , output  wire  [PROFILE_CNT_WIDTH-1:0]  profile_mac_num
    , output  wire  [PROFILE_CNT_WIDTH-1:0]  profile_mac_overflow
    , output  wire  [PROFILE_CNT_WIDTH-1:0]  profile_bias_overflow
    , output  wire  [PROFILE_CNT_WIDTH-1:0]  profile_activ_overflow
);
    //--------------------------------------------------------------------------
    assign profile_mac_num='h0;
    assign profile_mac_overflow='h0;
    assign profile_bias_overflow='h0;
    assign profile_activ_overflow='h0;
    //--------------------------------------------------------------------------
    localparam NUM_BLOCKS=AXI_WIDTH_DA/DATA_WIDTH;
    // synthesis translate_off
    initial begin
        if (NUM_BLOCKS!=(1<<$clog2(NUM_BLOCKS)))
            $display("%m ERROR not power of 2: %d.", NUM_BLOCKS);
    end
    // synthesis translate_on
    //--------------------------------------------------------------------------
    assign linear_ready = ~linear_init;
    //--------------------------------------------------------------------------
    wire                    in_ready ;
    wire                    in_valid =IN_INPUT_VALID&IN_WEIGHT_VALID;
    wire [AXI_WIDTH_DA-1:0] in_data_A=IN_INPUT_DATA;
    wire [AXI_WIDTH_DS-1:0] in_strb_A=IN_INPUT_STRB;
    wire [AXI_WIDTH_DA-1:0] in_data_B=IN_WEIGHT_DATA;
    wire [AXI_WIDTH_DS-1:0] in_strb_B=IN_WEIGHT_STRB;
    wire                    in_last  =IN_INPUT_LAST&IN_WEIGHT_LAST;
    assign IN_INPUT_READY = in_ready&IN_WEIGHT_VALID;
    assign IN_WEIGHT_READY= in_ready&IN_INPUT_VALID ;
    //--------------------------------------------------------------------------
    wire                  out_ready   ;
    wire                  out_valid   ;
    wire [DATA_WIDTH-1:0] out_data    ;
    wire [DATA_BYTES-1:0] out_strb    ;
    wire                  out_last    ;
    wire                  out_overflow;
    //--------------------------------------------------------------------------
    tree_mac_bias #(.AXI_WIDTH_DA(AXI_WIDTH_DA)
                   ,.DATA_TYPE   (DATA_TYPE   )
                   ,.DATA_WIDTH  (DATA_WIDTH  )
                   `ifdef DATA_FIXED_POINT
                   ,.DATA_WIDTH_Q(DATA_WIDTH_Q) // fractional bits
                   `endif
                   ,.ZEROFY(1))
    u_tree_mac_bias (
          .reset_n      ( RESET_N       )
        , .clk          ( CLK           )
        , .bias_ready   ( IN_BIAS_READY )
        , .bias_valid   ( IN_BIAS_VALID )
        , .bias_data    ( IN_BIAS_DATA  )
        , .in_ready     ( in_ready      )
        , .in_valid     ( in_valid      )
        , .in_data_A    ( in_data_A     )
        , .in_strb_A    ( in_strb_A     )
        , .in_data_B    ( in_data_B     )
        , .in_strb_B    ( in_strb_B     )
        , .in_last      ( in_last       )
        , .out_ready    ( out_ready     )
        , .out_valid    ( out_valid     )
        , .out_data     ( out_data      )
        , .out_strb     ( out_strb      )
        , .out_last     ( out_last      )
        , .out_overflow ( out_overflow  )
    );
    //--------------------------------------------------------------------------
    linear_1d_activation #(.DATA_TYPE (DATA_TYPE )
                          ,.DATA_WIDTH(DATA_WIDTH)
                          `ifdef DATA_FIXED_POINT
                          ,.DATA_WIDTH_Q(DATA_WIDTH_Q)
                          `endif
                          ,.USER_WIDTH(DATA_BYTES)
                          ,.ACTIV_FUNC_BYPASS    ( ACTIV_FUNC_BYPASS     )
                          ,.ACTIV_FUNC_RELU      ( ACTIV_FUNC_RELU       )
                          ,.ACTIV_FUNC_LEAKY_RELU( ACTIV_FUNC_LEAKY_RELU )
                          ,.ACTIV_FUNC_SIGMOID   ( ACTIV_FUNC_SIGMOID    )
                          ,.ACTIV_FUNC_TANH      ( ACTIV_FUNC_TANH       )
                          )
    u_activation (
        .RESET_N     ( RESET_N       )
      , .CLK         ( CLK           )
      , .ACTIV_FUNC  ( ACTIV_FUNC    )
      , .ACTIV_PARAM ( ACTIV_PARAM   )
      , .IN_READY    ( out_ready     )
      , .IN_VALID    ( out_valid&out_last)
      , .IN_DATA     ( out_data      )
      , .IN_USER     ( out_strb      )
      , .IN_LAST     ( out_last      )
      , .OUT_READY   ( OUT_RST_READY )
      , .OUT_VALID   ( OUT_RST_VALID )
      , .OUT_DATA    ( OUT_RST_DATA  )
      , .OUT_USER    ( OUT_RST_STRB  )
      , .OUT_LAST    ( OUT_RST_LAST  )
      , .OUT_OVERFLOW(               )
    );
    //--------------------------------------------------------------------------
endmodule
//------------------------------------------------------------------------------
// Revision history
//
// 2021.06.10: Started by Ando Ki (andoki@gmail.com)
//------------------------------------------------------------------------------
