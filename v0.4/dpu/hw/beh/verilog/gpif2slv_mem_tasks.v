//----------------------------------------------------------------
// Read-After-Write
task test_raw;
     input [31:0] saddr; // start address
     input [31:0] depth; // size in byte
     input [31:0] bsize; // burst size in byte
     input [31:0] bleng; // burst length
     input integer verbose;
     reg   [31:0] addr;
     integer      idx, idy, idz, error;
     reg   [31:0] msk;
     reg   [32*256-1:0] burst_dataW;
     reg   [32*256-1:0] burst_dataR;
begin
    error = 0;
    addr = saddr;
    case (bsize)
    1: msk = 32'h0000_00FF;
    2: msk = 32'h0000_FFFF;
    4: msk = 32'hFFFF_FFFF;
    endcase
    for (idy=0; idy<depth; idy=idy+bsize*bleng) begin
        for (idx=0; idx<bleng; idx=idx+1) begin
            burst_dataW[idx*32+:32] = idy+idx+1;
        end
        axi_write      ( addr
                       , bsize
                       , bleng
                       , burst_dataW
                       );
        axi_read       ( addr
                       , bsize
                       , bleng
                       , burst_dataR
                       );
        for (idz=0; idz<bleng; idz=idz+1) begin
             if ((burst_dataW[idz*32+:32]&msk)!==(burst_dataR[idz*32+:32]&msk)) begin
                 error = error + 1;
                 if (verbose>0)
                 $display("%0t %m Error A:0x%08X D:0x%08X, but 0x%08X expected",
                                  $time, addr+idz, burst_dataW[idz*32+:32]&msk, burst_dataR[idz*32+:32]&msk);
             end
             `ifdef DEBUG
             else begin
                 if (verbose)
                 $display("%0t %m OK A:0x%08X D:0x%08X", $time, addr+idz, burst_dataR[idz*32+:32]&msk);
             end
             `endif
        end
        addr = addr + bsize*bleng;
    end
    if (error==0) $display("%0t %m test_raw from 0x%08X to 0x%08X %03d-size %03d-leng OK",
                            $time, saddr, saddr+depth-1, bsize, bleng);
    else          $display("%0t %m test_raw from 0x%08X to 0x%08X %03d-size %03d-leng %0d ERROR",
                            $time, saddr, saddr+depth-1, bsize, bleng, error);
end
endtask
//----------------------------------------------------------------
// Read-After-Write ALL
task test_raw_all;
     input [31:0] saddr; // start address
     input [31:0] depth; // size in byte
     input [31:0] bsize; // burst size in byte
     input [31:0] bleng; // burst length
     input integer verbose;
     reg   [31:0] addr;
     integer      idx, idy, idz, error;
     reg   [31:0] msk;
     reg   [32*256-1:0] burst_dataW;
     reg   [32*256-1:0] burst_dataR;
begin
    error = 0;
    addr = saddr;
    case (bsize)
    1: msk = 32'h0000_00FF;
    2: msk = 32'h0000_FFFF;
    4: msk = 32'hFFFF_FFFF;
    endcase
    for (idy=0; idy<depth; idy=idy+bsize*bleng) begin
        for (idx=0; idx<bleng; idx=idx+1) begin
            burst_dataW[idx*32+:32] = (idy+idx+1)&msk;
        end
        axi_write      ( addr
                       , bsize
                       , bleng
                       , burst_dataW
                       );
        addr = addr + bsize*bleng;
    end
    addr = saddr;
    for (idy=0; idy<depth; idy=idy+bsize*bleng) begin
        axi_read       ( addr
                       , bsize
                       , bleng
                       , burst_dataR
                       );
        for (idz=0; idz<bleng; idz=idz+1) begin
             if (((idy+idz+1)&msk)!==(burst_dataR[idz*32+:32]&msk)) begin
                 error = error + 1;
                 if (verbose)
                 $display("%0t %m Error A:0x%x D:0x%x, but 0x%x expected",
                                  $time, addr+idz, burst_dataR[idz*32+:32]&msk, (idy+idz+1)&msk);
             end
        end
        addr = addr + bsize*bleng;
    end
    if (error==0) $display("%0t %m test_raw_all from 0x%08X to 0x%08X %03d-size %03d-leng OK",
                               $time, saddr, saddr+depth-1, bsize, bleng);
    else          $display("%0t %m test_raw_all from 0x%08X to 0x%08X %03d-size %03d-leng %0d ERROR",
                               $time, saddr, saddr+depth-1, bsize, bleng, error);
end
endtask
//----------------------------------------------------------------
