//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All right reserved.
//------------------------------------------------------------------------------
// VERSION: 2021.06.10.
//------------------------------------------------------------------------------
// Convolution 2D Controller
//------------------------------------------------------------------------------

module convolution_2d_control
     #(parameter AXI_WIDTH_ID =4       // ID width in bits
               , AXI_WIDTH_AD =32      // address width
               , AXI_WIDTH_DA =32      // data width
               , AXI_WIDTH_DS =AXI_WIDTH_DA/8
               , DATA_WIDTH     =32
               , KERNEL_MAX_SIZE   =5 // max value
               , KERNEL_FIFO_DEPTH =1<<$clog2(KERNEL_MAX_SIZE*KERNEL_MAX_SIZE)
               , FEATURE_FIFO_DEPTH=16 // kernel_max_size*2
               , CHANNEL_FIFO_DEPTH=16
               , RESULT_FIFO_DEPTH =16
               , KERNEL_FIFO_AW    =$clog2(KERNEL_FIFO_DEPTH )
               , FEATURE_FIFO_AW   =$clog2(FEATURE_FIFO_DEPTH)
               , CHANNEL_FIFO_AW   =$clog2(CHANNEL_FIFO_DEPTH)
               , RESULT_FIFO_AW    =$clog2(RESULT_FIFO_DEPTH )
               , PROFILE_CNT_WIDTH=32
               )
(
      input   wire                           ARESETn
    , input   wire                           ACLK
    // master port for kernel (read-only)
    ,           output  wire  [AXI_WIDTH_ID-1:0]       M_AXI_KNL_ARID
    , `DBG_CONV output  wire  [AXI_WIDTH_AD-1:0]       M_AXI_KNL_ARADDR
    , `DBG_CONV output  wire  [ 7:0]                   M_AXI_KNL_ARLEN
    ,           output  wire  [ 2:0]                   M_AXI_KNL_ARSIZE
    ,           output  wire  [ 1:0]                   M_AXI_KNL_ARBURST
    , `DBG_CONV output  wire                           M_AXI_KNL_ARVALID
    , `DBG_CONV input   wire                           M_AXI_KNL_ARREADY
    ,           input   wire  [AXI_WIDTH_ID-1:0]       M_AXI_KNL_RID
    , `DBG_CONV input   wire  [AXI_WIDTH_DA-1:0]       M_AXI_KNL_RDATA
    ,           input   wire  [ 1:0]                   M_AXI_KNL_RRESP
    , `DBG_CONV input   wire                           M_AXI_KNL_RLAST
    , `DBG_CONV input   wire                           M_AXI_KNL_RVALID
    , `DBG_CONV output  wire                           M_AXI_KNL_RREADY
    // master port for feature (read-only)
    ,           output  wire  [AXI_WIDTH_ID-1:0]       M_AXI_FTU_ARID
    , `DBG_CONV output  wire  [AXI_WIDTH_AD-1:0]       M_AXI_FTU_ARADDR
    , `DBG_CONV output  wire  [ 7:0]                   M_AXI_FTU_ARLEN
    ,           output  wire  [ 2:0]                   M_AXI_FTU_ARSIZE
    ,           output  wire  [ 1:0]                   M_AXI_FTU_ARBURST
    , `DBG_CONV output  wire                           M_AXI_FTU_ARVALID
    , `DBG_CONV input   wire                           M_AXI_FTU_ARREADY
    ,           input   wire  [AXI_WIDTH_ID-1:0]       M_AXI_FTU_RID
    , `DBG_CONV input   wire  [AXI_WIDTH_DA-1:0]       M_AXI_FTU_RDATA
    ,           input   wire  [ 1:0]                   M_AXI_FTU_RRESP
    , `DBG_CONV input   wire                           M_AXI_FTU_RLAST
    , `DBG_CONV input   wire                           M_AXI_FTU_RVALID
    , `DBG_CONV output  wire                           M_AXI_FTU_RREADY
    // master port for channel (read-only)
    ,           output  wire  [AXI_WIDTH_ID-1:0]       M_AXI_CHN_ARID
    , `DBG_CONV output  wire  [AXI_WIDTH_AD-1:0]       M_AXI_CHN_ARADDR
    , `DBG_CONV output  wire  [ 7:0]                   M_AXI_CHN_ARLEN
    ,           output  wire  [ 2:0]                   M_AXI_CHN_ARSIZE
    ,           output  wire  [ 1:0]                   M_AXI_CHN_ARBURST
    , `DBG_CONV output  wire                           M_AXI_CHN_ARVALID
    , `DBG_CONV input   wire                           M_AXI_CHN_ARREADY
    ,           input   wire  [AXI_WIDTH_ID-1:0]       M_AXI_CHN_RID
    , `DBG_CONV input   wire  [AXI_WIDTH_DA-1:0]       M_AXI_CHN_RDATA
    ,           input   wire  [ 1:0]                   M_AXI_CHN_RRESP
    , `DBG_CONV input   wire                           M_AXI_CHN_RLAST
    , `DBG_CONV input   wire                           M_AXI_CHN_RVALID
    , `DBG_CONV output  wire                           M_AXI_CHN_RREADY
    // master port for result (write-only)
    ,           output  wire  [AXI_WIDTH_ID-1:0]       M_AXI_RST_AWID
    , `DBG_CONV output  wire  [AXI_WIDTH_AD-1:0]       M_AXI_RST_AWADDR
    , `DBG_CONV output  wire  [ 7:0]                   M_AXI_RST_AWLEN
    ,           output  wire  [ 2:0]                   M_AXI_RST_AWSIZE
    ,           output  wire  [ 1:0]                   M_AXI_RST_AWBURST
    , `DBG_CONV output  wire                           M_AXI_RST_AWVALID
    , `DBG_CONV input   wire                           M_AXI_RST_AWREADY
    , `DBG_CONV output  wire  [AXI_WIDTH_DA-1:0]       M_AXI_RST_WDATA
    , `DBG_CONV output  wire  [AXI_WIDTH_DS-1:0]       M_AXI_RST_WSTRB
    , `DBG_CONV output  wire                           M_AXI_RST_WLAST
    , `DBG_CONV output  wire                           M_AXI_RST_WVALID
    , `DBG_CONV input   wire                           M_AXI_RST_WREADY
    ,           input   wire  [AXI_WIDTH_ID-1:0]       M_AXI_RST_BID
    ,           input   wire  [ 1:0]                   M_AXI_RST_BRESP
    , `DBG_CONV input   wire                           M_AXI_RST_BVALID
    , `DBG_CONV output  wire                           M_AXI_RST_BREADY
    // for kernel part of conv
    , input   wire                           OUT_KNL_READY
    , output  wire                           OUT_KNL_VALID
    , output  wire  [DATA_WIDTH-1:0]         OUT_KNL_DATA
    , output  wire                           OUT_KNL_LAST
    , input   wire  [KERNEL_FIFO_AW:0]       OUT_KNL_ROOMS // fifo rooms
    , output  reg   [ 1:0]                   OUT_KNL_MODE
                                             // 00=disabled(clear), 01=fill
                                             // 10=read-out, 11=read-out-rotate
    // for feature part of MconvAC
    , input   wire                           OUT_FTU_READY
    , output  wire                           OUT_FTU_VALID
    , output  wire  [DATA_WIDTH-1:0]         OUT_FTU_DATA
    , output  wire                           OUT_FTU_LAST
    , input   wire  [FEATURE_FIFO_AW:0]      OUT_FTU_ROOMS // fifo rooms
    // for channel part of MconvAC
    , input   wire                           OUT_CHN_READY
    , output  wire                           OUT_CHN_VALID
    , output  wire  [DATA_WIDTH-1:0]         OUT_CHN_DATA
    , output  wire                           OUT_CHN_LAST
    , input   wire  [CHANNEL_FIFO_AW:0]      OUT_CHN_ROOMS // fifo rooms
    , output  wire                           OUT_CHN_MODE
                                             // 0=not use
    // resultant D=D+A*B+C
    , output  wire                           IN_RST_READY
    , input   wire                           IN_RST_VALID
    , input   wire  [DATA_WIDTH-1:0]         IN_RST_DATA
    , input   wire                           IN_RST_LAST
    , input   wire  [RESULT_FIFO_AW:0]       IN_RST_ITEMS // fifo items
    //
    , `DBG_CONV input   wire                           kernel_go
    , `DBG_CONV output  wire                           kernel_done// read-done
    , input   wire  [AXI_WIDTH_AD-1:0]       kernel_address
    , input   wire  [ 3:0]                   kernel_width// num of items in a row of kernel
    , input   wire  [ 3:0]                   kernel_height// num of items in a column of kernel
    , input   wire  [ 7:0]                   kernel_items// num of items in a kernel
    , input   wire  [ 7:0]                   kernel_leng // AxLENG format
    //
    , `DBG_CONV input   wire                           feature_go
    , `DBG_CONV output  wire                           feature_done// read-done
    , input   wire  [AXI_WIDTH_AD-1:0]       feature_address
    , input   wire  [15:0]                   feature_width// num of items in row (i.e., num of columns)
    , input   wire  [15:0]                   feature_height// num of items in column (i.e., num of rows)
    , input   wire  [31:0]                   feature_items// num of items in a feature
    , input   wire  [ 3:0]                   feature_padding_pre
    , input   wire  [ 3:0]                   feature_padding_post
    , input   wire  [ 3:0]                   feature_stride
    , input   wire  [ 7:0]                   feature_leng // AxLENG format
    //
    , `DBG_CONV input   wire                           channel_go
    , `DBG_CONV output  wire                           channel_done// read-done
    , input   wire  [AXI_WIDTH_AD-1:0]       channel_address
    , input   wire  [15:0]                   channel_width
    , input   wire  [15:0]                   channel_height
    , input   wire  [31:0]                   channel_items// num of items whole (not byte)
    , input   wire  [ 7:0]                   channel_leng // AxLENG format
    , input   wire                           channel_mode // 0=no use, 1=use
    //
    , `DBG_CONV input   wire                           result_go
    , `DBG_CONV output  wire                           result_done// read-done
    , input   wire  [AXI_WIDTH_AD-1:0]       result_address
    , input   wire  [15:0]                   result_width
    , input   wire  [15:0]                   result_height
    , input   wire  [31:0]                   result_items// num of items whole (not byte)
    , input   wire  [ 7:0]                   result_leng // AxLENG format
    //
    , input   wire                           conv_init // synchronous initialization
    , output  reg                            conv_ready // to upward
    , input   wire                           conv_core_ready // from convolution_2d_core
    , input   wire                           profile_init
    , output  reg   [PROFILE_CNT_WIDTH-1:0]  profile_cnt_read
    , output  reg   [PROFILE_CNT_WIDTH-1:0]  profile_cnt_write
);
    //--------------------------------------------------------------------------
    // synthesis translate_off
    initial begin
        if (AXI_WIDTH_DA!=32) begin
            $display("%m ERROR AXI-MM data width %d is not supplorted yet.", AXI_WIDTH_DA);
        end
        if ((DATA_WIDTH!=AXI_WIDTH_DA)&&
            (DATA_WIDTH!=(AXI_WIDTH_DA/2))&&
            (DATA_WIDTH!=(AXI_WIDTH_DA/4))) begin
            $display("%m ERROR AXI-Stream data width %d:%d is not supplorted yet.", AXI_WIDTH_DA, DATA_WIDTH);
        end
    end // initial
    // synthesis translate_on
    //--------------------------------------------------------------------------
    reg knl_go=1'b0;
    reg ftu_go=1'b0; // in order to start feature after kernel.
    reg chn_go=1'b0;
    reg rst_go=1'b0;
    //--------------------------------------------------------------------------
    localparam ST_READY       ='h0
             , ST_KERNEL      ='h1
             , ST_KERNEL_DONE ='h2
             , ST_FEATURE     ='h3 
             , ST_FEATURE_DONE='h4 
             , ST_DONE        ='h5;
    `DBG_CONV reg [2:0] state=ST_READY;
    //--------------------------------------------------------------------------
    always @ (posedge ACLK or negedge ARESETn) begin
    if (ARESETn==1'b0) begin
        knl_go       <= 1'b0;
        ftu_go       <= 1'b0;
        chn_go       <= 1'b0;
        rst_go       <= 1'b0;
        conv_ready   <= 1'b0;
        OUT_KNL_MODE <= 2'b0;
        state      <= ST_READY;
    end else if (conv_init==1'b1) begin
        knl_go       <= 1'b0;
        ftu_go       <= 1'b0;
        chn_go       <= 1'b0;
        rst_go       <= 1'b0;
        conv_ready   <= 1'b0;
        OUT_KNL_MODE <= 2'b0;
        state        <= ST_READY;
    end else begin
        case (state)
        ST_READY: begin
           conv_ready <= conv_core_ready;
           if ((conv_core_ready==1'b1)&&(kernel_go==1'b1)) begin
               OUT_KNL_MODE <= 2'b01;
               knl_go       <= 1'b1;
               state        <= ST_KERNEL;
           end
           end // ST_READY
        ST_KERNEL: begin
           if (kernel_done==1'b1) begin
               OUT_KNL_MODE <= 2'b11;
               knl_go       <= 1'b0;
               // kernel_done will be 0 by kernal FSM
               state <= ST_KERNEL_DONE;
           end
           end // ST_KERNEL
        ST_KERNEL_DONE: begin
           if ((feature_go==1'b1)&&(result_go==1'b1)) begin
               ftu_go <= 1'b1;
               chn_go <= 1'b1;
               rst_go <= 1'b1;
               state  <= ST_FEATURE;
           end
           end // ST_KERNEL_DONE
        ST_FEATURE: begin
           if (feature_done==1'b1) begin
               // feature_done will be 0 by feature FSM
               ftu_go <= 1'b0;
           end
           if (channel_done==1'b1) begin
               // feature_done will be 0 by feature FSM
               chn_go <= 1'b0;
           end
           if ((ftu_go==1'b0)&&(chn_go==1'b0)) begin
               state  <= ST_FEATURE_DONE;
           end
           end // ST_FEATURE
        ST_FEATURE_DONE: begin
           if (result_done==1'b1) begin
               rst_go <= 1'b0;
               state  <= ST_DONE;
           end
           end // ST_FEATURE_DONE
        ST_DONE: begin
           if (!(kernel_go|kernel_done|
                 feature_go|feature_done|
                 channel_go|channel_done|
                 result_go|result_done)) begin
               OUT_KNL_MODE <= 2'b00;
               state        <= ST_READY;
           end
           end // ST_DONE
        default: begin
                 knl_go       <= 1'b0;
                 ftu_go       <= 1'b0;
                 rst_go       <= 1'b0;
                 conv_ready   <= 1'b0;
                 OUT_KNL_MODE <= 2'b0;
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
    ST_READY       : state_ascii="READY  ";
    ST_KERNEL      : state_ascii="KERNEL ";
    ST_KERNEL_DONE : state_ascii="KDONE  ";
    ST_FEATURE     : state_ascii="FEATURE";
    ST_FEATURE_DONE: state_ascii="FDONE  ";
    ST_DONE        : state_ascii="DONE   ";
    default        : state_ascii="UNKNOWN";
    endcase
    end
    // synthesis translate_on
    //--------------------------------------------------------------------------
    // fill kernel FIFO.
    convolution_2d_control_kernel #(.AXI_WIDTH_ID   ( AXI_WIDTH_ID      )
                                   ,.AXI_WIDTH_AD   ( AXI_WIDTH_AD      )
                                   ,.AXI_WIDTH_DA   ( AXI_WIDTH_DA      )
                                   ,.DATA_WIDTH     ( DATA_WIDTH        )
                                   ,.FIFO_DEPTH     ( KERNEL_FIFO_DEPTH )
                                   )
    u_kernel (
          .ARESETn        ( ARESETn&~conv_init )
        , .ACLK           ( ACLK               )
        , .AXI_ARID       ( M_AXI_KNL_ARID     )
        , .AXI_ARADDR     ( M_AXI_KNL_ARADDR   )
        , .AXI_ARLEN      ( M_AXI_KNL_ARLEN    )
        , .AXI_ARSIZE     ( M_AXI_KNL_ARSIZE   )
        , .AXI_ARBURST    ( M_AXI_KNL_ARBURST  )
        , .AXI_ARVALID    ( M_AXI_KNL_ARVALID  )
        , .AXI_ARREADY    ( M_AXI_KNL_ARREADY  )
        , .AXI_RID        ( M_AXI_KNL_RID      )
        , .AXI_RDATA      ( M_AXI_KNL_RDATA    )
        , .AXI_RRESP      ( M_AXI_KNL_RRESP    )
        , .AXI_RLAST      ( M_AXI_KNL_RLAST    )
        , .AXI_RVALID     ( M_AXI_KNL_RVALID   )
        , .AXI_RREADY     ( M_AXI_KNL_RREADY   )
        , .OUT_READY      ( OUT_KNL_READY      )
        , .OUT_DATA       ( OUT_KNL_DATA       )
        , .OUT_VALID      ( OUT_KNL_VALID      )
        , .OUT_LAST       ( OUT_KNL_LAST       )
        , .OUT_ROOMS      ( OUT_KNL_ROOMS      )
        , .kernel_go      ( knl_go             )
        , .kernel_done    ( kernel_done        )
        , .kernel_address ( kernel_address     )
        , .kernel_width   ( kernel_width       )
        , .kernel_height  ( kernel_height      )
        , .kernel_items   ( kernel_items       )
        , .kernel_leng    ( kernel_leng        )
    );
    //--------------------------------------------------------------------------
    convolution_2d_control_feature #(.AXI_WIDTH_ID   ( AXI_WIDTH_ID       )
                                    ,.AXI_WIDTH_AD   ( AXI_WIDTH_AD       )
                                    ,.AXI_WIDTH_DA   ( AXI_WIDTH_DA       )
                                    ,.DATA_WIDTH     ( DATA_WIDTH         )
                                    ,.FIFO_DEPTH     ( FEATURE_FIFO_DEPTH )
                                    )
    u_feature (
          .ARESETn             ( ARESETn&~conv_init   )
        , .ACLK                ( ACLK                 )
        , .AXI_ARID            ( M_AXI_FTU_ARID       )
        , .AXI_ARADDR          ( M_AXI_FTU_ARADDR     )
        , .AXI_ARLEN           ( M_AXI_FTU_ARLEN      )
        , .AXI_ARSIZE          ( M_AXI_FTU_ARSIZE     )
        , .AXI_ARBURST         ( M_AXI_FTU_ARBURST    )
        , .AXI_ARVALID         ( M_AXI_FTU_ARVALID    )
        , .AXI_ARREADY         ( M_AXI_FTU_ARREADY    )
        , .AXI_RID             ( M_AXI_FTU_RID        )
        , .AXI_RDATA           ( M_AXI_FTU_RDATA      )
        , .AXI_RRESP           ( M_AXI_FTU_RRESP      )
        , .AXI_RLAST           ( M_AXI_FTU_RLAST      )
        , .AXI_RVALID          ( M_AXI_FTU_RVALID     )
        , .AXI_RREADY          ( M_AXI_FTU_RREADY     )
        , .OUT_READY           ( OUT_FTU_READY        )
        , .OUT_DATA            ( OUT_FTU_DATA         )
        , .OUT_VALID           ( OUT_FTU_VALID        )
        , .OUT_LAST            ( OUT_FTU_LAST         )
        , .OUT_ROOMS           ( OUT_FTU_ROOMS        )
        , .feature_go          ( ftu_go               )
        , .feature_done        ( feature_done         )
        , .feature_address     ( feature_address      )
        , .feature_width       ( feature_width        )
        , .feature_height      ( feature_height       )
        , .feature_items       ( feature_items        )
        , .feature_padding_pre ( feature_padding_pre  )
        , .feature_padding_post( feature_padding_post )
        , .feature_stride      ( feature_stride       )
        , .feature_leng        ( feature_leng         )
        , .kernel_width        ( kernel_width         )
        , .kernel_height       ( kernel_height        )
    );
    //--------------------------------------------------------------------------
    convolution_2d_control_channel #(.AXI_WIDTH_ID ( AXI_WIDTH_ID       )
                                    ,.AXI_WIDTH_AD ( AXI_WIDTH_AD       )
                                    ,.AXI_WIDTH_DA ( AXI_WIDTH_DA       )
                                    ,.DATA_WIDTH   ( DATA_WIDTH         )
                                    ,.FIFO_DEPTH   ( CHANNEL_FIFO_DEPTH )
                                    )
    u_channel (
          .ARESETn             ( ARESETn&~conv_init )
        , .ACLK                ( ACLK               )
        , .AXI_ARID            ( M_AXI_CHN_ARID     )
        , .AXI_ARADDR          ( M_AXI_CHN_ARADDR   )
        , .AXI_ARLEN           ( M_AXI_CHN_ARLEN    )
        , .AXI_ARSIZE          ( M_AXI_CHN_ARSIZE   )
        , .AXI_ARBURST         ( M_AXI_CHN_ARBURST  )
        , .AXI_ARVALID         ( M_AXI_CHN_ARVALID  )
        , .AXI_ARREADY         ( M_AXI_CHN_ARREADY  )
        , .AXI_RID             ( M_AXI_CHN_RID      )
        , .AXI_RDATA           ( M_AXI_CHN_RDATA    )
        , .AXI_RRESP           ( M_AXI_CHN_RRESP    )
        , .AXI_RLAST           ( M_AXI_CHN_RLAST    )
        , .AXI_RVALID          ( M_AXI_CHN_RVALID   )
        , .AXI_RREADY          ( M_AXI_CHN_RREADY   )
        , .OUT_READY           ( OUT_CHN_READY      )
        , .OUT_DATA            ( OUT_CHN_DATA       )
        , .OUT_VALID           ( OUT_CHN_VALID      )
        , .OUT_LAST            ( OUT_CHN_LAST       )
        , .OUT_ROOMS           ( OUT_CHN_ROOMS      )
        , .OUT_MODE            ( OUT_CHN_MODE       )
        , .channel_go          ( chn_go             )
        , .channel_done        ( channel_done       )
        , .channel_address     ( channel_address    )
        , .channel_width       ( channel_width      )
        , .channel_height      ( channel_height     )
        , .channel_items       ( channel_items      )
        , .channel_leng        ( channel_leng       )
        , .channel_mode        ( channel_mode       )
    );
    //--------------------------------------------------------------------------
    convolution_2d_control_result #(.AXI_WIDTH_ID   ( AXI_WIDTH_ID      )
                                   ,.AXI_WIDTH_AD   ( AXI_WIDTH_AD      )
                                   ,.AXI_WIDTH_DA   ( AXI_WIDTH_DA      )
                                   ,.DATA_WIDTH     ( DATA_WIDTH        )
                                   ,.FIFO_DEPTH     ( RESULT_FIFO_DEPTH )
                                   )
    u_result (
          .ARESETn          ( ARESETn&~conv_init )
        , .ACLK             ( ACLK               )
        , .AXI_AWID         ( M_AXI_RST_AWID     )
        , .AXI_AWADDR       ( M_AXI_RST_AWADDR   )
        , .AXI_AWLEN        ( M_AXI_RST_AWLEN    )
        , .AXI_AWSIZE       ( M_AXI_RST_AWSIZE   )
        , .AXI_AWBURST      ( M_AXI_RST_AWBURST  )
        , .AXI_AWVALID      ( M_AXI_RST_AWVALID  )
        , .AXI_AWREADY      ( M_AXI_RST_AWREADY  )
        , .AXI_WDATA        ( M_AXI_RST_WDATA    )
        , .AXI_WSTRB        ( M_AXI_RST_WSTRB    )
        , .AXI_WLAST        ( M_AXI_RST_WLAST    )
        , .AXI_WVALID       ( M_AXI_RST_WVALID   )
        , .AXI_WREADY       ( M_AXI_RST_WREADY   )
        , .AXI_BID          ( M_AXI_RST_BID      )
        , .AXI_BRESP        ( M_AXI_RST_BRESP    )
        , .AXI_BVALID       ( M_AXI_RST_BVALID   )
        , .AXI_BREADY       ( M_AXI_RST_BREADY   )
        , .IN_DATA          ( IN_RST_DATA        )
        , .IN_VALID         ( IN_RST_VALID       )
        , .IN_READY         ( IN_RST_READY       )
        , .IN_LAST          ( IN_RST_LAST        )
        , .IN_ITEMS         ( IN_RST_ITEMS       )
        , .result_go        ( rst_go             )
        , .result_done      ( result_done        )
        , .result_address   ( result_address     )
        , .result_width     ( result_width       )
        , .result_height    ( result_height      )
        , .result_items     ( result_items       )
        , .result_leng      ( result_leng        )
    );
    //--------------------------------------------------------------------------
    wire knl_read =(M_AXI_KNL_RVALID&M_AXI_KNL_RREADY);
    wire ftu_read =(M_AXI_FTU_RVALID&M_AXI_FTU_RREADY);
    wire chn_read =(M_AXI_CHN_RVALID&M_AXI_CHN_RREADY);
    wire rst_write=(M_AXI_RST_WVALID&M_AXI_RST_WREADY);
    //--------------------------------------------------------------------------
    always @ ( posedge ACLK or negedge ARESETn) begin
    if (ARESETn==1'b0) begin
        profile_cnt_read  <= 'h0;
        profile_cnt_write <= 'h0;
    end else if (profile_init==1'b1) begin
        profile_cnt_read  <= 'h0;
        profile_cnt_write <= 'h0;
    end else begin
        case ({knl_read,ftu_read,chn_read})
        3'b001:  profile_cnt_read <= profile_cnt_read + 1;
        3'b010:  profile_cnt_read <= profile_cnt_read + 1;
        3'b100:  profile_cnt_read <= profile_cnt_read + 1;
        3'b011:  profile_cnt_read <= profile_cnt_read + 2;
        3'b110:  profile_cnt_read <= profile_cnt_read + 2;
        3'b101:  profile_cnt_read <= profile_cnt_read + 2;
        3'b111:  profile_cnt_read <= profile_cnt_read + 3;
        default: profile_cnt_read <= profile_cnt_read;
        endcase
        if (rst_write) profile_cnt_write <= profile_cnt_write + 1;
    end // if
    end // always
endmodule

//------------------------------------------------------------------------------
// It fills n x n kernel when mode=01.
// It read-out n x n kernel and write-back n x n kernel when mode=10.
//
//  kernel (i.e., filter) in the memory with row-major contiguous.
//    +---------------------+
//    |                     |
//    +---------------------+
//    |                     |
//    +---------------------+
//    |                     |
//    +---------------------+
//
module convolution_2d_control_kernel
     #(parameter AXI_WIDTH_ID =4       // ID width in bits
               , AXI_WIDTH_AD =32      // address width
               , AXI_WIDTH_DA =32      // data width
               , AXI_WIDTH_DS =AXI_WIDTH_DA/8
               , AXI_WIDTH_DSB=$clog2(AXI_WIDTH_DS)
               , DATA_WIDTH     =32
               , DATA_BYTES     =(DATA_WIDTH/8)// num of bytes per kernel item (1 for byte)
               , KERNEL_MAX_SIZE   =5 // max value
               , FIFO_DEPTH =(KERNEL_MAX_SIZE*KERNEL_MAX_SIZE)
               , FIFO_AW    =$clog2(FIFO_DEPTH )
               )
(
      input   wire                          ARESETn
    , input   wire                          ACLK
    // master port for kernel (read-only)
    , output  wire  [AXI_WIDTH_ID-1:0]      AXI_ARID
    , output  wire  [AXI_WIDTH_AD-1:0]      AXI_ARADDR
    , output  wire  [ 7:0]                  AXI_ARLEN
    , output  wire  [ 2:0]                  AXI_ARSIZE
    , output  wire  [ 1:0]                  AXI_ARBURST
    , output  wire                          AXI_ARVALID
    , input   wire                          AXI_ARREADY
    , input   wire  [AXI_WIDTH_ID-1:0]      AXI_RID
    , input   wire  [AXI_WIDTH_DA-1:0]      AXI_RDATA
    , input   wire  [ 1:0]                  AXI_RRESP
    , input   wire                          AXI_RLAST
    , input   wire                          AXI_RVALID
    , output  wire                          AXI_RREADY
    //
    , input   wire                          OUT_READY
    , output  wire   [DATA_WIDTH-1:0]       OUT_DATA
    , output  wire                          OUT_VALID
    , output  wire                          OUT_LAST
    , input   wire   [FIFO_AW:0]            OUT_ROOMS
    //
    , input   wire                          kernel_go
    , output  reg                           kernel_done// read-done
    , input   wire  [AXI_WIDTH_AD-1:0]      kernel_address
    , input   wire  [ 3:0]                  kernel_width
    , input   wire  [ 3:0]                  kernel_height
    , input   wire  [ 7:0]                  kernel_items
    , input   wire  [ 7:0]                  kernel_leng // AxLENG format
);
    //--------------------------------------------------------------------------
    reg [AXI_WIDTH_ID-1:0] knl_aid={AXI_WIDTH_ID{1'b0}};
    reg [AXI_WIDTH_AD-1:0] knl_addr={AXI_WIDTH_AD{1'b0}};
    reg [ 7:0]             knl_items=8'h0; // num of items whole
    reg [ 7:0]             knl_leng=8'h0; // AxLENG format
    reg [ 7:0]             knl_cnt=8'h0; // keep track of burst
    //--------------------------------------------------------------------------
    localparam ST_READY='h0
             , ST_ADDR ='h1
             , ST_DATA ='h2
             , ST_DONE ='h3
             ;
    reg [1:0] state=ST_READY;
    //--------------------------------------------------------------------------
    always @ (posedge ACLK or negedge ARESETn) begin
    if (ARESETn==1'b0) begin
        knl_aid     <={AXI_WIDTH_ID{1'b0}};
        knl_addr    <={AXI_WIDTH_AD{1'b0}};
        knl_items   <= 8'h0; // num of items whole
        knl_leng    <= 8'h0; // AxLENG format, 0 means length 1
        knl_cnt     <= 8'h0;
        kernel_done <= 1'b0;
        state       <= ST_READY;
    end else begin
        case (state    )
        ST_READY: begin
            if (kernel_go==1'b1) begin
                knl_aid     <= {AXI_WIDTH_ID{1'b0}};
                knl_addr    <= kernel_address;
                knl_items   <= 8'h1;
                knl_leng    <= (kernel_leng<kernel_items) ? kernel_leng 
                                                          : kernel_items -1;
                state       <= ST_ADDR;
                // synthesis translate_off
                if (kernel_width!=kernel_height) begin
                    $display("%0t %m WARNING square kernel is only supported.", $time);
                end
                if (kernel_width[0]!=1'b1) begin
                    $display("%0t %m ERROR kernel width should be odd.", $time);
                end
                if (kernel_items!=kernel_width*kernel_height) begin
                    $display("%0t %m ERROR kernel items mis-match.", $time);
                end
                if (FIFO_DEPTH<(kernel_width*kernel_height)) begin
                    $display("%0t %m ERROR FIFO depth not sufficient.", $time);
                end
                if (OUT_ROOMS!==FIFO_DEPTH) begin
                    $display("%0t %m ERROR kernel fifo not empty.", $time);
                end
                // synthesis translate_on
            end
            end // ST_READY
        ST_ADDR: begin
            if (AXI_ARREADY==1'b1) begin
                knl_cnt <= 'h0;
                state   <= ST_DATA;
                // synthesis translate_off
                if ((AXI_ARADDR<kernel_address)||
                    (AXI_ARADDR>=(kernel_address+kernel_items*DATA_BYTES)))
                    $display("%0t %m ERROR kernel address out-of-bound (start): 0x%08X", $time, AXI_ARADDR);
                if ((AXI_ARADDR+(knl_leng+1)*DATA_BYTES)>(kernel_address+kernel_items*DATA_BYTES))
                    // end address check
                    $display("%0t %m ERROR kernel address out-of-bound (end): 0x%08X",
                              $time, AXI_ARADDR+(knl_leng+1)*DATA_BYTES);
                // synthesis translate_on
            end
            end // ST_ADDR
        ST_DATA: begin
            // mind AXI_ARSIZE that was partial.
            if ((AXI_RVALID==1'b1)&&(AXI_RREADY==1'b1)) begin
                knl_items <= knl_items+1;
                knl_addr  <= knl_addr + DATA_BYTES;
                if (AXI_RLAST==1'b1) begin
                    if (knl_items<kernel_items) begin
                        knl_aid  <= knl_aid + 1;
                        knl_leng <= (kernel_leng<(kernel_items-knl_items))
                                  ? kernel_leng : (kernel_items-knl_items-1);
                        state       <= ST_ADDR;
                    end else begin
                        kernel_done <= 1'b1;
                        state       <= ST_DONE;
                    end
                end
                // synthesis translate_off
                if ((kernel_items==knl_items)&&(AXI_RLAST==1'b0)) begin
                     $display("%0t %m RLAST expected.", $time);
                end
                if ((knl_leng==knl_cnt)&&(AXI_RLAST==1'b0)) begin
                     $display("%0t %m RLAST expected.", $time);
                end
                if (AXI_RRESP!=2'b00) begin
                    $display("%0t %m ERROR RRESP not OK.", $time);
                end
                if (AXI_RID!=knl_aid) begin
                    $display("%0t %m ERROR RID mis-match.", $time);
                end
                // synthesis translate_on
            end
            end // ST_DATA
        ST_DONE: begin
            if (kernel_go==1'b0) begin
                kernel_done   <= 1'b0;
                state         <= ST_READY;
            end
            end // ST_DONE
        default: begin
                 knl_aid         <={AXI_WIDTH_ID{1'b0}};
                 knl_addr        <={AXI_WIDTH_AD{1'b0}};
                 knl_items       <= 8'h0; // num of items whole
                 knl_leng        <= 8'h0; // AxLENG format, 0 means length 1
                 kernel_done     <= 1'b0;
                 state           <= ST_READY;
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
    ST_ADDR : state_ascii="ADDR ";
    ST_DATA : state_ascii="DATA ";
    ST_DONE : state_ascii="DONE ";
    default : state_ascii="UNKNOWN";
    endcase
    end
    // synthesis translate_on
    //--------------------------------------------------------------------------
    assign AXI_ARID    = knl_aid;
    assign AXI_ARADDR  = knl_addr;
    assign AXI_ARLEN   = knl_leng;
    assign AXI_ARVALID = (state==ST_ADDR);
    assign AXI_ARSIZE  = func_get_axsize(DATA_BYTES);
    assign AXI_ARBURST = 2'b01; // incremental
    //--------------------------------------------------------------------------
    // num of kernels per a AIX-MM data width
    localparam NUM_ITEMS=AXI_WIDTH_DA/DATA_WIDTH;
    localparam NUM_BITS=$clog2(DATA_BYTES);
    //--------------------------------------------------------------------------
    assign OUT_VALID = (state==ST_DATA)&&(AXI_RVALID==1'b1);
    assign OUT_DATA  = func_get_data(AXI_RDATA,knl_addr[AXI_WIDTH_DSB-1:0]);
    assign OUT_LAST  = (kernel_items==knl_items) ? AXI_RLAST : 1'b0;
    assign AXI_RREADY= (state==ST_DATA)&&(OUT_READY==1'b1);
    //--------------------------------------------------------------------------
    function [DATA_WIDTH-1:0] func_get_data;
        input [AXI_WIDTH_DA-1:0] data;
        input [AXI_WIDTH_DSB-1:0] offset;
    begin
        if (NUM_ITEMS==1) begin
            func_get_data = data;
        end else begin
            func_get_data = data[DATA_WIDTH*offset[AXI_WIDTH_DSB-1:NUM_BITS]
                                 +: DATA_WIDTH];
        end
    end
    endfunction
    //--------------------------------------------------------------------------
    function [2:0] func_get_axsize;
    input [3:0] bytes;
    begin
        case (bytes)
        4'h01: func_get_axsize = 3'h0;
        4'h02: func_get_axsize = 3'h1;
        4'h04: func_get_axsize = 3'h2;
        4'h08: func_get_axsize = 3'h3;
        default: func_get_axsize = 3'h0;
        endcase
    end
    endfunction
    //--------------------------------------------------------------------------
endmodule

//------------------------------------------------------------------------------
// Horizontal case:
//   a: intra-kernel row
//   b: intra-kernel column
//   x: inter-kernel row
//   y: inter-kernel column
//
//       --(x)-->
//      +-------+------------------------+
//    | |-(a)-> |                        |
//    | ||      |                        |
//    | |(b)    |                        |
//    | +-------+------------------------+
//   (y)|                                |
//      |                                |
//      |                                |
//      |                                |
//      +--------------------------------+
//
//  do {
//        do {
//              do {
//                   do {
//                        a++;
//                   } while (a<kwidth);
//                   b++;
//              } while (b<kheight);
//              x++;
//        } while (x<width);
//        y++;
//  } while (y<height);
//
// [When padding exists]
//       ------> (x)
//        padding_pre                           padding_post
//       |    |                                |     |
//       +-------------------------------------------+ ___
//       |                                           | padding_pre
//       |    +-------+------------------------+     | ___
//    |  |    |-(a)-> |                        |     |
//    |  |    ||     ........................................................kernel-window
//    |  |    |(b)    |                        |     |
//    |  |    +-------+------------------------+     |
//   (y) |    |                                |     |
//       |    |                                |     |
//       |    |                                |     |
//       |    |                                |     |
//       |    +--------------------------------+     | ___
//       |                                           |
//       |                                           | padding_post
//       +-------------------------------------------+ ___
//
//
//  idy: starting index Y of kernel-window
//  idy+idb: starting address of each line (row) of kernel-window
//  idx: staring indxe X of kernel-window
//
module convolution_2d_control_feature
     #(parameter AXI_WIDTH_ID =4       // ID width in bits
               , AXI_WIDTH_AD =32      // address width
               , AXI_WIDTH_DA =32      // data width
               , AXI_WIDTH_DS =AXI_WIDTH_DA/8
               , AXI_WIDTH_DSB=$clog2(AXI_WIDTH_DS)
               , DATA_WIDTH     =32
               , DATA_BYTES     =(DATA_WIDTH/8)// num of bytes per feature item (1 for byte)
               , FIFO_DEPTH =32
               , FIFO_AW    =$clog2(FIFO_DEPTH )
               )
(
      input   wire                       ARESETn
    , input   wire                       ACLK
    // master port for kernel (read-only)
    , output  wire  [AXI_WIDTH_ID-1:0]   AXI_ARID
    , output  wire  [AXI_WIDTH_AD-1:0]   AXI_ARADDR
    , output  wire  [ 7:0]               AXI_ARLEN
    , output  wire  [ 2:0]               AXI_ARSIZE
    , output  wire  [ 1:0]               AXI_ARBURST
    , output  wire                       AXI_ARVALID
    , input   wire                       AXI_ARREADY
    , input   wire  [AXI_WIDTH_ID-1:0]   AXI_RID
    , input   wire  [AXI_WIDTH_DA-1:0]   AXI_RDATA
    , input   wire  [ 1:0]               AXI_RRESP
    , input   wire                       AXI_RLAST
    , input   wire                       AXI_RVALID
    , output  wire                       AXI_RREADY
    //
    , input   wire                       OUT_READY
    , output  wire  [DATA_WIDTH-1:0]     OUT_DATA
    , output  wire                       OUT_VALID
    , output  wire                       OUT_LAST // driven high at the end of kernel-block
    , input   wire  [FIFO_AW:0]          OUT_ROOMS 
    //
    , input   wire                       feature_go
    , output  reg                        feature_done// read-done
    , input   wire  [AXI_WIDTH_AD-1:0]   feature_address
    , input   wire  [15:0]               feature_width// num of items in row
    , input   wire  [15:0]               feature_height// num of items in column
    , input   wire  [31:0]               feature_items // not including padding
    , input   wire  [ 3:0]               feature_padding_pre
    , input   wire  [ 3:0]               feature_padding_post
    , input   wire  [ 3:0]               feature_stride
    , input   wire  [ 7:0]               feature_leng // AxLENG format (not used here)
    , input   wire  [ 3:0]               kernel_width// num of items in a row of kernel
    , input   wire  [ 3:0]               kernel_height// num of items in a column of kernel
);
    //--------------------------------------------------------------------------
    // in order to make use of negative number in calculation
    wire signed [16:0] ftu_width       =feature_width       ;
    wire signed [16:0] ftu_height      =feature_height      ;
    wire signed [ 4:0] ftu_padding_pre =feature_padding_pre ;
    wire signed [ 4:0] ftu_padding_post=feature_padding_post;
    wire signed [ 4:0] ftu_stride      =feature_stride      ;
    wire signed [ 4:0] knl_width       =kernel_width        ;
    wire signed [ 4:0] knl_height      =kernel_height       ;
    //--------------------------------------------------------------------------
    reg signed [16:0] idy=17'h0; // keep tracking feature_height
    reg signed [16:0] idx=17'h0; // keep tracking feature_width
    reg signed [ 4:0] idb= 5'h0; // keep tracking kernel_height
    //--------------------------------------------------------------------------
    reg        [AXI_WIDTH_ID-1:0] ftu_aid={AXI_WIDTH_ID{1'b0}};
    reg        [AXI_WIDTH_AD-1:0] ftu_addr={AXI_WIDTH_AD{1'b0}};
    reg signed [ 8:0]             cnt_leng=9'h0; // AxLENG format
    reg signed [ 8:0]             cnt_bcnt=9'h0; // tracking burst
    reg signed [ 4:0]             cnt_pre=5'h0; // zero padding pre
    reg signed [ 4:0]             cnt_post=5'h0; // zero padding post
    reg signed [ 4:0]             cnt_pad=5'h0; // padding counter
    reg        [31:0]             cnt_items=32'h0; // num of items whole, not including paddings
    reg        [15:0]             cnt_knum=16'h0; // num of kernel-blocks
    //--------------------------------------------------------------------------
    reg  [31:0] kernel_num='h0; // num of kernels to read
    //--------------------------------------------------------------------------
    localparam ST_READY  ='h0
             , ST_ADDR   ='h1
             , ST_PRE    ='h2
             , ST_DATA   ='h3
             , ST_POST   ='h4
             , ST_CALCU  ='h5
             , ST_PADDING='h6
             , ST_DONE   ='h7;
    reg [2:0] state=ST_READY;
    //--------------------------------------------------------------------------
    always @ (posedge ACLK or negedge ARESETn) begin
    if (ARESETn==1'b0) begin
        feature_done <= 1'b0;
        idb          <= 5'h0;
        idx          <=17'h0;
        idy          <=17'h0;
        ftu_aid      <={AXI_WIDTH_ID{1'b0}};
        ftu_addr     <={AXI_WIDTH_AD{1'b0}};
        cnt_leng     <= 9'h0;
        cnt_bcnt     <= 9'h0;
        cnt_pre      <= 5'h0;
        cnt_post     <= 5'h0;
        cnt_pad      <= 5'h0;
        cnt_items    <=32'h0;
        cnt_knum     <=16'h0;
        kernel_num   <=32'h0; // num of kernels to read
        state       <= ST_READY;
    end else begin
        case (state)
        ST_READY: begin
           if (feature_go==1'b1) begin
               ftu_aid      <={AXI_WIDTH_ID{1'b0}};
               ftu_addr     <= feature_address;
               cnt_leng     <= knl_width-1; // mind AxLENG format (0 means length 1)
               cnt_bcnt     <=  9'h0;
               cnt_pre      <=  5'h0;
               cnt_post     <=  5'h0;
               cnt_pad      <=  5'h0;
               cnt_items    <= 32'h0;
               cnt_knum     <= 16'h0;
               kernel_num   <= (((ftu_width-knl_width+ftu_padding_pre+ftu_padding_post)/ftu_stride)+1)
                                *(((ftu_height-knl_height+ftu_padding_pre+ftu_padding_post)/ftu_stride)+1);
               idb          <=  5'h0;
               idx          <= -ftu_padding_pre;
               idy          <= -ftu_padding_pre;
               state        <= (ftu_padding_pre!=0) ? ST_CALCU : ST_ADDR;
               // synthesis translate_off
               if (ftu_width!=ftu_height) begin
                   $display("%0t %m WARNING only support square feature.", $time);
               end
               if (feature_items!=ftu_width*ftu_height) begin
                   $display("%0t %m ERROR feature items mis-match.", $time);
               end
               // synthesis translate_on
           end
           end // ST_READY
        ST_ADDR: begin
           if ((AXI_ARVALID==1'b1)&&(AXI_ARREADY==1'b1)) begin
                cnt_bcnt <=  8'h0; // burst counter
                state    <= (cnt_pre==0) ? ST_DATA : ST_PRE;
                // synthesis translate_off
                if ((AXI_ARADDR<feature_address)||
                    (AXI_ARADDR>=(feature_address+feature_items*DATA_BYTES)))
                    // start address check
                    $display("%0t %m ERROR feature address out-of-bound (start): 0x%08X",
                              $time, AXI_ARADDR);
                if ((AXI_ARADDR+(cnt_leng+1)*DATA_BYTES)>(feature_address+feature_items*DATA_BYTES)) begin
                    // end address check
                    $display("%0t %m ERROR feature address out-of-bound (end): 0x%08X:%08X",
                              $time, AXI_ARADDR+(cnt_leng+1)*DATA_BYTES
                                   , (feature_address+feature_items*DATA_BYTES));
                end
                // synthesis translate_on
           end
           end // ST_ADDR
        ST_PRE: begin
           // filling zero-padding before getting data from bus
           if ((OUT_VALID==1'b1)&&(OUT_READY==1'b1)) begin
               cnt_pad <= cnt_pad + 1;
               if ((cnt_pad+1)==cnt_pre) begin
                   state <= ST_DATA;
               end
           end
           end // ST_PRE
        ST_DATA: begin
           if ((AXI_RVALID==1'b1)&&(AXI_RREADY==1'b1)) begin
               // calculate next addressi
               ftu_addr  <= ftu_addr + DATA_BYTES;
               cnt_bcnt  <= cnt_bcnt + 1;
               cnt_items <= cnt_items + 1;
               if (AXI_RLAST==1'b1) begin
                   state  <= (cnt_post==0) ? ST_CALCU : ST_POST;
                   // update idy, idb, idx if required
                   idb <= idb + 1;
                   if ((idb+1)==knl_height) begin
                        cnt_knum <= cnt_knum + 1;
                        idb      <= 5'h0;
                        idx      <= idx + ftu_stride;
                        if ((idx+ftu_stride)>(ftu_width+ftu_padding_post-knl_width)) begin
                            idx  <= -ftu_padding_pre;
                            idy  <= idy + ftu_stride;
                            if ((idy+ftu_stride)>(ftu_height+ftu_padding_post-knl_height)) begin
                                 feature_done <= 1'b1;
                                 state        <= (cnt_post==0) ? ST_DONE : ST_POST;
                            end
                        end
                   end
                   // synthesis translate_off
                   if (cnt_bcnt!=cnt_leng) // note cnt_leng is AxLENG format.
                       $display("%0t %m ERROR burst length mis-match.", $time);
                   // synthesis translate_on
               end
           end
           end // ST_DATA
        ST_POST: begin
           // filling zero-padding after getting data from bus
           // There is noway to go 'ST_DONE' from this state
           if ((OUT_VALID==1'b1)&&(OUT_READY==1'b1)) begin
               cnt_pad <= cnt_pad + 1;
               if ((cnt_pad+1)==cnt_post) begin
                   state <= ST_CALCU;
               end
           end
           end // ST_PRE
        ST_CALCU: begin
           cnt_pad <= 4'h0;
           if (((idy+idb)>=0)&&((idy+idb)<(ftu_height))) begin
               ftu_aid  <= ftu_aid  + 1;
               if (idx<0) begin
                   ftu_addr <= feature_address + $unsigned($signed(idy+idb)*ftu_width*DATA_BYTES);
                   cnt_leng <= knl_width+idx-1; // mind idx is negative is AxLENG format
                   cnt_pre  <= -idx; // knl_width-(cnt_leng+1): mind idx is negative
                   cnt_post <= 4'h0;
               end else if (idx>=(ftu_width-knl_width)) begin
                   ftu_addr <= feature_address + $unsigned(($signed(idy+idb)*ftu_width*DATA_BYTES) + idx*DATA_BYTES);
                   cnt_leng <= ftu_width-idx-1; // mind idx is positive and is AxLENG format
                   cnt_pre  <= 4'h0;
                   cnt_post <= knl_width-(ftu_width-idx); // knl_width-(cnt_leng+1): mind idx is negative
               end else begin
                   ftu_addr <= feature_address + $unsigned(($signed(idy+idb)*ftu_width*DATA_BYTES) + idx*DATA_BYTES);
                   cnt_leng <= knl_width-1;
                   cnt_pre  <= 4'h0;
                   cnt_post <= 4'h0;
               end
               state <= ST_ADDR;
           end else begin
               // zero kernel line on padding
               cnt_leng <= 0;
               cnt_pre  <= knl_width;
               cnt_post <= 4'h0;
               state    <= ST_PADDING;
           end
           end // ST_CALCU
        ST_PADDING: begin
           // filling padding a kernel-line
           if ((OUT_VALID==1'b1)&&(OUT_READY==1'b1)) begin
               cnt_pad <= cnt_pad + 1;
               if ((cnt_pad+1)==cnt_pre) begin // equivalance TLAST
                   state <= ST_CALCU;
                   idb   <= idb + 1;
                   if ((idb+1)==knl_height) begin
                        cnt_knum <= cnt_knum + 1;
                        idb      <= 5'h0;
                        idx      <= idx + ftu_stride;
                        if ((idx+ftu_stride)>(ftu_width+ftu_padding_post-knl_width)) begin
                            idx <= -ftu_padding_pre;
                            idy <= idy + ftu_stride;
                            if ((idy+ftu_stride)>(ftu_height+ftu_padding_post-knl_height)) begin
                                 feature_done <= 1'b1;
                                 state        <= ST_DONE;
                            end
                        end
                   end
               end
           end
           end // ST_PADDING
        ST_DONE: begin
           if (feature_go==1'b0) begin
               feature_done <= 1'b0;
               state       <= ST_READY;
               // synthesis translate_off
               if (cnt_knum!=kernel_num) begin
                   $display("%0t %m kernel-block number mis-match: %0d %0d",
                              $time, cnt_knum, kernel_num);
               end
               // synthesis translate_on
           end
           end // ST_DONE
        default: begin
                 feature_done <= 1'b0;
                 idb          <= 5'h0;
                 idx          <=17'h0;
                 idy          <=17'h0;
                 ftu_aid      <={AXI_WIDTH_ID{1'b0}};
                 ftu_addr     <={AXI_WIDTH_AD{1'b0}};
                 cnt_leng     <= 9'h0;
                 cnt_bcnt     <= 9'h0;
                 cnt_pre      <= 5'h0;
                 cnt_post     <= 5'h0;
                 cnt_pad      <= 5'h0;
                 cnt_items    <=32'h0;
                 cnt_knum     <=16'h0;
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
    ST_READY  : state_ascii="READY  ";
    ST_ADDR   : state_ascii="ADDR   ";
    ST_PRE    : state_ascii="PRE    ";
    ST_DATA   : state_ascii="DATA   ";
    ST_POST   : state_ascii="POST   ";
    ST_CALCU  : state_ascii="CALCU  ";
    ST_PADDING: state_ascii="PADDING";
    ST_DONE   : state_ascii="DONE   ";
    default  : state_ascii="UNKNOWN";
    endcase
    end
    // synthesis translate_on
    //--------------------------------------------------------------------------
    assign AXI_ARID    = ftu_aid;
    assign AXI_ARADDR  = ftu_addr;
    assign AXI_ARLEN   = cnt_leng;
    assign AXI_ARSIZE  = func_get_axsize(DATA_BYTES);
    assign AXI_ARBURST = 2'b01; // incremental
    assign AXI_ARVALID = (state==ST_ADDR);
    //--------------------------------------------------------------------------
    assign AXI_RREADY  = (state==ST_DATA) ? OUT_READY : 1'b0;
    //--------------------------------------------------------------------------
    assign OUT_VALID = ((state==ST_DATA)&&(AXI_RVALID==1'b1))
                     || (state==ST_PRE)||(state==ST_POST)||(state==ST_PADDING);
    assign OUT_DATA  = (state==ST_DATA) ? func_get_data(AXI_RDATA
                                                       ,ftu_addr[AXI_WIDTH_DSB-1:0])
                                        : {DATA_WIDTH{1'b0}};
    // OUT_LAST driven at the end of kernel-block
    assign OUT_LAST  = ((state==ST_DATA)&&((idb+1)==knl_height)&&(cnt_post==5'h0)) ? AXI_RLAST
                     : ((state==ST_POST)&&(idb==5'h0)&&(cnt_post==(cnt_pad+1))) ? 1'b1
                     : ((state==ST_PADDING)&&((idb+1)==knl_height)&&((cnt_pad+1)==cnt_pre)) ? 1'b1 : 1'b0;
    //--------------------------------------------------------------------------
    function [2:0] func_get_axsize;
    input [3:0] bytes;
    begin
        case (bytes)
        4'h01: func_get_axsize = 3'h0;
        4'h02: func_get_axsize = 3'h1;
        4'h04: func_get_axsize = 3'h2;
        4'h08: func_get_axsize = 3'h3;
        default: func_get_axsize = 3'h0;
        endcase
    end
    endfunction
    //--------------------------------------------------------------------------
    // num of kernels per a AIX-MM data width
    localparam NUM_ITEMS=AXI_WIDTH_DA/DATA_WIDTH;
    localparam NUM_BITS=$clog2(DATA_BYTES);
    //--------------------------------------------------------------------------
    function [DATA_WIDTH-1:0] func_get_data;
        input [AXI_WIDTH_DA-1:0] data;
        input [AXI_WIDTH_DSB-1:0] offset;
    begin
        if (NUM_ITEMS==1) begin
            func_get_data = data;
        end else begin
            func_get_data = data[DATA_WIDTH*offset[AXI_WIDTH_DSB-1:NUM_BITS]
                                 +: DATA_WIDTH];
        end
    end
    endfunction
endmodule

//------------------------------------------------------------------------------
// It read feature map data of previous convolution
module convolution_2d_control_channel
     #(parameter AXI_WIDTH_ID =4       // ID width in bits
               , AXI_WIDTH_AD =32      // address width
               , AXI_WIDTH_DA =32      // data width
               , AXI_WIDTH_DS =AXI_WIDTH_DA/8
               , AXI_WIDTH_DSB=$clog2(AXI_WIDTH_DS)
               , DATA_WIDTH     =32
               , DATA_BYTES     =(DATA_WIDTH/8)// num of bytes per kernel item (1 for byte)
               , FIFO_DEPTH =16
               , FIFO_AW    =$clog2(FIFO_DEPTH )
               )
(
      input   wire                          ARESETn
    , input   wire                          ACLK
    // master port for kernel (read-only)
    , output  wire  [AXI_WIDTH_ID-1:0]      AXI_ARID
    , output  wire  [AXI_WIDTH_AD-1:0]      AXI_ARADDR
    , output  wire  [ 7:0]                  AXI_ARLEN
    , output  wire  [ 2:0]                  AXI_ARSIZE
    , output  wire  [ 1:0]                  AXI_ARBURST
    , output  wire                          AXI_ARVALID
    , input   wire                          AXI_ARREADY
    , input   wire  [AXI_WIDTH_ID-1:0]      AXI_RID
    , input   wire  [AXI_WIDTH_DA-1:0]      AXI_RDATA
    , input   wire  [ 1:0]                  AXI_RRESP
    , input   wire                          AXI_RLAST
    , input   wire                          AXI_RVALID
    , output  wire                          AXI_RREADY
    //
    , input   wire                          OUT_READY
    , output  wire   [DATA_WIDTH-1:0]       OUT_DATA
    , output  wire                          OUT_VALID
    , output  wire                          OUT_LAST
    , input   wire   [FIFO_AW:0]            OUT_ROOMS
    , output  reg                           OUT_MODE
    //
    , input   wire                          channel_go
    , output  reg                           channel_done// read-done
    , input   wire  [AXI_WIDTH_AD-1:0]      channel_address
    , input   wire  [15:0]                  channel_width
    , input   wire  [15:0]                  channel_height
    , input   wire  [31:0]                  channel_items
    , input   wire  [ 7:0]                  channel_leng // AxLENG format
    , input   wire                          channel_mode // 0=disabled
);
    //--------------------------------------------------------------------------
    reg [AXI_WIDTH_ID-1:0] chn_aid={AXI_WIDTH_ID{1'b0}};
    reg [AXI_WIDTH_AD-1:0] chn_addr={AXI_WIDTH_AD{1'b0}};
    reg [31:0]             chn_items=32'h0; // num of items whole
    reg [ 7:0]             chn_leng=8'h0; // AxLENG format
    reg [ 7:0]             chn_cnt=8'h0; // keep track of burst
    //- ----------------------------------------------------------------------
    localparam ST_READY='h0
             , ST_WAIT ='h2
             , ST_ADDR ='h3
             , ST_DATA ='h4
             , ST_DONE ='h5
             ;
    reg [2:0] state=ST_READY;
    //--------------------------------------------------------------------------
    always @ (posedge ACLK or negedge ARESETn) begin
    if (ARESETn==1'b0) begin
        chn_aid      <={AXI_WIDTH_ID{1'b0}};
        chn_addr     <={AXI_WIDTH_AD{1'b0}};
        chn_items    <=32'h0; // num of items whole
        chn_leng     <= 8'h0; // AxLENG format, 0 means length 1
        chn_cnt      <= 8'h0;
        channel_done <= 1'b0;
        OUT_MODE     <= 1'b0;
        state        <= ST_READY;
    end else begin
        case (state    )
        ST_READY: begin
            OUT_MODE <= channel_mode;
            if (channel_go==1'b1) begin
                if ((channel_mode==1'b1)&&(channel_width>0)&&(channel_height>0)) begin
                    chn_aid     <={AXI_WIDTH_ID{1'b0}};
                    chn_addr    <= channel_address;
                    chn_items   <= 32'h1;
                    chn_leng    <= (channel_leng<channel_items) ? channel_leng 
                                                                : channel_items -1;
                    state       <= ST_WAIT;
                    // synthesis translate_off
                    if (channel_width!=channel_height) begin
                        $display("%0t %m WARNING square is only supported.", $time);
                    end
                    if (channel_items!=channel_width*channel_height) begin
                        $display("%0t %m ERROR channel items mis-match.", $time);
                    end
                    if (FIFO_DEPTH<=channel_leng) begin
                        $display("%0t %m ERROR FIFO depth not sufficient.", $time);
                    end
                    if (OUT_ROOMS!==FIFO_DEPTH) begin
                        $display("%0t %m ERROR kernel fifo not empty.", $time);
                    end
                    // synthesis translate_on
                end else begin
                    channel_done <= 1'b1;
                    state       <= ST_DONE;
                end
            end
            end // ST_READY
        ST_WAIT: begin // wait for sufficient rooms
            if (OUT_ROOMS>chn_leng) begin
                chn_cnt <= 'h0;
                state   <= ST_ADDR;
            end
            end // ST_WAIT
        ST_ADDR: begin
            if (AXI_ARREADY==1'b1) begin
                state <= ST_DATA;
                // synthesis translate_off
                if ((AXI_ARADDR<channel_address)||
                    (AXI_ARADDR>=(channel_address+channel_items*DATA_BYTES)))
                    $display("%0t %m ERROR channel address out-of-bound (start): 0x%08X", $time, AXI_ARADDR);
                if ((AXI_ARADDR+(chn_leng+1)*DATA_BYTES)>(channel_address+channel_items*DATA_BYTES))
                    // end address check
                    $display("%0t %m ERROR channel address out-of-bound (end): 0x%08X",
                              $time, AXI_ARADDR+(chn_leng+1)*DATA_BYTES);
                // synthesis translate_on
            end
            end // ST_ADDR
        ST_DATA: begin
            // mind AXI_ARSIZE that was partial.
            if ((AXI_RVALID==1'b1)&&(AXI_RREADY==1'b1)) begin
                chn_items <= chn_items+1;
                chn_addr  <= chn_addr + DATA_BYTES;
                chn_cnt   <= chn_cnt + 1;
                if (AXI_RLAST==1'b1) begin
                    if (chn_items<channel_items) begin
                        chn_aid  <= chn_aid + 1;
                        chn_leng <= (channel_leng<(channel_items-chn_items))
                                  ? channel_leng : (channel_items-chn_items-1);
                        state    <= ST_WAIT; // since it is not latency critical
                    end else begin
                        channel_done <= 1'b1;
                        state       <= ST_DONE;
                    end
                end
                // synthesis translate_off
                if ((channel_items==chn_items)&&(AXI_RLAST==1'b0)) begin
                     $display("%0t %m RLAST expected.", $time);
                end
                if ((chn_leng==chn_cnt)&&(AXI_RLAST==1'b0)) begin
                     $display("%0t %m RLAST expected.", $time);
                end
                if (AXI_RRESP!=2'b00) begin
                    $display("%0t %m ERROR RRESP not OK.", $time);
                end
                if (AXI_RID!=chn_aid) begin
                    $display("%0t %m ERROR RID mis-match.", $time);
                end
                // synthesis translate_on
            end
            end // ST_DATA
        ST_DONE: begin
            if (channel_go==1'b0) begin
                channel_done   <= 1'b0;
                state         <= ST_READY;
            end
            end // ST_DONE
        default: begin
                 chn_aid         <={AXI_WIDTH_ID{1'b0}};
                 chn_addr        <={AXI_WIDTH_AD{1'b0}};
                 chn_items       <=32'h0; // num of items whole
                 chn_leng        <= 8'h0; // AxLENG format, 0 means length 1
                 channel_done    <= 1'b0;
                 state           <= ST_READY;
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
    ST_ADDR : state_ascii="ADDR ";
    ST_DATA : state_ascii="DATA ";
    ST_DONE : state_ascii="DONE ";
    default : state_ascii="UNKNOWN";
    endcase
    end
    // synthesis translate_on
    //--------------------------------------------------------------------------
    assign AXI_ARID   = chn_aid;
    assign AXI_ARADDR = chn_addr;
    assign AXI_ARLEN  = chn_leng;
    assign AXI_ARVALID= (state==ST_ADDR);
    assign AXI_ARSIZE = func_get_axsize(DATA_BYTES);
    assign AXI_ARBURST= 2'b01; // incremental
    //--------------------------------------------------------------------------
    // num of kernels per a AIX-MM data width
    localparam NUM_ITEMS=AXI_WIDTH_DA/DATA_WIDTH;
    localparam NUM_BITS=$clog2(DATA_BYTES);
    //--------------------------------------------------------------------------
    assign  OUT_VALID = (state==ST_DATA)&&(AXI_RVALID==1'b1);
    assign  OUT_DATA  = func_get_data(AXI_RDATA,chn_addr[AXI_WIDTH_DSB-1:0]);
    assign  OUT_LAST  = (channel_items==chn_items) ? AXI_RLAST : 1'b0;
    assign  AXI_RREADY= (state==ST_DATA)&&(OUT_READY==1'b1);
    //--------------------------------------------------------------------------
    function [DATA_WIDTH-1:0] func_get_data;
        input [AXI_WIDTH_DA-1:0] data;
        input [AXI_WIDTH_DSB-1:0] offset;
    begin
        if (NUM_ITEMS==1) begin
            func_get_data = data;
        end else begin
            func_get_data = data[DATA_WIDTH*offset[AXI_WIDTH_DSB-1:NUM_BITS]
                                 +: DATA_WIDTH];
        end
    end
    endfunction
    //--------------------------------------------------------------------------
    function [2:0] func_get_axsize;
    input [3:0] bytes;
    begin
        case (bytes)
        4'h01: func_get_axsize = 3'h0;
        4'h02: func_get_axsize = 3'h1;
        4'h04: func_get_axsize = 3'h2;
        4'h08: func_get_axsize = 3'h3;
        default: func_get_axsize = 3'h0;
        endcase
    end
    endfunction
    //--------------------------------------------------------------------------
endmodule

//------------------------------------------------------------------------------
module convolution_2d_control_result
     #(parameter AXI_WIDTH_ID =4       // ID width in bits
               , AXI_WIDTH_AD =32      // address width
               , AXI_WIDTH_DA =32      // data width
               , AXI_WIDTH_DS =(AXI_WIDTH_DA/8)
               , AXI_WIDTH_DSB=$clog2(AXI_WIDTH_DS)
               , DATA_WIDTH     =32
               , DATA_BYTES     =(DATA_WIDTH/8)// num of bytes per result item (1 for byte)
               , FIFO_DEPTH=32
               , FIFO_AW   =$clog2(FIFO_DEPTH)
               )
(
      input   wire                          ARESETn
    , input   wire                          ACLK
    , output  wire  [AXI_WIDTH_ID-1:0]      AXI_AWID
    , output  wire  [AXI_WIDTH_AD-1:0]      AXI_AWADDR
    , output  wire  [ 7:0]                  AXI_AWLEN
    , output  wire  [ 2:0]                  AXI_AWSIZE
    , output  wire  [ 1:0]                  AXI_AWBURST
    , output  wire                          AXI_AWVALID
    , input   wire                          AXI_AWREADY
    , output  wire  [AXI_WIDTH_DA-1:0]      AXI_WDATA
    , output  wire  [AXI_WIDTH_DS-1:0]      AXI_WSTRB
    , output  wire                          AXI_WLAST
    , output  wire                          AXI_WVALID
    , input   wire                          AXI_WREADY
    , input   wire  [AXI_WIDTH_ID-1:0]      AXI_BID
    , input   wire  [ 1:0]                  AXI_BRESP
    , input   wire                          AXI_BVALID
    , output  wire                          AXI_BREADY
    //
    , input   wire   [DATA_WIDTH-1:0]       IN_DATA
    , input   wire                          IN_VALID
    , output  wire                          IN_READY
    , input   wire                          IN_LAST
    , input   wire   [FIFO_AW:0]            IN_ITEMS
    //
    , input   wire                          result_go
    , output  reg                           result_done// read-done
    , input   wire  [AXI_WIDTH_AD-1:0]      result_address
    , input   wire  [15:0]                  result_width
    , input   wire  [15:0]                  result_height
    , input   wire  [31:0]                  result_items// num of items whole
    , input   wire  [ 7:0]                  result_leng // AxLENG format
);
    //--------------------------------------------------------------------------
    reg  [AXI_WIDTH_ID-1:0] rst_aid={AXI_WIDTH_ID{1'b0}};
    reg  [AXI_WIDTH_AD-1:0] rst_addr={AXI_WIDTH_AD{1'b0}};
    reg  [31:0]             rst_items=32'h0; // num of items whole
    reg  [ 7:0]             rst_leng=8'h0; // AxLENG format
    reg  [ 7:0]             rst_cnt=8'h0; // keep track of burst
    //--------------------------------------------------------------------------
    // num of kernels per a AIX-MM data width
    localparam NUM_ITEMS=AXI_WIDTH_DA/DATA_WIDTH;
    localparam NUM_BITS=$clog2(DATA_BYTES);
    //--------------------------------------------------------------------------
    localparam ST_READY='h0
             , ST_WAIT ='h1
             , ST_ADDR ='h2
             , ST_DATA ='h3
             , ST_RESP ='h4
             , ST_DONE ='h5
             ;
    reg [2:0] state=ST_READY;
    //--------------------------------------------------------------------------
    always @ (posedge ACLK or negedge ARESETn) begin
    if (ARESETn==1'b0) begin
        rst_aid         <={AXI_WIDTH_ID{1'b0}};
        rst_addr        <={AXI_WIDTH_AD{1'b0}};
        rst_items       <=32'h0; // num of items whole
        rst_leng        <= 8'h0; // AxLENG format, 0 means length 1
        rst_cnt         <= 8'h0;
        result_done     <= 1'b0;
        state           <= ST_READY;
    end else begin
        case (state)
        ST_READY: begin
            if (result_go==1'b1) begin
                rst_aid   <={AXI_WIDTH_ID{1'b0}};
                rst_addr  <= result_address;
                rst_items <= 32'h0;
                rst_leng  <= (result_leng<result_items) ? result_leng 
                                                        : result_items -1;
                state       <= ST_WAIT;
                // synthesis translate_off
                if (result_width!=result_height) begin
                    $display("%0t %m WARNING square is only supported.", $time);
                end
                if (result_items!=result_width*result_height) begin
                    $display("%0t %m ERROR result items mis-match.", $time);
                end
                if (IN_ITEMS!=={FIFO_AW+1{1'b0}}) begin
                    $display("%0t %m ERROR result fifo not empty.", $time);
                end
                if (FIFO_DEPTH<(result_leng+1)) begin
                    $display("%0t %m ERROR FIFO depth mis-match: %0d %0d.", $time, FIFO_DEPTH, result_leng+1);
                end
                // synthesis translate_on
            end
            end // ST_DATA1
        ST_WAIT: begin // wait for sufficients items
            if (IN_ITEMS>rst_leng) begin
                rst_items   <= rst_items + (rst_leng+1);
                rst_cnt     <= 8'h0;
                state       <= ST_ADDR;
            end
            end // ST_WAIT
        ST_ADDR: begin
            if (AXI_AWREADY==1'b1) begin
                state <= ST_DATA;
                // synthesis translate_off
                if ((AXI_AWADDR<result_address)||
                    (AXI_AWADDR>=(result_address+result_items*DATA_BYTES)))
                    $display("%0t %m ERROR result address out-of-bound (start): 0x%08X", $time, AXI_AWADDR);
                if ((AXI_AWADDR+(rst_leng+1)*DATA_BYTES)>(result_address+result_items*DATA_BYTES))
                    // end address check
                    $display("%0t %m ERROR result address out-of-bound (end): 0x%08X",
                              $time, AXI_AWADDR+(rst_leng+1)*DATA_BYTES);
                // synthesis translate_on
            end
            end // ST_ADDR
        ST_DATA: begin
            // mind AXI_AWSISE that is partial.
            if ((AXI_WREADY==1'b1)&&(AXI_WVALID==1'b1)) begin
                rst_addr  <= rst_addr + DATA_BYTES;
                rst_cnt   <= rst_cnt + 1;
                if (AXI_WLAST==1'b1) begin
                    state <= ST_RESP;
                end
                // synthesis translate_off
                if ((rst_leng==rst_cnt)&&(AXI_WLAST==1'b0)) begin
                     $display("%0t %m WLAST expected.", $time);
                end
              //if ((result_items==rst_items)&&(AXI_WLAST!=1'b0)) begin
              //     $display("%0t %m WLAST expected.", $time);
              //end
                // synthesis translate_on
            end
            end // ST_DATA
        ST_RESP: begin
            if (AXI_BVALID==1'b1) begin
                if (rst_items==result_items) begin
                    result_done     <= 1'b1;
                    state           <= ST_DONE;
                end else begin
                    rst_aid   <= rst_aid + 1;
                    rst_leng  <= (result_leng<(result_items-rst_items))
                               ? result_leng : (result_items-rst_items-1);
                    state     <= ST_WAIT; // since it is not latency critical
                end
                // synthesis translate_off
                if (AXI_BRESP!=2'b00) begin
                    $display("%0t %m ERROR BRESP not OK.", $time);
                end
                // synthesis translate_on
            end
            end // ST_RESP
        ST_DONE: begin
            // synthesis translate_off
            if (IN_ITEMS!={FIFO_AW+1{1'b0}}) begin
                $display("%0t %m ERROR result fifo not-empty.", $time);
            end
            // synthesis translate_on
            if (result_go==1'b0) begin
                result_done <= 1'b0;
                state       <= ST_READY;
            end
            end // ST_DONE
        default: begin
                 rst_aid         <={AXI_WIDTH_ID{1'b0}};
                 rst_addr        <={AXI_WIDTH_AD{1'b0}};
                 rst_items       <=32'h0; // num of items whole
                 rst_leng        <= 8'h0; // AxLENG format, 0 means length 1
                 result_done     <= 1'b0;
                 state           <= ST_READY;
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
    ST_WAIT : state_ascii="WAIT ";
    ST_ADDR : state_ascii="ADDR ";
    ST_DATA : state_ascii="DATA ";
    ST_RESP : state_ascii="RESP ";
    ST_DONE : state_ascii="DONE ";
    default : state_ascii="UNKNOWN";
    endcase
    end
    // synthesis translate_on
    //--------------------------------------------------------------------------
    assign AXI_AWID   = rst_aid;
    assign AXI_AWADDR = rst_addr;
    assign AXI_AWLEN  = rst_leng ;
    assign AXI_AWVALID= (state==ST_ADDR);
    assign AXI_AWSIZE = func_get_axsize(DATA_BYTES);
    assign AXI_AWBURST= 1'b01; // incremental
    //--------------------------------------------------------------------------
    // pop from FIFO
    assign IN_READY  = (state==ST_DATA)&&(AXI_WREADY==1'b1);
    assign AXI_WVALID= (state==ST_DATA)&&(IN_VALID==1'b1);
    assign AXI_WDATA = (NUM_ITEMS==1) ? IN_DATA
                                      : func_get_data(IN_DATA, rst_addr[AXI_WIDTH_DSB-1:0]);
    assign AXI_WLAST = (rst_leng==rst_cnt);
    assign AXI_WSTRB = func_get_wstrb(rst_addr[AXI_WIDTH_DSB-1:0],DATA_BYTES);
    assign AXI_BREADY= (state==ST_RESP);
    //--------------------------------------------------------------------------
    function [2:0] func_get_axsize;
    input [3:0] bytes;
    begin
        case (bytes)
        4'h01: func_get_axsize = 3'h0;
        4'h02: func_get_axsize = 3'h1;
        4'h04: func_get_axsize = 3'h2;
        4'h08: func_get_axsize = 3'h3;
        default: func_get_axsize = 3'h0;
        endcase
    end
    endfunction
    //--------------------------------------------------------------------------
    function [AXI_WIDTH_DS-1:0] func_get_wstrb;
       input [AXI_WIDTH_DSB-1:0] offset;
       input [3:0] bytes;
    begin
       case (bytes)
       4'd1: func_get_wstrb = {1{1'b1}}<<offset;
       4'd2: func_get_wstrb = {2{1'b1}}<<offset;
       4'd4: func_get_wstrb = {4{1'b1}}<<offset;
       4'd8: func_get_wstrb = {8{1'b1}}<<offset;
       default: func_get_wstrb = 0;
       endcase
    end
    endfunction
    //--------------------------------------------------------------------------
    function [AXI_WIDTH_DA-1:0] func_get_data;
       input [DATA_WIDTH-1:0] data;
       input [AXI_WIDTH_DSB-1:0] offset;
    begin
       if (NUM_ITEMS==1) begin
           func_get_data = data;
       end else begin
           func_get_data[DATA_WIDTH*offset[AXI_WIDTH_DSB-1:NUM_BITS]
                         +: DATA_WIDTH] = data;
       end
    end
    endfunction
    //--------------------------------------------------------------------------
endmodule

//------------------------------------------------------------------------------
// Revision history
//
// 2021.06.10: Started by Ando Ki (andoki@gmail.com)
//------------------------------------------------------------------------------
