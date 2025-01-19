
   localparam CSRA_VERSION       = (ADDR_BASE_CONV+'h00)
            , CSRA_CONTROL       = (ADDR_BASE_CONV+'h10)
            , CSRA_CONFIG        = (ADDR_BASE_CONV+'h14)
            , CSRA_CONFIG_FIFO   = (ADDR_BASE_CONV+'h18)

            , CSRA_KNL_ADDR_LOW  = (ADDR_BASE_CONV+'h20)
            , CSRA_KNL_ADDR_HIGH = (ADDR_BASE_CONV+'h24)
            , CSRA_KNL_CFG       = (ADDR_BASE_CONV+'h28)
            , CSRA_KNL_BURST     = (ADDR_BASE_CONV+'h30)

            , CSRA_FTU_ADDR_LOW  = (ADDR_BASE_CONV+'h40)
            , CSRA_FTU_ADDR_HIGH = (ADDR_BASE_CONV+'h44)
            , CSRA_FTU_CFG_SIZE  = (ADDR_BASE_CONV+'h48)
            , CSRA_FTU_CFG_KNL   = (ADDR_BASE_CONV+'h4C)
            , CSRA_FTU_ITEMS     = (ADDR_BASE_CONV+'h50)
            , CSRA_FTU_BURST     = (ADDR_BASE_CONV+'h54)

            , CSRA_CHN_ADDR_LOW  = (ADDR_BASE_CONV+'h60)
            , CSRA_CHN_ADDR_HIGH = (ADDR_BASE_CONV+'h64)
            , CSRA_CHN_CFG_SIZE  = (ADDR_BASE_CONV+'h68)
            , CSRA_CHN_ITEMS     = (ADDR_BASE_CONV+'h6C)
            , CSRA_CHN_BURST     = (ADDR_BASE_CONV+'h70)

            , CSRA_RST_ADDR_LOW  = (ADDR_BASE_CONV+'h80)
            , CSRA_RST_ADDR_HIGH = (ADDR_BASE_CONV+'h84)
            , CSRA_RST_CFG_SIZE  = (ADDR_BASE_CONV+'h88)
            , CSRA_RST_ITEMS     = (ADDR_BASE_CONV+'h8C)
            , CSRA_RST_BURST     = (ADDR_BASE_CONV+'h90)

            , CSRA_MAC_BIAS       = (ADDR_BASE_CONV+'hA0)
            , CSRA_MAC_ACTIV_FUNC = (ADDR_BASE_CONV+'hA4)
            , CSRA_MAC_ACTIV_PARAM= (ADDR_BASE_CONV+'hA8)

            , CSRA_PROFILE_CTL     = (ADDR_BASE_CONV+'hB0)
            , CSRA_PROFILE_CYCLES  = (ADDR_BASE_CONV+'hB4) // num of MAC operations
            , CSRA_PROFILE_MAC_NUM = (ADDR_BASE_CONV+'hB8) // num of MAC operations
            , CSRA_PROFILE_MAC_OVR = (ADDR_BASE_CONV+'hBC) // num of overflow while MAC operations
            , CSRA_PROFILE_CHN_OVR = (ADDR_BASE_CONV+'hC0) // num of overflow while adding channels
            , CSRA_PROFILE_BIA_OVR = (ADDR_BASE_CONV+'hC4) // num of overflow while adding bias
            , CSRA_PROFILE_ACT_OVR = (ADDR_BASE_CONV+'hC8) // num of overflow while activation
            , CSRA_PROFILE_CNT_RD  = (ADDR_BASE_CONV+'hCC) // num of read
            , CSRA_PROFILE_CNT_WR  = (ADDR_BASE_CONV+'hD0) // num of write
            ;
   //---------------------------------------------------------------------------
   task csr_test;
       reg [31:0] data;
   begin
     read_word_task(CSRA_VERSION        ,data); $display("%m %s A:0x%08X D:0x%08X","VERSION        ",CSRA_VERSION      ,data);
     read_word_task(CSRA_CONTROL        ,data); $display("%m %s A:0x%08X D:0x%08X","CONTROL        ",CSRA_CONTROL      ,data);
     read_word_task(CSRA_CONFIG         ,data); $display("%m %s A:0x%08X D:0x%08X","CONFIG         ",CSRA_CONFIG       ,data);
     read_word_task(CSRA_CONFIG_FIFO    ,data); $display("%m %s A:0x%08X D:0x%08X","CONFIG_FIFO    ",CSRA_CONFIG_FIFO  ,data);
     read_word_task(CSRA_KNL_ADDR_LOW   ,data); $display("%m %s A:0x%08X D:0x%08X","KNL_ADDR_LOW   ",CSRA_KNL_ADDR_LOW ,data);
     read_word_task(CSRA_KNL_ADDR_HIGH  ,data); $display("%m %s A:0x%08X D:0x%08X","KNL_ADDR_HIGH  ",CSRA_KNL_ADDR_HIGH,data);
     read_word_task(CSRA_KNL_CFG        ,data); $display("%m %s A:0x%08X D:0x%08X","KNL_CFG        ",CSRA_KNL_CFG      ,data);
     read_word_task(CSRA_KNL_BURST      ,data); $display("%m %s A:0x%08X D:0x%08X","KNL_BURST      ",CSRA_KNL_BURST    ,data);
     read_word_task(CSRA_FTU_ADDR_LOW   ,data); $display("%m %s A:0x%08X D:0x%08X","FTU_ADDR_LOW   ",CSRA_FTU_ADDR_LOW ,data);
     read_word_task(CSRA_FTU_ADDR_HIGH  ,data); $display("%m %s A:0x%08X D:0x%08X","FTU_ADDR_HIGH  ",CSRA_FTU_ADDR_HIGH,data);
     read_word_task(CSRA_FTU_CFG_SIZE   ,data); $display("%m %s A:0x%08X D:0x%08X","FTU_CFG_SIZE   ",CSRA_FTU_CFG_SIZE ,data);
     read_word_task(CSRA_FTU_CFG_KNL    ,data); $display("%m %s A:0x%08X D:0x%08X","FTU_CFG_KNL    ",CSRA_FTU_CFG_KNL  ,data);
     read_word_task(CSRA_FTU_ITEMS      ,data); $display("%m %s A:0x%08X D:0x%08X","FTU_ITEMS      ",CSRA_FTU_ITEMS    ,data);
     read_word_task(CSRA_FTU_BURST      ,data); $display("%m %s A:0x%08X D:0x%08X","FTU_BURST      ",CSRA_FTU_BURST    ,data);
     read_word_task(CSRA_CHN_ADDR_LOW   ,data); $display("%m %s A:0x%08X D:0x%08X","CHN_ADDR_LOW   ",CSRA_CHN_ADDR_LOW ,data);
     read_word_task(CSRA_CHN_ADDR_HIGH  ,data); $display("%m %s A:0x%08X D:0x%08X","CHN_ADDR_HIGH  ",CSRA_CHN_ADDR_HIGH,data);
     read_word_task(CSRA_CHN_CFG_SIZE   ,data); $display("%m %s A:0x%08X D:0x%08X","CHN_CFG_SIZE   ",CSRA_CHN_CFG_SIZE ,data);
     read_word_task(CSRA_CHN_ITEMS      ,data); $display("%m %s A:0x%08X D:0x%08X","CHN_ITEMS      ",CSRA_CHN_ITEMS    ,data);
     read_word_task(CSRA_CHN_BURST      ,data); $display("%m %s A:0x%08X D:0x%08X","CHN_BURST      ",CSRA_CHN_BURST    ,data);
     read_word_task(CSRA_RST_ADDR_LOW   ,data); $display("%m %s A:0x%08X D:0x%08X","RST_ADDR_LOW   ",CSRA_RST_ADDR_LOW ,data);
     read_word_task(CSRA_RST_ADDR_HIGH  ,data); $display("%m %s A:0x%08X D:0x%08X","RST_ADDR_HIGH  ",CSRA_RST_ADDR_HIGH,data);
     read_word_task(CSRA_RST_CFG_SIZE   ,data); $display("%m %s A:0x%08X D:0x%08X","RST_CFG_SIZE   ",CSRA_RST_CFG_SIZE ,data);
     read_word_task(CSRA_RST_ITEMS      ,data); $display("%m %s A:0x%08X D:0x%08X","RST_ITEMS      ",CSRA_RST_ITEMS    ,data);
     read_word_task(CSRA_RST_BURST      ,data); $display("%m %s A:0x%08X D:0x%08X","RST_BURST      ",CSRA_RST_BURST    ,data);
     read_word_task(CSRA_MAC_BIAS       ,data); $display("%m %s A:0x%08X D:0x%08X","MAC_BIAS       ",CSRA_MAC_BIAS     ,data);
     read_word_task(CSRA_MAC_ACTIV_FUNC ,data); $display("%m %s A:0x%08X D:0x%08X","MAC_ACTIV_FUNC ",CSRA_MAC_ACTIV_FUNC  ,data);
     read_word_task(CSRA_MAC_ACTIV_PARAM,data); $display("%m %s A:0x%08X D:0x%08X","MAC_ACTIV_PARAM",CSRA_MAC_ACTIV_PARAM ,data);
     read_word_task(CSRA_PROFILE_CTL    ,data); $display("%m %s A:0x%08X D:0x%08X","PROFILE_CTL    ",CSRA_PROFILE_CTL    ,data);
     read_word_task(CSRA_PROFILE_CYCLES ,data); $display("%m %s A:0x%08X D:0x%08X","PROFILE_CYCLES ",CSRA_PROFILE_CYCLES,data);
     read_word_task(CSRA_PROFILE_MAC_NUM,data); $display("%m %s A:0x%08X D:0x%08X","PROFILE_MAC_NUM",CSRA_PROFILE_MAC_NUM,data);
     read_word_task(CSRA_PROFILE_MAC_OVR,data); $display("%m %s A:0x%08X D:0x%08X","PROFILE_MAC_OVR",CSRA_PROFILE_MAC_OVR,data);
     read_word_task(CSRA_PROFILE_CHN_OVR,data); $display("%m %s A:0x%08X D:0x%08X","PROFILE_CHN_OVR",CSRA_PROFILE_CHN_OVR,data);
     read_word_task(CSRA_PROFILE_BIA_OVR,data); $display("%m %s A:0x%08X D:0x%08X","PROFILE_BIA_OVR",CSRA_PROFILE_BIA_OVR,data);
     read_word_task(CSRA_PROFILE_ACT_OVR,data); $display("%m %s A:0x%08X D:0x%08X","PROFILE_ACT_OVR",CSRA_PROFILE_ACT_OVR,data);
     read_word_task(CSRA_PROFILE_CNT_RD ,data); $display("%m %s A:0x%08X D:0x%08X","PROFILE_CNT_RD ",CSRA_PROFILE_CNT_RD,data);
     read_word_task(CSRA_PROFILE_CNT_WR ,data); $display("%m %s A:0x%08X D:0x%08X","PROFILE_CNT_WR ",CSRA_PROFILE_CNT_WR,data);
   end
   endtask

   //===========================================================================
   task conv_init;
       reg [31:0] dataW, dataR;
   begin
        read_word_task(CSRA_CONTROL,dataR);
        dataW = dataR | (1'b1<<31); // auto clean automatically
        write_word_task(CSRA_CONTROL,dataW);
        read_word_task(CSRA_CONTROL,dataR);
        if (!(dataR&(1<<30))) $display("%0t %m conv_ready should be 1.", $time);
        if   (dataR&(1<<31))  $display("%0t %m conv_init should be 0.", $time);
   end
   endtask

   //---------------------------------------------------------------------------
   task conv_get_config;
       output integer Q;
       output integer N;
       output integer kernel_fifo_dpeth;
       output integer feature_fifo_dpeth;
       output integer channel_fifo_dpeth;
       output integer result_fifo_dpeth;
       reg [31:0] dataR;
   begin
       read_word_task(CSRA_CONFIG,dataR);
       N = dataR[7:0];
       Q = dataR[15:8];
       read_word_task(CSRA_CONFIG_FIFO,dataR);
       kernel_fifo_dpeth  = dataR[ 7: 0];
       feature_fifo_dpeth = dataR[15: 8];
       channel_fifo_dpeth = dataR[23:16];
       result_fifo_dpeth  = dataR[31:24];
   end
   endtask

   //---------------------------------------------------------------------------
   task conv_go_wait;
       input ie;
       input blocking;
       reg [31:0] dataW, dataR;
   begin
        read_word_task(CSRA_CONTROL,dataR);
        dataW = dataR | 'b1111 | (ie<<28);
        write_word_task(CSRA_CONTROL,dataW);
        if (blocking) begin
            dataR = 'b1111; // go clean automatically
            while (dataR[3:0]!='b0000) begin
                read_word_task(CSRA_CONTROL,dataR);
            end
        end
        read_word_task(CSRA_CONTROL,dataR);
        if ((dataR[11:8]!=4'b0)||(dataR[3:0]!=4'b0))
            $display("%0t %m go-done error.", $time);
   end
   endtask

   //---------------------------------------------------------------------------
   task conv_clear_interrupt;
       reg [31:0] dataW, dataR;
   begin
        read_word_task(CSRA_CONTROL,dataR);
        dataW = dataR & ~(2'b11<<28);
        write_word_task(CSRA_CONTROL,dataW);
   end
   endtask

   //---------------------------------------------------------------------------
   // Note:
   // * result_width/height is calculated by using kernel_width/height, feature_width/height
   //                                      stride, padding.
   // * channel_width/height is the same as result_width/height.
   // * kerenel_num is calculated by using result_width/height;
   task conv_set;
       input integer kernel_addr;
       input integer kernel_width;
       input integer kernel_height;
       input integer kernel_leng; // not AxLENG format
       input integer feature_addr;
       input integer feature_width;
       input integer feature_height;
       input integer feature_stride;
       input integer feature_padding_pre;
       input integer feature_padding_post;
       input integer feature_leng; // not AxLENG format
       input integer channel_addr;
       input integer channel_leng; // 0 if not used (not AxLENG format)
       input integer result_addr;
       input integer result_leng; // not AxLENG format
       integer kernel_num;
       integer channel_width; // 0 if not used
       integer channel_height; // 0 if not used
       integer result_width;
       integer result_height;
   begin
       result_width = func_result_size( kernel_width, feature_width, feature_stride
                                      , feature_padding_pre, feature_padding_post);
       result_height = func_result_size( kernel_height, feature_height, feature_stride
                                       , feature_padding_pre, feature_padding_post);

       kernel_num = result_width*result_height;
       kernel_set( kernel_addr
                 , kernel_width
                 , kernel_height
                 , kernel_num
                 , kernel_leng);
       kernel_fill(kernel_addr, kernel_width, kernel_height);

       feature_set( feature_addr
                  , feature_width
                  , feature_height
                  , feature_stride
                  , feature_padding_pre
                  , feature_padding_post
                  , feature_leng);
       feature_fill(feature_addr, feature_width, feature_height);

       result_set(result_addr, result_width, result_height, result_leng);
       result_clear(result_addr, result_width, result_height);

       if (channel_leng==0) begin
           channel_width = 0;
           channel_height = 0;
       end else begin
           channel_width  = result_width;
           channel_height = result_height;
       end
       channel_set(channel_addr, channel_width, channel_height, channel_leng);
    end
    endtask

localparam MAX_KERNEL_SIZE =15
         , MAX_FEATURE_SIZE=640;
   //---------------------------------------------------------------------------
   task check_result;
       input integer kernel_addr;
       input integer kernel_width;
       input integer kernel_height;
       input integer feature_addr;
       input integer feature_width;
       input integer feature_height;
       input integer feature_stride;
       input integer feature_padding_pre;
       input integer feature_padding_post;
       input integer result_addr ;
       input integer result_width ;
       input integer result_height;
       input integer channel_addr  ; // starting address
       input integer channel_width ; // num of items
       input integer channel_height;
       input [DATA_WIDTH-1:0] bias;
       input integer          activ_func;
       input [DATA_WIDTH-1:0] activ_param;
       reg [DATA_WIDTH-1:0] mem_kernel [MAX_KERNEL_SIZE*MAX_KERNEL_SIZE-1:0];
       reg [DATA_WIDTH-1:0] mem_feature[MAX_FEATURE_SIZE*MAX_FEATURE_SIZE-1:0];
       reg [DATA_WIDTH-1:0] mem_result [MAX_FEATURE_SIZE*MAX_FEATURE_SIZE-1:0];
       reg [DATA_WIDTH-1:0] mem_channel[MAX_FEATURE_SIZE*MAX_FEATURE_SIZE-1:0];
       reg [DATA_WIDTH-1:0] mem_expect [MAX_FEATURE_SIZE*MAX_FEATURE_SIZE-1:0];
       reg [WIDTH_AD-1:0] addr;
       reg [WIDTH_DA-1:0] data;
       reg [DATA_WIDTH-1:0] sum;
       reg [DATA_WIDTH-1:0] result_value;
       integer ida, idb;
       integer a, b, x, y, z, k;
       integer yid, xid, bid, aid;
       integer error;
   begin
       if (kernel_width[0]==1'b0) $display("%0t %m ERROR kernel width should be odd.", $time);
       if (kernel_height[0]==1'b0) $display("%0t %m ERROR kernel width should be odd.", $time);
       if (feature_stride==0) $display("%0t %m ERROR stride should be positive.", $time);
       if (feature_padding_pre>kernel_width/2) $display("%0t %m ERROR padding.", $time);
       if (feature_padding_post>kernel_height/2) $display("%0t %m ERROR padding.", $time);
       if (result_width!= func_result_size(kernel_width
                                          ,feature_width
                                          ,feature_stride
                                          ,feature_padding_pre
                                          ,feature_padding_post))
           $display("%0t %m ERROR result width.", $time);
       if (result_height!= func_result_size(kernel_height
                                           ,feature_height
                                           ,feature_stride
                                           ,feature_padding_pre
                                           ,feature_padding_post))
           $display("%0t %m ERROR result height.", $time);
       if (kernel_width>MAX_KERNEL_SIZE) $display("%0t %m ERROR kernel size exceed.", $time);
       if (feature_width>MAX_FEATURE_SIZE) $display("%0t %m ERROR feature size exceed.", $time);
       if (result_width>MAX_FEATURE_SIZE) $display("%0t %m ERROR result size exceed.", $time);
       addr = kernel_addr;
       for (ida=0; ida<kernel_width*kernel_height; ida=ida+(WIDTH_DA/DATA_WIDTH)) begin
            data = top.u_mem.read_word(addr);
            for (idb=0; idb<(WIDTH_DA/DATA_WIDTH); idb=idb+1) begin
                 mem_kernel[ida+idb] = data[DATA_WIDTH*idb +: DATA_WIDTH];
            end
            addr = addr + WIDTH_DS;
       end
       addr = feature_addr;
       for (ida=0; ida<feature_width*feature_height; ida=ida+(WIDTH_DA/DATA_WIDTH)) begin
            data = top.u_mem.read_word(addr);
            for (idb=0; idb<(WIDTH_DA/DATA_WIDTH); idb=idb+1) begin
                 mem_feature[ida+idb] = data[DATA_WIDTH*idb +: DATA_WIDTH];
            end
            addr = addr + WIDTH_DS;
       end
       if ((channel_width!=0)&&(channel_height!=0)) begin
           addr = channel_addr;
           for (ida=0; ida<channel_width*channel_height; ida=ida+(WIDTH_DA/DATA_WIDTH)) begin
                data = top.u_mem.read_word(addr);
                for (idb=0; idb<(WIDTH_DA/DATA_WIDTH); idb=idb+1) begin
                     mem_channel[ida+idb] = data[DATA_WIDTH*idb +: DATA_WIDTH];
                end
                addr = addr + WIDTH_DS;
           end
       end
       if ((feature_padding_pre==0)&&(feature_padding_post==0)) begin
           // convolution 2d
           //   a: intra-kernel row
           //   b: intra-kernel column
           //   x: inter-kernel row
           //   y: inter-kernel column
           //   z: result
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
           //  z = 0;
           //  for (y=0; y<(fheight-kheight); y=y+stride) {
           //       yid = y*fwidth;
           //       for (x=0; x<(fwidth-kwidth); x=x+strid) {
           //            k = 0;
           //            sum = bias;
           //            xid = yid + x;
           //            for (b=0; b<kheight; b=b+1) {
           //                 bid = xid + b*fwidth;
           //                 for (a=0; a<kwidth; a=a+1) {
           //                      aid = bid + a;
           //                      sum += kernel[k]*feature[aid];
           //                      k++;
           //                 } // for (a=0
           //            } // for (b=0
           //            result[z] = sum;
           //            z++;
           //       } // for (x=0
           //  } // for (y=0
           z = 0;
           for (y=0; y<=(feature_height-kernel_height); y=y+feature_stride) begin
                yid = y*feature_width; // row to index
                for (x=0; x<=(feature_width-kernel_width); x=x+feature_stride) begin
                     k = 0;
                     sum = mem_channel[z];
                     xid = yid + x; // col to index
                     for (b=0; b<kernel_height; b=b+1) begin
                          bid = xid + b*feature_width;
                          for (a=0; a<kernel_width; a=a+1) begin
                               aid = bid + a;
                               sum = func_mac(sum, mem_kernel[k], mem_feature[aid]);
                               k = k + 1;
                          end // for (a=0
                     end // for (b=0
                     mem_expect[z] = sum + bias;
                     z = z + 1;
                end // for (x=0
           end // for (y=0
       end else begin // if (feature_padding_pre==0
           z = 0;
           for (y=-feature_padding_pre; y<=(feature_height-kernel_height+feature_padding_post)
                                  ; y=y+feature_stride) begin
                yid = y*feature_width; // row to index
                for (x=-feature_padding_pre; x<=(feature_width-kernel_width+feature_padding_post)
                                       ; x=x+feature_stride) begin
                     k = 0;
                     sum = mem_channel[z];
                     xid = yid + x; // col to index
                     for (b=0; b<kernel_height; b=b+1) begin
                          bid = xid + b*feature_width;
                          for (a=0; a<kernel_width; a=a+1) begin
                               if (((y+b)<0)||((x+a)<0)||
                                   ((y+b)>=feature_height)||
                                   ((x+a)>=feature_width)) begin
                                   sum = func_mac(sum, mem_kernel[k], 0);
                               end else begin
                                   aid = bid + a;
                                   sum = func_mac(sum, mem_kernel[k], mem_feature[aid]);
                               end
                               k = k + 1;
                          end // for (a=0
                     end // for (b=0
                     mem_expect[z] = sum + bias;
                     z = z + 1;
                end // for (x=0
           end // for (y=0
       end  // if (feature_padding_pre==0
       error = 0;
       addr = result_addr;
       z = 0;
       for (ida=0; ida<result_width*result_height; ida=ida+(WIDTH_DA/DATA_WIDTH)) begin
            data = top.u_mem.read_word(addr);
            for (idb=0; (((ida*(WIDTH_DA/DATA_WIDTH))+idb)<(result_width*result_height))&&(idb<(WIDTH_DA/DATA_WIDTH)); idb=idb+1) begin
                 result_value = data[DATA_WIDTH*idb +: DATA_WIDTH];
                 mem_result[z] = result_value;
                 if (result_value!==mem_expect[ida+idb]) begin
                     error = error + 1;
                     $display("%m [%0dx%0d] V:0x%0X E:0x%0X.",
                               (ida+idb)/result_width, 
                               (ida+idb)%result_width, 
                               result_value, mem_expect[ida+idb]);
                 end
                 z = z + 1;
            end
            addr = addr + WIDTH_DS;
       end
       if (error==0) $display("%0t %m OK %0d.", $time, result_width*result_height);
       else          $display("%0t %m mis-match %0d out of %0d.", $time, error, result_width*result_height);
if ($value$plusargs("VERBOSE=%d", arg) && (arg>0)) begin
       // display
       $display("feature=%0dx%0d kernel=%0dx%0d stride=%0d", feature_width, feature_height, kernel_width, kernel_height, feature_stride);
       if (DATA_WIDTH==8) begin
          for (xid=0; xid<feature_width; xid=xid+1) $write("%s", " --");
          $write("      ");
          for (xid=0; xid<result_width; xid=xid+1) $write("%s", " --");
          $write("\n");
          for (yid=0; yid<feature_height; yid=yid+1) begin
              for (xid=0; xid<feature_width; xid=xid+1) begin
                   $write("|%02X", mem_feature[yid*feature_width+xid]);
                   if ((xid+1)==feature_width) $write("| ");
              end
              for (xid=0; (yid<result_height)&&(xid<result_width); xid=xid+1) begin
                   if (xid==0) $write("    ");
                   $write("|%02X", mem_result[yid*result_width+xid]);
                   if ((xid+1)==result_width) $write("| ");
              end
              if (yid==result_height) begin
                   if (xid==0) $write("    ");
                   for (xid=0; xid<result_width; xid=xid+1) $write("%s", " --");
              end
              for (xid=0; (error!=0)&&(yid<result_height)&&(xid<result_width); xid=xid+1) begin
                   if (xid==0) $write("    ");
                   $write("|%02X", mem_expect[yid*result_width+xid]);
                   if ((xid+1)==result_width) $write("| ");
              end
              if ((error!=0)&&(yid==result_height)) begin
                   if (xid==0) $write("    ");
                   for (xid=0; xid<result_width; xid=xid+1) $write("%s", " --");
              end
              $write("\n");
          end
          for (xid=0; xid<feature_width; xid=xid+1) $write("%s", " --------");
          $write("\n");
       end
       if (DATA_WIDTH==16) begin
          for (xid=0; xid<feature_width; xid=xid+1) $write("%s", " ----");
          $write("      ");
          for (xid=0; xid<result_width; xid=xid+1) $write("%s", " ----");
          $write("\n");
          for (yid=0; yid<feature_height; yid=yid+1) begin
              for (xid=0; xid<feature_width; xid=xid+1) begin
                   $write("|%04X", mem_feature[yid*feature_width+xid]);
                   if ((xid+1)==feature_width) $write("| ");
              end
              for (xid=0; (yid<result_height)&&(xid<result_width); xid=xid+1) begin
                   if (xid==0) $write("    ");
                   $write("|%04X", mem_result[yid*result_width+xid]);
                   if ((xid+1)==result_width) $write("| ");
              end
              if (yid==result_height) begin
                   if (xid==0) $write("    ");
                   for (xid=0; xid<result_width; xid=xid+1) $write("%s", " ----");
              end
              for (xid=0; (error!=0)&&(yid<result_height)&&(xid<result_width); xid=xid+1) begin
                   if (xid==0) $write("    ");
                   $write("|%04X", mem_expect[yid*result_width+xid]);
                   if ((xid+1)==result_width) $write("| ");
              end
              if ((error!=0)&&(yid==result_height)) begin
                   if (xid==0) $write("    ");
                   for (xid=0; xid<result_width; xid=xid+1) $write("%s", " ----");
              end
              $write("\n");
          end
          for (xid=0; xid<feature_width; xid=xid+1) $write("%s", " --------");
          $write("\n");
       end
       if (DATA_WIDTH==32) begin
          for (xid=0; xid<feature_width; xid=xid+1) $write("%s", " --------");
          $write("      ");
          for (xid=0; xid<result_width; xid=xid+1) $write("%s", " --------");
          $write("\n");
          for (yid=0; yid<feature_height; yid=yid+1) begin
              for (xid=0; xid<feature_width; xid=xid+1) begin
                   $write("|%08X", mem_feature[yid*feature_width+xid]);
                   if ((xid+1)==feature_width) $write("| ");
              end
              for (xid=0; (yid<result_height)&&(xid<result_width); xid=xid+1) begin
                   if (xid==0) $write("    ");
                   $write("|%08X", mem_result[yid*result_width+xid]);
                   if ((xid+1)==result_width) $write("| ");
              end
              if (yid==result_height) begin
                   if (xid==0) $write("    ");
                   for (xid=0; xid<result_width; xid=xid+1) $write("%s", " --------");
              end
              for (xid=0; (error!=0)&&(yid<result_height)&&(xid<result_width); xid=xid+1) begin
                   if (xid==0) $write("    ");
                   $write("|%08X", mem_expect[yid*result_width+xid]);
                   if ((xid+1)==result_width) $write("| ");
              end
              if ((error!=0)&&(yid==result_height)) begin
                   if (xid==0) $write("    ");
                   for (xid=0; xid<result_width; xid=xid+1) $write("%s", " --------");
              end
              $write("\n");
          end
          for (xid=0; xid<feature_width; xid=xid+1) $write("%s", " --------");
          $write("\n");
       end
end
   end
   endtask

   //===========================================================================
   task kernel_test;
       input integer addr;
       input integer width; // num of items
       input integer height;
       input integer num; // the number of kernels over a whole feature map
                          // if not known, set it to 0.
       input integer leng; // not AxLENG format
   begin
        // initialize kernel
        kernel_fill(addr, width, height);
        kernel_set( addr // input [31:0] addr_mem; // space for filter(kernel)
                  , width
                  , height
                  , num
                  , leng // input [ 7:0] leng; // burst length (not AxLENG format)
                  );
        kernel_go_wait(1);
   end
   endtask

   //---------------------------------------------------------------------------
   task kernel_go_wait;
       input blocking;
       reg [31:0] dataW, dataR;
   begin
        read_word_task(CSRA_CONTROL,dataR);
        dataW = dataR | 'b1; // kernel go
        write_word_task(CSRA_CONTROL,dataW);
        if (blocking) begin
            dataR = 'h1; // kernel_go clean automatically
            while (dataR[0]==1'b1) begin
                read_word_task(CSRA_CONTROL,dataR);
            end
        end
   end
   endtask

   //---------------------------------------------------------------------------
   task kernel_fill;
       input integer addr;
       input integer width;
       input integer height;
       integer Q, N, bytes;
       integer w, x, y, z;
       integer idx;
       reg [31:0] dataW;
       shortreal sf;
   begin
       conv_get_config(Q,N,w,x,y,z);
       if (Q!=0) $display("%t %m ERROR Q %d.", $time, Q);
        bytes = N/8;
        // initialize feature
        for (idx=0; idx<(width*height); idx=idx+1) begin
`ifdef xxyy
             {dataWB[3],dataWB[2],dataWB[1],dataWB[0]} = (idx+1)<<Q;
             write_task(3, addr+(idx*bytes), bytes, 1, 1); // through BUS
`else
           //if (DATA_TYPE=="FLOATING_POINT") begin
           //    sf = idx+1;
           //    dataW = $shortrealtobits(sf);
           //end else dataW = (idx+1)<<Q;
             dataW = (idx+1)<<Q;
             top.u_mem.write(addr+(idx*bytes), dataW, bytes); // direct call task
`endif
        end
   end
   endtask

   //---------------------------------------------------------------------------
   task kernel_set;
        input [31:0] addr_mem; // space for filter(kernel)
        input [ 3:0] width; // width (num of items)
        input [ 3:0] height;
        input [15:0] num; // need to know feature_width/height
        input [ 7:0] leng; // burst length (not AxLENG format)
        reg [31:0] items;
        reg [31:0] data;
   begin
        data = addr_mem;
        write_word_task(CSRA_KNL_ADDR_LOW ,data);
        write_word_task(CSRA_KNL_ADDR_HIGH,32'h0);
        items = width*height;
        data = {num,items[7:0],height,width};
        write_word_task(CSRA_KNL_CFG  ,data);
        data = (leng==0) ? 0 : leng-1; // mind AxLENG format
        write_word_task(CSRA_KNL_BURST,data);
   end
   endtask

   //===========================================================================
   task feature_test;
       input integer addr;
       input integer width;
       input integer height;
       input integer stride;
       input integer padding_pre;
       input integer padding_post;
       input integer leng; // not AxLENG format
       integer kernel_width, kernel_height;
       integer result_width, result_height, result_leng;
       integer Q, N, bytes;
       integer kl, fl, cl, rl;
       reg [31:0] dataW, dataR;
   begin
        // initialize feature
        feature_fill(addr, width, height);
        feature_set( addr // input [31:0] addr_mem; // space for filter(kernel)
                   , width // input [ 3:0] size; // width (num of items)
                   , height
                   , stride
                   , padding_pre
                   , padding_post
                   , leng // input [ 7:0] leng; // burst length (not AxLENG format)
                   );
        read_word_task(CSRA_KNL_CFG,dataR);
        conv_get_config(Q,N,kl,fl,cl,rl);
        bytes = N/8;
        kernel_width = dataR[3:0];
        kernel_height = dataR[7:4];
        result_width = func_result_size(kernel_width, width, stride, padding_pre, padding_post);
        result_height = func_result_size(kernel_height, height, stride, padding_pre, padding_post);
        result_leng = kernel_width;
        if (result_leng>rl) result_leng = rl;
        result_set( addr+((width*height*bytes+63)/64)*64
                  , result_width
                  , result_height
                  , result_leng  // burst length (not AxLENG format)
                  );
        feature_result_go_wait(1);
   end
   endtask

   //---------------------------------------------------------------------------
   task feature_result_go_wait;
       input blocking;
       reg [31:0] dataW, dataR;
   begin
        read_word_task(CSRA_CONTROL,dataR);
        dataW = dataR | 'b1010; // result/feature go
        write_word_task(CSRA_CONTROL,dataW);
        if (blocking) begin
            dataR = 'b1010; // feature_go clean automatically
            while (dataR[1]) begin
                read_word_task(CSRA_CONTROL,dataR);
            end
        end
   end
   endtask

   //---------------------------------------------------------------------------
   task feature_fill;
       input integer addr;
       input integer width;
       input integer height;
       integer Q, N, bytes;
       integer w, x, y, z;
       integer idx;
       reg [31:0] dataW;
   begin
       conv_get_config(Q,N,w,x,y,z);
       if (Q!=0) $display("%t %m ERROR Q %d.", $time, Q);
        bytes = N/8;
        // initialize feature
        for (idx=0; idx<(width*height); idx=idx+1) begin
`ifdef xxyy
             {dataWB[3],dataWB[2],dataWB[1],dataWB[0]} = (idx+1)<<Q;
             write_task(3, addr+(idx*bytes), bytes, 1, 1); // through BUS
`else
             dataW = (idx+1)<<Q;
             top.u_mem.write(addr+(idx*bytes), dataW, bytes); // direct call task
`endif
        end
   end
   endtask

   //---------------------------------------------------------------------------
   task feature_set;
        input [31:0] addr_mem; // space for filter(feature)
        input [15:0] width; // width (num of items)
        input [15:0] height; // width (num of items)
        input [ 3:0] stride; // width (num of items)
        input [ 3:0] padding_pre; // width (num of items)
        input [ 3:0] padding_post; // width (num of items)
        input [ 7:0] leng; // burst length (not AxLENG format)
        reg [31:0] data;
   begin
        data = addr_mem;
        write_word_task(CSRA_FTU_ADDR_LOW ,data);
        write_word_task(CSRA_FTU_ADDR_HIGH,32'h0);
        write_word_task(CSRA_FTU_CFG_SIZE,{height,width});
        data = {16'h0,padding_post,padding_pre,4'h0,stride};
        write_word_task(CSRA_FTU_CFG_KNL,data);
        write_word_task(CSRA_FTU_ITEMS,width*height);
        if (leng<=0) leng = 1; // make AxLENG format
        write_word_task(CSRA_FTU_BURST,leng-1); // mind AxLENG format
   end
   endtask

   //===========================================================================
   task channel_set;
        input [31:0] addr_mem; // space for filter(feature)
        input [15:0] width; // width (num of items)
        input [15:0] height;
        input [ 7:0] leng; // burst length (not AxLENG format)
        reg [31:0] data;
   begin
        data = addr_mem;
        write_word_task(CSRA_CHN_ADDR_LOW ,data);
        write_word_task(CSRA_CHN_ADDR_HIGH,32'h0);
        write_word_task(CSRA_CHN_CFG_SIZE,{height,width});
        write_word_task(CSRA_CHN_ITEMS,width*height);
        if (leng<=0) leng = 1; // make AxLENG format
        write_word_task(CSRA_CHN_BURST,leng-1); // mind AxLENG format
   end
   endtask

   //---------------------------------------------------------------------------
   task channel_clear;
       input integer addr;
       input integer width;
       input integer height;
       integer Q, N, bytes;
       integer w,x,y,z;
       integer idx, idy;
       reg [31:0] dataW;
   begin
        conv_get_config(Q,N,w,x,y,z);
        bytes = N/8;
        // clear result
        for (idy=0; idy<bytes; idy=idy+1) dataWB[idy] = 0;
        dataW = 0;
        for (idx=0; idx<(width*height); idx=idx+1) begin
`ifdef xxyy
             write_task(1, addr+(idx*bytes), bytes, 1, 1); // through BUS
`else
             top.u_mem.write(addr+(idx*bytes), dataW, bytes); // direct call task
`endif
        end
   end
   endtask

   //===========================================================================
   function integer func_result_size;
        input integer kernel_size;
        input integer feature_size;
        input integer stride;
        input integer padding_pre;
        input integer padding_post;
   begin
        func_result_size = (((feature_size-kernel_size+(padding_pre+padding_post))/stride)+1);
   end
   endfunction

   //---------------------------------------------------------------------------
   task result_clear;
       input integer addr;
       input integer width;
       input integer height;
       integer Q, N, bytes;
       integer w,x,y,z;
       integer idx, idy;
       reg [31:0] dataW;
   begin
        conv_get_config(Q,N,w,x,y,z);
        bytes = N/8;
        // clear result
        for (idy=0; idy<bytes; idy=idy+1) dataWB[idy] = 0;
        dataW = 0;
        for (idx=0; idx<(width*height); idx=idx+1) begin
`ifdef xxyy
             write_task(1, addr+(idx*bytes), bytes, 1, 1); // through BUS
`else
             top.u_mem.write(addr+(idx*bytes), dataW, bytes); // direct call task
`endif
        end
   end
   endtask

   //---------------------------------------------------------------------------
   task result_set;
        input [31:0] addr_mem; // space for filter(feature)
        input [15:0] width; // width (num of items)
        input [15:0] height;
        input [ 7:0] leng; // burst length (not AxLENG format)
        reg [31:0] data;
   begin
        data = addr_mem;
        write_word_task(CSRA_RST_ADDR_LOW ,data);
        write_word_task(CSRA_RST_ADDR_HIGH,32'h0);
        write_word_task(CSRA_RST_CFG_SIZE,{height,width});
        write_word_task(CSRA_RST_ITEMS,width*height);
        if (leng<=0) leng = 1; // make AxLENG format
        write_word_task(CSRA_RST_BURST,leng-1); // mind AxLENG format
   end
   endtask

   //===========================================================================
    // It performs multiplication and accmulation and then returns resultant and overflow.
    // It maintains full-precision while multiplication and accumulation.
    // It returns maximum value when overflw occurs.
    localparam MAX_POS={1'b0,{DATA_WIDTH-1{1'b1}}}; // max positive
    localparam MAX_NEG={1'b1,{DATA_WIDTH-1{1'b0}}}; // max negative
    function [DATA_WIDTH-1:0] func_mac;
        input  signed [DATA_WIDTH-1:0] S;
        input  signed [DATA_WIDTH-1:0] A;
        input  signed [DATA_WIDTH-1:0] B;
        reg signed [DATA_WIDTH*2-1:0]  mul;
        reg signed [DATA_WIDTH*2-1:0]  sum;
        reg ovr;
    begin
        mul = A*B;
        sum = S + mul;
        if ((S>0)&&(mul>0)&&(sum<0)) begin
            ovr = 1'b1;
            func_mac = MAX_POS;
        end else if ((S<0)&&(mul<0)&&(sum>0)) begin
            ovr = 1'b1;
            func_mac = MAX_NEG;
        end else begin
            if (sum>$signed(MAX_POS)) begin
                ovr = 1'b1;
                func_mac = MAX_POS;
            end else if (sum<$signed(MAX_NEG)) begin
                ovr = 1'b1;
                func_mac = MAX_NEG;
            end else begin
                ovr = 1'b0;
                func_mac = sum[DATA_WIDTH-1:0];
            end
        end
    end
    endfunction

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
      output [31:0] profile_cycles ;
      output [31:0] profile_mac_num;
      output [31:0] profile_mac_ovr;
      output [31:0] profile_chn_ovr;
      output [31:0] profile_bia_ovr;
      output [31:0] profile_act_ovr;
      output [31:0] profile_cnt_rd ;
      output [31:0] profile_cnt_wr ;
      reg    [31:0] dataW, dataR;
     begin
      dataW = 32'h1; // snapshot
      write_word_task(CSRA_PROFILE_CTL, dataW);
      dataR = dataW;
      while (dataR[1:0]!=2'b00) read_word_task(CSRA_PROFILE_CTL, dataR);
      read_word_task(CSRA_PROFILE_CYCLES ,profile_cycles );
      read_word_task(CSRA_PROFILE_MAC_NUM,profile_mac_num);
      read_word_task(CSRA_PROFILE_MAC_OVR,profile_mac_ovr);
      read_word_task(CSRA_PROFILE_CHN_OVR,profile_chn_ovr);
      read_word_task(CSRA_PROFILE_BIA_OVR,profile_bia_ovr);
      read_word_task(CSRA_PROFILE_ACT_OVR,profile_act_ovr);
      read_word_task(CSRA_PROFILE_CNT_RD ,profile_cnt_rd );
      read_word_task(CSRA_PROFILE_CNT_WR ,profile_cnt_wr );
    end
    endtask

    //---------------------------------------------------------------------------
    task profile_put;
      reg [31:0] profile_cycles;
      reg [31:0] profile_mac_num;
      reg [31:0] profile_mac_ovr;
      reg [31:0] profile_bia_ovr;
      reg [31:0] profile_act_ovr;
      reg [31:0] profile_cnt_rd ;
      reg [31:0] profile_cnt_wr ;
     begin
      read_word_task(CSRA_PROFILE_CYCLES ,profile_cycles);
      read_word_task(CSRA_PROFILE_MAC_NUM,profile_mac_num);
      read_word_task(CSRA_PROFILE_MAC_OVR,profile_mac_ovr);
      read_word_task(CSRA_PROFILE_BIA_OVR,profile_bia_ovr);
      read_word_task(CSRA_PROFILE_ACT_OVR,profile_act_ovr);
      read_word_task(CSRA_PROFILE_CNT_RD ,profile_cnt_rd );
      read_word_task(CSRA_PROFILE_CNT_WR ,profile_cnt_wr );
      $display("PROFILE_CYCLES(x10): %-d", profile_cycles);
      $display("PROFILE_MAC_NUM    : %-d", profile_mac_num);
      $display("PROFILE_MAC_OVR    : %-d", profile_mac_ovr);
      $display("PROFILE_BIA_OVR    : %-d", profile_bia_ovr);
      $display("PROFILE_ACT_OVR    : %-d", profile_act_ovr);
      $display("PROFILE_CNT_RD     : %-d", profile_cnt_rd );
      $display("PROFILE_CNT_WR     : %-d", profile_cnt_wr );
    end
    endtask

   //===========================================================================
