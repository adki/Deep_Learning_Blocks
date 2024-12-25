//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All right reserved.
//------------------------------------------------------------------------------
// VERSION: 2021.11.06.
//------------------------------------------------------------------------------
// Pooling 2D CSR
//------------------------------------------------------------------------------
module pooling_2d_csr
     #(parameter APB_WIDTH_AD =32        // address width
               , APB_WIDTH_DA =32        // data width
               , AXI_WIDTH_AD =32
               , DATA_TYPE="INTEGER" // "INTEGER", "FLOATING_POINT", "FIXED_POINT"
               , DATA_WIDTH     =32 // bit-width of a whole part
               `ifdef DATA_FIXED_POINT
               , DATA_WIDTH_Q=(DATA_WIDTH/2) // fractional bits
               `endif
               , FEATURE_FIFO_DEPTH=16
               , RESULT_FIFO_DEPTH =16
               , PROFILE_CNT_WIDTH =32,
       parameter [3:0] POOLING_NOP = 4'h0,
       parameter [3:0] POOLING_MAX = 4'h1,
       parameter [3:0] POOLING_AVG = 4'h2 
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
    , output wire [ 3:0]              command
    , output wire [ 3:0]              kernel_width // num of items in a row (column)
    , output wire [ 3:0]              kernel_height // num of items in a column
    , output wire                     feature_go
    , input  wire                     feature_done // read-done
    , output wire [AXI_WIDTH_AD-1:0]  feature_address
    , output wire [15:0]              feature_width // num of items in a row (column)
    , output wire [15:0]              feature_height // num of items in a column
    , output wire [31:0]              feature_items // feature_width*feature_height
    , output wire [ 3:0]              feature_padding_pre
    , output wire [ 3:0]              feature_padding_post
    , output wire [ 3:0]              feature_stride // (<=kernel_width)
    , output wire [ 7:0]              feature_leng // same format for AxLEN
    , output wire [15:0]              feature_channel // num of channels
    , output wire                     result_go
    , input  wire                     result_done // read-done
    , output wire [AXI_WIDTH_AD-1:0]  result_address
    , output wire [15:0]              result_width // num of items in a row (column)
    , output wire [15:0]              result_height // num of items in a column
    , output wire [31:0]              result_items // result_width*result_height
    , output wire [ 7:0]              result_leng // same format for AxLEN
    , output wire                     pool_init // synchronous reset except this CSR
    , input  wire                     pool_ready
    , output wire                           profile_init
    , output wire                           profile_snapshot
    , input  wire                           profile_done
    , input  wire  [PROFILE_CNT_WIDTH-1:0]  profile_cnt_read
    , input  wire  [PROFILE_CNT_WIDTH-1:0]  profile_cnt_write
    , output wire                     interrupt // interrupt to get attention
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
   pooling_2d_csr_core #(.T_ADDR_WID        (T_ADDR_WID        )
                        ,.APB_WIDTH_DA      (APB_WIDTH_DA      )
                        ,.AXI_WIDTH_AD      (AXI_WIDTH_AD      )
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
       .RESET_N   (PRESETn  )
     , .CLK       (PCLK     )
     , .T_ADDR    (T_ADDR   )
     , .T_WREN    (T_WREN   )
     , .T_RDEN    (T_RDEN   )
     , .T_WDATA   (T_WDATA  )
     , .T_RDATA   (T_RDATA  )
     , .command              ( command              )
     , .kernel_width         ( kernel_width         )
     , .kernel_height        ( kernel_height        )
     , .feature_go           ( feature_go           )
     , .feature_done         ( feature_done         )
     , .feature_address      ( feature_address      )
     , .feature_width        ( feature_width        )
     , .feature_height       ( feature_height       )
     , .feature_items        ( feature_items        )
     , .feature_padding_pre  ( feature_padding_pre  )
     , .feature_padding_post ( feature_padding_post )
     , .feature_stride       ( feature_stride       )
     , .feature_leng         ( feature_leng         )
     , .feature_channel      ( feature_channel      )
     , .result_go            ( result_go            )
     , .result_done          ( result_done          )
     , .result_address       ( result_address       )
     , .result_width         ( result_width         )
     , .result_height        ( result_height        )
     , .result_items         ( result_items         )
     , .result_leng          ( result_leng          )
     , .pool_init            ( pool_init            )
     , .pool_ready           ( pool_ready           )
     , .profile_init         ( profile_init         )
     , .profile_snapshot     ( profile_snapshot     )
     , .profile_done         ( profile_done         )
     , .profile_cnt_read     ( profile_cnt_read     )
     , .profile_cnt_write    ( profile_cnt_write    )
     , .interrupt            ( interrupt            )
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

module pooling_2d_csr_core
     #(parameter T_ADDR_WID  =8
               , APB_WIDTH_DA=32
               , AXI_WIDTH_AD=32
               , DATA_TYPE   ="INTEGER" // "INTEGER", "FLOATING_POINT", "FIXED_POINT"
               , DATA_WIDTH  =32 // bit-width of a whole part
               `ifdef DATA_FIXED_POINT
               , DATA_WIDTH_Q=(DATA_WIDTH/2) // fractional bits
               `endif
               , FEATURE_FIFO_DEPTH=16
               , RESULT_FIFO_DEPTH =16
               , PROFILE_CNT_WIDTH =32,
       parameter [3:0] POOLING_NOP = 4'h0,
       parameter [3:0] POOLING_MAX = 4'h1,
       parameter [3:0] POOLING_AVG = 4'h2 
               )
(
      input   wire                     RESET_N
    , input   wire                     CLK
    , input   wire [T_ADDR_WID-1:0]    T_ADDR
    , input   wire                     T_WREN
    , input   wire                     T_RDEN
    , input   wire [APB_WIDTH_DA-1:0]  T_WDATA
    , output  reg  [APB_WIDTH_DA-1:0]  T_RDATA
    //-------------------------------------------------------------------------
    , output wire [ 3:0]              command
    , output wire [ 3:0]              kernel_width // num of items in row
    , output wire [ 3:0]              kernel_height
    , output wire                     feature_go // auto clean
    , input  wire                     feature_done // read-done
    , output wire [AXI_WIDTH_AD-1:0]  feature_address
    , output wire [15:0]              feature_width // num of items in row
    , output wire [15:0]              feature_height
    , output wire [31:0]              feature_items
    , output wire [ 3:0]              feature_padding_pre
    , output wire [ 3:0]              feature_padding_post
    , output wire [ 3:0]              feature_stride
    , output wire [ 7:0]              feature_leng // AxLENG
    , output wire [15:0]              feature_channel // num of channels
    , output wire                     result_go // auto clean
    , input  wire                     result_done // read-done
    , output wire [AXI_WIDTH_AD-1:0]  result_address
    , output wire [15:0]              result_width // num of items in row
    , output wire [15:0]              result_height
    , output wire [31:0]              result_items// num of items whole
    , output wire [ 7:0]              result_leng // AxLENG
    , output wire                     pool_init // active-high synchronous reset except this CSR
                                                // auto clean
    , input  wire                           pool_ready
    , output reg                            profile_init // auto return 0
    , output reg                            profile_snapshot // auto return 0
    , input  wire                           profile_done
    , input  wire  [PROFILE_CNT_WIDTH-1:0]  profile_cnt_read
    , input  wire  [PROFILE_CNT_WIDTH-1:0]  profile_cnt_write
    , output wire                           interrupt // interrupt to get attention
);
   //---------------------------------------------------------------------------
   // CSR address
   localparam CSRA_VERSION       = 'h00
            , CSRA_CONTROL       = 'h10
            , CSRA_CONFIG        = 'h14
            , CSRA_CONFIG_FIFO   = 'h18

            , CSRA_COMMAND       = 'h20
            , CSRA_KNL_CFG       = 'h24

            , CSRA_FTU_ADDR_LOW  = 'h30
            , CSRA_FTU_ADDR_HIGH = 'h34
            , CSRA_FTU_CFG_SIZE  = 'h38
            , CSRA_FTU_CFG_KNL   = 'h3C
            , CSRA_FTU_ITEMS     = 'h40
            , CSRA_FTU_BURST     = 'h44
            , CSRA_FTU_CHANNEL   = 'h48

            , CSRA_RST_ADDR_LOW  = 'h50
            , CSRA_RST_ADDR_HIGH = 'h54
            , CSRA_RST_CFG_SIZE  = 'h58
            , CSRA_RST_ITEMS     = 'h5C
            , CSRA_RST_BURST     = 'h60

            , CSRA_PROFILE_CTL     = 'h70
            , CSRA_PROFILE_CYCLES  = 'h74 // num of cycles (x10)
            , CSRA_PROFILE_CNT_RD  = 'h78 // num of read
            , CSRA_PROFILE_CNT_WR  = 'h7C // num of write
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
   wire [31:0]              csr_version             =32'h20210610;
   reg                      csr_ctl_ip              =1'b0;
   reg                      csr_ctl_ie              =1'b0;
   reg                      csr_ctl_init            =1'b0;
   wire [15:0]              csr_data_type           =(DATA_TYPE=="FLOATING_POINT") ? swap("FP")
                                                    :(DATA_TYPE=="FIXED_POINT") ? swap("FX")
                                                    : swap("IT");
   reg  [ 3:0]              csr_command             = POOLING_NOP[3:0];
   reg  [ 3:0]              csr_kernel_width        = 'h0;
   reg  [ 3:0]              csr_kernel_height       = 'h0;
   reg                      csr_feature_go          =1'b0;
   wire                     csr_feature_done;
   reg  [AXI_WIDTH_AD-1:0]  csr_feature_address     = 'h0;
   reg  [15:0]              csr_feature_width       = 'h0;
   reg  [15:0]              csr_feature_height      = 'h0;
   reg  [31:0]              csr_feature_items       = 'h0;
   reg  [ 3:0]              csr_feature_padding_pre = 'h0; // padding 0
   reg  [ 3:0]              csr_feature_padding_post= 'h0; // padding 0
   reg  [ 3:0]              csr_feature_stride      = 'h1; // stride 1
   reg  [ 7:0]              csr_feature_leng        = 'h0; // 0 = length 1 (AxLEN format)
   reg  [15:0]              csr_feature_channel     = 'h0; // number of channel
   reg                      csr_result_go           =1'b0;
   wire                     csr_result_done;
   reg  [AXI_WIDTH_AD-1:0]  csr_result_address      = 'h0;
   reg  [15:0]              csr_result_width        = 'h0; // num of items of row
   reg  [15:0]              csr_result_height       = 'h0;
   reg  [31:0]              csr_result_items        = 'h0; // num of items whole
   reg  [ 7:0]              csr_result_leng         = 'h0; // 0 = length 1
   reg  [PROFILE_CNT_WIDTH-1:0]  profile_cycles='h0;
   //---------------------------------------------------------------------------
   // CSR read
   always @ (posedge CLK or negedge RESET_N) begin
   if (RESET_N==1'b0) begin
       T_RDATA <= 32'h0;
   end else begin
	if (T_RDEN==1'b1) begin
         (* full_case *)
         case (T_ADDR[T_ADDR_WID-1:0]) // synthesis full_case parallel_case
           CSRA_VERSION      : T_RDATA <= csr_version;
           CSRA_CONTROL      : T_RDATA <={csr_ctl_init     // bit-31
                                         ,pool_ready       // bit-30
                                         ,csr_ctl_ip       // bit-29
                                         ,csr_ctl_ie       // bit-28
                                         ,18'h0            // bit-27:10
                                         ,csr_result_done  // bit-9
                                         ,csr_feature_done // bit-8
                                         ,6'h0             // bit-7-2
                                         ,csr_result_go    // bit-1
                                         ,csr_feature_go   // bit-0
                                         };
           CSRA_COMMAND      : T_RDATA <= {28'h0, csr_command[3:0]};
           CSRA_CONFIG       : T_RDATA <= {csr_data_type   // bit-31:16
                                          `ifdef DATA_FIXED_POINT
                                          ,DATA_WIDTH_Q[7:0]// bit-15:8
                                          `else
                                          ,8'h0            // bit-15:8
                                          `endif
                                          ,DATA_WIDTH[7:0] // bit-7:0
                                          };
           CSRA_CONFIG_FIFO  : T_RDATA <= {16'h0                   // bit-31:16
                                          ,RESULT_FIFO_DEPTH[7:0]  // bit-15:8
                                          ,FEATURE_FIFO_DEPTH[7:0] // bit-7:0
                                          };
           CSRA_KNL_CFG      : T_RDATA <= {24'h0            // bit-31:8
                                          ,csr_kernel_height// bit-7:4
                                          ,csr_kernel_width // bit-3:0
                                          };
           CSRA_FTU_ADDR_LOW : T_RDATA <= csr_feature_address[31:0];
           CSRA_FTU_ADDR_HIGH: T_RDATA <= (AXI_WIDTH_AD>32)
                                        ? csr_feature_address[AXI_WIDTH_AD-1:32]
                                        : 32'h0;
           CSRA_FTU_CFG_SIZE : T_RDATA <={csr_feature_height// bit-31:16
                                         ,csr_feature_width // bit-15:0
                                         };
           CSRA_FTU_CFG_KNL  : T_RDATA <={16'h0                   // bit-31:16
                                         ,csr_feature_padding_post// bit-15:12
                                         ,csr_feature_padding_pre // bit-11:8
                                         ,4'h0                    // bit-7:4
                                         ,csr_feature_stride      // bit-3:0
                                         };
           CSRA_FTU_ITEMS    : T_RDATA <= csr_feature_items; // should be csr_feature_width*height
           CSRA_FTU_BURST    : T_RDATA <={24'h0                 // bit-31:8
                                         ,csr_feature_leng      // bit-7:0 AxLENG style
                                         };
           CSRA_FTU_CHANNEL  : T_RDATA <={16'h0
                                         ,csr_feature_channel // bit-15-0
                                         };
           CSRA_RST_ADDR_LOW : T_RDATA <= csr_result_address[31:0];
           CSRA_RST_ADDR_HIGH: T_RDATA <= (AXI_WIDTH_AD>32)
                                        ? csr_result_address[AXI_WIDTH_AD-1:32]
                                        : 32'h0;
           CSRA_RST_CFG_SIZE : T_RDATA <={csr_result_height// bit-31:16
                                         ,csr_result_width // bit-15:0
                                         };
           CSRA_RST_ITEMS    : T_RDATA <= csr_result_items;
           CSRA_RST_BURST    : T_RDATA <={24'h0            // bit-31:8
                                         ,csr_result_leng  // bit-7:0 AxLENG style
                                         };
           CSRA_PROFILE_CTL    : T_RDATA <={profile_init
                                           ,29'h0
                                           ,profile_done
                                           ,profile_snapshot};
           CSRA_PROFILE_CYCLES : T_RDATA <= profile_cycles;
           CSRA_PROFILE_CNT_RD : T_RDATA <= profile_cnt_read;
           CSRA_PROFILE_CNT_WR : T_RDATA <= profile_cnt_write;
           default: begin
                    T_RDATA <= 32'h0;
           end
         endcase
      end else T_RDATA <= 32'h0;
   end // if
   end // always
   //---------------------------------------------------------------------------
   // CSR write
   always @ (posedge CLK or negedge RESET_N) begin
   if (RESET_N==1'b0) begin
       csr_command              <= POOLING_NOP[3:0];
       csr_kernel_width         <= 4'h0;
       csr_kernel_height        <= 4'h0;
       csr_feature_address      <=  'h0;
       csr_feature_width        <=16'h0;
       csr_feature_height       <=16'h0;
       csr_feature_items        <=32'h0;
       csr_feature_padding_pre  <= 4'h0;
       csr_feature_padding_post <= 4'h0;
       csr_feature_stride       <= 4'h1;
       csr_feature_leng         <= 8'h0;
       csr_feature_channel      <=16'h0;
       csr_result_address       <=  'h0;
       csr_result_width         <=16'h0;
       csr_result_height        <=16'h0;
       csr_result_items         <=32'h0;
       csr_result_leng          <= 8'h0;
   end else begin
      if (T_WREN==1'b1) begin
         (* parallel_case *)
         case (T_ADDR[T_ADDR_WID-1:0]) // synthesis parallel_case
           CSRA_COMMAND      [T_ADDR_WID-1:0]: csr_command <= T_WDATA[3:0];
           CSRA_KNL_CFG      [T_ADDR_WID-1:0]:{csr_kernel_height// bit-7:4
                                              ,csr_kernel_width // bit-3:0
                                              } <= T_WDATA[7:0];
           CSRA_FTU_ADDR_LOW [T_ADDR_WID-1:0]: begin
                                               csr_feature_address[31:0] <= T_WDATA[31:0];
                                               end
           CSRA_FTU_ADDR_HIGH[T_ADDR_WID-1:0]: begin
                                               if (AXI_WIDTH_AD>32) csr_feature_address[AXI_WIDTH_AD-1:32] <= T_WDATA;
                                               end
           CSRA_FTU_CFG_SIZE [T_ADDR_WID-1:0]:{csr_feature_height
                                              ,csr_feature_width} <= T_WDATA;
           CSRA_FTU_CFG_KNL  [T_ADDR_WID-1:0]: begin
                                               csr_feature_padding_post <= T_WDATA[15:12];
                                               csr_feature_padding_pre <= T_WDATA[11:8];
                                               csr_feature_stride  <= (T_WDATA[3:0]==4'h0) ? 4'h1 : T_WDATA[3:0];
                                               end
           CSRA_FTU_ITEMS    [T_ADDR_WID-1:0]: csr_feature_items   <= T_WDATA;
           CSRA_FTU_BURST    [T_ADDR_WID-1:0]: csr_feature_leng    <= T_WDATA[ 7:0];
           CSRA_FTU_CHANNEL  [T_ADDR_WID-1:0]: csr_feature_channel <= T_WDATA[15:0];
           CSRA_RST_ADDR_LOW [T_ADDR_WID-1:0]: csr_result_address  <= T_WDATA[31:0];
           CSRA_RST_ADDR_HIGH[T_ADDR_WID-1:0]: if (AXI_WIDTH_AD>32) csr_result_address[AXI_WIDTH_AD-1:32] <= T_WDATA;
           CSRA_RST_CFG_SIZE [T_ADDR_WID-1:0]:{csr_result_height
                                              ,csr_result_width} <= T_WDATA;
           CSRA_RST_ITEMS    [T_ADDR_WID-1:0]: csr_result_items <= T_WDATA;
           CSRA_RST_BURST    [T_ADDR_WID-1:0]: csr_result_leng  <= T_WDATA[7:0];
         endcase
      end
   end // if
   end // always
   //---------------------------------------------------------------------------
   // init and go
   reg init_reg=1'b0;
   always @ (posedge CLK or negedge RESET_N) begin
   if (RESET_N==1'b0) begin
       init_reg       <= 1'b0;
       csr_ctl_init   <= 1'b0;
       csr_result_go  <= 1'b0; // bit-3
       csr_feature_go <= 1'b0; // bit-1
   end else begin
       if ((T_WREN==1'b1)&&(T_ADDR==CSRA_CONTROL[T_ADDR_WID-1:0])) begin
           csr_ctl_init   <= T_WDATA[31];
           csr_result_go  <= T_WDATA[1];
           csr_feature_go <= T_WDATA[0];
       end else begin
           init_reg <= csr_ctl_init;
           if (init_reg) csr_ctl_init <= 1'b0;
           if (csr_result_done ) csr_result_go  <= 1'b0;
           if (csr_feature_done) csr_feature_go <= 1'b0;
       end
   end // if
   end // always
   //---------------------------------------------------------------------------
   // synthesis translate_off
   reg [31:0] widthR='h0;
   reg [31:0] heightR='h0;
   always @ (posedge csr_feature_go) begin
     //if ((csr_kernel_width[0]==1'b0)||(csr_kernel_height[0]==0))
     //     $display("%0t %m ERROR kernel size should be odd.", $time);
       widthR = func_get_num( csr_kernel_width, csr_feature_width
                            , csr_feature_stride, csr_feature_padding_pre, csr_feature_padding_post );
       heightR = func_get_num( csr_kernel_height, csr_feature_height
                             , csr_feature_stride, csr_feature_padding_pre, csr_feature_padding_post );
       if (csr_feature_items!=(csr_feature_width*csr_feature_height))
            $display("%0t %m ERROR feature size and items mis-match.", $time);
       if (csr_feature_stride==0)
            $display("%0t %m ERROR feature stride should be greater than 0.", $time);
       if (csr_feature_stride>csr_kernel_width)
            $display("%0t %m ERROR feature stride mis-match %0d %0d.", $time, csr_feature_stride, csr_kernel_width);
   end // always
   always @ (posedge csr_result_go) begin
       widthR = func_get_num( csr_kernel_width, csr_feature_width
                            , csr_feature_stride, csr_feature_padding_pre, csr_feature_padding_post );
       heightR = func_get_num( csr_kernel_height, csr_feature_height
                             , csr_feature_stride, csr_feature_padding_pre, csr_feature_padding_post );
       if (csr_result_items!=(csr_result_width*csr_result_height))
            $display("%0t %m ERROR result size and items mis-match.", $time);
       if (csr_result_width!=widthR)
            $display("%0t %m ERROR result width size mis-match: %d %d", $time, csr_result_width, widthR);
       if (csr_result_height!=heightR)
            $display("%0t %m ERROR result height size mis-match: %d %d", $time, csr_result_height, heightR);
   end // always
   function integer func_get_num;
       input integer kernel_width;
       input integer feature_width;
       input integer feature_stride;
       input integer feature_pdding_pre;
       input integer feature_pdding_post;
   begin
       func_get_num=((feature_width-kernel_width+
                      feature_padding_pre+feature_padding_post)/feature_stride)+1;
   end
   endfunction
   // synthesis translate_on
   //---------------------------------------------------------------------------
   // interrupt
   always @ (posedge CLK or negedge RESET_N) begin
   if (RESET_N==1'b0) begin
       csr_ctl_ie <= 1'b0; // bit-28
       csr_ctl_ip <= 1'b0; // bit-29
   end else begin
       if ((T_WREN==1'b1)&&(T_ADDR==CSRA_CONTROL[T_ADDR_WID-1:0])) begin
           csr_ctl_ie <= T_WDATA[28];
           csr_ctl_ip <= (T_WDATA[29]==1'b0) ? 1'b0 : csr_ctl_ip;
       end else begin
           if (csr_ctl_ie      & 
             //csr_kernel_done &csr_kernel_go &
             //csr_feature_done&csr_feature_go&
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
       if ((T_WREN==1'b1)&&(T_ADDR==CSRA_PROFILE_CTL[T_ADDR_WID-1:0])) begin
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
   assign  command             =csr_command          ;
   assign  kernel_width        =csr_kernel_width     ;
   assign  kernel_height       =csr_kernel_height    ;
   assign  feature_go          =csr_feature_go       ;
   assign                       csr_feature_done     =feature_done;
   assign  feature_address     =csr_feature_address  ;
   assign  feature_width       =csr_feature_width    ;
   assign  feature_height      =csr_feature_height   ;
   assign  feature_items       =csr_feature_items    ;
   assign  feature_padding_pre =csr_feature_padding_pre ;
   assign  feature_padding_post=csr_feature_padding_post;
   assign  feature_stride      =csr_feature_stride   ;
   assign  feature_leng        =csr_feature_leng     ;
   assign  feature_channel     =csr_feature_channel  ;
   assign  result_go           =csr_result_go        ;
   assign                       csr_result_done      =result_done;
   assign  result_address      =csr_result_address   ;
   assign  result_width        =csr_result_width     ;
   assign  result_height       =csr_result_height    ;
   assign  result_items        =csr_result_items     ;
   assign  result_leng         =csr_result_leng      ;
   assign  pool_init           =csr_ctl_init         ;
   assign  interrupt           =csr_ctl_ie&csr_ctl_ip;
endmodule

//------------------------------------------------------------------------------
// Revision history
//
// 2021.11.06: APB
// 2021.06.10: Started by Ando Ki (andoki@gmail.com)
//------------------------------------------------------------------------------
