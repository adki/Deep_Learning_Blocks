`ifndef GPIF2SLV_TRX_AXI_TASKS_V
`define GPIF2SLV_TRX_AXI_TASKS_V
//------------------------------------------------------------------------------
// Copyright (c) 2018 by Future Design Systems.
// All right reserved.
//------------------------------------------------------------------------------
// gpif2slv_axi_tasks.v
//------------------------------------------------------------------------------
// VERSION: 2018.04.30.
//------------------------------------------------------------------------------
function [31:0] trx_cmd;
     input         write; // 1 for write, 0 for read
     input integer size ; // num of bytes
     input integer bleng; // burst length
     input [1:0]   btype; // burst type: 0:fixed, 1:inc, 2:wrap, 3:reserved
     input [2:0]   prot ;
     input [3:0]   cache;
     input [3:0]   tid  ; // transaction id
     input [1:0]   lkexc; // lock & exclusive
begin
     trx_cmd[   31] = 1'b0 ; // 0 for external, 1 for internal
     trx_cmd[   30] = write; // 0 for read, 1 for write
     trx_cmd[29:28] = lkexc;
     trx_cmd[27:25] = size>>1;
     trx_cmd[24:23] = btype;
     trx_cmd[22:20] = prot ; // protection
     trx_cmd[19:16] = cache;
     trx_cmd[15:12] = tid  ;
     trx_cmd[11: 0] = bleng-1; //(0=1-beat, N=(N+1)-beat)
end
endfunction
//------------------------------------------------------------------------------
task axi_write_one;
     input [31:0] addr;
     input [ 2:0] size; // num of bytes: 1, 2, 4
     input [31:0] data;
begin
     u2f_data[0] = {16'h2,4'b0010,4'h0,4'h0,4'h0};
     u2f_data[1] = trx_cmd(1'b1, size, 12'h1, 2'b1, 3'b0, 4'b0, 4'b1, 2'b0);
     u2f_data[2] = addr;
     u2f_data[3] = {16'h1,4'b0100,4'h0,4'h0,4'h0};
     gpif2_u2f_stream_core(16'h4,1'b0);

     u2f_data[0] = data;
     gpif2_u2f_stream_core(1, 0);
end
endtask
//------------------------------------------------------------------------------
task axi_read_one;
     input  [31:0] addr;
     input  [ 2:0] size; // num of bytes: 1, 2, 4
     output [31:0] data;
begin
     u2f_data[0] = {16'h2,4'b0010,4'h0,4'h0,4'h0};
     u2f_data[1] = trx_cmd(1'b0, size, 12'h1, 2'b1, 3'b0, 4'b0, 4'b1, 2'b0);
     u2f_data[2] = addr;
     u2f_data[3] = {16'h1,4'b0101,4'h0,4'h0,4'h0};
     gpif2_u2f_stream_core(16'h4,1'b0);

     gpif2_f2u_stream_core(16'h1, 0);
     data = f2u_data[0];
end
endtask
//------------------------------------------------------------------------------
task axi_write;
     input [31:0] addr;
     input [ 2:0] size; // num of bytes: 1, 2, 4
     input [15:0] leng; // 1, 4, 8, 16
     input [32*256-1:0] data; // 32-bit-wise justified data
     integer idx;
begin
     u2f_data[0] = {16'h2,4'b0010,4'h0,4'h0,4'h0};
     u2f_data[1] = trx_cmd(1'b1, size, leng[11:0], 2'b1, 3'b0, 4'b0, 4'b1, 2'b0);
     u2f_data[2] = addr;
     u2f_data[3] = {leng,4'b0100,4'h0,4'h0,4'h0};
     gpif2_u2f_stream_core(16'h4,1'b0);

     for (idx=0; idx<leng; idx=idx+1) begin
          u2f_data[idx] = data[idx*32+:32];
     end
     gpif2_u2f_stream_core(leng, 0);
end
endtask
//------------------------------------------------------------------------------
task axi_read;
     input  [31:0] addr;
     input  [ 2:0] size; // num of bytes: 1, 2, 4
     input  [15:0] leng; // 1, 4, 8, 16
     output [32*256-1:0] data; // 32-bit-wise justified data
     integer idx;
begin
     u2f_data[0] = {16'h2,4'b0010,4'h0,4'h0,4'h0};
     u2f_data[1] = trx_cmd(1'b0, size, leng[11:0], 2'b1, 3'b0, 4'b0, 4'b1, 2'b0);
     u2f_data[2] = addr;
     u2f_data[3] = {leng,4'b0101,4'h0,4'h0,4'h0};
     gpif2_u2f_stream_core(16'h4,1'b0);

     gpif2_f2u_stream_core(leng, 0);
     for (idx=0; idx<leng; idx=idx+1) begin
          data[idx*32+:32] = f2u_data[idx];
     end
end
endtask
//------------------------------------------------------------------------------
// It drives GPOUT of trx_axi.
task axi_write_gpout;
     input [15:0] gpout;
begin
     u2f_data[0][   31] =  1'b1; // 0 for external, 1 for internal
     u2f_data[0][   30] =  1'b1; // 0 for read, 1 for write
     u2f_data[0][29:16] =   'h0;
     u2f_data[0][15: 0] = gpout;
     gpif2_u2f_cmd_core(4'b0010, 4'b0000, 16'h1, 0);
end
endtask
//------------------------------------------------------------------------------
// It reads GPIN of trx_axi.
task axi_read_gpin;
     output [31:0] data;
begin
     u2f_data[0][   31] =  1'b1; // 0 for external, 1 for internal
     u2f_data[0][   30] =  1'b0; // 0 for read, 1 for write
     u2f_data[0][29:16] =   'h0;
     u2f_data[0][15: 0] = 16'h0;
     gpif2_u2f_cmd_core(4'b0010, 4'b0000, 16'h1, 0);
     gpif2_f2u_dat_core(4'b0000, 16'h1, 0);
     data = f2u_data[0];
end
endtask
//------------------------------------------------------------------------------
// Revision History
//
// 2018.04.27: Started by Ando Ki (adki@future-ds.com)
//------------------------------------------------------------------------------
`endif
