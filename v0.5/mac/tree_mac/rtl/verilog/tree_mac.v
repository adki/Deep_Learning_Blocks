//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All right reserved.
//------------------------------------------------------------------------------
// VERSION: 2021.06.10.
//------------------------------------------------------------------------------
// mac_tree_bias
// tree_adder_accumulator_bias
// tree_adder
//------------------------------------------------------------------------------
`ifndef AXI_WIDTH_DA
`define AXI_WIDTH_DA   32
`endif
`ifndef DATA_WIDTH
`define DATA_WIDTH     32
`endif
`ifndef DATA_TYPE
`define DATA_TYPE "INTEGER"
`endif

`ifdef __ICARUS__
`define NET_DELAY
`else
`ifdef SIM
`define NET_DELAY  #(1)
`else
`define NET_DELAY
`endif
`endif

//------------------------------------------------------------------------------
//                  tree_adder_accumulator_bias
//                  +-----------------------------+
//         +-----+  | +-----+   +-----+   +-----+ |
// wider   |     |  | |tree |   |accu |   |adder| |
// data ==>|mul  |===>|adder|==>|mula |==>|     |===>result[DATA_WIDTH]
// bus     |     |  | |     |   |tor  |   |     | |  strbe [DATA_BYTES]
//         +-----+  | +-----+   +-----+   +-----+ |
//                  +-----------------------||----+
// bias =====================================
//------------------------------------------------------------------------------
//                       0                             0
//    +----+----+----+----+         +----+----+----+----+
//    | A3 | A2 | A1 | A0 |         | B3 | B2 | B1 | B0 |
//    +----+----+----+----+         +----+----+----+----+
//
//         +----+----+----+----+----+----+----+----+
//         | B3 | A3 | B2 | A2 | B1 | A1 | B0 | A0 |
//         +----+----+----+----+----+----+----+----+
// --        ||   ||   ||   ||   ||   ||   ||   ||
//  |      +---------+---------+---------+---------+
//  |       \  MUL  / \  MUL  / \  MUL  / \  MUL  /
//  |        +-----+   +-----+   +-----+   +-----+
// --           ||       ||         ||       ||
//  |          +-----------+       +-----------+
//  |           \   ADD   /         \   ADD   /
//  |            +-------+           +-------+
//  |                ||                  ||
//  |               +----------------------+
//  |                 \                  /
//  |                   \     ADD      /
//  |                     \          /
//  |                      +--------+
// --                          ||
//  |                      +--------+
//  |                      |  ACC   |
//  |                      +--------+
// --                          ||
//  |                      +--------+
//  |  bias ==============>|  ADD   |
//  |                      +--------+
// --                          ||
//------------------------------------------------------------------------------
// New round starts after 'in_last'.
// 
// 'bias_valid/data' should be given (i.e., 0-value) even thoug there is not bias.
// Bias will be added when 'in_last' is driven.
module tree_mac_bias
     #(parameter AXI_WIDTH_DA=`AXI_WIDTH_DA
               , AXI_WIDTH_DS=(AXI_WIDTH_DA/8)
               , DATA_TYPE   ="INTEGER"
               , DATA_WIDTH  =`DATA_WIDTH
               , DATA_BYTES  =(DATA_WIDTH/8)
               `ifdef DATA_FIXED_POINT
               , DATA_WIDTH_Q=(DATA_WIDTH/2) // fractional bits
               `endif
               , ZEROFY=1 // make byte zero if strob is not 1
               )
(
      input  wire                    reset_n
    , input  wire                    clk
    , output wire                    bias_ready // should be driven 1 if not used
    , input  wire                    bias_valid // should be driven 1 if not used
    , input  wire [DATA_WIDTH-1:0]   bias_data // should be 0 if not used
    , output wire                    in_ready
    , input  wire                    in_valid
    , input  wire [AXI_WIDTH_DA-1:0] in_data_A // should be justified
    , input  wire [AXI_WIDTH_DS-1:0] in_strb_A // should be justified
    , input  wire [AXI_WIDTH_DA-1:0] in_data_B // should be justified
    , input  wire [AXI_WIDTH_DS-1:0] in_strb_B // not used
    , input  wire                    in_last
    , input  wire                    out_ready
    , output wire                    out_valid
    , output wire [DATA_WIDTH-1:0]   out_data
    , output wire [DATA_BYTES-1:0]   out_strb
    , output wire                    out_last
    , output wire                    out_overflow
);
    //--------------------------------------------------------------------------
    localparam NUM=AXI_WIDTH_DA/DATA_WIDTH;
    //--------------------------------------------------------------------------
    wire [NUM-1:0]            `NET_DELAY mul_in_ready_mul;
    wire                      `NET_DELAY mul_in_valid    =in_valid ;
    wire [AXI_WIDTH_DA-1:0]   `NET_DELAY mul_in_data_A   ;
    wire [AXI_WIDTH_DA-1:0]   `NET_DELAY mul_in_data_B   ;
    wire [AXI_WIDTH_DS-1:0]   `NET_DELAY mul_in_strb     =in_strb_A;
    wire                      `NET_DELAY mul_in_last     =in_last  ;
    wire                      `NET_DELAY mul_out_ready   ;
    wire [NUM-1:0]            `NET_DELAY mul_out_valid   ;
    wire [NUM*DATA_WIDTH-1:0] `NET_DELAY mul_out_data    ;
    wire [NUM*DATA_BYTES-1:0] `NET_DELAY mul_out_strb    ;
    wire [NUM-1:0]            `NET_DELAY mul_out_last    ;
    wire [NUM-1:0]            `NET_DELAY mul_out_overflow;
    //--------------------------------------------------------------------------
    assign in_ready = &mul_in_ready_mul;
    //--------------------------------------------------------------------------
    generate
    genvar ida;
    if (ZEROFY[0]==1'b1) begin : BLK_ZEROFY
        for (ida=0; ida<AXI_WIDTH_DS; ida=ida+1) begin
            assign mul_in_data_A[ida*8+:8] = (in_strb_A[ida]) ? in_data_A[ida*8+:8] : 8'h0;
            assign mul_in_data_B[ida*8+:8] = (in_strb_B[ida]) ? in_data_B[ida*8+:8] : 8'h0;
        end
    end else begin
        assign mul_in_data_A=in_data_A;
        assign mul_in_data_B=in_data_B;
    end
    endgenerate
    //--------------------------------------------------------------------------
    generate
    genvar idx;
    for (idx=0; idx<NUM; idx=idx+1) begin : BLK_MUL
        mac_core_multiplier #(.N(DATA_WIDTH),.B(DATA_BYTES))
        u_multiplier (
              .reset_n      ( reset_n              )
            , .clk          ( clk                  )
            , .in_ready     ( mul_in_ready_mul[idx])
            , .in_valid     ( mul_in_valid         )
            , .in_data_A    ( mul_in_data_A   [idx*DATA_WIDTH+:DATA_WIDTH])
            , .in_data_B    ( mul_in_data_B   [idx*DATA_WIDTH+:DATA_WIDTH])
            , .in_user      ( mul_in_strb     [idx*DATA_BYTES+:DATA_BYTES])
            , .in_last      ( mul_in_last          )
            , .out_ready    ( mul_out_ready        )
            , .out_valid    ( mul_out_valid   [idx])
            , .out_data     ( mul_out_data    [idx*DATA_WIDTH+:DATA_WIDTH])
            , .out_user     ( mul_out_strb    [idx*DATA_BYTES+:DATA_BYTES])
            , .out_last     ( mul_out_last    [idx])
            , .out_overflow ( mul_out_overflow[idx])
        );
    end // for
    endgenerate
    //--------------------------------------------------------------------------
    // synthesis translate_off
    always @ ( posedge clk ) begin
        if (in_valid&in_ready) begin
            if (in_strb_A!==in_strb_B)
                $display("%0t %m ERROR strobe mis-match.", $time);
        end
    end
    // synthesis translate_on
    //--------------------------------------------------------------------------
    generate
    if (NUM>1) begin : BLK_TREE_MANY
        tree_adder_accumulator_bias #(.AXI_WIDTH_DA (NUM*DATA_WIDTH/2)
                                     ,.AXI_WIDTH_DS (NUM*DATA_WIDTH/8/2)
                                     ,.DATA_TYPE    (DATA_TYPE     )
                                     ,.DATA_WIDTH   (DATA_WIDTH    )
                                     ,.DATA_BYTES   (DATA_BYTES    )
                                     `ifdef DATA_FIXED_POINT
                                     ,.DATA_WIDTH_Q (DATA_WIDTH_Q  ) // fractional bits
                                     `endif
                                     ,.ZEROFY(0)
                                     )
        u_tree_adder_accumulator_bias (
              .reset_n      ( reset_n      )
            , .clk          ( clk          )
            , .bias_ready   ( bias_ready   )
            , .bias_valid   ( bias_valid   )
            , .bias_data    ( bias_data    )
            , .in_ready     ( mul_out_ready)
            , .in_valid     (&mul_out_valid)
            , .in_last      (&mul_out_last )
            , .in_data_A    ( mul_out_data [0+:NUM*DATA_WIDTH/2])
            , .in_strb_A    ( mul_out_strb [0+:NUM*DATA_BYTES/2])
            , .in_data_B    ( mul_out_data [NUM*DATA_WIDTH/2+:NUM*DATA_WIDTH/2])
            , .in_strb_B    ( mul_out_strb [NUM*DATA_BYTES/2+:NUM*DATA_BYTES/2])
            , .out_ready    ( out_ready    )
            , .out_valid    ( out_valid    )
            , .out_last     ( out_last     )
            , .out_data     ( out_data     )
            , .out_strb     ( out_strb     )
            , .out_overflow ( out_overflow )
        );
    end else begin : BLK_TREE_ONE
        //----------------------------------------------------------------------
        // for the case NUM==1, i.e., AXI_WIDTH_DA==DATA_WIDTH
        wire                   `NET_DELAY acc_out_ready   ;
        wire                   `NET_DELAY acc_out_valid   ;
        wire  [DATA_WIDTH-1:0] `NET_DELAY acc_out_data    ;
        wire  [DATA_BYTES-1:0] `NET_DELAY acc_out_strb    ;
        wire                   `NET_DELAY acc_out_last    ;
        wire                   `NET_DELAY acc_out_overflow;
        mac_core_accumulator #(.N(DATA_WIDTH),.B(DATA_BYTES))
        u_accumulator (
              .clk          ( clk              )
            , .reset_n      ( reset_n          )
            , .in_ready     ( mul_out_ready    )
            , .in_valid     ( mul_out_valid    )
            , .in_data      ( mul_out_data     )
            , .in_user      ( mul_out_strb     )
            , .in_last      ( mul_out_last     )
            , .out_ready    ( acc_out_ready    )
            , .out_valid    ( acc_out_valid    )
            , .out_data     ( acc_out_data     )
            , .out_user     ( acc_out_strb     )
            , .out_last     ( acc_out_last     )
            , .out_overflow ( acc_out_overflow )
        );
        //----------------------------------------------------------------------
        // make a room for bias
        wire                 reg_bias_ready;
        reg                  reg_bias_valid=1'b0;
        reg [DATA_WIDTH-1:0] reg_bias_data={DATA_WIDTH{1'b0}};
        assign bias_ready = ~reg_bias_valid|reg_bias_ready;
        always @ (posedge clk) begin
        if (reset_n==1'b0) begin
            reg_bias_valid <= 1'b0;
            reg_bias_data  <= {DATA_WIDTH{1'b0}};
        end else begin
            if (reg_bias_valid==1'b0) begin
                reg_bias_valid <= bias_valid;
                reg_bias_data  <= bias_data ;
            end else begin
                if (reg_bias_ready==1'b1) begin
                    reg_bias_valid <= bias_valid;
                    reg_bias_data  <= bias_data ;
                end
            end
        end // if
        end // always
        //----------------------------------------------------------------------
        wire                  `NET_DELAY tmp_ready ;
        wire                  `NET_DELAY tmp_valid ;
        wire                  `NET_DELAY tmp_last  =acc_out_last ;
        wire [DATA_WIDTH-1:0] `NET_DELAY tmp_data_A=acc_out_data ;
        wire [DATA_WIDTH-1:0] `NET_DELAY tmp_data_B;
        wire [DATA_BYTES-1:0] `NET_DELAY tmp_strb   =acc_out_strb ;
        assign acc_out_ready = (tmp_last) ? (tmp_ready&reg_bias_valid) : tmp_ready;
        assign tmp_valid     = (tmp_last) ? (reg_bias_valid&acc_out_valid) : acc_out_valid;
        assign tmp_data_B    = (tmp_last) ? reg_bias_data : {DATA_WIDTH{1'b0}};
        assign reg_bias_ready= tmp_last & tmp_ready & acc_out_valid;
        //----------------------------------------------------------------------
        mac_core_adder #(.N(DATA_WIDTH),.B(DATA_BYTES))
        u_adder (
              .reset_n      ( reset_n      )
            , .clk          ( clk          )
            , .in_ready     ( tmp_ready    ) // output
            , .in_valid     ( tmp_valid    )
            , .in_last      ( tmp_last     )
            , .in_user      ( tmp_strb     )
            , .in_data_A    ( tmp_data_A   )
            , .in_data_B    ( tmp_data_B   )
            , .out_ready    ( out_ready    ) // input
            , .out_valid    ( out_valid    )
            , .out_last     ( out_last     )
            , .out_data     ( out_data     )
            , .out_user     ( out_strb     )
            , .out_overflow ( out_overflow )
        );
        //----------------------------------------------------------------------
    end
    endgenerate
    //--------------------------------------------------------------------------
`ifdef DEBUG
`ifndef __ICARUS__
    // synthesis translate_off
    shortreal fin_data_A0, fin_data_B0;
    shortreal fin_data_A1, fin_data_B1;
    shortreal fin_data_A2, fin_data_B2;
    shortreal fin_data_A3, fin_data_B3;
    shortreal fout_data;
    always @ ( * ) begin
        fout_data = $bitstoshortreal(out_data);
        if ((AXI_WIDTH_DA/DATA_WIDTH)>=1) begin
            fin_data_A0 = $bitstoshortreal(in_data_A[0*DATA_WIDTH+:DATA_WIDTH]);
            fin_data_B0 = $bitstoshortreal(in_data_B[0*DATA_WIDTH+:DATA_WIDTH]);
        end
        if ((AXI_WIDTH_DA/DATA_WIDTH)>=2) begin
            fin_data_A1 = $bitstoshortreal(in_data_A[1*DATA_WIDTH+:DATA_WIDTH]);
            fin_data_B1 = $bitstoshortreal(in_data_B[1*DATA_WIDTH+:DATA_WIDTH]);
        end
        if ((AXI_WIDTH_DA/DATA_WIDTH)>=3) begin
            fin_data_A2 = $bitstoshortreal(in_data_A[2*DATA_WIDTH+:DATA_WIDTH]);
            fin_data_B2 = $bitstoshortreal(in_data_B[2*DATA_WIDTH+:DATA_WIDTH]);
        end
        if ((AXI_WIDTH_DA/DATA_WIDTH)>=4) begin
            fin_data_A3 = $bitstoshortreal(in_data_A[3*DATA_WIDTH+:DATA_WIDTH]);
            fin_data_B3 = $bitstoshortreal(in_data_B[3*DATA_WIDTH+:DATA_WIDTH]);
        end
    end
    // synthesis translate_on
`endif
`endif
    //--------------------------------------------------------------------------
endmodule

//------------------------------------------------------------------------------
//         +-----+   +-----+   +-----+
// wider   |tree |   |accu |   |adder|
// data ==>|adder|==>|mula |==>|     |===>result[DATA_WIDTH]
// bus     |     |   |tor  |   |     |    strbe [DATA_BYTES]
//         +-----+   +-----+   +-----+
//                               ||
// bias ==========================
//------------------------------------------------------------------------------
// New round starts after 'in_last'.
module tree_adder_accumulator_bias
     #(parameter AXI_WIDTH_DA=`AXI_WIDTH_DA
               , AXI_WIDTH_DS=(AXI_WIDTH_DA/8)
               , DATA_TYPE   ="INTEGER"
               , DATA_WIDTH=`DATA_WIDTH
               , DATA_BYTES=(DATA_WIDTH/8)
               `ifdef DATA_FIXED_POINT
               , DATA_WIDTH_Q=(DATA_WIDTH/2) // fractional bits
               `endif
               , ZEROFY=1 // make byte zero if strob is not 1
               )
(
      input  wire                    reset_n
    , input  wire                    clk
    , output wire                    bias_ready // should be driven 1 if not used
    , input  wire                    bias_valid // should be driven 1 if not used
    , input  wire [DATA_WIDTH-1:0]   bias_data // should be 0 if not used
    , output wire                    in_ready
    , input  wire                    in_valid
    , input  wire [AXI_WIDTH_DA-1:0] in_data_A // should be justified
    , input  wire [AXI_WIDTH_DS-1:0] in_strb_A // should be justified
    , input  wire [AXI_WIDTH_DA-1:0] in_data_B // should be justified
    , input  wire [AXI_WIDTH_DS-1:0] in_strb_B // not used
    , input  wire                    in_last
    , input  wire                    out_ready
    , output wire                    out_valid
    , output wire [DATA_WIDTH-1:0]   out_data
    , output wire [DATA_BYTES-1:0]   out_strb
    , output wire                    out_last
    , output wire                    out_overflow
);
    //--------------------------------------------------------------------------
    wire                    tree_in_ready ;
    wire                    tree_in_valid =in_valid;
    wire                    tree_in_last  =in_last;
    wire [AXI_WIDTH_DA-1:0] tree_in_data_A;
    wire [AXI_WIDTH_DA-1:0] tree_in_data_B;
    wire [AXI_WIDTH_DS-1:0] tree_in_strb_A=in_strb_A;
    wire [AXI_WIDTH_DS-1:0] tree_in_strb_B=in_strb_B;
    assign in_ready = tree_in_ready;
    //--------------------------------------------------------------------------
    generate
    genvar ida;
    if (ZEROFY[0]==1'b1) begin : BLK_ZEROFY
        for (ida=0; ida<AXI_WIDTH_DS; ida=ida+1) begin
            assign tree_in_data_A[ida*8+:8] = (in_strb_A[ida]) ? in_data_A[ida*8+:8] : 8'h0;
            assign tree_in_data_B[ida*8+:8] = (in_strb_B[ida]) ? in_data_B[ida*8+:8] : 8'h0;
        end
    end else begin
        assign tree_in_data_A=in_data_A;
        assign tree_in_data_B=in_data_B;
    end
    endgenerate
    //--------------------------------------------------------------------------
    wire                  `NET_DELAY acc_out_ready;
    wire                  `NET_DELAY acc_out_valid;
    wire                  `NET_DELAY acc_out_last;
    wire [DATA_WIDTH-1:0] `NET_DELAY acc_out_data;
    wire [DATA_BYTES-1:0] `NET_DELAY acc_out_strb;
    wire                  `NET_DELAY acc_out_overflow;
    //--------------------------------------------------------------------------
    tree_adder_accumulator #(.AXI_WIDTH_DA(AXI_WIDTH_DA)
                            ,.DATA_TYPE   (DATA_TYPE   )
                            ,.DATA_WIDTH  (DATA_WIDTH  )
                            `ifdef DATA_FIXED_POINT
                            ,.DATA_WIDTH_Q=(DATA_WIDTH_Q) // fractional bits
                            `endif
                            ,.ZEROFY(0) // make byte zero if strob is not 1
                            )
    u_tree_adder_accumulator (
          .reset_n      ( reset_n          )
        , .clk          ( clk              )
        , .in_ready     ( tree_in_ready    )
        , .in_valid     ( tree_in_valid    )
        , .in_last      ( tree_in_last     )
        , .in_data_A    ( tree_in_data_A   )
        , .in_strb_A    ( tree_in_strb_A   )
        , .in_data_B    ( tree_in_data_B   )
        , .in_strb_B    ( tree_in_strb_B   )
        , .out_ready    ( acc_out_ready    )
        , .out_valid    ( acc_out_valid    )
        , .out_last     ( acc_out_last     )
        , .out_data     ( acc_out_data     )
        , .out_strb     ( acc_out_strb     )
        , .out_overflow ( acc_out_overflow )
    );
    //--------------------------------------------------------------------------
`define reg_type_bias
`ifdef reg_type_bias
    // 'out_valid' keeps high during accumulating.
    // make a room for bias
    wire                 reg_bias_ready;
    reg                  reg_bias_valid=1'b0;
    reg [DATA_WIDTH-1:0] reg_bias_data={DATA_WIDTH{1'b0}};
    assign bias_ready = ~reg_bias_valid|reg_bias_ready;
    always @ (posedge clk) begin
    if (reset_n==1'b0) begin
        reg_bias_valid <= 1'b0;
        reg_bias_data  <= {DATA_WIDTH{1'b0}};
    end else begin
        if (reg_bias_valid==1'b0) begin
            reg_bias_valid <= bias_valid;
            reg_bias_data  <= bias_data ;
        end else begin
            if (reg_bias_ready==1'b1) begin
                reg_bias_valid <= bias_valid;
                reg_bias_data  <= bias_data ;
            end
        end
    end // if
    end // always
    //-------------------------------------------------------------------------
    wire                  `NET_DELAY tmp_ready ;
    wire                  `NET_DELAY tmp_valid ;
    wire                  `NET_DELAY tmp_last  =acc_out_last ;
    wire [DATA_WIDTH-1:0] `NET_DELAY tmp_data_A=acc_out_data ;
    wire [DATA_WIDTH-1:0] `NET_DELAY tmp_data_B;
    wire [DATA_BYTES-1:0] `NET_DELAY tmp_strb   =acc_out_strb ;
    assign acc_out_ready = (tmp_last) ? (tmp_ready&reg_bias_valid) : tmp_ready;
    assign tmp_valid     = (tmp_last) ? (reg_bias_valid&acc_out_valid) : acc_out_valid;
    assign tmp_data_B    = (tmp_last) ? reg_bias_data : {DATA_WIDTH{1'b0}};
    assign reg_bias_ready= tmp_last & tmp_ready & acc_out_valid;
    //--------------------------------------------------------------------------
    mac_core_adder #(.N(DATA_WIDTH),.B(DATA_BYTES))
    u_adder (
          .reset_n      ( reset_n      )
        , .clk          ( clk          )
        , .in_ready     ( tmp_ready    ) // output
        , .in_valid     ( tmp_valid    )
        , .in_last      ( tmp_last     )
        , .in_user      ( tmp_strb     )
        , .in_data_A    ( tmp_data_A   )
        , .in_data_B    ( tmp_data_B   )
        , .out_ready    ( out_ready    ) // input
        , .out_valid    ( out_valid    )
        , .out_last     ( out_last     )
        , .out_data     ( out_data     )
        , .out_user     ( out_strb     )
        , .out_overflow ( out_overflow )
    );
`else
    // 'out_valid' goes high only for 'out_last'.
    wire                  tmp_ready;
    wire                  tmp_valid;
    wire                  bias_out_ready ;
    wire                  bias_out_valid ;
    wire                  bias_out_last  ;
    wire [DATA_WIDTH-1:0] bias_out_data  ;
    assign acc_out_ready  = tmp_ready;
    assign bias_out_ready = tmp_ready & acc_out_valid & acc_out_last;
    assign tmp_valid      = bias_out_valid & acc_out_valid & acc_out_last;
    //--------------------------------------------------------------------------
    mac_core_fifo_sync #(.FDW(DATA_WIDTH),.FAW(1))
    u_fifo (
           .rstn     ( reset_n    )
         , .clr      ( 1'b0       )
         , .clk      ( clk        )
         , .wr_rdy   ( bias_ready )
         , .wr_vld   ( bias_valid )
         , .wr_din   ( bias_data  )
         , .rd_rdy   ( bias_out_ready )
         , .rd_vld   ( bias_out_valid )
         , .rd_dout  ( bias_out_data  )
         , .full     (  )
         , .empty    (  )
         , .item_cnt (  )
         , .room_cnt (  )
    );
    //--------------------------------------------------------------------------
    mac_core_adder #(.N(DATA_WIDTH),.B(DATA_BYTES))
    u_adder (
          .reset_n      ( reset_n       )
        , .clk          ( clk           )
        , .in_ready     ( tmp_ready     ) // output
        , .in_valid     ( tmp_valid     )
        , .in_data_A    ( acc_out_data  )
        , .in_data_B    ( bias_out_data )
        , .in_user      ( acc_out_strb  )
        , .in_last      ( acc_out_last  )
        , .out_ready    ( out_ready     ) // input
        , .out_valid    ( out_valid     )
        , .out_last     ( out_last      )
        , .out_data     ( out_data      )
        , .out_user     ( out_strb      )
        , .out_overflow ( out_overflow  )
    );
`endif
    //--------------------------------------------------------------------------
`ifdef DEBUG
`ifndef __ICARUS__
    // synthesis translate_off
    shortreal fin_data_A0, fin_data_B0;
    shortreal fin_data_A1, fin_data_B1;
    shortreal fin_data_A2, fin_data_B2;
    shortreal fin_data_A3, fin_data_B3;
    shortreal fout_data;
    always @ ( * ) begin
        fout_data = $bitstoshortreal(out_data);
        if ((AXI_WIDTH_DA/DATA_WIDTH)>=1) begin
            fin_data_A0 = $bitstoshortreal(in_data_A[0*DATA_WIDTH+:DATA_WIDTH]);
            fin_data_B0 = $bitstoshortreal(in_data_B[0*DATA_WIDTH+:DATA_WIDTH]);
        end
        if ((AXI_WIDTH_DA/DATA_WIDTH)>=2) begin
            fin_data_A1 = $bitstoshortreal(in_data_A[1*DATA_WIDTH+:DATA_WIDTH]);
            fin_data_B1 = $bitstoshortreal(in_data_B[1*DATA_WIDTH+:DATA_WIDTH]);
        end
        if ((AXI_WIDTH_DA/DATA_WIDTH)>=3) begin
            fin_data_A2 = $bitstoshortreal(in_data_A[2*DATA_WIDTH+:DATA_WIDTH]);
            fin_data_B2 = $bitstoshortreal(in_data_B[2*DATA_WIDTH+:DATA_WIDTH]);
        end
        if ((AXI_WIDTH_DA/DATA_WIDTH)>=4) begin
            fin_data_A3 = $bitstoshortreal(in_data_A[3*DATA_WIDTH+:DATA_WIDTH]);
            fin_data_B3 = $bitstoshortreal(in_data_B[3*DATA_WIDTH+:DATA_WIDTH]);
        end
    end
    // synthesis translate_on
`endif
`endif
    //--------------------------------------------------------------------------
endmodule

//------------------------------------------------------------------------------
//         +-----+   +-----+
// wider   |tree |   |accu |
// data ==>|adder|==>|mula |===>result[DATA_WIDTH]
// bus     |     |   |tor  |    strbe [DATA_BYTES]
//         +-----+   +-----+
//------------------------------------------------------------------------------
// New round starts after 'in_last'.
module tree_adder_accumulator
     #(parameter AXI_WIDTH_DA=`AXI_WIDTH_DA
               , AXI_WIDTH_DS=(AXI_WIDTH_DA/8)
               , DATA_TYPE   ="INTEGER"
               , DATA_WIDTH=`DATA_WIDTH
               , DATA_BYTES=(DATA_WIDTH/8)
               `ifdef DATA_FIXED_POINT
               , DATA_WIDTH_Q=(DATA_WIDTH/2) // fractional bits
               `endif
               , ZEROFY=1 // make byte zero if strob is not 1
               )
(
      input  wire                    reset_n
    , input  wire                    clk
    , output wire                    in_ready
    , input  wire                    in_valid
    , input  wire [AXI_WIDTH_DA-1:0] in_data_A // should be justified
    , input  wire [AXI_WIDTH_DS-1:0] in_strb_A // should be justified
    , input  wire [AXI_WIDTH_DA-1:0] in_data_B // should be justified
    , input  wire [AXI_WIDTH_DS-1:0] in_strb_B // not used
    , input  wire                    in_last
    , input  wire                    out_ready
    , output wire                    out_valid
    , output wire [DATA_WIDTH-1:0]   out_data
    , output wire [DATA_BYTES-1:0]   out_strb
    , output wire                    out_last
    , output wire                    out_overflow
);
    //--------------------------------------------------------------------------
    wire                    tree_in_ready ;
    wire                    tree_in_valid =in_valid;
    wire                    tree_in_last  =in_last;
    wire [AXI_WIDTH_DA-1:0] tree_in_data_A;
    wire [AXI_WIDTH_DA-1:0] tree_in_data_B;
    wire [AXI_WIDTH_DS-1:0] tree_in_strb_A=in_strb_A;
    wire [AXI_WIDTH_DS-1:0] tree_in_strb_B=in_strb_B;
    assign in_ready = tree_in_ready;
    //--------------------------------------------------------------------------
    generate
    genvar ida;
    if (ZEROFY[0]==1'b1) begin : BLK_ZEROFY
        for (ida=0; ida<AXI_WIDTH_DS; ida=ida+1) begin
            assign tree_in_data_A[ida*8+:8] = (in_strb_A[ida]) ? in_data_A[ida*8+:8] : 8'h0;
            assign tree_in_data_B[ida*8+:8] = (in_strb_B[ida]) ? in_data_B[ida*8+:8] : 8'h0;
        end
    end else begin
        assign tree_in_data_A=in_data_A;
        assign tree_in_data_B=in_data_B;
    end
    endgenerate
    //--------------------------------------------------------------------------
    wire                  `NET_DELAY  acc_in_ready;
    wire                  `NET_DELAY  acc_in_valid;
    wire                  `NET_DELAY  acc_in_last;
    wire [DATA_WIDTH-1:0] `NET_DELAY  acc_in_data;
    wire [DATA_BYTES-1:0] `NET_DELAY  acc_in_strb;
    wire                  `NET_DELAY  acc_in_overflow;
    //--------------------------------------------------------------------------
    tree_adder #(.AXI_WIDTH_DA(AXI_WIDTH_DA)
                ,.DATA_TYPE   (DATA_TYPE   )
                ,.DATA_WIDTH  (DATA_WIDTH  )
                `ifdef DATA_FIXED_POINT
                ,.DATA_WIDTH_Q=(DATA_WIDTH_Q) // fractional bits
                `endif
               ,.ZEROFY(0) // make byte zero if strob is not 1
                )
    u_tree_adder (
          .reset_n      ( reset_n         )
        , .clk          ( clk             )
        , .in_ready     ( tree_in_ready   )
        , .in_valid     ( tree_in_valid   )
        , .in_last      ( tree_in_last    )
        , .in_data_A    ( tree_in_data_A  )
        , .in_strb_A    ( tree_in_strb_A  )
        , .in_data_B    ( tree_in_data_B  )
        , .in_strb_B    ( tree_in_strb_B  )
        , .out_ready    ( acc_in_ready    )
        , .out_valid    ( acc_in_valid    )
        , .out_last     ( acc_in_last     )
        , .out_data     ( acc_in_data     )
        , .out_strb     ( acc_in_strb     )
        , .out_overflow ( acc_in_overflow )
    );
    //--------------------------------------------------------------------------
    mac_core_accumulator #(.N(DATA_WIDTH),.B(DATA_BYTES))
    u_accumulator (
          .clk          ( clk              )
        , .reset_n      ( reset_n          )
        , .in_ready     ( acc_in_ready     )
        , .in_valid     ( acc_in_valid     )
        , .in_data      ( acc_in_data      )
        , .in_user      ( acc_in_strb      )
        , .in_last      ( acc_in_last      )
        , .out_ready    (     out_ready    )
        , .out_valid    (     out_valid    )
        , .out_data     (     out_data     )
        , .out_user     (     out_strb     )
        , .out_last     (     out_last     )
        , .out_overflow (     out_overflow )
    );
    //--------------------------------------------------------------------------
`ifdef DEBUG
`ifndef __ICARUS__
    // synthesis translate_off
    shortreal fin_data_A0, fin_data_B0;
    shortreal fin_data_A1, fin_data_B1;
    shortreal fin_data_A2, fin_data_B2;
    shortreal fin_data_A3, fin_data_B3;
    shortreal fout_data;
    always @ ( * ) begin
        fout_data = $bitstoshortreal(out_data);
        if ((AXI_WIDTH_DA/DATA_WIDTH)>=1) begin
            fin_data_A0 = $bitstoshortreal(in_data_A[0*DATA_WIDTH+:DATA_WIDTH]);
            fin_data_B0 = $bitstoshortreal(in_data_B[0*DATA_WIDTH+:DATA_WIDTH]);
        end
        if ((AXI_WIDTH_DA/DATA_WIDTH)>=2) begin
            fin_data_A1 = $bitstoshortreal(in_data_A[1*DATA_WIDTH+:DATA_WIDTH]);
            fin_data_B1 = $bitstoshortreal(in_data_B[1*DATA_WIDTH+:DATA_WIDTH]);
        end
        if ((AXI_WIDTH_DA/DATA_WIDTH)>=3) begin
            fin_data_A2 = $bitstoshortreal(in_data_A[2*DATA_WIDTH+:DATA_WIDTH]);
            fin_data_B2 = $bitstoshortreal(in_data_B[2*DATA_WIDTH+:DATA_WIDTH]);
        end
        if ((AXI_WIDTH_DA/DATA_WIDTH)>=4) begin
            fin_data_A3 = $bitstoshortreal(in_data_A[3*DATA_WIDTH+:DATA_WIDTH]);
            fin_data_B3 = $bitstoshortreal(in_data_B[3*DATA_WIDTH+:DATA_WIDTH]);
        end
    end
    // synthesis translate_on
`endif
`endif
    //--------------------------------------------------------------------------
endmodule

//------------------------------------------------------------------------------
// for the case of num of items = 4
//             0                   0
//    +----+----+         +----+----+
//    | A1 | A0 |         | B1 | B0 |
//    +----+----+         +----+----+
//                            0
//         +----+----+----+----+
//         | B1 | A1 | B0 | A0 |
//         +----+----+----+----+
//           ||   ||   ||   ||
//         +---------+---------+
//          \  ADD  / \  ADD  /
//           +-----+   +-----+
//              ||       ||
//             +-----------+
//              \   ADD   /
//               +-------+
//                   ||
//------------------------------------------------------------------------------
//          0   1   2  3  4  5  6  7  8  9  10  11  12  13  14  15
// stage 0   \  /   \  /   
//            16     17    18    19    20     21      22      23
// stage 1      \   /        \  /      \     /
//               24           25          26              27
// stage 2           \    /                    \       /
//                     28                         29
// stage 3                    \           /
//                                 30
//------------------------------------------------------------------------------
// num of items: N                    for N=16
// num of stage: S = log2(N)              S=4
// num of links: L = 2**(S+1)-1           L=31 (2*N-1)=2*2**S-1
// starting id of each stage: I=
//------------------------------------------------------------------------------
// It deal with wider data-bus for addition.
module tree_adder
     #(parameter AXI_WIDTH_DA=`AXI_WIDTH_DA
               , AXI_WIDTH_DS=(AXI_WIDTH_DA/8)
               , DATA_TYPE   ="INTEGER"
               , DATA_WIDTH=`DATA_WIDTH
               , DATA_BYTES=(DATA_WIDTH/8)
               `ifdef DATA_FIXED_POINT
               , DATA_WIDTH_Q=(DATA_WIDTH/2) // fractional bits
               `endif
               , ZEROFY = 1
               )
(
      input  wire                    reset_n
    , input  wire                    clk
    , output wire                    in_ready
    , input  wire                    in_valid
    , input  wire [AXI_WIDTH_DA-1:0] in_data_A // should be justified
    , input  wire [AXI_WIDTH_DS-1:0] in_strb_A // should be justified
    , input  wire [AXI_WIDTH_DA-1:0] in_data_B // no effective
    , input  wire [AXI_WIDTH_DS-1:0] in_strb_B // not used
    , input  wire                    in_last
    , input  wire                    out_ready
    , output wire                    out_valid
    , output wire [DATA_WIDTH-1:0]   out_data
    , output wire [DATA_BYTES-1:0]   out_strb // simply bypass in_strb_A[DATA_BYTES-1:0]
    , output wire                    out_last
    , output wire                    out_overflow
);
    //--------------------------------------------------------------------------
    localparam NUM=(2*AXI_WIDTH_DA)/DATA_WIDTH;
    // synthesis translate_off
    real fnum;
    initial begin
        fnum = ((2*AXI_WIDTH_DA)/DATA_WIDTH);
        if (fnum!=$itor(NUM)) $display("%m ERROR width.");
        if (NUM!=(1<<$clog2(NUM))) $display("%m ERROR NUM.");
    end // initial
  //It does not care of in_strb_A/B.
  //always @ ( posedge clk) begin
  //    if (in_ready&in_valid) begin
  //        if (in_strb_A!==in_strb_B) begin
  //             $display("%0t %m ERROR strobe mis-match: %X:%X", $time, in_strb_A, in_strb_B);
  //        end
  //    end
  //end // always
    always @ ( posedge clk) begin
        if (in_ready&in_valid) begin
            if (in_strb_A[DATA_BYTES-1:0]!={DATA_BYTES{1'b1}}) begin
                 $display("%0t %m ERROR strobe: %X:%X[%0d:0]", $time, in_strb_A, in_strb_A[DATA_BYTES-1:0], DATA_BYTES-1);
            end
        end
    end // always
    always @ ( posedge clk ) begin
        if (out_ready&out_valid) begin
            if (out_strb!=={DATA_BYTES{1'b1}}) begin
                 $display("%0t %m ERROR out strobe: %X", $time, out_strb);
            end
        end
    end // always
    // synthesis translate_on
    //--------------------------------------------------------------------------
    wire [2*NUM-2:0]      `NET_DELAY link_ready;
    wire [2*NUM-2:0]      `NET_DELAY link_valid;
    wire [2*NUM-2:0]      `NET_DELAY link_last;
    wire [DATA_WIDTH-1:0] `NET_DELAY link_data[0:2*NUM-2];
    wire [DATA_BYTES-1:0] `NET_DELAY link_strb[0:2*NUM-2];
    wire [2*NUM-2:0]      `NET_DELAY link_overflow;
    //--------------------------------------------------------------------------
    assign in_ready     = (&link_ready[NUM-1:0])&in_valid;
    assign out_valid    = link_valid[2*NUM-2];
    assign out_data     = link_data [2*NUM-2];
    assign out_strb     = link_strb [2*NUM-2];
    assign out_last     = link_last [2*NUM-2];
    assign out_overflow = |link_overflow;
    assign link_ready[2*NUM-2] = out_ready;
    //--------------------------------------------------------------------------
    genvar idw, idx, idy, idz;
    generate
    for (idx=0; idx<$clog2(NUM); idx=idx+1) begin : BLK_STAGE
        localparam idz = get_idz(idx, NUM);
        for (idy=0; idy<(NUM/(1<<(idx+1))); idy=idy+1) begin : BLK_LAYER
            if (idx==0) begin : BLK_IDX
                assign link_ready[2*idy+1] = link_ready[2*idy];
                assign link_valid[2*idy  ] = in_valid;
                assign link_valid[2*idy+1] = in_valid;
                assign link_last [2*idy  ] = in_last ;
                assign link_last [2*idy+1] = in_last ;
                assign link_strb [2*idy  ] = in_strb_A[(idy*DATA_BYTES)+:DATA_BYTES];
                assign link_strb [2*idy+1] = in_strb_B[(idy*DATA_BYTES)+:DATA_BYTES];
                if (ZEROFY[0]==1'b1) begin
                    for (idw=0; idw<DATA_BYTES; idw=idw+1) begin
                        assign link_data [2*idy  ][(8*idw)+:8] = (in_strb_A[idy*DATA_BYTES+idw])
                                                               ? in_data_A[(idy*DATA_WIDTH+8*idw)+:8]
                                                               : 8'h0;
                        assign link_data [2*idy+1][(8*idw)+:8] = (in_strb_B[idy*DATA_BYTES+idw])
                                                               ? in_data_B[(idy*DATA_WIDTH+8*idw)+:8]
                                                               : 8'h0;
                    end
                end else begin
                    assign link_data [2*idy  ] = in_data_A[(idy*DATA_WIDTH)+:DATA_WIDTH];
                    assign link_data [2*idy+1] = in_data_B[(idy*DATA_WIDTH)+:DATA_WIDTH];
                end
                assign link_overflow[2*idy  ] = 1'b0; // no input port
                assign link_overflow[2*idy+1] = 1'b0; // no input port
                mac_core_adder #(.N(DATA_WIDTH),.B(DATA_BYTES))
                u_adder (
                      .reset_n      ( reset_n       )
                    , .clk          ( clk           )
                    , .in_ready     ( link_ready    [(2*idy)]) // output
                    , .in_valid     ( link_valid    [(2*idy)])
                    , .in_data_A    ( link_data     [(2*idy)])
                    , .in_data_B    ( link_data     [(2*idy)+1])
                    , .in_user      ( link_strb     [(2*idy)])
                    , .in_last      ( link_last     [(2*idy)])
                    , .out_ready    ( link_ready    [NUM+idy]) // input
                    , .out_valid    ( link_valid    [NUM+idy])
                    , .out_data     ( link_data     [NUM+idy])
                    , .out_user     ( link_strb     [NUM+idy])
                    , .out_last     ( link_last     [NUM+idy])
                    , .out_overflow ( link_overflow [NUM+idy])
                );
            end else begin
                mac_core_adder #(.N(DATA_WIDTH),.B(DATA_BYTES))
                u_adder (
                      .reset_n      ( reset_n       )
                    , .clk          ( clk           )
                    , .in_ready     ( link_ready    [idz+(2*idy)]) // output
                    , .in_valid     ( link_valid    [idz+(2*idy)])
                    , .in_data_A    ( link_data     [idz+(2*idy)])
                    , .in_data_B    ( link_data     [idz+(2*idy)+1])
                    , .in_user      ( link_strb     [idz+(2*idy)])
                    , .in_last      ( link_last     [idz+(2*idy)])
                    , .out_ready    ( link_ready    [idz+(NUM/(1<<idx))+idy]) // input
                    , .out_valid    ( link_valid    [idz+(NUM/(1<<idx))+idy])
                    , .out_last     ( link_last     [idz+(NUM/(1<<idx))+idy])
                    , .out_data     ( link_data     [idz+(NUM/(1<<idx))+idy])
                    , .out_user     ( link_strb     [idz+(NUM/(1<<idx))+idy])
                    , .out_overflow ( link_overflow [idz+(NUM/(1<<idx))+idy])
                );
                assign link_ready[idz+(2*idy)+1] = link_ready[idz+(2*idy)];// make hidden link
              //assign link_valid[idz+(2*idy)+1] = link_valid[idz+(2*idy)];// make hidden link
              //assign link_last [idz+(2*idy)+1] = link_last [idz+(2*idy)];// make hidden link
              //assign link_strb [idz+(2*idy)+1] = link_strb [idz+(2*idy)];// make hidden link
            end
        end // for (idy
    end // for (idx
    endgenerate
    //--------------------------------------------------------------------------
    function automatic integer get_idz;
        input integer stage;
        input integer num;
        integer s, n;
    begin
        if (stage==0) begin
            get_idz = 0;
        end  else begin
            n = 0;
            for (s=0; s<stage; s=s+1) begin
                n = n + (num>>s);
            end
            get_idz = n;
        end
    end
    endfunction
    //--------------------------------------------------------------------------
    // synthesis translate_off
`ifdef DEBUG
    //--------------------------------------------------------------------------
    shortreal fin_data_A0, fin_data_B0;
    shortreal fin_data_A1, fin_data_B1;
    shortreal fin_data_A2, fin_data_B2;
    shortreal fin_data_A3, fin_data_B3;
    shortreal fout_data;
    always @ ( * ) begin
        fout_data = $bitstoshortreal(out_data);
        if ((AXI_WIDTH_DA/DATA_WIDTH)>=1) begin
            fin_data_A0 = $bitstoshortreal(in_data_A[0*DATA_WIDTH+:DATA_WIDTH]);
            fin_data_B0 = $bitstoshortreal(in_data_B[0*DATA_WIDTH+:DATA_WIDTH]);
        end
        if ((AXI_WIDTH_DA/DATA_WIDTH)>=2) begin
            fin_data_A1 = $bitstoshortreal(in_data_A[1*DATA_WIDTH+:DATA_WIDTH]);
            fin_data_B1 = $bitstoshortreal(in_data_B[1*DATA_WIDTH+:DATA_WIDTH]);
        end
        if ((AXI_WIDTH_DA/DATA_WIDTH)>=3) begin
            fin_data_A2 = $bitstoshortreal(in_data_A[2*DATA_WIDTH+:DATA_WIDTH]);
            fin_data_B2 = $bitstoshortreal(in_data_B[2*DATA_WIDTH+:DATA_WIDTH]);
        end
        if ((AXI_WIDTH_DA/DATA_WIDTH)>=4) begin
            fin_data_A3 = $bitstoshortreal(in_data_A[3*DATA_WIDTH+:DATA_WIDTH]);
            fin_data_B3 = $bitstoshortreal(in_data_B[3*DATA_WIDTH+:DATA_WIDTH]);
        end
    end
    //--------------------------------------------------------------------------
    integer idb, idc, idd;
    initial begin
    $display("Link[%0d~%0d] =====================", 2*NUM-2, 0);
    for (idb=0; idb<$clog2(NUM); idb=idb+1) begin
        idd = get_idz(idb, NUM);
        $display("STAGE %d start=%0d [%0d~%0d] =================", idb, idd, 0, (NUM/(1<<(idb+1)))-1);
        for (idc=0; idc<(NUM/(1<<(idb+1))); idc=idc+1) begin
            if (idb==0) begin
                $display("assign link_ready[%0d] = link_ready[%0d];", 2*idc+1,2*idc);
                $display("assign link_valid[%0d] = in_valid;",2*idc  );
                $display("assign link_valid[%0d] = in_valid;",2*idc+1);
                $display("assign link_last [%0d] = in_last ;",2*idc  );
                $display("assign link_last [%0d] = in_last ;",2*idc+1);
                $display("assign link_strb [%0d] = in_strb_A[%0d:%0d];",2*idc  ,(idc*DATA_BYTES)+DATA_BYTES-1,(idc*DATA_BYTES));
                $display("assign link_strb [%0d] = in_strb_B[%0d:%0d];",2*idc+1,(idc*DATA_BYTES)+DATA_BYTES-1,(idc*DATA_BYTES));
                $display("assign link_data [%0d] = in_data_A[%0d:%0d];",2*idc  ,(idc*DATA_WIDTH)+DATA_WIDTH-1,(idc*DATA_WIDTH));
                $display("assign link_data [%0d] = in_data_B[%0d:%0d];",2*idc+1,(idc*DATA_WIDTH)+DATA_WIDTH-1,(idc*DATA_WIDTH));
                $display("assign link_overflow[%0d] = 1'b0;",2*idc  );
                $display("assign link_overflow[%0d] = 1'b0;",2*idc+1);
                $display("mac_core_adder #(.N(%0d),.B(%0d))", DATA_WIDTH, DATA_BYTES);
                $display("u_adder (");
                $display("      .reset_n      ( reset_n       )");
                $display("    , .clk          ( clk           )");
                $display("    , .in_ready     ( link_ready    [%0d])", (2*idc)  );
                $display("    , .in_valid     ( link_valid    [%0d])", (2*idc)  );
                $display("    , .in_data_A    ( link_data     [%0d])", (2*idc)  );
                $display("    , .in_data_B    ( link_data     [%0d])", (2*idc)+1);
                $display("    , .in_user      ( link_strb     [%0d])", (2*idc)  );
                $display("    , .in_last      ( link_last     [%0d])", (2*idc)  );
                $display("    , .out_ready    ( link_ready    [%0d])", NUM+idc  );
                $display("    , .out_valid    ( link_valid    [%0d])", NUM+idc  );
                $display("    , .out_data     ( link_data     [%0d])", NUM+idc  );
                $display("    , .out_user     ( link_strb     [%0d])", NUM+idc  );
                $display("    , .out_last     ( link_last     [%0d])", NUM+idc  );
                $display("    , .out_overflow ( link_overflow [%0d])", NUM+idc  );
                $display(");");
            end else begin
                $display("mac_core_adder #(.N(%0d),.B(%0d))", DATA_WIDTH, DATA_BYTES);
                $display("u_adder (");
                $display("      .reset_n      ( reset_n       )");
                $display("    , .clk          ( clk           )");
                $display("    , .in_ready     ( link_ready    [%0d])", idd+(2*idc)           );
                $display("    , .in_valid     ( link_valid    [%0d])", idd+(2*idc)           );
                $display("    , .in_last      ( link_last     [%0d])", idd+(2*idc)           );
                $display("    , .in_user      ( link_strb     [%0d])", idd+(2*idc)           );
                $display("    , .in_data_A    ( link_data     [%0d])", idd+(2*idc)           );
                $display("    , .in_data_B    ( link_data     [%0d])", idd+(2*idc)+1         );
                $display("    , .out_ready    ( link_ready    [%0d])", idd+(NUM/(1<<idb))+idc);
                $display("    , .out_valid    ( link_valid    [%0d])", idd+(NUM/(1<<idb))+idc);
                $display("    , .out_last     ( link_last     [%0d])", idd+(NUM/(1<<idb))+idc);
                $display("    , .out_data     ( link_data     [%0d])", idd+(NUM/(1<<idb))+idc);
                $display("    , .out_user     ( link_strb     [%0d])", idd+(NUM/(1<<idb))+idc);
                $display("    , .out_overflow ( link_overflow [%0d])", idd+(NUM/(1<<idb))+idc);
                $display(");");
                $display("assign link_ready[%0d] = link_ready[%0d];", idd+(2*idc)+1, idd+(2*idc));
              //$display("assign link_valid[%0d] = link_valid[%0d];", idd+(2*idc)+1, idd+(2*idc));
              //$display("assign link_last [%0d] = link_last [%0d];", idd+(2*idc)+1, idd+(2*idc));
              //$display("assign link_strb [%0d] = link_strb [%0d];", idd+(2*idc)+1, idd+(2*idc));
            end
        end // for (idc
    end // for (idb
    end
`endif
    // synthesis translate_on
    //--------------------------------------------------------------------------
endmodule

//------------------------------------------------------------------------------
// Revision history
//
// 2021.06.10: Started by Ando Ki (andoki@gmail.com)
//------------------------------------------------------------------------------
/*
#include <stdio.h>
#include <stdlib.h>

static int clog2(int value)
{
    int tmp, rt;
    tmp = value - 1;
    for (rt=0; tmp>0; rt=rt+1) tmp=tmp>>1;
    return rt;
}

static int get_idz(int stage, int num)
{
    int s, n;
    n = num;
    for (s=1; s<=(stage-1); s++) {
         n += num/(1<<s);
    }
    return n;
}

int main( int argc, char *argv[])
{
    int num = 2;
    if (argc>1) num = atoi(argv[1]);
    if (num!=(1<<clog2(num))) return -1;

    printf("num=%d stage=%d\n", num, clog2(num));
    for (int idx=0; idx<clog2(num); idx=idx+1) {
       int idz = get_idz(idx, num);
       for (int idy=0; idy<((num/(1<<idx))/2); idy=idy+1) {
            if (idx==0) {
                printf("[%d]=[%d]+[%d] ", num+idy
                                        , 2*idy, 2*idy+1);
            } else {
                printf("[%d]=[%d]+[%d] ", idz+num/(1<<idx)+idy
                                        , idz+2*idy
                                        , idz+2*idy+1);
            }
       }
       printf("\n");
    }

    return 0;
}
*/

//------------------------------------------------------------------------------
// Copyright (c) by Ando Ki
// All right reserved.
//
// http://www.future-ds.com
// adki@future-ds.com
//------------------------------------------------------------------------------
// mac_core_fifo_sync.v
//------------------------------------------------------------------------------
// Synchronous FIFO
//------------------------------------------------------------------------------
// VERSION: 2021.06.10.
//------------------------------------------------------------------------------
// MACROS and PARAMETERS
//     FDW: bit-width of data
//     FAW: num of entries in power of 2
//------------------------------------------------------------------------------
// Features
//    * ready-valid handshake protocol
//    * First-Word Fall-Through, but rd_vld indicates its validity
//------------------------------------------------------------------------------
//    * data moves when both ready(rdy) and valid(vld) is high.
//    * ready(rdy) means the receiver is ready to accept data.
//    * valid(vld) means the data is valid on 'data'.
//------------------------------------------------------------------------------
//               __     ___     ___     ___     ___
//   clk           |___|   |___|   |___|   |___|
//               _______________________________
//   wr_rdy     
//                      _______________ 
//   wr_vld      ______|       ||      |___________  
//                      _______  ______
//   wr_din      XXXXXXX__D0___XX__D1__XXXX
//               ______________                         ___
//   empty                     |_______________________|
//                                      _______________ 
//   rd_rdy      ______________________|               |___
//                                      _______________
//   rd_vld      ______________________|       ||      |___
//                                      ________ _______
//   rd_dout     XXXXXXXXXXXXXXXXXXXXXXX__D0____X__D1___XXXX
//
//   full        __________________________________________
//------------------------------------------------------------------------------

module mac_core_fifo_sync
     #(parameter FDW =32,  // fifo data width
                 FAW =5 )  // num of entries in 2 to the power FAW
(
       input   wire           rstn// asynchronous reset (active low)
     , input   wire           clr // synchronous reset (active high)
     , input   wire           clk
     , output  wire           wr_rdy
     , input   wire           wr_vld
     , input   wire [FDW-1:0] wr_din
     , input   wire           rd_rdy
     , output  wire           rd_vld
     , output  wire [FDW-1:0] rd_dout
     , output  wire           full
     , output  wire           empty
     , output  reg  [FAW:0]   item_cnt // num of elements in the FIFO to be read
     , output  wire [FAW:0]   room_cnt // num of rooms in the FIFO to be written
);
   //---------------------------------------------------
   localparam FDT = 1<<FAW;
   //---------------------------------------------------
   reg  [FAW:0]   fifo_head='h0; // where data to be read
   reg  [FAW:0]   fifo_tail='h0; // where data to be written
   reg  [FAW:0]   next_head='h1;
   reg  [FAW:0]   next_tail='h1;
   wire [FAW-1:0] read_addr = (rd_vld&rd_rdy) ? next_head[FAW-1:0]
                                              : fifo_head[FAW-1:0];
   //---------------------------------------------------
   // accept input
   // push data item into the entry pointed by fifo_tail
   //
   always @(posedge clk or negedge rstn) begin
      if (rstn==1'b0) begin
          fifo_tail <= 0;
          next_tail <= 1;
      end else if (clr) begin
          fifo_tail <= 0;
          next_tail <= 1;
      end else begin
          if (!full && wr_vld) begin
              fifo_tail <= next_tail;
              next_tail <= next_tail + 1;
          end 
      end
   end
   //---------------------------------------------------
   // provide output
   // pop data item from the entry pointed by fifo_head
   //
   always @(posedge clk or negedge rstn) begin
      if (rstn==1'b0) begin
          fifo_head <= 0;
          next_head <= 1;
      end else if (clr) begin
          fifo_head <= 0;
          next_head <= 1;
      end else begin
          if (!empty && rd_rdy) begin
              fifo_head <= next_head;
              next_head <= next_head + 1;
          end
      end
   end
   //---------------------------------------------------
   // how many items in the FIFO
   //
   assign  room_cnt = FDT-item_cnt;
   always @(posedge clk or negedge rstn) begin
      if (rstn==1'b0) begin
         item_cnt <= 0;
      end else if (clr) begin
         item_cnt <= 0;
      end else begin
         if (wr_vld&&!full&&(!rd_rdy||(rd_rdy&&empty))) begin
             item_cnt <= item_cnt + 1;
         end else
         if (rd_rdy&&!empty&&(!wr_vld||(wr_vld&&full))) begin
             item_cnt <= item_cnt - 1;
         end
      end
   end
   
   //---------------------------------------------------
   assign rd_vld = ~empty;
   assign wr_rdy = ~full;
   assign empty  = (fifo_head == fifo_tail);
   assign full   = (item_cnt>=FDT);
   //---------------------------------------------------
   // synopsys translate_off
`ifdef RIGOR
   //always @ (posedge clk) begin
   //    if (full) $display($time,,"%m: synchronous fifo full.....");
   //end
   always @(negedge clk or negedge rstn) begin
      if (rstn&&!clr) begin
          if ((item_cnt==0)&&(!empty))
             $display($time,, "%m: empty flag mis-match: %d", item_cnt);
          if ((item_cnt==FDT)&&(!full))
             $display($time,, "%m: full flag mis-match: %d", item_cnt);
          if (item_cnt>FDT)
             $display($time,, "%m: fifo handling error: item_cnt>FDT %d:%d", item_cnt, FDT);
          if ((item_cnt+room_cnt)!=FDT)
             $display($time,, "%m: count mis-match: item_cnt:room_cnt %d:%d", item_cnt, room_cnt);
      end
   end
`endif
   // synopsys translate_on
   //---------------------------------------------------
   (* ram_style="block" *) reg [FDW-1:0] Mem [0:FDT-1];
`ifdef SIM
   assign rd_dout  = (rd_vld) ? Mem[fifo_head[FAW-1:0]] : 'h0;
`else
   assign rd_dout  = Mem[fifo_head[FAW-1:0]];
`endif
   always @(posedge clk) begin
       if (!full && wr_vld) begin
           Mem[fifo_tail[FAW-1:0]] <= wr_din;
       end
   end
   //---------------------------------------------------
endmodule
//------------------------------------------------------------------------------
// Revision History
//
// 2021.06.10: Started by Ando Ki (andoki@gmail.com)
//------------------------------------------------------------------------------
