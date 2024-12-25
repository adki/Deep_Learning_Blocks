//------------------------------------------------------------------------------
//  Copyright (c) 2018 by Future Design Systems.
//  http://www.future-ds.com
//------------------------------------------------------------------------------
// mem_axi.v
//------------------------------------------------------------------------------
// VERSION: 2018.05.01.
//------------------------------------------------------------------------------
`timescale 1ns/1ns

module mem_axi
     #(parameter AXI_WIDTH_CID=4        // Channel ID width in bits
               , AXI_WIDTH_ID=4         // ID width in bits
               , AXI_WIDTH_AD=32        // address width
               , AXI_WIDTH_DA=32        // data width
               , AXI_WIDTH_DS=AXI_WIDTH_DA/8  // data strobe width
               , AXI_WIDTH_DSB=clogb2(AXI_WIDTH_DS)
               , AXI_WIDTH_SID=AXI_WIDTH_CID+AXI_WIDTH_ID
               , P_SIZE_IN_BYTES=1024
               )
(
       input  wire                 ARESETn
     , input  wire                 ACLK
     , input  wire [AXI_WIDTH_SID-1:0] AWID
     , input  wire [AXI_WIDTH_AD-1:0]  AWADDR
     `ifdef AMBA_AXI4
     , input  wire [ 7:0]          AWLEN
     , input  wire                 AWLOCK
     `else
     , input  wire [ 3:0]          AWLEN
     , input  wire [ 1:0]          AWLOCK
     `endif
     , input  wire [ 2:0]          AWSIZE
     , input  wire [ 1:0]          AWBURST
     `ifdef AMBA_AXI_CACHE
     , input  wire [ 3:0]          AWCACHE
     `endif
     `ifdef AMBA_AXI_PROT
     , input  wire [ 2:0]          AWPROT
     `endif
     , input  wire                 AWVALID
     , output wire                 AWREADY
     `ifdef AMBA_AXI4
     , input  wire [ 3:0]          AWQOS
     , input  wire [ 3:0]          AWREGION
     `endif
     , input  wire [AXI_WIDTH_SID-1:0] WID
     , input  wire [AXI_WIDTH_DA-1:0]  WDATA
     , input  wire [AXI_WIDTH_DS-1:0]  WSTRB
     , input  wire                 WLAST
     , input  wire                 WVALID
     , output reg                  WREADY
     , output reg  [AXI_WIDTH_SID-1:0] BID
     , output reg  [ 1:0]          BRESP
     , output reg                  BVALID
     , input  wire                 BREADY
     , input  wire [AXI_WIDTH_SID-1:0] ARID
     , input  wire [AXI_WIDTH_AD-1:0]  ARADDR
     `ifdef AMBA_AXI4
     , input  wire [ 7:0]          ARLEN
     , input  wire                 ARLOCK
     `else
     , input  wire [ 3:0]          ARLEN
     , input  wire [ 1:0]          ARLOCK
     `endif
     , input  wire [ 2:0]          ARSIZE
     , input  wire [ 1:0]          ARBURST
     `ifdef AMBA_AXI_CACHE
     , input  wire [ 3:0]          ARCACHE
     `endif
     `ifdef AMBA_AXI_PROT
     , input  wire [ 2:0]          ARPROT
     `endif
     , input  wire                 ARVALID
     , output wire                 ARREADY
     `ifdef AMBA_AXI4
     , input  wire [ 3:0]          ARQOS
     , input  wire [ 3:0]          ARREGION
     `endif
     , output reg  [AXI_WIDTH_SID-1:0] RID
     , output reg  [AXI_WIDTH_DA-1:0]  RDATA
     , output reg  [ 1:0]          RRESP
     , output reg                  RLAST
     , output reg                  RVALID
     , input  wire                 RREADY
);
     //-------------------------------------------------------------------------
     localparam ADDR_LENGTH=clogb2(P_SIZE_IN_BYTES);
     //-------------------------------------------------------------------------
     localparam
     `ifdef AMBA_AXI4
            WIDTH_LEN  = 8,
            WIDTH_LOCK = 1,
     `else
            WIDTH_LEN  = 4,
            WIDTH_LOCK = 2,
     `endif
            WIDTH_SIZE = 3,
            WIDTH_BURST= 2,
            WIDTH_WFIFO= AXI_WIDTH_SID+AXI_WIDTH_AD+WIDTH_SIZE
                        +WIDTH_LEN+WIDTH_BURST+WIDTH_LOCK,
            WIDTH_RFIFO= WIDTH_WFIFO;
     //-------------------------------------------------------------------------
     localparam TLENG = 16; // out-standing-transactions
     //-------------------------------------------------------------------------
     reg [AXI_WIDTH_DA-1:0] mem[0:(1<<ADDR_LENGTH)-1];
     //-------------------------------------------------------------------------
     // write handling
     //-------------------------------------------------------------------------
     wire                   wfifo_push_ready;
     wire                   wfifo_push_valid;
     wire [WIDTH_WFIFO-1:0] wfifo_push_din  ;
     reg                    wfifo_pop_ready ;
     wire                   wfifo_pop_valid ;
     wire [WIDTH_WFIFO-1:0] wfifo_pop_dout  ;
     integer awdelay;
     reg wfifo_enable; initial wfifo_enable = 1'b1;
     //-------------------------------------------------------------------------
     // handling write-address
     //-------------------------------------------------------------------------
     assign #1 AWREADY       = wfifo_enable&wfifo_push_ready&AWVALID;
     assign wfifo_push_valid = wfifo_enable&wfifo_push_ready&AWVALID&AWREADY;
     assign wfifo_push_din   = {AWID,AWADDR,AWSIZE,AWLEN,AWBURST,AWLOCK};
     `ifdef DELAY_ACTIVE
      always @ (posedge ACLK or negedge ARESETn) begin
        if (ARESETn==1'b0) begin
            wfifo_enable  <= 1'b1;
        end else begin
            awdelay          <= {$random}%5;
            if (awdelay>0) begin
                wfifo_enable <=  1'b0;
                repeat (awdelay) @ (posedge ACLK);
                wfifo_enable <= 1'b1;
            end
        end
      end
     `else
      always @ ( * ) begin
           wfifo_enable <=  1'b1;
      end
     `endif
     //-------------------------------------------------------------------------
     reg [AXI_WIDTH_SID-1:0]          idW   ; initial idW    = 'h0;
     reg [AXI_WIDTH_AD-1:0]           addW  ; initial addW   = 'h0;
     reg [AXI_WIDTH_AD-AXI_WIDTH_DSB-1:0] addWL ; initial addWL  = 'h0;
     reg [WIDTH_SIZE-1:0]         sizeW ; initial sizeW  = 'h0;
     reg [WIDTH_LEN-1:0]          lenW  ; initial lenW   = 'h0;
     reg [WIDTH_BURST-1:0]        burstW; initial burstW = 'h0;
     reg [WIDTH_LOCK-1:0]         lockW ; initial lockW  = 'h0;
     reg [15:0]                   bnumW ; initial bnumW  = 'h0;
     reg [15:0]                   blenW ; initial blenW  = 'h0;
     integer idy;
     integer wdelay;
     //------------------------------------------------------------------------
     wire [AXI_WIDTH_DA-1:0] get_data;
     generate
     genvar gv;
     for (gv=0; gv<AXI_WIDTH_DS; gv=gv+1) begin: GG
          assign get_data[8*gv+7:8*gv] = (WSTRB[gv]) ? WDATA>>(8*gv)
                                                     : (mem[addWL]>>(8*gv));
     end
     endgenerate
     //-------------------------------------------------------------------------
     // handling write-data
     always @ (posedge ACLK or negedge ARESETn) begin
       if (ARESETn==1'b0) begin
           WREADY  <= 0;
           BID     <= 0;
           BRESP   <= 0;
           BVALID  <= 0;
           wfifo_pop_ready <= 0;
       end else begin
           `ifdef DELAY_ACTIVE
           wdelay <= {$random}%5;
           if (wdelay>0) begin
               repeat (wdelay) @ (posedge ACLK);
           end
           `endif
           wfifo_pop_ready <= #1 1'b1;
           @ (posedge ACLK); //--------------------------------------
           while (~wfifo_pop_valid) @ (posedge ACLK);
           {idW,addW,sizeW,lenW,burstW,lockW} = wfifo_pop_dout; // blocking
           bnumW  = get_bnum(sizeW); // blocking
           blenW  = lenW + 1; // blocking
           addWL  = addW[ADDR_LENGTH-1:AXI_WIDTH_DSB]; // blocking
           wfifo_pop_ready <= #1 1'b0;
           for (idy=0; idy<blenW; idy=idy+1) begin
               WREADY <= #1 1'b1;
               @ (posedge ACLK);
               while (~WVALID) @ (posedge ACLK);
               mem[addWL] <= get_data;
`ifdef VERBOS
if (lockW[1])
$display($time,,"%m written M:%02d A:0x%x/0x%x D:0x%x lock",
idW[AXI_WIDTH_SID-1:AXI_WIDTH_ID],addW,addWL,get_data);
else if (lockW[0])
$display($time,,"%m written M:%02d A:0x%x/0x%x D:0x%x exclusive",
idW[AXI_WIDTH_SID-1:AXI_WIDTH_ID],addW,addWL,get_data);
else
$display($time,,"%m written M:%02d A:0x%x/0x%x D:0x%x",
idW[AXI_WIDTH_SID-1:AXI_WIDTH_ID],addW,addWL,get_data);
`endif
               if (WID!=idW) begin
                   $display($time,,"%m ERROR WR WID mis-match 0x%4x:0x%04x", WID, idW);
               end
               if (idy==(blenW-1)) begin
                   if (WLAST==1'b0) begin
                       $display($time,,"%m ERROR WR WLAST not driven");
                   end
               end else begin
                   if (WLAST==1'b1) begin
                       $display($time,,"%m ERROR WR WLAST not expected");
                   end
               end
               `ifdef DELAY_ACTIVE
               wdelay <= {$random}%5;
               if (wdelay>0) begin
                      WREADY      <= #1 1'b0;
                      repeat (wdelay) @ (posedge ACLK);
                      WREADY      <= #1 1'b1;
               end
               `endif
                addW  = addW + bnumW; // blocking
                addWL = addW[ADDR_LENGTH-1:AXI_WIDTH_DSB]; // blocking
           end
           WREADY <= #1 1'b0;
           BID    <= #1 idW ;
           BRESP  <= #1 2'b00;
           BVALID <= #1 1'b1;
           @ (posedge ACLK);
           while (~BREADY) @ (posedge ACLK);
           BID    <= #1 0;
           BRESP  <= #1 2'b00;
           BVALID <= #1 1'b0;
       end
     end
     //-------------------------------------------------------------------------
     // read handling
     //-------------------------------------------------------------------------
     wire                   rfifo_push_ready;
     wire                   rfifo_push_valid;
     wire [WIDTH_RFIFO-1:0] rfifo_push_din  ;
     reg                    rfifo_pop_ready ;
     wire                   rfifo_pop_valid ;
     wire [WIDTH_RFIFO-1:0] rfifo_pop_dout  ;
     integer ardelay;
     reg rfifo_enable; initial rfifo_enable = 1'b1;
     //-------------------------------------------------------------------------
     // read-address
     assign #1 ARREADY       = rfifo_enable&rfifo_push_ready&ARVALID;
     assign rfifo_push_valid = rfifo_enable&rfifo_push_ready&ARVALID&ARREADY;
     assign rfifo_push_din   = {ARID,ARADDR,ARSIZE,ARLEN,ARBURST,ARLOCK};
     `ifdef DELAY_ACTIVE
         always @ (posedge ACLK or negedge ARESETn) begin
             if (ARESETn==1'b0) begin
                 rfifo_enable  <= 1'b1;
             end else begin
                 ardelay          <= {$random}%5;
                 if (ardelay>0) begin
                     rfifo_enable <=  1'b0;
                     repeat (ardelay) @ (posedge ACLK);
                     rfifo_enable <= 1'b1;
                 end
             end
         end
     `else
         always @ ( * ) begin
              rfifo_enable <=  1'b1;
         end
     `endif
     //-------------------------------------------------------------------------
     reg [AXI_WIDTH_SID-1:0]          idR   ; initial idR    = 'h0;
     reg [AXI_WIDTH_AD-1:0]           addR  ; initial addR   = 'h0;
     reg [AXI_WIDTH_AD-AXI_WIDTH_DSB-1:0] addRL ; initial addRL  = 'h0;
     reg [WIDTH_SIZE-1:0]         sizeR ; initial sizeR  = 'h0;
     reg [WIDTH_LEN-1:0]          lenR  ; initial lenR   = 'h0;
     reg [WIDTH_BURST-1:0]        burstR; initial burstR = 'h0;
     reg [WIDTH_LOCK-1:0]         lockR ; initial lockR  = 'h0;
     reg [15:0]                   bnumR ; initial bnumR  = 'h0;
     reg [15:0]                   blenR ; initial blenR  = 'h0;
     integer                      rdelay;
     integer                      idz;
     //-------------------------------------------------------------------------
     always @ (posedge ACLK or negedge ARESETn) begin
       if (ARESETn==1'b0) begin
           RID             <= 0;
           RDATA           <= ~0;
           RRESP           <= 0;
           RLAST           <= 0;
           RVALID          <= 0;
           rfifo_pop_ready <= 1'b0;
       end else begin
           rfifo_pop_ready <= 1'b0;
           while (~rfifo_pop_valid) @ (posedge ACLK);
           {idR,addR,sizeR,lenR,burstR,lockR} = rfifo_pop_dout; // blocking
           bnumR  = get_bnum(sizeR); // blocking
           blenR  = lenR + 1; // blocking
           addRL  = addR[ADDR_LENGTH-1:AXI_WIDTH_DSB]; // blocking
           rfifo_pop_ready <= 1'b1;
           @ (posedge ACLK); //-----------------------------------
           rfifo_pop_ready <= 1'b0;
           for (idz=0; idz<blenR; idz=idz+1) begin
               RID    <= #1 idR;
               RDATA  <= #1 mem[addRL];
`ifdef VERBOS
if (lockR[1])
$display($time,,"%m read    M:%02d A:0x%x/0x%x D:0x%x lock",
idR[AXI_WIDTH_SID-1:AXI_WIDTH_ID],addR,addRL,mem[addRL]);
else if (lockR[0])
$display($time,,"%m read    M:%02d A:0x%x/0x%x D:0x%x exclusive",
idR[AXI_WIDTH_SID-1:AXI_WIDTH_ID],addR,addRL,mem[addRL]);
else
$display($time,,"%m read    M:%02d A:0x%x/0x%x D:0x%x",
idR[AXI_WIDTH_SID-1:AXI_WIDTH_ID],addR,addRL,mem[addRL]);
`endif
               RVALID <= #1 1'b1;
               RRESP  <= #1 2'b00;
               if (idz==(blenR-1)) RLAST <= #1 1'b1;
               else                RLAST <= #1 1'b0;
               @ (posedge ACLK);
               while (~RREADY) @ (posedge ACLK);
               RLAST <= #1 1'b0;
               addR  = addR + bnumR; // blocking
               addRL = addR[ADDR_LENGTH-1:AXI_WIDTH_DSB]; // blocking
               `ifdef DELAY_ACTIVE
               rdelay <= {$random}%5;
               if (rdelay>0) begin
                   RVALID <= #1 1'b0;
                   RLAST  <= #1 1'b0;
                   RID    <= #1 0;
                   RDATA  <= #1 ~0;
                   repeat (rdelay) @ (posedge ACLK);
               end
               `endif
           end
           RVALID <= #1 1'b0;
           RLAST  <= #1 1'b0;
           RID    <= #1 0;
           RDATA  <= #1 ~0;
       end
     end
     //------------------------------------------------------------------------
     function [15:0] get_bnum;
         input [2:0] size;
     begin
        case (size)
        3'h0:  get_bnum = 1;
        3'h1:  get_bnum = 2;
        3'h2:  get_bnum = 4;
        3'h3:  get_bnum = 8;
        3'h4:  get_bnum = 16;
        3'h5:  get_bnum = 32;
        3'h6:  get_bnum = 64;
        3'h7:  get_bnum = 128;
        endcase
     end
     endfunction
     //------------------------------------------------------------------------
     mem_axi_fifo_sync #(.FDW(WIDTH_WFIFO)
                        ,.FAW(4))
     u_wfifo (
           .rstn     (ARESETn)
         , .clr      (1'b0   )
         , .clk      (ACLK)
         , .wr_rdy   (wfifo_push_ready)
         , .wr_vld   (wfifo_push_valid)
         , .wr_din   (wfifo_push_din  )
         , .rd_rdy   (wfifo_pop_ready )
         , .rd_vld   (wfifo_pop_valid )
         , .rd_dout  (wfifo_pop_dout  )
         , .full     ()
         , .empty    ()
         , .item_cnt ()
         , .room_cnt ()
     );
     //------------------------------------------------------------------------
     mem_axi_fifo_sync #(.FDW(WIDTH_RFIFO)
                        ,.FAW(4))
     u_rfifo (
           .rstn     (ARESETn)
         , .clr      (1'b0   )
         , .clk      (ACLK)
         , .wr_rdy   (rfifo_push_ready)
         , .wr_vld   (rfifo_push_valid)
         , .wr_din   (rfifo_push_din  )
         , .rd_rdy   (rfifo_pop_ready )
         , .rd_vld   (rfifo_pop_valid )
         , .rd_dout  (rfifo_pop_dout  )
         , .full     ()
         , .empty    ()
         , .item_cnt ()
         , .room_cnt ()
     );
     //------------------------------------------------------------------------
     function integer clogb2;
     input [31:0] value;
     begin
       value = value - 1;
       for (clogb2=0; value>0; clogb2=clogb2+1) value = value>>1;
     end
     endfunction
endmodule
//------------------------------------------------------------------------------
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
//
//               ___   _____   _____   _____   ____
//   clk           |___|   |___|   |___|   |___|
//               _______________________________
//   wr_rdy     
//                     _________________
//   wr_vld      ______|       ||      |___________  
//                      _______  ______
//   wr_din      XXXXXXX__D0___XX__D1__XXXX
//               ______________                        ____
//   empty                     |_______________________|
//                                     _________________
//   rd_rdy      ______________________|               |___
//                                     ________________
//   rd_vld      ______________________|       ||      |___
//                                      ________ _______
//   rd_dout     XXXXXXXXXXXXXXXXXXXXXXX__D0____X__D1___XXXX
//
//   full        __________________________________________
//
//------------------------------------------------------------------------------
module mem_axi_fifo_sync #(parameter FDW =32  // fifof data width
                                   , FAW =5 ) // num of entries in 2 to the power FAW
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
   reg  [FAW:0]   fifo_head; // where data to be read
   reg  [FAW:0]   fifo_tail; // where data to be written
   reg  [FAW:0]   next_tail;
   reg  [FAW:0]   next_head;
   wire [FAW-1:0] read_addr = (rd_vld&rd_rdy) ? next_head[FAW-1:0] : fifo_head[FAW-1:0];
   //---------------------------------------------------
   // synopsys translate_off
   initial fifo_head = 'h0;
   initial fifo_tail = 'h0;
   initial next_head = 'h0;
   initial next_tail = 'h0;
   // synopsys translate_on
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
   reg [FDW-1:0] Mem [0:FDT-1];
   assign rd_dout  = Mem[fifo_head[FAW-1:0]];
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
// 2018.05.01: Started by Ando Ki (adki@future-ds.com)
//------------------------------------------------------------------------------
