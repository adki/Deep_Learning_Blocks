//------------------------------------------------------------------------------
// Copyright (c) by Ando Ki
// All right reserved.
//------------------------------------------------------------------------------
// mover_2d_fifo_sync_merger.v
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
//    * justified-input, justified-output
//    * 'last' indicates the end of stream, i.e., does not fill any more.
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
`ifdef SIM
`timescale 1ns/1ps
`endif

module mover_2d_fifo_sync_merger
     #(parameter FDW=32
               , FAW=$clog2(16)
               , FEN=(FDW/8)
               , DEPTH=(1<<FAW)
               )
(
       input   wire           rstn// asynchronous reset (active low)
     , input   wire           clr // synchronous reset (active high)
     , input   wire           clk
     , output  wire           wr_rdy
     , input   wire           wr_vld
     , input   wire [FDW-1:0] wr_din // justified
     , input   wire [FEN-1:0] wr_strb// justified strobe for each byte
     , input   wire           wr_last
     , input   wire           rd_rdy
     , output  wire           rd_vld
     , output  wire [FDW-1:0] rd_dout // justified
     , output  wire [FEN-1:0] rd_strb // justified strobe
     , output  wire           rd_last
     , input   wire [FEN-1:0] rd_sreq // justified strobe, note it is input
                                      // indicates the number of bytes to be required.
     , output  wire           full
     , output  wire           empty
     , output  wire [FAW:0]   item_cnt // num of elements for the OUT FIFO.
     , output  wire [FAW:0]   room_cnt // num of rooms for the IN FIFO.
);
    //--------------------------------------------------------------------------
    `ifdef SIM
    `ifdef __ICARUS__
    `define NET_DELAYX
    `else
    `define NET_DELAYX  #(0.1)
    `endif
    `else
    `define NET_DELAYX
    `endif
    wire           `NET_DELAYX F_wr_rdy  ;
    wire                       F_wr_vld  ;
    wire [FDW-1:0]             F_wr_din  ;
    wire [FEN-1:0]             F_wr_strb ;
    wire                       F_wr_last ;
    wire           `NET_DELAYX F_rd_rdy  ;
    wire           `NET_DELAYX F_rd_vld  ;
    wire [FDW-1:0] `NET_DELAYX F_rd_dout ;
    wire [FEN-1:0] `NET_DELAYX F_rd_strb ;
    wire           `NET_DELAYX F_rd_last ;
    `ifdef SIM
    `undef NET_DELAYX
    `endif
    //--------------------------------------------------------------------------
    mover_2d_fifo_sync_merger_push #(.FDW(FDW),.FEN(FEN))
    u_push (
          .rstn    (   rstn    )
        , .clr     (   clr     )
        , .clk     (   clk     )
        , .wr_rdy  (   wr_rdy  )
        , .wr_vld  (   wr_vld  )
        , .wr_data (   wr_din  )
        , .wr_strb (   wr_strb )
        , .wr_last (   wr_last )
        , .rd_rdy  ( F_wr_rdy  )
        , .rd_vld  ( F_wr_vld  )
        , .rd_data ( F_wr_din  )
        , .rd_strb ( F_wr_strb )
        , .rd_last ( F_wr_last )
    );
    //--------------------------------------------------------------------------
    mover_2d_fifo_sync_merger_core #(.FDW(1+FEN+FDW),.FAW(FAW))
    u_fifo (
          .rstn     (   rstn                        )
        , .clr      (   clr                         )
        , .clk      (   clk                         )
        , .wr_rdy   ( F_wr_rdy                      )
        , .wr_vld   ( F_wr_vld                      )
        , .wr_din   ({F_wr_last,F_wr_strb,F_wr_din} )
        , .rd_rdy   ( F_rd_rdy                      )
        , .rd_vld   ( F_rd_vld                      )
        , .rd_dout  ({F_rd_last,F_rd_strb,F_rd_dout})
        , .full     ( full                          )
        , .empty    ( empty                         )
        , .item_cnt ( item_cnt                      )
        , .room_cnt ( room_cnt                      )
    );
    //--------------------------------------------------------------------------
    mover_2d_fifo_sync_merger_pop #(.FDW(FDW),.FEN(FEN))
    u_pop (
          .rstn    (   rstn    )
        , .clr     (   clr     )
        , .clk     (   clk     )
        , .wr_rdy  ( F_rd_rdy  )
        , .wr_vld  ( F_rd_vld  )
        , .wr_data ( F_rd_dout )
        , .wr_strb ( F_rd_strb )
        , .wr_last ( F_rd_last )
        , .rd_rdy  (   rd_rdy  )
        , .rd_vld  (   rd_vld  )
        , .rd_data (   rd_dout )
        , .rd_strb (   rd_strb ) // to check
        , .rd_last (   rd_last )
        , .rd_sreq (   rd_sreq )
    );
    //--------------------------------------------------------------------------
endmodule

//------------------------------------------------------------------------------
// It tries to fill all bytes in rd_dout, i.e., rd_strb=~0.
// It tries to fill rd_dout when 'rd_last'.
//
//    --+--+--+--+    --+--+--+--+
//      |0 |1 |0 |      |0 |0 |1 |
//    --+--+--+--+    --+--+--+--+
//      |0 |1 |0 |      |0 |1 |1 |
//    --+--+--+--+ ==>--+--+--+--+
//      |1 |1 |0 |      |0 |1 |1 |
//    --+--+--+--+    --+--+--+--+
//      |1 |1 |1 |      |0 |1 |1 |
//    --+--+--+--+    --+--+--+--+
//
module mover_2d_fifo_sync_merger_push
     #(parameter FDW=32
               , FEN=(FDW/8)
               )
(
       input   wire           rstn// asynchronous reset (active low)
     , input   wire           clr // synchronous reset (active high)
     , input   wire           clk
     , output  reg            wr_rdy
     , input   wire           wr_vld
     , input   wire [FDW-1:0] wr_data// justified
     , input   wire [FEN-1:0] wr_strb// justified strobe for each byte
     , input   wire           wr_last // something like flush
     , input   wire           rd_rdy
     , output  reg            rd_vld
     , output  reg  [FDW-1:0] rd_data // justified
     , output  reg  [FEN-1:0] rd_strb // justified strobe
     , output  reg            rd_last // something like flush
);
   //---------------------------------------------------------------------------
   reg           bf_vld = 1'b0;
   reg [FDW-1:0] bf_data={FDW{1'b0}};
   reg [FEN-1:0] bf_strb={FEN{1'b0}};
   reg           bf_last= 1'b0;
   //---------------------------------------------------------------------------
   wire [FEN:0] num_wr_strb = func_get_bnum(wr_strb);
   wire [FEN:0] num_bf_strb = func_get_bnum(bf_strb);
   wire [FEN:0] num_rd_strb = func_get_bnum(rd_strb);
   //---------------------------------------------------------------------------
   wire [FDW-1:0] wr_data_masked;
   generate
   genvar idx;
   for (idx=0; idx<FEN; idx=idx+1) begin : BLK_IDX
        assign wr_data_masked[idx*8+:8] = (wr_strb[idx]) ? wr_data[idx*8+:8] : 8'h0;
   end
   endgenerate
   //---------------------------------------------------------------------------
   always @ (posedge clk or negedge rstn) begin
   if (rstn==1'b0) begin
       bf_vld  <=  1'b0;
       bf_data <= {FDW{1'b0}};
       bf_strb <= {FEN{1'b0}};
       bf_last <=  1'b0;
   end else if (clr==1'b1) begin
       bf_vld  <=  1'b0;
       bf_data <= {FDW{1'b0}};
       bf_strb <= {FEN{1'b0}};
       bf_last <=  1'b0;
   end else begin
       if (bf_vld==1'b0) begin
           //   +--+          +--+
           // W |0 |        R |1 |
           //   |0 |          |1 |
           //   |1 |          |1 |
           //   +--+  +--+    +--+
           //       B |0 |
           //         |0 |
           //         |0 |
           //         +--+
           if (wr_vld==1'b1) begin
               bf_vld  <=  1'b1;
               bf_data <= wr_data_masked;
               bf_strb <= wr_strb;
               bf_last <= wr_last;
           end
           // synthesis translate_off
           if (wr_rdy==1'b0) $display("%0t %m wr_rdy should be 1.", $time);
           if (rd_vld==1'b1) $display("%0t %m rd_rdy should be 0.", $time);
           // synthesis translate_on
       end else begin // there are some items in bf
           if (((bf_last==1'b1)&&(rd_rdy==1'b1))||((num_bf_strb==FEN)&&(rd_rdy==1'b1))) begin
               bf_vld  <= (wr_vld==1'b1) ? 1'b1 : 1'b0;
               bf_data <= (wr_vld==1'b1) ? wr_data_masked : {FDW{1'b0}};
               bf_strb <= (wr_vld==1'b1) ? wr_strb : {FEN{1'b0}};
               bf_last <= (wr_vld==1'b1) ? wr_last :  1'b0;
               // synthesis translate_off
               if (wr_rdy==1'b0) $display("%0t %m wr_rdy should be 1.", $time);
               if (rd_vld==1'b0) $display("%0t %m rd_rdy should be 1.", $time);
               // synthesis translate_on
           end else begin
               if (wr_vld==1'b1) begin
                   //   +--+          +--+
                   // W |x |        R |1 |
                   //   |x |          |1 |
                   //   |1 |          |1 |
                   //   +--+  +--+    +--+
                   //       B |x |
                   //         |x |
                   //         |1 |
                   //         +--+
                   if (((num_wr_strb+num_bf_strb)==FEN)&&(rd_rdy==1'b1)) begin
                       // note that all "wr_data and bf_data" are used.
                       bf_vld  <=  1'b0;
                       bf_data <= {FDW{1'b0}};
                       bf_strb <= {FEN{1'b0}};
                       bf_last <=  1'b0;
                       // synthesis translate_off
                       if (wr_rdy==1'b0) $display("%0t %m wr_rdy should be 1.", $time);
                       if (rd_vld==1'b0) $display("%0t %m rd_rdy should be 1.", $time);
                       // synthesis translate_on
                   end else if (((num_wr_strb+num_bf_strb)>FEN)&&(rd_rdy==1'b1)) begin
                       bf_vld  <=  1'b1;
                       bf_data <= wr_data_masked>>((FEN-num_bf_strb)*8);
                       bf_strb <= wr_strb>>(FEN-num_bf_strb);
                       bf_last <= wr_last;
                       // synthesis translate_off
                       if (wr_rdy==1'b0) $display("%0t %m wr_rdy should be 1.", $time);
                       if (rd_vld==1'b0) $display("%0t %m rd_rdy should be 1.", $time);
                       // synthesis translate_on
                   end else if ((num_wr_strb+num_bf_strb)<FEN) begin
                       bf_vld  <=  1'b1;
                       bf_data <= bf_data | (wr_data_masked<<(num_bf_strb*8));
                       bf_strb <= bf_strb | (wr_strb<<num_bf_strb);
                       bf_last <= wr_last;
                       // synthesis translate_off
                       if (wr_rdy==1'b0) $display("%0t %m wr_rdy should be 1.", $time);
                       if (rd_vld==1'b1) $display("%0t %m rd_rdy should be 0.", $time);
                       // synthesis translate_on
                   end
               end
             //else begin // (wr_vld==1'b0)
             //    //   +--+          +--+
             //    // W |0 |        R |x |
             //    //   |0 |          |x |
             //    //   |0 |          |1 |
             //    //   +--+  +--+    +--+
             //    //       B |x |
             //    //         |x |
             //    //         |1 |
             //    //         +--+
             //    if ((num_bf_strb==FEN)&&(rd_rdy==1'b1)) begin
             //        bf_vld  <= 1'b0;
             //        bf_data <= {FDW{1'b0}};
             //        bf_strb <= {FEN{1'b0}};
             //        bf_last <=  1'b0;
             //    end
             //    // synthesis translate_off
             //    if (wr_rdy==1'b0) $display("%0t %m wr_rdy should be 1.", $time);
             //    if (rd_vld==1'b1) $display("%0t %m wr_rdy should be 0.", $time);
             //    // synthesis translate_on
             //end
           end
       end
   end // if
   end // always
   //---------------------------------------------------------------------------
   always @ ( * ) begin
       wr_rdy  =  (bf_vld ==1'b0) ? 1'b1
               : ((bf_last==1'b1)||(num_bf_strb==FEN)) ? rd_rdy
               : ((wr_vld ==1'b1)&&((num_wr_strb+num_bf_strb)>=FEN)) ? rd_rdy
               : 1'b1;
       rd_vld  =  (bf_vld ==1'b0) ? 1'b0
               : ((bf_last==1'b1)||(num_bf_strb==FEN)) ? 1'b1
               : ((wr_vld ==1'b1)&&((num_wr_strb+num_bf_strb)>=FEN)) ? 1'b1 : 1'b0;
       rd_data = {FDW{1'b0}};
       rd_strb = {FEN{1'b0}};
       rd_last =  1'b0;
       if (bf_vld==1'b0) begin
           rd_data = {FDW{1'b0}};
           rd_strb = {FDW{1'b0}};
           rd_last =  1'b0;
       end else begin
           if ((bf_last==1'b1)||(num_bf_strb==FEN)) begin
               rd_data = bf_data;
               rd_strb = bf_strb;
               rd_last = bf_last;
           end else begin
               if (wr_vld==1'b1) begin
                   if ((num_wr_strb+num_bf_strb)==FEN) begin
                       rd_data = bf_data | (wr_data_masked<<(num_bf_strb*8));
                       rd_strb = bf_strb | (wr_strb<<num_bf_strb);
                       rd_last = wr_last;
                   end else if ((num_wr_strb+num_bf_strb)>FEN) begin
                       rd_data = bf_data | (wr_data_masked<<(num_bf_strb*8));
                       rd_strb = bf_strb | (wr_strb<<num_bf_strb);
                       rd_last =  1'b0;
                   end else if ((num_wr_strb+num_bf_strb)<FEN) begin
                       rd_data = {FDW{1'b0}};
                       rd_strb = {FDW{1'b0}};
                       rd_last =  1'b0;
                   end
               end
             //else begin // (wr_vld==1'b0)
             //    rd_data = {FDW{1'b0}};
             //    rd_strb = {FEN{1'b0}};
             //    rd_last =  1'b0;
             //end
           end
       end
   end
   //---------------------------------------------------------------------------
   // get the number of bytes from strobe
   function [FEN:0] func_get_bnum;
   input [FEN-1:0] strb;
   integer idx;
   integer num;
   begin
       num = 0;
       for (idx=0; idx<FEN; idx=idx+1) begin
            num = num + strb[idx];
            //if (strb[idx]==1'b1) num = num + 1;
       end
       func_get_bnum = num[FEN:0];
   end
   endfunction
   //---------------------------------------------------------------------------
endmodule

//------------------------------------------------------------------------------
// It tries to get bytes in rd_dout when rd_strb==rd_sreq.
// It tries to fill rd_dout when 'rd_last'.
//
//    --+--+--+--+    --+--+--+--+
//      |0 |1 |1 |      |0 |1 |0 |
//    --+--+--+--+    --+--+--+--+
//      |0 |1 |1 |      |1 |1 |0 |
//    --+--+--+--+ ==>--+--+--+--+
//      |0 |1 |1 |      |1 |1 |1 |
//    --+--+--+--+    --+--+--+--+
//      |1 |1 |1 |      |1 |1 |1 |
//    --+--+--+--+    --+--+--+--+
//
module mover_2d_fifo_sync_merger_pop
     #(parameter FDW=32
               , FEN=(FDW/8)
               )
(
       input   wire           rstn// asynchronous reset (active low)
     , input   wire           clr // synchronous reset (active high)
     , input   wire           clk
     , output  reg            wr_rdy
     , input   wire           wr_vld
     , input   wire [FDW-1:0] wr_data// justified
     , output  wire [FEN-1:0] wr_strb// justified strobe for each byte
     , input   wire           wr_last // something like flush
     , input   wire           rd_rdy
     , output  reg            rd_vld
     , output  reg  [FDW-1:0] rd_data // justified
     , output  reg  [FEN-1:0] rd_strb // justified strobe
     , output  reg            rd_last // something like flush
     , input   wire [FEN-1:0] rd_sreq // justified strobe, (num of byte to pop)
);
   //---------------------------------------------------------------------------
   reg           bf_vld =1'b0;
   reg [FDW-1:0] bf_data={FDW{1'b0}};
   reg [FEN-1:0] bf_strb={FEN{1'b0}};
   reg           bf_last= 1'b0;
   //---------------------------------------------------------------------------
   wire [FEN:0] num_wr_strb = (wr_vld==1'b1) ? func_get_bnum(wr_strb) : {FEN{1'b0}};
   wire [FEN:0] num_bf_strb = func_get_bnum(bf_strb);
   wire [FEN:0] num_rd_sreq = (rd_rdy==1'b1) ? func_get_bnum(rd_sreq) : {FEN{1'b0}};
   //---------------------------------------------------------------------------
   wire [FDW-1:0] wr_data_masked;
   generate
   genvar idx;
   for (idx=0; idx<FEN; idx=idx+1) begin : BLK_IDX
        assign wr_data_masked[idx*8+:8] = (wr_strb[idx]) ? wr_data[idx*8+:8] : 8'h0;
   end
   endgenerate
   //---------------------------------------------------------------------------
   always @ (posedge clk or negedge rstn) begin
   if (rstn==1'b0) begin
       bf_vld  <=  1'b0;
       bf_data <= {FDW{1'b0}};
       bf_strb <= {FEN{1'b0}};
       bf_last <=  1'b0;
   end else if (clr==1'b1) begin
       bf_vld  <=  1'b0;
       bf_data <= {FDW{1'b0}};
       bf_strb <= {FEN{1'b0}};
       bf_last <=  1'b0;
   end else begin
       // 'rd_data' will be moved.
       if (bf_vld==1'b0) begin
           //   +--+          +--+
           // W |0 |        R |1 |
           //   |0 |          |1 |
           //   |1 |          |1 |
           //   +--+  +--+    +--+
           //       B |0 |
           //         |0 |
           //         |0 |
           //         +--+
           if (wr_vld==1'b1) begin
               bf_vld  <=  1'b1;
               bf_data <= wr_data_masked;
               bf_strb <= wr_strb;
               bf_last <= wr_last;
           end
           // synthesis translate_off
           if (wr_rdy==1'b0) $display("%0t %m wr_rdy should be 1.", $time);
           if (rd_vld==1'b1) $display("%0t %m rd_vld should be 0.", $time);
           // synthesis translate_on
       end else begin // there are some items in bf
           if ((num_bf_strb==num_rd_sreq)&&(num_rd_sreq!='h0)) begin
               bf_vld  <= (wr_vld==1'b1) ? 1'b1: 1'b0;
               bf_data <= (wr_vld==1'b1) ? wr_data_masked : {FDW{1'b0}};
               bf_strb <= (wr_vld==1'b1) ? wr_strb : {FEN{1'b0}};
               bf_last <= (wr_vld==1'b1) ? wr_last :  1'b0;
               // synthesis translate_off
               if (wr_rdy==1'b0) $display("%0t %m wr_rdy should be 1.", $time);
               if (rd_vld==1'b0) $display("%0t %m rd_vld should be 1.", $time);
               // synthesis translate_on
           end else if ((num_bf_strb>num_rd_sreq)&&(num_rd_sreq!='h0)) begin
               // do not use 'wr_data' since 'bf_data' does not have sufficient room
               bf_vld  <= 1'b1;
               bf_data <= bf_data>>(num_rd_sreq*8);
               bf_strb <= bf_strb>>(num_rd_sreq);
               bf_last <= bf_last;
               // synthesis translate_off
               if (wr_rdy==1'b1) $display("%0t %m wr_rdy should be 0.", $time);
               if (rd_vld==1'b0) $display("%0t %m rd_vld should be 1.", $time);
               // synthesis translate_on
           end else begin
               if (wr_vld==1'b1) begin
                   //   +--+          +--+
                   // W |x |        R |1 |
                   //   |x |          |1 |
                   //   |1 |          |1 |
                   //   +--+  +--+    +--+
                   //       B |x |
                   //         |x |
                   //         |1 |
                   //         +--+
                   if (((num_wr_strb+num_bf_strb)==num_rd_sreq)&&(num_rd_sreq!='h0)) begin
                       bf_vld  <= 1'b0;
                       bf_data <= {FDW{1'b0}};
                       bf_strb <= {FEN{1'b0}};
                       bf_last <= 1'b0;
                       // synthesis translate_off
                       if (wr_rdy==1'b0) $display("%0t %m wr_rdy should be 1.", $time);
                       if (rd_vld==1'b0) $display("%0t %m rd_vld should be 1.", $time);
                       // synthesis translate_on
                   end else if (((num_wr_strb+num_bf_strb)>num_rd_sreq)&&(num_rd_sreq!='h0)) begin
                       bf_vld  <= 1'b1;
                       bf_data <= wr_data_masked>>((num_rd_sreq-num_bf_strb)*8);
                       bf_strb <= wr_strb>>(num_rd_sreq-num_bf_strb);
                       bf_last <= wr_last;
                       // synthesis translate_off
                       if (wr_rdy==1'b0) $display("%0t %m wr_rdy should be 1.", $time);
                       if (rd_vld==1'b0) $display("%0t %m rd_vld should be 1.", $time);
                       // synthesis translate_on
                   end else if ((num_wr_strb+num_bf_strb)<num_rd_sreq) begin
                       bf_vld  <= 1'b1;
                       bf_data <= bf_data | (wr_data_masked<<(num_bf_strb*8));
                       bf_strb <= bf_strb | (wr_strb<<(num_bf_strb));
                       bf_last <= wr_last;
                       // synthesis translate_off
                       if (wr_rdy==1'b0) $display("%0t %m wr_rdy should be 1.", $time);
                       if (rd_vld==1'b1) $display("%0t %m rd_vld should be 0.", $time);
                       // synthesis translate_on
                   end
               end 
             //else begin // (wr_vld==1'b0)
             //    //   +--+          +--+
             //    // W |0 |        R |1 |
             //    //   |0 |          |1 |
             //    //   |0 |          |1 |
             //    //   +--+  +--+    +--+
             //    //       B |x |
             //    //         |x |
             //    //         |1 |
             //    //         +--+
             //    if ((num_bf_strb==num_rd_sreq)&&(num_rd_sreq!='h0)) begin
             //        bf_vld  <= 1'b0;
             //        bf_data <= {FDW{1'b0}};
             //        bf_strb <= {FEN{1'b0}};
             //        bf_last <= 1'b0;
             //    end else if ((num_bf_strb>num_rd_sreq)&&(num_rd_sreq!='h0)) begin
             //        bf_vld  <= 1'b1;
             //        bf_data <= bf_data>>(num_rd_sreq*8);
             //        bf_strb <= bf_strb>>(num_rd_sreq);
             //        bf_last <= bf_last; // keep last
             //    end
             //end
           end
       end
       // sythesis translate_off
       if ((rd_vld==1'b1)&&(rd_rdy==1'b1)) begin
            if (rd_strb!==rd_sreq) $display("%0t %m ERROR strobe mis-match.", $time);
       end
       // sythesis translate_on
   end // if
   end // always
   //---------------------------------------------------------------------------
   always @ ( * ) begin
       wr_rdy  = (bf_vld==1'b0) ? 1'b1
               : ((num_bf_strb==num_rd_sreq)&&(num_rd_sreq!='h0)) ? rd_rdy
               : ((num_bf_strb>num_rd_sreq)&&(num_rd_sreq!='h0)) ? 1'b0
               : ((wr_vld==1'b1)&&((num_wr_strb+num_bf_strb)>=num_rd_sreq)&&(num_rd_sreq!='h0))  ? rd_rdy
               : ((wr_vld==1'b1)&&((num_wr_strb+num_bf_strb)<num_rd_sreq)&&(num_rd_sreq!='h0))  ? rd_rdy
               : 1'b0;
       rd_vld  = (bf_vld==1'b0) ? 1'b0
               : ((num_bf_strb==num_rd_sreq)&&(num_rd_sreq!='h0)) ? 1'b1
               : (num_bf_strb>num_rd_sreq) ? 1'b1
               : ((wr_vld==1'b1)&&((num_wr_strb+num_bf_strb)>=num_rd_sreq)&&(num_rd_sreq!='h0)) ? 1'b1
               : ((wr_vld==1'b1)&&((num_wr_strb+num_bf_strb)<num_rd_sreq)) ? 1'b0
               : ((wr_vld==1'b0)&&(num_bf_strb>=num_rd_sreq)&&(num_rd_sreq!='h0)) ? 1'b1
               : ((wr_vld==1'b0)&&(num_bf_strb<num_rd_sreq)) ? 1'b0 : 1'b0;
       rd_data = {FDW{1'b0}};
       rd_strb = {FEN{1'b0}};
       rd_last = 1'b0;
       if (bf_vld==1'b0) begin
           rd_data = {FDW{1'b0}};
           rd_strb = {FEN{1'b0}};
           rd_last = 1'b0;
       end else begin
           if ((num_bf_strb==num_rd_sreq)&&(num_rd_sreq!='h0)) begin
               rd_data = bf_data;
               rd_strb = rd_sreq;
               rd_last = bf_last;
           end else if ((num_bf_strb>num_rd_sreq)&&(num_rd_sreq!='h0)) begin
               rd_data = bf_data;
               rd_strb = rd_sreq;
               rd_last = 1'b0;
           end else begin
               if (wr_vld==1'b1) begin
                   if (((num_wr_strb+num_bf_strb)==num_rd_sreq)&&(num_rd_sreq!='h0)) begin
                       rd_data = bf_data | (wr_data_masked<<(num_bf_strb*8));
                       rd_strb = rd_sreq;
                       rd_last = wr_last;
                   end else if (((num_wr_strb+num_bf_strb)>num_rd_sreq)&&(num_rd_sreq!='h0)) begin
                       rd_data = bf_data | (wr_data_masked<<(num_bf_strb*8));
                       rd_strb = rd_sreq;
                       rd_last = 1'b0;
                   end else if ((num_wr_strb+num_bf_strb)<num_rd_sreq) begin
                       rd_data = {FDW{1'b0}};
                       rd_strb = {FEN{1'b0}};
                       rd_last = 1'b0;
                   end
               end
             //else begin // (wr_vld==1'b0)
             //    if ((num_bf_strb==num_rd_sreq)&&(num_rd_sreq!='h0)) begin
             //        rd_data = bf_data;
             //        rd_strb = rd_sreq;
             //        rd_last = bf_last;
             //    end else if (num_bf_strb>num_rd_sreq) begin
             //        rd_data = bf_data;
             //        rd_strb = rd_sreq;
             //        rd_last = 1'b0;
             //    end else if ((rd_rdy==1'b1)&&(rd_vld==1'b1)) begin
             //        rd_data = {FDW{1'b0}};
             //        rd_strb = {FEN{1'b0}};
             //        rd_last = 1'b0;
             //    end
             //end
           end
       end
   end
   //---------------------------------------------------------------------------
   // get the number of bytes from strobe
   function [FEN:0] func_get_bnum;
   input [FEN-1:0] strb;
   integer idx;
   integer num;
   begin
       num = 0;
       for (idx=0; idx<FEN; idx=idx+1) begin
            num = num + strb[idx];
            //if (strb[idx]==1'b1) num = num + 1;
       end
       func_get_bnum = num[FEN:0];
   end
   endfunction
   //---------------------------------------------------------------------------
endmodule

module mover_2d_fifo_sync_merger_core
     #(parameter FDW=32,  // fifof data width
                 FAW=4 )  // num of entries in 2 to the power FAW
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
   //---------------------------------------------------------------------------
   localparam FDT = 1<<FAW;
   //---------------------------------------------------------------------------
   reg  [FAW:0]   fifo_head='h0; // where data to be read
   reg  [FAW:0]   fifo_tail='h0; // where data to be written
   reg  [FAW:0]   next_tail='h0;
   reg  [FAW:0]   next_head='h0;
   wire [FAW-1:0] read_addr = (rd_vld&rd_rdy) ? next_head[FAW-1:0]
                                              : fifo_head[FAW-1:0];
   //---------------------------------------------------------------------------
   // push data item into the entry pointed by fifo_tail
   // pop data item from the entry pointed by fifo_head
   always @(posedge clk or negedge rstn) begin
      if (rstn==1'b0) begin
          fifo_tail <= 0; // for push
          next_tail <= 1; // for push
          fifo_head <= 0; // for pop
          next_head <= 1; // for pop
          item_cnt  <= 0; // items
      end else if (clr) begin
          fifo_tail <= 0;
          next_tail <= 1;
          fifo_head <= 0;
          next_head <= 1;
          item_cnt  <= 0;
      end else begin
          if (!full && wr_vld) begin // for push
              fifo_tail <= next_tail;
              next_tail <= next_tail + 1;
          end 
          if (!empty && rd_rdy) begin // for pop
              fifo_head <= next_head;
              next_head <= next_head + 1;
          end
          if (wr_vld&&!full&&(!rd_rdy||(rd_rdy&&empty))) begin
              item_cnt <= item_cnt + 1;
          end else
          if (rd_rdy&&!empty&&(!wr_vld||(wr_vld&&full))) begin
              item_cnt <= item_cnt - 1;
          end
      end
   end
   //---------------------------------------------------------------------------
   assign rd_vld   = ~empty;
   assign wr_rdy   = ~full;
   assign empty    = (fifo_head == fifo_tail);
   assign full     = (item_cnt>=FDT);
   assign room_cnt = FDT-item_cnt;
   //---------------------------------------------------------------------------
   // synopsys translate_off
   `ifdef RIGOR
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
