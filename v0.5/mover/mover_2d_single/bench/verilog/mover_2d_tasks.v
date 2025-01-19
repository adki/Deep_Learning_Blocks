
   localparam CSRA_VERSION        = (ADDR_BASE_MOVER+'h00)
            , CSRA_CONTROL        = (ADDR_BASE_MOVER+'h10)
            , CSRA_CONFIG         = (ADDR_BASE_MOVER+'h14)
            , CSRA_CONFIG_FIFO    = (ADDR_BASE_MOVER+'h18)
            , CSRA_COMMAND        = (ADDR_BASE_MOVER+'h20)
            , CSRA_SRCA_ADDR_LOW  = (ADDR_BASE_MOVER+'h30)
            , CSRA_SRCA_ADDR_HIGH = (ADDR_BASE_MOVER+'h34)
            , CSRA_SRCA_CFG_SIZE  = (ADDR_BASE_MOVER+'h38)
            , CSRA_SRCA_ITEMS     = (ADDR_BASE_MOVER+'h3C)
            , CSRA_SRCA_BURST     = (ADDR_BASE_MOVER+'h40)
            , CSRA_SRCB_ADDR_LOW  = (ADDR_BASE_MOVER+'h50)
            , CSRA_SRCB_ADDR_HIGH = (ADDR_BASE_MOVER+'h54)
            , CSRA_SRCB_CFG_SIZE  = (ADDR_BASE_MOVER+'h58)
            , CSRA_SRCB_ITEMS     = (ADDR_BASE_MOVER+'h5C)
            , CSRA_SRCB_BURST     = (ADDR_BASE_MOVER+'h60)
            , CSRA_RST_ADDR_LOW   = (ADDR_BASE_MOVER+'h70)
            , CSRA_RST_ADDR_HIGH  = (ADDR_BASE_MOVER+'h74)
            , CSRA_RST_CFG_SIZE   = (ADDR_BASE_MOVER+'h78)
            , CSRA_RST_ITEMS      = (ADDR_BASE_MOVER+'h7C)
            , CSRA_RST_BURST      = (ADDR_BASE_MOVER+'h80)
            , CSRA_FILL_VALUE     = (ADDR_BASE_MOVER+'h90)
            , CSRA_ACTIV_FUNC     = (ADDR_BASE_MOVER+'h94)
            , CSRA_ACTIV_PARAM    = (ADDR_BASE_MOVER+'h98)
            , CSRA_PROFILE_CTL               = (ADDR_BASE_MOVER+'hA0)// num of read
            , CSRA_PROFILE_CYCLES            = (ADDR_BASE_MOVER+'hA4)// num of read
            , CSRA_PROFILE_RESIDUAL_OVERFLOW = (ADDR_BASE_MOVER+'hA8)// num of read
            , CSRA_PROFILE_CNT_RD            = (ADDR_BASE_MOVER+'hAC)// num of read
            , CSRA_PROFILE_CNT_WR            = (ADDR_BASE_MOVER+'hB0)// num of write
            ;

   //---------------------------------------------------------------------------
   task csr_test;
       reg [31:0] data;
   begin
     read_word_task(CSRA_VERSION       ,data); $display("%m %s A:0x%08X D:0x%08X","VERSION       ",CSRA_VERSION       ,data);
     read_word_task(CSRA_CONTROL       ,data); $display("%m %s A:0x%08X D:0x%08X","CONTROL       ",CSRA_CONTROL       ,data);
     read_word_task(CSRA_CONFIG        ,data); $display("%m %s A:0x%08X D:0x%08X","CONFIG        ",CSRA_CONFIG        ,data);
     read_word_task(CSRA_CONFIG_FIFO   ,data); $display("%m %s A:0x%08X D:0x%08X","CONFIG_FIFO   ",CSRA_CONFIG_FIFO   ,data);
     read_word_task(CSRA_COMMAND       ,data); $display("%m %s A:0x%08X D:0x%08X","COMMAND       ",CSRA_COMMAND       ,data);
     read_word_task(CSRA_SRCA_ADDR_LOW ,data); $display("%m %s A:0x%08X D:0x%08X","SRCA_ADDR_LOW ",CSRA_SRCA_ADDR_LOW ,data);
     read_word_task(CSRA_SRCA_ADDR_HIGH,data); $display("%m %s A:0x%08X D:0x%08X","SRCA_ADDR_HIGH",CSRA_SRCA_ADDR_HIGH,data);
     read_word_task(CSRA_SRCA_CFG_SIZE ,data); $display("%m %s A:0x%08X D:0x%08X","SRCA_CFG_SIZE ",CSRA_SRCA_CFG_SIZE ,data);
     read_word_task(CSRA_SRCA_ITEMS    ,data); $display("%m %s A:0x%08X D:0x%08X","SRCA_ITEMS    ",CSRA_SRCA_ITEMS    ,data);
     read_word_task(CSRA_SRCA_BURST    ,data); $display("%m %s A:0x%08X D:0x%08X","SRCA_BURST    ",CSRA_SRCA_BURST    ,data);
     read_word_task(CSRA_SRCB_ADDR_LOW ,data); $display("%m %s A:0x%08X D:0x%08X","SRCB_ADDR_LOW ",CSRA_SRCB_ADDR_LOW ,data);
     read_word_task(CSRA_SRCB_ADDR_HIGH,data); $display("%m %s A:0x%08X D:0x%08X","SRCB_ADDR_HIGH",CSRA_SRCB_ADDR_HIGH,data);
     read_word_task(CSRA_SRCB_CFG_SIZE ,data); $display("%m %s A:0x%08X D:0x%08X","SRCB_CFG_SIZE ",CSRA_SRCB_CFG_SIZE ,data);
     read_word_task(CSRA_SRCB_ITEMS    ,data); $display("%m %s A:0x%08X D:0x%08X","SRCB_ITEMS    ",CSRA_SRCB_ITEMS    ,data);
     read_word_task(CSRA_SRCB_BURST    ,data); $display("%m %s A:0x%08X D:0x%08X","SRCB_BURST    ",CSRA_SRCB_BURST    ,data);
     read_word_task(CSRA_RST_ADDR_LOW  ,data); $display("%m %s A:0x%08X D:0x%08X","RST_ADDR_LOW  ",CSRA_RST_ADDR_LOW  ,data);
     read_word_task(CSRA_RST_ADDR_HIGH ,data); $display("%m %s A:0x%08X D:0x%08X","RST_ADDR_HIGH ",CSRA_RST_ADDR_HIGH ,data);
     read_word_task(CSRA_RST_CFG_SIZE  ,data); $display("%m %s A:0x%08X D:0x%08X","RST_CFG_SIZE  ",CSRA_RST_CFG_SIZE  ,data);
     read_word_task(CSRA_RST_ITEMS     ,data); $display("%m %s A:0x%08X D:0x%08X","RST_ITEMS     ",CSRA_RST_ITEMS     ,data);
     read_word_task(CSRA_RST_BURST     ,data); $display("%m %s A:0x%08X D:0x%08X","RST_BURST     ",CSRA_RST_BURST     ,data);
     read_word_task(CSRA_FILL_VALUE    ,data); $display("%m %s A:0x%08X D:0x%08X","FILL_VALUE    ",CSRA_FILL_VALUE    ,data);
     read_word_task(CSRA_ACTIV_FUNC    ,data); $display("%m %s A:0x%08X D:0x%08X","ACTIV_FUNC    ",CSRA_ACTIV_FUNC    ,data);
     read_word_task(CSRA_ACTIV_PARAM   ,data); $display("%m %s A:0x%08X D:0x%08X","ACTIV_PARAM   ",CSRA_ACTIV_PARAM   ,data);
     read_word_task(CSRA_PROFILE_CTL              ,data); $display("%m %s A:0x%08X D:0x%08X","PROFILE_CTL   ",CSRA_PROFILE_CTL              ,data);
     read_word_task(CSRA_PROFILE_CYCLES           ,data); $display("%m %s A:0x%08X D:0x%08X","PROFILE_CYCLES",CSRA_PROFILE_CYCLES           ,data);
     read_word_task(CSRA_PROFILE_RESIDUAL_OVERFLOW,data); $display("%m %s A:0x%08X D:0x%08X","OVERFLOW      ",CSRA_PROFILE_RESIDUAL_OVERFLOW,data);
     read_word_task(CSRA_PROFILE_CNT_RD           ,data); $display("%m %s A:0x%08X D:0x%08X","PROFILE_CNT_RD",CSRA_PROFILE_CNT_RD           ,data);
     read_word_task(CSRA_PROFILE_CNT_WR           ,data); $display("%m %s A:0x%08X D:0x%08X","PROFILE_CNT_WR",CSRA_PROFILE_CNT_WR           ,data);
   end
   endtask

   task mover_init;
       reg [31:0] dataW, dataR;
   begin
        read_word_task(CSRA_CONTROL,dataR);
        dataW = dataR | (1'b1<<31); // auto clean automatically
        write_word_task(CSRA_CONTROL,dataW);
        read_word_task(CSRA_CONTROL,dataR);
        if (!(dataR&(1<<30))) $display("%0t %m mover_ready should be 1.", $time);
        if   (dataR&(1<<31))  $display("%0t %m mover_init should be 0.", $time);
   end
   endtask

   //---------------------------------------------------------------------------
   task mover_get_config;
       output [ 7:0] q;
       output [ 7:0] n;
       output [15:0] src_fifo_dpeth;
       output [15:0] result_fifo_dpeth;
       reg [31:0] dataR;
   begin
       read_word_task(CSRA_CONFIG,dataR);
       n = dataR[7:0];
       q = dataR[15:8];
#1;
       read_word_task(CSRA_CONFIG_FIFO,dataR);
       src_fifo_dpeth  = dataR[ 7: 0];
       result_fifo_dpeth = dataR[15: 8];
   end
   endtask

   //---------------------------------------------------------------------------
   task mover_go_wait;
       input ie;
       input blocking;
       reg [31:0] dataW, dataR;
   begin
        read_word_task(CSRA_CONTROL,dataR);
        dataW = dataR | 'b111 | (ie<<28);
        write_word_task(CSRA_CONTROL,dataW);
        if (blocking) begin
            dataR = 'b111; // go clean automatically
            while (dataR[2:0]!=3'b0) begin
                read_word_task(CSRA_CONTROL,dataR);
            end
        end
        read_word_task(CSRA_CONTROL,dataR);
        if ((dataR[10:8]!=3'b0)||(dataR[2:0]!=3'b0))
            $display("%0t %m go-done error: 0x%08X", $time, dataR);
   end
   endtask

   //---------------------------------------------------------------------------
   task mover_clear_interrupt;
       reg [31:0] dataW, dataR;
   begin
        read_word_task(CSRA_CONTROL,dataR);
        dataW = dataR & ~(2'b11<<28);
        write_word_task(CSRA_CONTROL,dataW);
   end
   endtask

   //===========================================================================
// fill a block of memory.
// srcA can be dst
// last=flush (at the end of whole move)
   task mover_set_fill;
       input [WIDTH_AD-1:0] addr;
       input [DATA_WIDTH-1:0] fill_value;
       input [31:0] items;
       input [ 8:0] leng; // not AxLEN
       reg [15:0] width, height;
       reg [31:0] dataW;
   begin
       dataW = {28'h0,COMMAND_FILL[3:0]};
       write_word_task(CSRA_COMMAND, dataW);

       width = 1;
       height = items;

       write_word_task(CSRA_SRCA_CFG_SIZE, 0);
       write_word_task(CSRA_SRCA_ITEMS, 0);
       write_word_task(CSRA_SRCA_BURST, 0);
       write_word_task(CSRA_SRCB_CFG_SIZE, 0);
       write_word_task(CSRA_SRCB_ITEMS, 0);
       write_word_task(CSRA_SRCB_BURST, 0);

       write_word_task(CSRA_RST_ADDR_LOW , addr);
       write_word_task(CSRA_RST_ADDR_HIGH, 32'h0);
       write_word_task(CSRA_RST_CFG_SIZE , {height[15:0],width[15:0]});
       write_word_task(CSRA_RST_ITEMS    , items);
       write_word_task(CSRA_RST_BURST    , leng[8:0]-1);
       write_word_task(CSRA_FILL_VALUE   , fill_value);

       write_word_task(CSRA_ACTIV_FUNC   , ACTIV_FUNC_BYPASS);
   end
   endtask

   //---------------------------------------------------------------------------
   task check_result_fill;
       input [WIDTH_AD-1:0] addr;
       input [DATA_WIDTH-1:0] fill_value;
       input [31:0] items;
       integer ida, idb, error;
       reg [WIDTH_DA*2-1:0] dataW;
       reg [WIDTH_DA-1:0] dataR, dataS;
       reg [WIDTH_AD-1:0] addrR;
   begin
       error = 0;
       dataW[0+:WIDTH_DA]        = {(WIDTH_DA/DATA_WIDTH){fill_value}};
       dataW[WIDTH_DA+:WIDTH_DA] = {(WIDTH_DA/DATA_WIDTH){fill_value}};
       addrR = addr;
       for (ida=0; ida<items; ida=ida+(WIDTH_DA/DATA_WIDTH)) begin
            dataS = dataW>>(8*addrR[WIDTH_DSB-1:0]);
            top.u_mem.read(addrR,dataR,WIDTH_DS);
//if (dataS!==dataR)
//$display("%0t %m 0x%X addrD=0x%08X:%X", $time, dataS, addrR, dataR);
            for (idb=0; idb<(WIDTH_DA/DATA_WIDTH); idb=idb+1) begin
                 if (dataS[idb*DATA_WIDTH+:DATA_WIDTH]!==
                     dataR[idb*DATA_WIDTH+:DATA_WIDTH]) begin
//$display("%0t %m 0x%X addrD=0x%08X+%0d:%X", $time, 
//                       dataS[idb*DATA_WIDTH+:DATA_WIDTH],
//           addrR, idb, dataR[idb*DATA_WIDTH+:DATA_WIDTH]);
                     error = error+1;
                 end
            end
            addrR = addrR + WIDTH_DS;
       end // for (ida
       if (error>0) $display("%0t %m \033[0;31mmis-match\033[0m %-d out of %-d.", $time, error, items);
       else         $display("%0t %m \033[0;33mOK\033[0m %-d.", $time, items);
   end
   endtask

   //===========================================================================
// Simple DMA supporting mis-aligned address both srcA and dst
// +------------+          +------------+
// |srcA        | -+-+-+   |dst         |
// |            |=>| | |==>|            |
// |            | -+-+-+   |            |
// +------------+          +------------+
// srcA can be dst
// last=flush (at the end of whole move)
   task mover_set_copy;
       input [WIDTH_AD-1:0] dst_addr;
       input [WIDTH_AD-1:0] src_addr;
       input [15:0] src_width;
       input [15:0] src_height;
       input [ 8:0] src_leng; // not AxLEN
       reg [31:0] dataW;
   begin
       dataW = {28'h0,COMMAND_COPY[3:0]};
       write_word_task(CSRA_COMMAND, dataW);
       write_word_task(CSRA_SRCA_ADDR_LOW , src_addr);
       write_word_task(CSRA_SRCA_ADDR_HIGH, 32'h0   );
       dataW = {src_height[15:0],src_width[15:0]};
       write_word_task(CSRA_SRCA_CFG_SIZE, dataW);
       dataW = src_height[15:0]*src_width[15:0];
       write_word_task(CSRA_SRCA_ITEMS, dataW);
       dataW = src_leng[8:0]-1;
       write_word_task(CSRA_SRCA_BURST, dataW);

       write_word_task(CSRA_RST_ADDR_LOW , dst_addr);
       write_word_task(CSRA_RST_ADDR_HIGH, 32'h0);
       write_word_task(CSRA_RST_CFG_SIZE , {src_height[15:0],src_width[15:0]});
       write_word_task(CSRA_RST_ITEMS    ,  src_height[15:0]*src_width[15:0] );
       write_word_task(CSRA_RST_BURST    , src_leng[8:0]-1);

       write_word_task(CSRA_ACTIV_FUNC   , ACTIV_FUNC_BYPASS);
   end
   endtask

   //---------------------------------------------------------------------------
   task check_result_copy;
       input [WIDTH_AD-1:0] dst_addr;
       input [WIDTH_AD-1:0] src_addr;
       input [15:0] src_width;
       input [15:0] src_height;
       integer ida, idb, error;
       reg [WIDTH_DA-1:0] dataS, dataR;
       reg [WIDTH_AD-1:0] addrS, addrR;
   begin
       error = 0;
       addrS = src_addr;
       addrR = dst_addr;
       for (ida=0; ida<src_height*src_width; ida=ida+(WIDTH_DA/DATA_WIDTH)) begin
            top.u_mem.read(addrS,dataS,WIDTH_DS);
            top.u_mem.read(addrR,dataR,WIDTH_DS);
//if (dataS!==dataR)
//$display("%0t %m addrS=0x%08X:%X addrD=0x%08X:%X", $time, addrS, dataS, addrR, dataR);
            for (idb=0; idb<(WIDTH_DA/DATA_WIDTH); idb=idb+1) begin
                 if (dataS[idb*DATA_WIDTH+:DATA_WIDTH]!==
                     dataR[idb*DATA_WIDTH+:DATA_WIDTH]) begin
//$display("%0t %m addrS=0x%08X+%0d:%X addrD=0x%08X+%0d:%X", $time, 
//             addrS, idb, dataS[idb*DATA_WIDTH+:DATA_WIDTH],
//             addrR, idb, dataR[idb*DATA_WIDTH+:DATA_WIDTH]);
                     error = error+1;
                 end
            end
            addrS = addrS + WIDTH_DS;
            addrR = addrR + WIDTH_DS;
       end // for (ida
       if (error>0) $display("%0t %m \033[0;31mmis-match\033[0m %-d out of %-d.", $time, error, src_height*src_width);
       else         $display("%0t %m \033[0;33mOK\033[0m %-d.", $time, src_height*src_width);
   end
   endtask

   //---------------------------------------------------------------------------
   task check_result_copy_activation;
       input [WIDTH_AD-1:0] dst_addr;
       input [WIDTH_AD-1:0] src_addr;
       input [15:0] src_width;
       input [15:0] src_height;
       input integer activ_func;
       input integer activ_param;
       integer ida, idb, error;
       reg [WIDTH_DA-1:0] dataS, dataR;
       reg [WIDTH_AD-1:0] addrS, addrR;
       reg [DATA_WIDTH-1:0] dataA;
   begin
       error = 0;
       addrS = src_addr;
       addrR = dst_addr;
       for (ida=0; ida<src_height*src_width; ida=ida+(WIDTH_DA/DATA_WIDTH)) begin
            top.u_mem.read(addrS,dataS,WIDTH_DS);
            top.u_mem.read(addrR,dataR,WIDTH_DS);
//if (dataS!==dataR)
//$display("%0t %m addrS=0x%08X:%X addrD=0x%08X:%X", $time, addrS, dataS, addrR, dataR);
            for (idb=0; idb<(WIDTH_DA/DATA_WIDTH); idb=idb+1) begin
                 dataA = func_activation(dataS[idb*DATA_WIDTH+:DATA_WIDTH], activ_func, activ_param);
                 if (dataR[idb*DATA_WIDTH+:DATA_WIDTH]!==dataA) begin
$display("%0t %m addrS=0x%08X+%0d:%X addrD=0x%08X+%0d:%X", $time, 
             addrS, idb, dataR[idb*DATA_WIDTH+:DATA_WIDTH],
             addrR, idb, dataA);
                     error = error+1;
                 end
            end
            addrS = addrS + WIDTH_DS;
            addrR = addrR + WIDTH_DS;
       end // for (ida
       if (error>0) $display("%0t %m \033[0;31mmis-match\033[0m %-d out of %-d.", $time, error, src_height*src_width);
       else         $display("%0t %m \033[0;33mOK\033[0m %-d.", $time, src_height*src_width);
   end
   endtask

   function [DATA_WIDTH-1:0] func_activation;
       input [DATA_WIDTH-1:0] value;
       input integer activ_func;
       input integer activ_param;
   begin
      case (activ_func)
      ACTIV_FUNC_RELU: begin
            if (value[DATA_WIDTH-1]) func_activation = 'h0; // negative
            else                     func_activation = value;
            end
      ACTIV_FUNC_LEAKY_RELU: begin
            if (value[DATA_WIDTH-1]==1'b0) begin // positive
                func_activation = value;
            end else begin // negative
                if (DATA_TYPE=="FLOATING_POINT") begin
                    func_activation = value;
                    if (DATA_WIDTH==32) func_activation[30:23] = value[30:23] - activ_param;
                    else if (DATA_WIDTH==16) func_activation[14:10] = value[14:10] - activ_param;
                end else begin
                    func_activation = value>>activ_param;
                end
            end
            end
      default: func_activation = value;
      endcase
   end
   endfunction

   //===========================================================================
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
   task mover_set_residual;
       input [WIDTH_AD-1:0] dst_addr;
       input [WIDTH_AD-1:0] srcA_addr;
       input [WIDTH_AD-1:0] srcB_addr;
       input [15:0] src_width;
       input [15:0] src_height;
       input [ 8:0] src_leng; // not AxLEN
   begin
       write_word_task(CSRA_COMMAND, {28'h0,COMMAND_RESIDUAL[3:0]});

       write_word_task(CSRA_SRCA_ADDR_LOW , srcA_addr);
       write_word_task(CSRA_SRCA_ADDR_HIGH, 32'h0    );
       write_word_task(CSRA_SRCA_CFG_SIZE, {src_height[15:0],src_width[15:0]});
       write_word_task(CSRA_SRCA_ITEMS, src_height[15:0]*src_width[15:0]);
       write_word_task(CSRA_SRCA_BURST, src_leng[8:0]-1);

       write_word_task(CSRA_SRCB_ADDR_LOW , srcB_addr);
       write_word_task(CSRA_SRCB_ADDR_HIGH, 32'h0    );
       write_word_task(CSRA_SRCB_CFG_SIZE , {src_height[15:0],src_width[15:0]});
       write_word_task(CSRA_SRCB_ITEMS, src_height[15:0]*src_width[15:0]);
       write_word_task(CSRA_SRCB_BURST, src_leng[8:0]-1);

       write_word_task(CSRA_RST_ADDR_LOW , dst_addr);
       write_word_task(CSRA_RST_ADDR_HIGH, 32'h0);
       write_word_task(CSRA_RST_CFG_SIZE , {src_height[15:0],src_width[15:0]});
       write_word_task(CSRA_RST_ITEMS    ,  src_height[15:0]*src_width[15:0] );
       write_word_task(CSRA_RST_BURST    ,  src_leng[8:0]-1);

       write_word_task(CSRA_ACTIV_FUNC   , ACTIV_FUNC_BYPASS);
   end
   endtask

   //---------------------------------------------------------------------------
   task check_result_residual;
       input [WIDTH_AD-1:0] dst_addr;
       input [WIDTH_AD-1:0] srcA_addr;
       input [WIDTH_AD-1:0] srcB_addr;
       input [15:0] src_width;
       input [15:0] src_height;
       integer idx, idy, idz, error;
       reg [DATA_WIDTH-1:0] dataSA, dataSB, dataR;
       reg [DATA_WIDTH:0]   sum;
       reg [WIDTH_AD-1:0]   addrSA, addrSB, addrR;
       reg                  overflow;
   begin
       error = 0;
       addrSA= srcA_addr;
       addrSB= srcB_addr;
       addrR = dst_addr;
       for (idy=0; idy<src_height; idy=idy+1) begin
           for (idx=0; idx<src_width ; idx=idx+1) begin
                top.u_mem.read(addrSA,dataSA,DATA_BYTES); // justified data
                top.u_mem.read(addrSB,dataSB,DATA_BYTES); // justified data
                top.u_mem.read(addrR ,dataR ,DATA_BYTES); // justified data
                sum = $signed(dataSA) + $signed(dataSB);
                overflow = ((~dataSA[DATA_WIDTH-1]&~dataSB[DATA_WIDTH-1])& sum[DATA_WIDTH-1]) // (+)+(+)->(-)
                         | (( dataSA[DATA_WIDTH-1]& dataSB[DATA_WIDTH-1])&~sum[DATA_WIDTH-1]);// (-)+(-)->(+)
                if (overflow) begin
                    if (dataSA[DATA_WIDTH-1]) sum = {2'b01,{DATA_WIDTH-1{1'b0}}}; // MAX_NEGATIVE
                    else                      sum = {2'b00,{DATA_WIDTH-1{1'b1}}}; // MAX_POSITIVE
                end
                if (sum[DATA_WIDTH-1:0]!==dataR) begin
$display("%0t %m A:0x%X: 0x%X+0x%X=0x%X, but got 0x%X", $time, addrR, dataSA, dataSB, sum[DATA_WIDTH-1:0], dataR);
                        error = error+1;
                end

                addrSA= addrSA+DATA_BYTES;
                addrSB= addrSB+DATA_BYTES;
                addrR = addrR +DATA_BYTES;
           end
       end
       if (error>0) $display("%0t %m \033[0;31mmis-match\033[0m %-d out of %-d.", $time, error, src_height*src_width);
       else         $display("%0t %m \033[0;33mOK\033[0m %-d.", $time, src_height*src_width);
   end
   endtask

   //===========================================================================
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
   task mover_set_concat0;
       input [WIDTH_AD-1:0] dst_addr;
       input [WIDTH_AD-1:0] srcA_addr;
       input [WIDTH_AD-1:0] srcB_addr;
       input [15:0] srcA_width;
       input [15:0] srcA_height;
       input [15:0] srcB_width;
       input [15:0] srcB_height;
       input [ 8:0] src_leng; // not AxLEN
   begin
       write_word_task(CSRA_COMMAND, {28'h0,COMMAND_CONCAT0[3:0]});

       write_word_task(CSRA_SRCA_ADDR_LOW , srcA_addr);
       write_word_task(CSRA_SRCA_ADDR_HIGH, 32'h0    );
       write_word_task(CSRA_SRCA_CFG_SIZE, {srcA_height[15:0],srcA_width[15:0]});
       write_word_task(CSRA_SRCA_ITEMS, srcA_height[15:0]*srcA_width[15:0]);
       write_word_task(CSRA_SRCA_BURST, src_leng[8:0]-1);

       write_word_task(CSRA_SRCB_ADDR_LOW , srcB_addr);
       write_word_task(CSRA_SRCB_ADDR_HIGH, 32'h0    );
       write_word_task(CSRA_SRCB_CFG_SIZE, {srcB_height[15:0],srcB_width[15:0]});
       write_word_task(CSRA_SRCB_ITEMS, srcB_height[15:0]*srcB_width[15:0]);
       write_word_task(CSRA_SRCB_BURST, src_leng[8:0]-1);

       write_word_task(CSRA_RST_ADDR_LOW , dst_addr);
       write_word_task(CSRA_RST_ADDR_HIGH, 32'h0);
       write_word_task(CSRA_RST_CFG_SIZE , {srcA_height[15:0]+srcB_height[15:0],srcA_width[15:0]});
       write_word_task(CSRA_RST_ITEMS    , (srcA_height[15:0]+srcB_height[15:0])*srcA_width[15:0] );
       write_word_task(CSRA_RST_BURST    , src_leng[8:0]-1);

       write_word_task(CSRA_ACTIV_FUNC   , ACTIV_FUNC_BYPASS);
   end
   endtask

   //---------------------------------------------------------------------------
   task check_result_concat0;
       input [WIDTH_AD-1:0] dst_addr;
       input [WIDTH_AD-1:0] srcA_addr;
       input [WIDTH_AD-1:0] srcB_addr;
       input [15:0] srcA_width;
       input [15:0] srcA_height;
       input [15:0] srcB_width;
       input [15:0] srcB_height;
       integer idx, idy, idz, error;
       reg [WIDTH_DA-1:0] dataS, dataR;
       reg [WIDTH_AD-1:0] addrSA, addrSB, addrR;
   begin
       if (srcA_width!=srcB_width) $display("%0t %m width mis-match.", $time);
       error = 0;
       addrSA= srcA_addr;
       addrSB= srcB_addr;
       addrR = dst_addr;
       for (idy=0; idy<srcA_height; idy=idy+1) begin
           for (idx=0; idx<srcA_width ; idx=idx+1) begin
                top.u_mem.read(addrSA,dataS,DATA_BYTES); // justified data
                top.u_mem.read(addrR ,dataR,DATA_BYTES); // justified data
                if (dataS[DATA_WIDTH-1:0]!==dataR[DATA_WIDTH-1:0]) begin
$display("%0t %m [%08X]0x%08X, but [%08X]0x%08X expected.", $time, 
          addrR, dataR[DATA_WIDTH-1:0],
          addrSA, dataS[DATA_WIDTH-1:0]);
                    error = error+1;
                end
                //for (idz=0; idz<(WIDTH_DA/DATA_WIDTH); idz=idz+1) begin
                //     if (dataS[idz*DATA_WIDTH+:DATA_WIDTH]!==
                //         dataR[idz*DATA_WIDTH+:DATA_WIDTH]) begin
                //         error = error+1;
                //     end
                //end // for (idz
                addrSA= addrSA+ DATA_BYTES;
                addrR = addrR + DATA_BYTES;
           end // for (idx
           end // for (idy
           for (idy=0; idy<srcB_height; idy=idy+1) begin
           for (idx=0; idx<srcB_width ; idx=idx+1) begin
                top.u_mem.read(addrSB,dataS,DATA_BYTES); // justified data
                top.u_mem.read(addrR ,dataR,DATA_BYTES); // justified data
                if (dataS[DATA_WIDTH-1:0]!==dataR[DATA_WIDTH-1:0]) begin
$display("%0t %m [%08X]0x%08X, but [%08X]0x%08X expected.", $time, 
         addrR, dataR[DATA_WIDTH-1:0],
         addrSB, dataS[DATA_WIDTH-1:0]);
                    error = error+1;
                end
                //for (idz=0; idz<(WIDTH_DA/DATA_WIDTH); idz=idz+1) begin
                //     if (dataS[idz*DATA_WIDTH+:DATA_WIDTH]!==
                //         dataR[idz*DATA_WIDTH+:DATA_WIDTH]) begin
                //         error = error+1;
                //     end
                //end // for (idz
                addrSB= addrSB+ DATA_BYTES;
                addrR = addrR + DATA_BYTES;
           end // for (idx
       end // for (idy

       if (error>0) $display("%0t %m \033[0;31mmis-match\033[0m %-d out of %-d.", $time, error, (srcA_height+srcB_height)*srcA_width);
       else         $display("%0t %m \033[0;33mOK\033[0m %-d.", $time, (srcA_height+srcB_height)*srcA_width);
   end
   endtask

   //===========================================================================
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
   task mover_set_concat1;
       input [WIDTH_AD-1:0] dst_addr;
       input [WIDTH_AD-1:0] srcA_addr;
       input [WIDTH_AD-1:0] srcB_addr;
       input [15:0] srcA_width;
       input [15:0] srcA_height;
       input [15:0] srcB_width;
       input [15:0] srcB_height;
       input [ 8:0] src_leng; // not AxLENG
   begin
       write_word_task(CSRA_COMMAND, {28'h0,COMMAND_CONCAT1[3:0]});

       write_word_task(CSRA_SRCA_ADDR_LOW , srcA_addr);
       write_word_task(CSRA_SRCA_ADDR_HIGH, 32'h0    );
       write_word_task(CSRA_SRCA_CFG_SIZE, {srcA_height[15:0],srcA_width[15:0]});
       write_word_task(CSRA_SRCA_ITEMS, srcA_height[15:0]*srcA_width[15:0]);
       write_word_task(CSRA_SRCA_BURST, src_leng[8:0]-1);

       write_word_task(CSRA_SRCB_ADDR_LOW , srcB_addr);
       write_word_task(CSRA_SRCB_ADDR_HIGH, 32'h0    );
       write_word_task(CSRA_SRCB_CFG_SIZE, {srcB_height[15:0],srcB_width[15:0]});
       write_word_task(CSRA_SRCB_ITEMS, srcB_height[15:0]*srcB_width[15:0]);
       write_word_task(CSRA_SRCB_BURST, src_leng[8:0]-1);

       write_word_task(CSRA_RST_ADDR_LOW , dst_addr);
       write_word_task(CSRA_RST_ADDR_HIGH, 32'h0);
       write_word_task(CSRA_RST_CFG_SIZE ,{srcA_height[15:0],srcA_width[15:0]+srcB_width[15:0]});
       write_word_task(CSRA_RST_ITEMS    , srcA_height[15:0]*(srcA_width[15:0]+srcB_width[15:0]));
       write_word_task(CSRA_RST_BURST    , src_leng[8:0]-1);

       write_word_task(CSRA_ACTIV_FUNC   , ACTIV_FUNC_BYPASS);
   end
   endtask

   //---------------------------------------------------------------------------
   task check_result_concat1;
       input [WIDTH_AD-1:0] dst_addr;
       input [WIDTH_AD-1:0] srcA_addr;
       input [WIDTH_AD-1:0] srcB_addr;
       input [15:0] srcA_width;
       input [15:0] srcA_height;
       input [15:0] srcB_width;
       input [15:0] srcB_height;
       integer idx, idy, idz, error;
       reg [WIDTH_DA-1:0] dataS, dataR;
       reg [WIDTH_AD-1:0] addrSA, addrSB, addrR;
   begin
       if (srcA_height!=srcB_height) $display("%0t %m height mis-match.", $time);
       error = 0;
       addrSA = srcA_addr;
       addrSB = srcB_addr;
       addrR  = dst_addr ;
       for (idy=0; idy<srcA_height; idy=idy+1) begin
           for (idx=0; idx<srcA_width ; idx=idx+1) begin
                top.u_mem.read(addrSA,dataS,DATA_BYTES);
                top.u_mem.read(addrR ,dataR,DATA_BYTES);
                if (dataS[DATA_WIDTH-1:0]!==dataR[DATA_WIDTH-1:0]) begin
$display("%0t %m [%08X]0x%08X, but [%08X]0x%08X expected.", $time, 
          addrR, dataR[DATA_WIDTH-1:0],
          addrSA, dataS[DATA_WIDTH-1:0]);
                    error = error+1;
                end
                //for (idz=0; idz<(WIDTH_DA/DATA_WIDTH); idz=idz+1) begin
                //     if (dataS[idz*DATA_WIDTH+:DATA_WIDTH]!==
                //         dataR[idz*DATA_WIDTH+:DATA_WIDTH]) begin
//$display("%0t %m [%08X]0x%08X, but [%08X]0x%08X expected.", $time, 
                //         addrR,dataR[idz*DATA_WIDTH+:DATA_WIDTH],
                //         addrSA,dataS[idz*DATA_WIDTH+:DATA_WIDTH]);
                //         error = error+1;
                //     end
                //end // for (idz
#1;
                addrSA = addrSA + DATA_BYTES;
                addrR  = addrR  + DATA_BYTES;
           end // for (idx
           for (idx=0; idx<srcB_width ; idx=idx+1) begin
                top.u_mem.read(addrSB,dataS,DATA_BYTES);
                top.u_mem.read(addrR ,dataR,DATA_BYTES);
                if (dataS[DATA_WIDTH-1:0]!==dataR[DATA_WIDTH-1:0]) begin
$display("%0t %m [%08X]0x%08X, but [%08X]0x%08X expected.", $time, 
         addrR, dataR[DATA_WIDTH-1:0],
         addrSB, dataS[DATA_WIDTH-1:0]);
                    error = error+1;
                end
                //for (idz=0; idz<(WIDTH_DA/DATA_WIDTH); idz=idz+1) begin
                //     if (dataS[idz*DATA_WIDTH+:DATA_WIDTH]!==
                //         dataR[idz*DATA_WIDTH+:DATA_WIDTH]) begin
//$display("%0t %m [%08X]0x%08X, but [%08X]0x%08X expected.", $time, 
                //         addrR,dataR[idz*DATA_WIDTH+:DATA_WIDTH],
                //         addrSB,dataS[idz*DATA_WIDTH+:DATA_WIDTH]);
                //         error = error+1;
                //     end
                //end // for (idz
#1;
                addrSB = addrSB + DATA_BYTES;
                addrR  = addrR  + DATA_BYTES;
           end // for (idx
       end // for (idy

       if (error>0) $display("%0t %m mis-match %-d out of %-d.", $time, error, srcA_height*(srcA_width+srcB_width));
       else         $display("%0t %m OK %-d.", $time, srcA_height*(srcA_width+srcB_width));
   end
   endtask

   //===========================================================================
// need to move line-by-line
// +------------+          +------+
// |srcA        | -+-+-+   |dst   |
// |            |=>| | |==>|      |
// +------------+ -+-+-+   |      |
//                         |      |
//                         +------+
// srcA cannot be dst
// last=end_of_line
   task mover_set_transpose;
       input [WIDTH_AD-1:0] dst_addr;
       input [WIDTH_AD-1:0] src_addr;
       input [15:0] src_width;
       input [15:0] src_height;
       input [ 8:0] src_leng; // not AxLENG
   begin
       write_word_task(CSRA_COMMAND, {28'h0,COMMAND_TRANSPOSE[3:0]});
       write_word_task(CSRA_ACTIV_FUNC   , ACTIV_FUNC_BYPASS);
   end
   endtask

   //---------------------------------------------------------------------------
   task check_result_transpose;
       input [WIDTH_AD-1:0] dst_addr;
       input [WIDTH_AD-1:0] src_addr;
       input [15:0] src_width;
       input [15:0] src_height;
   begin
   end
   endtask

    //==========================================================================
    // func: 0=nop (bypass), 1=relu, 2=leaky-relu, 3=sigmoid, 4=tanh
    //                                             (not yet)  (not yet)
    // param: valid for leaky-relu
    //        floating-point = 1/(10**param)
    //        integer, fixed = 1/(2**param)
    task activation_set;
         input integer func;
         input integer param;
    begin
         write_word_task(CSRA_ACTIV_FUNC , func );
         write_word_task(CSRA_ACTIV_PARAM, param);
    end
    endtask

    task activation_get;
         output integer func;
         output integer param;
    begin
         read_word_task(CSRA_ACTIV_FUNC , func );
         read_word_task(CSRA_ACTIV_PARAM, param);
    end
    endtask

    //==========================================================================
    task profile_init;
         reg [31:0] dataW;
    begin
         dataW = 1<<31;
         write_word_task(CSRA_PROFILE_CTL, dataW);
    end
    endtask

    //---------------------------------------------------------------------------
    task profile_get;
      output [31:0] profile_cycles;
      output [31:0] profile_overflow; // residual overflow
      output [31:0] profile_cnt_rd;
      output [31:0] profile_cnt_wr;
      reg [31:0] data;
     begin
      data = 32'h1;
      write_word_task(CSRA_PROFILE_CTL, data);
      while (data[1:0]!=2'b0) read_word_task(CSRA_PROFILE_CTL, data);
      read_word_task(CSRA_PROFILE_CYCLES,profile_cycles );
      read_word_task(CSRA_PROFILE_RESIDUAL_OVERFLOW,profile_overflow );
      read_word_task(CSRA_PROFILE_CNT_RD,profile_cnt_rd );
      read_word_task(CSRA_PROFILE_CNT_WR,profile_cnt_wr );
    end
    endtask

    //---------------------------------------------------------------------------
    task profile_put;
      reg [31:0] profile_cycles;
      reg [31:0] profile_overflow;
      reg [31:0] profile_cnt_rd;
      reg [31:0] profile_cnt_wr;
     begin
      read_word_task(CSRA_PROFILE_CYCLES,profile_cycles);
      read_word_task(CSRA_PROFILE_RESIDUAL_OVERFLOW,profile_overflow);
      read_word_task(CSRA_PROFILE_CNT_RD,profile_cnt_rd);
      read_word_task(CSRA_PROFILE_CNT_WR,profile_cnt_wr);
      $display("PROFILE_CYCLES(x10): %-d", profile_cycles  );
      $display("PROFILE_OVERFLOW   : %-d", profile_overflow);
      $display("PROFILE_CNT_RD     : %-d", profile_cnt_rd  );
      $display("PROFILE_CNT_WR     : %-d", profile_cnt_wr  );
    end
    endtask
    //==========================================================================
