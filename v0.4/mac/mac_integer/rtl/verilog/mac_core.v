//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All right reserved.
//------------------------------------------------------------------------------
// VERSION: 2021.08.01.
//------------------------------------------------------------------------------
// MAC (multiplier–accumulator)
//------------------------------------------------------------------------------
// Note:
//    all inputs and outputs are 2's complement signed value.
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
    localparam N=WIDTH_DATA;
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
    wire signed [N-1:0]   mul_in_data_A=IN_DATA_A;
    wire signed [N-1:0]   mul_in_data_B=IN_DATA_B;
    wire                  mul_in_valid=IN_VALID_A&IN_VALID_B;
    wire                  mul_in_ready;
    wire                  mul_in_last=mul_in_valid&IN_LAST_A&IN_LAST_B;
    wire signed [N*2-1:0] mul_out_data ;
    wire                  mul_out_valid;
    wire                  mul_out_ready;
    wire                  mul_out_last ;
    assign IN_READY_A = mul_in_ready&IN_VALID_B;
    assign IN_READY_B = mul_in_ready&IN_VALID_A;
    //--------------------------------------------------------------------------
    // It produces N*2-bit multiplication result of two N-bit inputs.
    // No overflow occrs.
    mac_core_multiplier_simple #(.N(N))
    u_multiplier (
          .clk       ( CLK           )
        , .reset_n   ( SRESETn       )
        , .in_data_A ( mul_in_data_A )
        , .in_data_B ( mul_in_data_B )
        , .in_valid  ( mul_in_valid  )
        , .in_ready  ( mul_in_ready  )
        , .in_last   ( mul_in_last   )
        , .out_data  ( mul_out_data  )
        , .out_valid ( mul_out_valid )
        , .out_ready ( mul_out_ready )
        , .out_last  ( mul_out_last  )
    );
    //--------------------------------------------------------------------------
    wire signed [N*2-1:0]  acc_in_data=mul_out_data;
    wire                   acc_in_valid=mul_out_valid;
    wire                   acc_in_ready;
    wire                   acc_in_last=mul_out_last;
    wire signed [N*2-1:0]  acc_out_data    ;
    wire                   acc_out_valid   ;
    wire                   acc_out_ready   ;
    wire                   acc_out_last    ;
    wire                   acc_out_overflow;
    assign mul_out_ready=acc_in_ready;
    //--------------------------------------------------------------------------
    // It produces N*2+1-bit accumulation result of a series of N*2+1-bit inputs.
    // Internal storage is clear when LAST is 1.
    mac_core_accumulator #(.N(N*2))
    u_accumulator (
          .clk          ( CLK              )
        , .reset_n      ( SRESETn          )
        , .in_ready     ( acc_in_ready     )
        , .in_valid     ( acc_in_valid     )
        , .in_data      ( acc_in_data      )
        , .in_user      ( 'h0              )
        , .in_last      ( acc_in_last      )
        , .out_ready    ( acc_out_ready    )
        , .out_valid    ( acc_out_valid    )
        , .out_data     ( acc_out_data     )
        , .out_user     (                  )
        , .out_last     ( acc_out_last     )
        , .out_overflow ( acc_out_overflow )
    );
    //--------------------------------------------------------------------------
    wire signed [N-1:0] MAX_POS={1'b0,{N-1{1'b1}}};
    wire signed [N-1:0] MAX_NEG={1'b1,{N-1{1'b0}}};
    //--------------------------------------------------------------------------
    always @ ( * ) begin
        if (acc_out_overflow) begin
            OUT_OVERFLOW= acc_out_valid; // overflow
            if (acc_out_data[N*2-1]) OUT_DATA = MAX_NEG;
            else OUT_DATA = MAX_POS;
        end else begin
            if (acc_out_data>MAX_POS) begin
                OUT_DATA = MAX_POS;
                OUT_OVERFLOW = acc_out_valid; // overflow
            end else if (acc_out_data<MAX_NEG) begin
                OUT_DATA = MAX_NEG;
                OUT_OVERFLOW = acc_out_valid; // overflow
            end else begin
                OUT_DATA = acc_out_data[N-1:0];
                OUT_OVERFLOW = 1'b0;
            end
        end
    end
    //--------------------------------------------------------------------------
    assign acc_out_ready = OUT_READY;
    assign OUT_VALID = acc_out_valid;
    assign OUT_LAST  = acc_out_last ;
    //--------------------------------------------------------------------------
endmodule

//------------------------------------------------------------------------------
// It produces N*2-bit multiplication result of two N-bit inputs.
//------------------------------------------------------------------------------
//              __    __    __    __    __    __    __
//  clk      __|  |__|  |__|  |__|  |__|  |__|  |__|  |__
//             |_____|_____|     |_____|
//  A/B      XXX__a__X_____XXXXXXX_____X
//             |     |     |_____|_____|
//  C        XXXXXXXXXXXXXXX__a'_X_____X
//
module mac_core_multiplier_reg
     #(parameter N=32)
(
      input  wire                   clk
    , input  wire                   reset_n
    , input  wire signed [N-1:0]    in_data_A
    , input  wire signed [N-1:0]    in_data_B
    , input  wire                   in_valid
    , output wire                   in_ready
    , input  wire                   in_last
    , output wire signed [N*2-1:0]  out_data
    , output wire                   out_valid
    , input  wire                   out_ready
    , output wire                   out_last
);
    //--------------------------------------------------------------------------
    localparam ST_ZERO='h0
             , ST_ONE ='h1
             , ST_TWO ='h2;
    reg [1:0] state=ST_ZERO;
    reg [1:0] next;
    //--------------------------------------------------------------------------
    // state
    always @ (posedge clk or negedge reset_n) begin
    if (reset_n==1'b0) state <= ST_ZERO;
    else state <= next;
    end // always
    //--------------------------------------------------------------------------
    // next state
    always @ (*) begin
    case (state)
    ST_ZERO: if (in_valid&in_ready) next = ST_ONE;
             else                   next = ST_ZERO;
    ST_ONE :      if (~in_valid& out_ready) next = ST_ZERO;
             else if ( in_valid&~out_ready) next = ST_TWO;
             else                           next = ST_ONE;
    ST_TWO : if (out_ready) next = ST_ONE;
             else           next = ST_TWO;
    default: next = ST_ZERO;
    endcase
    end // always
    //--------------------------------------------------------------------------
    wire [N*2-1:0] mul = in_data_A * in_data_B;
    wire           load_p1, load_p2, load_p1_from_p2;
    reg            in_ready_t;
    reg  [N*2:0]   data_p1='h0;
    reg  [N*2:0]   data_p2='h0;
    always @ (posedge clk) begin
    if (load_p2) data_p2 <= {in_last,mul};
    if (load_p1) begin
        if (load_p1_from_p2) data_p1 <= data_p2;
        else                 data_p1 <= {in_last,mul};
    end
    end // always
    //--------------------------------------------------------------------------
    assign in_ready = in_ready_t;
    assign {out_last,out_data}=data_p1;
    assign out_valid=state[0];
    assign load_p1 = ((state==ST_ZERO)&& in_valid) ||
                     ((state==ST_ONE)&& in_valid && out_ready) ||
                     ((state==ST_TWO)&& out_ready);
    assign load_p2 = in_valid & in_ready;
    assign load_p1_from_p2 = (state == ST_TWO);
    //--------------------------------------------------------------------------
    // in_ready_t
    always @ (posedge clk or negedge reset_n) begin
             if (reset_n==1'b0) in_ready_t <= 1'b0;
        else if (state==ST_ZERO) in_ready_t <= 1'b1;
        else if ((state==ST_ONE)&&(next==ST_TWO)) in_ready_t <= 1'b0;
        else if ((state==ST_TWO)&&(next==ST_ONE)) in_ready_t <= 1'b1;
    end
    //--------------------------------------------------------------------------
endmodule

//------------------------------------------------------------------------------
// It uses sufficient output-bit in order not to get overflow.
module mac_core_multiplier_simple
     #(parameter N=32)
(
      input  wire                   clk
    , input  wire                   reset_n
    , input  wire signed [N-1:0]    in_data_A
    , input  wire signed [N-1:0]    in_data_B
    , input  wire                   in_valid
    , output wire                   in_ready
    , input  wire                   in_last
    , output reg  signed [N*2-1:0]  out_data
    , output reg                    out_valid
    , input  wire                   out_ready
    , output reg                    out_last
);
    //--------------------------------------------------------------------------
    wire signed [N*2-1:0] inA = in_data_A;
    wire signed [N*2-1:0] inB = in_data_B;
    wire signed [N*2-1:0] mul = inA*inB;
    wire                  enable;
    //--------------------------------------------------------------------------
    assign enable = (out_ready==1'b1) // when receiver is ready
                  ||(out_valid==1'b0);// when empty
    assign in_ready = ~out_valid|out_ready;
    //--------------------------------------------------------------------------
    always @ (posedge clk) begin
    if (reset_n==1'b0) begin
        out_data  <= {N*2{1'b0}};
        out_valid <= 1'b0;
        out_last  <= 1'b0;
    end else begin
        if (enable) begin
            out_data    <= mul;
            out_valid   <= in_valid;
            out_last    <= in_last;
        end
    end // if
    end // always
    //--------------------------------------------------------------------------
endmodule

//------------------------------------------------------------------------------
// 'in_user[]' can be 'strobe[]', but 'in_user[]' does not work as strobe.
// It simply passes through.
module mac_core_multiplier
     #(parameter N=32, B=N/8)
(
      input  wire                   clk
    , input  wire                   reset_n
    , output wire                   in_ready
    , input  wire                   in_valid
    , input  wire signed [N-1:0]    in_data_A
    , input  wire signed [N-1:0]    in_data_B
    , input  wire        [B-1:0]    in_user
    , input  wire                   in_last
    , input  wire                   out_ready
    , output reg                    out_valid
    , output reg  signed [N-1:0]    out_data
    , output reg         [B-1:0]    out_user
    , output reg                    out_last
    , output reg                    out_overflow
);
    //--------------------------------------------------------------------------
    localparam [N-1:0] MAX_POSITIVE={1'b0,{N-1{1'b1}}};
    localparam [N-1:0] MAX_NEGATIVE={1'b1,{N-1{1'b0}}};
    //--------------------------------------------------------------------------
    wire signed [N-1:0] max_positive=MAX_POSITIVE;
    wire signed [N-1:0] max_negative=MAX_NEGATIVE;
    wire signed [N*2-1:0] inA = in_data_A;
    wire signed [N*2-1:0] inB = in_data_B;
    wire signed [N*2-1:0] mul = inA*inB;
    wire                  enable;
    //--------------------------------------------------------------------------
    assign enable = (out_ready==1'b1) // when receiver is ready
                  ||(out_valid==1'b0);// when empty
    assign in_ready = ~out_valid|out_ready;
    wire   overflow = (mul>max_positive)||(mul<max_negative);
    //--------------------------------------------------------------------------
    always @ (posedge clk) begin
    if (reset_n==1'b0) begin
        out_data     <= {N{1'b0}};
        out_user     <= {B{1'b0}};
        out_valid    <= 1'b0;
        out_last     <= 1'b0;
        out_overflow <= 1'b0;
    end else begin
        if (enable) begin
            out_data     <= (mul>max_positive) ? MAX_POSITIVE
                          : (mul<max_negative) ? MAX_NEGATIVE
                          : mul[N-1:0];
            out_user     <= in_user;
            out_overflow <= overflow;
            out_valid    <= in_valid;
            out_last     <= in_last;
        end
    end // if
    end // always
    //--------------------------------------------------------------------------
endmodule

//------------------------------------------------------------------------------
// The result changes depending on whether the bias is used as the initial value of the operation or is processed after the operation.
// - If bias is applied after calculation, there is a change in saturation due to overflow.
module mac_core_adder
     #(parameter N=32, B=N/8)
(
      input  wire           reset_n
    , input  wire           clk
    , output wire           in_ready
    , input  wire           in_valid
    , input  wire [N-1:0]   in_data_A
    , input  wire [N-1:0]   in_data_B
    , input  wire [B-1:0]   in_user // can be byte strobe
    , input  wire           in_last
    , input  wire           out_ready
    , output reg            out_valid
    , output reg  [N-1:0]   out_data
    , output reg  [B-1:0]   out_user // can be byte strobe
    , output reg            out_last
    , output reg            out_overflow
);
    //--------------------------------------------------------------------------
    localparam [N-1:0] MAX_POSITIVE={1'b0,{N-1{1'b1}}};
    localparam [N-1:0] MAX_NEGATIVE={1'b1,{N-1{1'b0}}};
    //--------------------------------------------------------------------------
    wire [N:0] tmp_sum = $signed(in_data_A)+$signed(in_data_B);
    //--------------------------------------------------------------------------
    wire         tmp_over = ((~in_data_A[N-1]&~in_data_B[N-1])& tmp_sum[N-1]) // (+)+(+)-->(-)
                          | (( in_data_A[N-1]& in_data_B[N-1])&~tmp_sum[N-1]);// (-)+(-)-->(+)
    wire [N-1:0] tmp_data =  (tmp_over==1'b0) ? tmp_sum[N-1:0]
                                              : in_data_A[N-1] ? MAX_NEGATIVE
                                                               : MAX_POSITIVE;
    //--------------------------------------------------------------------------
    wire   enable   =  out_ready|~out_valid;
    assign in_ready = ~out_valid| out_ready;
    //--------------------------------------------------------------------------
    always @ (posedge clk) begin
    if (reset_n==1'b0) begin
        out_data  <= {N{1'b0}};
        out_user  <= {B{1'b0}};
        out_valid <= 1'b0;
        out_last  <= 1'b0;
        out_overflow <= 1'b0;
    end else begin
        if (enable) begin
            out_data     <= tmp_data;
            out_user     <= in_user ;
            out_overflow <= tmp_over;
            out_valid    <= in_valid;
            out_last     <= in_last ;
        end
    end // if
    end // always
    //--------------------------------------------------------------------------
endmodule
module mac_core_adder_old
     #(parameter N=32)
(
      input  wire         reset_n
    , input  wire         clk
    , output wire         in_ready
    , input  wire         in_valid
    , input  wire         in_last
    , input  wire [N-1:0] in_data_A
    , input  wire [N-1:0] in_data_B
    , input  wire         in_overflow_A
    , input  wire         in_overflow_B
    , input  wire         out_ready
    , output reg          out_valid
    , output reg          out_last
    , output reg  [N-1:0] out_data
    , output reg          out_overflow
);
    //--------------------------------------------------------------------------
    localparam [N-1:0] MAX_POSITIVE={1'b0,{N-1{1'b1}}};
    localparam [N-1:0] MAX_NEGATIVE={1'b1,{N-1{1'b0}}};
    //--------------------------------------------------------------------------
    wire [N:0] tmp_sum = $signed(in_data_A)+$signed(in_data_B);
    //--------------------------------------------------------------------------
    wire         tmp_over = ((~in_data_A[N-1]&~in_data_B[N-1])& tmp_sum[N-1]) // (+)+(+)-->(-)
                          | (( in_data_A[N-1]& in_data_B[N-1])&~tmp_sum[N-1]);// (-)+(-)-->(+)
    wire [N-1:0] tmp_data =  (tmp_over==1'b0) ? tmp_sum[N-1:0]
                                              : in_data_A[N-1] ? MAX_NEGATIVE
                                                               : MAX_POSITIVE;
    //--------------------------------------------------------------------------
    wire   enable   =  out_ready|~out_valid;
    assign in_ready = ~out_valid| out_ready;
    //--------------------------------------------------------------------------
    always @ (posedge clk) begin
    if (reset_n==1'b0) begin
        out_data  <= {N{1'b0}};
        out_valid <= 1'b0;
        out_last  <= 1'b0;
        out_overflow <= 1'b0;
    end else begin
        if (enable) begin
            out_data  <=(in_overflow_A) ? in_data_A :
                        (in_overflow_B) ? in_data_B : tmp_data;
            out_overflow <=(tmp_over|in_overflow_A|in_overflow_B)&in_valid;
            out_valid    <= in_valid;
            out_last  <= in_last;
        end
    end // if
    end // always
    //--------------------------------------------------------------------------
endmodule

//------------------------------------------------------------------------------
module mac_core_adder_combinational
     #(parameter N=32)
(
      input  wire signed [N-1:0] inA
    , input  wire signed [N-1:0] inB
    , output wire signed [N-1:0] out
    , output wire                over
);
    //--------------------------------------------------------------------------
    localparam [N-1:0] MAX_POSITIVE={1'b0,{N-1{1'b1}}};
    localparam [N-1:0] MAX_NEGATIVE={1'b1,{N-1{1'b0}}};
    //--------------------------------------------------------------------------
    wire signed [N:0] sum = inA+inB;
    //--------------------------------------------------------------------------
    assign over = ((~inA[N-1]&~inB[N-1])& sum[N-1]) // (+)+(+)-->(-)
                | (( inA[N-1]& inB[N-1])&~sum[N-1]);// (-)+(-)-->(+)
    assign out  =  (over==1'b0) ? sum[N-1:0]
                                : inA[N-1] ? MAX_NEGATIVE
                                           : MAX_POSITIVE;
endmodule

//------------------------------------------------------------------------------
// Make sure 'in_data' be zeror, if non-valid input is given.
module mac_core_accumulator
     #(parameter N=32, B=N/8)
(
      input  wire                 clk
    , input  wire                 reset_n
    , output wire                 in_ready
    , input  wire                 in_valid
    , input  wire signed [N-1:0]  in_data
    , input  wire        [B-1:0]  in_user
    , input  wire                 in_last
    , input  wire                 out_ready
    , output reg                  out_valid
    , output reg  signed [N-1:0]  out_data
    , output reg         [B-1:0]  out_user
    , output reg                  out_last
    , output reg                  out_overflow
);
    //--------------------------------------------------------------------------
    reg   [N-1:0]  reg_data={N{1'b0}};
    wire           enable;
    wire  [N-1:0]  value ;
    wire           over  ;
    //--------------------------------------------------------------------------
    assign enable = (out_ready==1'b1) // when receiver is ready
                  ||(out_valid==1'b0);// when empty
    assign in_ready = ~out_valid|out_ready;
    assign {over,value}=func_adder(in_data,reg_data);
    //--------------------------------------------------------------------------
    always @ (posedge clk) begin
    if (reset_n==1'b0) begin
        reg_data     <= {N{1'b0}};
        out_valid    <= 1'b0;
        out_user     <= {B{1'b0}};
        out_last     <= 1'b0;
        out_overflow <= 1'b0;
    end else begin
        if (enable) begin
            out_valid    <= in_valid;
            out_user     <= in_user ;
            out_last     <= in_last;
            out_overflow <= over&in_valid;
            if (in_valid&in_ready) begin
                out_data <= value;
                if (in_last) begin
                    reg_data <= {N{1'b0}};
                end else begin
                    reg_data <= value;
                end
            end
        end
    end // if
    end // always
    //--------------------------------------------------------------------------
    localparam [N-1:0] MAX_POSITIVE={1'b0,{N-1{1'b1}}}; // mind 2's complement
    localparam [N-1:0] MAX_NEGATIVE={1'b1,{N-1{1'b0}}}; // mind 2's complement
    //--------------------------------------------------------------------------
    // combinational logic
    function [N:0] func_adder;
        input [N-1:0] inA;
        input [N-1:0] inB;
        reg   [N-1:0] out ;
        reg           over;
        reg signed [N:0] sum ;
    begin
        sum = $signed(inA)+$signed(inB);
        over = ((~inA[N-1]&~inB[N-1])& sum[N-1]) // (+)+(+)-->(-)
             | (( inA[N-1]& inB[N-1])&~sum[N-1]);// (-)+(-)-->(+)
        out  =  (over==1'b0) ? sum[N-1:0]
                             : inA[N-1] ? MAX_NEGATIVE
                                        : MAX_POSITIVE;
        func_adder = {over,out};
    end
    endfunction
    //--------------------------------------------------------------------------
endmodule

//------------------------------------------------------------------------------
module mac_core_compare
     #(parameter N=32)
(
      input  wire signed [N-1:0] in_data_A
    , input  wire signed [N-1:0] in_data_B
    , output wire                out_AeqB
    , output wire                out_AgtB
    , output wire                out_AltB
);
    assign out_AeqB = (in_data_A==in_data_B);
    assign out_AgtB = (in_data_A>in_data_B); 
    assign out_AltB = (in_data_A<in_data_B);
endmodule
//------------------------------------------------------------------------------
// Revision history
//
// 2021.08.01: 'in_overflowA/B' added for 'mac_core_adder'.
// 2021.06.10: Started by Ando Ki.
//------------------------------------------------------------------------------
