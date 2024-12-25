//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All right reserved.
//------------------------------------------------------------------------------
// VERSION: 2021.11.09.
//------------------------------------------------------------------------------
// Mover 2D Controller
//------------------------------------------------------------------------------
//
//    +----------------------------------+   +--------------------+
//    |   source                         |   |result              |
//    |  +---+ srcA +---+  -+-+-+   +--+ |   |             +---+  |
//    |  | B |=====>| X |==>| | |==>|  | |   |             | B |  |
//    |  | U |      +---+  -+-+-+   |  | |   | +---+       | U |  |
//  ====>| S |                      |op|======>| Y |======>| S |====>
//    |  | I | srcB +---+  -+-+-+   |  | |   | +---+ result| I |  |
//    |  | F |=====>| X |==>| | |==>|  | |   |             | F |  |
//    |  +---+      +---+  -+-+-+   +--+ |   |             +---+  |
//    |      justified  filled  syched   |   |      filled        |
//    |                                  |   |      justified     |
//    +----------------------------------+   +--------------------+
//             X: merger_push
//             Y: merger_pop
//    * justified: right-justified for partial data.
//    * filled: make a whole entry for fifo if possible.
//------------------------------------------------------------------------------
`include "mover_2d_fifo_sync.v"
`include "mover_2d_fifo_sync_merger.v"
`include "mover_2d_activation.v"

module mover_2d_control
     #(parameter AXI_WIDTH_ID =4       // ID width in bits
               , AXI_WIDTH_AD =32      // address width
               , AXI_WIDTH_DA =32      // data width
               , AXI_WIDTH_DS =AXI_WIDTH_DA/8
               , AXI_WIDTH_DSB=$clog2(AXI_WIDTH_DS)
               , DATA_TYPE      ="INTEGER" // "INTEGER", "FLOATING_POINT", "FIXED_POINT"
               , DATA_WIDTH        =32
               , DATA_WIDTH_DSB    =$clog2(DATA_WIDTH/8)
               , SRC_FIFO_DEPTH    =16 // To prevent full it should be >=(burst-length * AXI_WIDTH_DS)
               , RESULT_FIFO_DEPTH =16 // not used at this version; use fifo_merger_pop instead of fifo_merger
               , PROFILE_CNT_WIDTH =32,
       parameter [3:0] MOVER_COMMAND_NOP      = 'h0,
       parameter [3:0] MOVER_COMMAND_FILL     = 'h1,
       parameter [3:0] MOVER_COMMAND_COPY     = 'h2,
       parameter [3:0] MOVER_COMMAND_RESIDUAL = 'h3,// point-to-point adder
       parameter [3:0] MOVER_COMMAND_CONCAT0  = 'h4,
       parameter [3:0] MOVER_COMMAND_CONCAT1  = 'h5,
       parameter [3:0] MOVER_COMMAND_TRANSPOSE= 'h6,
       parameter [3:0] ACTIV_FUNC_BYPASS    =4'h0,
       parameter [3:0] ACTIV_FUNC_RELU      =4'h1,
       parameter [3:0] ACTIV_FUNC_LEAKY_RELU=4'h2,
       parameter [3:0] ACTIV_FUNC_SIGMOID   =4'h3,
       parameter [3:0] ACTIV_FUNC_TANH      =4'h4
               )
(
      input   wire                        ARESETn
    , input   wire                        ACLK
    // master port for feature (read-only)
    , output  wire  [AXI_WIDTH_ID-1:0]    M_AXI_SRC_ARID
    , output  wire  [AXI_WIDTH_AD-1:0]    M_AXI_SRC_ARADDR
    , output  wire  [ 7:0]                M_AXI_SRC_ARLEN
    , output  wire  [ 2:0]                M_AXI_SRC_ARSIZE
    , output  wire  [ 1:0]                M_AXI_SRC_ARBURST
    , output  wire                        M_AXI_SRC_ARVALID
    , input   wire                        M_AXI_SRC_ARREADY
    , input   wire  [AXI_WIDTH_ID-1:0]    M_AXI_SRC_RID
    , input   wire  [AXI_WIDTH_DA-1:0]    M_AXI_SRC_RDATA
    , input   wire  [ 1:0]                M_AXI_SRC_RRESP
    , input   wire                        M_AXI_SRC_RLAST
    , input   wire                        M_AXI_SRC_RVALID
    , output  wire                        M_AXI_SRC_RREADY
    // master port for result (write-only)
    , output  wire  [AXI_WIDTH_ID-1:0]    M_AXI_RST_AWID
    , output  wire  [AXI_WIDTH_AD-1:0]    M_AXI_RST_AWADDR
    , output  wire  [ 7:0]                M_AXI_RST_AWLEN
    , output  wire  [ 2:0]                M_AXI_RST_AWSIZE
    , output  wire  [ 1:0]                M_AXI_RST_AWBURST
    , output  wire                        M_AXI_RST_AWVALID
    , input   wire                        M_AXI_RST_AWREADY
    , output  wire  [AXI_WIDTH_DA-1:0]    M_AXI_RST_WDATA
    , output  wire  [AXI_WIDTH_DS-1:0]    M_AXI_RST_WSTRB
    , output  wire                        M_AXI_RST_WLAST
    , output  wire                        M_AXI_RST_WVALID
    , input   wire                        M_AXI_RST_WREADY
    , input   wire  [AXI_WIDTH_ID-1:0]    M_AXI_RST_BID
    , input   wire  [ 1:0]                M_AXI_RST_BRESP
    , input   wire                        M_AXI_RST_BVALID
    , output  wire                        M_AXI_RST_BREADY
    //
    , input   wire  [ 3:0]                command
    //
    , input   wire                        sourceA_go
    , output  wire                        sourceA_done// read-done
    , input   wire  [AXI_WIDTH_AD-1:0]    sourceA_address
    , input   wire  [15:0]                sourceA_width// num of items in row (i.e., num of columns)
    , input   wire  [15:0]                sourceA_height// num of items in column (i.e., num of rows)
    , input   wire  [31:0]                sourceA_items// num of items in a feature
    , input   wire  [ 7:0]                sourceA_leng // AxLENG format
    //
    , input   wire                        sourceB_go
    , output  wire                        sourceB_done// read-done
    , input   wire  [AXI_WIDTH_AD-1:0]    sourceB_address
    , input   wire  [15:0]                sourceB_width// num of items in row (i.e., num of columns)
    , input   wire  [15:0]                sourceB_height// num of items in column (i.e., num of rows)
    , input   wire  [31:0]                sourceB_items// num of items in a feature
    , input   wire  [ 7:0]                sourceB_leng // AxLENG format
    //
    , input   wire                        result_go
    , output  wire                        result_done// read-done
    , input   wire  [AXI_WIDTH_AD-1:0]    result_address
    , input   wire  [15:0]                result_width
    , input   wire  [15:0]                result_height
    , input   wire  [31:0]                result_items// num of items whole (not byte)
    , input   wire  [ 7:0]                result_leng // AxLENG format
    //
    , input   wire  [DATA_WIDTH-1:0]      fill_value // value for fill command
    , input   wire  [ 3:0]                activ_func
    , input   wire  [DATA_WIDTH-1:0]      activ_param
    //
    , input   wire                        mover_init // synchronous initialization
    , output  reg                         mover_ready // to upward
    //
    , input  wire                           profile_init
    , output wire  [PROFILE_CNT_WIDTH-1:0]  profile_residual_overflow
    , output reg   [PROFILE_CNT_WIDTH-1:0]  profile_cnt_read
    , output reg   [PROFILE_CNT_WIDTH-1:0]  profile_cnt_write
);
    //--------------------------------------------------------------------------
    // synthesis translate_off
    initial begin
        if ((DATA_WIDTH!=AXI_WIDTH_DA)&&
            (DATA_WIDTH!=(AXI_WIDTH_DA/2))&&
            (DATA_WIDTH!=(AXI_WIDTH_DA/4))) begin
            $display("%m ERROR AXI-Stream data width %d:%d is not supplorted yet.", AXI_WIDTH_DA, DATA_WIDTH);
        end
    end // initial
    // synthesis translate_on
    //--------------------------------------------------------------------------
    wire source_ready;
    wire result_ready;
    //--------------------------------------------------------------------------
    reg srcA_go=1'b0; // in order to start feature after kernel.
    reg srcB_go=1'b0; // in order to start feature after kernel.
    reg rst_go =1'b0;
    //--------------------------------------------------------------------------
    localparam ST_READY='h0
             , ST_GO   ='h1
             , ST_DONE ='h2;
    `DBG_MOVER reg [1:0] state=ST_READY;
    //--------------------------------------------------------------------------
    always @ (posedge ACLK or negedge ARESETn) begin
    if (ARESETn==1'b0) begin
        srcA_go     <= 1'b0;
        srcB_go     <= 1'b0;
        rst_go      <= 1'b0;
        mover_ready <= 1'b0;
        state       <= ST_READY;
    end else if (mover_init==1'b1) begin
        srcA_go     <= 1'b0;
        srcB_go     <= 1'b0;
        rst_go      <= 1'b0;
        mover_ready <= 1'b0;
        state       <= ST_READY;
    end else begin
        case (state)
        ST_READY: begin
           mover_ready <= source_ready&result_ready;
           (* full_case *)
           case ({result_go,command}) // synthesis full_case parallel_case
           {1'b1,MOVER_COMMAND_COPY[3:0]}:     begin
// Simple DMA supporting mis-aligned address both srcA and dst
// +------------+          +------------+
// |srcA        | -+-+-+   |dst         |
// |            |=>| | |==>|            |
// |            | -+-+-+   |            |
// +------------+          +------------+
// srcA can be dst
// last=flush (at the end of whole move)
                 if (sourceA_go) begin
                    srcA_go <= 1'b1;
                    srcB_go <= 1'b0;
                    rst_go  <= 1'b1;
                    state   <= ST_GO;
                 end // if
                 // synthesis translate_off
                 if ((sourceA_width!=result_width)||
                     (sourceA_height!=result_height)||
                     (sourceA_items!=result_items))
                     $display("%0t %m ERROR mis-match: width, height, items.", $time);
                 if (DATA_WIDTH>8) begin
                     if (sourceA_address[DATA_WIDTH_DSB-1:0]!='h0)
                         $display("%0t %m WARNING mis-aligned source access.", $time);
                     if (result_address[DATA_WIDTH_DSB-1:0]!='h0)
                         $display("%0t %m WARNING mis-aligned destination access.", $time);
                 end
                 if (sourceB_go)
                     $display("%0t %m WARNING sourceB are not relevant.", $time);
                 // synthesis translate_on
                 end // command_move
           {1'b1,MOVER_COMMAND_RESIDUAL[3:0]}: begin
// RESIDUAL, i.e., point-to-point adder
// +------------+                +------------+
// |srcA        | -+-+-+         |dst         |
// |            |=>| | |==(+)===>|            |
// |            | -+-+-+  ||     |            |
// +------------+         ||     +------------+
// +------------+         ||
// |srcB        | -+-+-+  ||
// |            |=>| | |==//
// |            | -+-+-+              
// +------------+                     
// offset_srcA and offset_srcB should be the same
// srcA can be dst
// srcB can be dst
// lastA at the end of srcA
// lastB at the end of srcA
// lastA&lastB=flush through mac_core_adder (at the end of whole move)
                 if (sourceA_go&sourceB_go) begin
                     srcA_go <= 1'b1;
                     srcB_go <= 1'b1;
                     rst_go  <= 1'b1;
                     state   <= ST_GO;
                 end // if
                 // synthesis translate_off
                 if ((sourceA_width!=result_width)||
                     (sourceA_height!=result_height)||
                     (sourceA_items!=result_items))
                     $display("%0t %m \033[0;31mERROR\033[0m mis-match: width, height, items.", $time);
                 if (sourceA_address[AXI_WIDTH_DSB-1:0]!==
                     sourceB_address[AXI_WIDTH_DSB-1:0])
                     $display("%0t %m \033[0;33mWARNING\033[0m mis-match offset of starting address.", $time);
                 if (DATA_WIDTH>8) begin
                     if (sourceA_address[DATA_WIDTH_DSB-1:0]!='h0)
                         $display("%0t %m \033[0;33mWARNING\033[0m mis-aligned source access.", $time);
                     if (sourceB_address[DATA_WIDTH_DSB-1:0]!='h0)
                         $display("%0t %m \033[0;33mWARNING\033[0m mis-aligned source access.", $time);
                     if (result_address[DATA_WIDTH_DSB-1:0]!='h0)
                         $display("%0t %m \033[0;33mWARNING\033[0m mis-aligned destination access.", $time);
                 end
                 // synthesis translate_on
                 end // command_residual
           {1'b1,MOVER_COMMAND_CONCAT0[3:0]}:  begin
// need to move srcB after srcA
// +------------+              +------------+
// |srcA        |     -+-+-+   |dst         |
// |            |=====>| | |==>|            |
// |            |  || -+-+-+   |            |
// +------------+  ||          +............+
// +------------+  ||          |            |
// |srcB        |  ||          |            |
// |            |==//          |            |
// |            |              +------------+
// +------------+   
// srcA can be dst when there are sufficient free space abter srcA
// srcB can be dst when there are sufficient free space abter srcB
// last=flush (at the end of whole move)
                 if (sourceA_go) begin
                     srcA_go <= 1'b1;
                     srcB_go <= 1'b1;
                     rst_go  <= 1'b1;
                     state   <= ST_GO;
                 end // if
                 // synthesis translate_off
                 if ((sourceA_width!=sourceB_width)||
                     (sourceA_width!=result_width)||
                     ((sourceA_height+sourceB_height)!=result_height)||
                     ((sourceA_items+sourceB_items!=result_items)))
                     $display("%0t %m ERROR mis-match: width, height, items.", $time);
                 if (DATA_WIDTH>8) begin
                     if (sourceA_address[DATA_WIDTH_DSB-1:0]!='h0)
                         $display("%0t %m WARNING mis-aligned source access.", $time);
                     if (sourceB_address[DATA_WIDTH_DSB-1:0]!='h0)
                         $display("%0t %m WARNING mis-aligned source access.", $time);
                     if (result_address[DATA_WIDTH_DSB-1:0]!='h0)
                         $display("%0t %m WARNING mis-aligned destination access.", $time);
                 end
                 // synthesis translate_on
                 end // command_concat0
           {1'b1,MOVER_COMMAND_CONCAT1[3:0]}:  begin
// need to move line-by-line (interleaving fashion)
// +------------+              +------------+------------+
// |srcA        |     -+-+-+   |dst         :            |
// |            |=====>| | |==>|            :            |
// |            |  || -+-+-+   |            :            |
// +------------+  ||          +------------+------------+
// +------------+  ||
// |srcB        |  ||
// |            |==//
// |            |
// +------------+   
// srcA cannot be dst
// srcB cannot be dst
// last=flush (at the end of whole move)
                 if (sourceA_go&sourceB_go) begin
                     srcA_go <= 1'b1;
                     srcB_go <= 1'b1;
                     rst_go  <= 1'b1;
                     state   <= ST_GO;
                 end // if 
                 // synthesis translate_off
                 if ((sourceA_height!=sourceB_height)||
                     ((sourceA_width+sourceB_width)!=result_width)||
                     (sourceA_height!=sourceB_height)||
                     (sourceA_height!=result_height)||
                     ((sourceA_items+sourceB_items!=result_items)))
                     $display("%0t %m ERROR mis-match: width, height, items.", $time);
                 if (DATA_WIDTH>8) begin
                     if (sourceA_address[DATA_WIDTH_DSB-1:0]!='h0)
                         $display("%0t %m WARNING mis-aligned source access.", $time);
                     if (sourceB_address[DATA_WIDTH_DSB-1:0]!='h0)
                         $display("%0t %m WARNING mis-aligned source access.", $time);
                     if (result_address[DATA_WIDTH_DSB-1:0]!='h0)
                         $display("%0t %m WARNING mis-aligned destination access.", $time);
                 end
                 // synthesis translate_on
                 end // command_concat1
           {1'b1,MOVER_COMMAND_TRANSPOSE[3:0]}:begin
// need to move line-by-line
// +------------+          +------+
// |srcA        | -+-+-+   |dst   |
// |            |=>| | |==>|      |
// +------------+ -+-+-+   |      |
//                         |      |
//                         +------+
// srcA cannot be dst
// last=end_of_line
                 if (sourceA_go) begin
                     srcA_go <= 1'b1;
                     srcB_go <= 1'b0;
                     rst_go  <= 1'b1;
                     state   <= ST_GO;
                 end // if
                 // synthesis translate_off
                 if ((sourceA_width!=result_height)||
                     (sourceA_height!=result_width)||
                     (sourceA_items!=result_items))
                     $display("%0t %m ERROR mis-match: width, height, items.", $time);
                 if (DATA_WIDTH>8) begin
                     if (sourceA_address[DATA_WIDTH_DSB-1:0]!='h0)
                         $display("%0t %m WARNING mis-aligned source access.", $time);
                     if (result_address[DATA_WIDTH_DSB-1:0]!='h0)
                         $display("%0t %m WARNING mis-aligned destination access.", $time);
                 end
                 if (sourceB_go|sourceB_go)
                     $display("%0t %m WARNING sourceB are not relevant.", $time);
                 // synthesis translate_on
                 end // command_transpose
           {1'b1,MOVER_COMMAND_FILL[3:0]}:begin
// It only uses result module
                 if (result_go) begin
                     srcA_go <= sourceA_go; // make sure doneA driven 1 by mover_2d_control_source
                     srcB_go <= sourceB_go; // make sure doneA driven 1 by mover_2d_control_source
                     rst_go  <= 1'b1;
                     state   <= ST_GO;
                 end
                 // synthesis translate_off
                 if (sourceA_go|sourceB_go)
                     $display("%0t %m WARNING sourceA/sourceB are not relevant.", $time);
                 // synthesis translate_on
                 end // command_fill
           default: begin
                    srcA_go <= 1'b0;
                    srcB_go <= 1'b0;
                    rst_go  <= 1'b0;
                    end
           endcase
           end // ST_READY
        ST_GO: begin
           if (srcA_go&sourceA_done) srcA_go <= 1'b0;
           if (srcB_go&sourceB_done) srcB_go <= 1'b0;
           if (rst_go&result_done  ) rst_go  <= 1'b0;
           if (((!srcA_go&~sourceA_done)|sourceA_done)&&
               ((!srcB_go&~sourceB_done)|sourceB_done)&&
               ((!rst_go&~result_done)|result_done)) begin
               state <= ST_DONE;
           end
           end // ST_GO
        ST_DONE: begin
           if (!(sourceA_go|sourceA_done|
                 sourceB_go|sourceB_done|
                 result_go |result_done )) begin
                   state <= ST_READY;
           end
           end // ST_DONE
        default: begin
                 srcA_go      <= 1'b0;
                 srcB_go      <= 1'b0;
                 rst_go       <= 1'b0;
                 mover_ready  <= 1'b0;
                 state        <= ST_READY;
                 end
        endcase
    end // if
    end // always
    //--------------------------------------------------------------------------
    // synthesis translate_off
    reg  [8*10-1:0] state_ascii="READY";
    always @ (state) begin
    case (state)
    ST_READY: state_ascii="READY  ";
    ST_GO   : state_ascii="GO     ";
    ST_DONE : state_ascii="DONE   ";
    default : state_ascii="UNKNOWN";
    endcase
    end
    // synthesis translate_on
    //--------------------------------------------------------------------------
    wire                     OUT_READY;
    wire                     OUT_VALID;
    wire  [AXI_WIDTH_DA-1:0] OUT_DATA ; // justified
    wire  [AXI_WIDTH_DS-1:0] OUT_STRB ;
    wire                     OUT_LAST ;
    wire                     OUT_FLUSH;
    wire                     OUT_EMPTY;
    wire                     OUT_FULL ;
    //--------------------------------------------------------------------------
    mover_2d_control_source #(.AXI_WIDTH_ID( AXI_WIDTH_ID   )
                             ,.AXI_WIDTH_AD( AXI_WIDTH_AD   )
                             ,.AXI_WIDTH_DA( AXI_WIDTH_DA   )
                             ,.DATA_TYPE   ( DATA_TYPE      )
                             ,.DATA_WIDTH  ( DATA_WIDTH     )
                             ,.FIFO_DEPTH  ( SRC_FIFO_DEPTH )
                             ,.PROFILE_CNT_WIDTH( PROFILE_CNT_WIDTH )
                             ,.MOVER_COMMAND_NOP      (MOVER_COMMAND_NOP       )
                             ,.MOVER_COMMAND_FILL     (MOVER_COMMAND_FILL      )
                             ,.MOVER_COMMAND_COPY     (MOVER_COMMAND_COPY      )
                             ,.MOVER_COMMAND_RESIDUAL (MOVER_COMMAND_RESIDUAL  )
                             ,.MOVER_COMMAND_CONCAT0  (MOVER_COMMAND_CONCAT0   )
                             ,.MOVER_COMMAND_CONCAT1  (MOVER_COMMAND_CONCAT1   )
                             ,.MOVER_COMMAND_TRANSPOSE(MOVER_COMMAND_TRANSPOSE )
                             )
    u_source (
          .ARESETn      ( ARESETn           )
        , .ACLK         ( ACLK              )
        , .AXI_ARID     ( M_AXI_SRC_ARID    )
        , .AXI_ARADDR   ( M_AXI_SRC_ARADDR  )
        , .AXI_ARLEN    ( M_AXI_SRC_ARLEN   )
        , .AXI_ARSIZE   ( M_AXI_SRC_ARSIZE  )
        , .AXI_ARBURST  ( M_AXI_SRC_ARBURST )
        , .AXI_ARVALID  ( M_AXI_SRC_ARVALID )
        , .AXI_ARREADY  ( M_AXI_SRC_ARREADY )
        , .AXI_RID      ( M_AXI_SRC_RID     )
        , .AXI_RDATA    ( M_AXI_SRC_RDATA   )
        , .AXI_RRESP    ( M_AXI_SRC_RRESP   )
        , .AXI_RLAST    ( M_AXI_SRC_RLAST   )
        , .AXI_RVALID   ( M_AXI_SRC_RVALID  )
        , .AXI_RREADY   ( M_AXI_SRC_RREADY  )
        , .OUT_READY    ( OUT_READY         )
        , .OUT_VALID    ( OUT_VALID         )
        , .OUT_DATA     ( OUT_DATA          )
        , .OUT_STRB     ( OUT_STRB          )
        , .OUT_LAST     ( OUT_LAST          )
        , .OUT_FLUSH    ( OUT_FLUSH         )
        , .OUT_EMPTY    ( OUT_EMPTY         )
        , .OUT_FULL     ( OUT_FULL          )
        , .command      ( command           )
        , .srcA_go      ( srcA_go           )
        , .srcA_done    ( sourceA_done      )
        , .srcA_address ( sourceA_address   )
        , .srcA_width   ( sourceA_width     )
        , .srcA_height  ( sourceA_height    )
        , .srcA_items   ( sourceA_items     )
        , .srcA_leng    ( sourceA_leng      )
        , .srcB_go      ( srcB_go           )
        , .srcB_done    ( sourceB_done      )
        , .srcB_address ( sourceB_address   )
        , .srcB_width   ( sourceB_width     )
        , .srcB_height  ( sourceB_height    )
        , .srcB_items   ( sourceB_items     )
        , .srcB_leng    ( sourceB_leng      )
        , .init         ( mover_init        )
        , .ready        ( source_ready      )
        , .profile_init             ( profile_init              )
        , .profile_residual_overflow( profile_residual_overflow )
    );
    //--------------------------------------------------------------------------
    mover_2d_control_result #(.AXI_WIDTH_ID( AXI_WIDTH_ID      )
                             ,.AXI_WIDTH_AD( AXI_WIDTH_AD      )
                             ,.AXI_WIDTH_DA( AXI_WIDTH_DA      )
                             ,.DATA_TYPE   ( DATA_TYPE         )
                             ,.DATA_WIDTH  ( DATA_WIDTH        )
                             ,.FIFO_DEPTH  ( RESULT_FIFO_DEPTH )
                             ,.MOVER_COMMAND_NOP      (MOVER_COMMAND_NOP       )
                             ,.MOVER_COMMAND_FILL     (MOVER_COMMAND_FILL      )
                             ,.MOVER_COMMAND_COPY     (MOVER_COMMAND_COPY      )
                             ,.MOVER_COMMAND_RESIDUAL (MOVER_COMMAND_RESIDUAL  )
                             ,.MOVER_COMMAND_CONCAT0  (MOVER_COMMAND_CONCAT0   )
                             ,.MOVER_COMMAND_CONCAT1  (MOVER_COMMAND_CONCAT1   )
                             ,.MOVER_COMMAND_TRANSPOSE(MOVER_COMMAND_TRANSPOSE )
                             ,.ACTIV_FUNC_BYPASS    ( ACTIV_FUNC_BYPASS     )
                             ,.ACTIV_FUNC_RELU      ( ACTIV_FUNC_RELU       )
                             ,.ACTIV_FUNC_LEAKY_RELU( ACTIV_FUNC_LEAKY_RELU )
                             ,.ACTIV_FUNC_SIGMOID   ( ACTIV_FUNC_SIGMOID    )
                             ,.ACTIV_FUNC_TANH      ( ACTIV_FUNC_TANH       )
                             )
    u_result (
          .ARESETn          ( ARESETn           )
        , .ACLK             ( ACLK              )
        , .AXI_AWID         ( M_AXI_RST_AWID    )
        , .AXI_AWADDR       ( M_AXI_RST_AWADDR  )
        , .AXI_AWLEN        ( M_AXI_RST_AWLEN   )
        , .AXI_AWSIZE       ( M_AXI_RST_AWSIZE  )
        , .AXI_AWBURST      ( M_AXI_RST_AWBURST )
        , .AXI_AWVALID      ( M_AXI_RST_AWVALID )
        , .AXI_AWREADY      ( M_AXI_RST_AWREADY )
        , .AXI_WDATA        ( M_AXI_RST_WDATA   )
        , .AXI_WSTRB        ( M_AXI_RST_WSTRB   )
        , .AXI_WLAST        ( M_AXI_RST_WLAST   )
        , .AXI_WVALID       ( M_AXI_RST_WVALID  )
        , .AXI_WREADY       ( M_AXI_RST_WREADY  )
        , .AXI_BID          ( M_AXI_RST_BID     )
        , .AXI_BRESP        ( M_AXI_RST_BRESP   )
        , .AXI_BVALID       ( M_AXI_RST_BVALID  )
        , .AXI_BREADY       ( M_AXI_RST_BREADY  )
        , .IN_READY         ( OUT_READY         )
        , .IN_VALID         ( OUT_VALID         )
        , .IN_DATA          ( OUT_DATA          )
        , .IN_STRB          ( OUT_STRB          )
        , .IN_LAST          ( OUT_LAST          )
        , .IN_FLUSH         ( OUT_FLUSH         )
        , .command          ( command           )
        , .result_go        ( rst_go            )
        , .result_done      ( result_done       )
        , .result_address   ( result_address    )
        , .result_width     ( result_width      )
        , .result_height    ( result_height     )
        , .result_items     ( result_items      )
        , .result_leng      ( result_leng       )
        , .fill_value       ( fill_value        )
        , .activ_func       ( activ_func        )
        , .activ_param      ( activ_param       )
        , .init             ( mover_init        )
        , .ready            ( result_ready      )
    );
    //--------------------------------------------------------------------------
    wire num_read =(M_AXI_SRC_RVALID&M_AXI_SRC_RREADY);
    wire num_write=(M_AXI_RST_WVALID&M_AXI_RST_WREADY);
    //--------------------------------------------------------------------------
    always @ ( posedge ACLK or negedge ARESETn) begin
    if (ARESETn==1'b0) begin
        profile_cnt_read  <= 'h0;
        profile_cnt_write <= 'h0;
    end else if (profile_init==1'b1) begin
        profile_cnt_read  <= 'h0;
        profile_cnt_write <= 'h0;
    end else begin
        if (num_read ) profile_cnt_read  <= profile_cnt_read  + 1;
        if (num_write) profile_cnt_write <= profile_cnt_write + 1;
    end // if
    end // always
    //--------------------------------------------------------------------------
endmodule

//------------------------------------------------------------------------------
// It fills fifo after justifing data and strobe
// It makes all zeros for non-valid bytes in order to be possible OR-ing data bytes.
module mover_2d_control_source
     #(parameter AXI_WIDTH_ID =4       // ID width in bits
               , AXI_WIDTH_AD =32      // address width
               , AXI_WIDTH_DA =32      // data width
               , AXI_WIDTH_DS =AXI_WIDTH_DA/8
               , AXI_WIDTH_DSB=$clog2(AXI_WIDTH_DS)
               , DATA_TYPE    ="INTEGER" // "INTEGER", "FLOATING_POINT", "FIXED_POINT"
               , DATA_WIDTH   =32
               , DATA_BYTES   =(DATA_WIDTH/8)// num of bytes per feature item (1 for byte)
               , FIFO_DEPTH   =32
               , PROFILE_CNT_WIDTH =32,
       parameter [3:0] MOVER_COMMAND_NOP      = 'h0,
       parameter [3:0] MOVER_COMMAND_FILL     = 'h1,
       parameter [3:0] MOVER_COMMAND_COPY     = 'h2,
       parameter [3:0] MOVER_COMMAND_RESIDUAL = 'h3,// point-to-point adder
       parameter [3:0] MOVER_COMMAND_CONCAT0  = 'h4,
       parameter [3:0] MOVER_COMMAND_CONCAT1  = 'h5,
       parameter [3:0] MOVER_COMMAND_TRANSPOSE= 'h6
               )
(
      input   wire                       ARESETn
    , input   wire                       ACLK
    // master port for kernel (read-only)
    ,            output  reg   [AXI_WIDTH_ID-1:0]   AXI_ARID
    , `DBG_MOVER output  reg   [AXI_WIDTH_AD-1:0]   AXI_ARADDR
    , `DBG_MOVER output  reg   [ 7:0]               AXI_ARLEN
    , `DBG_MOVER output  reg   [ 2:0]               AXI_ARSIZE
    ,            output  reg   [ 1:0]               AXI_ARBURST
    , `DBG_MOVER output  reg                        AXI_ARVALID
    , `DBG_MOVER input   wire                       AXI_ARREADY
    ,            input   wire  [AXI_WIDTH_ID-1:0]   AXI_RID
    , `DBG_MOVER input   wire  [AXI_WIDTH_DA-1:0]   AXI_RDATA
    ,            input   wire  [ 1:0]               AXI_RRESP
    , `DBG_MOVER input   wire                       AXI_RLAST
    , `DBG_MOVER input   wire                       AXI_RVALID
    , `DBG_MOVER output  wire                       AXI_RREADY
    //
    , input   wire                       OUT_READY
    , output  reg                        OUT_VALID
    , output  reg   [AXI_WIDTH_DA-1:0]   OUT_DATA // justified
    , output  reg   [AXI_WIDTH_DS-1:0]   OUT_STRB // justified
    , output  reg                        OUT_LAST
    , output  reg                        OUT_FLUSH
    , output  reg                        OUT_EMPTY
    , output  reg                        OUT_FULL
    //
    , `DBG_MOVER input   wire  [ 3:0]               command
    , `DBG_MOVER input   wire                       srcA_go
    , `DBG_MOVER output  reg                        srcA_done// read-done
    , `DBG_MOVER input   wire  [AXI_WIDTH_AD-1:0]   srcA_address
    , `DBG_MOVER input   wire  [15:0]               srcA_width// num of items in row
    , `DBG_MOVER input   wire  [15:0]               srcA_height// num of items in column
    , `DBG_MOVER input   wire  [31:0]               srcA_items // not including padding
    , `DBG_MOVER input   wire  [ 7:0]               srcA_leng // AxLENG format (not used here)
    , `DBG_MOVER input   wire                       srcB_go
    , `DBG_MOVER output  reg                        srcB_done// read-done
    , `DBG_MOVER input   wire  [AXI_WIDTH_AD-1:0]   srcB_address
    , `DBG_MOVER input   wire  [15:0]               srcB_width// num of items in row
    , `DBG_MOVER input   wire  [15:0]               srcB_height// num of items in column
    , `DBG_MOVER input   wire  [31:0]               srcB_items // not including padding
    , `DBG_MOVER input   wire  [ 7:0]               srcB_leng // AxLENG format (not used here)
    //
    , input   wire                       init
    , output  wire                       ready
    //
    , input  wire                           profile_init
    , output reg   [PROFILE_CNT_WIDTH-1:0]  profile_residual_overflow
);
    //--------------------------------------------------------------------------
    `ifdef SIM
        `ifdef __ICARUS__
            `define  RES_DLY
        `else
            `define  RES_DLY #1
        `endif
    `else
        `define  RES_DLY
    `endif
    //--------------------------------------------------------------------------
    localparam FIFO_AW=$clog2(FIFO_DEPTH);
    //--------------------------------------------------------------------------
    // COMMAND_FILL, COMMAND_COPY, COMMAND_CONCATE0, COMMAND_CONCAT1, COMMAND_TRANSPOSE
    wire                    `RES_DLY  pushA_wr_ready;
    wire                    `RES_DLY  pushA_wr_valid;
    wire [AXI_WIDTH_DA-1:0] `RES_DLY  pushA_wr_data ; // justified
    wire [AXI_WIDTH_DS-1:0] `RES_DLY  pushA_wr_strb ; // justified
    wire                    `RES_DLY  pushA_wr_last ;
    wire                    `RES_DLY  fifoA_empty   ;
    wire [FIFO_AW:0]        `RES_DLY  fifoA_items   ;
    //--------------------------------------------------------------------------
    // only COMMAND_RESIDUAL uses fifoB
    wire                    `RES_DLY  pushB_wr_ready;
    wire                    `RES_DLY  pushB_wr_valid;
    wire [AXI_WIDTH_DA-1:0] `RES_DLY  pushB_wr_data ; // justified
    wire [AXI_WIDTH_DS-1:0] `RES_DLY  pushB_wr_strb ; // justified
    wire                    `RES_DLY  pushB_wr_last ;
    wire                    `RES_DLY  fifoB_empty   ;
    wire [FIFO_AW:0]        `RES_DLY  fifoB_items   ;
    //--------------------------------------------------------------------------
    `DBG_MOVER reg  [AXI_WIDTH_AD-1:0]  regA_add             ='h0; // keep track of the address for srcA
    `DBG_MOVER wire [AXI_WIDTH_DSB-1:0] regA_offset          =regA_add[AXI_WIDTH_DSB-1:0];
    `DBG_MOVER reg  [31:0]              cntA_all_moved_bytes ='h0;
    `DBG_MOVER reg  [15:0]              cntA_line_moved_bytes='h0;
    `DBG_MOVER reg  [ 7:0]              cntA_beat            ='h0; // keet track of a burst
    `DBG_MOVER wire [31:0]              numA_all_bytes       = srcA_items*DATA_BYTES;
    `DBG_MOVER wire signed [31:0]       remA_all_bytes       = numA_all_bytes-cntA_all_moved_bytes;
    `DBG_MOVER wire [31:0]              numA_line_bytes      = srcA_width*DATA_BYTES;
    `DBG_MOVER wire signed [31:0]       remA_line_bytes      = srcA_width*DATA_BYTES-cntA_line_moved_bytes;
    `DBG_MOVER reg  [AXI_WIDTH_AD-1:0]  regB_add             ='h0;
    `DBG_MOVER wire [AXI_WIDTH_DSB-1:0] regB_offset          =regB_add[AXI_WIDTH_DSB-1:0];
    `DBG_MOVER reg  [31:0]              cntB_all_moved_bytes ='h0;
    `DBG_MOVER reg  [15:0]              cntB_line_moved_bytes='h0;
    `DBG_MOVER reg  [ 7:0]              cntB_beat            ='h0;
    `DBG_MOVER wire [31:0]              numB_all_bytes       = srcB_items*DATA_BYTES;
    `DBG_MOVER wire signed [31:0]       remB_all_bytes       = numB_all_bytes-cntB_all_moved_bytes;
    `DBG_MOVER wire [31:0]              numB_line_bytes      = srcB_width*DATA_BYTES;
    `DBG_MOVER wire signed [31:0]       remB_line_bytes      = srcB_width*DATA_BYTES-cntB_line_moved_bytes;
    `DBG_MOVER wire [ 7:0]              num_bytes            = 1<<AXI_ARSIZE;
    //--------------------------------------------------------------------------
    localparam ST_READY               ='h00
             , ST_MOV_CON0_SRCA_CAL   ='h01 // COMMAND_MOV and COMMAND_CONCAT0
             , ST_MOV_CON0_SRCA_ADDR  ='h02 // COMMAND_MOV and COMMAND_CONCAT0
             , ST_MOV_CON0_SRCA_DATA  ='h03 // COMMAND_MOV and COMMAND_CONCAT0
             , ST_CON0_SRCB_CAL       ='h04 // COMMAND_CONCAT0
             , ST_CON0_SRCB_ADDR      ='h05 // COMMAND_CONCAT0
             , ST_CON0_SRCB_DATA      ='h06 // COMMAND_CONCAT0
             , ST_RES_SRCA_CAL        ='h07 // COMMAND_RESIDUAL
             , ST_RES_SRCA_ADDR       ='h08 // COMMAND_RESIDUAL
             , ST_RES_SRCA_DATA       ='h09 // COMMAND_RESIDUAL
             , ST_RES_SRCB_CAL        ='h0A // COMMAND_RESIDUAL
             , ST_RES_SRCB_ADDR       ='h0B // COMMAND_RESIDUAL
             , ST_RES_SRCB_DATA       ='h0C // COMMAND_RESIDUAL
             , ST_CON1_TRANS_SRCA_CAL ='h0D // COMMAND_TRANSPOSE,COMMAND_CONCAT1
             , ST_CON1_TRANS_SRCA_ADDR='h0E // COMMAND_TRANSPOSE,COMMAND_CONCAT1
             , ST_CON1_TRANS_SRCA_DATA='h0F // COMMAND_TRANSPOSE,COMMAND_CONCAT1
             , ST_CON1_SRCB_CAL       ='h10 // COMMAND_CONCAT1
             , ST_CON1_SRCB_ADDR      ='h11 // COMMAND_CONCAT1
             , ST_CON1_SRCB_DATA      ='h12 // COMMAND_CONCAT1
             , ST_DONE                ='h1F;
    `DBG_MOVER reg [4:0] state=ST_READY;
    //--------------------------------------------------------------------------
    always @ (posedge ACLK or negedge ARESETn) begin
    if (ARESETn==1'b0) begin
        AXI_ARID              <=  'h0;
        AXI_ARADDR            <=  'h0;
        AXI_ARLEN             <= 8'h0;
        AXI_ARSIZE            <= 3'b0;
        AXI_ARBURST           <= 2'b01;
        AXI_ARVALID           <= 1'b0;
        srcA_done             <= 1'b0;
        regA_add              <=  'h0;
        cntA_all_moved_bytes  <=  'h0;
        cntA_line_moved_bytes <=  'h0;
        cntA_beat             <=  'h0;
        srcB_done             <= 1'b0;
        regB_add              <=  'h0;
        cntB_all_moved_bytes  <=  'h0;
        cntB_line_moved_bytes <=  'h0;
        cntB_beat             <=  'h0;
        OUT_FLUSH             <= 1'b0;
        state                 <= ST_READY;
    end else begin
    case (state)
    ST_READY: begin
       regA_add              <= srcA_address;
       cntA_all_moved_bytes  <= 'h0;
       cntA_line_moved_bytes <= 'h0;
       regB_add              <= srcB_address;
       cntB_all_moved_bytes  <= 'h0;
       cntB_line_moved_bytes <= 'h0;
       if ((command==MOVER_COMMAND_COPY[3:0])&&(srcA_go==1'b1)&&(srcA_done==1'b0)) begin
           // move srcA only for COPY
           srcB_done <= 1'b1; // since it does not use srcB
           state     <= ST_MOV_CON0_SRCA_CAL;
       end else if ((command==MOVER_COMMAND_CONCAT0[3:0])&&(srcA_go==1'b1)&&(srcA_done==1'b0)) begin
           // move srcA and then move srcB for CONCAT0
           state     <= ST_MOV_CON0_SRCA_CAL;
       end else if ((command==MOVER_COMMAND_RESIDUAL[3:0])&&(srcA_go==1'b1)&&(srcA_done==1'b0)) begin
           // move srcA and srcB
           state     <= ST_RES_SRCA_CAL;
       end else if ((command==MOVER_COMMAND_CONCAT1[3:0])&&(srcA_go==1'b1)&&(srcA_done==1'b0)) begin
           // move srcA and srcB line-by-line
           state     <= ST_CON1_TRANS_SRCA_CAL;
       end else if ((command==MOVER_COMMAND_TRANSPOSE[3:0])&&(srcA_go==1'b1)&&(srcA_done==1'b0)) begin
           // move srcA line-by-line
           srcB_done <= 1'b1; // since it does not use srcB
           state     <= ST_DONE; // since it is not implemented yet.
         //state     <= ST_CON1_TRANS_SRCA_CAL;
           // synthesis translate_off
           $display("%0t %m ERROR TRANSPOSE not supported yet.", $time);
           // synthesis translate_on
       end else if (command==MOVER_COMMAND_FILL[3:0]) begin
           srcA_done <= srcA_go; // since it does not use srcA
           srcB_done <= srcB_go; // since it does not use srcB
           state     <= ST_READY;
       end else begin
           state     <= ST_READY;
           // synthesis translate_off
           if ((srcA_go==1'b1)||(srcB_go==1'b1)) begin
               $display("%0t %m ERROR un-defined command: 0x%0X", $time, command);
           end
           // synthesis translate_on
       end // if (((command
       end // ST_READY
    // for COMMAND_COPY or COMMAND_CONCAT0
    ST_MOV_CON0_SRCA_CAL: begin
       AXI_ARID    <= AXI_ARID + 1;
       AXI_ARADDR  <= regA_add;
       if (regA_offset=='h0) begin
           // aligned access
           if (remA_all_bytes<AXI_WIDTH_DS) begin
               AXI_ARLEN   <= 'h0;
               AXI_ARSIZE  <= func_get_arsize(remA_all_bytes[AXI_WIDTH_DSB:0]);
           end else if (remA_all_bytes<((srcA_leng+1)*AXI_WIDTH_DS)) begin
               AXI_ARLEN   <= remA_all_bytes/AXI_WIDTH_DS-1;
               AXI_ARSIZE  <= func_get_arsize(AXI_WIDTH_DS);
           end else begin
               AXI_ARLEN   <= srcA_leng;
               AXI_ARSIZE  <= func_get_arsize(AXI_WIDTH_DS);
           end
       end else begin
           // mis-aligned access
           if ((AXI_WIDTH_DS-regA_offset)<=remA_all_bytes) begin
               AXI_ARLEN   <= 'h0;
               AXI_ARSIZE  <= func_get_arsize_misaligned(AXI_WIDTH_DS-regA_offset, regA_offset);
           end else begin
               AXI_ARLEN   <= 'h0;
               AXI_ARSIZE  <= func_get_arsize_misaligned(remA_all_bytes[AXI_WIDTH_DSB:0], regA_offset);
           end
       end
       AXI_ARVALID      <= 1'b1;
       state            <= ST_MOV_CON0_SRCA_ADDR;
       // synthesis translate_off
       if (remA_all_bytes<=0) $display("%t %m ERROR addres error.", $time);
       // synthesis translate_on
       end // ST_SRCA_ADDR_DRIVE
    ST_MOV_CON0_SRCA_ADDR: begin
       if ((AXI_ARVALID==1'b1)&&(AXI_ARREADY==1'b1)) begin
           AXI_ARVALID <= 1'b0;
           cntA_beat   <=  'h0;
           state       <= ST_MOV_CON0_SRCA_DATA;
           // synthesis translate_off
           if (AXI_ARLEN>=FIFO_DEPTH) $display("%0t %m ERROR burst length exceeds the depth of FIFO.", $time);
           // synthesis translate_on
       end
       end // ST_SRCA_ADDR
    ST_MOV_CON0_SRCA_DATA: begin
       if ((AXI_RVALID==1'b1)&&(AXI_RREADY==1'b1)) begin
            cntA_beat            <= cntA_beat + 1;
            cntA_all_moved_bytes <= cntA_all_moved_bytes + num_bytes;
            regA_add             <= regA_add + num_bytes;
            if (AXI_RLAST==1'b1) begin
                if ((cntA_all_moved_bytes+num_bytes)<numA_all_bytes) begin
                    state  <= ST_MOV_CON0_SRCA_CAL;
                end else begin // ((cntA_all_moved_bytes+num_bytes)<numA_all_bytes)
                    srcA_done <= 1'b1;
                    if ((command==MOVER_COMMAND_CONCAT0[3:0])&&
                        (srcB_go==1'b1)&&(srcB_done==1'b0)) begin
                        state <= ST_CON0_SRCB_CAL;
                    end else begin
                        OUT_FLUSH <= 1'b1;
                        state     <= ST_DONE;
                    end
                end
                // synthesis translate_off
                if (cntA_beat!=AXI_ARLEN)
                    $display("%0t %m ERROR burst length error.", $time);
                // synthesis translate_on
            end
            // synthesis translate_off
            if ((cntA_all_moved_bytes+num_bytes)>numA_all_bytes)
                $display("%t %m WARNING source A addres exceeds.", $time);
            // synthesis translate_on
       end // if ((AXI_RVALID
       end // ST_SRCA_DATA
    // for COMMAND_CONCAT0 srcB
    ST_CON0_SRCB_CAL: begin
       if (fifoA_empty==1'b1) begin
           OUT_FLUSH  <= 1'b0;
           AXI_ARID   <= AXI_ARID + 1;
           AXI_ARADDR <= regB_add;
           if (regB_offset=='h0) begin
               // aligned access
               if (remB_all_bytes<AXI_WIDTH_DS) begin
                   AXI_ARLEN   <= 'h0;
                   AXI_ARSIZE  <= func_get_arsize(remB_all_bytes[AXI_WIDTH_DSB:0]);
               end else if (remB_all_bytes<((srcB_leng+1)*AXI_WIDTH_DS)) begin
                   AXI_ARLEN   <= remB_all_bytes/AXI_WIDTH_DS-1;
                   AXI_ARSIZE  <= func_get_arsize(AXI_WIDTH_DS);
               end else begin
                   AXI_ARLEN   <= srcB_leng;
                   AXI_ARSIZE  <= func_get_arsize(AXI_WIDTH_DS);
               end
           end else begin
               // mis-aligned access
               if ((AXI_WIDTH_DS-regB_offset)<=remB_all_bytes) begin
                   AXI_ARLEN   <= 'h0;
                   AXI_ARSIZE  <= func_get_arsize_misaligned(AXI_WIDTH_DS-regB_offset, regB_offset);
               end else begin
                   AXI_ARLEN   <= 'h0;
                   AXI_ARSIZE  <= func_get_arsize_misaligned(remB_all_bytes[AXI_WIDTH_DSB:0], regB_offset);
               end
           end
           AXI_ARVALID          <= 1'b1;
           state                <= ST_CON0_SRCB_ADDR;
           // synthesis translate_off
           if (remB_all_bytes<=0) $display("%t %m ERROR addres error.", $time);
           // synthesis translate_on
       end
       end // ST_SRCB_CAL
    ST_CON0_SRCB_ADDR: begin
       if ((AXI_ARVALID==1'b1)&&(AXI_ARREADY==1'b1)) begin
           AXI_ARVALID <= 1'b0;
           cntB_beat   <=  'h0;
           state       <= ST_CON0_SRCB_DATA;
           // synthesis translate_off
           if (AXI_ARLEN>=FIFO_DEPTH) $display("%0t %m WARNING burst length exceeds the depth of FIFO.", $time);
           // synthesis translate_on
       end
       end // ST_SRCB_ADDR
    ST_CON0_SRCB_DATA: begin
       if ((AXI_RVALID==1'b1)&&(AXI_RREADY==1'b1)) begin
            cntB_beat            <= cntB_beat + 1;
            cntB_all_moved_bytes <= cntB_all_moved_bytes + num_bytes;
            regB_add             <= regB_add + num_bytes;
            if (AXI_RLAST==1'b1) begin
                if ((cntB_all_moved_bytes+num_bytes)<numB_all_bytes) begin
                    state  <= ST_CON0_SRCB_CAL;
                end else begin
                    srcB_done <= 1'b1;
                    OUT_FLUSH <= 1'b1;
                    state     <= ST_DONE;
                end
                // synthesis translate_off
                if (cntB_beat!=AXI_ARLEN)
                    $display("%0t %m ERROR burst length error.", $time);
                // synthesis translate_on
            end
            // synthesis translate_off
            if ((cntB_all_moved_bytes+num_bytes)>numB_all_bytes)
                $display("%t %m ERROR source B addres exceeds.", $time);
            // synthesis translate_on
       end
       end // ST_SRCB_DATA
    // for COMMAND_RESIDUAL
    ST_RES_SRCA_CAL: begin
       AXI_ARID    <= AXI_ARID + 1;
       AXI_ARADDR  <= regA_add;
       if (regA_offset=='h0) begin
           // aligned access
           if (remA_all_bytes<AXI_WIDTH_DS) begin
               AXI_ARLEN   <= 'h0;
               AXI_ARSIZE  <= func_get_arsize(remA_all_bytes[AXI_WIDTH_DSB:0]);
           end else if (remA_all_bytes<((srcA_leng+1)*AXI_WIDTH_DS)) begin
               AXI_ARLEN   <= remA_all_bytes/AXI_WIDTH_DS-1;
               AXI_ARSIZE  <= func_get_arsize(AXI_WIDTH_DS);
           end else begin
               AXI_ARLEN   <= srcA_leng;
               AXI_ARSIZE  <= func_get_arsize(AXI_WIDTH_DS);
           end
       end else begin
           // mis-aligned access
           if ((AXI_WIDTH_DS-regA_offset)<=remA_all_bytes) begin
               AXI_ARLEN   <= 'h0;
               AXI_ARSIZE  <= func_get_arsize_misaligned(AXI_WIDTH_DS-regA_offset, regA_offset);
           end else begin
               AXI_ARLEN   <= 'h0;
               AXI_ARSIZE  <= func_get_arsize_misaligned(remA_all_bytes[AXI_WIDTH_DSB:0], regA_offset);
           end
       end
       AXI_ARVALID      <= 1'b1;
       state            <= ST_RES_SRCA_ADDR;
       // synthesis translate_off
       if (remA_all_bytes<=0) $display("%t %m ERROR addres error.", $time);
       // synthesis translate_on
       end // ST_SRCA_ADDR_DRIVE
    ST_RES_SRCA_ADDR: begin
       if ((AXI_ARVALID==1'b1)&&(AXI_ARREADY==1'b1)) begin
           AXI_ARVALID <= 1'b0;
           cntA_beat   <=  'h0;
           state       <= ST_RES_SRCA_DATA;
           // synthesis translate_off
           if (AXI_ARLEN>=FIFO_DEPTH) $display("%0t %m ERROR burst length exceeds the depth of FIFO.", $time);
           // synthesis translate_on
       end
       end // ST_RES_SRCA_ADDR
    ST_RES_SRCA_DATA: begin
       if ((AXI_RVALID==1'b1)&&(AXI_RREADY==1'b1)) begin
            cntA_beat            <= cntA_beat + 1;
            cntA_all_moved_bytes <= cntA_all_moved_bytes + num_bytes;
            regA_add             <= regA_add + num_bytes;
            if (AXI_RLAST==1'b1) begin
                if ((cntA_all_moved_bytes+num_bytes)==numA_all_bytes) begin
                    srcA_done <= 1'b1;
                end
                // fifoA and fifoB: interleaving
                if ((srcB_go==1'b1)&&(srcB_done==1'b0)) begin
                    // make sure fifo depth should be sufficient in order not to get full.
                    state <= ST_RES_SRCB_CAL;
                end else begin
                    if ((cntA_all_moved_bytes+num_bytes)<numA_all_bytes) begin
                        state  <= ST_RES_SRCA_CAL;
                    end else begin
                        OUT_FLUSH <= 1'b1;
                        state     <= ST_DONE;
                    end
                end // if (srcB_go
                // synthesis translate_off
                if (cntA_beat!=AXI_ARLEN)
                    $display("%0t %m ERROR burst length error.", $time);
                // synthesis translate_on
            end
            // synthesis translate_off
            if ((cntA_all_moved_bytes+num_bytes)>numA_all_bytes)
                $display("%t %m WARNING source A addres exceeds.", $time);
            // synthesis translate_on
       end
       end // ST_RES_SRCA_DATA
    ST_RES_SRCB_CAL: begin
       AXI_ARID    <= AXI_ARID + 1;
       AXI_ARADDR  <= regB_add;
       if (regB_offset=='h0) begin
           // aligned access
           if (remB_all_bytes<AXI_WIDTH_DS) begin
               AXI_ARLEN   <= 'h0;
               AXI_ARSIZE  <= func_get_arsize(remB_all_bytes[AXI_WIDTH_DSB:0]);
           end else if (remB_all_bytes<((srcB_leng+1)*AXI_WIDTH_DS)) begin
               AXI_ARLEN   <= remB_all_bytes/AXI_WIDTH_DS-1;
               AXI_ARSIZE  <= func_get_arsize(AXI_WIDTH_DS);
           end else begin
               AXI_ARLEN   <= srcB_leng;
               AXI_ARSIZE  <= func_get_arsize(AXI_WIDTH_DS);
           end
       end else begin
           // mis-aligned access
           if ((AXI_WIDTH_DS-regB_offset)<=remB_all_bytes) begin
               AXI_ARLEN   <= 'h0;
               AXI_ARSIZE  <= func_get_arsize_misaligned(AXI_WIDTH_DS-regB_offset, regB_offset);
           end else begin
               AXI_ARLEN   <= 'h0;
               AXI_ARSIZE  <= func_get_arsize_misaligned(remB_all_bytes[AXI_WIDTH_DSB:0], regB_offset);
           end
       end
       AXI_ARVALID      <= 1'b1;
       state            <= ST_RES_SRCB_ADDR;
       // synthesis translate_off
       if (remB_all_bytes<=0) $display("%t %m ERROR addres error.", $time);
       // synthesis translate_on
       end // ST_RES_SRCB_CAL
    ST_RES_SRCB_ADDR: begin
       if ((AXI_ARVALID==1'b1)&&(AXI_ARREADY==1'b1)) begin
           AXI_ARVALID <= 1'b0;
           cntB_beat   <=  'h0;
           state       <= ST_RES_SRCB_DATA;
           // synthesis translate_off
           if (AXI_ARLEN>=FIFO_DEPTH) $display("%0t %m WARNING burst length exceeds the depth of FIFO.", $time);
           // synthesis translate_on
       end
       end // ST_RES_SRCB_ADDR
    ST_RES_SRCB_DATA: begin
       if ((AXI_RVALID==1'b1)&&(AXI_RREADY==1'b1)) begin
            cntB_beat            <= cntB_beat + 1;
            cntB_all_moved_bytes <= cntB_all_moved_bytes + num_bytes;
            regB_add             <= regB_add + num_bytes;
            if (AXI_RLAST==1'b1) begin
                if ((cntB_all_moved_bytes+num_bytes)==numB_all_bytes) begin
                    srcB_done <= 1'b1;
                end
                // fifoA and fifoB interleaving
                if ((srcA_go==1'b1)&&(srcA_done==1'b0)) begin
                    // make sure fifo depth should be sufficient in order not to get full.
                   state  <= ST_RES_SRCA_CAL;
                end else begin
                    if ((cntB_all_moved_bytes+num_bytes)<numB_all_bytes) begin
                        state  <= ST_RES_SRCB_CAL;
                    end else begin
                        OUT_FLUSH <= 1'b1;
                        state     <= ST_DONE;
                    end
                end // if (srcB_go
                // synthesis translate_off
                if (cntB_beat!=AXI_ARLEN)
                    $display("%0t %m ERROR burst length error.", $time);
                // synthesis translate_on
            end
            // synthesis translate_off
            if ((cntB_all_moved_bytes+num_bytes)>numB_all_bytes)
                $display("%t %m ERROR source B addres exceeds.", $time);
            // synthesis translate_on
       end
       end // ST_RES_SRCB_DATA
    // for COMMAND_CONCAT1
    ST_CON1_TRANS_SRCA_CAL: begin
       AXI_ARID    <= AXI_ARID + 1;
       AXI_ARADDR  <= regA_add;
       if (regA_offset=='h0) begin
           // aligned access
           if (remA_line_bytes<AXI_WIDTH_DS) begin
               AXI_ARLEN   <= 'h0;
               AXI_ARSIZE  <= func_get_arsize(remA_line_bytes[AXI_WIDTH_DSB:0]);
           end else if (remA_line_bytes<((srcA_leng+1)*AXI_WIDTH_DS)) begin
               AXI_ARLEN   <= remA_line_bytes/AXI_WIDTH_DS-1;
               AXI_ARSIZE  <= func_get_arsize(AXI_WIDTH_DS);
           end else begin
               AXI_ARLEN   <= srcA_leng;
               AXI_ARSIZE  <= func_get_arsize(AXI_WIDTH_DS);
           end
       end else begin
           // mis-aligned access
           if ((AXI_WIDTH_DS-regA_offset)<=remA_line_bytes) begin
               AXI_ARLEN   <= 'h0;
               AXI_ARSIZE  <= func_get_arsize_misaligned(AXI_WIDTH_DS-regA_offset, regA_offset);
           end else begin
               AXI_ARLEN   <= 'h0;
               AXI_ARSIZE  <= func_get_arsize_misaligned(remA_line_bytes[AXI_WIDTH_DSB:0], regA_offset);
           end
       end
       AXI_ARVALID      <= 1'b1;
       state            <= ST_CON1_TRANS_SRCA_ADDR;
       // synthesis translate_off
       if (remA_line_bytes<=0) $display("%t %m ERROR addres error.", $time);
       // synthesis translate_on
       end // ST_CON1_SRCA_CAL
    ST_CON1_TRANS_SRCA_ADDR: begin
       if ((AXI_ARVALID==1'b1)&&(AXI_ARREADY==1'b1)) begin
           AXI_ARVALID <= 1'b0;
           cntA_beat   <=  'h0;
           state       <= ST_CON1_TRANS_SRCA_DATA;
           // synthesis translate_off
           if (AXI_ARLEN>=FIFO_DEPTH) $display("%0t %m ERROR burst length exceeds the depth of FIFO.", $time);
           // synthesis translate_on
       end
       end // ST_CON1_SRCA_ADDR
    ST_CON1_TRANS_SRCA_DATA: begin
       if ((AXI_RVALID==1'b1)&&(AXI_RREADY==1'b1)) begin
            cntA_beat             <= cntA_beat + 1;
            cntA_all_moved_bytes  <= cntA_all_moved_bytes + num_bytes;
            cntA_line_moved_bytes <= cntA_line_moved_bytes + num_bytes;
            regA_add              <= regA_add + num_bytes;
            if (AXI_RLAST==1'b1) begin
                if ((cntA_line_moved_bytes+num_bytes)==numA_line_bytes) begin
                    cntA_line_moved_bytes <= 'h0; // for next line
                end
                if ((cntA_all_moved_bytes+num_bytes)==numA_all_bytes) begin
                    srcA_done <= 1'b1;
                    // synthesis translate_off
                    if ((cntA_line_moved_bytes+num_bytes)!=numA_line_bytes)
                        $display("%0t %m ERROR line/all mis-match.", $time);
                    // synthesis translate_on
                end
                if ((cntA_line_moved_bytes+num_bytes)<numA_line_bytes) begin
                    state  <= ST_CON1_TRANS_SRCA_CAL;
                end else begin // ((cntA_all_moved_bytes+num_bytes)==numA_all_bytes)
                    if ((command==MOVER_COMMAND_CONCAT1[3:0])&&
                        (srcB_go==1'b1)&&(srcB_done==1'b0)) begin
                        // interleaving
                        state <= ST_CON1_SRCB_CAL;
                    end else begin
                        OUT_FLUSH <= 1'b1;
                        state <= ST_DONE;
                    end
                end
                // synthesis translate_off
                if (cntA_beat!=AXI_ARLEN)
                    $display("%0t %m ERROR burst length error.", $time);
                // synthesis translate_on
            end
            // synthesis translate_off
            if ((cntA_line_moved_bytes+num_bytes)>numA_line_bytes)
                $display("%t %m WARNING source A addres exceeds.", $time);
            // synthesis translate_on
       end
       end // ST_CON1_SRCA_DATA
    ST_CON1_SRCB_CAL: begin
       AXI_ARID    <= AXI_ARID + 1;
       AXI_ARADDR  <= regB_add;
       if (regB_offset=='h0) begin
           // aligned access
           if (remB_line_bytes<AXI_WIDTH_DS) begin
               AXI_ARLEN   <= 'h0;
               AXI_ARSIZE  <= func_get_arsize(remB_line_bytes[AXI_WIDTH_DSB:0]);
           end else if (remB_line_bytes<((srcB_leng+1)*AXI_WIDTH_DS)) begin
               AXI_ARLEN   <= remB_line_bytes/AXI_WIDTH_DS-1;
               AXI_ARSIZE  <= func_get_arsize(AXI_WIDTH_DS);
           end else begin
               AXI_ARLEN   <= srcB_leng;
               AXI_ARSIZE  <= func_get_arsize(AXI_WIDTH_DS);
           end
       end else begin
           // mis-aligned access
           if ((AXI_WIDTH_DS-regB_offset)<=remB_line_bytes) begin
               AXI_ARLEN   <= 'h0;
               AXI_ARSIZE  <= func_get_arsize_misaligned(AXI_WIDTH_DS-regB_offset, regB_offset);
           end else begin
               AXI_ARLEN   <= 'h0;
               AXI_ARSIZE  <= func_get_arsize_misaligned(remB_line_bytes[AXI_WIDTH_DSB:0], regB_offset);
           end
       end
       AXI_ARVALID      <= 1'b1;
       state            <= ST_CON1_SRCB_ADDR;
       // synthesis translate_off
       if (remB_line_bytes<=0) $display("%t %m ERROR addres error.", $time);
       // synthesis translate_on
       end // ST_CON1_SRCB_CAL
    ST_CON1_SRCB_ADDR: begin
       if ((AXI_ARVALID==1'b1)&&(AXI_ARREADY==1'b1)) begin
           AXI_ARVALID <= 1'b0;
           cntB_beat   <=  'h0;
           state       <= ST_CON1_SRCB_DATA;
           // synthesis translate_off
           if (AXI_ARLEN>=FIFO_DEPTH) $display("%0t %m WARNING burst length exceeds the depth of FIFO.", $time);
           // synthesis translate_on
       end
       end // ST_CON1_SRCA_ADDR
    ST_CON1_SRCB_DATA: begin
       if ((AXI_RVALID==1'b1)&&(AXI_RREADY==1'b1)) begin
            cntB_beat             <= cntB_beat + 1;
            cntB_all_moved_bytes  <= cntB_all_moved_bytes + num_bytes;
            cntB_line_moved_bytes <= cntB_line_moved_bytes + num_bytes;
            regB_add              <= regB_add + num_bytes;
            if (AXI_RLAST==1'b1) begin
                if ((cntB_line_moved_bytes+num_bytes)==numB_line_bytes) begin
                     cntB_line_moved_bytes <= 'h0; // for next line
                end
                if ((cntB_all_moved_bytes+num_bytes)==numB_all_bytes) begin
                    srcB_done <= 1'b1;
                    // synthesis translate_off
                    if ((cntB_line_moved_bytes+num_bytes)!=numB_line_bytes)
                        $display("%0t %m ERROR line/all mis-match.", $time);
                    // synthesis translate_on
                end
                if ((cntB_line_moved_bytes+num_bytes)<numB_line_bytes) begin
                   state  <= ST_CON1_SRCB_CAL;
                end else begin
                    if ((srcA_go==1'b1)&&(srcA_done==1'b0)) begin
                       // interleaving
                       state  <= ST_CON1_TRANS_SRCA_CAL;
                    end else begin
                        if ((srcB_done==1'b1)||
                            (cntB_all_moved_bytes+num_bytes)>=numB_all_bytes) begin
                            OUT_FLUSH <= 1'b1;
                            state     <= ST_DONE;
                        end else begin
                            state  <= ST_CON1_SRCB_CAL;
                        end
                    end // if (srcB_go
                end
                // synthesis translate_off
                if (cntB_beat!=AXI_ARLEN)
                    $display("%0t %m ERROR burst length error.", $time);
                // synthesis translate_on
            end
            // synthesis translate_off
            if ((cntB_line_moved_bytes+num_bytes)>numB_line_bytes)
                $display("%t %m ERROR source B addres exceeds.", $time);
            // synthesis translate_on
       end
       end // ST_CON1_SRCB_DATA
    ST_DONE: begin
       if ((fifoA_empty&&fifoB_empty)) OUT_FLUSH <= 1'b0;
       if (srcA_go==1'b0) srcA_done <= 1'b0;
       if (srcB_go==1'b0) srcB_done <= 1'b0;
     //if ((OUT_FLUSH==1'b0)&&(srcA_done==1'b0)&&(srcB_done==1'b0))state <= ST_READY;
       if ((srcA_done==1'b0)&&(srcB_done==1'b0))state <= ST_READY;
       end // ST_DONE
    default: begin
             AXI_ARID              <=  'h0;
             AXI_ARADDR            <=  'h0;
             AXI_ARLEN             <= 8'h0;
             AXI_ARSIZE            <= 3'b0;
             AXI_ARVALID           <= 1'b0;
             srcA_done             <= 1'b0;
             regA_add              <=  'h0;
             cntA_all_moved_bytes  <=  'h0;
             cntA_line_moved_bytes <=  'h0;
             srcB_done             <= 1'b0;
             regB_add              <=  'h0;
             cntB_all_moved_bytes  <=  'h0;
             cntB_line_moved_bytes <=  'h0;
             OUT_FLUSH             <= 1'b0;
             state                 <= ST_READY;
             end
    endcase
    end // if
    end // always
    //--------------------------------------------------------------------------
    // synthesis translate_off
    reg  [8*32-1:0] state_ascii="READY               ";
    always @ (state) begin
    case (state)
    ST_READY               : state_ascii="READY               ";
    ST_MOV_CON0_SRCA_CAL   : state_ascii="MOV_CON0_SRCA_CAL   ";
    ST_MOV_CON0_SRCA_ADDR  : state_ascii="MOV_CON0_SRCA_ADDR  ";
    ST_MOV_CON0_SRCA_DATA  : state_ascii="MOV_CON0_SRCA_DATA  ";
    ST_CON0_SRCB_CAL       : state_ascii="CON0_SRCB_CAL       ";
    ST_CON0_SRCB_ADDR      : state_ascii="CON0_SRCB_ADDR      ";
    ST_CON0_SRCB_DATA      : state_ascii="CON0_SRCB_DATA      ";
    ST_RES_SRCA_CAL        : state_ascii="RES_SRCA_CAL        ";
    ST_RES_SRCA_ADDR       : state_ascii="RES_SRCA_ADDR       ";
    ST_RES_SRCA_DATA       : state_ascii="RES_SRCA_DATA       ";
    ST_RES_SRCB_CAL        : state_ascii="RES_SRCB_CAL        ";
    ST_RES_SRCB_ADDR       : state_ascii="RES_SRCB_ADDR       ";
    ST_RES_SRCB_DATA       : state_ascii="RES_SRCB_DATA       ";
    ST_CON1_TRANS_SRCA_CAL : state_ascii="CON1_TRANS_SRCA_CAL ";
    ST_CON1_TRANS_SRCA_ADDR: state_ascii="CON1_TRANS_SRCA_ADDR";
    ST_CON1_TRANS_SRCA_DATA: state_ascii="CON1_TRANS_SRCA_DATA";
    ST_CON1_SRCB_CAL       : state_ascii="CON1_SRCB_CAL       ";
    ST_CON1_SRCB_ADDR      : state_ascii="CON1_SRCB_ADDR      ";
    ST_CON1_SRCB_DATA      : state_ascii="CON1_SRCB_DATA      ";
    ST_DONE                : state_ascii="DONE                ";
    default                : state_ascii="UNKNOWN             ";
    endcase
    end
    // synthesis translate_on
    //--------------------------------------------------------------------------
    assign AXI_RREADY  = (state==ST_MOV_CON0_SRCA_DATA  ) ? pushA_wr_ready
                       : (state==ST_CON0_SRCB_DATA      ) ? pushA_wr_ready // it is fifoA
                       : (state==ST_RES_SRCA_DATA       ) ? pushA_wr_ready
                       : (state==ST_RES_SRCB_DATA       ) ? pushB_wr_ready
                       : (state==ST_CON1_TRANS_SRCA_DATA) ? pushA_wr_ready
                       : (state==ST_CON1_SRCB_DATA      ) ? pushA_wr_ready // it is fifoA
                       : 1'b0;
    //--------------------------------------------------------------------------
    assign pushA_wr_valid = ((state==ST_MOV_CON0_SRCA_DATA  )||
                             (state==ST_CON0_SRCB_DATA      )||
                             (state==ST_RES_SRCA_DATA       )||
                             (state==ST_CON1_TRANS_SRCA_DATA)||
                             (state==ST_CON1_SRCB_DATA      )) ? AXI_RVALID : 1'b0;
    assign pushA_wr_data  =  (state==ST_MOV_CON0_SRCA_DATA  ) ? func_get_data_justified(regA_offset,AXI_RDATA)
                          :  (state==ST_CON0_SRCB_DATA      ) ? func_get_data_justified(regB_offset,AXI_RDATA)
                          :  (state==ST_RES_SRCA_DATA       ) ? func_get_data_justified(regA_offset,AXI_RDATA)
                          :  (state==ST_CON1_TRANS_SRCA_DATA) ? func_get_data_justified(regA_offset,AXI_RDATA)
                          :  (state==ST_CON1_SRCB_DATA      ) ? func_get_data_justified(regB_offset,AXI_RDATA)
                          : 'h0;
    assign pushA_wr_strb  =  (state==ST_MOV_CON0_SRCA_DATA  ) ? func_get_strb_justified(regA_offset,AXI_ARSIZE)
                          :  (state==ST_CON0_SRCB_DATA      ) ? func_get_strb_justified(regB_offset,AXI_ARSIZE)
                          :  (state==ST_RES_SRCA_DATA       ) ? func_get_strb_justified(regA_offset,AXI_ARSIZE)
                          :  (state==ST_CON1_TRANS_SRCA_DATA) ? func_get_strb_justified(regA_offset,AXI_ARSIZE)
                          :  (state==ST_CON1_SRCB_DATA      ) ? func_get_strb_justified(regB_offset,AXI_ARSIZE)
                          : 'h0;
    assign pushA_wr_last  =((command==MOVER_COMMAND_COPY[3:0])&&
                            (state==ST_MOV_CON0_SRCA_DATA )) ? ((cntA_all_moved_bytes+num_bytes)==numA_all_bytes)
                          : (state==ST_CON0_SRCB_DATA     )  ? ((cntB_all_moved_bytes+num_bytes)==numB_all_bytes)
                          : (state==ST_RES_SRCA_DATA      )  ? ((cntA_all_moved_bytes+num_bytes)==numA_all_bytes)
                          :((command==MOVER_COMMAND_TRANSPOSE[3:0])&&
                            (state==ST_CON1_TRANS_SRCA_DATA)) ?  ((cntA_all_moved_bytes+num_bytes)==numA_all_bytes)
                          : (state==ST_CON1_SRCB_DATA      )  ?  ((cntB_all_moved_bytes+num_bytes)==numB_all_bytes)
                          : 1'b0;
    assign pushB_wr_valid = (state==ST_RES_SRCB_DATA) ? AXI_RVALID : 1'b0;
    assign pushB_wr_data  = (state==ST_RES_SRCB_DATA) ? func_get_data_justified(regB_offset,AXI_RDATA)
                          : 'h0;
    assign pushB_wr_strb  = (state==ST_RES_SRCB_DATA) ? func_get_strb_justified(regB_offset,AXI_ARSIZE)
                          : 'h0;
    assign pushB_wr_last  = (state==ST_RES_SRCB_DATA) ? ((cntB_all_moved_bytes+num_bytes)==numB_all_bytes)
                          : 1'b0;
    //--------------------------------------------------------------------------
    // get ARSIZE using the number of bytes that is 1 t0 AXI_WIDTH_DS.
    function [2:0] func_get_arsize;
    input [AXI_WIDTH_DSB:0] bytes;
    begin
        case (bytes)
        'h01: func_get_arsize = 3'h0; //00001
        'h02: func_get_arsize = 3'h1; //00010
        'h03: func_get_arsize = 3'h1; //00011
        'h04: func_get_arsize = 3'h2; //00100
        'h05: func_get_arsize = 3'h2; //00101
        'h06: func_get_arsize = 3'h2; //00110
        'h07: func_get_arsize = 3'h2; //00111
        'h08: func_get_arsize = 3'h3; //01000
        'h09: func_get_arsize = 3'h3; //01001
        'h0A: func_get_arsize = 3'h3; //01010
        'h0B: func_get_arsize = 3'h3; //01011
        'h0C: func_get_arsize = 3'h3; //01100
        'h0D: func_get_arsize = 3'h3; //01101
        'h0E: func_get_arsize = 3'h3; //01110
        'h0F: func_get_arsize = 3'h3; //01111
        'h10: func_get_arsize = 3'h4; //10000
        default: begin
                 func_get_arsize = 3'h0;
                 // synthesis translate_off
                 $display("%0t %m ERROR size error.", $time);
                 // synthesis translate_on
                 end
        endcase
    end
    endfunction
    //--------------------------------------------------------------------------
    // get ARSIZE using the number of bytes that is 1 t0 AXI_WIDTH_DS.
    function [2:0] func_get_arsize_misaligned;
    input [AXI_WIDTH_DSB:0] bytes;
    input [AXI_WIDTH_DSB-1:0] offset;
    begin
        if (offset[0]==1'b1) begin
            func_get_arsize_misaligned = 3'h0; // one-byte
        end else begin
            if (AXI_WIDTH_DS==4) begin // 32-bit data
                // offset can be 2
                // bytes can be 1, 2, 3, 4
                if (bytes==1) func_get_arsize_misaligned = 3'h0; // one-byte
                else func_get_arsize_misaligned = 3'h1; // two-byte
            end else if (AXI_WIDTH_DS==8) begin // 64-bit data
                // offset can be 2, 4, 6
                // bytes can be 1, 2, 3, 4, 5, 6, 7, 8
                if ((bytes>=4)&&(offset==4)) func_get_arsize_misaligned = 3'h2; // four-byte
                else if (bytes>=2) func_get_arsize_misaligned = 3'h1; // two-byte
                else func_get_arsize_misaligned = 3'h0; // one-byte
            end else if (AXI_WIDTH_DS==16) begin // 128-bit data
                // offset can be 2, 4, 6, 8, 10, 12, 14
                // bytes can be 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
                if ((bytes>=8)&&(offset==8)) func_get_arsize_misaligned = 3'h3; // eight-byte
                else if ((bytes>=4)&&((offset==4)||(offset==8)||(offset==12))) func_get_arsize_misaligned = 3'h2; // four-byte
                else if (bytes>=2) func_get_arsize_misaligned = 3'h1; // two-byte
                else func_get_arsize_misaligned = 3'h0; // one-byte
            end else if (AXI_WIDTH_DS==32) begin // 256-bit data
                // offset can be 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30
                // bytes can be 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, ...
                if ((bytes>=16)&&(offset==16)) func_get_arsize_misaligned = 3'h4; // 16-byte
                else if ((bytes>=8)&&(offset==8)) func_get_arsize_misaligned = 3'h3; // eight-byte
                else if ((bytes>=4)&&((offset==4)||(offset==8)||(offset==12)||(offset==16)||(offset==20)||(offset==24)||(offset==28))) func_get_arsize_misaligned = 3'h2; // four-byte
                else if (bytes>=2) func_get_arsize_misaligned = 3'h1; // two-byte
                else func_get_arsize_misaligned = 3'h0; // one-byte
            end else begin
                func_get_arsize_misaligned = 3'h0; // one-byte
            end
        end
    end
    endfunction
    //--------------------------------------------------------------------------
    function [AXI_WIDTH_DA-1:0] func_get_data_justified;
    input [AXI_WIDTH_DSB-1:0] offset;  // address offset
    input [AXI_WIDTH_DA-1:0]  data; // to move
    begin
        func_get_data_justified = data>>(offset*8);
    end
    endfunction
    //--------------------------------------------------------------------------
    function [AXI_WIDTH_DS-1:0] func_get_strb_justified;
    input [AXI_WIDTH_DSB-1:0] offset;  // address offset
    input [2:0]               size; // AxSIZE format
    begin
        case (size)
        3'b000: func_get_strb_justified= {  1{1'b1}};
        3'b001: func_get_strb_justified= {  2{1'b1}};
        3'b010: func_get_strb_justified= {  4{1'b1}};
        3'b011: func_get_strb_justified= {  8{1'b1}};
        3'b100: func_get_strb_justified= { 16{1'b1}};
        3'b101: func_get_strb_justified= { 32{1'b1}};
        3'b110: func_get_strb_justified= { 64{1'b1}};
        3'b111: func_get_strb_justified= {128{1'b1}};
        endcase
    end
    endfunction
    //--------------------------------------------------------------------------
    function [AXI_WIDTH_DS-1:0] func_get_strb;
    input [AXI_WIDTH_DSB-1:0] offset;  // address offset
    input [2:0]               size; // AxSIZE format
    begin
        case (size)
        3'b000: func_get_strb = {  1{1'b1}}<<offset;
        3'b001: func_get_strb = {  2{1'b1}}<<offset;
        3'b010: func_get_strb = {  4{1'b1}}<<offset;
        3'b011: func_get_strb = {  8{1'b1}}<<offset;
        3'b100: func_get_strb = { 16{1'b1}}<<offset;
        3'b101: func_get_strb = { 32{1'b1}}<<offset;
        3'b110: func_get_strb = { 64{1'b1}}<<offset;
        3'b111: func_get_strb = {128{1'b1}}<<offset;
        endcase
    end
    endfunction
    //--------------------------------------------------------------------------
    wire                    `RES_DLY  fifoA_wr_ready;
    wire                    `RES_DLY  fifoA_wr_valid;
    wire [AXI_WIDTH_DA-1:0] `RES_DLY  fifoA_wr_data ; // justified
    wire [AXI_WIDTH_DS-1:0] `RES_DLY  fifoA_wr_strb ; // justified
    wire                    `RES_DLY  fifoA_wr_last ;
    reg                               fifoA_rd_ready;
    wire                    `RES_DLY  fifoA_rd_valid;
    wire [AXI_WIDTH_DA-1:0] `RES_DLY  fifoA_rd_data ; // justified
    wire [AXI_WIDTH_DS-1:0] `RES_DLY  fifoA_rd_strb ; // justified
    wire                    `RES_DLY  fifoA_rd_last ;
    wire [FIFO_AW:0]        `RES_DLY  fifoA_rooms   ;
    wire                    `RES_DLY  fifoA_full    ;
    wire                    `RES_DLY  fifoA_clr      = init;
    wire                    `RES_DLY  fifoA_clr_done = fifoA_wr_ready&fifoA_empty&~fifoA_full;
    wire                    `RES_DLY  fifoB_wr_ready;
    wire                    `RES_DLY  fifoB_wr_valid;
    wire [AXI_WIDTH_DA-1:0] `RES_DLY  fifoB_wr_data ; // justified
    wire [AXI_WIDTH_DS-1:0] `RES_DLY  fifoB_wr_strb ; // justified
    wire                    `RES_DLY  fifoB_wr_last ;
    reg                               fifoB_rd_ready;
    wire                    `RES_DLY  fifoB_rd_valid;
    wire [AXI_WIDTH_DA-1:0] `RES_DLY  fifoB_rd_data ; // justified
    wire [AXI_WIDTH_DS-1:0] `RES_DLY  fifoB_rd_strb ; // justified
    wire                    `RES_DLY  fifoB_rd_last ;
    wire [FIFO_AW:0]        `RES_DLY  fifoB_rooms   ;
    wire                    `RES_DLY  fifoB_full    ;
    wire                    `RES_DLY  fifoB_clr      = init;
    wire                    `RES_DLY  fifoB_clr_done = fifoB_wr_ready&fifoB_empty&~fifoB_full;
    assign ready = fifoA_clr_done&fifoB_clr_done;
    //--------------------------------------------------------------------------
    // It makes justified-filled data output.
    mover_2d_fifo_sync_merger_push #(.FDW(AXI_WIDTH_DA))
    u_pushA (
          .rstn    ( ARESETn        )
        , .clr     ( init           )
        , .clk     ( ACLK           )
        , .wr_rdy  ( pushA_wr_ready ) // makes sure resB_wr_ready is 1 at the same time
        , .wr_vld  ( pushA_wr_valid ) // makes sure resB_wr_valid is 1 at the same time
        , .wr_data ( pushA_wr_data  )
        , .wr_strb ( pushA_wr_strb  )
        , .wr_last ( pushA_wr_last  )
        , .rd_rdy  ( fifoA_wr_ready )
        , .rd_vld  ( fifoA_wr_valid )
        , .rd_data ( fifoA_wr_data  )
        , .rd_strb ( fifoA_wr_strb  )
        , .rd_last ( fifoA_wr_last  )
    );
    mover_2d_fifo_sync_merger_push #(.FDW(AXI_WIDTH_DA))
    u_pushB (
          .rstn    ( ARESETn        )
        , .clr     ( init           )
        , .clk     ( ACLK           )
        , .wr_rdy  ( pushB_wr_ready ) // makes sure resA_wr_ready is 1 at the same time
        , .wr_vld  ( pushB_wr_valid ) // makes sure resA_wr_valid is 1 at the same time
        , .wr_data ( pushB_wr_data  )
        , .wr_strb ( pushB_wr_strb  )
        , .wr_last ( pushB_wr_last  )
        , .rd_rdy  ( fifoB_wr_ready )
        , .rd_vld  ( fifoB_wr_valid )
        , .rd_data ( fifoB_wr_data  )
        , .rd_strb ( fifoB_wr_strb  )
        , .rd_last ( fifoB_wr_last  )
    );
    //--------------------------------------------------------------------------
    // LAST+STRB+DATA
    // note that 'fifoA_wr/rd_data' carried justified data.
    mover_2d_fifo_sync #(.FDW(1+AXI_WIDTH_DS+AXI_WIDTH_DA),.FAW(FIFO_AW   ))
    u_fifo_srcA (
          .rstn     ( ARESETn        )
        , .clk      ( ACLK           )
        , .clr      ( fifoA_clr      )
        , .wr_rdy   ( fifoA_wr_ready )
        , .wr_vld   ( fifoA_wr_valid )
        , .wr_din   ({fifoA_wr_last,fifoA_wr_strb,fifoA_wr_data})
        , .rd_rdy   ( fifoA_rd_ready )
        , .rd_vld   ( fifoA_rd_valid )
        , .rd_dout  ({fifoA_rd_last,fifoA_rd_strb,fifoA_rd_data})
        , .full     ( fifoA_full     )
        , .empty    ( fifoA_empty    )
        , .item_cnt ( fifoA_items    )
        , .room_cnt ( fifoA_rooms    )
    );
    //--------------------------------------------------------------------------
    // LAST+STRB+DATA
    // note that 'fifoB_wr/rd_data' carried justified data.
    mover_2d_fifo_sync #(.FDW(1+AXI_WIDTH_DS+AXI_WIDTH_DA),.FAW(FIFO_AW   ))
    u_fifo_srcB (
          .rstn     ( ARESETn        )
        , .clk      ( ACLK           )
        , .clr      ( fifoB_clr      )
        , .wr_rdy   ( fifoB_wr_ready )
        , .wr_vld   ( fifoB_wr_valid )
        , .wr_din   ({fifoB_wr_last,fifoB_wr_strb,fifoB_wr_data})
        , .rd_rdy   ( fifoB_rd_ready )
        , .rd_vld   ( fifoB_rd_valid )
        , .rd_dout  ({fifoB_rd_last,fifoB_rd_strb,fifoB_rd_data})
        , .full     ( fifoB_full     )
        , .empty    ( fifoB_empty    )
        , .item_cnt ( fifoB_items    )
        , .room_cnt ( fifoB_rooms    )
    );
    //--------------------------------------------------------------------------
    wire [AXI_WIDTH_DA/DATA_WIDTH-1:0] `RES_DLY residual_ready;
    //--------------------------------------------------------------------------
    wire [AXI_WIDTH_DA/DATA_WIDTH-1:0] `RES_DLY residual_valid   ;
    wire [AXI_WIDTH_DA-1:0]            `RES_DLY residual_data    ;
    wire [AXI_WIDTH_DS-1:0]            `RES_DLY residual_strb    ;
    wire [AXI_WIDTH_DA/DATA_WIDTH-1:0] `RES_DLY residual_last    ;
    wire [AXI_WIDTH_DA/DATA_WIDTH-1:0] `RES_DLY residual_overflow;
    //--------------------------------------------------------------------------
    always @ ( * ) begin
    OUT_VALID = 1'b0;
    OUT_DATA  =  'h0;
    OUT_STRB  =  'h0;
    OUT_LAST  = 1'b0;
    OUT_EMPTY = 1'b0;
    OUT_FULL  = 1'b0;
    fifoA_rd_ready = 1'b0;
    fifoB_rd_ready = 1'b0;
    case (command)
    MOVER_COMMAND_COPY[3:0]: begin // use fifoA only
            OUT_VALID = fifoA_rd_valid;
            OUT_DATA  = fifoA_rd_data ;
            OUT_STRB  = fifoA_rd_strb ;
            OUT_LAST  = fifoA_rd_last ;
            OUT_EMPTY = fifoA_empty   ;
            OUT_FULL  = fifoA_full    ;
            fifoA_rd_ready = OUT_READY;
            fifoB_rd_ready = 1'b0     ;
            end
    MOVER_COMMAND_CONCAT0[3:0]: begin // use fifoA only
            OUT_VALID = fifoA_rd_valid;
            OUT_DATA  = fifoA_rd_data ;
            OUT_STRB  = fifoA_rd_strb ;
            OUT_LAST  = fifoA_rd_last ;
            OUT_EMPTY = fifoA_empty   ;
            OUT_FULL  = fifoA_full    ;
            fifoA_rd_ready = OUT_READY;
            fifoB_rd_ready = 1'b0     ;
            end
    MOVER_COMMAND_RESIDUAL[3:0]: begin // use two fifos for addition
            OUT_VALID = &residual_valid;
            OUT_DATA  =  residual_data;
            OUT_STRB  =  residual_strb;
            OUT_LAST  = &residual_last;
            OUT_EMPTY =  fifoA_empty&fifoB_empty;
            OUT_FULL  =  fifoB_full|fifoB_full;
            fifoA_rd_ready = (&residual_ready)&fifoB_rd_valid;
            fifoB_rd_ready = (&residual_ready)&fifoA_rd_valid;
            end
    MOVER_COMMAND_CONCAT1[3:0]: begin // use fifoA only
            OUT_VALID = fifoA_rd_valid;
            OUT_DATA  = fifoA_rd_data ;
            OUT_STRB  = fifoA_rd_strb ;
            OUT_LAST  = fifoA_rd_last ;
            OUT_EMPTY = fifoA_empty   ;
            OUT_FULL  = fifoA_full    ;
            fifoA_rd_ready = OUT_READY;
            fifoB_rd_ready = OUT_READY;
            end
    MOVER_COMMAND_TRANSPOSE[3:0]: begin // single source, line-by-line
            OUT_VALID = fifoA_rd_valid;
            OUT_DATA  = fifoA_rd_data ;
            OUT_STRB  = fifoA_rd_data ;
            OUT_LAST  = fifoA_rd_last ;
            OUT_EMPTY = fifoA_empty   ;
            OUT_FULL  = fifoA_full    ;
            fifoA_rd_ready = OUT_READY;
            fifoB_rd_ready = 1'b0     ;
            end
    default: begin
            OUT_VALID = 1'b0;
            OUT_DATA  =  'h0;
            OUT_STRB  =  'h0;
            OUT_LAST  = 1'b0;
            OUT_EMPTY = 1'b0;
            OUT_FULL  = 1'b0;
            fifoA_rd_ready = 1'b0;
            fifoB_rd_ready = 1'b0;
             end
    endcase
    end // always
    //--------------------------------------------------------------------------
    generate
    genvar gdx;
    for (gdx=0; gdx<(AXI_WIDTH_DA/DATA_WIDTH); gdx=gdx+1) begin : BLK_GDX
        mac_core_adder #(.N(DATA_WIDTH)
                        `ifdef DATA_FIXED_POINT
                        ,.Q(DATA_WIDTH_Q)
                        `endif
                        )
        u_add (
            .reset_n      ( ARESETn              )
          , .clk          ( ACLK                 )
          , .in_ready     ( residual_ready [gdx] )
          , .in_valid     ( fifoA_rd_valid&fifoB_rd_valid )
          , .in_last      ( fifoA_rd_last         )
          , .in_data_A    ( fifoA_rd_data  [gdx*DATA_WIDTH+:DATA_WIDTH]     )
          , .in_data_B    ( fifoB_rd_data  [gdx*DATA_WIDTH+:DATA_WIDTH]     )
          , .in_user      ( fifoA_rd_strb  [gdx*DATA_WIDTH/8+:DATA_WIDTH/8] )
        //, .in_overflow_A( add_mac_overflow     )
        //, .in_overflow_B( 1'b0                 )
          , .out_ready    ( OUT_READY            )
          , .out_valid    ( residual_valid [gdx] )
          , .out_last     ( residual_last  [gdx] )
          , .out_data     ( residual_data  [gdx*DATA_WIDTH+:DATA_WIDTH]     )
          , .out_user     ( residual_strb  [gdx*DATA_WIDTH/8+:DATA_WIDTH/8] )
          , .out_overflow ( residual_overflow[gdx] )
        );
    end // for
    endgenerate
    //--------------------------------------------------------------------------
    always @ (posedge ACLK or negedge ARESETn) begin
    if (ARESETn==1'b0) begin
        profile_residual_overflow <='h0;
    end else if (profile_init==1'b1) begin
        profile_residual_overflow <='h0;
    end else begin
        if (command==MOVER_COMMAND_RESIDUAL[3:0]) begin
            if (|residual_overflow) begin
                 profile_residual_overflow = profile_residual_overflow
                                           + func_get_bnum_overflow(residual_overflow);
            end
        end
    end // if
    end // always
    //--------------------------------------------------------------------------
    function [AXI_WIDTH_DSB:0] func_get_bnum_overflow;
    input [AXI_WIDTH_DA/DATA_WIDTH-1:0] strb;
    integer idx;
    integer num;
    begin
        num = 0;
        for (idx=0; idx<AXI_WIDTH_DA/DATA_WIDTH; idx=idx+1) begin
             num = num + strb[idx];
        end
        func_get_bnum_overflow = num[AXI_WIDTH_DSB:0];
    end
    endfunction
    //--------------------------------------------------------------------------
    //             +------+      --+--+--+fifoA_rd   AND        +
    //             | fill |------->|  |  |------------*----.--->|\ 
    // fifoA_wr==> | push |<-------|  |  |<----------(---.------|  \
    //             |      |      --+--+--+            | /       | A |residual
    //             +------+                           | |       | D |--------->
    //             +------+      --+--+--+fifoB_rd    | |       | D |<---------
    //             | fill |------->|  |  |------------+ |       |   |
    // fifoB_wr==> | push |<-------|  |  |<-------------+       |  /
    //             |      |      --+--+--+                      |/
    //             +------+                                     +
    //     /\              /\                  /\
    //     ||              ||                  ||
    //  justified   filled & justified      both outputs should be synchronized.
    //--------------------------------------------------------------------------
    // synthesis translate_off
    always @ (posedge ACLK) begin
        if (fifoA_rd_ready&fifoA_rd_valid&fifoB_rd_ready&fifoB_rd_valid) begin
             if (fifoA_rd_strb!==fifoB_rd_strb) begin
                  $display("%0t %m ERROR mis-match data strb for residual.", $time);
             end
             if (fifoA_rd_last!=fifoB_rd_last) begin
                  $display("%0t %m ERROR mis-match last for residual.", $time);
             end
        end
    end
    // synthesis translate_on
    //--------------------------------------------------------------------------
endmodule

//------------------------------------------------------------------------------
module mover_2d_control_result
     #(parameter AXI_WIDTH_ID =4       // ID width in bits
               , AXI_WIDTH_AD =32      // address width
               , AXI_WIDTH_DA =32      // data width
               , AXI_WIDTH_DS =(AXI_WIDTH_DA/8)
               , AXI_WIDTH_DSB=$clog2(AXI_WIDTH_DS)
               , DATA_TYPE    ="INTEGER" // "INTEGER", "FLOATING_POINT", "FIXED_POINT"
               , DATA_WIDTH   =32
               , DATA_BYTES   =(DATA_WIDTH/8)// num of bytes per result item (1 for byte)
               , FIFO_DEPTH   =32, // not used for this version since fifo_merger_pop is used
       parameter [3:0] MOVER_COMMAND_NOP      = 'h0,
       parameter [3:0] MOVER_COMMAND_FILL     = 'h1,
       parameter [3:0] MOVER_COMMAND_COPY     = 'h2,
       parameter [3:0] MOVER_COMMAND_RESIDUAL = 'h3,// point-to-point adder
       parameter [3:0] MOVER_COMMAND_CONCAT0  = 'h4,
       parameter [3:0] MOVER_COMMAND_CONCAT1  = 'h5,
       parameter [3:0] MOVER_COMMAND_TRANSPOSE= 'h6,
       parameter [3:0] ACTIV_FUNC_BYPASS    =4'h0,
       parameter [3:0] ACTIV_FUNC_RELU      =4'h1,
       parameter [3:0] ACTIV_FUNC_LEAKY_RELU=4'h2,
       parameter [3:0] ACTIV_FUNC_SIGMOID   =4'h3,
       parameter [3:0] ACTIV_FUNC_TANH      =4'h4
               )
(
      input   wire                      ARESETn
    , input   wire                      ACLK
    ,            output  reg   [AXI_WIDTH_ID-1:0]  AXI_AWID
    , `DBG_MOVER output  reg   [AXI_WIDTH_AD-1:0]  AXI_AWADDR
    , `DBG_MOVER output  reg   [ 7:0]              AXI_AWLEN
    , `DBG_MOVER output  reg   [ 2:0]              AXI_AWSIZE
    ,            output  reg   [ 1:0]              AXI_AWBURST // incremental
    , `DBG_MOVER output  reg                       AXI_AWVALID
    , `DBG_MOVER input   wire                      AXI_AWREADY
    , `DBG_MOVER output  reg   [AXI_WIDTH_DA-1:0]  AXI_WDATA // non-justified
    , `DBG_MOVER output  wire  [AXI_WIDTH_DS-1:0]  AXI_WSTRB // non-justified
    , `DBG_MOVER output  wire                      AXI_WLAST
    , `DBG_MOVER output  reg                       AXI_WVALID
    , `DBG_MOVER input   wire                      AXI_WREADY
    ,            input   wire  [AXI_WIDTH_ID-1:0]  AXI_BID
    , `DBG_MOVER input   wire  [ 1:0]              AXI_BRESP
    , `DBG_MOVER input   wire                      AXI_BVALID
    , `DBG_MOVER output  reg                       AXI_BREADY
    //
    , output  wire                      IN_READY
    , input   wire                      IN_VALID
    , input   wire  [AXI_WIDTH_DA-1:0]  IN_DATA // justified
    , input   wire  [AXI_WIDTH_DS-1:0]  IN_STRB // justified
    , input   wire                      IN_LAST
    , input   wire                      IN_FLUSH
    //
    , `DBG_MOVER input   wire  [ 3:0]              command
    , `DBG_MOVER input   wire                      result_go
    , `DBG_MOVER output  reg                       result_done// read-done
    , `DBG_MOVER input   wire  [AXI_WIDTH_AD-1:0]  result_address
    , `DBG_MOVER input   wire  [15:0]              result_width
    , `DBG_MOVER input   wire  [15:0]              result_height
    , `DBG_MOVER input   wire  [31:0]              result_items// num of items whole
    , `DBG_MOVER input   wire  [ 7:0]              result_leng // AxLENG format
    //
    , input   wire  [DATA_WIDTH-1:0]    fill_value
    , input   wire  [ 3:0]              activ_func
    , input   wire  [DATA_WIDTH-1:0]    activ_param
    //
    , input   wire                      init
    , output  reg                       ready
);
    //--------------------------------------------------------------------------
    wire                      pop_wr_READY;
    wire                      pop_wr_VALID;
    wire  [AXI_WIDTH_DA-1:0]  pop_wr_DATA ;// justified
    wire  [AXI_WIDTH_DS-1:0]  pop_wr_STRB ;// justified
    wire                      pop_wr_LAST ;
    reg                       pop_rd_READY;
    wire                      pop_rd_VALID;
    wire  [AXI_WIDTH_DA-1:0]  pop_rd_DATA ;// justified
    wire  [AXI_WIDTH_DS-1:0]  pop_rd_STRB ;// justified
    wire                      pop_rd_LAST ;
    reg   [AXI_WIDTH_DS-1:0]  pop_rd_SREQ ;// justified
    wire                      fifo_EMPTY;
    wire                      fifo_FULL ;
    //--------------------------------------------------------------------------
    localparam NUM=(AXI_WIDTH_DA/DATA_WIDTH);
    wire  [NUM-1:0]          activ_in_ready_part ;
    wire                     activ_in_valid      ;
    wire  [AXI_WIDTH_DA-1:0] activ_in_data       ;
    wire  [AXI_WIDTH_DS-1:0] activ_in_strb       ;
    wire                     activ_in_last       ;
    wire                     activ_in_ready =&activ_in_ready_part;
    //--------------------------------------------------------------------------
    wire                     activ_out_ready     ;
    wire  [NUM-1:0]          activ_out_valid_part;
    wire  [AXI_WIDTH_DA-1:0] activ_out_data      ;
    wire  [AXI_WIDTH_DS-1:0] activ_out_strb      ;
    wire  [NUM-1:0]          activ_out_last_part ;
    wire                     activ_out_valid=&activ_out_valid_part;
    wire                     activ_out_last =&activ_out_last_part ;
    //--------------------------------------------------------------------------
    `DBG_MOVER reg  [AXI_WIDTH_AD-1:0]  reg_add             ='h0; // keep track of address
    `DBG_MOVER wire [AXI_WIDTH_DSB-1:0] reg_offset          =reg_add[AXI_WIDTH_DSB-1:0];
    `DBG_MOVER reg  [31:0]              cnt_all_moved_bytes = 'h0;
    `DBG_MOVER reg  [31:0]              cnt_line_moved_bytes= 'h0;
    `DBG_MOVER reg  [ 7:0]              cnt_beat            = 'h0; // keep track of a burst
    `DBG_MOVER wire [31:0]              num_all_bytes       = result_items*DATA_BYTES;
    `DBG_MOVER wire signed [31:0]       rem_all_bytes       = num_all_bytes-cnt_all_moved_bytes;
    `DBG_MOVER wire signed [31:0]       rem_line_bytes      = result_width*DATA_BYTES-cnt_line_moved_bytes;
    `DBG_MOVER wire [ 7:0]              num_bytes           = 1<<AXI_AWSIZE;
    //--------------------------------------------------------------------------
    localparam ST_READY='h0
             , ST_DRV  ='h1
             , ST_ADDR ='h2
             , ST_DATA ='h3
             , ST_RESP ='h4
             , ST_DONE ='h5;
    `DBG_MOVER reg [2:0] state=ST_READY;
    //--------------------------------------------------------------------------
    always @ (posedge ACLK or negedge ARESETn) begin
    if (ARESETn==1'b0) begin
        AXI_AWID    <=  'h0;
        AXI_AWADDR  <=  'h0;
        AXI_AWLEN   <=  'h0;
        AXI_AWSIZE  <=  'h0;
        AXI_AWBURST <= 2'b01;
        AXI_AWVALID <= 1'b0;
        AXI_BREADY  <= 1'b0;
        result_done          <= 1'b0;
        ready                <= 1'b0;
        reg_add              <=  'h0;
        cnt_all_moved_bytes  <=  'h0;
        cnt_line_moved_bytes <=  'h0;
        cnt_beat             <=  'h0;
        state                <= ST_READY;
    end else begin
    case (state)
    ST_READY: begin
        ready                <= 1'b1;
        reg_add              <= result_address;
        cnt_all_moved_bytes  <= 'h0;
        cnt_line_moved_bytes <= 'h0;
        if (result_go==1'b1) begin
           if (command==MOVER_COMMAND_TRANSPOSE[3:0]) begin
               result_done <= 1'b1;
               state       <= ST_DONE;
               // synthesis translate_off
               $display("%0t %m ERROR TRANSPOSE not supported yet.", $time);
               // synthesis translate_on
           end else begin
               state <= ST_DRV;
           end
        end
        end // ST_DATA1
    ST_DRV: begin
       AXI_AWID    <= AXI_AWID + 1;
       AXI_AWADDR  <= reg_add;
       if (reg_offset=='h0) begin
           // aligned access
           if (rem_all_bytes<AXI_WIDTH_DS) begin
               AXI_AWLEN  <= 'h0;
               AXI_AWSIZE <= func_get_awsize(rem_all_bytes[AXI_WIDTH_DSB:0]);
           end else if (rem_all_bytes<((result_leng+1)*AXI_WIDTH_DS)) begin
               AXI_AWLEN  <= rem_all_bytes/AXI_WIDTH_DS-1;
               AXI_AWSIZE <= func_get_awsize(AXI_WIDTH_DS);
           end else begin
               AXI_AWLEN  <= result_leng;
               AXI_AWSIZE <= func_get_awsize(AXI_WIDTH_DS);
           end
       end else begin
           // mis-aligned access
           if ((AXI_WIDTH_DS-reg_offset)<=rem_all_bytes) begin
               AXI_AWLEN  <= 'h0;
               AXI_AWSIZE <= func_get_awsize_misaligned(AXI_WIDTH_DS-reg_offset, reg_offset);
           end else begin
               AXI_AWLEN  <= 'h0;
               AXI_AWSIZE <= func_get_awsize_misaligned(rem_all_bytes[AXI_WIDTH_DSB:0], reg_offset);
           end
       end
       AXI_AWVALID <= 1'b1;
       state       <= ST_ADDR;
       // synthesis translate_off
       if (rem_all_bytes<=0) $display("%t %m ERROR addres error.", $time);
       // synthesis translate_on
       end // ST_DRV
    ST_ADDR: begin
       if ((AXI_AWVALID==1'b1)&&(AXI_AWREADY==1'b1)) begin
           AXI_AWVALID <= 1'b0;
           cnt_beat    <=  'h0;
           state       <= ST_DATA;
       end
       end // ST_ADDR
    ST_DATA: begin
       if ((AXI_WVALID==1'b1)&&(AXI_WREADY==1'b1)) begin
            cnt_beat             <= cnt_beat + 1;
            cnt_all_moved_bytes  <= cnt_all_moved_bytes + num_bytes;
            cnt_line_moved_bytes <= cnt_line_moved_bytes + num_bytes;
            reg_add              <= reg_add + num_bytes;
            if (AXI_WLAST==1'b1) begin
                AXI_BREADY <= 1'b1;
                state      <= ST_RESP;
                // synthesis translate_off
                if (cnt_beat!=AXI_AWLEN)
                    $display("%0t %m ERROR burst length error.", $time);
                // synthesis translate_on
            end
            // synthesis translate_off
            if ((cnt_all_moved_bytes+num_bytes)>num_all_bytes)
                $display("%t %m WARNING source A addres exceeds.", $time);
            // synthesis translate_on
       end
       end // ST_DATA
    ST_RESP: begin
       if (AXI_BVALID==1'b1) begin
           AXI_BREADY <= 1'b0;
           if (cnt_all_moved_bytes<num_all_bytes) begin
               if (cnt_line_moved_bytes==(result_width*DATA_BYTES)) begin
                   cnt_line_moved_bytes <= 'h0;
               end
               state  <= ST_DRV;
           end else begin // ((cnt_all_moved_bytes==num_all_bytes)
               result_done <= 1'b1;
               state       <= ST_DONE;
           end
           // synthesis translate_off
           if (AXI_BRESP!=2'b00)
               $display("%t %m ERROR non-OK response.", $time);
           if (AXI_BID!=AXI_AWID)
               $display("%t %m ERROR mis-match BID.", $time);
           // synthesis translate_on
       end
       end // ST_RESP
    ST_DONE: begin
       if (result_go==1'b0) begin
           result_done <= 1'b0;
           state       <= ST_READY;
       end
       end // ST_DONE
    default: begin
             AXI_AWID    <=  'h0;
             AXI_AWADDR  <=  'h0;
             AXI_AWLEN   <=  'h0;
             AXI_AWSIZE  <=  'h0;
             AXI_AWVALID <= 1'b0;
             AXI_BREADY  <= 1'b0;
             result_done          <= 1'b0;
             reg_add              <=  'h0;
             cnt_all_moved_bytes  <=  'h0;
             cnt_line_moved_bytes <=  'h0;
             cnt_beat             <=  'h0;
             state                <= ST_READY;
             end
    endcase
    end // if
    end // always
    //--------------------------------------------------------------------------
    // synthesis translate_off
    reg  [8*10-1:0] state_ascii="READY";
    always @ (state) begin
    case (state)
    ST_READY: state_ascii="READY";
    ST_DRV  : state_ascii="DRV  ";
    ST_ADDR : state_ascii="ADDR ";
    ST_DATA : state_ascii="DATA ";
    ST_RESP : state_ascii="RESP ";
    ST_DONE : state_ascii="DONE ";
    default : state_ascii="UNKNOWN";
    endcase
    end
    // synthesis translate_on
    //--------------------------------------------------------------------------
    assign AXI_WSTRB = func_get_wstrb(reg_offset,AXI_AWSIZE);
    assign AXI_WLAST = (cnt_beat==AXI_AWLEN);
    always @ ( * ) begin
    if (state==ST_DATA) begin
        if (command==MOVER_COMMAND_FILL[3:0]) begin
            pop_rd_READY =1'b0;
            pop_rd_SREQ  ={AXI_WIDTH_DS{1'b0}};
            AXI_WVALID =1'b1;
            AXI_WDATA  ={(AXI_WIDTH_DA/DATA_WIDTH){fill_value}};
        end else begin
            pop_rd_READY =AXI_WREADY;
            pop_rd_SREQ  =AXI_WSTRB>>reg_offset;
            AXI_WVALID =pop_rd_VALID;
            AXI_WDATA  =pop_rd_DATA<<(reg_offset*8);
        end
    end else begin
        pop_rd_READY =1'b0;
        pop_rd_SREQ  ={AXI_WIDTH_DS{1'b0}};
        AXI_WVALID =1'b0;
        AXI_WDATA  = 'h0;
    end // if
    end // always
    // synthesis translate_off
    always @ ( posedge ACLK) begin
        if (command!=MOVER_COMMAND_FILL[3:0]) begin
            if ((AXI_WVALID==1'b1)&&(AXI_WREADY==1'b1)) begin
                 if (AXI_WSTRB!==(pop_rd_STRB<<reg_offset)) begin
                     $display("%0t %m ERROR strobe mis-match.", $time);
                 end
            end
        end
    end
    // synthesis translate_on
    //--------------------------------------------------------------------------
    // get AWSIZE from the number of bytes that is 1 to AXI_WIDTH_DS.
    function [2:0] func_get_awsize;
    input [AXI_WIDTH_DSB:0] bytes;
    begin
        case (bytes)
        'h01: func_get_awsize = 3'h0;
        'h02: func_get_awsize = 3'h1;
        'h03: func_get_awsize = 3'h1;
        'h04: func_get_awsize = 3'h2;
        'h05: func_get_awsize = 3'h2;
        'h06: func_get_awsize = 3'h2;
        'h07: func_get_awsize = 3'h2;
        'h08: func_get_awsize = 3'h3;
        'h09: func_get_awsize = 3'h3;
        'h0A: func_get_awsize = 3'h3;
        'h0B: func_get_awsize = 3'h3;
        'h0C: func_get_awsize = 3'h3;
        'h0D: func_get_awsize = 3'h3;
        'h0E: func_get_awsize = 3'h3;
        'h0F: func_get_awsize = 3'h3;
        'h10: func_get_awsize = 3'h4;
        default: begin
                 func_get_awsize = 3'h0;
                 // synthesis translate_off
                 $display("%0t %m ERROR size error.", $time);
                 // synthesis translate_on
                 end
        endcase
    end
    endfunction
    //--------------------------------------------------------------------------
    // get AWSIZE from the number of bytes that is 1 to AXI_WIDTH_DS.
    function [2:0] func_get_awsize_misaligned;
    input [AXI_WIDTH_DSB:0] bytes;
    input [AXI_WIDTH_DSB-1:0] offset;
    begin
        if (offset[0]==1'b1) begin
            func_get_awsize_misaligned = 3'h0; // one-byte
        end else begin
            if (AXI_WIDTH_DS==4) begin // 32-bit data
                // offset can be 2
                // bytes can be 1, 2, 3, 4
                if (bytes==1) func_get_awsize_misaligned = 3'h0; // one-byte
                else func_get_awsize_misaligned = 3'h1; // two-byte
            end else if (AXI_WIDTH_DS==8) begin // 64-bit data
                // offset can be 2, 4, 6
                // bytes can be 1, 2, 3, 4, 5, 6, 7, 8
                if ((bytes>=4)&&(offset==4)) func_get_awsize_misaligned = 3'h2; // four-byte
                else if (bytes>=2) func_get_awsize_misaligned = 3'h1; // two-byte
                else func_get_awsize_misaligned = 3'h0; // one-byte
            end else if (AXI_WIDTH_DS==16) begin // 128-bit data
                // offset can be 2, 4, 6, 8, 10, 12, 14
                // bytes can be 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
                if ((bytes>=8)&&(offset==8)) func_get_awsize_misaligned = 3'h3; // eight-byte
                else if ((bytes>=4)&&((offset==4)||(offset==8)||(offset==12))) func_get_awsize_misaligned = 3'h2; // four-byte
                else if (bytes>=2) func_get_awsize_misaligned = 3'h1; // two-byte
                else func_get_awsize_misaligned = 3'h0; // one-byte
            end else if (AXI_WIDTH_DS==32) begin // 256-bit data
                // offset can be 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30
                // bytes can be 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, ...
                if ((bytes>=16)&&(offset==16)) func_get_awsize_misaligned = 3'h4; // 16-byte
                else if ((bytes>=8)&&(offset==8)) func_get_awsize_misaligned = 3'h3; // eight-byte
                else if ((bytes>=4)&&((offset==4)||(offset==8)||(offset==12)||(offset==16)||(offset==20)||(offset==24)||(offset==28))) func_get_awsize_misaligned = 3'h2; // four-byte
                else if (bytes>=2) func_get_awsize_misaligned = 3'h1; // two-byte
                else func_get_awsize_misaligned = 3'h0; // one-byte
            end else begin
                func_get_awsize_misaligned = 3'h0; // one-byte
            end
        end
    end
    endfunction
    //--------------------------------------------------------------------------
    function [AXI_WIDTH_DSB:0] func_get_bnum;
    input [AXI_WIDTH_DS-1:0] strb;
    integer idx;
    integer num;
    begin
        num = 0;
        for (idx=0; idx<AXI_WIDTH_DS; idx=idx+1) begin
           //if (strb[idx]==1'b1) num = num + 1;
             num = num + strb[idx];
        end
        func_get_bnum = num[AXI_WIDTH_DSB:0];
    end
    endfunction
    //--------------------------------------------------------------------------
    function [AXI_WIDTH_DSB+1:0] func_get_bnum_long;
    input [AXI_WIDTH_DS*2-1:0] strb;
    integer idx;
    integer num;
    begin
        num = 0;
        for (idx=0; idx<(AXI_WIDTH_DS*2); idx=idx+1) begin
           //if (strb[idx]==1'b1) num = num + 1;
             num = num + strb[idx];
        end
        func_get_bnum_long = num[AXI_WIDTH_DSB+1:0];
    end
    endfunction
    //--------------------------------------------------------------------------
    function [AXI_WIDTH_DS-1:0] func_get_wstrb;
       input [AXI_WIDTH_DSB-1:0] offset;
       input [2:0] size; // AxSIZE format
    begin
       case (size)
       3'b000: func_get_wstrb = {  1{1'b1}}<<offset;
       3'b001: func_get_wstrb = {  2{1'b1}}<<offset;
       3'b010: func_get_wstrb = {  4{1'b1}}<<offset;
       3'b011: func_get_wstrb = {  8{1'b1}}<<offset;
       3'b100: func_get_wstrb = { 16{1'b1}}<<offset;
       3'b101: func_get_wstrb = { 32{1'b1}}<<offset;
       3'b110: func_get_wstrb = { 64{1'b1}}<<offset;
       3'b111: func_get_wstrb = {128{1'b1}}<<offset;
       default:func_get_wstrb = 0;
       endcase
    end
    endfunction
    //--------------------------------------------------------------------------
    // justified input justified output
    // |<-- push ---------------->|      |<--- pop ---------------->|
    // --+--+--+--+    --+--+--+--+      --+--+--+--+    --+--+--+--+
    //   |0 |1 |0 |      |0 |0 |1 |        |0 |1 |1 |      |0 |1 |0 |
    // --+--+--+--+    --+--+--+--+      --+--+--+--+    --+--+--+--+
    //   |0 |1 |0 |      |0 |1 |1 |        |0 |1 |1 |      |1 |1 |0 |
    // --+--+--+--+ ==>--+--+--+--+      --+--+--+--+ ==>--+--+--+--+
    //   |1 |1 |0 |      |0 |1 |1 |        |0 |1 |1 |      |1 |1 |1 |
    // --+--+--+--+    --+--+--+--+      --+--+--+--+    --+--+--+--+
    //   |1 |1 |1 |      |0 |1 |1 |        |1 |1 |1 |      |1 |1 |1 |
    // --+--+--+--+    --+--+--+--+      --+--+--+--+    --+--+--+--+
    //               |<====== hidden in the FIFFO ====>|
    mover_2d_fifo_sync_merger_pop #(.FDW(AXI_WIDTH_DA))
    u_pop (
          .rstn     ( ARESETn      )
        , .clr      ( init         )
        , .clk      ( ACLK         )
        , .wr_rdy   ( pop_wr_READY )
        , .wr_vld   ( pop_wr_VALID )
        , .wr_data  ( pop_wr_DATA  )
        , .wr_strb  ( pop_wr_STRB  )
        , .wr_last  ( pop_wr_LAST  )
        , .rd_rdy   ( pop_rd_READY )
        , .rd_vld   ( pop_rd_VALID )
        , .rd_data  ( pop_rd_DATA  )
        , .rd_strb  ( pop_rd_STRB  )
        , .rd_last  ( pop_rd_LAST  )
        , .rd_sreq  ( pop_rd_SREQ  ) // the bit-pattern to request bytes
    );
    assign fifo_EMPTY=1'b1;
    assign fifo_FULL =1'b0;
    //--------------------------------------------------------------------------
    assign IN_READY        = (activ_func=='h0) ? pop_wr_READY : activ_in_ready;
    assign activ_in_valid  = (activ_func=='h0) ? 1'b0 : IN_VALID   ;
    assign activ_in_data   = (activ_func=='h0) ? 1'b0 : IN_DATA    ;
    assign activ_in_strb   = (activ_func=='h0) ? 1'b0 : IN_STRB    ;
    assign activ_in_last   = (activ_func=='h0) ? 1'b0 : IN_LAST    ;
    assign activ_out_ready = (activ_func=='h0) ? 1'b0 : pop_wr_READY;
    //--------------------------------------------------------------------------
    assign pop_wr_VALID= (activ_func=='h0) ? IN_VALID : activ_out_valid;
    assign pop_wr_DATA = (activ_func=='h0) ? IN_DATA  : activ_out_data ;
    assign pop_wr_STRB = (activ_func=='h0) ? IN_STRB  : activ_out_strb ;
    assign pop_wr_LAST = (activ_func=='h0) ? IN_LAST  : activ_out_last ;
    //--------------------------------------------------------------------------
    generate
    genvar gv;
    for (gv=0; gv<NUM; gv=gv+1) begin : BLK_GV
        mover_2d_activation #(.DATA_TYPE(DATA_TYPE)
                             ,.DATA_WIDTH(DATA_WIDTH)
                             `ifdef DATA_FIXED_POINT
                             ,.DATA_WIDTH_Q=(DATA_WIDTH_Q)
                             `endif
                             ,.USER_WIDTH(DATA_BYTES)
                             ,.ACTIV_FUNC_BYPASS    (ACTIV_FUNC_BYPASS    )
                             ,.ACTIV_FUNC_RELU      (ACTIV_FUNC_RELU      )
                             ,.ACTIV_FUNC_LEAKY_RELU(ACTIV_FUNC_LEAKY_RELU)
                             ,.ACTIV_FUNC_SIGMOID   (ACTIV_FUNC_SIGMOID   )
                             ,.ACTIV_FUNC_TANH      (ACTIV_FUNC_TANH      )
                             )
        u_activ (
              .RESET_N     ( ARESETn      )
            , .CLK         ( ACLK         )
            , .ACTIV_FUNC  ( activ_func   )
            , .ACTIV_PARAM ( activ_param  )
            , .IN_READY    ( activ_in_ready_part [gv]                          )
            , .IN_VALID    ( activ_in_valid                                    )
            , .IN_DATA     ( activ_in_data       [gv*DATA_WIDTH +: DATA_WIDTH] )
            , .IN_USER     ( activ_in_strb       [gv*DATA_BYTES +: DATA_BYTES] )
            , .IN_LAST     ( activ_in_last                                     )
            , .OUT_READY   ( activ_out_ready                                   )
            , .OUT_VALID   ( activ_out_valid_part[gv]                          )
            , .OUT_DATA    ( activ_out_data      [gv*DATA_WIDTH +: DATA_WIDTH] )
            , .OUT_USER    ( activ_out_strb      [gv*DATA_BYTES +: DATA_BYTES] )
            , .OUT_LAST    ( activ_out_last_part [gv]                          )
        );
    end // for
    endgenerate
    //--------------------------------------------------------------------------
endmodule

//------------------------------------------------------------------------------
// Revision history
//
// 2021.11.09: 'num_bytes' bit-width updated to be sufficient to hold number.
//             'func_get_arsize/awsize_misaligned()' updated.
// 2021.06.10: Started by Ando Ki (andoki@gmail.com)
//------------------------------------------------------------------------------
