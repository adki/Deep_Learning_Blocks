//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All right reserved.
//------------------------------------------------------------------------------
// VERSION: 2021.06.10.
//------------------------------------------------------------------------------
// Max-Pooling
//------------------------------------------------------------------------------
// Note:
//    all inputs and outputs are 2's complement signed value.
//
// TLAST makes clear internal data for accumulator.
//------------------------------------------------------------------------------
//              __    __    __    __    __    __    __
//  CLK      __|  |__|  |__|  |__|  |__|  |__|  |__|  |__
//             |_____|_____|_____|_____|     |
//  IN       XXX__a__X_____X_____X_____XXXXXXXXXXXX
//             |_____|_____|_____|_____|     |
//  VALID    __|                       |_____|____
//                                _____
//  LAST     ____________________|     |_____|____
//                                      _____ 
//  OUT      XXXXXXXXXXXXXXXXXXXXXXXXXXX_____XXXXX
//------------------------------------------------------------------------------

module pooling_max_core
     #(parameter DATA_TYPE="INTEGER"
               , DATA_WIDTH=32
               `ifdef DATA_FIXED_POINT
               , DATA_WIDTH_Q=(DATA_WIDTH/2) // fractional bits
               `endif
               )
(
      input  wire                     RESET_N // asynchronous reset
    , input  wire                     CLK
    , input  wire                     INIT  // synchronous reset
    , output reg                      READY // ready when 1
    // operand
    , `DBG_POOL output wire                     IN_READY
    , `DBG_POOL input  wire  [DATA_WIDTH-1:0]   IN_DATA
    , `DBG_POOL input  wire                     IN_VALID
    , `DBG_POOL input  wire                     IN_LAST
    // resultant
    , `DBG_POOL output reg   [DATA_WIDTH-1:0]   OUT_DATA
    , `DBG_POOL output reg                      OUT_VALID
    , `DBG_POOL input  wire                     OUT_READY
    , `DBG_POOL output reg                      OUT_LAST
);
    //--------------------------------------------------------------------------
    // synthesis translate_off
    initial begin
        if ((DATA_TYPE!="FIXED_POINT")&&(DATA_TYPE!="FLOATING_POINT")&&
            (DATA_TYPE!="INTEGER"))
           $display("%m ERROR unknown data type: %s.", DATA_TYPE);
    end
    // synthesis translate_on
    //--------------------------------------------------------------------------
    localparam N=DATA_WIDTH;
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
    wire signed [N-1:0] data=IN_DATA;
    reg  signed [N-1:0] reg_data={N{1'b0}};
    wire                enable;
    wire                AgtB;
    //--------------------------------------------------------------------------
    assign enable   = (OUT_READY==1'b1)||(OUT_VALID==1'b0);
    assign IN_READY = enable;
    //--------------------------------------------------------------------------
    localparam [N-1:0] MAX_NEGATIVE=(DATA_TYPE=="FIXED_POINT"   ) ? {1'b1,{N-1{1'b1}}}
                                   :(DATA_TYPE=="FLOATING_POINT") ? {1'b1,{N-1{1'b1}}}
                                   :{1'b1,{N-1{1'b0}}}; // 2's complement
    //--------------------------------------------------------------------------
    always @ ( posedge CLK or negedge RESET_N) begin
    if (RESET_N==1'b0) begin
        reg_data  <= {N{1'b0}};
        OUT_DATA  <= {N{1'b0}};
        OUT_VALID <= 1'b0;
        OUT_LAST  <= 1'b0;
    end else if (INIT==1'b1) begin
        reg_data  <= {N{1'b0}};
        OUT_DATA  <= {N{1'b0}};
        OUT_VALID <= 1'b0;
        OUT_LAST  <= 1'b0;
    end else begin
        if (enable) begin
            OUT_VALID <= IN_VALID;
            OUT_LAST  <= IN_LAST;
            if (IN_VALID&IN_READY) begin
                if (AgtB) begin
                    OUT_DATA <= data;
                    reg_data <= data;
                end else begin
                    OUT_DATA <= reg_data;
                end
                if (IN_LAST) reg_data <= MAX_NEGATIVE;
            end
        end
    end // if
    end // always
    //--------------------------------------------------------------------------
    mac_core_compare #(.N(DATA_WIDTH))
    u_compare (
          .in_data_A ( data     )
        , .in_data_B ( reg_data )
        , .out_AeqB  (          )
        , .out_AgtB  ( AgtB     )
        , .out_AltB  (          )
    );
endmodule

//------------------------------------------------------------------------------
// Revision history
//
// 2021.06.10: Started by Ando Ki.
//------------------------------------------------------------------------------
