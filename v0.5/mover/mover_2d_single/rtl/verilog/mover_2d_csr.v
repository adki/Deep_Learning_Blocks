//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All right reserved.
//------------------------------------------------------------------------------
// VERSION: 2021.11.06.
//------------------------------------------------------------------------------
// Mover 2D CSR
//------------------------------------------------------------------------------
// FILL
//                  +------------+
//                  |dst         |
//                  |            |
//                  |            |
//                  +------------+
//
// COPY, i.e., DMA
// +------------+   +------------+   srcA!=dst
// |srcA        |   |dst         |
// |            |==>|            |
// |            |   |            |
// +------------+   +------------+
//
// RESIDUAL, i.e., point-to-point adder
// +------------+       +------------+  ok: srcA==dst
// |srcA        |       |dst         |  ok: srcB==dst
// |            |==+===>|            |
// |            |  ||   |            |
// +------------+  ||   +------------+
// +------------+  ||
// |srcB        |  ||
// |            |==||
// |            |   
// +------------+   
//
// CONCAT0, i.e., concat two block
// +------------+       +------------+ ok: srcA==dst
// |srcA        |       |dst         | ok: srcB==dst
// |            |======>|            |
// |            |       |            |
// +------------+       +------------+
// +------------+  ====>|            |
// |srcB        |  ||   |            |
// |            |==||   |            |
// |            |       +------------+
// +------------+   
//
// CONCAT1, i.e., concat by shuffling
// +------------+       +------------+------------+
// |srcA        |       |dst         |            |
// |            |======>|            |            |
// |            |       |            |            |
// +------------+       +------------+------------+
// +------------+                         ||
// |srcB        |                         ||
// |            |==========================
// |            |
// +------------+   
//
// TRANSPOSE
// +------------+   +------+
// |srcA        |   |dst   |
// |            |==>|      |
// +------------+   |      |
//                  |      |
//                  +------+
//
//------------------------------------------------------------------------------
module mover_2d_csr
     #(parameter APB_WIDTH_AD =32
               , APB_WIDTH_DA =32        // data width
               , AXI_WIDTH_AD =32        // address width
               , DATA_TYPE="INTEGER" // "INTEGER", "FLOATING_POINT", "FIXED_POINT"
               , DATA_WIDTH     =32 // bit-width of a whole part
               `ifdef DATA_FIXED_POINT
               , DATA_WIDTH_Q=(DATA_WIDTH/2) // fractional bits
               `endif
               , SRC_FIFO_DEPTH   =16
               , RESULT_FIFO_DEPTH=16
               , PROFILE_CNT_WIDTH=32,
       parameter [3:0] MOVER_COMMAND_NOP      = 'h0,
       parameter [3:0] MOVER_COMMAND_FILL     = 'h1,
       parameter [3:0] MOVER_COMMAND_COPY     = 'h2,
       parameter [3:0] MOVER_COMMAND_RESIDUAL = 'h3,// point-to-point adder
       parameter [3:0] MOVER_COMMAND_CONCAT0  = 'h4,
       parameter [3:0] MOVER_COMMAND_CONCAT1  = 'h5,
       parameter [3:0] MOVER_COMMAND_TRANSPOSE= 'h6
               )
(
      input  wire                     PRESETn
    , input  wire                     PCLK
    , input  wire                     PSEL
    , input  wire                     PENABLE
    , input  wire [APB_WIDTH_AD-1:0]  PADDR
    , input  wire                     PWRITE
    , output wire [APB_WIDTH_DA-1:0]  PRDATA
    , input  wire [APB_WIDTH_DA-1:0]  PWDATA
    , output wire [ 3:0]              command // command
    , output wire                     srcA_go
    , input  wire                     srcA_done // read-done
    , output wire [AXI_WIDTH_AD-1:0]  srcA_address
    , output wire [15:0]              srcA_width // num of items in a row (column)
    , output wire [15:0]              srcA_height // num of items in a column
    , output wire [31:0]              srcA_items // width*height
    , output wire [ 7:0]              srcA_leng // same format for AxLEN
    , output wire                     srcB_go
    , input  wire                     srcB_done // read-done
    , output wire [AXI_WIDTH_AD-1:0]  srcB_address
    , output wire [15:0]              srcB_width // == srcA_width
    , output wire [15:0]              srcB_height // == srcA_height
    , output wire [31:0]              srcB_items // == srcA_items
    , output wire [ 7:0]              srcB_leng // same format for AxLEN
    , output wire                     result_go
    , input  wire                     result_done // read-done
    , output wire [AXI_WIDTH_AD-1:0]  result_address
    , output wire [15:0]              result_width // num of items in a row (column)
    , output wire [15:0]              result_height // num of items in a column
    , output wire [31:0]              result_items // result_width*result_height
    , output wire [ 7:0]              result_leng // same format for AxLEN
    , output wire [DATA_WIDTH-1:0]    fill_value // value for fill command
    , output wire [ 3:0]              activ_func
    , output wire [DATA_WIDTH-1:0]    activ_param
    , output wire                     mover_init // synchronous reset except this CSR
    , input  wire                     mover_ready
    , output wire                          profile_init
    , output wire                          profile_snapshot
    , input  wire                          profile_done
    , input  wire [PROFILE_CNT_WIDTH-1:0]  profile_residual_overflow
    , input  wire [PROFILE_CNT_WIDTH-1:0]  profile_cnt_read
    , input  wire [PROFILE_CNT_WIDTH-1:0]  profile_cnt_write
    , output wire                          interrupt // interrupt to get attention
);
   //---------------------------------------------------------------------------
   localparam T_ADDR_WID=8;
   //---------------------------------------------------------------------------
   wire [T_ADDR_WID-1:0]   T_ADDR =PADDR[T_ADDR_WID-1:0];
   wire                    T_WREN =PSEL& PWRITE;
   wire                    T_RDEN =PSEL&~PWRITE;
   wire [APB_WIDTH_DA-1:0] T_WDATA=PWDATA;
   wire [APB_WIDTH_DA-1:0] T_RDATA;
   assign                  PRDATA=T_RDATA;
   //---------------------------------------------------------------------------
   mover_2d_csr_core #(.T_ADDR_WID        (T_ADDR_WID        )
                      ,.APB_WIDTH_DA      (APB_WIDTH_DA      )
                      ,.AXI_WIDTH_AD      (AXI_WIDTH_AD      )
                      ,.DATA_TYPE         (DATA_TYPE         )
                      ,.DATA_WIDTH        (DATA_WIDTH        )
                      `ifdef DATA_FIXED_POINT
                      ,.DATA_WIDTH_Q      (DATA_WIDTH_Q      )
                      `endif
                      ,.SRC_FIFO_DEPTH    (SRC_FIFO_DEPTH    )
                      ,.RESULT_FIFO_DEPTH (RESULT_FIFO_DEPTH )
                      ,.PROFILE_CNT_WIDTH (PROFILE_CNT_WIDTH )
                      ,.MOVER_COMMAND_NOP       (MOVER_COMMAND_NOP       )
                      ,.MOVER_COMMAND_FILL      (MOVER_COMMAND_FILL      )
                      ,.MOVER_COMMAND_COPY      (MOVER_COMMAND_COPY      )
                      ,.MOVER_COMMAND_RESIDUAL  (MOVER_COMMAND_RESIDUAL  )
                      ,.MOVER_COMMAND_CONCAT0   (MOVER_COMMAND_CONCAT0   )
                      ,.MOVER_COMMAND_CONCAT1   (MOVER_COMMAND_CONCAT1   )
                      ,.MOVER_COMMAND_TRANSPOSE (MOVER_COMMAND_TRANSPOSE )
                      )
   u_csr (
       .RESET_N           ( PRESETn           )
     , .CLK               ( PCLK              )
     , .T_ADDR            ( T_ADDR            )
     , .T_WREN            ( T_WREN            )
     , .T_RDEN            ( T_RDEN            )
     , .T_WDATA           ( T_WDATA           )
     , .T_RDATA           ( T_RDATA           )
     , .command           ( command           )
     , .srcA_go           ( srcA_go           )
     , .srcA_done         ( srcA_done         )
     , .srcA_address      ( srcA_address      )
     , .srcA_width        ( srcA_width        )
     , .srcA_height       ( srcA_height       )
     , .srcA_items        ( srcA_items        )
     , .srcA_leng         ( srcA_leng         )
     , .srcB_go           ( srcB_go           )
     , .srcB_done         ( srcB_done         )
     , .srcB_address      ( srcB_address      )
     , .srcB_width        ( srcB_width        )
     , .srcB_height       ( srcB_height       )
     , .srcB_items        ( srcB_items        )
     , .srcB_leng         ( srcB_leng         )
     , .result_go         ( result_go         )
     , .result_done       ( result_done       )
     , .result_address    ( result_address    )
     , .result_width      ( result_width      )
     , .result_height     ( result_height     )
     , .result_items      ( result_items      )
     , .result_leng       ( result_leng       )
     , .fill_value        ( fill_value        )
     , .activ_func        ( activ_func        )
     , .activ_param       ( activ_param       )
     , .mover_init        ( mover_init        )
     , .mover_ready       ( mover_ready       )
     , .profile_init              ( profile_init              )
     , .profile_snapshot          ( profile_snapshot          )
     , .profile_done              ( profile_done              )
     , .profile_residual_overflow ( profile_residual_overflow )
     , .profile_cnt_read          ( profile_cnt_read          )
     , .profile_cnt_write         ( profile_cnt_write         )
     , .interrupt         ( interrupt         )
   );
endmodule

//------------------------------------------------------------------------------
// CSR access signals
//             __    __    __    __    __    _
// CLK      __|  |__|  |__|  |__|  |__|  |__|
//             _____             _____
// T_ADDR   XXX_____XXXXXXXXXXXXX_____XXX
//             _____
// T_RDEN   __|     |____________________
//                   _____
// T_RDATA  XXXXXXXXX_____XXXXXXXXXXXXXXX
//                               _____
// T_WREN   ____________________|     |__
//                               _____
// T_WDATA  XXXXXXXXXXXXXXXXXXXXX_____XXXX
//------------------------------------------------------------------------------

module mover_2d_csr_core
     #(parameter T_ADDR_WID  =8
               , APB_WIDTH_DA=32
               , AXI_WIDTH_AD=32
               , DATA_TYPE   ="INTEGER" // "INTEGER", "FLOATING_POINT", "FIXED_POINT"
               , DATA_WIDTH  =32 // bit-width of a whole part
               `ifdef DATA_FIXED_POINT
               , DATA_WIDTH_Q=(DATA_WIDTH/2) // fractional bits
               `endif
               , SRC_FIFO_DEPTH   =16
               , RESULT_FIFO_DEPTH=16
               , PROFILE_CNT_WIDTH=32,
       parameter [3:0] MOVER_COMMAND_NOP      = 'h0,
       parameter [3:0] MOVER_COMMAND_FILL     = 'h1,
       parameter [3:0] MOVER_COMMAND_COPY     = 'h2,
       parameter [3:0] MOVER_COMMAND_RESIDUAL = 'h3,// point-to-point adder
       parameter [3:0] MOVER_COMMAND_CONCAT0  = 'h4,
       parameter [3:0] MOVER_COMMAND_CONCAT1  = 'h5,
       parameter [3:0] MOVER_COMMAND_TRANSPOSE= 'h6
               )
(
      input   wire                    RESET_N
    , input   wire                    CLK
    , input   wire [T_ADDR_WID-1:0]   T_ADDR
    , input   wire                    T_WREN
    , input   wire                    T_RDEN
    , input   wire [APB_WIDTH_DA-1:0] T_WDATA
    , output  reg  [APB_WIDTH_DA-1:0] T_RDATA
    //-------------------------------------------------------------------------
    , output wire [ 3:0]              command // command
    , output wire                     srcA_go // auto return to 0
    , input  wire                     srcA_done // read-done
    , output wire [AXI_WIDTH_AD-1:0]  srcA_address
    , output wire [15:0]              srcA_width // num of items in a row (column)
    , output wire [15:0]              srcA_height // num of items in a column
    , output wire [31:0]              srcA_items // width*height
    , output wire [ 7:0]              srcA_leng // same format for AxLEN
    , output wire                     srcB_go // auto return to 0
    , input  wire                     srcB_done // read-done
    , output wire [AXI_WIDTH_AD-1:0]  srcB_address
    , output wire [15:0]              srcB_width
    , output wire [15:0]              srcB_height
    , output wire [31:0]              srcB_items
    , output wire [ 7:0]              srcB_leng
    , output wire                     result_go // auto return to 0
    , input  wire                     result_done // read-done
    , output wire [AXI_WIDTH_AD-1:0]  result_address
    , output wire [15:0]              result_width // num of items in a row (column)
    , output wire [15:0]              result_height // num of items in a column
    , output wire [31:0]              result_items // result_width*result_height
    , output wire [ 7:0]              result_leng // same format for AxLEN
    , output wire [DATA_WIDTH-1:0]    fill_value // value for fill command
    , output wire [ 3:0]              activ_func
    , output wire [DATA_WIDTH-1:0]    activ_param
    , output wire                     mover_init // auto return 0
    , input  wire                     mover_ready
    , output reg                           profile_init // auto return 0
    , output reg                           profile_snapshot
    , input  wire                          profile_done
    , input  wire [PROFILE_CNT_WIDTH-1:0]  profile_residual_overflow
    , input  wire [PROFILE_CNT_WIDTH-1:0]  profile_cnt_read
    , input  wire [PROFILE_CNT_WIDTH-1:0]  profile_cnt_write
    , output wire                          interrupt // interrupt to get attention
);
   //---------------------------------------------------------------------------
   // CSR address
   localparam CSRA_VERSION        = 'h00
            , CSRA_CONTROL        = 'h10
            , CSRA_CONFIG         = 'h14
            , CSRA_CONFIG_FIFO    = 'h18

            , CSRA_COMMAND        = 'h20

            , CSRA_SRCA_ADDR_LOW  = 'h30
            , CSRA_SRCA_ADDR_HIGH = 'h34
            , CSRA_SRCA_CFG_SIZE  = 'h38
            , CSRA_SRCA_ITEMS     = 'h3C
            , CSRA_SRCA_BURST     = 'h40

            , CSRA_SRCB_ADDR_LOW  = 'h50
            , CSRA_SRCB_ADDR_HIGH = 'h54
            , CSRA_SRCB_CFG_SIZE  = 'h58
            , CSRA_SRCB_ITEMS     = 'h5C
            , CSRA_SRCB_BURST     = 'h60

            , CSRA_RST_ADDR_LOW   = 'h70
            , CSRA_RST_ADDR_HIGH  = 'h74
            , CSRA_RST_CFG_SIZE   = 'h78
            , CSRA_RST_ITEMS      = 'h7C
            , CSRA_RST_BURST      = 'h80

            , CSRA_FILL_VALUE     = 'h90
            , CSRA_ACTIV_FUNC     = 'h94
            , CSRA_ACTIV_PARAM    = 'h98

            , CSRA_PROFILE_CTL               = 'hA0
            , CSRA_PROFILE_CYCLES            = 'hA4 // cycles
            , CSRA_PROFILE_RESIDUAL_OVERFLOW = 'hA8
            , CSRA_PROFILE_CNT_RD            = 'hAC // num of read
            , CSRA_PROFILE_CNT_WR            = 'hB0 // num of write
            ;
   //---------------------------------------------------------------------------
   function [15:0] swap;
   input [15:0] data;
   begin
        swap[ 7:0] = data[15:8];
        swap[15:8] = data[ 7:0];
   end
   endfunction
   //---------------------------------------------------------------------------
   // CSR
   wire [31:0]              csr_version       =32'h20210610;
   reg                      csr_ctl_ip        =1'b0;
   reg                      csr_ctl_ie        =1'b0;
   reg                      csr_ctl_init      =1'b0;
   wire [15:0]              csr_data_type     =(DATA_TYPE=="FLOATING_POINT") ? swap("FP")
                                              :(DATA_TYPE=="FIXED_POINT") ? swap("FX")
                                              : swap("IT");
   reg  [ 3:0]              csr_command       = MOVER_COMMAND_NOP;

   reg                      csr_srcA_go       =1'b0;
   wire                     csr_srcA_done;
   reg  [AXI_WIDTH_AD-1:0]  csr_srcA_address  = 'h0;
   reg  [15:0]              csr_srcA_width    = 'h0;
   reg  [15:0]              csr_srcA_height   = 'h0;
   reg  [31:0]              csr_srcA_items    = 'h0;
   reg  [ 7:0]              csr_srcA_leng     = 'h0; // 0 = length 1
   reg                      csr_srcB_go       =1'b0;
   wire                     csr_srcB_done;
   reg  [AXI_WIDTH_AD-1:0]  csr_srcB_address  = 'h0;
   reg  [15:0]              csr_srcB_width    = 'h0;
   reg  [15:0]              csr_srcB_height   = 'h0;
   reg  [31:0]              csr_srcB_items    = 'h0;
   reg  [ 7:0]              csr_srcB_leng     = 'h0; // 0 = length 1
   reg                      csr_result_go     =1'b0;
   wire                     csr_result_done;
   reg  [AXI_WIDTH_AD-1:0]  csr_result_address = 'h0;
   reg  [15:0]              csr_result_width   = 'h0; // num of items of row
   reg  [15:0]              csr_result_height  = 'h0;
   reg  [31:0]              csr_result_items   = 'h0; // num of items whole
   reg  [ 7:0]              csr_result_leng    = 'h0; // 0 = length 1

   reg  [DATA_WIDTH-1:0]    csr_fill_value     = 'h0; // command FILL
   reg  [ 3:0]              csr_activ_func     =4'b0; // acivation function (0=linear, 1=ReLU, 2=LeakyReLU)
   reg  [DATA_WIDTH-1:0]    csr_activ_param    = 'h0; // activation parameter if required

   reg  [PROFILE_CNT_WIDTH-1:0]  profile_cycles='h0;
   //---------------------------------------------------------------------------
   // CSR read
   always @ (posedge CLK or negedge RESET_N) begin
   if (RESET_N==1'b0) begin
       T_RDATA <= 'h0;
   end else begin
      if (T_RDEN) begin
         (* full_case *)
         case (T_ADDR) // synthesis full_case parallel_case
           CSRA_VERSION      : T_RDATA <= csr_version;
           CSRA_CONTROL      : T_RDATA <={csr_ctl_init     // bit-31
                                         ,mover_ready      // bit-30
                                         ,csr_ctl_ip       // bit-29
                                         ,csr_ctl_ie       // bit-28
                                         ,17'h0            // bit-27:11
                                         ,csr_result_done  // bit-10
                                         ,csr_srcB_done    // bit-9
                                         ,csr_srcA_done    // bit-8
                                         ,5'h0             // bit-7-3
                                         ,csr_result_go    // bit-2
                                         ,csr_srcB_go      // bit-1
                                         ,csr_srcA_go      // bit-0
                                         };
           CSRA_CONFIG       : T_RDATA <= {csr_data_type   // bit-31:16
                                          `ifdef DATA_FIXED_POINT
                                          ,DATA_WIDTH_Q[7:0]// bit-15:8
                                          `else
                                          ,8'h0            // bit-15:8
                                          `endif
                                          ,DATA_WIDTH[7:0] // bit-7:0
                                          };
           CSRA_CONFIG_FIFO  : T_RDATA <= {16'h0                  // bit-31:16
                                          ,RESULT_FIFO_DEPTH[7:0] // bit-15:8
                                          ,SRC_FIFO_DEPTH[7:0]    // bit-7:0
                                          };
           CSRA_COMMAND       : T_RDATA <={28'h0,csr_command};
           CSRA_SRCA_ADDR_LOW : T_RDATA <= csr_srcA_address[31:0];
           CSRA_SRCA_ADDR_HIGH: T_RDATA <= csr_srcA_address>>32;
           CSRA_SRCA_CFG_SIZE : T_RDATA <={csr_srcA_height// bit-31:16
                                          ,csr_srcA_width // bit-15:0
                                          };
           CSRA_SRCA_ITEMS    : T_RDATA <= csr_srcA_items; // should be csr_width*height
           CSRA_SRCA_BURST    : T_RDATA <={24'h0           // bit-31:8
                                          ,csr_srcA_leng   // bit-7:0 AxLENG style
                                          };
           CSRA_SRCB_ADDR_LOW : T_RDATA <= csr_srcB_address[31:0];
           CSRA_SRCB_ADDR_HIGH: T_RDATA <= csr_srcB_address>>32;
           CSRA_SRCB_CFG_SIZE : T_RDATA <={csr_srcB_height// bit-31:16
                                          ,csr_srcB_width // bit-15:0
                                          };
           CSRA_SRCB_ITEMS    : T_RDATA <= csr_srcB_items; // should be csr_width*height
           CSRA_SRCB_BURST    : T_RDATA <={24'h0           // bit-31:8
                                          ,csr_srcB_leng   // bit-7:0 AxLENG style
                                          };
           CSRA_RST_ADDR_LOW : T_RDATA <= csr_result_address[31:0];
           CSRA_RST_ADDR_HIGH: T_RDATA <= csr_result_address>>32;
           CSRA_RST_CFG_SIZE : T_RDATA <={csr_result_height// bit-31:16
                                         ,csr_result_width // bit-15:0
                                         };
           CSRA_RST_ITEMS    : T_RDATA <= csr_result_items;
           CSRA_RST_BURST    : T_RDATA <={24'h0            // bit-31:8
                                         ,csr_result_leng  // bit-7:0 AxLENG style
                                         };
           CSRA_FILL_VALUE     : T_RDATA <={{32-DATA_WIDTH{1'b0}},csr_fill_value};
           CSRA_ACTIV_FUNC     : T_RDATA <= {28'h0, csr_activ_func};
           CSRA_ACTIV_PARAM    : T_RDATA <= (DATA_WIDTH==32)
                                          ? csr_activ_param
                                          : {{32-DATA_WIDTH{1'b0}},csr_activ_param};
           CSRA_PROFILE_CTL              : T_RDATA <={profile_init
                                                     ,29'h0
                                                     ,profile_done
                                                     ,profile_snapshot};
           CSRA_PROFILE_CYCLES           : T_RDATA <= profile_cycles;
           CSRA_PROFILE_RESIDUAL_OVERFLOW: T_RDATA <= profile_residual_overflow;
           CSRA_PROFILE_CNT_RD           : T_RDATA <= profile_cnt_read;
           CSRA_PROFILE_CNT_WR           : T_RDATA <= profile_cnt_write;
           default: begin
                    T_RDATA <=32'h0;
           end
         endcase
      end else T_RDATA <= 'h0;
   end // if
   end // always
   //---------------------------------------------------------------------------
   // CSR write
   always @ (posedge CLK or negedge RESET_N) begin
   if (RESET_N==1'b0) begin
       csr_command        <= MOVER_COMMAND_NOP;
       csr_srcA_address   <=  'h0;
       csr_srcA_width     <=  'h0;
       csr_srcA_height    <=  'h0;
       csr_srcA_items     <=  'h0;
       csr_srcA_leng      <= 8'h0;
       csr_srcB_address   <=  'h0;
       csr_srcB_width     <=  'h0;
       csr_srcB_height    <=  'h0;
       csr_srcB_items     <=  'h0;
       csr_srcB_leng      <= 8'h0;
       csr_result_address <=  'h0;
       csr_result_width   <=  'h0;
       csr_result_height  <=  'h0;
       csr_result_items   <=  'h0;
       csr_result_leng    <= 8'h0;
       csr_fill_value     <={DATA_WIDTH{1'b0}};
       csr_activ_func     <= 4'h0;
       csr_activ_param    <={DATA_WIDTH{1'b0}};
   end else begin
      if (T_WREN) begin
         (* parallel_case *)
         case (T_ADDR) // synthesis parallel_case
           CSRA_COMMAND       : csr_command <=T_WDATA[3:0];
           CSRA_SRCA_ADDR_LOW : csr_srcA_address[31:0] <= T_WDATA[31:0];
           CSRA_SRCA_ADDR_HIGH: if (AXI_WIDTH_AD>32) csr_srcA_address[AXI_WIDTH_AD-1:32] <= T_WDATA;
           CSRA_SRCA_CFG_SIZE :{csr_srcA_height
                               ,csr_srcA_width} <= T_WDATA;
           CSRA_SRCA_ITEMS    : csr_srcA_items <= T_WDATA;
           CSRA_SRCA_BURST    : csr_srcA_leng <= T_WDATA[7:0];
           CSRA_SRCB_ADDR_LOW : csr_srcB_address[31:0] <= T_WDATA[31:0];
           CSRA_SRCB_ADDR_HIGH: if (AXI_WIDTH_AD>32) csr_srcB_address[AXI_WIDTH_AD-1:32] <= T_WDATA;
           CSRA_SRCB_CFG_SIZE :{csr_srcB_height
                               ,csr_srcB_width} <= T_WDATA;
           CSRA_SRCB_ITEMS    : csr_srcB_items <= T_WDATA;
           CSRA_SRCB_BURST    : csr_srcB_leng <= T_WDATA[7:0];
           CSRA_RST_ADDR_LOW  : csr_result_address <= T_WDATA[31:0];
           CSRA_RST_ADDR_HIGH : if (AXI_WIDTH_AD>32) csr_result_address[AXI_WIDTH_AD-1:32] <= T_WDATA;
           CSRA_RST_CFG_SIZE  :{csr_result_height
                               ,csr_result_width} <= T_WDATA;
           CSRA_RST_ITEMS     : csr_result_items  <= T_WDATA;
           CSRA_RST_BURST     : csr_result_leng   <= T_WDATA[7:0];
           CSRA_FILL_VALUE    : csr_fill_value    <= T_WDATA[DATA_WIDTH-1:0];
           CSRA_ACTIV_FUNC    : csr_activ_func    <= T_WDATA[3:0];
           CSRA_ACTIV_PARAM   : csr_activ_param   <= T_WDATA[DATA_WIDTH-1:0];
         endcase
      end
   end // if
   end // always
   //---------------------------------------------------------------------------
   // init and go
   reg init_reg=1'b0;
   always @ (posedge CLK or negedge RESET_N) begin
   if (RESET_N==1'b0) begin
       init_reg      <= 1'b0;
       csr_ctl_init  <= 1'b0;
       csr_result_go <= 1'b0; // bit-3
       csr_srcB_go   <= 1'b0; // bit-1
       csr_srcA_go   <= 1'b0; // bit-1
   end else begin
       if (T_WREN&&(T_ADDR==CSRA_CONTROL)) begin
           csr_ctl_init  <= T_WDATA[31];
           csr_result_go <= (csr_command!=MOVER_COMMAND_NOP) ? T_WDATA[2] : 1'b0;
           csr_srcB_go   <= (csr_command!=MOVER_COMMAND_NOP) ? T_WDATA[1] : 1'b0;
           csr_srcA_go   <= (csr_command!=MOVER_COMMAND_NOP) ? T_WDATA[0] : 1'b0;
       end else begin
           init_reg <= csr_ctl_init;
           if (init_reg) csr_ctl_init <= 1'b0;
           if (csr_result_done) csr_result_go  <= 1'b0;
           if (csr_srcB_done  ) csr_srcB_go <= 1'b0;
           if (csr_srcA_done  ) csr_srcA_go <= 1'b0;
       end
   end // if
   end // always
   //---------------------------------------------------------------------------
   // synthesis translate_off
   always @ (posedge csr_result_go) begin
       case (csr_command)
       MOVER_COMMAND_COPY     : begin
                          if ((csr_srcA_width !=csr_result_width )||
                              (csr_srcA_height!=csr_result_height)||
                              (csr_srcA_items !=csr_result_items )) begin
                              $display("%0t %m ERROR Copy width/height/items.", $time);
                          end
                          if (csr_srcA_address==csr_result_address) begin
                              $display("%0t %m WARNING Copy address.", $time);
                          end
                          end
       MOVER_COMMAND_RESIDUAL : begin
                          if ((csr_srcA_width !=csr_result_width )||
                              (csr_srcA_height!=csr_result_height)||
                              (csr_srcA_items !=csr_result_items )||
                              (csr_srcB_width !=csr_result_width )||
                              (csr_srcB_height!=csr_result_height)||
                              (csr_srcB_items !=csr_result_items )) begin
                              $display("%0t %m ERROR Residual width/height/items.", $time);
                          end
                          end
       MOVER_COMMAND_CONCAT0  : begin
                          if (csr_srcA_width!=csr_srcB_width) begin
                              $display("%0t %m ERROR Concat mode 0 width", $time);
                          end
                          if ((csr_srcA_width!=csr_result_width)||
                              ((csr_srcA_height+csr_srcB_height)!=csr_result_height)||
                              ((csr_srcA_items+csr_srcB_items)!=csr_result_items)) begin
                              $display("%0t %m ERROR Concat mode 0 width/height/items.", $time);
                          end
                          end
       MOVER_COMMAND_CONCAT1  : begin
                          if (csr_srcA_height!=csr_srcB_height) begin
                              $display("%0t %m ERROR Concat mode 0 width", $time);
                          end
                          if ((csr_srcA_height!=csr_result_height)||
                              ((csr_srcA_width+csr_srcB_width)!=csr_result_width)||
                              ((csr_srcA_items+csr_srcB_items)!=csr_result_items)) begin
                              $display("%0t %m ERROR Concat mode 1 width/height/items.", $time);
                          end
                          if ((csr_srcA_address==csr_result_address)||
                              (csr_srcB_address==csr_result_address)) begin
                              $display("%0t %m ERROR Concat mode 1 address.", $time);
                          end
                          end
       MOVER_COMMAND_TRANSPOSE: begin
                          if ((csr_srcA_width!=csr_result_height)||
                              (csr_srcA_height!=csr_result_width)||
                              (csr_srcA_items!=csr_result_items)) begin
                              $display("%0t %m ERROR Transpose width/height/items.", $time);
                          end
                          if (csr_srcA_address==csr_result_address) begin
                              $display("%0t %m ERROR Transpose address.", $time);
                          end
                          end
       MOVER_COMMAND_NOP      : begin
                          end 
       endcase
       if (csr_result_items!=(csr_result_width*csr_result_height))
            $display("%0t %m ERROR result size and items mis-match.", $time);
   end // always
   // synthesis translate_on
   //---------------------------------------------------------------------------
   // interrupt
   always @ (posedge CLK or negedge RESET_N) begin
   if (RESET_N==1'b0) begin
       csr_ctl_ie <= 1'b0; // bit-28
       csr_ctl_ip <= 1'b0; // bit-29
   end else begin
       if (T_WREN&&(T_ADDR==CSRA_CONTROL)) begin
           csr_ctl_ie <= T_WDATA[28];
           csr_ctl_ip <= (T_WDATA[29]==1'b0) ? 1'b0 : csr_ctl_ip;
       end else begin
           if (csr_ctl_ie      & 
               csr_result_done &csr_result_go ) begin
               csr_ctl_ip <= 1'b1;
           end
       end
   end // if
   end // always
   //---------------------------------------------------------------------------
   // profile_init
`ifdef ONE_THENTH
   reg [3:0] profile_cnt=4'h0;
   reg profile_init_reg=1'b0;
   always @ (posedge CLK or negedge RESET_N) begin
   if (RESET_N==1'b0) begin
       profile_init_reg <= 1'b0;
       profile_init     <= 1'b0; // bit-0
       profile_cycles   <=  'h0;
       profile_cnt      <=  'h0;
   end else begin
       if (T_WREN&&(T_ADDR==CSRA_PROFILE_CTL)) begin
           profile_init   <= T_WDATA[0];
       end else begin
           profile_init_reg <= profile_init;
           if (profile_init_reg) begin
               profile_init   <= 1'b0;
               profile_cycles <=  'h0;
               profile_cnt    <=  'h0;
           end
           profile_cnt    <= profile_cnt + 1;
           if ((profile_cnt+1)=='d10) begin
               profile_cnt    <= 'h0;
               profile_cycles <= profile_cycles + 1;
           end
       end
   end // if
   end // always
`else
   reg profile_init_reg=1'b0;
   always @ (posedge CLK or negedge RESET_N) begin
   if (RESET_N==1'b0) begin
       profile_init_reg <= 1'b0;
       profile_init     <= 1'b0; // bit-31
       profile_snapshot <= 1'b0; // bit-0
       profile_cycles   <=  'h0;
   end else begin
       if (T_WREN&&(T_ADDR==CSRA_PROFILE_CTL)) begin
           profile_init     <= T_WDATA[31];
           profile_snapshot <= T_WDATA[0];
       end else begin
           profile_init_reg <= profile_init;
           if (profile_init_reg==1'b1) begin
               profile_init     <= 1'b0;
               profile_snapshot <= 1'b0;
               profile_cycles   <=  'h0;
           end else begin
               profile_cycles <= profile_cycles + 1;
               if ((profile_snapshot==1'b1)&&(profile_done==1'b1)) begin
                    profile_snapshot <= 1'b0;
               end
           end
       end
   end // if
   end // always
`endif
   //---------------------------------------------------------------------------
   assign  command       =csr_command     ;
   assign  srcA_go       =csr_srcA_go     ;
   assign                 csr_srcA_done   =srcA_done;
   assign  srcA_address  =csr_srcA_address;
   assign  srcA_width    =csr_srcA_width  ;
   assign  srcA_height   =csr_srcA_height ;
   assign  srcA_items    =csr_srcA_items  ;
   assign  srcA_leng     =csr_srcA_leng   ;

   assign  srcB_go       =csr_srcB_go     ;
   assign                 csr_srcB_done   =srcB_done;
   assign  srcB_address  =csr_srcB_address;
   assign  srcB_width    =csr_srcB_width  ;
   assign  srcB_height   =csr_srcB_height ;
   assign  srcB_items    =csr_srcB_items  ;
   assign  srcB_leng     =csr_srcB_leng   ;

   assign  result_go     =csr_result_go     ;
   assign                 csr_result_done   =result_done;
   assign  result_address=csr_result_address;
   assign  result_width  =csr_result_width  ;
   assign  result_height =csr_result_height ;
   assign  result_items  =csr_result_items  ;
   assign  result_leng   =csr_result_leng   ;

   assign  fill_value    =csr_fill_value ;
   assign  activ_func    =csr_activ_func ;
   assign  activ_param   =csr_activ_param;

   assign  mover_init    =csr_ctl_init         ;
   assign  interrupt     =csr_ctl_ie&csr_ctl_ip;
endmodule

//------------------------------------------------------------------------------
// Revision history
//
// 2021.11.06: APB
// 2021.09.18: 'mover_2d_csr_read/mover_2d_csr_write'
// 2021.06.10: Started by Ando Ki (andoki@gmail.com)
//------------------------------------------------------------------------------
