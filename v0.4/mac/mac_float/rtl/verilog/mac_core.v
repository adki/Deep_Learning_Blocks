//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All right reserved.
//------------------------------------------------------------------------------
// VERSION: 2021.06.01.
//------------------------------------------------------------------------------
// MAC (multiplier–accumulator)
//------------------------------------------------------------------------------
// Note:
// Floating-point 32-bit (Single-precision): 1-bit sign, 8-bit exponent, 23-bit fraction
// Floating-point 16-bit (half-precision): 1-bit sign, 5-bit exponent, 10-bit fraction
// Floating-point 8-bit (mini-precision): 1-bit sign, 4-bit exponent, 3-bit fraction
//
//                  (mantissa)
//   +-+----------+------------+
//   |S| exponent | fraction   |
//   +-+----------+------------+
//              +--------------+
//              |1.            |
//              +--------------+
//
// TLAST makes clear internal data for accumulator.
//------------------------------------------------------------------------------
//              __    __    __    __    __    __    __
//  CLK      __|  |__|  |__|  |__|  |__|  |__|  |__|  |__
//             |_____|_____|     |_____|
//  A or B   XXX__a__X_____XXXXXXX_____X
//             |     |     |_____|_____|
//  M        XXXXXXXXXXXXXXX__a'_X_____X
//             |     |     |     |_____|
//  C        XXXXXXXXXXXXXXXXXXXXX__c__X
//------------------------------------------------------------------------------
// mac_core
// mac_core_multiplier
// mac_core_adder
// mac_core_accumulator
// mac_core_compare
//------------------------------------------------------------------------------

`ifdef SIM
`include "fp32_accumulator/fp32_accumulator_sim_netlist.v"
`include "fp32_adder/fp32_adder_sim_netlist.v"
`include "fp32_multiplier/fp32_multiplier_sim_netlist.v"
`include "fp16_accumulator/fp16_accumulator_sim_netlist.v"
`include "fp16_adder/fp16_adder_sim_netlist.v"
`include "fp16_multiplier/fp16_multiplier_sim_netlist.v"
`else
`include "fp32_accumulator/fp32_accumulator_stub.v"
`include "fp32_adder/fp32_adder_stub.v"
`include "fp32_multiplier/fp32_multiplier_stub.v"
`include "fp16_accumulator/fp16_accumulator_stub.v"
`include "fp16_adder/fp16_adder_stub.v"
`include "fp16_multiplier/fp16_multiplier_stub.v"
`endif

module mac_core
     #(parameter WIDTH_DATA=32)
(
      input  wire                     RESET_N // asynchronous reset
    , input  wire                     CLK
    , input  wire                     INIT  // synchronous reset
    , output reg                      READY // ready when 1
    // operand A
    , output wire                     IN_READY_A
    , input  wire  [WIDTH_DATA-1:0]   IN_DATA_A
    , input  wire                     IN_VALID_A
    , input  wire                     IN_LAST_A
    // operand B
    , output wire                     IN_READY_B
    , input  wire  [WIDTH_DATA-1:0]   IN_DATA_B
    , input  wire                     IN_VALID_B
    , input  wire                     IN_LAST_B
    // resultant C=A*B+C'
    , output reg   [WIDTH_DATA-1:0]   OUT_DATA
    , output wire                     OUT_VALID
    , input  wire                     OUT_READY
    , output wire                     OUT_LAST
    , output reg                      OUT_OVERFLOW // overflow
);
    //--------------------------------------------------------------------------
    localparam N=WIDTH_DATA
             , E=(N==32) ? 8 : (N==16) ? 5 : 0
             , F= N-(E+1);
    //--------------------------------------------------------------------------
    reg SRESETn=1'b0; // synchronous reset
    always @ (posedge CLK) SRESETn <= RESET_N&~INIT;
    //--------------------------------------------------------------------------
    always @ (posedge CLK or negedge RESET_N) begin
    if (RESET_N==1'b0) begin
        READY <= 1'b0;
    end else begin
        if (INIT==1'b1) READY <= 1'b0;
        else            READY <= 1'b1;
    end // if
    end // always
    //--------------------------------------------------------------------------
    // synthesis translate_off
    always @ (posedge CLK or negedge RESET_N) begin
    if (RESET_N==1'b1) begin
        if (IN_VALID_A==1'b1&&IN_VALID_B==1'b1) begin
            if (IN_LAST_A^IN_LAST_B) begin
                $display("%0t %m ERROR tlast mis-match", $time);
            end
        end
    end
    end // always
    // synthesis translate_on
    //--------------------------------------------------------------------------
    wire [N-1:0]     mul_in_data_A=IN_DATA_A;
    wire [N-1:0]     mul_in_data_B=IN_DATA_B;
    wire             mul_in_valid=IN_VALID_A&IN_VALID_B;
    wire             mul_in_ready_A;
    wire             mul_in_ready_B;
    wire             mul_in_last=mul_in_valid&IN_LAST_A&IN_LAST_B;
    wire [N-1:0]     mul_out_data ;
    wire             mul_out_valid;
    wire             mul_out_ready;
    wire             mul_out_overflow;
    wire [N/8*2-1:0] mul_out_user ;
    wire             mul_out_last ;
    assign IN_READY_A = mul_in_ready_A&IN_VALID_A&IN_VALID_B;
    assign IN_READY_B = mul_in_ready_B&IN_VALID_A&IN_VALID_B;
    //--------------------------------------------------------------------------
    generate
    if (N==32) begin : FP32_MUL
        fp32_multiplier
        u_multiplier (
              .aresetn              ( RESET_N&~INIT    )
            , .aclk                 ( CLK              )
            , .s_axis_a_tvalid      ( mul_in_valid     )
            , .s_axis_a_tready      ( mul_in_ready_A   )
            , .s_axis_a_tdata       ( mul_in_data_A    )
            , .s_axis_a_tuser       ( 4'h0             )
            , .s_axis_a_tlast       ( mul_in_last      )
            , .s_axis_b_tvalid      ( mul_in_valid     )
            , .s_axis_b_tready      ( mul_in_ready_B   )
            , .s_axis_b_tdata       ( mul_in_data_B    )
            , .s_axis_b_tuser       ( 4'h0             )
            , .s_axis_b_tlast       ( mul_in_last      )
            , .m_axis_result_tvalid ( mul_out_valid    )
            , .m_axis_result_tready ( mul_out_ready    )
            , .m_axis_result_tdata  ( mul_out_data     )
            , .m_axis_result_tuser  ({mul_out_user,mul_out_overflow})
            , .m_axis_result_tlast  ( mul_out_last     )
        );
    end else if (N==16) begin : FP16_MUL
        fp16_multiplier
        u_multiplier (
              .aresetn              ( RESET_N&~INIT    )
            , .aclk                 ( CLK              )
            , .s_axis_a_tvalid      ( mul_in_valid     )
            , .s_axis_a_tready      ( mul_in_ready_A   )
            , .s_axis_a_tdata       ( mul_in_data_A    )
            , .s_axis_a_tuser       ( 2'h0             )
            , .s_axis_a_tlast       ( mul_in_last      )
            , .s_axis_b_tvalid      ( mul_in_valid     )
            , .s_axis_b_tready      ( mul_in_ready_B   )
            , .s_axis_b_tdata       ( mul_in_data_B    )
            , .s_axis_b_tuser       ( 2'h0             )
            , .s_axis_b_tlast       ( mul_in_last      )
            , .m_axis_result_tvalid ( mul_out_valid    )
            , .m_axis_result_tready ( mul_out_ready    )
            , .m_axis_result_tdata  ( mul_out_data     )
            , .m_axis_result_tuser  ({mul_out_user,mul_out_overflow})
            , .m_axis_result_tlast  ( mul_out_last     )
        );
    end
    endgenerate
    //--------------------------------------------------------------------------
    wire [N-1:0]   acc_in_data=mul_out_data;
    wire           acc_in_valid=mul_out_valid;
    wire           acc_in_ready;
    wire           acc_in_last=mul_out_last;
    wire [N-1:0]   acc_out_data    ;
    wire [N/8-1:0] acc_out_strb    ;
    wire           acc_out_valid   ;
    wire           acc_out_ready   ;
    wire           acc_out_last    ;
    wire [1:0]     acc_out_overflow; // [1]==output_overflow, [0]=input_overflow
    assign mul_out_ready=acc_in_ready;
    //--------------------------------------------------------------------------
    // It produces N*2+1-bit accumulation result of a series of N*2+1-bit inputs.
    // Internal storage is clear when LAST is 1.
    generate
    if (N==32) begin : FP32_ACC
        fp32_accumulator
        u_accumulator (
              .aresetn               ( RESET_N&~INIT    )
            , .aclk                  ( CLK              )
            , .s_axis_a_tvalid       ( acc_in_valid     )
            , .s_axis_a_tready       ( acc_in_ready     )
            , .s_axis_a_tdata        ( acc_in_data      )
            , .s_axis_a_tuser        ( 4'h0             )
            , .s_axis_a_tlast        ( acc_in_last      )
            , .m_axis_result_tvalid  ( acc_out_valid    )
            , .m_axis_result_tready  ( acc_out_ready    )
            , .m_axis_result_tdata   ( acc_out_data     )
            , .m_axis_result_tuser   ({acc_out_strb,acc_out_overflow})
            , .m_axis_result_tlast   ( acc_out_last     )
        );
    end else if (N==16) begin : FP16_ACC
        fp16_accumulator
        u_accumulator (
              .aresetn               ( RESET_N&~INIT    )
            , .aclk                  ( CLK              )
            , .s_axis_a_tvalid       ( acc_in_valid     )
            , .s_axis_a_tready       ( acc_in_ready     )
            , .s_axis_a_tdata        ( acc_in_data      )
            , .s_axis_a_tuser        ( 2'h0             )
            , .s_axis_a_tlast        ( acc_in_last      )
            , .m_axis_result_tvalid  ( acc_out_valid    )
            , .m_axis_result_tready  ( acc_out_ready    )
            , .m_axis_result_tdata   ( acc_out_data     )
            , .m_axis_result_tuser   ({acc_out_strb,acc_out_overflow})
            , .m_axis_result_tlast   ( acc_out_last     )
        );
    end
    endgenerate
    //--------------------------------------------------------------------------
    wire [N-1:0] MAX_POS={1'b0,{E{1'b1}},1'b1,{F-1{1'b0}}};
    wire [N-1:0] MAX_NEG={1'b1,{E{1'b1}},1'b1,{F-1{1'b0}}};
    //--------------------------------------------------------------------------
    always @ ( * ) begin
        if (|acc_out_overflow) begin
            OUT_OVERFLOW= acc_out_valid; // overflow
            if (acc_out_data[N-1]) OUT_DATA = MAX_NEG;
            else OUT_DATA = MAX_POS;
        end else begin
            OUT_DATA = acc_out_data[N-1:0];
            OUT_OVERFLOW = 1'b0;
        end
    end
    //--------------------------------------------------------------------------
    assign acc_out_ready = OUT_READY;
    assign OUT_VALID = acc_out_valid;
    assign OUT_LAST  = acc_out_last ;
    //--------------------------------------------------------------------------
    // synthesis translate_off
    shortreal IN_DATA_A_float;
    shortreal IN_DATA_B_float;
    shortreal OUT_DATA_float ;
    always @ ( * ) begin
        IN_DATA_A_float=$bitstoshortreal(IN_DATA_A);
        IN_DATA_B_float=$bitstoshortreal(IN_DATA_B);
        OUT_DATA_float =$bitstoshortreal(OUT_DATA );
    end
    // synthesis translate_on
    //--------------------------------------------------------------------------
endmodule

//------------------------------------------------------------------------------
module mac_core_multiplier
     #(parameter N=32, B=N/8)
(
      input  wire            clk
    , input  wire            reset_n
    , output wire            in_ready
    , input  wire            in_valid
    , input  wire [N-1:0]    in_data_A
    , input  wire [N-1:0]    in_data_B
    , input  wire [B-1:0]    in_user // byte strobe
    , input  wire            in_last
    , input  wire            out_ready
    , output wire            out_valid
    , output reg  [N-1:0]    out_data
    , output reg  [B-1:0]    out_user
    , output wire            out_last
    , output reg             out_overflow
);
    //--------------------------------------------------------------------------
    localparam E=(N==32) ? 8 : (N==16) ? 5 : 0
             , F= N-(E+1);
    //--------------------------------------------------------------------------
    wire   in_ready_A;
    wire   in_ready_B;
    assign in_ready = in_ready_A & in_ready_B;
    //--------------------------------------------------------------------------
    wire             tmp_ready;
    wire             tmp_valid;
    wire             tmp_last ;
    wire [N-1:0]     tmp_data ;
    wire [B*2-1:0]   tmp_user;
    wire             tmp_overflow;
    //--------------------------------------------------------------------------
    generate
    if (N==32) begin : FP32_MUL
        fp32_multiplier
        u_multiplier (
              .aresetn              ( reset_n      )
            , .aclk                 ( clk          )
            , .s_axis_a_tvalid      ( in_valid     )
            , .s_axis_a_tready      ( in_ready_A   )
            , .s_axis_a_tdata       ( in_data_A    )
            , .s_axis_a_tuser       ( in_user      )
            , .s_axis_a_tlast       ( in_last      )
            , .s_axis_b_tvalid      ( in_valid     )
            , .s_axis_b_tready      ( in_ready_B   )
            , .s_axis_b_tdata       ( in_data_B    )
            , .s_axis_b_tuser       ( in_user      )
            , .s_axis_b_tlast       ( in_last      )
            , .m_axis_result_tvalid ( tmp_valid    )
            , .m_axis_result_tready ( tmp_ready    )
            , .m_axis_result_tdata  ( tmp_data     )
            , .m_axis_result_tuser  ({tmp_user,tmp_overflow})
            , .m_axis_result_tlast  ( tmp_last     )
        );
    end else if (N==16) begin : FP16_MUL
        fp16_multiplier
        u_multiplier (
              .aresetn              ( reset_n      )
            , .aclk                 ( clk          )
            , .s_axis_a_tvalid      ( in_valid     )
            , .s_axis_a_tready      ( in_ready_A   )
            , .s_axis_a_tdata       ( in_data_A    )
            , .s_axis_a_tuser       ( in_user      )
            , .s_axis_a_tlast       ( in_last      )
            , .s_axis_b_tvalid      ( in_valid     )
            , .s_axis_b_tready      ( in_ready_B   )
            , .s_axis_b_tdata       ( in_data_B    )
            , .s_axis_b_tuser       ( in_user      )
            , .s_axis_b_tlast       ( in_last      )
            , .m_axis_result_tvalid ( tmp_valid    )
            , .m_axis_result_tready ( tmp_ready    )
            , .m_axis_result_tdata  ( tmp_data     )
            , .m_axis_result_tuser  ({tmp_user,tmp_overflow})
            , .m_axis_result_tlast  ( tmp_last     )
        );
    end
    endgenerate
    //--------------------------------------------------------------------------
    wire [N-1:0] MAX_POS={1'b0,{E{1'b1}},1'b1,{F-1{1'b0}}};
    wire [N-1:0] MAX_NEG={1'b1,{E{1'b1}},1'b1,{F-1{1'b0}}};
    //--------------------------------------------------------------------------
    always @ ( * ) begin
        out_overflow = tmp_overflow; // overflow
        out_user     = tmp_user[B-1:0];
        if (tmp_overflow) begin
            if (tmp_data[N-1]) out_data = MAX_NEG;
            else out_data = MAX_POS;
        end else begin
            out_data = tmp_data;
            out_user = tmp_user[0+:B]&tmp_user[B+:B];
        end
    end
    //--------------------------------------------------------------------------
    assign tmp_ready = out_ready;
    assign out_valid = tmp_valid;
    assign out_last  = tmp_last ;
    //--------------------------------------------------------------------------
    // synthesis translate_off
    shortreal in_data_A_float;
    shortreal in_data_B_float;
    shortreal out_data_float ;
    always @ ( * ) begin
        in_data_A_float = $bitstoshortreal(in_data_A);
        in_data_B_float = $bitstoshortreal(in_data_B);
        out_data_float  = $bitstoshortreal(out_data );
    end
    // synthesis translate_on
    //--------------------------------------------------------------------------
endmodule

//------------------------------------------------------------------------------
module mac_core_adder
     #(parameter N=32, B=N/8)
(
      input  wire           reset_n
    , input  wire           clk
    , output wire           in_ready
    , input  wire           in_valid
    , input  wire [N-1:0]   in_data_A
    , input  wire [N-1:0]   in_data_B
    , input  wire [B-1:0]   in_user
    , input  wire           in_last
    , input  wire           out_ready
    , output wire           out_valid
    , output reg  [N-1:0]   out_data
    , output reg  [B-1:0]   out_user
    , output wire           out_last
    , output reg            out_overflow
);
    //--------------------------------------------------------------------------
    localparam E=(N==32) ? 8 : (N==16) ? 5 : 0
             , F= N-(E+1);
    //--------------------------------------------------------------------------
    wire   in_ready_A;
    wire   in_ready_B;
    assign in_ready = in_ready_A & in_ready_B;
    //--------------------------------------------------------------------------
    wire             tmp_ready;
    wire             tmp_valid;
    wire             tmp_last ;
    wire [N-1:0]     tmp_data ;
    wire [B*2-1:0]   tmp_user;
    wire             tmp_overflow;
    //--------------------------------------------------------------------------
    generate
    if (N==32) begin : FP32_ADD
        fp32_adder
        u_adder (
              .aresetn              ( reset_n      )
            , .aclk                 ( clk          )
            , .s_axis_a_tready      ( in_ready_A   )
            , .s_axis_a_tvalid      ( in_valid     )
            , .s_axis_a_tdata       ( in_data_A    )
            , .s_axis_a_tuser       ( in_user      )
            , .s_axis_a_tlast       ( in_last      )
            , .s_axis_b_tready      ( in_ready_B   )
            , .s_axis_b_tvalid      ( in_valid     )
            , .s_axis_b_tdata       ( in_data_B    )
            , .s_axis_b_tuser       ( in_user      )
            , .s_axis_b_tlast       ( in_last      )
            , .m_axis_result_tvalid ( tmp_valid    )
            , .m_axis_result_tready ( tmp_ready    )
            , .m_axis_result_tdata  ( tmp_data     )
            , .m_axis_result_tuser  ({tmp_user,tmp_overflow})
            , .m_axis_result_tlast  ( tmp_last     )
        );
    end else if (N==16) begin : FP16_ADD
        fp16_adder
        u_adder (
              .aresetn              ( reset_n      )
            , .aclk                 ( clk          )
            , .s_axis_a_tready      ( in_ready_A   )
            , .s_axis_a_tvalid      ( in_valid     )
            , .s_axis_a_tdata       ( in_data_A    )
            , .s_axis_a_tlast       ( in_last      )
            , .s_axis_b_tready      ( in_ready_A   )
            , .s_axis_b_tvalid      ( in_valid     )
            , .s_axis_b_tdata       ( in_data_B    )
            , .s_axis_b_tlast       ( in_last      )
            , .m_axis_result_tvalid ( tmp_valid    )
            , .m_axis_result_tready ( tmp_ready    )
            , .m_axis_result_tdata  ( tmp_data     )
            , .m_axis_result_tuser  ({tmp_user,tmp_overflow})
            , .m_axis_result_tlast  ( tmp_last     )
        );
    end
    endgenerate
    //--------------------------------------------------------------------------
    wire [N-1:0] MAX_POS={1'b0,{E{1'b1}},1'b1,{F-1{1'b0}}};
    wire [N-1:0] MAX_NEG={1'b1,{E{1'b1}},1'b1,{F-1{1'b0}}};
    //--------------------------------------------------------------------------
    always @ ( * ) begin
        out_overflow = tmp_overflow; // overflow
        out_user = tmp_user[B-1:0];
        if (tmp_overflow) begin
            if (tmp_data[N-1]) out_data = MAX_NEG;
            else out_data = MAX_POS;
        end else begin
            out_data = tmp_data;
        end
    end
    //--------------------------------------------------------------------------
    assign tmp_ready = out_ready;
    assign out_valid = tmp_valid;
    assign out_last  = tmp_last ;
    //--------------------------------------------------------------------------
    // synthesis translate_off
    shortreal in_data_A_float;
    shortreal in_data_B_float;
    shortreal out_data_float ;
    always @ ( * ) begin
        in_data_A_float = $bitstoshortreal(in_data_A);
        in_data_B_float = $bitstoshortreal(in_data_B);
        out_data_float  = $bitstoshortreal(out_data );
    end
    // synthesis translate_on
    //--------------------------------------------------------------------------
endmodule

//------------------------------------------------------------------------------
module mac_core_accumulator
     #(parameter N=32, B=N/8)
(
      input  wire          clk
    , input  wire          reset_n
    , output wire          in_ready
    , input  wire          in_valid
    , input  wire [N-1:0]  in_data
    , input  wire [B-1:0]  in_user
    , input  wire          in_last
    , input  wire          out_ready
    , output reg           out_valid
    , output reg  [N-1:0]  out_data
    , output reg  [B-1:0]  out_user
    , output reg           out_last
    , output reg           out_overflow
);
    //--------------------------------------------------------------------------
    localparam E=(N==32) ? 8 : (N==16) ? 5 : 0
             , F= N-(E+1);
    //--------------------------------------------------------------------------
    reg           acc_out_ready   ;
    wire          acc_out_valid   ;
    wire [N-1:0]  acc_out_data    ;
    wire [B-1:0]  acc_out_user    ;
    wire          acc_out_last    ;
    wire [1:0]    acc_out_overflow; //[1]=output_overflow, [0]=input_overflow
    //--------------------------------------------------------------------------
    // Xilinx, PG060, "Floating-Point Operator v71."
    // [Starting a New Accumulation]
    // A floating-point number on the A channel is the first in a new accumulation when either of
    // the following conditions are true:
    // • It is the first summand after aresetn has been asserted and released.
    // • It is the first summand after s_axis_a_tlast has been asserted on a valid AXI transfer.
    // When a new accumulation starts, the exceptions are cleared, the accumulator register is set
    // to zero, and the new summand is combined (added or subtracted) with zero.
    // [Overflow]
    // The accumulator operator adds two non-standard exception flags: Accumulator Input
    // Overflow, and Accumulator Overflow.
    generate
    if (N==32) begin : FP32_ACC
        fp32_accumulator
        u_accumulator (
              .aresetn               ( reset_n          )
            , .aclk                  ( clk              )
            , .s_axis_a_tvalid       ( in_valid         )
            , .s_axis_a_tready       ( in_ready         )
            , .s_axis_a_tdata        ( in_data          )
            , .s_axis_a_tuser        ( in_user          )
            , .s_axis_a_tlast        ( in_last          )
            , .m_axis_result_tvalid  ( acc_out_valid    )
            , .m_axis_result_tready  ( acc_out_ready    )
            , .m_axis_result_tdata   ( acc_out_data     )
            , .m_axis_result_tuser   ({acc_out_user,acc_out_overflow})
            , .m_axis_result_tlast   ( acc_out_last     )
        );
    end else if (N==16) begin : FP16_ACC
        fp16_accumulator
        u_accumulator (
              .aresetn               ( reset_n          )
            , .aclk                  ( clk              )
            , .s_axis_a_tvalid       ( in_valid         )
            , .s_axis_a_tready       ( in_ready         )
            , .s_axis_a_tdata        ( in_data          )
            , .s_axis_a_tuser        ( in_user          )
            , .s_axis_a_tlast        ( in_last          )
            , .m_axis_result_tvalid  ( acc_out_valid    )
            , .m_axis_result_tready  ( acc_out_ready    )
            , .m_axis_result_tdata   ( acc_out_data     )
            , .m_axis_result_tuser   ({acc_out_user,acc_out_overflow})
            , .m_axis_result_tlast   ( acc_out_last     )
        );
    end
    endgenerate
    //--------------------------------------------------------------------------
    wire [N-1:0] MAX_POS={1'b0,{E{1'b1}},1'b1,{F-1{1'b0}}};
    wire [N-1:0] MAX_NEG={1'b1,{E{1'b1}},1'b1,{F-1{1'b0}}};
    //--------------------------------------------------------------------------
    always @ ( * ) begin
        acc_out_ready = out_ready;
        out_valid     = acc_out_valid;
        out_last      = acc_out_last;
        out_user      = acc_out_user;
        out_overflow  = |acc_out_overflow; // overflow
        if (|acc_out_overflow) begin
            if (acc_out_data[N-1]) out_data = MAX_NEG;
            else out_data = MAX_POS;
        end else begin
            out_data = acc_out_data;
        end
    end
endmodule

//------------------------------------------------------------------------------
// Floating-point 32-bit (Single-precision): 1-bit sign, 8-bit exponent, 23-bit fraction
// Floating-point 16-bit (half-precision): 1-bit sign, 5-bit exponent, 10-bit fraction
// Floating-point 8-bit (mini-precision): 1-bit sign, 4-bit exponent, 3-bit fraction
//
//                  (mantissa)
//   +-+----------+------------+
//   |S| exponent | fraction   |
//   +-+----------+------------+
module mac_core_compare
     #(parameter N=32
               , BIT_SIGN =N-1
               , BITS_EXP =(N==32) ? 8 :
                           (N==16) ? 5 :
                           (N== 8) ? 4 : (N/2)-1
               , BITS_MAN =N-1-BITS_EXP)
(
      input  wire [N-1:0] in_data_A
    , input  wire [N-1:0] in_data_B
    , output wire         out_AeqB
    , output wire         out_AgtB // A is greater than B
    , output wire         out_AltB // A is less than B
);
    //--------------------------------------------------------------------------
    wire                A_sign=in_data_A[BIT_SIGN];
    wire [BITS_EXP-1:0] A_exp =in_data_A[BITS_MAN +: BITS_EXP];
    wire [BITS_MAN-1:0] A_man =in_data_A[BITS_MAN-1:0];
    wire                B_sign=in_data_B[BIT_SIGN];
    wire [BITS_EXP-1:0] B_exp =in_data_B[BITS_MAN +: BITS_EXP];
    wire [BITS_MAN-1:0] B_man =in_data_B[BITS_MAN-1:0];
    //--------------------------------------------------------------------------
    wire eq_sign = (A_sign==B_sign);
    wire gt_sign = (~A_sign& B_sign); // A positive
    wire lt_sign = ( A_sign&~B_sign); // A negative
    wire eq_exp  = (A_exp==B_exp);
    wire gt_exp  = (A_exp>B_exp);
    wire lt_exp  = (A_exp<B_exp);
    wire eq_man  = (A_man==B_man);
    wire gt_man  = (A_man>B_man);
    wire lt_man  = (A_man<B_man);
    //--------------------------------------------------------------------------
    assign out_AeqB = eq_sign & eq_exp & eq_man;
    assign out_AgtB = gt_sign | (eq_sign & gt_exp ) | (eq_sign & eq_exp & gt_man);
    assign out_AltB = lt_sign | (eq_sign & lt_exp ) | (eq_sign & eq_exp & lt_man);
    //--------------------------------------------------------------------------
endmodule
//------------------------------------------------------------------------------
// Revision history
//
// 2021.06.10: Started by Ando Ki.
//------------------------------------------------------------------------------
