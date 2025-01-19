//------------------------------------------------------------------------------
// Copyright (c) 2025 by Ando Ki.
// All right reserved.
//------------------------------------------------------------------------------
// VERSION: 2025.01.10.
//------------------------------------------------------------------------------
// DPU configuration
//------------------------------------------------------------------------------
module dpu_configuration
     #(parameter APB_WIDTH_AD =32
               , APB_WIDTH_DA =32
               , AXI_WIDTH_AD =32    // AXI address width
               , AXI_WIDTH_DA =32    // AXI data width
               , DATA_TYPE="FLOATING_POINT" // "INTEGER", "FLOATING_POINT", "FIXED_POINT"
               , DATA_WIDTH     =32  // bit-width of a whole part
               `ifdef DATA_FIXED_POINT
               , DATA_WIDTH_Q=(DATA_WIDTH/2) // fractional bits
               `endif
               )
(
      input  wire                     PRESETn
    , input  wire                     PCLK
    , input  wire                     PSEL
    , input  wire                     PENABLE
    , input  wire [APB_WIDTH_AD-1:0]  PADDR
    , input  wire                     PWRITE
    , output reg  [APB_WIDTH_DA-1:0]  PRDATA
    , input  wire [APB_WIDTH_DA-1:0]  PWDATA
    , output wire                     PREADY
    , output wire                     PSLVERR
    , input  wire                     module_convolution
    , input  wire                     module_pooling
    , input  wire                     module_linear
    , input  wire                     module_mover
);
   //---------------------------------------------------------------------------
   assign PREADY=1'b1;
   assign PSLVERR=1'b0;
   //---------------------------------------------------------------------------
   localparam T_ADDR_WID=8;
   //---------------------------------------------------------------------------
   wire [T_ADDR_WID-1:0]   T_ADDR =PADDR[T_ADDR_WID-1:0];
   wire                    T_WREN =PSEL& PWRITE;
   wire                    T_RDEN =PSEL&~PWRITE;
   //---------------------------------------------------------------------------
   // CSR address
   localparam CSRA_VERSION = 'h00
            , CSRA_BUS     = 'h10
            , CSRA_TYPE    = 'h14
            , CSRA_BITS    = 'h18
            , CSRA_MODULE  = 'h1C
            ;
   //---------------------------------------------------------------------------
   // CSR
   wire [31:0] csr_version=32'h20250110;
   //---------------------------------------------------------------------------
   // CSR read
   always @ (posedge PCLK or negedge PRESETn) begin
   if (PRESETn==1'b0) begin
       PRDATA <= {APB_WIDTH_DA{1'b0}};
   end else begin
      if (T_RDEN) begin
         case (T_ADDR)
           CSRA_VERSION: PRDATA <= csr_version;
           CSRA_BUS    : PRDATA <= {AXI_WIDTH_AD[15:0]
                                   ,AXI_WIDTH_DA[15:0]};
           CSRA_TYPE   : PRDATA <= (DATA_TYPE=="FLOATING_POINT") ? swap("FP")
                                 : (DATA_TYPE=="FIXED_POINT") ? swap("FX")
                                 : swap("IT");
           CSRA_BITS   : `ifdef DATA_FIXED_POINT
                         PRDATA <= {DATA_WIDTH_Q[15:0],DATA_WIDTH[15:0]};
                         `else
                         PRDATA <= {16'h0,DATA_WIDTH[15:0]};
                         `endif
           CSRA_MODULE:  PRDATA <= { 28'h0               //31:4
                                   , module_mover        //3
                                   , module_linear       //2
                                   , module_pooling      //1
                                   , module_convolution};//0
           default: begin
                    PRDATA <= 'h0;
                    end
         endcase
      end else PRDATA <= 'h0;
   end // if
   end // always
   //---------------------------------------------------------------------------
   // CSR write
 //always @ (posedge PCLK or negedge PRESETn) begin
 //if (PRESETn==1'b0) begin
 //end else begin
 //   if (T_WREN) begin
 //      case (T_ADDR)
 //      endcase
 //   end
 //end // if
 //end // always
   //---------------------------------------------------------------------------
   function [31:0] swap;
   input [31:0] data;
   begin
        swap[ 7: 0] = data[31:24];
        swap[15: 8] = data[23:16];
        swap[23:16] = data[15: 8];
        swap[31:24] = data[ 7: 0];
   end
   endfunction
endmodule

//------------------------------------------------------------------------------
// Revision history
//
// 2025.01.10: 'PREADY' and 'PSLVERR' added
// 2021.06.10: Started by Ando Ki (andoki@gmail.com)
//------------------------------------------------------------------------------
