//----------------------------------------------------------------
//  Copyright (c) 2011 by Ando Ki.
//  All right reserved.
//  http://www.future-ds.com
//  All rights are reserved by Ando Ki.
//  Do not use in any means or/and methods without Ando Ki's permission.
//----------------------------------------------------------------
// axi_to_apb_s5.v
//----------------------------------------------------------------
// VERSION: 2011.04.05.
//----------------------------------------------------------------
// Limitation
//  - APB only supports 32-bit data width.
//  - Wrapping burst not supported.
//  - Exclusive-atomic access not supported.
//----------------------------------------------------------------
`timescale 1ns/1ns

`ifdef  AMBA_APB4
`ifndef AMBA_APB3
`define AMBA_APB3
`endif
`endif

module axi_to_apb
     #(parameter AXI_WIDTH_CID = 4 // Channel ID width in bits
               , AXI_WIDTH_ID  = 4 // ID width in bits
               , AXI_WIDTH_AD  =32 // address width
               , AXI_WIDTH_DA  =32 // data width
               , AXI_WIDTH_DS  =(AXI_WIDTH_DA/8) // data strobe width
               , AXI_WIDTH_SID =(AXI_WIDTH_CID+AXI_WIDTH_ID)
               , NUM_PSLAVE    = 1
               , WIDTH_PAD     =32 // address width
               , WIDTH_PDA     =32 // data width
               , WIDTH_PDS     =(WIDTH_PDA/8) // data strobe width
               )
(
       input  wire                     ARESETn
     , input  wire                     ACLK
     , input  wire [AXI_WIDTH_SID-1:0] AWID
     , input  wire [AXI_WIDTH_AD-1:0]  AWADDR
     `ifdef AMBA_AXI4
     , input  wire [ 7:0]              AWLEN
     , input  wire                     AWLOCK
     `else
     , input  wire [ 3:0]              AWLEN
     , input  wire [ 1:0]              AWLOCK
     `endif
     , input  wire [ 2:0]              AWSIZE
     , input  wire [ 1:0]              AWBURST
     `ifdef AMBA_AXI_CACHE
     , input  wire [ 3:0]              AWCACHE
     `endif
     `ifdef AMBA_AXI_PROT
     , input  wire [ 2:0]              AWPROT
     `endif
     , input  wire                     AWVALID
     , output wire                     AWREADY
     `ifdef AMBA_QOS
     , input  wire [ 3:0]              AWQOS
     , input  wire [ 3:0]              AWREGION
     `endif
     `ifndef AMBA_AXI4
     , input  wire [AXI_WIDTH_SID-1:0] WID
     `endif
     , input  wire [AXI_WIDTH_DA-1:0]  WDATA
     , input  wire [AXI_WIDTH_DS-1:0]  WSTRB
     , input  wire                     WLAST
     , input  wire                     WVALID
     , output wire                     WREADY
     , output wire [AXI_WIDTH_SID-1:0] BID
     , output wire [ 1:0]              BRESP
     , output wire                     BVALID
     , input  wire                     BREADY
     , input  wire [AXI_WIDTH_SID-1:0] ARID
     , input  wire [AXI_WIDTH_AD-1:0]  ARADDR
     `ifdef AMBA_AXI4
     , input  wire [ 7:0]              ARLEN
     , input  wire                     ARLOCK
     `else
     , input  wire [ 3:0]              ARLEN
     , input  wire [ 1:0]              ARLOCK
     `endif
     , input  wire [ 2:0]              ARSIZE
     , input  wire [ 1:0]              ARBURST
     `ifdef AMBA_AXI_CACHE
     , input  wire [ 3:0]              ARCACHE
     `endif
     `ifdef AMBA_AXI_PROT
     , input  wire [ 2:0]              ARPROT
     `endif
     , input  wire                     ARVALID
     , output wire                     ARREADY
     `ifdef AMBA_QOS
     , input  wire [ 3:0]              ARQOS
     , input  wire [ 3:0]              ARREGION
     `endif
     , output wire [AXI_WIDTH_SID-1:0] RID
     , output wire [AXI_WIDTH_DA-1:0]  RDATA
     , output wire [ 1:0]              RRESP
     , output wire                     RLAST
     , output wire                     RVALID
     , input  wire                     RREADY
     //-----------------------------------------------------------
     , input  wire                     PRESETn
     , input  wire                     PCLK
     , output wire [WIDTH_PAD-1:0]     PADDR
     , output wire                     PENABLE
     , output wire                     PWRITE
     , output wire [WIDTH_PDA-1:0]     PWDATA
     , output wire                     PSEL
     , input  wire [WIDTH_PDA-1:0]     PRDATA
     //-----------------------------------------------------------
     `ifdef AMBA_APB3
     , input  wire                     PREADY
     , input  wire                     PSLVERR
     `endif
     `ifdef AMBA_APB4
     , output wire [WIDTH_PDS-1:0]     PSTRB
     , output wire [ 2:0]              PPROT
     `endif
);
     //-----------------------------------------------------------
     wire                 APB_REQ  ;
     wire                 APB_ACK  ;
     wire [WIDTH_PAD-1:0] APB_ADDR ;
     wire                 APB_WR   ;
     wire [WIDTH_PDA-1:0] APB_DATAW;
     wire [WIDTH_PDA-1:0] APB_DATAR;
     wire [WIDTH_PDS-1:0] APB_BE   ;
     wire [ 2:0]          APB_PROT ;
     wire                 APB_ERROR;
     //-----------------------------------------------------------
     axi2apb_axi_if #(.AXI_WIDTH_SID(AXI_WIDTH_SID)// Channel ID width in bits
                     ,.AXI_WIDTH_AD (AXI_WIDTH_AD )// address width
                     ,.AXI_WIDTH_DA (AXI_WIDTH_DA )// data width
                     ,.APB_WIDTH_PAD(WIDTH_PAD    )// APB address width
                     )
     u_axi2apb_axi_if (
            .ARESETn            (ARESETn    )
          , .ACLK               (ACLK       )
          , .AWID               (AWID       )
          , .AWADDR             (AWADDR     )
          , .AWLEN              (AWLEN      )
          , .AWLOCK             (AWLOCK     )
          , .AWSIZE             (AWSIZE     )
          , .AWBURST            (AWBURST    )
          `ifdef AMBA_AXI_CACHE
          , .AWCACHE            (AWCACHE    )
          `endif
          `ifdef AMBA_AXI_PROT
          , .AWPROT             (AWPROT     )
          `endif
          , .AWVALID            (AWVALID    )
          , .AWREADY            (AWREADY    )
          `ifdef AMBA_QOS
          , .AWQOS              (AWQOS      )
          , .AWREGION           (AWREGION   )
          `endif
          `ifndef AMBA_AXI4
          , .WID                (WID        )
          `endif
          , .WDATA              (WDATA      )
          , .WSTRB              (WSTRB      )
          , .WLAST              (WLAST      )
          , .WVALID             (WVALID     )
          , .WREADY             (WREADY     )
          , .BID                (BID        )
          , .BRESP              (BRESP      )
          , .BVALID             (BVALID     )
          , .BREADY             (BREADY     )
          , .ARID               (ARID       )
          , .ARADDR             (ARADDR     )
          , .ARLEN              (ARLEN      )
          , .ARLOCK             (ARLOCK     )
          , .ARSIZE             (ARSIZE     )
          , .ARBURST            (ARBURST    )
          `ifdef AMBA_AXI_CACHE
          , .ARCACHE            (ARCACHE    )
          `endif
          `ifdef AMBA_AXI_PROT
          , .ARPROT             (ARPROT     )
          `endif
          , .ARVALID            (ARVALID    )
          , .ARREADY            (ARREADY    )
          `ifdef AMBA_QOS
          , .ARQOS              (ARQOS      )
          , .ARREGION           (ARREGION   )
          `endif
          , .RID                (RID         )
          , .RDATA              (RDATA       )
          , .RRESP              (RRESP       )
          , .RLAST              (RLAST       )
          , .RVALID             (RVALID      )
          , .RREADY             (RREADY      )
          , .REQ                (APB_REQ     ) // need synchronize
          , .ACK                (APB_ACK     )
          , .ADDR               (APB_ADDR    )
          , .WR                 (APB_WR      )
          , .DATAW              (APB_DATAW   )
          , .DATAR              (APB_DATAR   )
          , .BE                 (APB_BE      )
          , .PROT               (APB_PROT    )
          , .ERROR              (APB_ERROR   )
     );
     //-----------------------------------------------------------
     axi2apb_apb_if #(.NUM_PSLAVE   (NUM_PSLAVE   )
                     ,.WIDTH_PAD    (WIDTH_PAD    )
                     ,.WIDTH_PDA    (WIDTH_PDA    )
                     )
     u_axi2apb_apb (
          .PRESETn   (PRESETn   )
        , .PCLK      (PCLK      )
        , .PADDR     (PADDR     )
        , .PENABLE   (PENABLE   )
        , .PWRITE    (PWRITE    )
        , .PWDATA    (PWDATA    )
        , .PSEL      (PSEL      )
        , .PRDATA    (PRDATA    )
        `ifdef AMBA_APB3
        , .PREADY    (PREADY    )
        , .PSLVERR   (PSLVERR   )
        `endif
        `ifdef AMBA_APB4
        , .PSTRB     (PSTRB     )
        , .PPROT     (PPROT     )
        `endif
        , .SEL    (1'b1     )
        , .REQ    (APB_REQ  )
        , .ACK    (APB_ACK  )
        , .ADDR   (APB_ADDR )
        , .WR     (APB_WR   )
        , .DATAW  (APB_DATAW)
        , .DATAR  (APB_DATAR)
        , .BE     (APB_BE   )
        , .PROT   (APB_PROT )
        , .ERROR  (APB_ERROR)
     );
     //-----------------------------------------------------------
     // synopsys translate_off
     initial begin
         if (WIDTH_PDA!=32) $display("%m ERROR WIDTH_PDA(%3d) should be 32", WIDTH_PDA);
         if (AXI_WIDTH_DA<WIDTH_PDA) $display("%m ERROR AXI_WIDTH_DA(%3d) should be larger than WIDTH_PDS(%3d)", AXI_WIDTH_DA, WIDTH_PDA);
     end
     // synopsys translate_on
     //-----------------------------------------------------------
endmodule
//----------------------------------------------------------------
// Revision History
//
// 2011.04.05: Revised 'address overlap test part' by Ando Ki.
// 2011.02.25: 'PRESETn' added by Ando Ki.
//             It is related to 'PCLK'.
// 2011.02.16: 'PSTRB_R' changed by Ando Ki.
//             'WIDTH_XX' --> 'AXI_WIDTH_XX'
// 2011.01.29: Staryted by Ando Ki (adki@future-ds.com)
//----------------------------------------------------------------
//---------------------------------------------------------------
//  Copyright (c) 2011 by Future Design Systems Co., Ltd.
//  All right reserved.
//  http://www.future-ds.com
//---------------------------------------------------------------
//  axi2apb_axi_if.v
//---------------------------------------------------------------
//  VERSION: 2011.02.18.
//---------------------------------------------------------------
// [MACROS]
//---------------------------------------------------------------
// [PARAMTERS]
//---------------------------------------------------------------
// [Limitation]
//  - Exclusive atomic not supported.
//---------------------------------------------------------------
//          __    __    __    __    __    __    __    __
// ACLK  __|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__
//          _________________
// REQ   __|                 |_____________________________
//                      _____
// ACK   ______________|     |_____________________________
//         __________________
// ADDR  XX______________A___XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
//         __________________
// DATAW XX______________DW__XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
//                            _____
// DATAR XXXXXXXXXXXXXXXXXXXXX_DR__XXXXXXXXXXXXXXXXXXXXXXXX
// 
//---------------------------------------------------------------
`timescale 1ns/1ns

module axi2apb_axi_if
     #(parameter AXI_WIDTH_CID  = 4 // Channel ID width in bits
               , AXI_WIDTH_ID   = 4 // ID width in bits
               , AXI_WIDTH_AD   =32 // address width
               , AXI_WIDTH_DA   =32 // data width
               , AXI_WIDTH_DS   =(AXI_WIDTH_DA/8)  // data strobe width
               , AXI_WIDTH_DSB  =clogb2(AXI_WIDTH_DS) // data strobe width
               , AXI_WIDTH_SID  =(AXI_WIDTH_CID+AXI_WIDTH_ID)
               , APB_WIDTH_PAD  =32 // APB address width
               )
(
       input  wire                     ARESETn
     , input  wire                     ACLK
     , input  wire [AXI_WIDTH_SID-1:0] AWID
     , input  wire [AXI_WIDTH_AD-1:0]  AWADDR
     `ifdef AMBA_AXI4
     , input  wire [ 7:0]              AWLEN
     , input  wire                     AWLOCK
     `else
     , input  wire [ 3:0]              AWLEN
     , input  wire [ 1:0]              AWLOCK
     `endif
     , input  wire [ 2:0]              AWSIZE
     , input  wire [ 1:0]              AWBURST
     `ifdef AMBA_AXI_CACHE
     , input  wire [ 3:0]              AWCACHE
     `endif
     `ifdef AMBA_AXI_PROT
     , input  wire [ 2:0]              AWPROT
     `endif
     , input  wire                     AWVALID
     , output reg                      AWREADY
     `ifdef AMBA_QOS
     , input  wire [ 3:0]              AWQOS
     , input  wire [ 3:0]              AWREGION
     `endif
     `ifndef AMBA_AXI4
     , input  wire [AXI_WIDTH_SID-1:0] WID
     `endif
     , input  wire [AXI_WIDTH_DA-1:0]  WDATA
     , input  wire [AXI_WIDTH_DS-1:0]  WSTRB
     , input  wire                     WLAST
     , input  wire                     WVALID
     , output reg                      WREADY
     , output reg  [AXI_WIDTH_SID-1:0] BID
     , output reg  [ 1:0]              BRESP
     , output reg                      BVALID
     , input  wire                     BREADY
     , input  wire [AXI_WIDTH_SID-1:0] ARID
     , input  wire [AXI_WIDTH_AD-1:0]  ARADDR
     `ifdef AMBA_AXI4
     , input  wire [ 7:0]              ARLEN
     , input  wire                     ARLOCK
     `else
     , input  wire [ 3:0]              ARLEN
     , input  wire [ 1:0]              ARLOCK
     `endif
     , input  wire [ 2:0]              ARSIZE
     , input  wire [ 1:0]              ARBURST
     `ifdef AMBA_AXI_CACHE
     , input  wire [ 3:0]              ARCACHE
     `endif
     `ifdef AMBA_AXI_PROT
     , input  wire [ 2:0]              ARPROT
     `endif
     , input  wire                     ARVALID
     , output reg                      ARREADY
     `ifdef AMBA_QOS
     , input  wire [ 3:0]              ARQOS
     , input  wire [ 3:0]              ARREGION
     `endif
     , output reg  [AXI_WIDTH_SID-1:0] RID
     , output reg  [AXI_WIDTH_DA-1:0]  RDATA
     , output reg  [ 1:0]              RRESP
     , output reg                      RLAST
     , output reg                      RVALID
     , input  wire                     RREADY
     //-----------------------------------------------------------
     , output reg                      REQ
     , input  wire                     ACK    // need sync
     , output reg  [APB_WIDTH_PAD-1:0] ADDR
     , output reg                      WR
     , output reg  [31:0]              DATAW
     , input  wire [31:0]              DATAR
     , output reg  [ 3:0]              BE
     , output reg  [ 2:0]              PROT
     , input  wire                     ERROR
);
     //-----------------------------------------------------------
     reg  [APB_WIDTH_PAD-1:0] Twaddr ;
     reg  [31:0]              Twdata ;
     reg  [ 3:0]              Twstrb ;
     reg                      Twen   ;
     reg  [ 2:0]              Twprot ;
     reg  [APB_WIDTH_PAD-1:0] Traddr ;
     wire [31:0]              Trdata  = DATAR;
     reg  [ 3:0]              Trstrb ;
     reg                      Tren   ;
     reg  [ 2:0]              Trprot ;
     wire                     Tack   ; // ACK_sync;
     //-----------------------------------------------------------
     reg                     grant_write;
     reg                     grant_read ;
     //-----------------------------------------------------------
     always @ ( * ) begin
         case ({grant_write,grant_read})
         2'b10: begin // write-case
                REQ   = Twen  ;
                ADDR  = Twaddr;
                WR    = 1'b1  ;
                DATAW = Twdata; // be careful WDATA (AXI)
                BE    = Twstrb;
                PROT  = Twprot;
                end
         2'b01: begin // read-case
                REQ   = Tren  ;
                ADDR  = Traddr;
                WR    = 1'b0  ;
                DATAW =  'h0  ;
                BE    = Trstrb;
                PROT  = Trprot;
                end
         2'b00: begin
                REQ   = 1'b0;
                ADDR  =  'h0;
                WR    = 1'b0;
                DATAW =  'h0; // be careful WDATA (AXI)
                BE    = 4'h0;
                PROT  =  'h0;
                end
         2'b11: begin
                REQ   = 1'b0;
                ADDR  =  'h0;
                WR    = 1'b0;
                DATAW =  'h0; // be careful WDATA (AXI)
                BE    = 4'h0;
                PROT  =  'h0;
                // synopsys translate_off
                $display($time,,"%m ERROR both granted");
                // synopsys translate_on
                end
         endcase
     end
     //-----------------------------------------------------------
     reg ACK_sync, ACK_sync0;
     always @ (posedge ACLK or negedge ARESETn) begin
         if (ARESETn==1'b0) begin
             ACK_sync  <= 1'b0;
             ACK_sync0 <= 1'b0;
         end else begin
             ACK_sync  <= ACK_sync0;
             ACK_sync0 <= ACK;
         end
     end
     assign Tack = ACK_sync;
     //-----------------------------------------------------------
     // write case
     //-----------------------------------------------------------
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
     reg  [AXI_WIDTH_DA-1:0]  WDATA_reg  ;
     reg  [AXI_WIDTH_DS-1:0]  WSTRB_reg  ;
     //-----------------------------------------------------------
     reg  [APB_WIDTH_PAD-1:0] addrW; // address of each transfer within a burst
     reg  [APB_WIDTH_PAD-1:0] addrWT;// address of each transfer within a beat
     `ifdef AMBA_AXI4
     reg  [ 7:0]              beatW; // keeps num of transfers within a burst
     `else
     reg  [ 3:0]              beatW; // keeps num of transfers within a burst
     `endif
     //-----------------------------------------------------------
     reg  [ 3:0]         tickW;
     wire [ 3:0]         AWTICK = (AXI_WIDTH_DA/32); // num of words in a data-bus
     //-----------------------------------------------------------
     reg [2:0] stateW;
     localparam STW_IDLE        = 'h0,
                STW_RUN         = 'h1,
                STW_WRITE0      = 'h2,
                STW_WRITE1      = 'h3,
                STW_WRITE1_VOID = 'h4,
                STW_WRITE2      = 'h5,
                STW_WRITE       = 'h6,
                STW_RSP         = 'h7;
     always @ (posedge ACLK or negedge ARESETn) begin
         if (ARESETn==1'b0) begin
             AWID_reg    <=  'h0;
             AWADDR_reg  <=  'h0;
             AWLEN_reg   <=  'h0;
             AWSIZE_reg  <=  'b0;
             AWBURST_reg <=  'b0;
             AWLOCK_reg  <=  'b0;
             AWCACHE_reg <=  'h0;
             AWPROT_reg  <=  'b0;
             AWREADY     <= 1'b0;
             WREADY      <= 1'b0;
             WDATA_reg   <=  'h0;
             WSTRB_reg   <=  'h0;
             BID         <=  'h0;
             BRESP       <= 2'b10; // SLAVE ERROR
             BVALID      <= 1'b0;
             addrW       <=  'h0;
             addrWT      <=  'h0;
             beatW       <=  'h0;
             Twaddr      <=  'h0;
             Twdata      <=  'h0;
             Twstrb      <=  'h0;
             Twen        <= 1'b0;
             Twprot      <=  'h0;
             tickW       <=  'h0;
             grant_write <= 1'b0;
             stateW      <= STW_IDLE;
         end else begin
             case (stateW)
             STW_IDLE: begin
                 if ((AWVALID==1'b1)&&(grant_read==1'b0)) begin
                      AWREADY     <= 1'b1;
                      grant_write <= 1'b1;
                      AWID_reg    <= AWID   ;
                      AWADDR_reg  <= AWADDR ;
                      AWLEN_reg   <= AWLEN  ;
                      AWSIZE_reg  <= AWSIZE ;
                      AWBURST_reg <= AWBURST;
                      AWLOCK_reg  <= AWLOCK ;
                      `ifdef AMBA_AXI_CACHE
                      AWCACHE_reg <= AWCACHE;
                      `else
                      AWCACHE_reg <= 0;
                      `endif
                      `ifdef AMBA_AXI_PROT
                      AWPROT_reg  <= AWPROT ;
                      `else
                      AWPROT_reg  <= 0;
                      `endif
                      stateW      <= STW_RUN;
                 end
                 end // STW_IDLE
             STW_RUN: begin
                 AWREADY     <= 1'b0;
                 WREADY      <= 1'b1;
                 BRESP       <= 2'b00; // OKAY
                 addrW       <= AWADDR_reg[APB_WIDTH_PAD-1:0];
                 addrWT      <= AWADDR_reg[APB_WIDTH_PAD-1:0];
                 beatW       <=  'h0;
                 tickW       <= get_tick_wr(AWADDR_reg[7:0]); //get_tick_wr(AWADDR_reg[AXI_WIDTH_DSB-1:0]);
                 stateW      <= STW_WRITE0;
                 `ifdef RIGOR
                 // synopsys translate_off
                 if (AWVALID!=1'b1) begin
                   $display($time,,"%m ERROR AWVALID should be 1 at this point");
                 end
                 // synopsys translate_on
                 `endif
                 end // STW_RUN
             STW_WRITE0: begin
                 if (WVALID==1'b1) begin
                     WDATA_reg <= WDATA;
                     WSTRB_reg <= WSTRB;
                     Twaddr    <= addrWT;
                     Twdata    <= get_data_wr(addrWT,WDATA);
                     Twstrb    <= get_strb_wr(addrWT,WSTRB);
                     Twen      <= 1'b1;
                     `ifdef AMBA_AXI_PROT
                     Twprot    <= AWPROT_reg;
                     `else
                     Twprot    <=  'h0;
                     `endif
                     tickW     <= tickW + 1;
                     if (beatW>=AWLEN_reg) begin
                         if (WLAST==1'b0) BRESP <= 2'b10; // SLVERR - missing last
                     end
                     `ifndef AMBA_AXI4
                     if (WID!=AWID_reg) BRESP <= 2'b10; // SLVERR - ID mis-match occured
                     `endif
                     WREADY <= 1'b0;
                     stateW <= STW_WRITE1;
                 end else begin
                     Twen   <= 1'b0;
                 end
                 end // STW_WRITE0
             STW_WRITE1: begin
                 if (Tack==1'b1) begin
                     Twen <= 1'b0;
                     if (tickW>=AWTICK) begin
                        beatW  <= beatW + 1;
                        addrW  <= get_next_addr_wr(addrW,AWSIZE_reg,AWBURST_reg);
                        addrWT <= get_next_addr_wr(addrW,AWSIZE_reg,AWBURST_reg);
                        if (beatW>=AWLEN_reg) begin
                            BID    <= AWID_reg;
                            tickW  <=  'h0;
                            stateW <= STW_RSP;
                        end else begin
                            tickW  <=  'h0; // it should be 0
                            stateW <= STW_WRITE;
                        end
                     end else begin
                         addrWT <= addrWT+4; // because TCM is 32-bit wide
                         stateW <= STW_WRITE2;
                     end
                 end
                 end // STW_WRITE1
             STW_WRITE1_VOID: begin
                 if (tickW>=AWTICK) begin
                    beatW  <= beatW + 1;
                    addrW  <= get_next_addr_wr(addrW,AWSIZE_reg,AWBURST_reg);
                    addrWT <= get_next_addr_wr(addrW,AWSIZE_reg,AWBURST_reg);
                    if (beatW>=AWLEN_reg) begin
                        BID    <= AWID_reg;
                        tickW  <=  'h0;
                        stateW <= STW_RSP;
                    end else begin
                        tickW  <=  'h0; // it should be 0
                        stateW <= STW_WRITE;
                    end
                 end else begin
                     addrWT <= addrWT+4; // because TCM is 32-bit wide
                     stateW <= STW_WRITE2;
                 end
                 end // STW_WRITE1
             STW_WRITE2: begin
                 if (Tack==1'b0) begin
                     tickW  <= tickW + 1;
                     if (|get_strb_wr(addrWT,WSTRB_reg)) begin
                         Twaddr <= addrWT;
                         Twdata <= get_data_wr(addrWT,WDATA_reg);
                         Twstrb <= get_strb_wr(addrWT,WSTRB_reg);
                         Twen   <= 1'b1;
                         stateW <= STW_WRITE1;
                     end else begin
                         Twdata <= 'h0;
                         Twstrb <= 'h0;
                         stateW <= STW_WRITE1_VOID;
                     end
                 end
                 end // STW_WRITE2
             STW_WRITE: begin
                 if (Tack==1'b0) begin
                     WREADY <= 1'b1;
                     stateW <= STW_WRITE0;
                 end
                 end // STW_WRITE
             STW_RSP: begin
                 if (Tack==1'b0) begin
                     grant_write <= 1'b0;
                     if ((BREADY==1'b1)&&(BVALID==1'b1)) begin
                         BVALID  <= 1'b0;
                         stateW  <= STW_IDLE;
                     end else begin
                         BVALID <= 1'b1;
                     end
                 end
                 end // STW_RSP
             endcase
         end
     end
     //-----------------------------------------------------------
     // read case
     //-----------------------------------------------------------
     reg  [AXI_WIDTH_AD-1:0] ARADDR_reg ;
     `ifdef AMBA_AXI4
     reg  [ 7:0]             ARLEN_reg  ;
     reg                     ARLOCK_reg ;
     `else
     reg  [ 3:0]             ARLEN_reg  ;
     reg  [ 1:0]             ARLOCK_reg ;
     `endif
     reg  [ 2:0]             ARSIZE_reg ;
     reg  [ 1:0]             ARBURST_reg;
     reg  [ 3:0]             ARCACHE_reg;
     reg  [ 2:0]             ARPROT_reg ;
     reg  [AXI_WIDTH_DS-1:0] ARSTRB_reg ;
     //-----------------------------------------------------------
     reg  [APB_WIDTH_PAD-1:0] addrR ;// address of each transfer within a burst
     reg  [APB_WIDTH_PAD-1:0] addrRT;// address of each transfer within a beat
     `ifdef AMBA_AXI4
     reg  [ 7:0]              beatR; // keeps num of transfers within a burst
     `else
     reg  [ 3:0]              beatR; // keeps num of transfers within a burst
     `endif
     //-----------------------------------------------------------
     reg  [ 3:0] tickR;
     wire [ 3:0] ARTICK = (AXI_WIDTH_DA/32); // num of words in a data-bus
     //-----------------------------------------------------------
     reg [2:0] stateR;
     localparam STR_IDLE      = 'h0,
                STR_RUN       = 'h1,
                STR_WAIT      = 'h2,
                STR_WAIT_VOID = 'h3,
                STR_TICK      = 'h4,
                STR_READ0     = 'h5,
                STR_READ1     = 'h6,
                STR_END       = 'h7;
     always @ (posedge ACLK or negedge ARESETn) begin
         if (ARESETn==1'b0) begin
             ARADDR_reg  <=  'h0;
             ARLEN_reg   <=  'h0;
             ARLOCK_reg  <=  'b0;
             ARSIZE_reg  <=  'b0;
             ARBURST_reg <=  'b0;
             ARCACHE_reg <=  'h0;
             ARPROT_reg  <=  'b0;
             ARSTRB_reg  <=  'h0;
             ARREADY     <= 1'b0;
             RID         <=  'h0;
             RLAST       <= 1'b0;
             RRESP       <= 2'b10; // SLAERROR
             RDATA       <=  'h0;
             RVALID      <= 1'b0;
             addrR       <=  'h0;
             addrRT      <=  'h0;
             beatR       <=  'h0;
             Traddr      <=  'h0;
             Trstrb      <=  'h0;
             Tren        <= 1'b0;
             Trprot      <=  'h0;
             tickR       <=  'h0;
             grant_read  <= 1'b0;
             stateR      <= STR_IDLE;
         end else begin
             case (stateR)
             STR_IDLE: begin
                 if ((ARVALID==1'b1)&&(AWVALID==1'b0)&&(grant_write==1'b0)) begin
                      grant_read  <= 1'b1;
                      ARREADY     <= 1'b1;
                      ARADDR_reg  <= ARADDR ;
                      ARLEN_reg   <= ARLEN  ;
                      ARSIZE_reg  <= ARSIZE ;
                      ARBURST_reg <= ARBURST;
                      ARLOCK_reg  <= ARLOCK ;
                      `ifdef AMBA_AXI_CACHE
                      ARCACHE_reg <= ARCACHE;
                      `else
                      ARCACHE_reg <= 0;
                      `endif
                      `ifdef AMBA_AXI_PROT
                      ARPROT_reg  <= ARPROT ;
                      `else
                      ARPROT_reg  <= 0;
                      `endif
                      ARSTRB_reg  <= make_strb_rd(ARADDR[AXI_WIDTH_DSB-1:0],ARSIZE);
                      addrR       <= ARADDR[APB_WIDTH_PAD-1:0];
                      addrRT      <= ARADDR[APB_WIDTH_PAD-1:0];
                      stateR      <= STR_RUN;
                 end
                 end // STR_IDLE
             STR_RUN: begin
                 ARREADY     <= 1'b0;
                 RID         <= ARID;
                 RDATA       <=  'h0; // it should be here
                 beatR       <=  'h0;
                 tickR       <= get_tick_rd(addrRT[7:0]);
                 Traddr      <= addrRT;
                 Trstrb      <= get_strb_rd(addrRT,ARSTRB_reg);
                 Tren        <= 1'b1;
                 `ifdef AMBA_AXI_PROT
                 Trprot      <= ARPROT_reg;
                 `else
                 Trprot      <=  'h0;
                 `endif
                 stateR      <= STR_WAIT;
                 end // STR_RUN
             STR_WAIT: begin
                 if (Tack) begin
                    Tren   <= 1'b0;
                    RDATA  <= get_data_rd(RDATA,addrRT,Trdata,ARSIZE_reg);
                    if (tickR>=ARTICK) begin
                        addrR  <= get_next_addr_rd(addrR,ARSIZE_reg,ARBURST_reg);
                        addrRT <= get_next_addr_rd(addrR,ARSIZE_reg,ARBURST_reg);
                        tickR  <= 'h0; // since new beat
                        stateR <= STR_READ0;
                    end else begin
                        addrRT <= addrRT + 4; // since TCM is 32-bit width
                        stateR <= STR_TICK;
                    end
                 end
                 end // STR_WAIT
             STR_WAIT_VOID: begin
                 if (tickR>=ARTICK) begin
                     addrR  <= get_next_addr_rd(addrR,ARSIZE_reg,ARBURST_reg);
                     addrRT <= get_next_addr_rd(addrR,ARSIZE_reg,ARBURST_reg);
                     tickR  <= 'h0; // since new beat
                     stateR <= STR_READ0;
                 end else begin
                     addrRT <= addrRT + 4; // since TCM is 32-bit width
                     stateR <= STR_TICK;
                 end
                 end // STR_WAIT
             STR_TICK: begin
                 if (Tack==1'b0) begin
                     tickR  <= tickR + 1;
                     if (|get_strb_rd(addrRT,ARSTRB_reg)) begin
                          Tren   <= 1'b1;
                          Traddr <= addrRT;
                          Trstrb <= get_strb_rd(addrRT,ARSTRB_reg);
                          stateR <= STR_WAIT;
                     end else begin
                          stateR <= STR_WAIT_VOID; // nothing to read
                     end
                 end
                 end // STR_TICK
             STR_READ0: begin
                 if (Tack==1'b0) begin
                     if (beatR>=ARLEN_reg) begin
                         RLAST      <= 1'b1;
                         RRESP      <= 2'b00;
                         RVALID     <= 1'b1;
                         grant_read <= 1'b0;
                         stateR     <= STR_END;
                     end else begin
                         RLAST      <= 1'b0;
                         RRESP      <= 2'b00;
                         RVALID     <= 1'b1;
                         ARSTRB_reg <= make_strb_rd(addrR[AXI_WIDTH_DSB-1:0],ARSIZE_reg);
                         stateR     <= STR_READ1;
                     end
                 end
                 end // STR_READ0
             STR_READ1: begin
                 if (RREADY) begin
                     RVALID <= 1'b0;
                     RDATA  <= 'h0;
                     Tren   <= 1'b1;
                     Traddr <= addrRT;
                     Trstrb <= get_strb_rd(addrRT,ARSTRB_reg);
                     tickR  <= 'h1;
                     beatR  <= beatR + 1;
                     stateR <= STR_WAIT;
                 end
                 end // STR_READ1
             STR_END: begin // data only
                 if (RREADY==1'b1) begin
                     RLAST   <= 1'b0;
                     RVALID  <= 1'b0;
                     stateR <= STR_IDLE;
                 end
                 end // STR_END
             endcase
         end
     end
     //-----------------------------------------------------------
     function [3:0] get_strb_wr;
          input [APB_WIDTH_PAD-1:0]  addr;
          input [AXI_WIDTH_DS-1:0] strb;  // num. of byte to move: 0=1-byte, 1=2-byte
     begin
          case (AXI_WIDTH_DS)
           4: get_strb_wr = strb;
           8: case (addr[2])
              0: get_strb_wr = strb;
              1: get_strb_wr = strb>>4;
              endcase
          16: case (addr[3:2])
              2'b00: get_strb_wr = strb;
              2'b01: get_strb_wr = strb>>4;
              2'b10: get_strb_wr = strb>>8;
              2'b11: get_strb_wr = strb>>12;
              endcase
          default: begin
                   get_strb_wr = strb;
                   // synopsys translate_off
                   $display($time,,"%m ERROR un-supported WSTRB width %2d", AXI_WIDTH_DS);
                   // synopsys translate_on
                   end
          endcase
     end
     endfunction
     //-----------------------------------------------------------
     function [3:0] get_strb_rd;
          input [APB_WIDTH_PAD-1:0]  addr;
          input [AXI_WIDTH_DS-1:0] strb;  // num. of byte to move: 0=1-byte, 1=2-byte
     begin
          case (AXI_WIDTH_DS)
           4: get_strb_rd = strb;
           8: case (addr[2])
              0: get_strb_rd = strb;
              1: get_strb_rd = strb>>4;
              endcase
          16: case (addr[3:2])
              2'b00: get_strb_rd = strb;
              2'b01: get_strb_rd = strb>>4;
              2'b10: get_strb_rd = strb>>8;
              2'b11: get_strb_rd = strb>>12;
              endcase
          default: begin
                   get_strb_rd = strb;
                   // synopsys translate_off
                   $display($time,,"%m ERROR un-supported WSTRB width %2d", AXI_WIDTH_DS);
                   // synopsys translate_on
                   end
          endcase
     end
     endfunction
     //-----------------------------------------------------------
     function [AXI_WIDTH_DS-1:0] make_strb_rd;
          input [AXI_WIDTH_DSB-1:0] addr;
          input [ 2:0]              size; // 0=1-byte, 1=2-byte
          reg   [127:0]             strb;
     begin
          case (size)
          3'b000: strb = {   1{1'b1}}<<addr; // one-byte
          3'b001: strb = {   2{1'b1}}<<addr; // two-byte
          3'b010: strb = {   4{1'b1}}<<addr; // four-byte
          3'b011: strb = {   8{1'b1}}<<addr;
          3'b100: strb = {  16{1'b1}}<<addr;
          3'b101: strb = {  32{1'b1}}<<addr;
          3'b110: strb = { 64{1'b1}}<<addr;
          3'b111: strb = {128{1'b1}}<<addr;
          endcase
          make_strb_rd = strb[AXI_WIDTH_DS-1:0];
     end
     endfunction
     //-----------------------------------------------------------
     function [APB_WIDTH_PAD-1:0] get_next_addr_wr;
          input [APB_WIDTH_PAD-1:0] addr ;
          input [ 2:0]            size ;
          input [ 1:0]            burst; // burst type
          reg   [APB_WIDTH_PAD-3:0] naddr;
          reg   [APB_WIDTH_PAD-1:0] mask ;
     begin
          case (burst)
          2'b00: get_next_addr_wr = addr;
          2'b01: begin
                 if ((1<<size)<AXI_WIDTH_DS) begin
                    get_next_addr_wr = addr + (1<<size);
                 end else begin
                     naddr = addr[APB_WIDTH_PAD-1:AXI_WIDTH_DSB] + 1;
                     get_next_addr_wr = {naddr,{AXI_WIDTH_DSB{1'b0}}};
                 end
                 end
          2'b10: begin
                 // synopsys translate_off
                 $display($time,,"%m ERROR BURST WRAP not supported");
                 // synopsys translate_on
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
     //-----------------------------------------------------------
     function [APB_WIDTH_PAD-1:0] get_next_addr_rd;
          input [APB_WIDTH_PAD-1:0] addr ;
          input [ 2:0]            size ;
          input [ 1:0]            burst; // burst type
          reg   [APB_WIDTH_PAD-3:0] naddr;
          reg   [APB_WIDTH_PAD-1:0] mask ;
     begin
          case (burst)
          2'b00: get_next_addr_rd = addr;
          2'b01: begin
                 if ((1<<size)<AXI_WIDTH_DS) begin
                    get_next_addr_rd = addr + (1<<size);
                 end else begin
                     naddr = addr[APB_WIDTH_PAD-1:AXI_WIDTH_DSB] + 1;
                     get_next_addr_rd = {naddr,{AXI_WIDTH_DSB{1'b0}}};
                 end
                 end
          2'b10: begin
                 // synopsys translate_off
                 $display($time,,"%m ERROR BURST WRAP not supported");
                 // synopsys translate_on
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
     //-----------------------------------------------------------
     function [31:0] get_data_wr;
          input [APB_WIDTH_PAD-1:0] addr;
          input [AXI_WIDTH_DA-1:0]    data;
     begin
          case (AXI_WIDTH_DA)
          32: get_data_wr = data;
          64: case (addr[2])
              0: get_data_wr = data;
              1: get_data_wr = data>>32;
              endcase
          128: case (addr[3:2])
              2'b00: get_data_wr = data;
              2'b01: get_data_wr = data>>32;
              2'b10: get_data_wr = data>>64;
              2'b11: get_data_wr = data>>96;
              endcase
          default: begin
                   get_data_wr = data;
                   // synopsys translate_off
                   $display($time,,"%m ERROR %d-bit AXI data bus not supported", AXI_WIDTH_DA);
                   // synopsys translate_on
                   end
          endcase
     end
     endfunction
     //-----------------------------------------------------------
     // It determines the first tick value
     function [3:0] get_tick_wr;
          //input [AXI_WIDTH_DSB-1:0] addr;
          input [7:0] addr;
     begin
          case (AXI_WIDTH_DA)
           32: get_tick_wr = 4'h0;
           64: case (addr[2])
               0: get_tick_wr = 4'h0;
               1: get_tick_wr = 4'h1;
               endcase
          128: case (addr[3:2])
               2'b00: get_tick_wr = 4'h0;
               2'b01: get_tick_wr = 4'h1;
               2'b10: get_tick_wr = 4'h2;
               2'b11: get_tick_wr = 4'h3;
               endcase
          default: begin
                   get_tick_wr = 'h0;
                   // synopsys translate_off
                   $display($time,,"%m ERROR %d-bit AXI data bus not supported", AXI_WIDTH_DA);
                   // synopsys translate_on
                   end
          endcase
     end
     endfunction
     //-----------------------------------------------------------
     // It determines the first tick value
     function [3:0] get_tick_rd;
          //input [AXI_WIDTH_DSB-1:0] addr;
          input [7:0] addr;
     begin
          case (AXI_WIDTH_DA)
           32: get_tick_rd = 4'h1;
           64: case (addr[2])
               0: get_tick_rd = 4'h1;
               1: get_tick_rd = 4'h2;
               endcase
          128: case (addr[3:2])
               2'b00: get_tick_rd = 4'h1;
               2'b01: get_tick_rd = 4'h2;
               2'b10: get_tick_rd = 4'h3;
               2'b11: get_tick_rd = 4'h4;
               endcase
          default: begin
                   get_tick_rd = 'h1;
                   // synopsys translate_off
                   $display($time,,"%m ERROR %d-bit AXI data bus not supported", AXI_WIDTH_DA);
                   // synopsys translate_on
                   end
          endcase
     end
     endfunction
     //-----------------------------------------------------------
     // It merges 'dataT' to 'dataR'.
     function [AXI_WIDTH_DA-1:0] get_data_rd;
          input [AXI_WIDTH_DA-1:0] dataR;
          input [APB_WIDTH_PAD-1:0]  addr;
          input [31:0]             dataT;
          input [ 2:0]             sizeR; // 0=1-byte
     begin
          case (AXI_WIDTH_DA)
          32: get_data_rd = dataT;
          64: case (addr[2])
              0: get_data_rd = dataT;
              1: get_data_rd = (dataT<<32)|dataR;
              endcase
          128: case (addr[3:2])
              2'b00: get_data_rd = dataT;
              2'b01: get_data_rd = (dataT<<32)|dataR;
              2'b10: get_data_rd = (dataT<<64)|dataR;
              2'b11: get_data_rd = (dataT<<96)|dataR;
              endcase
          default: begin
                   get_data_rd = dataT;
                   // synopsys translate_off
                   $display($time,,"%m ERROR %d-bit AXI data bus not supported", AXI_WIDTH_DA);
                   // synopsys translate_on
                   end
          endcase
     end
     endfunction
     //-----------------------------------------------------------
     function integer clogb2;
     input [31:0] value;
     reg   [31:0] tmp;
     begin
        tmp = value - 1;
        for (clogb2 = 0; tmp > 0; clogb2 = clogb2 + 1) tmp = tmp >> 1;
     end
     endfunction
     //-----------------------------------------------------------
endmodule
//---------------------------------------------------------------
// Revision history
//
// 2011.02.18: re-written by Ando Ki.
// 2011.01.21: start by Ando Ki (adki@future-ds.com)
//---------------------------------------------------------------
//----------------------------------------------------------------
//  Copyright (c) 2011 by Ando Ki.
//  All right reserved.
//  http://www.future-ds.com
//  All rights are reserved by Ando Ki.
//  Do not use in any means or/and methods without Ando Ki's permission.
//----------------------------------------------------------------
// axi2apb_apb_if.v
//----------------------------------------------------------------
// VERSION: 2011.02.25.
//----------------------------------------------------------------
// Limitation
//  - APB only supports 32-bit data width.
//----------------------------------------------------------------
`timescale 1ns/1ns

`ifdef  AMBA_APB4
`ifndef AMBA_APB3
`define AMBA_APB3
`endif
`endif

//----------------------------------------------------------------
module axi2apb_apb_if
     #(parameter NUM_PSLAVE   = 8
               , WIDTH_PAD    =32 // address width
               , WIDTH_PDA    =32 // data width
               , WIDTH_PDS    =(WIDTH_PDA/8) // data strobe width
               )
(
       input  wire                  PRESETn
     , input  wire                  PCLK
     , output reg  [NUM_PSLAVE-1:0] PSEL
     , output reg  [NUM_PSLAVE-1:0] PENABLE
     , output reg  [NUM_PSLAVE-1:0] PWRITE
     , output reg  [WIDTH_PAD-1:0]  PADDR
     , output reg  [WIDTH_PDA-1:0]  PWDATA
     , input  wire [WIDTH_PDA-1:0]  PRDATA
     //-----------------------------------------------------------
     `ifdef AMBA_APB3
     , input  wire [NUM_PSLAVE-1:0] PREADY
     , input  wire [NUM_PSLAVE-1:0] PSLVERR
     `endif
     `ifdef AMBA_APB4
     , output reg  [WIDTH_PDS-1:0]  PSTRB
     , output reg  [ 2:0]           PPROT
     `endif
     //-----------------------------------------------------------
     , input  wire [NUM_PSLAVE-1:0] SEL
     //-----------------------------------------------------------
     , input  wire                 REQ
     , output reg                  ACK    // need sync
     , input  wire [WIDTH_PAD-1:0] ADDR
     , input  wire                 WR
     , input  wire [31:0]          DATAW
     , output reg  [31:0]          DATAR
     , input  wire [ 3:0]          BE
     , input  wire [ 2:0]          PROT
     , output reg                  ERROR
     //-----------------------------------------------------------
);
     //-----------------------------------------------------------
     // synopsys translate_off
     initial begin
             if (WIDTH_PAD!=32) $display("%m ERROR APB address width should be 32, but %2d", WIDTH_PAD);
             if (WIDTH_PDA!=32) $display("%m ERROR APB data width should be 32, but %2d", WIDTH_PDA);
     end
     // synopsys translate_on
     //-----------------------------------------------------------
     `ifndef AMBA_APB3
     wire [NUM_PSLAVE-1:0] PREADY  = {NUM_PSLAVE{1'b1}};
     wire [NUM_PSLAVE-1:0] PSLVERR = {NUM_PSLAVE{1'b0}};
     `endif
     `ifndef AMBA_APB4
     reg  [WIDTH_PDS-1:0]  PSTRB;
     reg  [ 2:0]           PPROT;
     `endif
     //-----------------------------------------------------------
     reg req_sync0, req_sync;
     always @ (posedge PCLK or negedge PRESETn) begin
            if (PRESETn==1'b0) begin
                req_sync  <= 1'b0;
                req_sync0 <= 1'b0;
            end else begin
                req_sync  <= req_sync0;
                req_sync0 <= REQ;
            end
     end
     //-----------------------------------------------------------
     reg [1:0] state;
     localparam ST_IDLE  = 'h0,
                ST_ADDR  = 'h1,
                ST_WAIT  = 'h2,
                ST_END   = 'h3;
     //-----------------------------------------------------------
     always @ (posedge PCLK or negedge PRESETn) begin
            if (PRESETn==1'b0) begin
                PSEL      <=  'h0;
                PENABLE   <=  'h0;
                PWRITE    <=  'h0;
                PADDR     <=  'h0;
                PWDATA    <=  'h0;
                PSTRB     <=  'h0;
                PPROT     <=  'h0;
                ACK       <=  'b0;
                ERROR     <=  'b0;
                DATAR     <=  'h0;
                state     <= ST_IDLE;
            end else begin
                case (state)
                ST_IDLE: begin
                   if (req_sync) begin
                       PSEL   <= SEL;
                       PWRITE <= {NUM_PSLAVE{WR}}&SEL;
                       PADDR  <= ADDR;
                       PWDATA <= DATAW;
                       PSTRB  <= {WIDTH_PDS{WR}}&BE;
                       PPROT  <= PROT;
                       state  <= ST_ADDR;
                   end
                   end // STW_IDLE
                ST_ADDR: begin
                   PENABLE  <= SEL;
                   state    <= ST_WAIT;
                   end // ST_ADDR
                ST_WAIT: begin
                   if (PREADY) begin
                       ERROR     <= PSLVERR;
                       PSEL      <=  'h0;
                       PENABLE   <=  'h0;
                       DATAR     <= PRDATA;
                       ACK       <= 1'b1;
                       state     <= ST_END;
                   end
                   end // ST_WAIT
                ST_END: begin
                   if (req_sync==1'b0) begin
                       ACK      <= 1'b0;
                       state    <= ST_IDLE;
                   end
                   end // ST_END
                endcase
            end
     end
     //-----------------------------------------------------------
     // synopsys translate_off
     integer idx, pnum;
     always @ (negedge PCLK or negedge PRESETn) begin
          if (PRESETn==1'b1) begin
              pnum = 0;
              for (idx=0; idx<NUM_PSLAVE; idx=idx+1) begin
                   if (PSEL[idx]) pnum = pnum + 1;
              end
              if (pnum>1)  $display($time,,"%m ERROR more than one APB slave selected %b", PSEL);
          end
     end
     // synopsys translate_on
     //-----------------------------------------------------------
endmodule
//----------------------------------------------------------------
// Revision History
//
// 2011.02.25: 'PRESETn' added by Ando Ki.
//             It is related to 'PCLK'.
// 2011.02.18: Re-written by Ando Ki
// 2011.01.29: Staryted by Ando Ki (adki@future-ds.com)
//----------------------------------------------------------------
