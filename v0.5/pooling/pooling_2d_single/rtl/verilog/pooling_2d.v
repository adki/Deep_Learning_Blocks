//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All right reserved.
//------------------------------------------------------------------------------
// VERSION: 2021.11.06.
//------------------------------------------------------------------------------
// Pooling 2D
//------------------------------------------------------------------------------
//            +-------------+                  
//            | control     |                   
//            |  --+--+--+  |                   +-------------+
//            |    |  |  |  |  pool_core_ready  |             |
// AXI4<=====>|  --+--+--+  |<------------------| core        |
//            |  +--+--+--  |                   |             |
//            |  |  |  |    |<----------+------>|             |
//            |  +--+--+--  |          /|\      |             |
//            +-------------+           |       +-------------+  
//               /|\    | pool_ready    |             /|\
//                |     |               | pool_init    |
//                |     |               |              |
//                |     |        +-----------+         |
//                |     |        |           |         |
//                |     +------->| csr       |         |
//                |              |           |         |
// APB<===========|=============>|           |         |
//                |              +-----------+         |
//                |                 /|\                |
//                |                  |                 |
// ARESETn -------+------------------+-----------------+
//
//------------------------------------------------------------------------------
`ifdef VIVADO
`define DBG_POOL (* mark_debug="true" *)
`else
`define DBG_POOL
`endif

`include "pooling_2d_csr.v"
`include "pooling_max_core.v"
`include "pooling_2d_control.v"
`include "pooling_2d_sync.v"

module pooling_2d
     #(parameter APB_WIDTH_AD   =32  // address width
               , APB_WIDTH_DA   =32  // data width
               , M_AXI_WIDTH_ID =4   // ID width in bits
               , M_AXI_WIDTH_AD =32  // address width
               , M_AXI_WIDTH_DA =32  // data width
               , M_AXI_WIDTH_DS =(M_AXI_WIDTH_DA/8)
               , DATA_TYPE      ="INTEGER" // "INTEGER", "FLOATING_POINT", "FIXED_POINT"
               , DATA_WIDTH     =32 // bit-width of an item
               `ifdef DATA_FIXED_POINT
               , DATA_WIDTH_Q=(DATA_WIDTH/2) // fractional bits
               `endif
               , KERNEL_MAX_SIZE   =5
               , FEATURE_FIFO_DEPTH=1<<$clog2(KERNEL_MAX_SIZE*2) // fifo for each pooling core
               , RESULT_FIFO_DEPTH =1<<$clog2(KERNEL_MAX_SIZE*2) // fifo for writing result
               , PROFILE_CNT_WIDTH =32,
       parameter [3:0] POOLING_NOP = 4'h0,
       parameter [3:0] POOLING_MAX = 4'h1,
       parameter [3:0] POOLING_AVG = 4'h2 
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
     // master port for feature (read-only)
     , output  wire  [M_AXI_WIDTH_ID-1:0]   M_AXI_FTU_ARID
     , output  wire  [M_AXI_WIDTH_AD-1:0]   M_AXI_FTU_ARADDR
     , output  wire  [ 7:0]                 M_AXI_FTU_ARLEN
     , output  wire  [ 2:0]                 M_AXI_FTU_ARSIZE
     , output  wire  [ 1:0]                 M_AXI_FTU_ARBURST
     , output  wire                         M_AXI_FTU_ARVALID
     , input   wire                         M_AXI_FTU_ARREADY
     , input   wire  [M_AXI_WIDTH_ID-1:0]   M_AXI_FTU_RID
     , input   wire  [M_AXI_WIDTH_DA-1:0]   M_AXI_FTU_RDATA
     , input   wire  [ 1:0]                 M_AXI_FTU_RRESP
     , input   wire                         M_AXI_FTU_RLAST
     , input   wire                         M_AXI_FTU_RVALID
     , output  wire                         M_AXI_FTU_RREADY
     // 
     , output wire                          interrupt // interrupt to get attention
);
    //--------------------------------------------------------------------------
    assign S_APB_PREADY=1'b1;
    assign S_APB_PSLVERR=1'b0;
    //--------------------------------------------------------------------------
    localparam DATA_BYTES     =(DATA_WIDTH/8)
             , FEATURE_FIFO_AW=$clog2(FEATURE_FIFO_DEPTH   )
             , RESULT_FIFO_AW =$clog2(RESULT_FIFO_DEPTH );
    //--------------------------------------------------------------------------
    wire [ 3:0]                command;

    wire [ 3:0]                kernel_width;// num of items in row
    wire [ 3:0]                kernel_height;

    wire                       feature_go, feature_go_sync;
    wire                       feature_done, feature_done_sync;// read-done
    wire [M_AXI_WIDTH_AD-1:0]  feature_address;
    wire [15:0]                feature_width;// num of items in row
    wire [15:0]                feature_height;
    wire [31:0]                feature_items;
    wire [ 3:0]                feature_padding_pre;
    wire [ 3:0]                feature_padding_post;
    wire [ 3:0]                feature_stride;
    wire [ 7:0]                feature_leng;// AxLENG format
    wire [15:0]                feature_channel;

    wire                       result_go, result_go_sync;
    wire                       result_done, result_done_sync;// read-done
    wire [M_AXI_WIDTH_AD-1:0]  result_address;
    wire [15:0]                result_width;// num of items in row
    wire [15:0]                result_height;
    wire [31:0]                result_items;// num of items whole
    wire [ 7:0]                result_leng;// AxLENG format

    wire                       pool_init, pool_init_sync;
    wire                       pool_ready, pool_ready_sync;
    wire                       pool_core_ready;

    wire                         profile_init, profile_init_sync;
    wire                         profile_snapshot, profile_snapshot_sync;
    reg                          profile_done=1'b0;
    wire                         profile_done_sync;
    wire [PROFILE_CNT_WIDTH-1:0] profile_cnt_read;
    wire [PROFILE_CNT_WIDTH-1:0] profile_cnt_write;
    reg  [PROFILE_CNT_WIDTH-1:0] profile_cnt_read_reg='h0;
    reg  [PROFILE_CNT_WIDTH-1:0] profile_cnt_write_reg='h0;
    //--------------------------------------------------------------------------
    wire                     IO_FTU_READY;
    wire                     IO_FTU_VALID;
    wire [DATA_WIDTH-1:0]    IO_FTU_DATA ;
    wire                     IO_FTU_LAST ;
    wire                     IO_RST_READY;
    wire                     IO_RST_VALID;
    wire [DATA_WIDTH-1:0]    IO_RST_DATA ;
    wire                     IO_RST_LAST ;
    //--------------------------------------------------------------------------
    pooling_max_core #(.DATA_TYPE (DATA_TYPE )
                      ,.DATA_WIDTH(DATA_WIDTH)
                      `ifdef DATA_FIXED_POINT
                      ,.DATA_WIDTH_Q(DATA_WIDTH_Q) // fractional bits
                      `endif
                      )
    u_core (
         .RESET_N    ( ARESETn         )
       , .CLK        ( ACLK            )
       , .INIT       ( pool_init       ) // from controller
       , .READY      ( pool_core_ready ) // to controller
       , .IN_READY   ( IO_FTU_READY    )
       , .IN_VALID   ( IO_FTU_VALID    )
       , .IN_DATA    ( IO_FTU_DATA     )
       , .IN_LAST    ( IO_FTU_LAST     )
       , .OUT_READY  ( IO_RST_READY    )
       , .OUT_VALID  ( IO_RST_VALID    )
       , .OUT_DATA   ( IO_RST_DATA     )
       , .OUT_LAST   ( IO_RST_LAST     )
    );
    //--------------------------------------------------------------------------
    pooling_2d_control #(.AXI_WIDTH_ID      (M_AXI_WIDTH_ID    )
                        ,.AXI_WIDTH_AD      (M_AXI_WIDTH_AD    )
                        ,.AXI_WIDTH_DA      (M_AXI_WIDTH_DA    )
                        ,.DATA_WIDTH        (DATA_WIDTH        )
                        ,.FEATURE_FIFO_DEPTH(FEATURE_FIFO_DEPTH)
                        ,.RESULT_FIFO_DEPTH (RESULT_FIFO_DEPTH )
                        ,.PROFILE_CNT_WIDTH (PROFILE_CNT_WIDTH )
                        ,.POOLING_NOP(POOLING_NOP)
                        ,.POOLING_MAX(POOLING_MAX)
                        ,.POOLING_AVG(POOLING_AVG)
                        )
    u_control (
          .ARESETn               ( ARESETn              )
        , .ACLK                  ( ACLK                 )
        , .M_AXI_FTU_ARID        ( M_AXI_FTU_ARID       )
        , .M_AXI_FTU_ARADDR      ( M_AXI_FTU_ARADDR     )
        , .M_AXI_FTU_ARLEN       ( M_AXI_FTU_ARLEN      )
        , .M_AXI_FTU_ARSIZE      ( M_AXI_FTU_ARSIZE     )
        , .M_AXI_FTU_ARBURST     ( M_AXI_FTU_ARBURST    )
        , .M_AXI_FTU_ARVALID     ( M_AXI_FTU_ARVALID    )
        , .M_AXI_FTU_ARREADY     ( M_AXI_FTU_ARREADY    )
        , .M_AXI_FTU_RID         ( M_AXI_FTU_RID        )
        , .M_AXI_FTU_RDATA       ( M_AXI_FTU_RDATA      )
        , .M_AXI_FTU_RRESP       ( M_AXI_FTU_RRESP      )
        , .M_AXI_FTU_RLAST       ( M_AXI_FTU_RLAST      )
        , .M_AXI_FTU_RVALID      ( M_AXI_FTU_RVALID     )
        , .M_AXI_FTU_RREADY      ( M_AXI_FTU_RREADY     )
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
        , .OUT_FTU_READY         ( IO_FTU_READY         )
        , .OUT_FTU_VALID         ( IO_FTU_VALID         )
        , .OUT_FTU_DATA          ( IO_FTU_DATA          )
        , .OUT_FTU_LAST          ( IO_FTU_LAST          )
        , .IN_RST_READY          ( IO_RST_READY         )
        , .IN_RST_VALID          ( IO_RST_VALID         )
        , .IN_RST_DATA           ( IO_RST_DATA          )
        , .IN_RST_LAST           ( IO_RST_LAST          )
        , .command               ( command              )
        , .kernel_width          ( kernel_width         )
        , .kernel_height         ( kernel_height        )
        , .feature_go            ( feature_go_sync      )
        , .feature_done          ( feature_done         )
        , .feature_address       ( feature_address      )
        , .feature_width         ( feature_width        )
        , .feature_height        ( feature_height       )
        , .feature_items         ( feature_items        )
        , .feature_padding_pre   ( feature_padding_pre  )
        , .feature_padding_post  ( feature_padding_post )
        , .feature_stride        ( feature_stride       )
        , .feature_leng          ( feature_leng         )
        , .feature_channel       ( feature_channel      )
        , .result_go             ( result_go_sync       )
        , .result_done           ( result_done          )
        , .result_address        ( result_address       )
        , .result_width          ( result_width         )
        , .result_height         ( result_height        )
        , .result_items          ( result_items         )
        , .result_leng           ( result_leng          )
        , .pool_init             ( pool_init_sync       )
        , .pool_ready            ( pool_ready           )
        , .pool_core_ready       ( pool_core_ready      )
        , .progress_feature_items(                      )
        , .progress_result_items (                      )
        , .profile_init          ( profile_init_sync    )
        , .profile_cnt_read      ( profile_cnt_read     )
        , .profile_cnt_write     ( profile_cnt_write    )
    );
    //--------------------------------------------------------------------------
    pooling_2d_csr #(.APB_WIDTH_AD      (APB_WIDTH_AD      )
                    ,.APB_WIDTH_DA      (APB_WIDTH_DA      )
                    ,.AXI_WIDTH_AD      (M_AXI_WIDTH_AD    )
                    ,.DATA_TYPE         (DATA_TYPE         )
                    ,.DATA_WIDTH        (DATA_WIDTH        )
                    `ifdef DATA_FIXED_POINT
                    ,.DATA_WIDTH_Q      (DATA_WIDTH_Q      )
                    `endif
                    ,.FEATURE_FIFO_DEPTH(FEATURE_FIFO_DEPTH)
                    ,.RESULT_FIFO_DEPTH (RESULT_FIFO_DEPTH )
                    ,.PROFILE_CNT_WIDTH (PROFILE_CNT_WIDTH )
                    ,.POOLING_NOP(POOLING_NOP)
                    ,.POOLING_MAX(POOLING_MAX)
                    ,.POOLING_AVG(POOLING_AVG)
                    )
    u_csr (
         .PRESETn             ( PRESETn       )
       , .PCLK                ( PCLK          )
       , .PSEL                ( S_APB_PSEL    )
       , .PENABLE             ( S_APB_PENABLE )
       , .PADDR               ( S_APB_PADDR   )
       , .PWRITE              ( S_APB_PWRITE  )
       , .PRDATA              ( S_APB_PRDATA  )
       , .PWDATA              ( S_APB_PWDATA  )
       , .command             ( command              )
       , .kernel_width        ( kernel_width         )
       , .kernel_height       ( kernel_height        )
       , .feature_go          ( feature_go           )
       , .feature_done        ( feature_done_sync    )
       , .feature_address     ( feature_address      )
       , .feature_width       ( feature_width        )
       , .feature_height      ( feature_height       )
       , .feature_items       ( feature_items        )
       , .feature_padding_pre ( feature_padding_pre  )
       , .feature_padding_post( feature_padding_post )
       , .feature_stride      ( feature_stride       )
       , .feature_leng        ( feature_leng         )
       , .feature_channel     ( feature_channel      )
       , .result_go           ( result_go            )
       , .result_done         ( result_done_sync     )
       , .result_address      ( result_address       )
       , .result_width        ( result_width         )
       , .result_height       ( result_height        )
       , .result_items        ( result_items         )
       , .result_leng         ( result_leng          )
       , .pool_init           ( pool_init            )
       , .pool_ready          ( pool_ready_sync      )
       , .profile_init        ( profile_init         )
       , .profile_snapshot    ( profile_snapshot     )
       , .profile_done        ( profile_done_sync    )
       , .profile_cnt_read    ( profile_cnt_read_reg )
       , .profile_cnt_write   ( profile_cnt_write_reg)
       , .interrupt           ( interrupt            )
    );
    //--------------------------------------------------------------------------
    pooling_2d_sync u_sync_init (
          .reset_n ( ARESETn        )
        , .clk     ( ACLK           )
        , .sig_in  ( pool_init      )
        , .sig_out ( pool_init_sync )
    );
    pooling_2d_sync u_sync_profile_init (
          .reset_n ( ARESETn           )
        , .clk     ( ACLK              )
        , .sig_in  ( profile_init      )
        , .sig_out ( profile_init_sync )
    );
    pooling_2d_sync u_sync_profile_snapshot (
          .reset_n ( ARESETn               )
        , .clk     ( ACLK                  )
        , .sig_in  ( profile_snapshot      )
        , .sig_out ( profile_snapshot_sync )
    );
    pooling_2d_sync u_sync_feature_go (
          .reset_n ( ARESETn         )
        , .clk     ( ACLK            )
        , .sig_in  ( feature_go      )
        , .sig_out ( feature_go_sync )
    );
    pooling_2d_sync u_sync_result_go (
          .reset_n ( ARESETn        )
        , .clk     ( ACLK           )
        , .sig_in  ( result_go      )
        , .sig_out ( result_go_sync )
    );
    //--------------------------------------------------------------------------
    pooling_2d_sync u_sync_ready (
          .reset_n ( PRESETn         )
        , .clk     ( PCLK            )
        , .sig_in  ( pool_ready      )
        , .sig_out ( pool_ready_sync )
    );
    pooling_2d_sync u_sync_profile_done ( // snapshot done
          .reset_n ( PRESETn           )
        , .clk     ( PCLK              )
        , .sig_in  ( profile_done      )
        , .sig_out ( profile_done_sync )
    );
    pooling_2d_sync u_sync_feature_done (
          .reset_n ( PRESETn           )
        , .clk     ( PCLK              )
        , .sig_in  ( feature_done      )
        , .sig_out ( feature_done_sync )
    );
    pooling_2d_sync u_sync_result_done (
          .reset_n ( PRESETn          )
        , .clk     ( PCLK             )
        , .sig_in  ( result_done      )
        , .sig_out ( result_done_sync )
    );
    //--------------------------------------------------------------------------
    always @ (posedge ACLK or negedge ARESETn) begin
    if (ARESETn==1'b0) begin
        profile_done          <=1'b0;
        profile_cnt_read_reg  <= 'h0; // get valid value when profile_done
        profile_cnt_write_reg <= 'h0; // get valid value when profile_done
    end else begin
        if ((profile_done==1'b0)&&(profile_snapshot_sync==1'b1)) begin
            profile_cnt_read_reg  <= profile_cnt_read;
            profile_cnt_write_reg <= profile_cnt_write;
            profile_done          <= 1'b1;
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
