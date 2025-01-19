//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All right reserved.
//------------------------------------------------------------------------------
// VERSION: 2021.06.10.
//------------------------------------------------------------------------------
// Linear 1D Controller
//------------------------------------------------------------------------------
`ifdef SIM
    `ifdef __ICARUS__
        `define  LIN_DLY
    `else
        `define  LIN_DLY #1
    `endif
`else
    `define  LIN_DLY
`endif

`include "linear_1d_control_input.v"
`include "linear_1d_control_weight.v"
`include "linear_1d_control_result.v"
`include "linear_1d_fifo_sync.v"
`include "linear_1d_fifo_sync_merger.v"

module linear_1d_control
     #(parameter AXI_WIDTH_ID =4       // ID width in bits
               , AXI_WIDTH_AD =32      // address width
               , AXI_WIDTH_DA =32      // data width
               , AXI_WIDTH_DS =AXI_WIDTH_DA/8
               , DATA_WIDTH       =32
               , DATA_BYTES       =(DATA_WIDTH/8)// num of bytes per item (1 for byte)
               , INPUT_FIFO_DEPTH =32
               , WEIGHT_FIFO_DEPTH=INPUT_FIFO_DEPTH
               , RESULT_FIFO_DEPTH=16
               , INPUT_FIFO_AW    =$clog2(INPUT_FIFO_DEPTH )
               , WEIGHT_FIFO_AW   =$clog2(WEIGHT_FIFO_DEPTH)
               , RESULT_FIFO_AW   =$clog2(RESULT_FIFO_DEPTH )
               , PROFILE_CNT_WIDTH=32
               )
(
      input   wire                           ARESETn
    , input   wire                           ACLK
    // master port for input & bias (read-only)
    , output  wire  [AXI_WIDTH_ID-1:0]       M_AXI_INPUT_ARID
    , output  wire  [AXI_WIDTH_AD-1:0]       M_AXI_INPUT_ARADDR
    , output  wire  [ 7:0]                   M_AXI_INPUT_ARLEN
    , output  wire  [ 2:0]                   M_AXI_INPUT_ARSIZE
    , output  wire  [ 1:0]                   M_AXI_INPUT_ARBURST
    , output  wire                           M_AXI_INPUT_ARVALID
    , input   wire                           M_AXI_INPUT_ARREADY
    , input   wire  [AXI_WIDTH_ID-1:0]       M_AXI_INPUT_RID
    , input   wire  [AXI_WIDTH_DA-1:0]       M_AXI_INPUT_RDATA
    , input   wire  [ 1:0]                   M_AXI_INPUT_RRESP
    , input   wire                           M_AXI_INPUT_RLAST
    , input   wire                           M_AXI_INPUT_RVALID
    , output  wire                           M_AXI_INPUT_RREADY
    // master port for weight (read-only)
    , output  wire  [AXI_WIDTH_ID-1:0]       M_AXI_WEIGHT_ARID
    , output  wire  [AXI_WIDTH_AD-1:0]       M_AXI_WEIGHT_ARADDR
    , output  wire  [ 7:0]                   M_AXI_WEIGHT_ARLEN
    , output  wire  [ 2:0]                   M_AXI_WEIGHT_ARSIZE
    , output  wire  [ 1:0]                   M_AXI_WEIGHT_ARBURST
    , output  wire                           M_AXI_WEIGHT_ARVALID
    , input   wire                           M_AXI_WEIGHT_ARREADY
    , input   wire  [AXI_WIDTH_ID-1:0]       M_AXI_WEIGHT_RID
    , input   wire  [AXI_WIDTH_DA-1:0]       M_AXI_WEIGHT_RDATA
    , input   wire  [ 1:0]                   M_AXI_WEIGHT_RRESP
    , input   wire                           M_AXI_WEIGHT_RLAST
    , input   wire                           M_AXI_WEIGHT_RVALID
    , output  wire                           M_AXI_WEIGHT_RREADY
    // master port for result (write-only)
    , output  wire  [AXI_WIDTH_ID-1:0]       M_AXI_RST_AWID
    , output  wire  [AXI_WIDTH_AD-1:0]       M_AXI_RST_AWADDR
    , output  wire  [ 7:0]                   M_AXI_RST_AWLEN
    , output  wire  [ 2:0]                   M_AXI_RST_AWSIZE
    , output  wire  [ 1:0]                   M_AXI_RST_AWBURST
    , output  wire                           M_AXI_RST_AWVALID
    , input   wire                           M_AXI_RST_AWREADY
    , output  wire  [AXI_WIDTH_DA-1:0]       M_AXI_RST_WDATA
    , output  wire  [AXI_WIDTH_DS-1:0]       M_AXI_RST_WSTRB
    , output  wire                           M_AXI_RST_WLAST
    , output  wire                           M_AXI_RST_WVALID
    , input   wire                           M_AXI_RST_WREADY
    , input   wire  [AXI_WIDTH_ID-1:0]       M_AXI_RST_BID
    , input   wire  [ 1:0]                   M_AXI_RST_BRESP
    , input   wire                           M_AXI_RST_BVALID
    , output  wire                           M_AXI_RST_BREADY
    //
    , input   wire                           OUT_BIAS_READY
    , output  wire                           OUT_BIAS_VALID
    , output  wire  [DATA_WIDTH-1:0]         OUT_BIAS_DATA
    , output  wire                           OUT_BIAS_LAST // indicates the end of bias
    // for input-vector part of linear
    , input   wire                           OUT_INPUT_READY
    , output  wire                           OUT_INPUT_VALID
    , output  wire  [AXI_WIDTH_DA-1:0]       OUT_INPUT_DATA // justified
    , output  wire  [AXI_WIDTH_DS-1:0]       OUT_INPUT_STRB // justified
    , output  wire                           OUT_INPUT_LAST // indicates the end of each line
    , output  wire                           OUT_INPUT_EMPTY
    // for weight
    , input   wire                           OUT_WEIGHT_READY
    , output  wire                           OUT_WEIGHT_VALID
    , output  wire  [AXI_WIDTH_DA-1:0]       OUT_WEIGHT_DATA // justified
    , output  wire  [AXI_WIDTH_DS-1:0]       OUT_WEIGHT_STRB // justified
    , output  wire                           OUT_WEIGHT_LAST // indicates the end of each line
    , output  wire                           OUT_WEIGHT_EMPTY
    // resultant
    , output  wire                           IN_RST_READY
    , input   wire                           IN_RST_VALID // it should be interpreced along with IN_RST_LAST
    , input   wire  [DATA_WIDTH-1:0]         IN_RST_DATA // justified
    , input   wire  [DATA_BYTES-1:0]         IN_RST_STRB // justified
    , input   wire                           IN_RST_LAST // indicates the end of MAC
    //
    , input   wire                           bias_go
    , output  wire                           bias_done
    , input   wire  [AXI_WIDTH_AD-1:0]       bias_address
    , input   wire  [15:0]                   bias_size 
    //
    , input   wire                           input_go
    , output  wire                           input_done
    , input   wire  [AXI_WIDTH_AD-1:0]       input_address
    , input   wire  [15:0]                   input_size // num of elements of input-vector
    , input   wire  [ 7:0]                   input_leng // AxLENG format, = block_size-1
                                                        // use "block_size-1" instead
    // note it is transposed matrix
    , input   wire                           weight_go
    , output  wire                           weight_done
    , input   wire  [AXI_WIDTH_AD-1:0]       weight_address
    , input   wire  [15:0]                   weight_width// num of items in row (i.e., num of columns)
    , input   wire  [15:0]                   weight_height// num of items in column (i.e., num of rows)
    , input   wire  [31:0]                   weight_items// num of items of weight-matrix
    , input   wire  [ 7:0]                   weight_leng // AxLENG format, = block_size-1
                                                         // use "block_size-1" instead
    //
    , input   wire                           result_go
    , output  wire                           result_done
    , input   wire  [AXI_WIDTH_AD-1:0]       result_address
    , input   wire  [15:0]                   result_size
    , input   wire  [ 7:0]                   result_leng // AxLENG format
    //
    , input   wire                           linear_init // synchronous initialization (a pulse)
    , output  wire                           linear_ready // to upward
    , input   wire                           linear_core_ready // from linear_1d_core
    //
    , input   wire                           profile_init
    , output  reg   [PROFILE_CNT_WIDTH-1:0]  profile_cnt_read
    , output  reg   [PROFILE_CNT_WIDTH-1:0]  profile_cnt_write
);
    //--------------------------------------------------------------------------
    // synthesis translate_off
    initial begin
      //if (AXI_WIDTH_DA!=32) begin
      //    $display("%m ERROR AXI-MM data width %d is not supplorted yet.", AXI_WIDTH_DA);
      //end
        if ((DATA_WIDTH!=AXI_WIDTH_DA)&&
            (DATA_WIDTH!=(AXI_WIDTH_DA/2))&&
            (DATA_WIDTH!=(AXI_WIDTH_DA/4))&&
            (DATA_WIDTH!=(AXI_WIDTH_DA/8))&&
            (DATA_WIDTH!=(AXI_WIDTH_DA/16))) begin
            $display("%m ERROR AXI-Stream data width %d:%d is not supplorted yet.", AXI_WIDTH_DA, DATA_WIDTH);
        end
        if (weight_go==1'b1) begin
            if (input_size!=weight_width)
                $display("%0t %m ERROR input-vector size should be the same as width of weight-matrix.", $time);
            if ((bias_size!=0)&&(bias_size!=weight_height))
                $display("%0t %m ERROR bias-vector size should be the same as height of weight-matrix.", $time);
            if (result_size!=weight_height)
                $display("%0t %m ERROR result-vector size should be the same as height of weight-matrix.", $time);
        end
    end // initial
    // synthesis translate_on
    //--------------------------------------------------------------------------
    wire linear_ready_input ;
    wire linear_ready_weight;
    wire linear_ready_result;
    assign linear_ready = ~linear_init&
                           linear_ready_input&linear_ready_weight&linear_ready_result&
                           linear_core_ready;
    //--------------------------------------------------------------------------
    // straight vector-matrix multiplication
    //
    //   +---+-------------+   +---+---+---------+   +---+    +---+ 
    //   | A0|             | x |W00|W01|         | + | B0| =  | C0| 
    //   +---+-------------+   +-------+---------+   +---+    +---+ 
    //                         |W10|W11|         |   | B1|    | C1| 
    //                         +-----------------+   +---+    +---+ 
    //                         |                 |   |   |    |   |
    //                         +---+-------------+   +---+    +---+ 
    //
    //--------------------------------------------------------------------------
    // It reads a block of input-vector and fills input FIFO.
    linear_1d_control_input #(.AXI_WIDTH_ID   ( AXI_WIDTH_ID      )
                             ,.AXI_WIDTH_AD   ( AXI_WIDTH_AD      )
                             ,.AXI_WIDTH_DA   ( AXI_WIDTH_DA      )
                             ,.DATA_WIDTH     ( DATA_WIDTH        )
                             ,.FIFO_DEPTH     ( INPUT_FIFO_DEPTH )
                             )
    u_input (
          .ARESETn       ( ARESETn              )
        , .ACLK          ( ACLK                 )
        , .AXI_ARID      ( M_AXI_INPUT_ARID     )
        , .AXI_ARADDR    ( M_AXI_INPUT_ARADDR   )
        , .AXI_ARLEN     ( M_AXI_INPUT_ARLEN    )
        , .AXI_ARSIZE    ( M_AXI_INPUT_ARSIZE   )
        , .AXI_ARBURST   ( M_AXI_INPUT_ARBURST  )
        , .AXI_ARVALID   ( M_AXI_INPUT_ARVALID  )
        , .AXI_ARREADY   ( M_AXI_INPUT_ARREADY  )
        , .AXI_RID       ( M_AXI_INPUT_RID      )
        , .AXI_RDATA     ( M_AXI_INPUT_RDATA    )
        , .AXI_RRESP     ( M_AXI_INPUT_RRESP    )
        , .AXI_RLAST     ( M_AXI_INPUT_RLAST    )
        , .AXI_RVALID    ( M_AXI_INPUT_RVALID   )
        , .AXI_RREADY    ( M_AXI_INPUT_RREADY   )
        , .OUT_BIAS_READY( OUT_BIAS_READY       )
        , .OUT_BIAS_VALID( OUT_BIAS_VALID       )
        , .OUT_BIAS_DATA ( OUT_BIAS_DATA        )
        , .OUT_BIAS_LAST ( OUT_BIAS_LAST        )
        , .OUT_READY     ( OUT_INPUT_READY      )
        , .OUT_VALID     ( OUT_INPUT_VALID      )
        , .OUT_DATA      ( OUT_INPUT_DATA       )
        , .OUT_STRB      ( OUT_INPUT_STRB       )
        , .OUT_LAST      ( OUT_INPUT_LAST       )
        , .OUT_EMPTY     ( OUT_INPUT_EMPTY      )
        , .linear_init   ( linear_init          )
        , .linear_ready  ( linear_ready_input   )
        , .bias_go       ( bias_go              )
        , .bias_done     ( bias_done            )
        , .bias_address  ( bias_address         )
        , .bias_size     ( bias_size            )
        , .output_size   ( weight_height        )
        , .input_go      ( input_go             )
        , .input_done    ( input_done           )
        , .input_address ( input_address        )
        , .input_size    ( input_size           )
        , .input_num     ( weight_height        )
        , .input_leng    ( input_leng           )
    );
    //--------------------------------------------------------------------------
    // It reads a block (burst) of columns from memory and fills them to the FIFO.
    // It shoud generate 'OUT_WEIDTH_LAST' at the end of each burst.
    linear_1d_control_weight #(.AXI_WIDTH_ID   ( AXI_WIDTH_ID       )
                              ,.AXI_WIDTH_AD   ( AXI_WIDTH_AD       )
                              ,.AXI_WIDTH_DA   ( AXI_WIDTH_DA       )
                              ,.DATA_WIDTH     ( DATA_WIDTH         )
                              ,.FIFO_DEPTH     ( WEIGHT_FIFO_DEPTH )
                              )
    u_weight (
          .ARESETn        ( ARESETn              )
        , .ACLK           ( ACLK                 )
        , .AXI_ARID       ( M_AXI_WEIGHT_ARID    )
        , .AXI_ARADDR     ( M_AXI_WEIGHT_ARADDR  )
        , .AXI_ARLEN      ( M_AXI_WEIGHT_ARLEN   )
        , .AXI_ARSIZE     ( M_AXI_WEIGHT_ARSIZE  )
        , .AXI_ARBURST    ( M_AXI_WEIGHT_ARBURST )
        , .AXI_ARVALID    ( M_AXI_WEIGHT_ARVALID )
        , .AXI_ARREADY    ( M_AXI_WEIGHT_ARREADY )
        , .AXI_RID        ( M_AXI_WEIGHT_RID     )
        , .AXI_RDATA      ( M_AXI_WEIGHT_RDATA   )
        , .AXI_RRESP      ( M_AXI_WEIGHT_RRESP   )
        , .AXI_RLAST      ( M_AXI_WEIGHT_RLAST   )
        , .AXI_RVALID     ( M_AXI_WEIGHT_RVALID  )
        , .AXI_RREADY     ( M_AXI_WEIGHT_RREADY  )
        , .OUT_READY      ( OUT_WEIGHT_READY     )
        , .OUT_VALID      ( OUT_WEIGHT_VALID     )
        , .OUT_DATA       ( OUT_WEIGHT_DATA      )
        , .OUT_STRB       ( OUT_WEIGHT_STRB      )
        , .OUT_LAST       ( OUT_WEIGHT_LAST      )
        , .OUT_EMPTY      ( OUT_WEIGHT_EMPTY     )
        , .linear_init    ( linear_init          )
        , .linear_ready   ( linear_ready_weight  )
        , .weight_go      ( weight_go            )
        , .weight_done    ( weight_done          )
        , .weight_address ( weight_address       )
        , .weight_width   ( weight_width         )
        , .weight_height  ( weight_height        )
        , .weight_leng    ( weight_leng          )
        , .weight_items   ( weight_items         )
    );
    //--------------------------------------------------------------------------
    // It reads all results from the FIFO and writes them to the memory.
    linear_1d_control_result #(.AXI_WIDTH_ID   ( AXI_WIDTH_ID      )
                              ,.AXI_WIDTH_AD   ( AXI_WIDTH_AD      )
                              ,.AXI_WIDTH_DA   ( AXI_WIDTH_DA      )
                              ,.DATA_WIDTH     ( DATA_WIDTH        )
                              ,.FIFO_DEPTH     ( RESULT_FIFO_DEPTH )
                              )
    u_result (
          .ARESETn          ( ARESETn              )
        , .ACLK             ( ACLK                 )
        , .AXI_AWID         ( M_AXI_RST_AWID       )
        , .AXI_AWADDR       ( M_AXI_RST_AWADDR     )
        , .AXI_AWLEN        ( M_AXI_RST_AWLEN      )
        , .AXI_AWSIZE       ( M_AXI_RST_AWSIZE     )
        , .AXI_AWBURST      ( M_AXI_RST_AWBURST    )
        , .AXI_AWVALID      ( M_AXI_RST_AWVALID    )
        , .AXI_AWREADY      ( M_AXI_RST_AWREADY    )
        , .AXI_WDATA        ( M_AXI_RST_WDATA      )
        , .AXI_WSTRB        ( M_AXI_RST_WSTRB      )
        , .AXI_WLAST        ( M_AXI_RST_WLAST      )
        , .AXI_WVALID       ( M_AXI_RST_WVALID     )
        , .AXI_WREADY       ( M_AXI_RST_WREADY     )
        , .AXI_BID          ( M_AXI_RST_BID        )
        , .AXI_BRESP        ( M_AXI_RST_BRESP      )
        , .AXI_BVALID       ( M_AXI_RST_BVALID     )
        , .AXI_BREADY       ( M_AXI_RST_BREADY     )
        , .IN_READY         ( IN_RST_READY         )
        , .IN_VALID         ( IN_RST_VALID         )
        , .IN_DATA          ( IN_RST_DATA          )
        , .IN_STRB          ( IN_RST_STRB          )
        , .IN_LAST          ( IN_RST_LAST          )
        , .linear_init      ( linear_init          )
        , .linear_ready     ( linear_ready_result  )
        , .result_go        ( result_go            )
        , .result_done      ( result_done          )
        , .result_address   ( result_address       )
        , .result_size      ( result_size          )
        , .result_leng      ( result_leng          )
    );
    //--------------------------------------------------------------------------
    wire input_read=(M_AXI_INPUT_RVALID&M_AXI_INPUT_RREADY);
    wire weight_read=(M_AXI_WEIGHT_RVALID&M_AXI_WEIGHT_RREADY);
    wire result_write=(M_AXI_RST_WVALID&M_AXI_RST_WREADY);
    //--------------------------------------------------------------------------
    always @ ( posedge ACLK or negedge ARESETn) begin
    if (ARESETn==1'b0) begin
        profile_cnt_read  <= 'h0;
        profile_cnt_write <= 'h0;
    end else if (profile_init==1'b1) begin
        profile_cnt_read  <= 'h0;
        profile_cnt_write <= 'h0;
    end else begin
        case ({input_read,weight_read})
        2'b01:   profile_cnt_read <= profile_cnt_read + 1;
        2'b10:   profile_cnt_read <= profile_cnt_read + 1;
        2'b11:   profile_cnt_read <= profile_cnt_read + 2;
        default: profile_cnt_read <= profile_cnt_read;
        endcase
        if (result_write) profile_cnt_write <= profile_cnt_write + 1;
    end // if
    end // always
endmodule
//------------------------------------------------------------------------------
// Revision history
//
// 2021.06.10: Started by Ando Ki (andoki@gmail.com)
//------------------------------------------------------------------------------
