//----------------------------------------------------------------
//  Copyright (c) 2013-2017-2021 by Ando Ki.
//  All right reserved.
//  http://www.future-ds.com
//  All rights are reserved by Ando Ki.
//  Do not use in any means or/and methods without Ando Ki's permission.
//----------------------------------------------------------------
// axi_tasks.v
//----------------------------------------------------------------
// VERSION: 2021.09.18.
//---------------------------------------------------------
localparam XX_LENG=1024;
reg  [7:0] dataWB[0:XX_LENG-1];
reg  [7:0] dataRB[0:XX_LENG-1];
wire [WIDTH_DA-1:0] dataWW[0:(XX_LENG/WIDTH_DS)-1];
wire [WIDTH_DA-1:0] dataRW[0:(XX_LENG/WIDTH_DS)-1];

`define WDELAYxx #(1)
//----------------------------------------------------------------
generate
genvar idx, idy;
for (idx=0; idx<(XX_LENG/WIDTH_DS); idx=idx+1) begin : BLK_XXY
for (idy=0; idy<WIDTH_DS; idy=idy+1) begin : BLK_YYX
     assign dataRW[idx][idy*8+:8] = dataRB[idx*WIDTH_DS+idy];
end
end
endgenerate
//----------------------------------------------------------------
// Read-After-Write
task test_raw;
     input [WIDTH_ID-1:0] id;
     input [WIDTH_AD-1:0] saddr; // start address
     input [WIDTH_AD-1:0] depth; // size in byte
     input [15:0]         bsize; // burst size in byte
     input [ 8:0]         bleng; // burst length (not AxLEN format)
     reg   [WIDTH_AD-1:0] addr;
     integer      idx, idy, idz, error;
begin
    error = 0;
    addr = saddr;
    for (idy=0; idy<depth; idy=idy+bsize*bleng) begin
        for (idx=0; idx<bsize*bleng; idx=idx+1) begin
            dataWB[idx] = idy + idx + 1;
        end
        write_task( id //input [31:0]         id;
                  , addr  //addr;
                  , bsize //size; // 1 ~ 128 byte in a beat
                  , bleng //leng; // 1 ~ 16  beats in a burst
                  , 'h1   //type; // burst type (0=fixed, 1=inc, 2=wrap)
                  );
        read_task ( id //input [31:0]         id;
                  , addr  //addr;
                  , bsize //size; // 1 ~ 128 byte in a beat
                  , bleng //leng; // 1 ~ 16  beats in a burst
                  , 'h1   //type; // burst type
                  );
        for (idz=0; idz<bsize; idz=idz+1) begin
             if (dataWB[idz]!=dataRB[idz]) begin
                 error = error + 1;
                 $display("%0t %m Error A:0x%x D:0x%x, but 0x%x expected",
                                  $time, addr+idz, dataRB[idz], dataWB[idz]);
             end
             `ifdef DEBUG
             else $display("%0t %m OK A:0x%x D:0x%x", $time, addr+idz, dataRB[idz]);
             `endif
        end
        addr = addr + bsize*bleng;
    end
    if (error==0) $display("%0t %m test_raw from 0x%08x to 0x%08x %03d-size %03d-leng OK",
                            $time, saddr, saddr+depth-1, bsize, bleng);
end
endtask
//----------------------------------------------------------------
// Read-After-Write ALL
task test_raw_all;
     input [WIDTH_ID-1:0] id;
     input [WIDTH_AD-1:0] saddr; // start address
     input [WIDTH_AD-1:0] depth; // size in byte
     input [15:0]         bsize; // burst size in byte
     input [ 8:0]         bleng; // burst length (not AxLEN format)
     reg   [WIDTH_AD-1:0] addr;
     integer      idx, idy, idz, error;
begin
    error = 0;
    addr = saddr;
    for (idy=0; idy<depth; idy=idy+bsize*bleng) begin
        for (idx=0; idx<bsize*bleng; idx=idx+1) begin
            dataWB[idx] = idy + idx + 1;
        end
        write_task( id //input [31:0]         id;
                  , addr  //addr;
                  , bsize //size; // 1 ~ 128 byte in a beat
                  , bleng //leng; // 1 ~ 16  beats in a burst
                  , 'h1   //type; // burst type
                  );
        addr = addr + bsize*bleng;
    end
    addr = saddr;
    for (idy=0; idy<depth; idy=idy+bsize*bleng) begin
        read_task ( id //input [31:0]         id;
                  , addr  //addr;
                  , bsize //size; // 1 ~ 128 byte in a beat
                  , bleng //leng; // 1 ~ 16  beats in a burst
                  , 'h1   //type; // burst type
                  );
        for (idz=0; idz<bsize; idz=idz+1) begin
             if ((idy+idz+1)!=dataRB[idz]) begin
                 error = error + 1;
                 $display("%0t %m Error A:0x%x D:0x%x, but 0x%x expected",
                                  $time, addr+idz, dataRB[idz], idy+idz+1);
             end
        end
        addr = addr + bsize*bleng;
    end
    if (error==0) $display("%0t %m test_raw_all from 0x%08x to 0x%08x %03d-size %03d-leng OK",
                               $time, saddr, saddr+depth-1, bsize, bleng);
end
endtask
//----------------------------------------------------------------
// Read-After-Write
task test_raw_burst;
     input [WIDTH_ID-1:0] id;
     input [WIDTH_AD-1:0] saddr; // start address
     input [WIDTH_AD-1:0] depth; // size in byte
     input [15:0]         bsize; // burst size in byte
     input [ 8:0]         bleng; // burst length (not AxLEN format)
     reg   [WIDTH_AD-1:0] addr;
     integer      idx, idy, idz, error;
begin
    error = 0;
    addr = saddr;
    for (idy=0; idy<depth; idy=idy+(bsize*bleng)) begin
        for (idx=0; idx<(bsize*bleng); idx=idx+1) begin
            dataWB[idx] = idy + idx + 1;
        end
        write_task( id //input [31:0]         id;
                  , addr  //addr;
                  , bsize //size; // 1 ~ 128 byte in a beat
                  , bleng //leng; // 1 ~ 16  beats in a burst
                  , 'h1   //type; // burst type (0=fixed, 1=inc, 2=wrap)
                  );
        read_task ( id //input [31:0]         id;
                  , addr  //addr;
                  , bsize //size; // 1 ~ 128 byte in a beat
                  , bleng //leng; // 1 ~ 16  beats in a burst
                  , 'h1   //type; // burst type
                  );
        for (idz=0; idz<bsize; idz=idz+1) begin
             if (dataWB[idz]!=dataRB[idz]) begin
                 error = error + 1;
                 $display("%0t %m Error A:0x%x D:0x%x, but 0x%x expected",
                                  $time, addr+idz, dataRB[idz], dataWB[idz]);
             end
             `ifdef DEBUG
             else $display("%0t %m OK A:0x%x D:0x%x", $time, addr+idz, dataRB[idz]);
             `endif
        end
        addr = addr + (bsize*bleng);
    end
    if (error==0) $display("%0t %m test_raw from 0x%08x to 0x%08x %03d-size %03d-leng OK",
                             $time, saddr, saddr+depth-1, bsize, bleng);
end
endtask
//----------------------------------------------------------------
// 32-bit access
task read_word_task;
     input  [WIDTH_AD-1:0] addr;
     output [31:0] data;
begin
     read_task(2,addr,4,1,1);
     data = dataRW[0][31:0];
end
endtask
//----------------------------------------------------------------
task read_task;
     input [WIDTH_ID-1:0] id;
     input [WIDTH_AD-1:0] addr;
     input [15:0]         size; // 1 ~ 128 byte in a beat
     input [ 8:0]         leng; // 1 ~ 16  beats in a burst (not ARLEN format)
     input [ 1:0]         xtype; // burst type
begin
     fork
     read_address_channel(id,addr,size,leng,xtype);
     read_data_channel(id,addr,size,leng,xtype);
     join
end
endtask
//----------------------------------------------------------------
task read_address_channel;
     input [WIDTH_ID-1:0] id;
     input [WIDTH_AD-1:0] addr;
     input [15:0]         size; // 1 ~ 128 byte in a beat
     input [ 8:0]         leng; // 1 ~ 16  beats in a burst (not ARLEN format)
     input [ 1:0]         xtype; // burst type
begin
     @ (posedge ACLK);
     ARID    <= `WDELAYxx id;
     ARADDR  <= `WDELAYxx addr;
     ARLEN   <= `WDELAYxx leng-1;
     ARLOCK  <= `WDELAYxx 'b0;
     ARSIZE  <= `WDELAYxx get_size(size);
     ARBURST <= `WDELAYxx  xtype[1:0];
     `ifdef AMBA_AXI_PROT
     ARPROT  <= `WDELAYxx 'h0; // data, secure, normal
     `endif
     ARVALID <= `WDELAYxx 'b1;
     @ (posedge ACLK);
     while (ARREADY==1'b0) @ (posedge ACLK);
     ARVALID <= `WDELAYxx 'b0;
     @ (negedge ACLK);
end
endtask
//----------------------------------------------------------------
task read_data_channel;
     input [WIDTH_ID-1:0] id;
     input [WIDTH_AD-1:0] addr;
     input [15:0]         size; // 1 ~ 128 byte in a beat
     input [ 8:0]         leng; // 1 ~ 16  beats in a burst (not ARLEN format)
     input [ 1:0]         xtype; // burst type
     reg   [WIDTH_AD-1:0] naddr;
     reg   [WIDTH_DS-1:0] strb;
     reg   [WIDTH_DA-1:0] dataR;
     integer idx, idy, idz;
begin
     idz = 0;
     naddr  = addr;
     @ (posedge ACLK);
     RREADY <= `WDELAYxx 1'b1;
     for (idx=0; idx<leng; idx=idx+1) begin
          @ (posedge ACLK);
          while (RVALID==1'b0) @ (posedge ACLK);
          strb = get_strb(naddr, size);
          dataR = RDATA;
          for (idy=0; idy<WIDTH_DS; idy=idy+1) begin
               //if (strb[idy]) dataRB[naddr-addr+idy] = dataR&8'hFF;
               if (strb[idy]) begin
                   dataRB[idz] = dataR&8'hFF; // justified
                   idz = idz + 1;
               end
               dataR = dataR>>8;
          end
          if (id!=RID) begin
             $display("%0t %m Error id/RID mis-match for read-data-channel", $time, id, RID);
          end
          if (idx==leng-1) begin
             if (RLAST==1'b0) begin
                 $display("%0t %m Error RLAST expected for read-data-channel", $time);
             end
          end else begin
              @ (negedge ACLK);
              naddr = get_next_addr( naddr  // current address
                                   , size  // num of bytes in a beat
                                   , xtype);// type of burst
          end
     end
     RREADY <= `WDELAYxx 'b0;
     @ (negedge ACLK);
end
endtask
//----------------------------------------------------------------
// 32-bit access
task write_word_task;
     input [WIDTH_AD-1:0] addr;
     input [31:0] data;
     integer idx;
begin
     for (idx=0; idx<4; idx=idx+1) begin
         dataWB[idx] = data[idx*8 +: 8];
     end
     write_task(1,addr,4,1,1);
end
endtask
//----------------------------------------------------------------
// dataWB[....] carries justified data
task write_task;
     input [WIDTH_ID-1:0] id;
     input [WIDTH_AD-1:0] addr;
     input [15:0]         size; // 1 ~ 128 byte in a beat
     input [ 8:0]         leng; // 1 ~ 16  beats in a burst (not AWLEN format)
     input [ 1:0]         xtype; // burst type
begin
     fork
     write_address_channel(id,addr,size,leng,xtype);
     write_data_channel(id,addr,size,leng,xtype);
     write_resp_channel(id);
     join
end
endtask
//----------------------------------------------------------------
task write_address_channel;
     input [WIDTH_ID-1:0] id;
     input [WIDTH_AD-1:0] addr;
     input [15:0]         size; // 1 ~ 128 byte in a beat
     input [ 8:0]         leng; // 1 ~ 16  beats in a burst (not AWLEN format)
     input [ 1:0]         xtype; // burst type
begin
     @ (posedge ACLK);
     AWID    <= `WDELAYxx id;
     AWADDR  <= `WDELAYxx addr;
     AWLEN   <= `WDELAYxx leng-1;
     AWLOCK  <= `WDELAYxx 'b0;
     AWSIZE  <= `WDELAYxx get_size(size);
     AWBURST <= `WDELAYxx  xtype[1:0];
     `ifdef AMBA_AXI_PROT
     AWPROT  <= `WDELAYxx 'h0; // data, secure, normal
     `endif
     AWVALID <= `WDELAYxx 'b1;
     @ (posedge ACLK);
     while (AWREADY==1'b0) @ (posedge ACLK);
     AWVALID <= `WDELAYxx 'b0;
     @ (negedge ACLK);
end
endtask
//----------------------------------------------------------------
task write_data_channel;
     input [WIDTH_ID-1:0] id;
     input [WIDTH_AD-1:0] addr;
     input [15:0]         size; // 1 ~ 128 byte in a beat
     input [ 8:0]         leng; // 1 ~ 16  beats in a burst (not AWLEN format)
     input [ 1:0]         xtype; // burst type
     reg   [WIDTH_AD-1:0] naddr;
     integer idx;
begin
     naddr  = addr;
     @ (posedge ACLK);
     `ifndef AMBA_AXI4
     WID    <= `WDELAYxx id;
     `endif
     WVALID <= `WDELAYxx 1'b1;
     for (idx=0; idx<leng; idx=idx+1) begin
          WDATA <= `WDELAYxx get_data(addr, naddr, size);
          WSTRB <= `WDELAYxx get_strb(naddr, size);
          WLAST <= `WDELAYxx (idx==(leng-1));
          naddr <= get_next_addr(naddr, size, xtype);
          @ (posedge ACLK);
          while (WREADY==1'b0) @ (posedge ACLK);
     end
     WLAST  <= `WDELAYxx 'b0;
     WVALID <= `WDELAYxx 'b0;
     @ (negedge ACLK);
end
endtask
//----------------------------------------------------------------
task write_resp_channel;
     input [WIDTH_ID-1:0] id;
begin
     BREADY <= `WDELAYxx 'b1;
     @ (posedge ACLK);
     while (BVALID==1'b0) @ (posedge ACLK);
     if (id!=BID) begin
        $display("%0t %m Error id mis-match for write-resp-channel 0x%x/0x%x", $time, id, BID);
     end else begin
         case (BRESP)
         2'b00: begin
                `ifdef DEBUG
                $display("%0t %m OK response for write-resp-channel: OKAY", $time);
                `endif
                end
         2'b01: $display("%0t %m OK response for write-resp-channel: EXOKAY", $time);
         2'b10: $display("%0t %m Error response for write-resp-channel: SLVERR", $time);
         2'b11: $display("%0t %m Error response for write-resp-channel: DECERR", $time);
         endcase
     end
     BREADY <= `WDELAYxx 'b0;
     @ (negedge ACLK);
end
endtask
//----------------------------------------------------------------
// input: num of bytes
// output: AxSIZE[2:0] code
function [2:0] get_size;
   input [15:0] size;
begin
   case (size)
     1: get_size = 0;
     2: get_size = 1;
     4: get_size = 2;
     8: get_size = 3;
    16: get_size = 4;
    32: get_size = 5;
    64: get_size = 6;
   128: get_size = 7;
   default: get_size = 0;
   endcase
end
endfunction
//----------------------------------------------------------------
function [WIDTH_DS-1:0] get_strb;
    input [WIDTH_AD-1:0] addr;
    input [15:0]         size; // num of bytes in a beat
    integer offset;
    reg   [127:0] bit_size;
begin
    offset   = addr[WIDTH_DSB-1:0];
    case (size)
      1: bit_size = {  1{1'b1}};
      2: bit_size = {  2{1'b1}};
      4: bit_size = {  4{1'b1}};
      8: bit_size = {  8{1'b1}};
     16: bit_size = { 16{1'b1}};
     32: bit_size = { 32{1'b1}};
     64: bit_size = { 64{1'b1}};
    128: bit_size = {128{1'b1}};
    default: bit_size = 0;
    endcase
    get_strb = bit_size<<offset;
end
endfunction
//----------------------------------------------------------------
function [WIDTH_AD-1:0] get_next_addr;
    input [WIDTH_AD-1:0] addr; // current address
    input [15:0]         size; // num of bytes in a beat
    input [ 1:0]         xtype; // type of burst
    integer offset;
begin
    case (xtype[1:0])
    2'b00: get_next_addr = addr; // fixed
    2'b01: begin // increment
           offset = addr[WIDTH_DSB-1:0];
           if ((offset+size)<=WIDTH_DS) begin
               get_next_addr = addr + size;
           end else begin // (offset+size)>nb
               get_next_addr = addr + WIDTH_DS - size;
           end
           end
    2'b10: begin // wrap
           if ((addr%size)!=0) begin
              $display("%0t %m wrap-burst not aligned", $time);
              get_next_addr = addr;
           end else begin
               offset = addr[WIDTH_DSB-1:0];
               if ((offset+size)<=WIDTH_DS) begin
                   get_next_addr = addr + size;
               end else begin // (offset+size)>nb
                   get_next_addr = addr + WIDTH_DS - size;
               end
           end
           end
    default: $display("%0t %m Error un-defined burst-type: %2b", $time, xtype);
    endcase
end
endfunction
//----------------------------------------------------------------
// dataWB[0]   = saddr + 0;
// dataWB[1]   = saddr + 1;
// dataWB[2]   = saddr + 2;
//
function [WIDTH_DA-1:0] get_data;
    input [WIDTH_AD-1:0] saddr; // start address
    input [WIDTH_AD-1:0] addr;  // current address
    input [15:0]         size;
    reg   [ 7:0]         data[0:WIDTH_DS-1];
    integer offset, idx, idy, idz, ids;
begin
    `ifdef RIGOR
    for (idx=0; idx<WIDTH_DS; idx=idx+1) begin
         data[idx] = 'bX;
    end
    `endif
    offset = addr%WIDTH_DS;
    ids = 0;
    for (idx=addr%WIDTH_DS; (idx<WIDTH_DS)&&(ids<size); idx=idx+1) begin
         idz = addr+(idx-offset)-saddr;
         data[idx] = dataWB[idz];
         ids = ids + 1;
    end
    get_data = 0;
    for (idy=0; idy<WIDTH_DS; idy=idy+1) begin
         get_data = get_data|(data[idy]<<(8*idy));
    end
end
endfunction
//----------------------------------------------------------------
// Revision History
//
// 2021.09.18: 'write_data_channel' task WSTRB bug-fixed.
// 2021.09.18: 'test_raw_all' task 'type' bug-fixed.
// 2021.09.18: Use parameter for function arguments.
// 2017.06.22: 'test_raw_burst' bug-fixed by Ando Ki.
// 2013.02.03: Started by Ando Ki (adki@future-ds.com)
//----------------------------------------------------------------
