//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All right reserved.
//------------------------------------------------------------------------------
// VERSION: 2021.11.06.
//------------------------------------------------------------------------------
// DPU configuration
//------------------------------------------------------------------------------
module dpu_configuration
     #(parameter APB_WIDTH_AD =32
               , APB_WIDTH_DA =32
               , AXI_WIDTH_AD =32    // AXI address width
               , AXI_WIDTH_DA =32    // AXI data width
               , DATA_TYPE="INTEGER" // "INTEGER", "FLOATING_POINT", "FIXED_POINT"
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
);
   //---------------------------------------------------------------------------
   localparam T_ADDR_WID=8;
   //---------------------------------------------------------------------------
   wire [T_ADDR_WID-1:0]   T_ADDR =PADDR[T_ADDR_WID-1:0];
   wire                    T_WREN =PSEL& PWRITE;
   wire                    T_RDEN =PSEL&~PWRITE;
   //---------------------------------------------------------------------------
   // CSR address
   localparam CSRA_VERSION = 'h00
            , CSRA_CONFIG  = 'h10
            , CSRA_STATUS  = 'h20
            ;
   //---------------------------------------------------------------------------
   // CSR
   wire [31:0] csr_version=32'h20210610;
   //---------------------------------------------------------------------------
   // CSR read
   always @ (posedge PCLK or negedge PRESETn) begin
   if (PRESETn==1'b0) begin
       PRDATA <= 'h0;
   end else begin
      if (T_RDEN) begin
         (* full_case *)
         case (T_ADDR) // synthesis full_case parallel_case
           CSRA_VERSION: PRDATA <= csr_version;
           CSRA_CONFIG : PRDATA <= {AXI_WIDTH_AD[15:0]
                                   ,AXI_WIDTH_DA[15:0]
                                   };
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
 //      (* parallel_case *)
 //      case (T_ADDR) // synthesis parallel_case
 //      endcase
 //   end
 //end // if
 //end // always
endmodule

//------------------------------------------------------------------------------
// Revision history
//
// 2021.06.10: Started by Ando Ki (andoki@gmail.com)
//------------------------------------------------------------------------------
