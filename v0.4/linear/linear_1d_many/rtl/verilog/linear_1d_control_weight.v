//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All right reserved.
//------------------------------------------------------------------------------
// VERSION: 2021.11.06.
//------------------------------------------------------------------------------
// Linear 1D Controller
//------------------------------------------------------------------------------
module linear_1d_control_weight
     #(parameter AXI_WIDTH_ID  =4       // ID width in bits
               , AXI_WIDTH_AD  =32      // address width
               , AXI_WIDTH_DA  =32      // data width
               , AXI_WIDTH_DS  =AXI_WIDTH_DA/8
               , AXI_WIDTH_DSB =$clog2(AXI_WIDTH_DS)
               , DATA_WIDTH    =32
               , DATA_BYTES    =(DATA_WIDTH/8)// num of bytes per item (1 for byte)
               , DATA_BYTES_DSB=$clog2(DATA_BYTES)
               , FIFO_DEPTH    =32
               , FIFO_AW       =$clog2(FIFO_DEPTH )
               )
(
      input   wire                       ARESETn
    , input   wire                       ACLK
    // master port for kernel (read-only)
    , output  reg   [AXI_WIDTH_ID-1:0]   AXI_ARID
    , output  reg   [AXI_WIDTH_AD-1:0]   AXI_ARADDR
    , output  reg   [ 7:0]               AXI_ARLEN
    , output  reg   [ 2:0]               AXI_ARSIZE
    , output  reg   [ 1:0]               AXI_ARBURST
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
    , output  wire  [AXI_WIDTH_DA-1:0]   OUT_DATA
    , output  wire  [AXI_WIDTH_DS-1:0]   OUT_STRB
    , output  wire                       OUT_VALID
    , output  wire                       OUT_LAST // driven high at the end of each row
    , output  wire                       OUT_EMPTY
    //
    , input   wire                       linear_init
    , output  reg                        linear_ready
    //
    , input   wire                       weight_go
    , output  reg                        weight_done
    , input   wire  [AXI_WIDTH_AD-1:0]   weight_address
    , input   wire  [15:0]               weight_width// num of items in row
    , input   wire  [15:0]               weight_height// num of items in column
    , input   wire  [ 7:0]               weight_leng // AxLENG format
    , input   wire  [31:0]               weight_items
);
    //--------------------------------------------------------------------------
    wire                    `LIN_DLY  push_wr_ready;
    wire                    `LIN_DLY  push_wr_valid;
    wire [AXI_WIDTH_DA-1:0] `LIN_DLY  push_wr_data ; // justified
    wire [AXI_WIDTH_DS-1:0] `LIN_DLY  push_wr_strb ; // justified
    wire                    `LIN_DLY  push_wr_last ;
    `DBG_LINEAR wire [FIFO_AW:0]        `LIN_DLY  fifo_rooms   ;
    `DBG_LINEAR wire [FIFO_AW:0]        `LIN_DLY  fifo_items   ;
    wire                    `LIN_DLY  fifo_clr_done;
    //--------------------------------------------------------------------------
    reg  [AXI_WIDTH_AD-1:0]  reg_add        ='h0; // keep track of the address for input
    wire [AXI_WIDTH_DSB-1:0] reg_offset     = reg_add[AXI_WIDTH_DSB-1:0];
    reg  [23:0]              cnt_moved_bytes='h0; // kepp track of bytes
    `DBG_LINEAR reg  [15:0]              cnt_moved_items='h0; // keep track of items
    `DBG_LINEAR reg  [15:0]              cnt_moved_lines='h0; // keep track of lines
    reg  [ 7:0]              cnt_beat       ='h0; // keep track of a burst
    wire [23:0]              line_bytes     = weight_width*DATA_BYTES;
    wire signed [23:0]       rem_line_bytes = weight_width*DATA_BYTES-cnt_moved_bytes;
    wire signed [15:0]       rem_line_items = weight_width-cnt_moved_items;
    wire signed [15:0]       rem_lines      = weight_height-cnt_moved_lines;
    wire [ 7:0]              num_bytes      = 1<<AXI_ARSIZE;
    //--------------------------------------------------------------------------
    localparam ST_IDLE     ='h0
             , ST_READY    ='h1
             , ST_CAL      ='h2
             , ST_ADDR     ='h3
             , ST_DATA     ='h4
             , ST_DONE     ='h5;
    `DBG_LINEAR reg [2:0] state=ST_READY;
    //--------------------------------------------------------------------------
    always @ (posedge ACLK or negedge ARESETn) begin
    if (ARESETn==1'b0) begin
        AXI_ARID        <=  'h0;
        AXI_ARADDR      <=  'h0;
        AXI_ARLEN       <= 8'h0;
        AXI_ARSIZE      <= 3'b0;
        AXI_ARBURST     <= 2'b01;
        linear_ready    <= 1'b0;
        weight_done     <= 1'b0;
        reg_add         <=  'h0;
        cnt_moved_bytes <=  'h0;
        cnt_moved_items <=  'h0;
        cnt_moved_lines <=  'h0;
        cnt_beat        <=  'h0;
        state           <= ST_IDLE;
    end else if (linear_init==1'b1) begin
        AXI_ARID        <=  'h0;
        AXI_ARADDR      <=  'h0;
        AXI_ARLEN       <= 8'h0;
        AXI_ARSIZE      <= 3'b0;
        AXI_ARBURST     <= 2'b01;
        linear_ready    <= 1'b0;
        weight_done     <= 1'b0;
        reg_add         <=  'h0;
        cnt_moved_bytes <=  'h0;
        cnt_moved_items <=  'h0;
        cnt_moved_lines <=  'h0;
        cnt_beat        <=  'h0;
        state           <= ST_IDLE;
    end else begin
    case (state)
    ST_IDLE: begin
       linear_ready <= fifo_clr_done;
       if (fifo_clr_done) state <= ST_READY;
       end // ST_IDLE
    ST_READY: begin
       reg_add         <= weight_address;
       cnt_moved_bytes <=  'h0; // within a line (width, row)
       cnt_moved_items <=  'h0; // within a line (width, row)
       cnt_moved_lines <=  'h0; // height
       cnt_beat        <=  'h0;
       if ((weight_go==1'b1)&&(weight_done==1'b0)) begin
           state     <= ST_CAL;
       end else begin
           state     <= ST_READY;
       end
       end // ST_READY
    ST_CAL: begin
       AXI_ARID    <= AXI_ARID + 1;
       AXI_ARADDR  <= reg_add;
       if (reg_offset=='h0) begin
           // aligned access
           if (rem_line_bytes<AXI_WIDTH_DS) begin
               AXI_ARLEN   <= 'h0;
               AXI_ARSIZE  <= func_get_arsize(rem_line_bytes[AXI_WIDTH_DSB:0]);
           end else begin // (rem_bytes>AXI_WIDTH_DS)
               AXI_ARLEN   <= (weight_leng<(rem_line_bytes>>AXI_WIDTH_DSB)) ? weight_leng
                            : (rem_line_bytes>>AXI_WIDTH_DSB) - 1;
               AXI_ARSIZE  <= func_get_arsize(AXI_WIDTH_DS);
           end
       end else begin
           // mis-aligned access
           if ((AXI_WIDTH_DS-reg_offset)<=rem_line_bytes) begin
               AXI_ARLEN   <= 'h0;
               AXI_ARSIZE  <= func_get_arsize_misaligned(AXI_WIDTH_DS-reg_offset, reg_offset);
           end else begin
               AXI_ARLEN   <= 'h0;
               AXI_ARSIZE  <= func_get_arsize_misaligned(rem_line_bytes[AXI_WIDTH_DSB:0],reg_offset);
           end
       end
       state            <= ST_ADDR;
       // synthesis translate_off
       if (rem_line_bytes<=0) $display("%t %m ERROR addres error.", $time);
       // synthesis translate_on
       end // ST_CAL
    ST_ADDR: begin
       if ((AXI_ARVALID==1'b1)&&(AXI_ARREADY==1'b1)) begin
           cnt_beat    <=  'h0;
           state       <= ST_DATA;
           // synthesis translate_off
           if (AXI_ARLEN>=FIFO_DEPTH) $display("%0t %m ERROR burst length exceeds the depth of FIFO.", $time);
           // synthesis translate_on
       end
       end // ST_ADDR
    ST_DATA: begin
       if ((AXI_RVALID==1'b1)&&(AXI_RREADY==1'b1)) begin
            reg_add         <= reg_add + num_bytes;
            cnt_beat        <= cnt_beat + 1;
            cnt_moved_bytes <= cnt_moved_bytes + num_bytes;
            cnt_moved_items <= cnt_moved_items + func_get_num_items(AXI_ARSIZE);
                                                 // It is assumed data-bus does not carry
                                                 // mis-aligned burst.
            if (AXI_RLAST==1'b1) begin
                if ((cnt_moved_bytes+num_bytes)<line_bytes) begin
                    state  <= ST_CAL;
                end else begin // ((cnt_moved_bytes+num_bytes)>=line_bytes)
// synthesis translate_off
//$display("%0t %m %0d/%0d line (row) done.", $time, cnt_moved_lines+1, weight_height);
// synthesis translate_on
                    cnt_moved_lines <= cnt_moved_lines + 1;
                    if ((cnt_moved_lines + 1)<weight_height) begin
                        cnt_moved_bytes <=  'h0;
                        cnt_moved_items <=  'h0;
                        cnt_beat        <=  'h0;
                        state           <= ST_CAL;
                        // synthesis translate_off
                        if ((reg_add+num_bytes)!=(weight_address+((cnt_moved_lines+1)*line_bytes)))
                            $display("%0t %m ERROR line addr error: 0x%08X:%08X",
                                    $time, (reg_add+num_bytes), (weight_address+((cnt_moved_lines+1)*line_bytes)));
                        // synthesis translate_on
                    end else begin
                        weight_done <= 1'b1;
                        state     <= ST_DONE;
                        // synthesis translate_off
                        if ((cnt_moved_lines+1)!=weight_height)
                            $display("%0t %m ERROR line num error.", $time);
                        // synthesis translate_on
                     end
                    // synthesis translate_off
                    if ((cnt_moved_bytes+num_bytes)!=line_bytes)
                        $display("%0t %m ERROR line size error.", $time);
                    // synthesis translate_on
                end
                // synthesis translate_off
                if (cnt_beat!=AXI_ARLEN)
                    $display("%0t %m ERROR burst length error.", $time);
                // synthesis translate_on
            end
            // synthesis translate_off
            if ((cnt_moved_bytes+num_bytes)>line_bytes)
                $display("%t %m WARNING source A addres exceeds.", $time);
            // synthesis translate_on
       end // if ((AXI_RVALID
       end // ST_SRCA_DATA
    ST_DONE: begin
       if (weight_go==1'b0) weight_done <= 1'b0;
       if (weight_done==1'b0) state <= ST_READY;
       end // ST_DONE
    default: begin
             AXI_ARID         <=  'h0;
             AXI_ARADDR       <=  'h0;
             AXI_ARLEN        <= 8'h0;
             AXI_ARSIZE       <= 3'b0;
             linear_ready     <= 1'b0;
             weight_done      <= 1'b0;
             reg_add          <=  'h0;
             cnt_moved_bytes  <=  'h0;
             cnt_moved_bytes  <=  'h0;
             cnt_moved_items  <=  'h0;
             cnt_beat         <=  'h0;
             state            <= ST_IDLE;
             end
    endcase
    end // if
    end // always
    //--------------------------------------------------------------------------
    // synthesis translate_off
    reg  [8*32-1:0] state_ascii="IDLE";
    always @ (state) begin
    case (state)
    ST_IDLE     : state_ascii="IDLE     ";
    ST_READY    : state_ascii="READY    ";
    ST_CAL      : state_ascii="CAL      ";
    ST_ADDR     : state_ascii="ADDR     ";
    ST_DATA     : state_ascii="DATA     ";
    ST_DONE     : state_ascii="DONE     ";
    default     : state_ascii="UNKNOWN  ";
    endcase
    end
    // synthesis translate_on
    //--------------------------------------------------------------------------
    assign AXI_ARVALID = ((state==ST_ADDR)&&(fifo_rooms>AXI_ARLEN)) ? 1'b1 : 1'b0;
    assign AXI_RREADY  = (state==ST_DATA) ? push_wr_ready : 1'b0;
    //--------------------------------------------------------------------------
    assign push_wr_valid = (state==ST_DATA) ? AXI_RVALID : 1'b0;
    assign push_wr_data  = (state==ST_DATA) ? func_get_data_justified(reg_offset,AXI_RDATA)
                          : 'h0;
    assign push_wr_strb  = (state==ST_DATA) ? func_get_strb_justified(reg_offset,AXI_ARSIZE)
                          : 'h0;
    assign push_wr_last  = (state==ST_DATA) ? ((cnt_moved_bytes+num_bytes)==line_bytes)
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
    // the number of itesm in a data bus.
    function [7:0] func_get_num_items;
        input [2:0] arsize;
        reg [7:0] num;
    begin
        num = (1<<arsize);
        func_get_num_items = num[7:DATA_BYTES_DSB];
    end
    endfunction
    //--------------------------------------------------------------------------
    wire                    `LIN_DLY  fifo_wr_ready;
    wire                    `LIN_DLY  fifo_wr_valid;
    wire [AXI_WIDTH_DA-1:0] `LIN_DLY  fifo_wr_data ; // justified
    wire [AXI_WIDTH_DS-1:0] `LIN_DLY  fifo_wr_strb ; // justified
    wire                    `LIN_DLY  fifo_wr_last ;
    wire                              fifo_rd_ready;
    wire                    `LIN_DLY  fifo_rd_valid;
    wire [AXI_WIDTH_DA-1:0] `LIN_DLY  fifo_rd_data ; // justified
    wire [AXI_WIDTH_DS-1:0] `LIN_DLY  fifo_rd_strb ; // justified
    wire                    `LIN_DLY  fifo_rd_last ;
    `DBG_LINEAR wire                    `LIN_DLY  fifo_empty   ;
    `DBG_LINEAR wire                    `LIN_DLY  fifo_full    ;
    wire                    `LIN_DLY  fifo_clr      = linear_init;
    assign                            fifo_clr_done = fifo_wr_ready&fifo_empty&~fifo_full;
    //--------------------------------------------------------------------------
    // It makes justified-filled data output.
    linear_1d_fifo_sync_merger_push #(.FDW(AXI_WIDTH_DA))
    u_push_weight (
          .rstn    ( ARESETn       )
        , .clr     ( fifo_clr      )
        , .clk     ( ACLK          )
        , .wr_rdy  ( push_wr_ready ) // makes sure resB_wr_ready is 1 at the same time
        , .wr_vld  ( push_wr_valid ) // makes sure resB_wr_valid is 1 at the same time
        , .wr_data ( push_wr_data  )
        , .wr_strb ( push_wr_strb  )
        , .wr_last ( push_wr_last  )
        , .rd_rdy  ( fifo_wr_ready )
        , .rd_vld  ( fifo_wr_valid )
        , .rd_data ( fifo_wr_data  )
        , .rd_strb ( fifo_wr_strb  )
        , .rd_last ( fifo_wr_last  )
    );
    //--------------------------------------------------------------------------
    // LAST+STRB+DATA
    // note that 'fifo_wr/rd_data' carried justified data.
    linear_1d_fifo_sync #(.FDW(1+AXI_WIDTH_DS+AXI_WIDTH_DA),.FAW(FIFO_AW   ))
    u_fifo_weight (
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
    assign OUT_VALID = fifo_rd_valid;
    assign OUT_DATA  = fifo_rd_data ;
    assign OUT_STRB  = fifo_rd_strb ;
    assign OUT_LAST  = fifo_rd_last ;
    assign OUT_EMPTY = fifo_empty   ;
    assign fifo_rd_ready = OUT_READY;
    //--------------------------------------------------------------------------
endmodule
//------------------------------------------------------------------------------
// Revision history
//
// 2021.11.06: func_get_arsize_misaligned() updated
// 2021.06.10: Started by Ando Ki (andoki@gmail.com)
//------------------------------------------------------------------------------