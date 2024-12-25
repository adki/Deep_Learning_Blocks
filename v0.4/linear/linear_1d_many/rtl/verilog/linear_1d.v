//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All right reserved.
//------------------------------------------------------------------------------
// VERSION: 2021.11.06.
//------------------------------------------------------------------------------
// Linear 1D : y = xA'+b
//------------------------------------------------------------------------------
// use transposed weight
//
//                            (input_size)         bias_size      result_size 
//   |<--input_size -->|   |<--weight_width->|    |<-------->|   |<-------->|
//   +-----------------+   +-----------------+-   +----------+   +----------+
//   | input feature   | x | weights         || + | bias     | = | result   |
//   +-----------------+   |                 ||   +----------+   +----------+
//                         |                 ||   
//                         |                 ||   
//                         |                 ||weight_height=result_size (output_size)
//                         +-----------------+-             =bias_size 
//------------------------------------------------------------------------------
// make sure 'bias','input','weight', and 'result' are all justified.
//           +-----------------------------------+
//           | controller                        |
//           | +------------------------+        |             +-----+
//           | | input                  |        |             |core |
//           | | +----+         --+--+  |bias[]  |             |     |
//    AXI-R  | | |AXI |==========>|F |========================>|     |
//        ======>|    |         --+--+  |        |             |     |
//           | | |    |   +--+  --+--+  |input[] |             |     |
//           | | |    |==>|PU|===>|F |========================>|     |
//           | | +----+   +--+  --+--+  |        |             |     |
//           | +------------------------+        |             |     |
//           | +------------------------+        |             |     |
//           | |  weight                |        |             |     |
//    AXI-R  | | +----+   +--+  --+--+  |weight[]|             |     |
//        ======>|AXI |==>|PU|===>|F |========================>|     |
//           | | +----+   +--+  --+--+  |        |             |     |
//           | +------------------------+        |             |     |
//           | +------------------------+        |             |     |
//           | | result                 |        |             |     |
//    AXI-W  | | +----+   +--+--  +--+  |result[]|             |     |
//        <======|AXI |===|F |===>|PO|<========================|     |
//           | | +----+   +--+--  +--+  |        | core_ready  |     |
//           | +------------------------+        |<------------|     |
//           |                                   | init        |     |
//           |                                   |<-.--------->|     |
//           +-----------------------------------+  |          +-----+
//               /|\    | linear_ready              |            /|\
//                |     +----------+                |linear_init  |
//                |               \|/               |             |
//                |              +----------------------+         |
//                |              | csr                  |         |
//                |              |                      |         |
//                |              +----------------------+         |
//                |                 /|\                           |
// ARESETn -------+------------------+----------------------------+
//------------------------------------------------------------------------------
`ifndef AXI_WIDTH_DA
`define AXI_WIDTH_DA   32
`endif
`ifndef DATA_WIDTH
`define DATA_WIDTH     32
`endif
`ifndef DATA_TYPE
`define DATA_TYPE "INTEGER"
`endif

`ifdef VIVADO
`define DBG_LINEAR (* mark_debug="true" *)
`else
`define DBG_LINEAR
`endif

`include "linear_1d_csr.v"
`include "linear_1d_core.v"
`include "linear_1d_control.v"
`include "linear_1d_sync.v"

module linear_1d
     #(parameter APB_WIDTH_AD   =32  // address width
               , APB_WIDTH_DA   =32
               , M_AXI_WIDTH_ID =4   // ID width in bits
               , M_AXI_WIDTH_AD =32  // address width
               , M_AXI_WIDTH_DA =`AXI_WIDTH_DA  // data width
               , M_AXI_WIDTH_DS =(M_AXI_WIDTH_DA/8)
               , DATA_TYPE=`DATA_TYPE // "INTEGER", "FLOATING_POINT", "FIXED_POINT"
               , DATA_WIDTH     =`DATA_WIDTH // bit-width of an item
               `ifdef DATA_FIXED_POINT
               , DATA_WIDTH_Q=(DATA_WIDTH/2) // fractional bits
               `endif
               , INPUT_FIFO_DEPTH =32
               , WEIGHT_FIFO_DEPTH=INPUT_FIFO_DEPTH // weight array
               , RESULT_FIFO_DEPTH=16
               , PROFILE_CNT_WIDTH=32
               , ACTIV_FUNC_BYPASS    =4'h0
               , ACTIV_FUNC_RELU      =4'h1
               , ACTIV_FUNC_LEAKY_RELU=4'h2
               , ACTIV_FUNC_SIGMOID   =4'h3
               , ACTIV_FUNC_TANH      =4'h4
               )
(
       input   wire                         PRESETn
     , input   wire                         PCLK
     , input   wire                         PSEL
     , input   wire                         PENABLE
     , input   wire [APB_WIDTH_AD-1:0]      PADDR
     , input   wire                         PWRITE
     , output  wire [APB_WIDTH_DA-1:0]      PRDATA
     , input   wire [APB_WIDTH_DA-1:0]      PWDATA
     // master port for result, write-only
     , input   wire                         ARESETn
     , input   wire                         ACLK
     , output  wire  [M_AXI_WIDTH_ID-1:0]   M_AXI_RST_AWID
     , output  wire  [M_AXI_WIDTH_AD-1:0]   M_AXI_RST_AWADDR
     , output  wire  [ 7:0]                 M_AXI_RST_AWLEN
     , output  wire  [ 2:0]                 M_AXI_RST_AWSIZE
     , output  wire  [ 1:0]                 M_AXI_RST_AWBURST
     , output  wire                         M_AXI_RST_AWVALID
     , input   wire                         M_AXI_RST_AWREADY
     , output  wire  [M_AXI_WIDTH_DA-1:0]   M_AXI_RST_WDATA
     , output  wire  [M_AXI_WIDTH_DS-1:0]   M_AXI_RST_WSTRB
     , output  wire                         M_AXI_RST_WLAST
     , output  wire                         M_AXI_RST_WVALID
     , input   wire                         M_AXI_RST_WREADY
     , input   wire  [M_AXI_WIDTH_ID-1:0]   M_AXI_RST_BID
     , input   wire  [ 1:0]                 M_AXI_RST_BRESP
     , input   wire                         M_AXI_RST_BVALID
     , output  wire                         M_AXI_RST_BREADY
     // master port for input feature (vector) and bias if any, read-only
     , output  wire  [M_AXI_WIDTH_ID-1:0]   M_AXI_INPUT_ARID
     , output  wire  [M_AXI_WIDTH_AD-1:0]   M_AXI_INPUT_ARADDR
     , output  wire  [ 7:0]                 M_AXI_INPUT_ARLEN
     , output  wire  [ 2:0]                 M_AXI_INPUT_ARSIZE
     , output  wire  [ 1:0]                 M_AXI_INPUT_ARBURST
     , output  wire                         M_AXI_INPUT_ARVALID
     , input   wire                         M_AXI_INPUT_ARREADY
     , input   wire  [M_AXI_WIDTH_ID-1:0]   M_AXI_INPUT_RID
     , input   wire  [M_AXI_WIDTH_DA-1:0]   M_AXI_INPUT_RDATA
     , input   wire  [ 1:0]                 M_AXI_INPUT_RRESP
     , input   wire                         M_AXI_INPUT_RLAST
     , input   wire                         M_AXI_INPUT_RVALID
     , output  wire                         M_AXI_INPUT_RREADY
     // master port for weight, read-only
     , output  wire  [M_AXI_WIDTH_ID-1:0]   M_AXI_WEIGHT_ARID
     , output  wire  [M_AXI_WIDTH_AD-1:0]   M_AXI_WEIGHT_ARADDR
     , output  wire  [ 7:0]                 M_AXI_WEIGHT_ARLEN
     , output  wire  [ 2:0]                 M_AXI_WEIGHT_ARSIZE
     , output  wire  [ 1:0]                 M_AXI_WEIGHT_ARBURST
     , output  wire                         M_AXI_WEIGHT_ARVALID
     , input   wire                         M_AXI_WEIGHT_ARREADY
     , input   wire  [M_AXI_WIDTH_ID-1:0]   M_AXI_WEIGHT_RID
     , input   wire  [M_AXI_WIDTH_DA-1:0]   M_AXI_WEIGHT_RDATA
     , input   wire  [ 1:0]                 M_AXI_WEIGHT_RRESP
     , input   wire                         M_AXI_WEIGHT_RLAST
     , input   wire                         M_AXI_WEIGHT_RVALID
     , output  wire                         M_AXI_WEIGHT_RREADY
     //
     , output wire                          interrupt // interrupt to get attention
);
    //--------------------------------------------------------------------------
    localparam DATA_BYTES    =(DATA_WIDTH/8)
             , INPUT_FIFO_AW =$clog2(INPUT_FIFO_DEPTH )
             , WEIGHT_FIFO_AW=$clog2(WEIGHT_FIFO_DEPTH)
             , RESULT_FIFO_AW=$clog2(RESULT_FIFO_DEPTH);
    //--------------------------------------------------------------------------
    wire                         bias_go, bias_go_sync;
    wire                         bias_done, bias_done_sync;// read-done
    wire [M_AXI_WIDTH_AD-1:0]    bias_address;
    wire [15:0]                  bias_size;// should be the same as result_size if >0

    wire                         input_go, input_go_sync;
    wire                         input_done, input_done_sync;// read-done
    wire [M_AXI_WIDTH_AD-1:0]    input_address;
    wire [15:0]                  input_size; // num of items in row
    wire [ 7:0]                  input_leng;// AxLENG format, =block_size-1

    wire                         weight_go, weight_go_sync;
    wire                         weight_done, weight_done_sync;// read-done
    wire [M_AXI_WIDTH_AD-1:0]    weight_address;
    wire [15:0]                  weight_width;// should be the same as input_size
    wire [15:0]                  weight_height;// should be the same result_size
    wire [31:0]                  weight_items;
    wire [ 7:0]                  weight_leng;// AxLENG format; =block_size-1

    wire                         result_go, result_go_sync;
    wire                         result_done, result_done_sync;// read-done
    wire [M_AXI_WIDTH_AD-1:0]    result_address;
    wire [15:0]                  result_size;// num of items
    wire [ 7:0]                  result_leng;// AxLENG format

    wire [ 3:0]                  activ_func;
    wire [DATA_WIDTH-1:0]        activ_param;

    wire                         linear_init, linear_init_sync; // synchronous initialization
    wire                         linear_ready, linear_ready_sync; // between csr<->control
    wire                         linear_core_ready; // signal between control<->core

    wire                         profile_init, profile_init_sync;
    wire                         profile_snapshot, profile_snapshot_sync;
    reg                          profile_done=1'b0;
    wire                         profile_done_sync;
    wire [PROFILE_CNT_WIDTH-1:0] profile_mac_num;
    wire [PROFILE_CNT_WIDTH-1:0] profile_mac_overflow;
    wire [PROFILE_CNT_WIDTH-1:0] profile_bias_overflow;
    wire [PROFILE_CNT_WIDTH-1:0] profile_activ_overflow;
    wire [PROFILE_CNT_WIDTH-1:0] profile_cnt_read;
    wire [PROFILE_CNT_WIDTH-1:0] profile_cnt_write;
    reg  [PROFILE_CNT_WIDTH-1:0] profile_mac_num_reg='h0;
    reg  [PROFILE_CNT_WIDTH-1:0] profile_mac_overflow_reg='h0;
    reg  [PROFILE_CNT_WIDTH-1:0] profile_bias_overflow_reg='h0;
    reg  [PROFILE_CNT_WIDTH-1:0] profile_activ_overflow_reg='h0;
    reg  [PROFILE_CNT_WIDTH-1:0] profile_cnt_read_reg='h0;
    reg  [PROFILE_CNT_WIDTH-1:0] profile_cnt_write_reg='h0;
    //--------------------------------------------------------------------------
    wire                       IO_BIAS_READY;
    wire                       IO_BIAS_VALID;
    wire [DATA_WIDTH-1:0]      IO_BIAS_DATA ;
    wire                       IO_BIAS_LAST ;
    wire                       IO_INPUT_READY   ;
    wire                       IO_INPUT_VALID   ;
    wire [M_AXI_WIDTH_DA-1:0]  IO_INPUT_DATA    ;
    wire [M_AXI_WIDTH_DS-1:0]  IO_INPUT_STRB    ;
    wire                       IO_INPUT_LAST    ;
    wire                       IO_INPUT_EMPTY   ;
    wire                       IO_WEIGHT_READY  ;
    wire                       IO_WEIGHT_VALID  ;
    wire [M_AXI_WIDTH_DA-1:0]  IO_WEIGHT_DATA   ;
    wire [M_AXI_WIDTH_DS-1:0]  IO_WEIGHT_STRB   ;
    wire                       IO_WEIGHT_LAST   ;
    wire                       IO_WEIGHT_EMPTY  ;
    wire                       IO_RST_READY     ;
    wire                       IO_RST_VALID     ;
    wire [DATA_WIDTH-1:0]      IO_RST_DATA      ;
    wire [DATA_BYTES-1:0]      IO_RST_STRB      ;
    wire                       IO_RST_LAST      ;
    //--------------------------------------------------------------------------
    linear_1d_core #(.AXI_WIDTH_DA         (M_AXI_WIDTH_DA   )
                    ,.DATA_TYPE            (DATA_TYPE        )
                    ,.DATA_WIDTH           (DATA_WIDTH       )
                    `ifdef DATA_FIXED_POINT
                    ,.DATA_WIDTH_Q         (DATA_WIDTH_Q     )
                    `endif
                    ,.INPUT_FIFO_DEPTH     (INPUT_FIFO_DEPTH )
                    ,.WEIGHT_FIFO_DEPTH    (WEIGHT_FIFO_DEPTH)
                    ,.RESULT_FIFO_DEPTH    (RESULT_FIFO_DEPTH)
                    ,.PROFILE_CNT_WIDTH    (PROFILE_CNT_WIDTH)
                    ,.ACTIV_FUNC_BYPASS    (ACTIV_FUNC_BYPASS    )
                    ,.ACTIV_FUNC_RELU      (ACTIV_FUNC_RELU      )
                    ,.ACTIV_FUNC_LEAKY_RELU(ACTIV_FUNC_LEAKY_RELU)
                    ,.ACTIV_FUNC_SIGMOID   (ACTIV_FUNC_SIGMOID   )
                    ,.ACTIV_FUNC_TANH      (ACTIV_FUNC_TANH      )
                    )
    u_core (
         .RESET_N           ( ARESETn           )
       , .CLK               ( ACLK              )
       , .IN_BIAS_READY     ( IO_BIAS_READY     )
       , .IN_BIAS_VALID     ( IO_BIAS_VALID     )
       , .IN_BIAS_DATA      ( IO_BIAS_DATA      )
       , .IN_BIAS_LAST      ( IO_BIAS_LAST      )
       , .IN_INPUT_READY    ( IO_INPUT_READY    )
       , .IN_INPUT_VALID    ( IO_INPUT_VALID    )
       , .IN_INPUT_DATA     ( IO_INPUT_DATA     )
       , .IN_INPUT_STRB     ( IO_INPUT_STRB     )
       , .IN_INPUT_LAST     ( IO_INPUT_LAST     )
       , .IN_INPUT_EMPTY    ( IO_INPUT_EMPTY    )
       , .IN_WEIGHT_READY   ( IO_WEIGHT_READY   )
       , .IN_WEIGHT_VALID   ( IO_WEIGHT_VALID   )
       , .IN_WEIGHT_DATA    ( IO_WEIGHT_DATA    )
       , .IN_WEIGHT_STRB    ( IO_WEIGHT_STRB    )
       , .IN_WEIGHT_LAST    ( IO_WEIGHT_LAST    )
       , .IN_WEIGHT_EMPTY   ( IO_WEIGHT_EMPTY   )
       , .OUT_RST_READY     ( IO_RST_READY      )
       , .OUT_RST_VALID     ( IO_RST_VALID      )
       , .OUT_RST_DATA      ( IO_RST_DATA       )
       , .OUT_RST_STRB      ( IO_RST_STRB       )
       , .OUT_RST_LAST      ( IO_RST_LAST       )
       , .ACTIV_FUNC        ( activ_func        ) // from controller
       , .ACTIV_PARAM       ( activ_param       ) // from CSR
       , .linear_init       ( linear_init_sync  )
       , .linear_ready      ( linear_core_ready )
       , .profile_init            ( profile_init_sync        )
       , .profile_mac_num         ( profile_mac_num          )
       , .profile_mac_overflow    ( profile_mac_overflow     )
       , .profile_bias_overflow   ( profile_bias_overflow    )
       , .profile_activ_overflow  ( profile_activ_overflow   )
    );
    //--------------------------------------------------------------------------
    linear_1d_control #(.AXI_WIDTH_ID      (M_AXI_WIDTH_ID    )
                       ,.AXI_WIDTH_AD      (M_AXI_WIDTH_AD    )
                       ,.AXI_WIDTH_DA      (M_AXI_WIDTH_DA    )
                       ,.DATA_WIDTH        (DATA_WIDTH        )
                       ,.INPUT_FIFO_DEPTH  (INPUT_FIFO_DEPTH  )
                       ,.WEIGHT_FIFO_DEPTH (WEIGHT_FIFO_DEPTH )
                       ,.RESULT_FIFO_DEPTH (RESULT_FIFO_DEPTH )
                       ,.PROFILE_CNT_WIDTH (PROFILE_CNT_WIDTH )
                       )
    u_control (
          .ARESETn               ( ARESETn              )
        , .ACLK                  ( ACLK                 )
        , .M_AXI_INPUT_ARID      ( M_AXI_INPUT_ARID     )
        , .M_AXI_INPUT_ARADDR    ( M_AXI_INPUT_ARADDR   )
        , .M_AXI_INPUT_ARLEN     ( M_AXI_INPUT_ARLEN    )
        , .M_AXI_INPUT_ARSIZE    ( M_AXI_INPUT_ARSIZE   )
        , .M_AXI_INPUT_ARBURST   ( M_AXI_INPUT_ARBURST  )
        , .M_AXI_INPUT_ARVALID   ( M_AXI_INPUT_ARVALID  )
        , .M_AXI_INPUT_ARREADY   ( M_AXI_INPUT_ARREADY  )
        , .M_AXI_INPUT_RID       ( M_AXI_INPUT_RID      )
        , .M_AXI_INPUT_RDATA     ( M_AXI_INPUT_RDATA    )
        , .M_AXI_INPUT_RRESP     ( M_AXI_INPUT_RRESP    )
        , .M_AXI_INPUT_RLAST     ( M_AXI_INPUT_RLAST    )
        , .M_AXI_INPUT_RVALID    ( M_AXI_INPUT_RVALID   )
        , .M_AXI_INPUT_RREADY    ( M_AXI_INPUT_RREADY   )
        , .M_AXI_WEIGHT_ARID     ( M_AXI_WEIGHT_ARID    )
        , .M_AXI_WEIGHT_ARADDR   ( M_AXI_WEIGHT_ARADDR  )
        , .M_AXI_WEIGHT_ARLEN    ( M_AXI_WEIGHT_ARLEN   )
        , .M_AXI_WEIGHT_ARSIZE   ( M_AXI_WEIGHT_ARSIZE  )
        , .M_AXI_WEIGHT_ARBURST  ( M_AXI_WEIGHT_ARBURST )
        , .M_AXI_WEIGHT_ARVALID  ( M_AXI_WEIGHT_ARVALID )
        , .M_AXI_WEIGHT_ARREADY  ( M_AXI_WEIGHT_ARREADY )
        , .M_AXI_WEIGHT_RID      ( M_AXI_WEIGHT_RID     )
        , .M_AXI_WEIGHT_RDATA    ( M_AXI_WEIGHT_RDATA   )
        , .M_AXI_WEIGHT_RRESP    ( M_AXI_WEIGHT_RRESP   )
        , .M_AXI_WEIGHT_RLAST    ( M_AXI_WEIGHT_RLAST   )
        , .M_AXI_WEIGHT_RVALID   ( M_AXI_WEIGHT_RVALID  )
        , .M_AXI_WEIGHT_RREADY   ( M_AXI_WEIGHT_RREADY  )
        , .M_AXI_RST_AWID        ( M_AXI_RST_AWID       )
        , .M_AXI_RST_AWADDR      ( M_AXI_RST_AWADDR     )
        , .M_AXI_RST_AWLEN       ( M_AXI_RST_AWLEN      )
        , .M_AXI_RST_AWSIZE      ( M_AXI_RST_AWSIZE     )
        , .M_AXI_RST_AWBURST     ( M_AXI_RST_AWBURST    )
        , .M_AXI_RST_AWVALID     ( M_AXI_RST_AWVALID    )
        , .M_AXI_RST_AWREADY     ( M_AXI_RST_AWREADY    )
        , .M_AXI_RST_WDATA       ( M_AXI_RST_WDATA      )
        , .M_AXI_RST_WSTRB       ( M_AXI_RST_WSTRB      )
        , .M_AXI_RST_WLAST       ( M_AXI_RST_WLAST      )
        , .M_AXI_RST_WVALID      ( M_AXI_RST_WVALID     )
        , .M_AXI_RST_WREADY      ( M_AXI_RST_WREADY     )
        , .M_AXI_RST_BID         ( M_AXI_RST_BID        )
        , .M_AXI_RST_BRESP       ( M_AXI_RST_BRESP      )
        , .M_AXI_RST_BVALID      ( M_AXI_RST_BVALID     )
        , .M_AXI_RST_BREADY      ( M_AXI_RST_BREADY     )
        , .OUT_BIAS_READY        ( IO_BIAS_READY        )
        , .OUT_BIAS_VALID        ( IO_BIAS_VALID        )
        , .OUT_BIAS_DATA         ( IO_BIAS_DATA         )
        , .OUT_BIAS_LAST         ( IO_BIAS_LAST         )
        , .OUT_INPUT_READY       ( IO_INPUT_READY       )
        , .OUT_INPUT_VALID       ( IO_INPUT_VALID       )
        , .OUT_INPUT_DATA        ( IO_INPUT_DATA        )
        , .OUT_INPUT_STRB        ( IO_INPUT_STRB        )
        , .OUT_INPUT_LAST        ( IO_INPUT_LAST        )
        , .OUT_INPUT_EMPTY       ( IO_INPUT_EMPTY       )
        , .OUT_WEIGHT_READY      ( IO_WEIGHT_READY      )
        , .OUT_WEIGHT_VALID      ( IO_WEIGHT_VALID      )
        , .OUT_WEIGHT_DATA       ( IO_WEIGHT_DATA       )
        , .OUT_WEIGHT_STRB       ( IO_WEIGHT_STRB       )
        , .OUT_WEIGHT_LAST       ( IO_WEIGHT_LAST       )
        , .OUT_WEIGHT_EMPTY      ( IO_WEIGHT_EMPTY      )
        , .IN_RST_READY          ( IO_RST_READY         )
        , .IN_RST_VALID          ( IO_RST_VALID         )
        , .IN_RST_DATA           ( IO_RST_DATA          )
        , .IN_RST_STRB           ( IO_RST_STRB          )
        , .IN_RST_LAST           ( IO_RST_LAST          )
        , .input_go              ( input_go_sync        )
        , .input_done            ( input_done           )
        , .input_address         ( input_address        )
        , .input_size            ( input_size           )
        , .input_leng            ( input_leng           )
        , .weight_go             ( weight_go_sync       )
        , .weight_done           ( weight_done          )
        , .weight_address        ( weight_address       )
        , .weight_width          ( weight_width         )
        , .weight_height         ( weight_height        )
        , .weight_items          ( weight_items         )
        , .weight_leng           ( weight_leng          )
        , .bias_go               ( bias_go_sync         )
        , .bias_done             ( bias_done            )
        , .bias_address          ( bias_address         )
        , .bias_size             ( bias_size            )
        , .result_go             ( result_go_sync       )
        , .result_done           ( result_done          )
        , .result_address        ( result_address       )
        , .result_size           ( result_size          )
        , .result_leng           ( result_leng          )
        , .linear_init           ( linear_init          )
        , .linear_ready          ( linear_ready         )
        , .linear_core_ready     ( linear_core_ready    )
        , .profile_init          ( profile_init_sync    )
        , .profile_cnt_read      ( profile_cnt_read     )
        , .profile_cnt_write     ( profile_cnt_write    )
    );
    //--------------------------------------------------------------------------
    linear_1d_csr #(.APB_WIDTH_AD      (APB_WIDTH_AD     )
                   ,.APB_WIDTH_DA      (APB_WIDTH_DA     )
                   ,.AXI_WIDTH_AD      (M_AXI_WIDTH_AD   )
                   ,.DATA_TYPE         (DATA_TYPE        )
                   ,.DATA_WIDTH        (DATA_WIDTH       )
                   `ifdef DATA_FIXED_POINT
                   ,.DATA_WIDTH_Q      (DATA_WIDTH_Q     )
                   `endif
                   ,.INPUT_FIFO_DEPTH  (INPUT_FIFO_DEPTH )
                   ,.WEIGHT_FIFO_DEPTH (WEIGHT_FIFO_DEPTH)
                   ,.RESULT_FIFO_DEPTH (RESULT_FIFO_DEPTH)
                   ,.PROFILE_CNT_WIDTH (PROFILE_CNT_WIDTH)
                   )
    u_csr (
         .PRESETn             ( PRESETn )
       , .PCLK                ( PCLK    )
       , .PSEL                ( PSEL    )
       , .PENABLE             ( PENABLE )
       , .PADDR               ( PADDR   )
       , .PWRITE              ( PWRITE  )
       , .PRDATA              ( PRDATA  )
       , .PWDATA              ( PWDATA  )
       , .input_go            ( input_go           )
       , .input_done          ( input_done_sync    )
       , .input_address       ( input_address      )
       , .input_size          ( input_size         )
       , .input_leng          ( input_leng         )
       , .weight_go           ( weight_go          )
       , .weight_done         ( weight_done_sync   )
       , .weight_address      ( weight_address     )
       , .weight_width        ( weight_width       )
       , .weight_height       ( weight_height      )
       , .weight_items        ( weight_items       )
       , .weight_leng         ( weight_leng        )
       , .bias_go             ( bias_go            )
       , .bias_done           ( bias_done_sync     )
       , .bias_address        ( bias_address       )
       , .bias_size           ( bias_size          )
       , .result_go           ( result_go          )
       , .result_done         ( result_done_sync   )
       , .result_address      ( result_address     )
       , .result_size         ( result_size        )
       , .result_leng         ( result_leng        )
       , .linear_activ_func   ( activ_func         )
       , .linear_activ_param  ( activ_param        )
       , .linear_init         ( linear_init        )
       , .linear_ready        ( linear_ready_sync  )
       , .profile_init           ( profile_init              )
       , .profile_snapshot       ( profile_snapshot          )
       , .profile_done           ( profile_done_sync         )
       , .profile_mac_num        ( profile_mac_num_reg       )
       , .profile_mac_overflow   ( profile_mac_overflow_reg  )
       , .profile_bias_overflow  ( profile_bias_overflow_reg )
       , .profile_activ_overflow ( profile_activ_overflow_reg)
       , .profile_cnt_read       ( profile_cnt_read_reg      )
       , .profile_cnt_write      ( profile_cnt_write_reg     )
       , .interrupt              ( interrupt                 )
    );
    //--------------------------------------------------------------------------
    linear_1d_sync u_sync_init (
          .reset_n ( ARESETn          )
        , .clk     ( ACLK             )
        , .sig_in  ( linear_init      )
        , .sig_out ( linear_init_sync )
    );
    linear_1d_sync u_sync_profile_init (
          .reset_n ( ARESETn           )
        , .clk     ( ACLK              )
        , .sig_in  ( profile_init      )
        , .sig_out ( profile_init_sync )
    );
    linear_1d_sync u_sync_profile_snapshot (
          .reset_n ( ARESETn               )
        , .clk     ( ACLK                  )
        , .sig_in  ( profile_snapshot      )
        , .sig_out ( profile_snapshot_sync )
    );
    linear_1d_sync u_sync_bias_go (
          .reset_n ( ARESETn      )
        , .clk     ( ACLK         )
        , .sig_in  ( bias_go      )
        , .sig_out ( bias_go_sync )
    );
    linear_1d_sync u_sync_input_go (
          .reset_n ( ARESETn       )
        , .clk     ( ACLK          )
        , .sig_in  ( input_go      )
        , .sig_out ( input_go_sync )
    );
    linear_1d_sync u_sync_weight_go (
          .reset_n ( ARESETn        )
        , .clk     ( ACLK           )
        , .sig_in  ( weight_go      )
        , .sig_out ( weight_go_sync )
    );
    linear_1d_sync u_sync_result_go (
          .reset_n ( ARESETn        )
        , .clk     ( ACLK           )
        , .sig_in  ( result_go      )
        , .sig_out ( result_go_sync )
    );
    //--------------------------------------------------------------------------
    linear_1d_sync u_sync_ready (
          .reset_n ( PRESETn         )
        , .clk     ( PCLK            )
        , .sig_in  ( linear_ready      )
        , .sig_out ( linear_ready_sync )
    );
    linear_1d_sync u_sync_profile_done ( // snapshot done
          .reset_n ( PRESETn           )
        , .clk     ( PCLK              )
        , .sig_in  ( profile_done      )
        , .sig_out ( profile_done_sync )
    );
    linear_1d_sync u_sync_bias_done (
          .reset_n ( PRESETn        )
        , .clk     ( PCLK           )
        , .sig_in  ( bias_done      )
        , .sig_out ( bias_done_sync )
    );
    linear_1d_sync u_sync_input_done (
          .reset_n ( PRESETn         )
        , .clk     ( PCLK            )
        , .sig_in  ( input_done      )
        , .sig_out ( input_done_sync )
    );
    linear_1d_sync u_sync_weight_done (
          .reset_n ( PRESETn          )
        , .clk     ( PCLK             )
        , .sig_in  ( weight_done      )
        , .sig_out ( weight_done_sync )
    );
    linear_1d_sync u_sync_result_done (
          .reset_n ( PRESETn          )
        , .clk     ( PCLK             )
        , .sig_in  ( result_done      )
        , .sig_out ( result_done_sync )
    );
    //--------------------------------------------------------------------------
    always @ (posedge ACLK or negedge ARESETn) begin
    if (ARESETn==1'b0) begin
        profile_done                 <=1'b0;
        profile_mac_num_reg          <= 'h0; // get valid value when profile_done
        profile_mac_overflow_reg     <= 'h0; // get valid value when profile_done
        profile_bias_overflow_reg    <= 'h0; // get valid value when profile_done
        profile_activ_overflow_reg   <= 'h0; // get valid value when profile_done
        profile_cnt_read_reg         <= 'h0; // get valid value when profile_done
        profile_cnt_write_reg        <= 'h0; // get valid value when profile_done
    end else begin
        if ((profile_done==1'b0)&&(profile_snapshot_sync==1'b1)) begin
            profile_mac_num_reg          <= profile_mac_num;
            profile_mac_overflow_reg     <= profile_mac_overflow;
            profile_bias_overflow_reg    <= profile_bias_overflow;
            profile_activ_overflow_reg   <= profile_activ_overflow;
            profile_cnt_read_reg         <= profile_cnt_read;
            profile_cnt_write_reg        <= profile_cnt_write;
            profile_done                 <= 1'b1;
        end else begin
            if (profile_snapshot_sync==1'b0) begin
                profile_done <= 1'b0;
            end
        end
    end
    end // always
endmodule
//------------------------------------------------------------------------------
// Revision history
//
// 2021.11.06: APB
// 2021.06.10: Started by Ando Ki (andoki@gmail.com)
//------------------------------------------------------------------------------
