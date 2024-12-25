//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All right reserved.
//------------------------------------------------------------------------------
// VERSION: 2021.06.10.
//------------------------------------------------------------------------------
// activation function
//------------------------------------------------------------------------------

module linear_1d_activation
     #(parameter DATA_TYPE ="INTEGER" // "INTEGER", "FLOATING_POINT", "FIXED_POINT"
               , DATA_WIDTH=32
               `ifdef DATA_FIXED_POINT
               , DATA_WIDTH_Q=(DATA_WIDTH/2) // fractional bits
               `endif
               , USER_WIDTH=(DATA_WIDTH/8)
               , ACTIV_FUNC_BYPASS    =4'h0
               , ACTIV_FUNC_RELU      =4'h1
               , ACTIV_FUNC_LEAKY_RELU=4'h2
               , ACTIV_FUNC_SIGMOID   =4'h3
               , ACTIV_FUNC_TANH      =4'h4
               )
(
      input    wire                    RESET_N
    , input    wire                    CLK
    , input    wire  [ 3:0]            ACTIV_FUNC
    , input    wire  [DATA_WIDTH-1:0]  ACTIV_PARAM
    , output   wire                    IN_READY
    , input    wire                    IN_VALID
    , input    wire  [DATA_WIDTH-1:0]  IN_DATA
    , input    wire  [USER_WIDTH-1:0]  IN_USER
    , input    wire                    IN_LAST
    , input    wire                    OUT_READY
    , output   reg                     OUT_VALID
    , output   reg   [DATA_WIDTH-1:0]  OUT_DATA
    , output   reg   [USER_WIDTH-1:0]  OUT_USER
    , output   reg                     OUT_LAST
    , output   wire                    OUT_OVERFLOW
);
    //--------------------------------------------------------------------------
    assign OUT_OVERFLOW=1'b0;
    //--------------------------------------------------------------------------
    wire signed [DATA_WIDTH-1:0] in_value=IN_DATA;
    reg  signed [DATA_WIDTH-1:0] value;
    wire   enable  = OUT_READY|~OUT_VALID;
    assign IN_READY=~OUT_VALID| OUT_READY;
    //--------------------------------------------------------------------------
    always @ (posedge CLK) begin
    if (RESET_N==1'b0) begin
        OUT_DATA  <=  'h0;
        OUT_USER  <=  'h0;
        OUT_VALID <= 1'b0;
        OUT_LAST  <= 1'b0;
    end else begin
        if (enable) begin
            OUT_DATA  <= value;
            OUT_USER  <= IN_USER;
            OUT_VALID <= IN_VALID;
            OUT_LAST  <= IN_LAST;
        end
    end // if
    end // always
    //--------------------------------------------------------------------------
    always @ ( * ) begin
        if (ACTIV_FUNC==ACTIV_FUNC_BYPASS) begin // bypass
            value = in_value;
        end else if (ACTIV_FUNC==ACTIV_FUNC_RELU) begin // ReLU
            value = func_relu(in_value);
        end else if (ACTIV_FUNC==ACTIV_FUNC_LEAKY_RELU) begin // LeakyReLU
            value = func_leaky_relu(in_value,ACTIV_PARAM);
        end else begin
            value = in_value;
        end
    end
    //--------------------------------------------------------------------------
    function [DATA_WIDTH-1:0] func_relu;
    input [DATA_WIDTH-1:0] value;
    begin
        if (DATA_TYPE=="FLOATING_POINT") begin // sing,exponent,fraction
            func_relu = (value[DATA_WIDTH-1]) ? {DATA_WIDTH{1'b0}} : value;
        end else if (DATA_TYPE=="FIXED_POINT") begin // sign-magnitude
            func_relu = (value[DATA_WIDTH-1]) ? {DATA_WIDTH{1'b0}} : value;
        end else begin // 2's complement integer
            func_relu = (value[DATA_WIDTH-1]) ? {DATA_WIDTH{1'b0}} : value;
        end
    end
    endfunction
    //--------------------------------------------------------------------------
    // floating point: 1/(10**param)
    // integer, fixed: 1/(2**param)
    function [DATA_WIDTH-1:0] func_leaky_relu;
    input [DATA_WIDTH-1:0] value;
    input [DATA_WIDTH-1:0] param;
    begin
        if (DATA_TYPE=="FLOATING_POINT") begin
            if (DATA_WIDTH==32) begin
                if (value[31]) begin
                    func_leaky_relu[31]    = value[31];
                    func_leaky_relu[30:23] =(value[30:23]>param[7:0]) ? value[30:23]-param[7:0] : 8'h0;
                    func_leaky_relu[22: 0] = value[22:0];
                end else begin
                    func_leaky_relu = value;
                end
            end else if (DATA_WIDTH==16) begin
                if (value[15]) begin
                    func_leaky_relu[15]    = value[15];
                    func_leaky_relu[14:10] =(value[14:10]>param[4:0]) ? value[14:10]-param[4:0] : 5'h0;
                    func_leaky_relu[ 9: 0] = value[ 9:0];
                end else begin
                    func_leaky_relu = value;
                end
            end else begin
                func_leaky_relu = (value[DATA_WIDTH-1]) ? {DATA_WIDTH{1'b0}} : value;
            end
        end else if (DATA_TYPE=="FIXED_POINT") begin // sign-magnitude
            func_leaky_relu = (value[DATA_WIDTH-1]) ? (value>>param) : value;
        end else begin // 2's complement integer
            func_leaky_relu = (value[DATA_WIDTH-1]) ? (value>>param) : value;
        end
    end
    endfunction
    //--------------------------------------------------------------------------
endmodule

//------------------------------------------------------------------------------
// Revision history
//
// 2021.06.10: Started by Ando Ki (andoki@gmail.com)
//------------------------------------------------------------------------------
