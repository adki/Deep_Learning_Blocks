//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All right reserved.
//------------------------------------------------------------------------------
// VERSION: 2021.11.06.
//------------------------------------------------------------------------------
// Linear 1D Controller
//------------------------------------------------------------------------------
module linear_1d_control_result
     #(parameter AXI_WIDTH_ID  =4       // ID width in bits
               , AXI_WIDTH_AD  =32      // address width
               , AXI_WIDTH_DA  =32      // data width
               , AXI_WIDTH_DS  =(AXI_WIDTH_DA/8)
               , AXI_WIDTH_DSB =$clog2(AXI_WIDTH_DS)
               , DATA_WIDTH    =32
               , DATA_BYTES    =(DATA_WIDTH/8)// num of bytes per result item (1 for byte)
               , DATA_BYTES_DSB=$clog2(DATA_BYTES)
               , FIFO_DEPTH    =32
               , FIFO_AW       =$clog2(FIFO_DEPTH)
               )
(
      input   wire                      ARESETn
    , input   wire                      ACLK
    , output  reg   [AXI_WIDTH_ID-1:0]  AXI_AWID
    , output  reg   [AXI_WIDTH_AD-1:0]  AXI_AWADDR
    , output  reg   [ 7:0]              AXI_AWLEN
    , output  reg   [ 2:0]              AXI_AWSIZE
    , output  reg   [ 1:0]              AXI_AWBURST
    , output  reg                       AXI_AWVALID
    , input   wire                      AXI_AWREADY
    , output  reg   [AXI_WIDTH_DA-1:0]  AXI_WDATA
    , output  reg   [AXI_WIDTH_DS-1:0]  AXI_WSTRB
    , output  reg                       AXI_WLAST
    , output  reg                       AXI_WVALID
    , input   wire                      AXI_WREADY
    , input   wire  [AXI_WIDTH_ID-1:0]  AXI_BID
    , input   wire  [ 1:0]              AXI_BRESP
    , input   wire                      AXI_BVALID
    , output  reg                       AXI_BREADY
    //
    , output  wire                      IN_READY
    , input   wire                      IN_VALID // should be interpreced along with IN_LAST
    , input   wire  [DATA_WIDTH-1:0]    IN_DATA
    , input   wire  [DATA_BYTES-1:0]    IN_STRB
    , input   wire                      IN_LAST // indicates each end of MAC
    //
    , input   wire                      linear_init
    , output  reg                       linear_ready
    //
    , input   wire                      result_go
    , output  reg                       result_done
    , input   wire  [AXI_WIDTH_AD-1:0]  result_address
    , input   wire  [15:0]              result_size
    , input   wire  [ 7:0]              result_leng // AxLENG format
);
    //--------------------------------------------------------------------------
    wire                      fifo_wr_ready;
    wire                      fifo_wr_valid;
    wire  [AXI_WIDTH_DA-1:0]  fifo_wr_data ;// justified
    wire  [AXI_WIDTH_DS-1:0]  fifo_wr_strb ;// justified
    wire                      fifo_wr_last ;
    wire                      fifo_rd_ready;
    wire                      fifo_rd_valid;
    wire  [AXI_WIDTH_DA-1:0]  fifo_rd_data ;// justified
    wire  [AXI_WIDTH_DS-1:0]  fifo_rd_strb ;// justified
    wire                      fifo_rd_last ;
    `DBG_LINEAR wire                      fifo_empty   ;
    `DBG_LINEAR wire                      fifo_full    ;
    `DBG_LINEAR wire  [FIFO_AW:0]         fifo_items   ;
    `DBG_LINEAR wire  [FIFO_AW:0]         fifo_rooms   ;
    wire                      fifo_clr      = linear_init;
    wire                      fifo_clr_done = fifo_wr_ready&fifo_empty&~fifo_full;
    //--------------------------------------------------------------------------
    reg                       pop_rd_ready;
    wire                      pop_rd_valid;
    wire  [AXI_WIDTH_DA-1:0]  pop_rd_data ;// justified
    wire  [AXI_WIDTH_DS-1:0]  pop_rd_strb ;// justified
    wire                      pop_rd_last ;
    reg   [AXI_WIDTH_DS-1:0]  pop_rd_sreq ;// justified
    wire  [FIFO_AW:0]         fifo_items_all=(pop_rd_valid)
                                            ? (fifo_items+1) // in order to reflect one item in merger_pop
                                            : fifo_items;
    //--------------------------------------------------------------------------
    reg  [AXI_WIDTH_AD-1:0]  reg_add         = 'h0; // keep track of address
    wire [AXI_WIDTH_DSB-1:0] reg_offset      = reg_add[AXI_WIDTH_DSB-1:0];
    reg  [31:0]              cnt_moved_bytes = 'h0;
    `DBG_LINEAR reg  [15:0]              cnt_moved_items = 'h0;
    reg  [ 7:0]              cnt_beat        = 'h0; // keep track of a burst
    wire [23:0]              num_all_bytes   = result_size*DATA_BYTES;
    wire signed [23:0]       rem_all_bytes   = num_all_bytes-cnt_moved_bytes;
    wire signed [15:0]       rem_all_items   = result_size-cnt_moved_items;
    wire [ 7:0]              num_bytes       = 1<<AXI_AWSIZE;
    //--------------------------------------------------------------------------
    wire [ 8:0] expect_leng = (rem_all_bytes<AXI_WIDTH_DS) ? 'h1
                            : (result_leng<(rem_all_bytes>>AXI_WIDTH_DSB)) ? (result_leng+1)
                            : (rem_all_bytes>>AXI_WIDTH_DSB);
    //--------------------------------------------------------------------------
    localparam ST_IDLE ='h0
             , ST_READY='h1
             , ST_DRV  ='h2
             , ST_ADDR ='h3
             , ST_DATA ='h4
             , ST_RESP ='h5
             , ST_DONE ='h6;
    `DBG_LINEAR reg [2:0] state=ST_IDLE;
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
        linear_ready     <= 1'b0;
        result_done      <= 1'b0;
        reg_add          <=  'h0;
        cnt_moved_bytes  <=  'h0;
        cnt_moved_items  <=  'h0;
        cnt_beat         <=  'h0;
        state            <= ST_IDLE;
    end else if (linear_init==1'b1) begin
        AXI_AWID    <=  'h0;
        AXI_AWADDR  <=  'h0;
        AXI_AWLEN   <=  'h0;
        AXI_AWSIZE  <=  'h0;
        AXI_AWBURST <= 2'b01;
        AXI_AWVALID <= 1'b0;
        AXI_BREADY  <= 1'b0;
        linear_ready     <= 1'b0;
        result_done      <= 1'b0;
        reg_add          <=  'h0;
        cnt_moved_bytes  <=  'h0;
        cnt_moved_items  <=  'h0;
        cnt_beat         <=  'h0;
        state            <= ST_IDLE;
    end else begin
    case (state)
    ST_IDLE: begin
        linear_ready    <= fifo_clr_done;
        if (fifo_clr_done) state <= ST_READY;
        end // ST_IDLE
    ST_READY: begin
        reg_add         <= result_address;
        cnt_moved_bytes <= 'h0;
        cnt_moved_items <= 'h0;
        if ((result_go==1'b1)&&(result_done==1'b0)) begin
             state <= ST_DRV;
        end
        end // ST_DATA1
    ST_DRV: begin
       AXI_AWID    <= AXI_AWID + 1;
       AXI_AWADDR  <= reg_add;
       if (reg_offset=='h0) begin
           // aligned access
           if ((expect_leng<=fifo_items_all)||((pop_rd_valid==1'b1)&&(fifo_rd_last==1'b1))) begin
              if (rem_all_bytes<AXI_WIDTH_DS) begin
                  AXI_AWLEN  <= 'h0;
                  AXI_AWSIZE <= func_get_awsize(rem_all_bytes[AXI_WIDTH_DSB:0]);
              end else begin // (rem_all_bytes>AXI_WIDTH_DS) begin
                  AXI_AWLEN  <= expect_leng-1;
                  AXI_AWSIZE <= func_get_awsize(AXI_WIDTH_DS);
              end
              AXI_AWVALID <= 1'b1;
              state       <= ST_ADDR;
           end
       end else begin
           // mis-aligned access
           if (pop_rd_valid==1'b1) begin
               if ((AXI_WIDTH_DS-reg_offset)<=rem_all_bytes) begin
                   AXI_AWLEN  <= 'h0;
                   AXI_AWSIZE <= func_get_awsize_misaligned(AXI_WIDTH_DS-reg_offset, reg_offset);
               end else begin
                   AXI_AWLEN  <= 'h0;
                   AXI_AWSIZE <= func_get_awsize_misaligned(rem_all_bytes[AXI_WIDTH_DSB:0], reg_offset);
               end
               AXI_AWVALID <= 1'b1;
               state       <= ST_ADDR;
           end
       end
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
            reg_add         <= reg_add + num_bytes;
            cnt_beat        <= cnt_beat + 1;
            cnt_moved_bytes <= cnt_moved_bytes + num_bytes;
            cnt_moved_items <= cnt_moved_items + func_get_num_items(AXI_AWSIZE);
                                                 // It is assumed data-bus does not carry
                                                 // mis-aligned burst.
            if (AXI_WLAST==1'b1) begin
                AXI_BREADY <= 1'b1;
                state      <= ST_RESP;
                // synthesis translate_off
                if (cnt_beat!=AXI_AWLEN)
                    $display("%0t %m ERROR burst length error.", $time);
                // synthesis translate_on
            end
            // synthesis translate_off
            if ((cnt_moved_bytes+num_bytes)>num_all_bytes)
                $display("%t %m WARNING source A addres exceeds.", $time);
            // synthesis translate_on
       end
       end // ST_DATA
    ST_RESP: begin
       if (AXI_BVALID==1'b1) begin
           AXI_BREADY <= 1'b0;
           if (cnt_moved_bytes<num_all_bytes) begin
               if (cnt_moved_bytes==num_all_bytes) begin
                   cnt_moved_bytes <= 'h0;
               end
               state  <= ST_DRV;
           end else begin // ((cnt_moved_bytes==num_all_bytes)
               result_done <= 1'b1;
               state       <= ST_DONE;
               // synthesis translate_off
               if (reg_add!=(result_address+num_all_bytes))
                   $display("%0t %m ERROR line addr error.", $time);
               // synthesis translate_on
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
             linear_ready    <= 1'b0;
             result_done     <= 1'b0;
             reg_add         <=  'h0;
             cnt_moved_bytes <=  'h0;
             cnt_moved_items <=  'h0;
             cnt_beat        <=  'h0;
             state           <= ST_IDLE;
             end
    endcase
    end // if
    end // always
    //--------------------------------------------------------------------------
    // synthesis translate_off
    reg  [8*10-1:0] state_ascii="IDLE";
    always @ (state) begin
    case (state)
    ST_IDLE : state_ascii="IDLE ";
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
    always @ ( * ) begin
    if (state==ST_DATA) begin
        pop_rd_ready =AXI_WREADY;
        pop_rd_sreq  =AXI_WSTRB>>reg_offset;
        AXI_WVALID =pop_rd_valid;
        AXI_WDATA  =pop_rd_data<<(reg_offset*8);
        AXI_WSTRB  =func_get_wstrb(reg_offset,AXI_AWSIZE);
        AXI_WLAST  =(cnt_beat==AXI_AWLEN);
    end else begin
        pop_rd_ready =1'b0;
        pop_rd_sreq  ={AXI_WIDTH_DS{1'b0}};
        AXI_WVALID =1'b0;
        AXI_WDATA  = 'h0;
        AXI_WSTRB  = 'h0;
        AXI_WLAST  =1'b0;
    end // if
    end // always
    // synthesis translate_off
    always @ ( posedge ACLK) begin
        if ((AXI_WVALID==1'b1)&&(AXI_WREADY==1'b1)) begin
             if (AXI_WSTRB!==(pop_rd_strb<<reg_offset)) begin
                 $display("%0t %m ERROR strobe mis-match.", $time);
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
    // the number of itesm in a data bus.
    function [7:0] func_get_num_items;
        input [2:0] awsize;
        reg [7:0] num;
    begin
        num = (1<<awsize);
        func_get_num_items = num[7:DATA_BYTES_DSB];
    end
    endfunction
    //--------------------------------------------------------------------------
    localparam NUM=AXI_WIDTH_DA/DATA_WIDTH
             , NUM_BITS=$clog2(NUM);
    //--------------------------------------------------------------------------
    reg [15:0]             fcnt_items='h0;
    reg [NUM_BITS+1:0]     fcnt_beats='h0;
    reg [AXI_WIDTH_DA-1:0] freg_data='h0; // make sure that no-valid data should be 0.
    reg [AXI_WIDTH_DS-1:0] freg_strb='h0; // make sure that no-valid bits should be 0.
    //--------------------------------------------------------------------------
    localparam SF_READY='h0
             , SF_PUSH ='h1
             , SF_DONE ='h2;
    `DBG_LINEAR reg [1:0] state_fifo=SF_READY;
    //--------------------------------------------------------------------------
    always @ ( posedge ACLK or negedge ARESETn) begin
    if (ARESETn==1'b0) begin
        fcnt_items  <= 'h0;
        fcnt_beats  <= 'h0;
        freg_data   <= 'h0;
        freg_strb   <= 'h0;
        state_fifo <= SF_READY;
    end else if (linear_init==1'b1) begin
        fcnt_items  <= 'h0;
        fcnt_beats  <= 'h0;
        freg_data   <= 'h0;
        freg_strb   <= 'h0;
        state_fifo <= SF_READY;
    end else begin
        case (state_fifo)
        SF_READY: begin
           if (state==ST_DRV) begin
               fcnt_items  <= 'h0;
               fcnt_beats  <= 'h0;
               freg_data   <= 'h0;
               freg_strb   <= 'h0;
               state_fifo <= SF_PUSH;
           end
           end // SF_READY
        SF_PUSH: begin
           if (IN_READY&IN_VALID) begin
               fcnt_items  <= fcnt_items + 1;
               if (NUM>1) begin
                   fcnt_beats  <= fcnt_beats + 1;
                   if (fcnt_beats=='h0) begin
                       freg_data <= {{AXI_WIDTH_DA-DATA_WIDTH{1'b0}},IN_DATA};
                       freg_strb <= {{AXI_WIDTH_DS-DATA_BYTES{1'b0}},IN_STRB};
                   end else begin
                       freg_data[fcnt_beats*DATA_WIDTH+:DATA_WIDTH] <= IN_DATA;
                       freg_strb[fcnt_beats*DATA_BYTES+:DATA_BYTES] <= IN_STRB;
                       if ((fcnt_beats+1)==NUM) begin
                           fcnt_beats <= 'h0;
                           freg_data  <= 'h0;
                           freg_strb  <= 'h0;
                       end
                   end
               end
               if ((fcnt_items+1)==result_size) state_fifo <= SF_DONE;
           end
           end // SF_PUSH
        SF_DONE: begin
           state_fifo <= SF_READY;
           end // SF_DONE
        default: begin
                 fcnt_items  <= 'h0;
                 fcnt_beats  <= 'h0;
                 freg_data   <= 'h0;
                 freg_strb   <= 'h0;
                 state_fifo <= SF_READY;
                 end
        endcase
    end // if
    end // always
    //--------------------------------------------------------------------------
    // synthesis translate_off
    reg  [8*10-1:0] state_fifo_ascii="READY";
    always @ (state_fifo) begin
    case (state_fifo)
    SF_READY: state_fifo_ascii="READY  ";
    SF_PUSH : state_fifo_ascii="PUSH   ";
    SF_DONE : state_fifo_ascii="DONE   ";
    default : state_fifo_ascii="UNKNOWN";
    endcase
    end
    // synthesis translate_on
    //--------------------------------------------------------------------------
    assign IN_READY = fifo_wr_ready;
    assign fifo_wr_last  = ((fcnt_items+1)==result_size);
    generate
    if (NUM==1) begin : BLK_ONE
        assign fifo_wr_valid = IN_VALID;
        assign fifo_wr_data  = IN_DATA;
        assign fifo_wr_strb  = IN_STRB;
    end else begin : BLK_WIDE
        assign fifo_wr_valid =(((fcnt_items+1)==result_size)||
                               ((fcnt_beats+1)==NUM)) ? IN_VALID : 1'b0;
        assign fifo_wr_data  = freg_data|(IN_DATA<<(fcnt_beats*DATA_WIDTH));
        assign fifo_wr_strb  = freg_strb|(IN_STRB<<(fcnt_beats*DATA_BYTES));
    end
    endgenerate
    //--------------------------------------------------------------------------
    // to deal with narrow to wider
    linear_1d_fifo_sync #(.FDW(1+AXI_WIDTH_DS+AXI_WIDTH_DA),.FAW(FIFO_AW))
    u_fifo_result (
          .rstn     ( ARESETn       )
        , .clr      ( fifo_clr      )
        , .clk      ( ACLK          )
        , .wr_rdy   ( fifo_wr_ready )
        , .wr_vld   ( fifo_wr_valid )
        , .wr_din   ({fifo_wr_last,fifo_wr_strb,fifo_wr_data})
        , .rd_rdy   ( fifo_rd_ready )
        , .rd_vld   ( fifo_rd_valid )
        , .rd_dout  ({fifo_rd_last,fifo_rd_strb,fifo_rd_data})
        , .full     ( fifo_full     )
        , .empty    ( fifo_empty    )
        , .item_cnt ( fifo_items    )
        , .room_cnt ( fifo_rooms    )
    );
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
    //               |<====== hidden in the FIFO ====>|
    linear_1d_fifo_sync_merger_pop #(.FDW(AXI_WIDTH_DA))
    u_pop_result (
          .rstn     ( ARESETn       )
        , .clr      ( fifo_clr      )
        , .clk      ( ACLK          )
        , .wr_rdy   ( fifo_rd_ready )
        , .wr_vld   ( fifo_rd_valid )
        , .wr_data  ( fifo_rd_data  )
        , .wr_strb  ( fifo_rd_strb  )
        , .wr_last  ( fifo_rd_last  )
        , .rd_rdy   ( pop_rd_ready  )
        , .rd_vld   ( pop_rd_valid  )
        , .rd_data  ( pop_rd_data   )
        , .rd_strb  ( pop_rd_strb   )
        , .rd_last  ( pop_rd_last   )
        , .rd_sreq  ( pop_rd_sreq   ) // the bit-pattern to request bytes
    );
    //--------------------------------------------------------------------------
endmodule

//------------------------------------------------------------------------------
// Revision history
//
// 2021.11.06: func_get_awsize_misaligned() updated
// 2021.06.10: Started by Ando Ki (andoki@gmail.com)
//------------------------------------------------------------------------------
