//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All right reserved.
//------------------------------------------------------------------------------
// VERSION: 2021.11.06.
//------------------------------------------------------------------------------
// Linear 1D CSR
//------------------------------------------------------------------------------
module linear_1d_csr
     #(parameter APB_WIDTH_AD =32
               , APB_WIDTH_DA =32
               , AXI_WIDTH_AD =32        // address width
               , DATA_TYPE="INTEGER" // "INTEGER", "FLOATING_POINT", "FIXED_POINT"
               , DATA_WIDTH     =32 // bit-width of a whole part
               `ifdef DATA_FIXED_POINT
               , DATA_WIDTH_Q=(DATA_WIDTH/2) // fractional bits
               `endif
               , INPUT_FIFO_DEPTH =32
               , WEIGHT_FIFO_DEPTH=32
               , RESULT_FIFO_DEPTH=16
               , PROFILE_CNT_WIDTH=32
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
    , output wire                     bias_go
    , input  wire                     bias_done // read-done
    , output wire [AXI_WIDTH_AD-1:0]  bias_address
    , output wire [15:0]              bias_size // result_size
    , output wire                     input_go
    , input  wire                     input_done // read-done
    , output wire [AXI_WIDTH_AD-1:0]  input_address
    , output wire [15:0]              input_size // num of items
    , output wire [ 7:0]              input_leng // same format for AxLEN
    , output wire                     weight_go
    , input  wire                     weight_done // read-done
    , output wire [AXI_WIDTH_AD-1:0]  weight_address
    , output wire [15:0]              weight_width // = input_size
    , output wire [15:0]              weight_height // = result_size
    , output wire [31:0]              weight_items // weight_width*weight_height
    , output wire [ 7:0]              weight_leng // same format for AxLEN
    , output wire                     result_go
    , input  wire                     result_done // read-done
    , output wire [AXI_WIDTH_AD-1:0]  result_address
    , output wire [15:0]              result_size
    , output wire [ 7:0]              result_leng // same format for AxLEN
    , output wire [ 3:0]              linear_activ_func // acivation function (0=linear, 1=ReLU, 2=LeakyReLU)
    , output wire [DATA_WIDTH-1:0]    linear_activ_param // activation parameter if required
    , output wire                     linear_init // synchronous reset except this CSR
    , input  wire                     linear_ready
    , output wire                           profile_init // auto-return 0
    , output wire                           profile_snapshot
    , input  wire                           profile_done
    , input  wire  [PROFILE_CNT_WIDTH-1:0]  profile_mac_num
    , input  wire  [PROFILE_CNT_WIDTH-1:0]  profile_mac_overflow
    , input  wire  [PROFILE_CNT_WIDTH-1:0]  profile_bias_overflow
    , input  wire  [PROFILE_CNT_WIDTH-1:0]  profile_activ_overflow
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
   linear_1d_csr_core #(.T_ADDR_WID        (T_ADDR_WID        )
                       ,.APB_WIDTH_DA      (APB_WIDTH_DA      )
                       ,.AXI_WIDTH_AD      (AXI_WIDTH_AD      )
                       ,.DATA_TYPE (DATA_TYPE)
                       ,.DATA_WIDTH        (DATA_WIDTH        )
                       `ifdef DATA_FIXED_POINT
                       ,.DATA_WIDTH_Q      (DATA_WIDTH_Q      )
                       `endif
                       ,.INPUT_FIFO_DEPTH ( INPUT_FIFO_DEPTH  )
                       ,.WEIGHT_FIFO_DEPTH( WEIGHT_FIFO_DEPTH )
                       ,.RESULT_FIFO_DEPTH( RESULT_FIFO_DEPTH )
                       ,.PROFILE_CNT_WIDTH( PROFILE_CNT_WIDTH )
                       )
   u_csr (
       .RESET_N   (PRESETn  )
     , .CLK       (PCLK     )
     , .T_ADDR    (T_ADDR   )
     , .T_WREN    (T_WREN   )
     , .T_RDEN    (T_RDEN   )
     , .T_WDATA   (T_WDATA  )
     , .T_RDATA   (T_RDATA  )
     , .bias_go              ( bias_go            )
     , .bias_done            ( bias_done          )
     , .bias_address         ( bias_address       )
     , .bias_size            ( bias_size          )
     , .input_go             ( input_go           )
     , .input_done           ( input_done         )
     , .input_address        ( input_address      )
     , .input_size           ( input_size         )
     , .input_leng           ( input_leng         )
     , .weight_go            ( weight_go          )
     , .weight_done          ( weight_done        )
     , .weight_address       ( weight_address     )
     , .weight_width         ( weight_width       )
     , .weight_height        ( weight_height      )
     , .weight_items         ( weight_items       )
     , .weight_leng          ( weight_leng        )
     , .result_go            ( result_go          )
     , .result_done          ( result_done        )
     , .result_address       ( result_address     )
     , .result_size          ( result_size        )
     , .result_leng          ( result_leng        )
     , .linear_activ_func    ( linear_activ_func  )
     , .linear_activ_param   ( linear_activ_param )
     , .linear_init          ( linear_init        )
     , .linear_ready         ( linear_ready       )
     , .profile_init             ( profile_init           )
     , .profile_snapshot         ( profile_snapshot       )
     , .profile_done             ( profile_done           )
     , .profile_mac_num          ( profile_mac_num        )
     , .profile_mac_overflow     ( profile_mac_overflow   )
     , .profile_bias_overflow    ( profile_bias_overflow  )
     , .profile_activ_overflow   ( profile_activ_overflow )
     , .profile_cnt_read         ( profile_cnt_read       )
     , .profile_cnt_write        ( profile_cnt_write      )
     , .interrupt                ( interrupt              )
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
// use transposed weight
//                                                result_width   result_width
//   |<-feature_width->|   |<-feature_width->|   |<-------->|   |<-------->|
//   +-----------------+   +-----------------+-   +----------+   +----------+
//   | input feature   | x | weights         || + | bias     | = | result   |
//   +-----------------+   |                 ||   +----------+   +----------+
//                         |                 ||   
//                         |                 ||   
//                         |                 ||result_width   
//                         +-----------------+-  
//
//------------------------------------------------------------------------------

module linear_1d_csr_core
     #(parameter T_ADDR_WID=8
               , APB_WIDTH_DA=32
               , AXI_WIDTH_AD=32
               , DATA_TYPE="INTEGER" // "INTEGER", "FLOATING_POINT", "FIXED_POINT"
               , DATA_WIDTH     =32 // bit-width of a whole part
               `ifdef DATA_FIXED_POINT
               , DATA_WIDTH_Q=(DATA_WIDTH/2) // fractional bits
               `endif
               , INPUT_FIFO_DEPTH =32
               , WEIGHT_FIFO_DEPTH=32
               , RESULT_FIFO_DEPTH=16
               , PROFILE_CNT_WIDTH=32
               )
(
      input   wire                      RESET_N
    , input   wire                      CLK
    , input   wire  [T_ADDR_WID-1:0]    T_ADDR
    , input   wire                      T_WREN
    , input   wire                      T_RDEN
    , input   wire  [APB_WIDTH_DA-1:0]  T_WDATA
    , output  reg   [APB_WIDTH_DA-1:0]  T_RDATA
    //-------------------------------------------------------------------------
    , output  wire                      bias_go
    , input   wire                      bias_done // read-done
    , output  wire  [AXI_WIDTH_AD-1:0]  bias_address
    , output  wire  [15:0]              bias_size // result_size
    , output  wire                      input_go
    , input   wire                      input_done // read-done
    , output  wire  [AXI_WIDTH_AD-1:0]  input_address
    , output  wire  [15:0]              input_size // num of items
    , output  wire  [ 7:0]              input_leng // same format for AxLEN
    , output  wire                      weight_go
    , input   wire                      weight_done // read-done
    , output  wire  [AXI_WIDTH_AD-1:0]  weight_address
    , output  wire  [15:0]              weight_width // = input_size
    , output  wire  [15:0]              weight_height // = result_size
    , output  wire  [31:0]              weight_items // weight_width*weight_height
    , output  wire  [ 7:0]              weight_leng // same format for AxLEN
    , output  wire                      result_go
    , input   wire                      result_done // read-done
    , output  wire  [AXI_WIDTH_AD-1:0]  result_address
    , output  wire  [15:0]              result_size
    , output  wire  [ 7:0]              result_leng // AxLENG
    , output  wire  [ 3:0]              linear_activ_func // acivation function (0=linear, 1=ReLU, 2=LeakyReLU)
    , output  wire  [DATA_WIDTH-1:0]    linear_activ_param // activation parameter if required
    , output  wire                      linear_init // active-high synchronous reset except this CSR
                                                 // auto clean
    , input   wire                      linear_ready
    , output  reg                            profile_init // auto-return 0
    , output  reg                            profile_snapshot
    , input   wire                           profile_done
    , input   wire  [PROFILE_CNT_WIDTH-1:0]  profile_mac_num
    , input   wire  [PROFILE_CNT_WIDTH-1:0]  profile_mac_overflow
    , input   wire  [PROFILE_CNT_WIDTH-1:0]  profile_bias_overflow
    , input   wire  [PROFILE_CNT_WIDTH-1:0]  profile_activ_overflow
    , input   wire  [PROFILE_CNT_WIDTH-1:0]  profile_cnt_read
    , input   wire  [PROFILE_CNT_WIDTH-1:0]  profile_cnt_write
    , output  wire                     interrupt // interrupt to get attention
);
   //---------------------------------------------------------------------------
   // CSR address
   localparam CSRA_VERSION       = 'h00
            , CSRA_CONTROL       = 'h10
            , CSRA_CONFIG        = 'h14
            , CSRA_CONFIG_FIFO   = 'h18

            , CSRA_INPUT_ADDR_LOW  = 'h20
            , CSRA_INPUT_ADDR_HIGH = 'h24
            , CSRA_INPUT_CFG       = 'h28
            , CSRA_INPUT_BURST     = 'h30

            , CSRA_WEIGHT_ADDR_LOW  = 'h40
            , CSRA_WEIGHT_ADDR_HIGH = 'h44
            , CSRA_WEIGHT_CFG       = 'h48
            , CSRA_WEIGHT_ITEMS     = 'h4C
            , CSRA_WEIGHT_BURST     = 'h50

            , CSRA_BIAS_ADDR_LOW  = 'h60
            , CSRA_BIAS_ADDR_HIGH = 'h64
            , CSRA_BIAS_CFG       = 'h68

            , CSRA_RST_ADDR_LOW  = 'h70
            , CSRA_RST_ADDR_HIGH = 'h74
            , CSRA_RST_CFG       = 'h78
            , CSRA_RST_BURST     = 'h80

            , CSRA_LINEAR_ACTIV_FUNC  = 'h90
            , CSRA_LINEAR_ACTIV_PARAM = 'h94

            , CSRA_PROFILE_CTL     = 'hA0
            , CSRA_PROFILE_CYCLES  = 'hA4
            , CSRA_PROFILE_MAC_NUM = 'hA8 // num of MAC operations
            , CSRA_PROFILE_MAC_OVR = 'hAC // num of overflow while MAC operations
            , CSRA_PROFILE_BIA_OVR = 'hB0 // num of overflow while adding bias
            , CSRA_PROFILE_ACT_OVR = 'hB4 // num of overflow while activation
            , CSRA_PROFILE_CNT_RD  = 'hB8 // num of read
            , CSRA_PROFILE_CNT_WR  = 'hBC // num of write
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
   wire [31:0]              csr_version           =32'h20210610;
   reg                      csr_ctl_ip            =1'b0;
   reg                      csr_ctl_ie            =1'b0;
   reg                      csr_ctl_init          =1'b0;
   wire [15:0]              csr_data_type         =(DATA_TYPE=="FLOATING_POINT") ? swap("FP")
                                                  :(DATA_TYPE=="FIXED_POINT") ? swap("FX")
                                                  : swap("IT");
   reg                      csr_input_go          =1'b0;
   wire                     csr_input_done;
   reg  [AXI_WIDTH_AD-1:0]  csr_input_address     = 'h0;
   reg  [15:0]              csr_input_size        = 'h0; // num of items of kernel-row
   reg  [ 7:0]              csr_input_leng        = 'h0; // AxLENG format
   reg                      csr_weight_go         =1'b0;
   wire                     csr_weight_done;
   reg  [AXI_WIDTH_AD-1:0]  csr_weight_address    = 'h0;
   reg  [15:0]              csr_weight_width      = 'h0;
   reg  [15:0]              csr_weight_height     = 'h0;
   reg  [31:0]              csr_weight_items      = 'h0;
   reg  [ 7:0]              csr_weight_leng       = 'h0; // AxLENG format
   reg                      csr_bias_go           =1'b0;
   wire                     csr_bias_done;
   reg  [AXI_WIDTH_AD-1:0]  csr_bias_address      = 'h0;
   reg  [15:0]              csr_bias_size         = 'h0; // num of items of row
   reg                      csr_result_go         =1'b0;
   wire                     csr_result_done;
   reg  [AXI_WIDTH_AD-1:0]  csr_result_address    = 'h0;
   reg  [15:0]              csr_result_size       = 'h0; // num of items of row
   reg  [ 7:0]              csr_result_leng       = 'h0; // 0 = length 1
   reg  [ 3:0]              csr_linear_activ_func =4'b0; // acivation function (0=linear, 1=ReLU, 2=LeakyReLU)
   reg  [DATA_WIDTH-1:0]    csr_linear_activ_param= 'h0; // activation parameter if required
   reg  [PROFILE_CNT_WIDTH-1:0]  profile_cycles='h0;
   //---------------------------------------------------------------------------
   // CSR read
   always @ (posedge CLK or negedge RESET_N) begin
   if (RESET_N==1'b0) begin
       T_RDATA <= 'h0;
   end else begin
      if (T_RDEN) begin
         case (T_ADDR)
           CSRA_VERSION      : T_RDATA <= csr_version;
           CSRA_CONTROL      : T_RDATA <={csr_ctl_init     // bit-31
                                         ,linear_ready     // bit-30
                                         ,csr_ctl_ip       // bit-29
                                         ,csr_ctl_ie       // bit-28
                                         ,16'h0            // bit-27-12
                                         ,csr_result_done  // bit-11
                                         ,csr_bias_done    // bit-10
                                         ,csr_weight_done  // bit-9
                                         ,csr_input_done   // bit-8
                                         ,4'h0             // bit-7-4
                                         ,csr_result_go    // bit-3
                                         ,csr_bias_go      // bit-2
                                         ,csr_weight_go    // bit-1
                                         ,csr_input_go     // bit-0
                                         };
           CSRA_CONFIG       : T_RDATA <= {csr_data_type   // bit-31:16
                                          `ifdef DATA_FIXED_POINT
                                          ,DATA_WIDTH_Q[7:0]// bit-15:8
                                          `else
                                          ,8'h0            // bit-15:8
                                          `endif
                                          ,DATA_WIDTH[7:0] // bit-7:0
                                          };
           CSRA_CONFIG_FIFO  : T_RDATA <= {8'h0                   // bit-31:24
                                          ,RESULT_FIFO_DEPTH[7:0] // bit-23:16
                                          ,WEIGHT_FIFO_DEPTH[7:0] // bit-15:8
                                          ,INPUT_FIFO_DEPTH [7:0] // bit-7:0
                                          };
           CSRA_INPUT_ADDR_LOW : T_RDATA <= csr_input_address[31:0];
           CSRA_INPUT_ADDR_HIGH: T_RDATA <= csr_input_address>>32;
         //CSRA_INPUT_ADDR_HIGH: T_RDATA <= (AXI_WIDTH_AD>32)
         //                               ? csr_input_address[AXI_WIDTH_AD-1:32]
         //                               : 32'h0;
           CSRA_INPUT_CFG      : T_RDATA <= {16'h0// bit-31:16
                                            ,csr_input_size  // bit-15:0
                                            };
           CSRA_INPUT_BURST    : T_RDATA <={24'h0            // bit-31:8
                                           ,csr_input_leng  // bit-7:0 AxLENG style
                                           };
           CSRA_WEIGHT_ADDR_LOW : T_RDATA <= csr_weight_address[31:0];
           CSRA_WEIGHT_ADDR_HIGH: T_RDATA <= csr_weight_address>>32;
         //CSRA_WEIGHT_ADDR_HIGH: T_RDATA <= (AXI_WIDTH_AD>32)
         //                                ? csr_weight_address[AXI_WIDTH_AD-1:32]
         //                                : 32'h0;
           CSRA_WEIGHT_CFG      : T_RDATA <={csr_weight_height// bit-31:16
                                            ,csr_weight_width // bit-15:0
                                            };
           CSRA_WEIGHT_ITEMS    : T_RDATA <= csr_weight_items; // should be csr_feature_width*height
           CSRA_WEIGHT_BURST    : T_RDATA <={24'h0                 // bit-31:8
                                            ,csr_weight_leng      // bit-7:0 AxLENG style
                                            };
           CSRA_BIAS_ADDR_LOW : T_RDATA <= csr_bias_address[31:0];
           CSRA_BIAS_ADDR_HIGH: T_RDATA <= csr_bias_address>>32;
         //CSRA_BIAS_ADDR_HIGH: T_RDATA <= (AXI_WIDTH_AD>32)
         //                             ? csr_bias_address[AXI_WIDTH_AD-1:32]
         //                             : 32'h0;
           CSRA_BIAS_CFG      : T_RDATA <={16'h0// bit-31:16
                                         ,csr_bias_size  // bit-15:0
                                         };
           CSRA_RST_ADDR_LOW : T_RDATA <= csr_result_address[31:0];
           CSRA_RST_ADDR_HIGH: T_RDATA <= csr_result_address>>32;
         //CSRA_RST_ADDR_HIGH: T_RDATA <= (AXI_WIDTH_AD>32)
         //                             ? csr_result_address[AXI_WIDTH_AD-1:32]
         //                             : 32'h0;
           CSRA_RST_CFG      : T_RDATA <={16'h0            // bit-31:16
                                         ,csr_result_size  // bit-15:0
                                         };
           CSRA_RST_BURST    : T_RDATA <={24'h0            // bit-31:8
                                         ,csr_result_leng  // bit-7:0 AxLENG style
                                         };
           CSRA_LINEAR_ACTIV_FUNC :T_RDATA <= {28'h0, csr_linear_activ_func};
           CSRA_LINEAR_ACTIV_PARAM:T_RDATA <= csr_linear_activ_param>>32;
         //CSRA_LINEAR_ACTIV_PARAM:T_RDATA <= (DATA_WIDTH==32)
         //                                 ? csr_linear_activ_param
         //                                 : {{32-DATA_WIDTH{1'b0}},csr_linear_activ_param};
           CSRA_PROFILE_CTL    : T_RDATA <={profile_init
                                           ,29'h0
                                           ,profile_done
                                           ,profile_snapshot};
           CSRA_PROFILE_CYCLES : T_RDATA <= profile_cycles;
           CSRA_PROFILE_MAC_NUM: T_RDATA <= profile_mac_num;
           CSRA_PROFILE_MAC_OVR: T_RDATA <= profile_mac_overflow ;   
           CSRA_PROFILE_BIA_OVR: T_RDATA <= profile_bias_overflow;
           CSRA_PROFILE_ACT_OVR: T_RDATA <= profile_activ_overflow;  
           CSRA_PROFILE_CNT_RD : T_RDATA <= profile_cnt_read;
           CSRA_PROFILE_CNT_WR : T_RDATA <= profile_cnt_write;
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
       csr_input_address       <=  'h0;
       csr_input_size          <=  'h0;
       csr_input_leng          <= 8'h0;
       csr_weight_address      <=  'h0;
       csr_weight_width        <=  'h0;
       csr_weight_height       <=  'h0;
       csr_weight_items        <=  'h0;
       csr_weight_leng         <= 8'h0;
       csr_bias_address        <=  'h0;
       csr_bias_size           <=  'h0;
       csr_result_address      <=  'h0;
       csr_result_size         <=  'h0;
       csr_result_leng         <= 8'h0;
       csr_linear_activ_func   <= 4'h0;
       csr_linear_activ_param  <=  'h0;
   end else begin
      if (T_WREN) begin
         case (T_ADDR)
           CSRA_INPUT_ADDR_LOW    : csr_input_address[31:0] <= T_WDATA[31:0];
           CSRA_INPUT_ADDR_HIGH   : if (AXI_WIDTH_AD>32) csr_input_address[AXI_WIDTH_AD-1:32] <= T_WDATA;
           CSRA_INPUT_CFG         : csr_input_size <= T_WDATA[15:0];
           CSRA_INPUT_BURST       : csr_input_leng <= T_WDATA[7:0];
           CSRA_WEIGHT_ADDR_LOW   : csr_weight_address[31:0] <= T_WDATA[31:0];
           CSRA_WEIGHT_ADDR_HIGH  : if (AXI_WIDTH_AD>32) csr_weight_address[AXI_WIDTH_AD-1:32] <= T_WDATA;
           CSRA_WEIGHT_CFG        :{csr_weight_height,csr_weight_width} <= T_WDATA;
           CSRA_WEIGHT_ITEMS      : csr_weight_items <= T_WDATA;
           CSRA_WEIGHT_BURST      : csr_weight_leng  <= T_WDATA[7:0];
           CSRA_BIAS_ADDR_LOW     : csr_bias_address <= T_WDATA[31:0];
           CSRA_BIAS_ADDR_HIGH    : if (AXI_WIDTH_AD>32) csr_bias_address[AXI_WIDTH_AD-1:32] <= T_WDATA;
           CSRA_BIAS_CFG          : csr_bias_size   <= T_WDATA[15:0];
           CSRA_RST_ADDR_LOW      : csr_result_address <= T_WDATA[31:0];
           CSRA_RST_ADDR_HIGH     : if (AXI_WIDTH_AD>32) csr_result_address[AXI_WIDTH_AD-1:32] <= T_WDATA;
           CSRA_RST_CFG           : csr_result_size  <= T_WDATA;
           CSRA_RST_BURST         : csr_result_leng  <= T_WDATA[7:0];
           CSRA_LINEAR_ACTIV_FUNC : csr_linear_activ_func  <= T_WDATA[3:0];
           CSRA_LINEAR_ACTIV_PARAM: csr_linear_activ_param <= T_WDATA[DATA_WIDTH-1:0];
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
       csr_bias_go   <= 1'b0; // bit-2
       csr_weight_go <= 1'b0; // bit-1
       csr_input_go  <= 1'b0; // bit-0
   end else begin
       if (T_WREN&&(T_ADDR==CSRA_CONTROL)) begin
           csr_ctl_init   <= T_WDATA[31];
           csr_result_go  <= T_WDATA[3];
           csr_bias_go    <= T_WDATA[2];
           csr_weight_go  <= T_WDATA[1];
           csr_input_go   <= T_WDATA[0];
       end else begin
           init_reg <= csr_ctl_init;
           if (init_reg) csr_ctl_init <= 1'b0;
           if (csr_result_done) csr_result_go <= 1'b0;
           if (csr_bias_done  ) csr_bias_go   <= 1'b0;
           if (csr_weight_done) csr_weight_go <= 1'b0;
           if (csr_input_done ) csr_input_go  <= 1'b0;
       end
   end // if
   end // always
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
   // synthesis translate_off
   always @ (posedge csr_weight_go) begin
       if (csr_weight_items!=(csr_weight_width*csr_weight_height))
            $display("%0t %m ERROR weight size and items mis-match.", $time);
       if (csr_input_size!=csr_weight_width)
            $display("%0t %m ERROR weight width mis-match: %d %d", $time, csr_weight_width, csr_input_size);
   end // always
   always @ (posedge csr_result_go) begin
       if (csr_result_size!=csr_weight_height)
            $display("%0t %m ERROR result size mis-match: %d %d", $time, csr_result_size, csr_weight_height);
   end // always
   // synthesis translate_on
   //---------------------------------------------------------------------------
   assign  input_go          =csr_input_go          ;
   assign                     csr_input_done        =input_done;
   assign  input_address     =csr_input_address     ;
   assign  input_size        =csr_input_size        ;
   assign  input_leng        =csr_input_leng        ;
   assign  weight_go         =csr_weight_go         ;
   assign                     csr_weight_done       =weight_done;
   assign  weight_address    =csr_weight_address    ;
   assign  weight_width      =csr_weight_width      ;
   assign  weight_height     =csr_weight_height     ;
   assign  weight_items      =csr_weight_items      ;
   assign  weight_leng       =csr_weight_leng       ;
   assign  bias_go           =csr_bias_go           ;
   assign                     csr_bias_done         =bias_done;
   assign  bias_address      =csr_bias_address      ;
   assign  bias_size         =csr_bias_size         ;
   assign  result_go         =csr_result_go         ;
   assign                     csr_result_done       =result_done;
   assign  result_address    =csr_result_address    ;
   assign  result_size       =csr_result_size       ;
   assign  result_leng       =csr_result_leng       ;
   assign  linear_activ_func =csr_linear_activ_func ;
   assign  linear_activ_param=csr_linear_activ_param;
   assign  linear_init       =csr_ctl_init          ;
   assign  interrupt         =csr_ctl_ie&csr_ctl_ip ;
endmodule

//------------------------------------------------------------------------------
// Revision history
//
// 2021.11.06: APB
// 2021.06.10: Started by Ando Ki (andoki@gmail.com)
//------------------------------------------------------------------------------
