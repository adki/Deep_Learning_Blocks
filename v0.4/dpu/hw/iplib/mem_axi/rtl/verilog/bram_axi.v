//------------------------------------------------------------------------------
//  Copyright (c) 2018-2020 by Future Design Systems.
//  http://www.future-ds.com
//------------------------------------------------------------------------------
// bram_axi.v
//------------------------------------------------------------------------------
// VERSION: 2020.02.07.
//------------------------------------------------------------------------------
// MACROS:
//    AMBA_AXI4                  - AMBA AXI4
//    BURST_TYPE_WRAPP_ENABLED   - Burst wrapping type enabled
// PARAMETERS:
//    P_SIZE_IN_BYTES - size of memory in bytes
//------------------------------------------------------------------------------
`ifdef VIVADO
`define DBG_BRAM  (* mark_debug="true" *)
`ifdef SIM
`include "bram_simple_dual_port_32_16KB/bram_simple_dual_port_32_16KB_sim_netlist.v"
`include "bram_simple_dual_port_32_32KB/bram_simple_dual_port_32_32KB_sim_netlist.v"
`include "bram_simple_dual_port_32_64KB/bram_simple_dual_port_32_64KB_sim_netlist.v"
//`include "bram_simple_dual_port_32_128KB/bram_simple_dual_port_32_128KB_sim_netlist.v"
//`include "bram_simple_dual_port_32_256KB/bram_simple_dual_port_32_256KB_sim_netlist.v"
`else
`include "bram_simple_dual_port_32_16KB/bram_simple_dual_port_32_16KB_stub.v"
`include "bram_simple_dual_port_32_32KB/bram_simple_dual_port_32_32KB_stub.v"
`include "bram_simple_dual_port_32_64KB/bram_simple_dual_port_32_64KB_stub.v"
//`include "bram_simple_dual_port_32_128KB/bram_simple_dual_port_32_128KB_stub.v"
//`include "bram_simple_dual_port_32_256KB/bram_simple_dual_port_32_256KB_stub.v"
`endif
`else
`include "bram_simple_dual_port_32_16KB.v"
`include "bram_simple_dual_port_32_32KB.v"
`include "bram_simple_dual_port_32_64KB.v"
//`include "bram_simple_dual_port_32_128KB.v"
//`include "bram_simple_dual_port_32_256KB.v"
`endif

module bram_axi
     #(parameter AXI_WIDTH_CID= 4  // Channel ID width in bits
               , AXI_WIDTH_ID = 4  // ID width in bits
               , AXI_WIDTH_AD =32  // address width
               , AXI_WIDTH_DA =256 // data width
               , AXI_WIDTH_DS =(AXI_WIDTH_DA/8)  // data strobe width
               , AXI_WIDTH_DSB=clogb2(AXI_WIDTH_DS) // data strobe width
               , AXI_WIDTH_SID=(AXI_WIDTH_CID+AXI_WIDTH_ID)
               , P_SIZE_IN_BYTES=(16*1024)
               )
(
                 input  wire                     ARESETn
     ,           input  wire                     ACLK
     ,           input  wire [AXI_WIDTH_SID-1:0] AWID
     , `DBG_BRAM input  wire [AXI_WIDTH_AD-1:0]  AWADDR
     `ifdef AMBA_AXI4
     , `DBG_BRAM input  wire [ 7:0]              AWLEN
     ,           input  wire                     AWLOCK
     `else
     , `DBG_BRAM input  wire [ 3:0]              AWLEN
     ,           input  wire [ 1:0]              AWLOCK
     `endif
     , `DBG_BRAM input  wire [ 2:0]              AWSIZE
     , `DBG_BRAM input  wire [ 1:0]              AWBURST
     `ifdef AMBA_AXI_CACHE
     ,           input  wire [ 3:0]              AWCACHE
     `endif
     `ifdef AMBA_AXI_PROT
     ,           input  wire [ 2:0]              AWPROT
     `endif
     , `DBG_BRAM input  wire                     AWVALID
     , `DBG_BRAM output reg                      AWREADY
     `ifdef AMBA_QOS
     ,           input  wire [ 3:0]              AWQOS
     ,           input  wire [ 3:0]              AWREGION
     `endif
     `ifndef AMBA_AXI4
     ,           input  wire [AXI_WIDTH_SID-1:0] WID
     `endif
     , `DBG_BRAM input  wire [AXI_WIDTH_DA-1:0]  WDATA
     , `DBG_BRAM input  wire [AXI_WIDTH_DS-1:0]  WSTRB
     , `DBG_BRAM input  wire                     WLAST
     , `DBG_BRAM input  wire                     WVALID
     , `DBG_BRAM output reg                      WREADY
     ,           output reg  [AXI_WIDTH_SID-1:0] BID
     , `DBG_BRAM output reg  [ 1:0]              BRESP
     , `DBG_BRAM output reg                      BVALID
     , `DBG_BRAM input  wire                     BREADY
     ,           input  wire [AXI_WIDTH_SID-1:0] ARID
     , `DBG_BRAM input  wire [AXI_WIDTH_AD-1:0]  ARADDR
     `ifdef AMBA_AXI4
     , `DBG_BRAM input  wire [ 7:0]              ARLEN
     ,           input  wire                     ARLOCK
     `else
     , `DBG_BRAM input  wire [ 3:0]              ARLEN
     ,           input  wire [ 1:0]              ARLOCK
     `endif
     , `DBG_BRAM input  wire [ 2:0]              ARSIZE
     , `DBG_BRAM input  wire [ 1:0]              ARBURST
     `ifdef AMBA_AXI_CACHE
     ,           input  wire [ 3:0]              ARCACHE
     `endif
     `ifdef AMBA_AXI_PROT
     ,           input  wire [ 2:0]              ARPROT
     `endif
     , `DBG_BRAM input  wire                     ARVALID
     , `DBG_BRAM output reg                      ARREADY
     `ifdef AMBA_QOS
     ,           input  wire [ 3:0]              ARQOS
     ,           input  wire [ 3:0]              ARREGION
     `endif
     ,           output reg  [AXI_WIDTH_SID-1:0] RID
     , `DBG_BRAM output reg  [AXI_WIDTH_DA-1:0]  RDATA
     , `DBG_BRAM output reg  [ 1:0]              RRESP
     , `DBG_BRAM output reg                      RLAST
     , `DBG_BRAM output reg                      RVALID
     , `DBG_BRAM input  wire                     RREADY
);
     //-------------------------------------------------------------------------
     localparam ADDR_LENGTH=clogb2(P_SIZE_IN_BYTES);
     //-------------------------------------------------------------------------
     reg  [ADDR_LENGTH-1:0]  Twaddr ;
     reg  [AXI_WIDTH_DA-1:0] Twdata ;
     reg  [AXI_WIDTH_DS-1:0] Twstrb ;
     reg                     Twen   ;
     reg  [ADDR_LENGTH-1:0]  Traddr ;
     wire [AXI_WIDTH_DA-1:0] Trdata ;
     reg  [AXI_WIDTH_DS-1:0] Trstrb ;
     reg                     Tren   ; // driven by stateR
     wire                    TrenX  ; // actual Tren
     //-------------------------------------------------------------------------
     // write case
     //-------------------------------------------------------------------------
     reg  [AXI_WIDTH_SID-1:0] AWID_reg   ;
     reg  [AXI_WIDTH_AD-1:0]  AWADDR_reg ;
     `ifdef AMBA_AXI4
     reg  [ 7:0]              AWLEN_reg  ;
     reg                      AWLOCK_reg ;
     `else
     reg  [ 3:0]              AWLEN_reg  ;
     reg  [ 1:0]              AWLOCK_reg ;
     `endif
     reg  [ 2:0]              AWSIZE_reg ;
     reg  [ 1:0]              AWBURST_reg;
     reg  [ 3:0]              AWCACHE_reg;
     reg  [ 2:0]              AWPROT_reg ;
     //-------------------------------------------------------------------------
     reg  [ADDR_LENGTH-1:0] addrW; // address of each transfer within a burst
     `ifdef AMBA_AXI4
     reg  [ 7:0]            beatW; // keeps num of transfers within a burst
     `else
     reg  [ 3:0]            beatW; // keeps num of transfers within a burst
     `endif
     //-------------------------------------------------------------------------
     localparam STW_IDLE   = 'h0,
                STW_WRITE0 = 'h1,
                STW_WRITE  = 'h2,
                STW_RSP    = 'h3;
     `DBG_BRAM reg [1:0] stateW=STW_IDLE; // synthesis attribute keep of stateW is "true";
     always @ (posedge ACLK or negedge ARESETn) begin
     if (ARESETn==1'b0) begin
         AWID_reg    <= 'h0;
         AWADDR_reg  <= 'h0;
         AWLEN_reg   <= 'h0;
         AWSIZE_reg  <= 'b0;
         AWBURST_reg <= 'b0;
         AWLOCK_reg  <= 'b0;
         AWCACHE_reg <= 'h0;
         AWPROT_reg  <= 'b0;
         AWREADY     <= 1'b0;
         WREADY      <= 1'b0;
         BID         <=  'h0;
         BRESP       <= 2'b10; // SLAVE ERROR
         BVALID      <= 1'b0;
         addrW       <=  'h0;
         beatW       <=  'h0;
         Twaddr      <=  'h0;
         Twdata      <=  'h0;
         Twstrb      <=  'h0;
         Twen        <= 1'b0;
         stateW      <= STW_IDLE;
     end else begin
         case (stateW)
         STW_IDLE: begin
             if ((AWVALID==1'b1)&&(AWREADY==1'b1)) begin
                  AWID_reg    <= AWID   ;
                  AWADDR_reg  <= AWADDR ;
                  AWLEN_reg   <= AWLEN  ;
                  AWSIZE_reg  <= AWSIZE ;
                  AWBURST_reg <= AWBURST;
                  AWLOCK_reg  <= AWLOCK ;
                  `ifdef AMBA_AXI_CACHE
                  AWCACHE_reg <= AWCACHE;
                  `else
                  AWCACHE_reg <= 'h0;
                  `endif
                  `ifdef AMBA_AXI_PROT
                  AWPROT_reg  <= AWPROT ;
                  `else
                  AWPROT_reg  <= 'h0;
                  `endif
                  AWREADY     <= 1'b0;
                  WREADY      <= 1'b1;
                  addrW       <= AWADDR[ADDR_LENGTH-1:0];
                  beatW       <=  'h0;
                  if (WVALID==1'b1) begin
                      Twaddr <= AWADDR[ADDR_LENGTH-1:0];
                      Twdata <= WDATA;
                      Twstrb <= WSTRB;
                      Twen   <= 1'b1;
                      beatW  <= 1;
                      addrW  <= get_next_addr_wr(AWADDR[ADDR_LENGTH-1:0]
                                                ,AWSIZE
                                                ,AWBURST,AWLEN);
                      if (AWLEN=='h0) begin
                          WREADY <= 1'b0;
                          BVALID <= 1'b1;
                          BID    <= AWID;
                          if (WLAST==1'b0) BRESP <= 2'b10; // SLVERR - missing last
                          `ifndef AMBA_AXI4
                          else if (WID!=AWID) BRESP <= 2'b10; // SLVERR - ID mis-match occured
                          `endif
                          else BRESP = 2'b00;
                          stateW <= STW_RSP;
                      end else begin
                          stateW <= STW_WRITE;
                      end
                  end else begin
                      Twen    <= 1'b0;
                      stateW  <= STW_WRITE0;
                  end
             end else begin
                  AWREADY <= 1'b1;
                  WREADY  <= 1'b1;
             end
             end // STW_IDLE
         STW_WRITE0: begin
             if (WVALID==1'b1) begin
                 Twaddr <= addrW;
                 Twdata <= WDATA;
                 Twstrb <= WSTRB;
                 Twen   <= 1'b1;
                 beatW  <= beatW + 1;
                 addrW  <= get_next_addr_wr(addrW,AWSIZE_reg
                                           ,AWBURST_reg,AWLEN_reg);
                 if (beatW>=AWLEN_reg) begin
                     WREADY <= 1'b0;
                     BVALID <= 1'b1;
                     BID    <= AWID_reg;
                     if (WLAST==1'b0) BRESP <= 2'b10; // SLVERR - missing last
                     `ifndef AMBA_AXI4
                     else if (WID!=AWID_reg) BRESP <= 2'b10; // SLVERR - ID mis-match occured
                     `endif
                     else BRESP = 2'b00;
                     stateW <= STW_RSP;
                 end else begin
                     stateW <= STW_WRITE;
                 end
             end else begin
                 Twen   <= 1'b0;
             end
             end // STW_WRITE0
         STW_WRITE: begin
             if (WVALID==1'b1) begin
                 Twaddr <= addrW;
                 Twdata <= WDATA;
                 Twstrb <= WSTRB;
                 Twen   <= 1'b1;
                 beatW  <= beatW + 1;
                 addrW  <= get_next_addr_wr(addrW,AWSIZE_reg
                                           ,AWBURST_reg,AWLEN_reg);
                 if (beatW>=AWLEN_reg) begin
                     WREADY <= 1'b0;
                     BVALID <= 1'b1;
                     BID    <= AWID_reg;
                     if (WLAST==1'b0) BRESP <= 2'b10; // SLVERR - missing last
                     `ifndef AMBA_AXI4
                     else if (WID!=AWID_reg) BRESP <= 2'b10; // SLVERR - ID mis-match occured
                     `endif
                     else BRESP = 2'b00;
                     stateW <= STW_RSP;
                 end
             end else begin
                 Twen   <= 1'b0;
             end
             end // STW_WRITE
         STW_RSP: begin
             Twen   <= 1'b0;
             if (BREADY==1'b1) begin
                 BVALID  <= 1'b0;
                 AWREADY <= 1'b1;
                 stateW  <= STW_IDLE;
             end
             end // STW_RSP
         endcase
     end // if
     end // always
     //-------------------------------------------------------------------------
     // read case
     //-------------------------------------------------------------------------
     reg  [AXI_WIDTH_AD-1:0]  ARADDR_reg ;
     `ifdef AMBA_AXI4
     reg  [ 7:0]          ARLEN_reg  ;
     reg                  ARLOCK_reg ;
     `else
     reg  [ 3:0]          ARLEN_reg  ;
     reg  [ 1:0]          ARLOCK_reg ;
     `endif
     reg  [ 2:0]          ARSIZE_reg ;
     reg  [ 1:0]          ARBURST_reg;
     reg  [ 3:0]          ARCACHE_reg;
     reg  [ 2:0]          ARPROT_reg ;
     //-------------------------------------------------------------------------
     reg  [AXI_WIDTH_DA-1:0] dataR;
     reg  [ADDR_LENGTH-1:0]  addrR; // address of each transfer within a burst
     reg  [AXI_WIDTH_DS-1:0] strbR; // strobe
     `ifdef AMBA_AXI4
     reg  [ 7:0]             beatR; // keeps num of transfers within a burst
     `else
     reg  [ 3:0]             beatR; // keeps num of transfers within a burst
     `endif
     //-------------------------------------------------------------------------
     localparam STR_IDLE   = 'h0,
                STR_READ0  = 'h1,
                STR_READ1  = 'h2,
                STR_READ2  = 'h3,
                STR_READ21 = 'h4,
                STR_READ22 = 'h5,
                STR_READ3  = 'h6,
                STR_READ31 = 'h7,
                STR_READ32 = 'h8,
                STR_READ33 = 'h9,
                STR_READ34 = 'hA,
                STR_END    = 'hB;
     `DBG_BRAM reg [3:0] stateR=STR_IDLE; // synthesis attribute keep of stateR is "true";
     always @ (posedge ACLK or negedge ARESETn) begin
     if (ARESETn==1'b0) begin
         ARADDR_reg  <= 'h0;
         ARLEN_reg   <= 'h0;
         ARLOCK_reg  <= 'b0;
         ARSIZE_reg  <= 'b0;
         ARBURST_reg <= 'b0;
         ARCACHE_reg <= 'h0;
         ARPROT_reg  <= 'b0;
         ARREADY     <= 1'b0;
         RID         <=  'h0;
         RLAST       <= 1'b0;
         RRESP       <= 2'b10; // SLAERROR
         RDATA       <=  'h0;
         RVALID      <= 1'b0;
         dataR       <=  'h0;
         addrR       <=  'h0;
         strbR       <=  'h0;
         beatR       <=  'h0;
         Traddr      <=  'h0;
         Trstrb      <=  'h0;
         Tren        <= 1'b0;
         stateR      <= STR_IDLE;
     end else begin
         case (stateR)
         STR_IDLE: begin
             if ((ARVALID==1'b1)&&(ARREADY==1'b1)) begin
                  ARADDR_reg  <= ARADDR ;
                  ARLEN_reg   <= ARLEN  ;
                  ARSIZE_reg  <= ARSIZE ;
                  ARBURST_reg <= ARBURST;
                  ARLOCK_reg  <= ARLOCK ;
                  `ifdef AMBA_AXI_CACHE
                  ARCACHE_reg <= ARCACHE;
                  `else
                  ARCACHE_reg <= 'h0;
                  `endif
                  `ifdef AMBA_AXI_PROT
                  ARPROT_reg  <= ARPROT ;
                  `else
                  ARPROT_reg  <= 'h0;
                  `endif
                  ARREADY     <= 1'b0;
                  RID         <= ARID;
                  addrR       <= get_next_addr_rd(ARADDR[ADDR_LENGTH-1:0]
                                                 ,ARSIZE,ARBURST,ARLEN);
                  beatR       <=  'h0;
                  Traddr      <= ARADDR[ADDR_LENGTH-1:0];
                  Trstrb      <= get_strb(ARADDR[ADDR_LENGTH-1:0],ARSIZE);
                  Tren        <= 1'b1;
                  stateR      <= STR_READ0;
             end else begin
                 ARREADY <= 1'b1;
             end
             end // STR_IDLE
         STR_READ0: begin // address only
             if (ARLEN_reg=='h0) begin // single beat burst
                 Tren   <= 1'b0;
                 stateR <= STR_READ1;
             end else if (ARLEN_reg=='h1) begin // two-beat burst
                 Tren   <= 1'b1;
                 Traddr <= addrR;
                 Trstrb <= get_strb(addrR,ARSIZE_reg);
                 stateR <= STR_READ2;
             end else begin // three or more beat burst
                 Tren   <= 1'b1;
                 Traddr <= addrR;
                 Trstrb <= get_strb(addrR,ARSIZE_reg);
                 addrR  <= get_next_addr_rd(addrR,ARSIZE_reg
                                           ,ARBURST_reg,ARLEN_reg);
                 beatR  <= 1;
                 stateR <= STR_READ3;
             end
             end // STR_READ0
         STR_READ1: begin // data only
             Tren   <= 1'b0;
             RLAST  <= 1'b1;
             RDATA  <= Trdata;
             RRESP  <= 2'b00;
             RVALID <= 1'b1;
             stateR <= STR_END;
             end // STR_READ1
         STR_READ2: begin // two-beat burst
             Tren   <= 1'b0;
             RLAST  <= 1'b0;
             RDATA  <= Trdata;
             RRESP  <= 2'b00;
             RVALID <= 1'b1;
             stateR <= STR_READ21;
             end // STR_READ2;
         STR_READ21: begin // two-beat burst
             if (RREADY==1'b1) begin
                 Tren   <= 1'b0;
                 RLAST  <= 1'b1;
                 RDATA  <= Trdata;
                 RRESP  <= 2'b00;
                 RVALID <= 1'b1;
                 stateR <= STR_END;
             end else begin
                 dataR   <= Trdata;
                 stateR  <= STR_READ22;
             end
             end // STR_READ21
         STR_READ22: begin // two-beat burst
             if (RREADY==1'b1) begin
                 Tren   <= 1'b0;
                 RLAST  <= 1'b1;
                 RDATA  <= dataR ;
                 RRESP  <= 2'b00;
                 RVALID <= 1'b1;
                 stateR <= STR_END;
             end
             end // STR_READ22
         STR_READ3: begin // n-beat burst
             RLAST  <= 1'b0;
             RDATA  <= Trdata;
             RRESP  <= 2'b00;
             RVALID <= 1'b1;
             Tren   <= 1'b1;
             Traddr <= addrR;
             Trstrb <= get_strb(addrR,ARSIZE_reg);
             addrR  <= get_next_addr_rd(addrR,ARSIZE_reg
                                       ,ARBURST_reg,ARLEN_reg);
             beatR  <= beatR + 1;
             stateR <= STR_READ31;
             end // STR_READ3;
         STR_READ31: begin
             if (RREADY==1'b1) begin
                 RLAST  <= 1'b0;
                 RDATA  <= Trdata;
                 RRESP  <= 2'b00;
                 RVALID <= 1'b1;
                 if (beatR>=ARLEN_reg) begin
                    Tren   <= 1'b0; // updated 2018.06.12. adki
                    Traddr <= addrR;
                    stateR <= STR_READ33;
                 end else begin
                    Tren   <= 1'b1; // actually RREADY determines it
                    Traddr <= addrR;
                    Trstrb <= get_strb(addrR,ARSIZE_reg);
                    addrR  <= get_next_addr_rd(addrR,ARSIZE_reg
                                              ,ARBURST_reg,ARLEN_reg);
                 end
                 beatR  <= beatR + 1;
             end else begin
                 Tren   <= 1'b1; // actually RREADY determines it
                 dataR  <= Trdata;
                 stateR <= STR_READ32;
             end
             end // STR_READ31
         STR_READ32: begin
             if (RREADY==1'b1) begin
                 RLAST  <= 1'b0;
                 RDATA  <= dataR;
                 RRESP  <= 2'b00;
                 RVALID <= 1'b1;
                 dataR  <= Trdata;
                 if (beatR>=ARLEN_reg) begin
                    Tren   <= 1'b0;
                    stateR <= STR_READ33;
                 end else begin
                    Tren   <= 1'b1; // actually RREADY determines it
                    Traddr <= addrR;
                    Trstrb <= get_strb(addrR,ARSIZE_reg);
                    addrR  <= get_next_addr_rd(addrR,ARSIZE_reg
                                              ,ARBURST_reg,ARLEN_reg);
                    stateR <= STR_READ31;
                 end
                 beatR  <= beatR + 1;
             end
             end // STR_READ32
         STR_READ33: begin
             if (RREADY==1'b1) begin
                 Tren   <= 1'b0;
                 RLAST  <= 1'b1;
                 RDATA  <= Trdata;
                 RRESP  <= 2'b00;
                 RVALID <= 1'b1;
                 stateR <= STR_END;
             end else begin
                 Tren   <= 1'b0;
                 dataR  <= Trdata;
                 stateR <= STR_READ34;
             end
             end // STR_READ33
         STR_READ34: begin
             if (RREADY==1'b1) begin
                 Tren   <= 1'b0;
                 RLAST  <= 1'b1;
                 RDATA  <= dataR;
                 RRESP  <= 2'b00;
                 RVALID <= 1'b1;
                 stateR <= STR_END;
             end
             end // STR_READ34
         STR_END: begin // data only
             Tren <= 1'b0;
             if (RREADY==1'b1) begin
                 RDATA   <=  'h0;
                 RRESP   <= 2'b10; // SLVERR
                 RLAST   <= 1'b0;
                 RVALID  <= 1'b0;
                 ARREADY <= 1'b1;
                 stateR  <= STR_IDLE;
             end
             end // STR_END
         endcase
     end // if
     end // always
     //-------------------------------------------------------------------------
     function [7:0] get_bytes;
     input [2:0] size;
          get_bytes = 1<<size;
     endfunction
     //-------------------------------------------------------------------------
     function [AXI_WIDTH_DS-1:0] get_strb;
     input [ADDR_LENGTH-1:0] addr;
     input [ 2:0]            size;  // num. of byte to move: 0=1-byte, 1=2-byte
     reg   [AXI_WIDTH_DS-1:0]    offset;
     begin
          offset = addr[AXI_WIDTH_DSB-1:0]; //offset = addr%AXI_WIDTH_DS;
          case (size)
          3'b000: get_strb = {  1{1'b1}}<<offset;
          3'b001: get_strb = {  2{1'b1}}<<offset;
          3'b010: get_strb = {  4{1'b1}}<<offset;
          3'b011: get_strb = {  8{1'b1}}<<offset;
          3'b100: get_strb = { 16{1'b1}}<<offset;
          3'b101: get_strb = { 32{1'b1}}<<offset;
          3'b110: get_strb = { 64{1'b1}}<<offset;
          3'b111: get_strb = {128{1'b1}}<<offset;
          endcase
     end
     endfunction
     //-------------------------------------------------------------------------
     function [ADDR_LENGTH-1:0] get_next_addr_wr;
     input [ADDR_LENGTH-1:0] addr ;
     input [ 2:0]            size ;
     input [ 1:0]            burst; // burst type
     `ifdef AMBA_AXI4
     input [ 7:0]            len  ; // burst length
     `else
     input [ 3:0]            len  ; // burst length
     `endif
     reg   [ADDR_LENGTH-AXI_WIDTH_DSB-1:0] naddr;
     reg   [ADDR_LENGTH-1:0] mask ;
     begin
          case (burst)
          2'b00: get_next_addr_wr = addr;
          2'b01: begin
                 if ((1<<size)<AXI_WIDTH_DS) begin
                    get_next_addr_wr = addr + (1<<size);
                 end else begin
                     naddr = addr[ADDR_LENGTH-1:AXI_WIDTH_DSB];
                     naddr = naddr + 1;
                     get_next_addr_wr = {naddr,{AXI_WIDTH_DSB{1'b0}}};
                 end
                 end
          2'b10: begin
                 `ifdef BURST_TYPE_WRAPP_ENABLED
                 mask          = get_wrap_mask(size,len);
                 get_next_addr_wr = (addr&~mask)
                               | (((addr&mask)+(1<<size))&mask);
                 `else
                 // synopsys translate_off
                 $display($time,,"%m ERROR BURST WRAP not supported");
                 // synopsys translate_on
                 `endif
                 end
          2'b11: begin
                 get_next_addr_wr = addr;
                 // synopsys translate_off
                 $display($time,,"%m ERROR un-defined BURST %01x", burst);
                 // synopsys translate_on
                 end
          endcase
     end
     endfunction
     //-------------------------------------------------------------------------
     function [ADDR_LENGTH-1:0] get_next_addr_rd;
     input [ADDR_LENGTH-1:0] addr ;
     input [ 2:0]            size ;
     input [ 1:0]            burst; // burst type
     `ifdef AMBA_AXI4
     input [ 7:0]            len  ; // burst length
     `else
     input [ 3:0]            len  ; // burst length
     `endif
     reg   [ADDR_LENGTH-AXI_WIDTH_DSB-1:0] naddr;
     reg   [ADDR_LENGTH-1:0] mask ;
     begin
          case (burst)
          2'b00: get_next_addr_rd = addr;
          2'b01: begin
                 if ((1<<size)<AXI_WIDTH_DS) begin
                    get_next_addr_rd = addr + (1<<size);
                 end else begin
                     naddr = addr[ADDR_LENGTH-1:AXI_WIDTH_DSB];
                     naddr = naddr + 1;
                     get_next_addr_rd = {naddr,{AXI_WIDTH_DSB{1'b0}}};
                 end
                 end
          2'b10: begin
                 `ifdef BURST_TYPE_WRAPP_ENABLED
                 mask          = get_wrap_mask(size,len);
                 get_next_addr_rd = (addr&~mask)
                               | (((addr&mask)+(1<<size))&mask);
                 `else
                 // synopsys translate_off
                 $display($time,,"%m ERROR BURST WRAP not supported");
                 // synopsys translate_on
                 `endif
                 end
          2'b11: begin
                 get_next_addr_rd = addr;
                 // synopsys translate_off
                 $display($time,,"%m ERROR un-defined BURST %01x", burst);
                 // synopsys translate_on
                 end
          endcase
     end
     endfunction
     //-------------------------------------------------------------------------
     `ifdef BURST_TYPE_WRAPP_ENABLED
     function [ADDR_LENGTH-1:0] get_wrap_mask;
     input [ 2:0]      size ;
     `ifdef AMBA_AXI4
     input [ 7:0]      len  ; // burst length
     `else
     input [ 3:0]      len  ; // burst length
     `endif
     begin
          case (size)
          3'b000: get_wrap_mask = (    len)-1;
          3'b001: get_wrap_mask = (  2*len)-1;
          3'b010: get_wrap_mask = (  4*len)-1;
          3'b011: get_wrap_mask = (  8*len)-1;
          3'b100: get_wrap_mask = ( 16*len)-1;
          3'b101: get_wrap_mask = ( 32*len)-1;
          3'b110: get_wrap_mask = ( 64*len)-1;
          3'b111: get_wrap_mask = (128*len)-1;
          endcase
     end
     endfunction
     `endif
     //-------------------------------------------------------------------------
     function integer clogb2;
     input [31:0] value;
     reg   [31:0] tmp;
     begin
        tmp = value - 1;
        for (clogb2 = 0; tmp > 0; clogb2 = clogb2 + 1) tmp = tmp >> 1;
     end
     endfunction
     //-------------------------------------------------------------------------
     assign TrenX = ((stateR==STR_READ31)||(stateR==STR_READ32))
                  ? RREADY : Tren;
     //-------------------------------------------------------------------------
   //---------------------------------------------------------------------------
   //         __    __    __    __    __    __
   // clk   _|  |__|  |__|  |__|  |__|  |__|  |__|
   //         _____       _____
   // en    _|     |_____|     |_______
   //         _____
   // we    _|     |____________________
   //         ______      ______
   // addr  XX__A___X----X__B___X--------
   //         ______
   // di    XX__DA__X--------------------
   //                           ______
   // do    -------------------X__DB__X--
   //
     //-------------------------------------------------------------------------
   wire [3:0] Twr = {4{Twen}}&Twstrb;
     //-------------------------------------------------------------------------
   generate
   if (AXI_WIDTH_DA==32) begin : BLK_256BIT
      if (P_SIZE_IN_BYTES==16*1024) begin : BLK_16KB
          bram_simple_dual_port_32_16KB u_bram(
                .clka   ( ACLK   )
              , .ena    ( Twen   )
              , .addra  ( Twaddr[ADDR_LENGTH-1:AXI_WIDTH_DSB] )
              , .wea    ( Twstrb )
              , .dina   ( Twdata )
              , .clkb   ( ACLK   )
              , .enb    ( Tren   )
              , .addrb  ( Traddr[ADDR_LENGTH-1:AXI_WIDTH_DSB] )
              , .doutb  ( Trdata )
          );
      end else if (P_SIZE_IN_BYTES==32*1024) begin : BLK_32KB
          bram_simple_dual_port_32_32KB u_bram(
                .clka   ( ACLK   )
              , .ena    ( Twen   )
              , .addra  ( Twaddr[ADDR_LENGTH-1:AXI_WIDTH_DSB] )
              , .wea    ( Twstrb )
              , .dina   ( Twdata )
              , .clkb   ( ACLK   )
              , .enb    ( Tren   )
              , .addrb  ( Traddr[ADDR_LENGTH-1:AXI_WIDTH_DSB] )
              , .doutb  ( Trdata )
          );
      end else if (P_SIZE_IN_BYTES==64*1024) begin : BLK_64KB
          bram_simple_dual_port_32_64KB u_bram(
                .clka   ( ACLK   )
              , .ena    ( Twen   )
              , .addra  ( Twaddr[ADDR_LENGTH-1:AXI_WIDTH_DSB] )
              , .wea    ( Twstrb )
              , .dina   ( Twdata )
              , .clkb   ( ACLK   )
              , .enb    ( Tren   )
              , .addrb  ( Traddr[ADDR_LENGTH-1:AXI_WIDTH_DSB] )
              , .doutb  ( Trdata )
          );
    //end else if (P_SIZE_IN_BYTES==128*1024) begin : BLK_128KB
    //    bram_simple_dual_port_32_128KB u_bram(
    //          .clka   ( ACLK   )
    //        , .ena    ( Twen   )
    //        , .addra  ( Twaddr[ADDR_LENGTH-1:AXI_WIDTH_DSB] )
    //        , .wea    ( Twstrb )
    //        , .dina   ( Twdata )
    //        , .clkb   ( ACLK   )
    //        , .enb    ( Tren   )
    //        , .addrb  ( Traddr[ADDR_LENGTH-1:AXI_WIDTH_DSB] )
    //        , .doutb  ( Trdata )
    //    );
    //end else if (P_SIZE_IN_BYTES==256*1024) begin : BLK_256KB
    //    bram_simple_dual_port_32_256KB u_bram(
    //          .clka   ( ACLK   )
    //        , .ena    ( Twen   )
    //        , .addra  ( Twaddr[ADDR_LENGTH-1:AXI_WIDTH_DSB] )
    //        , .wea    ( Twstrb )
    //        , .dina   ( Twdata )
    //        , .clkb   ( ACLK   )
    //        , .enb    ( Tren   )
    //        , .addrb  ( Traddr[ADDR_LENGTH-1:AXI_WIDTH_DSB] )
    //        , .doutb  ( Trdata )
    //    );
      end else begin
          // synthesis translate_off
          initial begin
              $display("%m ERROR %d-KByte not supported\n", P_SIZE_IN_BYTES);
              $stop;
          end
          // synthesis translate_on
      end
   end else begin
       // synthesis translate_off
       initial begin
           $display("%m ERROR %d-bit not supported\n", AXI_WIDTH_DA);
           $stop;
       end
       // synthesis translate_on
   end // if (AXI_WIDTH_DA==32)
   endgenerate
     //-------------------------------------------------------------------------
endmodule
//------------------------------------------------------------------------------
// Revision History
//
// 2020.02.07: Write-Addr and Write-Data come at the same time.
// 2018.06.12: Tren at 'STR_READ31' changed by Ando Ki.
// 2018.05.01: Started by Ando Ki (adki@future-ds.com)
//------------------------------------------------------------------------------
