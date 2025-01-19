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
`include "axi2apb_axi_if.v"
`include "axi2apb_apb_if.v"

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
