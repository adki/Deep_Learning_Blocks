//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki
// All right reserved.
//
// http://www.future-ds.com
// adki@future-ds.com
//------------------------------------------------------------------------------
`timescale 1ns/1ps

module tester
     #(parameter N=32)
(
      input   wire           RESET_N
    , input   wire           CLK
    , input   wire           IN_READY_A
    , output  reg   [N-1:0]  IN_DATA_A='h0
    , output  reg            IN_VALID_A=1'b0
    , output  reg            IN_LAST_A=1'b0
    , input   wire           IN_READY_B
    , output  reg   [N-1:0]  IN_DATA_B='h0
    , output  reg            IN_VALID_B=1'b0
    , output  reg            IN_LAST_B=1'b0
    , input   wire  [N-1:0]  OUT_MAC_DATA
    , input   wire           OUT_MAC_VALID
    , output  reg            OUT_MAC_READY=1'b0
    , input   wire           OUT_MAC_LAST
    , input   wire           OUT_MAC_OVERFLOW
);
    //--------------------------------------------------------------------------
    localparam  E=(N==32) ? 8 : (N==16) ? 5 : 0
              , F= N-(E+1);
    //--------------------------------------------------------------------------
    wire [N-1:0] MAX_POS={1'b0,{E{1'b1}},1'b1,{F-1{1'b1}}}; // {1'b0,{N-1{1'b1}}}
    wire [N-1:0] MAX_NEG={1'b1,{E{1'b1}},1'b1,{F-1{1'b1}}}; // {1'b0,{N-1{1'b1}}}
    //--------------------------------------------------------------------------
    reg done=1'b0;
    //--------------------------------------------------------------------------
    initial begin
            done = 1'b0;
            wait(RESET_N==1'b0);
            wait(RESET_N==1'b1);
            repeat (10) @ (posedge CLK);
            if (N==32) begin
                test_shortreal(10); // single-precision FP (32-bit)
            end else begin
                test_halfreal(10); // half-precision FP (16-bit)
            end
            repeat (10) @ (posedge CLK);
            done = 1'b1;
    end
    //-------------------------------------------------------------------------
    localparam MAX_NUM=1024;
    reg [N*MAX_NUM-1:0] valueA;
    reg [N*MAX_NUM-1:0] valueB;
    reg [N*MAX_NUM-1:0] valueC;
    reg [N*MAX_NUM-1:0] expected_mac;
    reg [N*MAX_NUM-1:0] expected_add;
    //-------------------------------------------------------------------------
    task test_shortreal; // 32-bit single precision floating-point [1:8:23]
        input integer num;
        integer   rep, ind, error;
        shortreal svalue, add, sum;
        reg [N-1:0] bits;
        shortreal sv, se, sd;
    begin
        rep = 2;
        sum = 0;
        for (ind=0; ind<num; ind=ind+1) begin
             svalue = ind+ind*0.1+ind*0.01;
             bits = $shortrealtobits(svalue);
             valueA[ind*N +: N] = bits;
             valueB[ind*N +: N] = bits;
             add = (svalue*svalue);
             sum = sum + add;
             expected_mac[ind*N +: N] = $shortrealtobits(sum);
             expected_add[ind*N +: N] = $shortrealtobits(add);
#(1);
        end
        drive_and_receive(valueA, valueB, valueC, num, rep);
        error = 0;
        for (ind=0; ind<num; ind = ind+1) begin
            sv = $bitstoshortreal(valueC[ind*N +: N]);
            se = $bitstoshortreal(expected_mac[ind*N +: N]);
            if (sv>se) sd = sv - se;
            else       sd = se - sv;
            if (sd>0.01) begin
                error = error + 1;
                $display("%0t %m ERROR %f, but %f expected.", $time, sv, se);
            end
        end
        if (error>0) $display("%m mis-match %d out of %d\n", error, num*rep);
        else         $display("%m OK %d\n", num*rep);
    end
    endtask
    //-------------------------------------------------------------------------
    task test_halfreal; // 16-bit single precision floating-point [1:5:10]
        input integer num;
        integer   rep, ind, error;
        shortreal svalue, add, sum;
        reg [N-1:0] bits;
        shortreal hv, he, hd;
    begin
        rep = 2; // repeat
        sum = 0;
        for (ind=0; ind<num; ind=ind+1) begin
             svalue = ind+ind*0.1+ind*0.01;
             bits = shortrealtohbits(svalue);
             valueA[ind*N +: N] = bits;
             valueB[ind*N +: N] = bits;
             add = (svalue*svalue);
             sum = sum + add;
             expected_mac[ind*N +: N] = shortrealtohbits(sum);
             expected_add[ind*N +: N] = shortrealtohbits(add);
#(1);
        end
        drive_and_receive(valueA, valueB, valueC, num, rep);
        error = 0;
        for (ind=0; ind<num; ind = ind+1) begin
            hv = hbitstoshortreal(valueC[ind*N +: N]);
            he = hbitstoshortreal(expected_mac[ind*N +: N]);
            if (hv>he) hd = hv - he;
            else       hd = he - hv;
            if (hd>0.1) begin
                error = error + 1;
                $display("%0t %m ERROR %f, but %f expected.", $time, hv, he);
            end
        end
        if (error>0) $display("%m mis-match %d out of %d\n", error, num*rep);
        else         $display("%m OK %d\n", num*rep);
    end
    endtask
    //-------------------------------------------------------------------------
    task drive_and_receive;
        input  [N*MAX_NUM-1:0] inA;
        input  [N*MAX_NUM-1:0] inB;
        output [N*MAX_NUM-1:0] out;
        input integer num;
        input integer rep;
        integer ida, idb, idc;
        integer idx, idy, idz;
    begin
        @ (posedge CLK);
        fork begin
                 for (ida=0; ida<rep; ida=ida+1) begin
                 for (idx=0; idx<num; idx=idx+1) begin
                     IN_DATA_A  = inA[idx*N +: N];
                     IN_VALID_A = 1'b1;
                     IN_LAST_A  = ((idx+1)==num) ? 1'b1 : 1'b0;
                     @ (posedge CLK);
                     while (IN_READY_A==1'b0) @ (posedge CLK);
                     IN_VALID_A = 1'b0;
                     IN_LAST_A  = 1'b0;
                 end // for
                 end // for
             end
             begin
                 for (idb=0; idb<rep; idb=idb+1) begin
                 for (idy=0; idy<num; idy=idy+1) begin
                     IN_DATA_B  = inB[idy*N +: N];
                     IN_VALID_B = 1'b1;
                     IN_LAST_B  = ((idy+1)==num) ? 1'b1 : 1'b0;
                     @ (posedge CLK);
                     while (IN_READY_B==1'b0) @ (posedge CLK);
                     IN_VALID_B = 1'b0;
                     IN_LAST_B  = 1'b0;
                 end // for
                 end // for
             end
             begin
                 for (idc=0; idc<rep; idc=idc+1) begin
                 for (idz=0; idz<num; idz=idz+1) begin
                     OUT_MAC_READY = 1'b1;
                     @ (posedge CLK);
                     while (OUT_MAC_VALID==1'b0) @ (posedge CLK);
                     out[idz*N +: N] = OUT_MAC_DATA;
                 end // for (idz
                 end // for (idc
                 OUT_MAC_READY = 1'b0;
             end
        join
    end
    endtask
    //--------------------------------------------------------------------------
    shortreal IN_DATA_A_FP32;
    shortreal IN_DATA_B_FP32;
    shortreal OUT_MAC_DATA_FP32;
    always @ ( * ) begin
        if (N==32) begin
            IN_DATA_A_FP32    = $bitstoshortreal(IN_DATA_A);
            IN_DATA_B_FP32    = $bitstoshortreal(IN_DATA_B);
            OUT_MAC_DATA_FP32 = $bitstoshortreal(OUT_MAC_DATA );
        end else if (N==16) begin
            IN_DATA_A_FP32    = hbitstoshortreal(IN_DATA_A);
            IN_DATA_B_FP32    = hbitstoshortreal(IN_DATA_B);
            OUT_MAC_DATA_FP32 = hbitstoshortreal(OUT_MAC_DATA );
        end
    end
    //-------------------------------------------------------------------------
    `include "float.sv"
    //-------------------------------------------------------------------------
endmodule
//-----------------------------------------------------------------------------
// Revision history
//
// 2021.06.10: Re-written by Ando Ki (adki@future-ds.com)
//-----------------------------------------------------------------------------
