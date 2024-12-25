//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All right reserved.
//------------------------------------------------------------------------------
// VERSION: 2021.11.06.
//------------------------------------------------------------------------------
// Mover 2D
//------------------------------------------------------------------------------
`ifdef VIVADO
`define DBG_MOVER (* mark_debug="true" *)
`else
`define DBG_MOVER
`endif

`include "mover_2d_csr.v"
`include "mover_2d_control.v"
`include "mover_2d_sync.v"

module mover_2d
     #(parameter APB_WIDTH_AD =32  // address width
               , APB_WIDTH_DA =32  // data width
               , M_AXI_WIDTH_ID =4   // ID width in bits
               , M_AXI_WIDTH_AD =32  // address width
               , M_AXI_WIDTH_DA =32  // data width
               , M_AXI_WIDTH_DS =(M_AXI_WIDTH_DA/8)
               , DATA_TYPE      ="INTEGER" // "INTEGER", "FLOATING_POINT", "FIXED_POINT"
               , DATA_WIDTH     =32 // bit-width of an item
               `ifdef DATA_FIXED_POINT
               , DATA_WIDTH_Q=(DATA_WIDTH/2) // fractional bits
               `endif
               , SRC_FIFO_DEPTH   =16 // fifo for input
               , RESULT_FIFO_DEPTH=16 // fifo for writing result
               , PROFILE_CNT_WIDTH=32,
       parameter [3:0] MOVER_COMMAND_NOP      = 4'h0,
       parameter [3:0] MOVER_COMMAND_FILL     = 4'h1,
       parameter [3:0] MOVER_COMMAND_COPY     = 4'h2,
       parameter [3:0] MOVER_COMMAND_RESIDUAL = 4'h3,// point-to-point adder
       parameter [3:0] MOVER_COMMAND_CONCAT0  = 4'h4,
       parameter [3:0] MOVER_COMMAND_CONCAT1  = 4'h5,
       parameter [3:0] MOVER_COMMAND_TRANSPOSE= 4'h6,
       parameter [3:0] ACTIV_FUNC_BYPASS    =4'h0,
       parameter [3:0] ACTIV_FUNC_RELU      =4'h1,
       parameter [3:0] ACTIV_FUNC_LEAKY_RELU=4'h2,
       parameter [3:0] ACTIV_FUNC_SIGMOID   =4'h3, // not yet
       parameter [3:0] ACTIV_FUNC_TANH      =4'h4 // not yet
               )
(
       input   wire                         PRESETn
     , input   wire                         PCLK
     , input   wire                         S_APB_PSEL
     , input   wire                         S_APB_PENABLE
     , input   wire [APB_WIDTH_AD-1:0]      S_APB_PADDR
     , input   wire                         S_APB_PWRITE
     , output  wire [APB_WIDTH_DA-1:0]      S_APB_PRDATA
     , input   wire [APB_WIDTH_DA-1:0]      S_APB_PWDATA
     , output  wire                         S_APB_PREADY
     , output  wire                         S_APB_PSLVERR
     // master port for result (write-only)
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
     // master port for source (read-only)
     , output  wire  [M_AXI_WIDTH_ID-1:0]   M_AXI_SRC_ARID
     , output  wire  [M_AXI_WIDTH_AD-1:0]   M_AXI_SRC_ARADDR
     , output  wire  [ 7:0]                 M_AXI_SRC_ARLEN
     , output  wire  [ 2:0]                 M_AXI_SRC_ARSIZE
     , output  wire  [ 1:0]                 M_AXI_SRC_ARBURST
     , output  wire                         M_AXI_SRC_ARVALID
     , input   wire                         M_AXI_SRC_ARREADY
     , input   wire  [M_AXI_WIDTH_ID-1:0]   M_AXI_SRC_RID
     , input   wire  [M_AXI_WIDTH_DA-1:0]   M_AXI_SRC_RDATA
     , input   wire  [ 1:0]                 M_AXI_SRC_RRESP
     , input   wire                         M_AXI_SRC_RLAST
     , input   wire                         M_AXI_SRC_RVALID
     , output  wire                         M_AXI_SRC_RREADY
     // 
     , output wire                          interrupt // interrupt to get attention
);
    //--------------------------------------------------------------------------
    assign S_APB_PREADY=1'b1;
    assign S_APB_PSLVERR=1'b0;
    //--------------------------------------------------------------------------
    wire [ 3:0]                command;

    wire                       sourceA_go, sourceA_go_sync;
    wire                       sourceA_done, sourceA_done_sync;// read-done
    wire [M_AXI_WIDTH_AD-1:0]  sourceA_address;
    wire [15:0]                sourceA_width;// num of items in row
    wire [15:0]                sourceA_height;
    wire [31:0]                sourceA_items;
    wire [ 7:0]                sourceA_leng;// AxLENG format

    wire                       sourceB_go, sourceB_go_sync;
    wire                       sourceB_done, sourceB_done_sync;// read-done
    wire [M_AXI_WIDTH_AD-1:0]  sourceB_address;
    wire [15:0]                sourceB_width;// num of items in row
    wire [15:0]                sourceB_height;
    wire [31:0]                sourceB_items;
    wire [ 7:0]                sourceB_leng;// AxLENG format

    wire                       result_go, result_go_sync;
    wire                       result_done, result_done_sync;// read-done
    wire [M_AXI_WIDTH_AD-1:0]  result_address;
    wire [15:0]                result_width;// num of items in row
    wire [15:0]                result_height;
    wire [31:0]                result_items;// num of items whole
    wire [ 7:0]                result_leng;// AxLENG format

    wire [DATA_WIDTH-1:0]      fill_value ;
    wire [ 3:0]                activ_func ;
    wire [DATA_WIDTH-1:0]      activ_param;

    wire                       mover_init, mover_init_sync;
    wire                       mover_ready, mover_ready_sync;

    wire                         profile_init, profile_init_sync;
    wire                         profile_snapshot, profile_snapshot_sync;
    reg                          profile_done=1'b0;
    wire                         profile_done_sync;
    wire [PROFILE_CNT_WIDTH-1:0] profile_residual_overflow;
    wire [PROFILE_CNT_WIDTH-1:0] profile_cnt_read;
    wire [PROFILE_CNT_WIDTH-1:0] profile_cnt_write;
    reg  [PROFILE_CNT_WIDTH-1:0] profile_residual_overflow_reg='h0;
    reg  [PROFILE_CNT_WIDTH-1:0] profile_cnt_read_reg='h0;
    reg  [PROFILE_CNT_WIDTH-1:0] profile_cnt_write_reg='h0;
    //--------------------------------------------------------------------------
    mover_2d_control #(.AXI_WIDTH_ID      (M_AXI_WIDTH_ID   )
                      ,.AXI_WIDTH_AD      (M_AXI_WIDTH_AD   )
                      ,.AXI_WIDTH_DA      (M_AXI_WIDTH_DA   )
                      ,.DATA_TYPE         (DATA_TYPE        )
                      ,.DATA_WIDTH        (DATA_WIDTH       )
                      ,.SRC_FIFO_DEPTH    (SRC_FIFO_DEPTH   )
                      ,.RESULT_FIFO_DEPTH (RESULT_FIFO_DEPTH)
                      ,.PROFILE_CNT_WIDTH (PROFILE_CNT_WIDTH)
                      ,.MOVER_COMMAND_NOP       (MOVER_COMMAND_NOP      )
                      ,.MOVER_COMMAND_FILL      (MOVER_COMMAND_FILL     )
                      ,.MOVER_COMMAND_COPY      (MOVER_COMMAND_COPY     )
                      ,.MOVER_COMMAND_RESIDUAL  (MOVER_COMMAND_RESIDUAL )
                      ,.MOVER_COMMAND_CONCAT0   (MOVER_COMMAND_CONCAT0  )
                      ,.MOVER_COMMAND_CONCAT1   (MOVER_COMMAND_CONCAT1  )
                      ,.MOVER_COMMAND_TRANSPOSE (MOVER_COMMAND_TRANSPOSE)
                      ,.ACTIV_FUNC_BYPASS    ( ACTIV_FUNC_BYPASS     )
                      ,.ACTIV_FUNC_RELU      ( ACTIV_FUNC_RELU       )
                      ,.ACTIV_FUNC_LEAKY_RELU( ACTIV_FUNC_LEAKY_RELU )
                      ,.ACTIV_FUNC_SIGMOID   ( ACTIV_FUNC_SIGMOID    )
                      ,.ACTIV_FUNC_TANH      ( ACTIV_FUNC_TANH       )
                      )
    u_control (
          .ARESETn           ( ARESETn           )
        , .ACLK              ( ACLK              )
        , .M_AXI_SRC_ARID    ( M_AXI_SRC_ARID    )
        , .M_AXI_SRC_ARADDR  ( M_AXI_SRC_ARADDR  )
        , .M_AXI_SRC_ARLEN   ( M_AXI_SRC_ARLEN   )
        , .M_AXI_SRC_ARSIZE  ( M_AXI_SRC_ARSIZE  )
        , .M_AXI_SRC_ARBURST ( M_AXI_SRC_ARBURST )
        , .M_AXI_SRC_ARVALID ( M_AXI_SRC_ARVALID )
        , .M_AXI_SRC_ARREADY ( M_AXI_SRC_ARREADY )
        , .M_AXI_SRC_RID     ( M_AXI_SRC_RID     )
        , .M_AXI_SRC_RDATA   ( M_AXI_SRC_RDATA   )
        , .M_AXI_SRC_RRESP   ( M_AXI_SRC_RRESP   )
        , .M_AXI_SRC_RLAST   ( M_AXI_SRC_RLAST   )
        , .M_AXI_SRC_RVALID  ( M_AXI_SRC_RVALID  )
        , .M_AXI_SRC_RREADY  ( M_AXI_SRC_RREADY  )
        , .M_AXI_RST_AWID    ( M_AXI_RST_AWID    )
        , .M_AXI_RST_AWADDR  ( M_AXI_RST_AWADDR  )
        , .M_AXI_RST_AWLEN   ( M_AXI_RST_AWLEN   )
        , .M_AXI_RST_AWSIZE  ( M_AXI_RST_AWSIZE  )
        , .M_AXI_RST_AWBURST ( M_AXI_RST_AWBURST )
        , .M_AXI_RST_AWVALID ( M_AXI_RST_AWVALID )
        , .M_AXI_RST_AWREADY ( M_AXI_RST_AWREADY )
        , .M_AXI_RST_WDATA   ( M_AXI_RST_WDATA   )
        , .M_AXI_RST_WSTRB   ( M_AXI_RST_WSTRB   )
        , .M_AXI_RST_WLAST   ( M_AXI_RST_WLAST   )
        , .M_AXI_RST_WVALID  ( M_AXI_RST_WVALID  )
        , .M_AXI_RST_WREADY  ( M_AXI_RST_WREADY  )
        , .M_AXI_RST_BID     ( M_AXI_RST_BID     )
        , .M_AXI_RST_BRESP   ( M_AXI_RST_BRESP   )
        , .M_AXI_RST_BVALID  ( M_AXI_RST_BVALID  )
        , .M_AXI_RST_BREADY  ( M_AXI_RST_BREADY  )
        , .command           ( command           )
        , .sourceA_go        ( sourceA_go_sync   )
        , .sourceA_done      ( sourceA_done      )
        , .sourceA_address   ( sourceA_address   )
        , .sourceA_width     ( sourceA_width     )
        , .sourceA_height    ( sourceA_height    )
        , .sourceA_items     ( sourceA_items     )
        , .sourceA_leng      ( sourceA_leng      )
        , .sourceB_go        ( sourceB_go_sync   )
        , .sourceB_done      ( sourceB_done      )
        , .sourceB_address   ( sourceB_address   )
        , .sourceB_width     ( sourceB_width     )
        , .sourceB_height    ( sourceB_height    )
        , .sourceB_items     ( sourceB_items     )
        , .sourceB_leng      ( sourceB_leng      )
        , .result_go         ( result_go_sync    )
        , .result_done       ( result_done       )
        , .result_address    ( result_address    )
        , .result_width      ( result_width      )
        , .result_height     ( result_height     )
        , .result_items      ( result_items      )
        , .result_leng       ( result_leng       )
        , .fill_value        ( fill_value        )
        , .activ_func        ( activ_func        )
        , .activ_param       ( activ_param       )
        , .mover_init        ( mover_init_sync   )
        , .mover_ready       ( mover_ready       )
        , .profile_init              ( profile_init_sync         )
        , .profile_residual_overflow ( profile_residual_overflow )
        , .profile_cnt_read          ( profile_cnt_read          )
        , .profile_cnt_write         ( profile_cnt_write         )
    );
    //--------------------------------------------------------------------------
    mover_2d_csr #(.APB_WIDTH_AD      (APB_WIDTH_AD      )
                  ,.APB_WIDTH_DA      (APB_WIDTH_DA      )
                  ,.AXI_WIDTH_AD      (M_AXI_WIDTH_AD    )
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
         .PRESETn           ( PRESETn       )
       , .PCLK              ( PCLK          )
       , .PSEL              ( S_APB_PSEL    )
       , .PENABLE           ( S_APB_PENABLE )
       , .PADDR             ( S_APB_PADDR   )
       , .PWRITE            ( S_APB_PWRITE  )
       , .PRDATA            ( S_APB_PRDATA  )
       , .PWDATA            ( S_APB_PWDATA  )
       , .command           ( command           )
       , .srcA_go           ( sourceA_go        )
       , .srcA_done         ( sourceA_done_sync )
       , .srcA_address      ( sourceA_address   )
       , .srcA_width        ( sourceA_width     )
       , .srcA_height       ( sourceA_height    )
       , .srcA_items        ( sourceA_items     )
       , .srcA_leng         ( sourceA_leng      )
       , .srcB_go           ( sourceB_go        )
       , .srcB_done         ( sourceB_done_sync )
       , .srcB_address      ( sourceB_address   )
       , .srcB_width        ( sourceB_width     )
       , .srcB_height       ( sourceB_height    )
       , .srcB_items        ( sourceB_items     )
       , .srcB_leng         ( sourceB_leng      )
       , .result_go         ( result_go         )
       , .result_done       ( result_done_sync  )
       , .result_address    ( result_address    )
       , .result_width      ( result_width      )
       , .result_height     ( result_height     )
       , .result_items      ( result_items      )
       , .result_leng       ( result_leng       )
       , .fill_value        ( fill_value        )
       , .activ_func        ( activ_func        )
       , .activ_param       ( activ_param       )
       , .mover_init        ( mover_init        )
       , .mover_ready       ( mover_ready_sync  )
       , .profile_init              ( profile_init              )
       , .profile_snapshot          ( profile_snapshot          )
       , .profile_done              ( profile_done_sync         )
       , .profile_residual_overflow ( profile_residual_overflow )
       , .profile_cnt_read          ( profile_cnt_read          )
       , .profile_cnt_write         ( profile_cnt_write         )
       , .interrupt         ( interrupt         )
    );
    //--------------------------------------------------------------------------
    mover_2d_sync u_sync_init (
          .reset_n ( ARESETn          )
        , .clk     ( ACLK             )
        , .sig_in  ( mover_init      )
        , .sig_out ( mover_init_sync )
    );
    mover_2d_sync u_sync_profile_init (
          .reset_n ( ARESETn           )
        , .clk     ( ACLK              )
        , .sig_in  ( profile_init      )
        , .sig_out ( profile_init_sync )
    );
    mover_2d_sync u_sync_profile_snapshot (
          .reset_n ( ARESETn               )
        , .clk     ( ACLK                  )
        , .sig_in  ( profile_snapshot      )
        , .sig_out ( profile_snapshot_sync )
    );
    mover_2d_sync u_sync_sourceA_go (
          .reset_n ( ARESETn      )
        , .clk     ( ACLK         )
        , .sig_in  ( sourceA_go      )
        , .sig_out ( sourceA_go_sync )
    );
    mover_2d_sync u_sync_sourceB_go (
          .reset_n ( ARESETn       )
        , .clk     ( ACLK          )
        , .sig_in  ( sourceB_go      )
        , .sig_out ( sourceB_go_sync )
    );
    mover_2d_sync u_sync_result_go (
          .reset_n ( ARESETn        )
        , .clk     ( ACLK           )
        , .sig_in  ( result_go      )
        , .sig_out ( result_go_sync )
    );
    //--------------------------------------------------------------------------
    mover_2d_sync u_sync_ready (
          .reset_n ( PRESETn          )
        , .clk     ( PCLK             )
        , .sig_in  ( mover_ready      )
        , .sig_out ( mover_ready_sync )
    );
    mover_2d_sync u_sync_profile_done ( // snapshot done
          .reset_n ( PRESETn           )
        , .clk     ( PCLK              )
        , .sig_in  ( profile_done      )
        , .sig_out ( profile_done_sync )
    );
    mover_2d_sync u_sync_sourceA_done (
          .reset_n ( PRESETn        )
        , .clk     ( PCLK           )
        , .sig_in  ( sourceA_done      )
        , .sig_out ( sourceA_done_sync )
    );
    mover_2d_sync u_sync_sourceB_done (
          .reset_n ( PRESETn         )
        , .clk     ( PCLK            )
        , .sig_in  ( sourceB_done      )
        , .sig_out ( sourceB_done_sync )
    );
    mover_2d_sync u_sync_result_done (
          .reset_n ( PRESETn          )
        , .clk     ( PCLK             )
        , .sig_in  ( result_done      )
        , .sig_out ( result_done_sync )
    );
    //--------------------------------------------------------------------------
    always @ (posedge ACLK or negedge ARESETn) begin
    if (ARESETn==1'b0) begin
        profile_done                 <=1'b0;
        profile_residual_overflow_reg<= 'h0; // get valid value when profile_done
        profile_cnt_read_reg         <= 'h0; // get valid value when profile_done
        profile_cnt_write_reg        <= 'h0; // get valid value when profile_done
    end else begin
        if ((profile_done==1'b0)&&(profile_snapshot_sync==1'b1)) begin
            profile_residual_overflow_reg<= profile_residual_overflow;
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
