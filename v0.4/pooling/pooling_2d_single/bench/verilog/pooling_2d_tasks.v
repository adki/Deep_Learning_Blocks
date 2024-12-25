
   localparam CSRA_VERSION       = (ADDR_BASE_POOL+'h00)
            , CSRA_CONTROL       = (ADDR_BASE_POOL+'h10)
            , CSRA_CONFIG        = (ADDR_BASE_POOL+'h14)
            , CSRA_CONFIG_FIFO   = (ADDR_BASE_POOL+'h18)

            , CSRA_COMMAND       = (ADDR_BASE_POOL+'h20)
            , CSRA_KNL_CFG       = (ADDR_BASE_POOL+'h24)

            , CSRA_FTU_ADDR_LOW  = (ADDR_BASE_POOL+'h30)
            , CSRA_FTU_ADDR_HIGH = (ADDR_BASE_POOL+'h34)
            , CSRA_FTU_CFG_SIZE  = (ADDR_BASE_POOL+'h38)
            , CSRA_FTU_CFG_KNL   = (ADDR_BASE_POOL+'h3C)
            , CSRA_FTU_ITEMS     = (ADDR_BASE_POOL+'h40)
            , CSRA_FTU_BURST     = (ADDR_BASE_POOL+'h44)
            , CSRA_FTU_CHANNEL   = (ADDR_BASE_POOL+'h48)

            , CSRA_RST_ADDR_LOW  = (ADDR_BASE_POOL+'h50)
            , CSRA_RST_ADDR_HIGH = (ADDR_BASE_POOL+'h54)
            , CSRA_RST_CFG_SIZE  = (ADDR_BASE_POOL+'h58)
            , CSRA_RST_ITEMS     = (ADDR_BASE_POOL+'h5C)
            , CSRA_RST_BURST     = (ADDR_BASE_POOL+'h60)

            , CSRA_PROFILE_CTL   = (ADDR_BASE_POOL+'h70)
            , CSRA_PROFILE_CYCLES= (ADDR_BASE_POOL+'h74)
            , CSRA_PROFILE_CNT_RD= (ADDR_BASE_POOL+'h78)
            , CSRA_PROFILE_CNT_WR= (ADDR_BASE_POOL+'h7C)
            ;
   //---------------------------------------------------------------------------
   task csr_test;
       reg [31:0] data;
   begin
     read_word_task(CSRA_VERSION      ,data); $display("%m %s A:0x%08X D:0x%08X","VERSION      ",CSRA_VERSION      ,data);
     read_word_task(CSRA_CONTROL      ,data); $display("%m %s A:0x%08X D:0x%08X","CONTROL      ",CSRA_CONTROL      ,data);
     read_word_task(CSRA_CONFIG       ,data); $display("%m %s A:0x%08X D:0x%08X","CONFIG       ",CSRA_CONFIG       ,data);
     read_word_task(CSRA_CONFIG_FIFO  ,data); $display("%m %s A:0x%08X D:0x%08X","CONFIG_FIFO  ",CSRA_CONFIG_FIFO  ,data);
     read_word_task(CSRA_COMMAND      ,data); $display("%m %s A:0x%08X D:0x%08X","COMMAND      ",CSRA_COMMAND      ,data);
     read_word_task(CSRA_KNL_CFG      ,data); $display("%m %s A:0x%08X D:0x%08X","KNL_CFG      ",CSRA_KNL_CFG      ,data);
     read_word_task(CSRA_FTU_ADDR_LOW ,data); $display("%m %s A:0x%08X D:0x%08X","FTU_ADDR_LOW ",CSRA_FTU_ADDR_LOW ,data);
     read_word_task(CSRA_FTU_ADDR_HIGH,data); $display("%m %s A:0x%08X D:0x%08X","FTU_ADDR_HIGH",CSRA_FTU_ADDR_HIGH,data);
     read_word_task(CSRA_FTU_CFG_SIZE ,data); $display("%m %s A:0x%08X D:0x%08X","FTU_CFG_SIZE ",CSRA_FTU_CFG_SIZE ,data);
     read_word_task(CSRA_FTU_CFG_KNL  ,data); $display("%m %s A:0x%08X D:0x%08X","FTU_CFG_KNL  ",CSRA_FTU_CFG_KNL  ,data);
     read_word_task(CSRA_FTU_ITEMS    ,data); $display("%m %s A:0x%08X D:0x%08X","FTU_ITEMS    ",CSRA_FTU_ITEMS    ,data);
     read_word_task(CSRA_FTU_BURST    ,data); $display("%m %s A:0x%08X D:0x%08X","FTU_BURST    ",CSRA_FTU_BURST    ,data);
     read_word_task(CSRA_FTU_CHANNEL  ,data); $display("%m %s A:0x%08X D:0x%08X","FTU_CHANNEL  ",CSRA_FTU_CHANNEL  ,data);
     read_word_task(CSRA_RST_ADDR_LOW ,data); $display("%m %s A:0x%08X D:0x%08X","RST_ADDR_LOW ",CSRA_RST_ADDR_LOW ,data);
     read_word_task(CSRA_RST_ADDR_HIGH,data); $display("%m %s A:0x%08X D:0x%08X","RST_ADDR_HIGH",CSRA_RST_ADDR_HIGH,data);
     read_word_task(CSRA_RST_CFG_SIZE ,data); $display("%m %s A:0x%08X D:0x%08X","RST_CFG_SIZE ",CSRA_RST_CFG_SIZE ,data);
     read_word_task(CSRA_RST_ITEMS    ,data); $display("%m %s A:0x%08X D:0x%08X","RST_ITEMS    ",CSRA_RST_ITEMS    ,data);
     read_word_task(CSRA_PROFILE_CTL   ,data); $display("%m %s A:0x%08X D:0x%08X","PROFILE_CTL   ",CSRA_PROFILE_CTL    ,data);
     read_word_task(CSRA_PROFILE_CYCLES,data); $display("%m %s A:0x%08X D:0x%08X","PROFILE_CYCLES",CSRA_PROFILE_CYCLES ,data);
     read_word_task(CSRA_PROFILE_CNT_RD,data); $display("%m %s A:0x%08X D:0x%08X","PROFILE_CNT_RD",CSRA_PROFILE_CNT_RD ,data);
     read_word_task(CSRA_PROFILE_CNT_WR,data); $display("%m %s A:0x%08X D:0x%08X","PROFILE_CNT_WR",CSRA_PROFILE_CNT_WR ,data);
   end
   endtask

   //===========================================================================
    localparam MAX_POS={1'b0,{DATA_WIDTH-1{1'b1}}}; // max positive
    localparam MAX_NEG={1'b1,{DATA_WIDTH-1{1'b0}}}; // max negative
   //===========================================================================
   task pool_init;
       reg [31:0] dataW, dataR;
   begin
        read_word_task(CSRA_CONTROL,dataR);
        dataW = dataR | (1'b1<<31); // auto clean automatically
        write_word_task(CSRA_CONTROL,dataW);
        read_word_task(CSRA_CONTROL,dataR);
        if (!(dataR&(1<<30))) $display("%0t %m pool_ready should be 1.", $time);
        if   (dataR&(1<<31))  $display("%0t %m pool_init should be 0.", $time);
   end
   endtask

   //---------------------------------------------------------------------------
   task pool_get_config;
       output integer q;
       output integer n;
       output integer feature_fifo_dpeth;
       output integer result_fifo_dpeth;
       reg [31:0] dataR;
   begin
       read_word_task(CSRA_CONFIG,dataR);
       n = dataR[7:0];
       q = dataR[15:8];
       read_word_task(CSRA_CONFIG_FIFO,dataR);
       feature_fifo_dpeth  = dataR[ 7: 0];
       result_fifo_dpeth = dataR[15: 8];
   end
   endtask
   task pool_get_config_old;
       output integer num_cores;
       output integer q;
       output integer n;
       output integer feature_fifo_dpeth;
       output integer result_fifo_dpeth;
       reg [31:0] dataR;
   begin
       read_word_task(CSRA_CONFIG,dataR);
       n = dataR[7:0];
       q = dataR[15:8];
       num_cores = dataR[31:16];
       read_word_task(CSRA_CONFIG_FIFO,dataR);
       feature_fifo_dpeth  = dataR[ 7: 0];
       result_fifo_dpeth = dataR[15: 8];
   end
   endtask

   //---------------------------------------------------------------------------
   task pool_go_wait;
       input ie;
       input blocking;
       reg [31:0] dataW, dataR;
   begin
        read_word_task(CSRA_CONTROL,dataR);
        dataW = dataR | 'b11 | (ie<<28);
        write_word_task(CSRA_CONTROL,dataW);
        if (blocking) begin
            dataR = 'b11; // go clean automatically
            while (dataR[1:0]!='b00) begin
                read_word_task(CSRA_CONTROL,dataR);
            end
        end
        read_word_task(CSRA_CONTROL,dataR);
        if ((dataR[9:8]!=2'b0)||(dataR[1:0]!=2'b0))
            $display("%0t %m go-done error: 0x%08X", $time, dataR);
   end
   endtask

   //---------------------------------------------------------------------------
   task pool_clear_interrupt;
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
   task pool_set;
       input integer kernel_width;
       input integer kernel_height;
       input integer feature_addr;
       input integer feature_width;
       input integer feature_height;
       input integer feature_stride;
       input integer feature_padding_pre;
       input integer feature_padding_post;
       input integer feature_leng; // not AxLENG format
       input integer feature_channel;
       input integer result_addr;
       input integer result_leng; // not AxLENG format
       integer kernel_num;
       integer result_width;
       integer result_height;
   begin
       result_width = func_result_size( kernel_width, feature_width, feature_stride
                                      , feature_padding_pre, feature_padding_post);
       result_height = func_result_size( kernel_height, feature_height, feature_stride
                                       , feature_padding_pre, feature_padding_post);

       kernel_num = result_width*result_height;
       kernel_set( kernel_width
                 , kernel_height);

       feature_set( feature_addr
                  , feature_width
                  , feature_height
                  , feature_stride
                  , feature_padding_pre
                  , feature_padding_post
                  , feature_leng
                  , feature_channel);
       feature_fill(feature_addr, feature_width, feature_height, feature_channel);

       result_set(result_addr, result_width, result_height, result_leng, feature_channel);
       result_clear(result_addr, result_width, result_height, feature_channel);
    end
    endtask

localparam MAX_KERNEL_SIZE =15
         , MAX_FEATURE_SIZE=640
         , MAX_CHANNEL=8;
   //---------------------------------------------------------------------------
   task check_result;
       input integer kernel_width;
       input integer kernel_height;
       input integer feature_addr;
       input integer feature_width;
       input integer feature_height;
       input integer feature_stride;
       input integer feature_padding_pre;
       input integer feature_padding_post;
       input integer feature_channel;
       input integer result_addr ;
       input integer result_width ;
       input integer result_height;
       reg signed [DATA_WIDTH-1:0] mem_feature[MAX_CHANNEL*MAX_FEATURE_SIZE*MAX_FEATURE_SIZE-1:0];
       reg signed [DATA_WIDTH-1:0] mem_expect [MAX_CHANNEL*MAX_FEATURE_SIZE*MAX_FEATURE_SIZE-1:0];
       reg signed [DATA_WIDTH-1:0] mem_result [MAX_CHANNEL*MAX_FEATURE_SIZE*MAX_FEATURE_SIZE-1:0];
       reg [WIDTH_AD-1:0] addr;
       reg [WIDTH_DA-1:0] data;
       reg signed [DATA_WIDTH-1:0] max;
       reg signed [DATA_WIDTH-1:0] result_value;
       integer ida, idb, idc;
       integer a, b, k, w, x, y, z;
       integer yid, xid, bid, aid;
       integer error;
   begin
     //if (kernel_width[0]==1'b0) $display("%0t %m ERROR kernel width should be odd.", $time);
     //if (kernel_height[0]==1'b0) $display("%0t %m ERROR kernel height should be odd.", $time);
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
       if (feature_channel>MAX_CHANNEL) $display("%0t %m ERROR channel exceed.", $time);
       if (result_width>MAX_FEATURE_SIZE) $display("%0t %m ERROR result size exceed.", $time);
       z = 0;
       addr = feature_addr;
       for (idc=0; idc<feature_channel; idc=idc+1) begin
           for (ida=0; ida<feature_width*feature_height; ida=ida+(WIDTH_DA/DATA_WIDTH)) begin
                data = top.u_mem.read_word(addr);
                for (idb=0; idb<(WIDTH_DA/DATA_WIDTH); idb=idb+1) begin
                     mem_feature[z] = data[DATA_WIDTH*idb +: DATA_WIDTH];
                     z = z + 1;
                end
                addr = addr + WIDTH_DS;
           end // if (ida
       end // if (idc
       if ((feature_padding_pre==0)&&(feature_padding_post==0)) begin
           // pooling 2d
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
           z = 0;
           for (w=0; w<=feature_channel; w=w+1) begin
               for (y=0; y<=(feature_height-kernel_height); y=y+feature_stride) begin
                    yid = w*feature_height*feature_width+y*feature_width; // row to index
                    for (x=0; x<=(feature_width-kernel_width); x=x+feature_stride) begin
                         max = MAX_NEG;
                         xid = yid + x; // col to index
                         for (b=0; b<kernel_height; b=b+1) begin
                              bid = xid + b*feature_width;
                              for (a=0; a<kernel_width; a=a+1) begin
                                   aid = bid + a;
                                   max = (max<mem_feature[aid]) ? mem_feature[aid] : max;
                              end // for (a=0
                         end // for (b=0
                         mem_expect[z] = max;
                         z = z + 1;
                    end // for (x=0
               end // for (y=0
           end // for (w=0
       end else begin // if (feature_padding_pre==0
           z = 0;
           for (w=0; w<feature_channel; w=w+1) begin
           for (y=-feature_padding_pre; y<=(feature_height-kernel_height+feature_padding_post)
                                  ; y=y+feature_stride) begin
                yid = w*feature_height*feature_width+y*feature_width; // row to index
                for (x=-feature_padding_pre; x<=(feature_width-kernel_width+feature_padding_post)
                                       ; x=x+feature_stride) begin
                     max = MAX_NEG;
                     xid = yid + x; // col to index
                     for (b=0; b<kernel_height; b=b+1) begin
                          bid = xid + b*feature_width;
                          for (a=0; a<kernel_width; a=a+1) begin
                               if (((y+b)<0)||((x+a)<0)||
                                   ((y+b)>=feature_height)||
                                   ((x+a)>=feature_width)) begin
                                   max = (max<0) ? 0 : max;
                               end else begin
                                   aid = bid + a;
                                   max = (max<mem_feature[aid]) ? mem_feature[aid] : max;
                               end
                          end // for (a=0
                     end // for (b=0
                     mem_expect[z] = max;
                     z = z + 1;
                end // for (x=0
           end // for (y=0
           end // for (w=0
       end  // if (feature_padding_pre==0
       error = 0;
       addr = result_addr;
       z = 0;
       for (idc=0; idc<feature_channel; idc=idc+1) begin
       for (ida=0; ida<result_width*result_height; ida=ida+(WIDTH_DA/DATA_WIDTH)) begin
            data = top.u_mem.read_word(addr);
            for (idb=0; (((ida*(WIDTH_DA/DATA_WIDTH))+idb)<(result_width*result_height))&&(idb<(WIDTH_DA/DATA_WIDTH)); idb=idb+1) begin
                 result_value = data[DATA_WIDTH*idb +: DATA_WIDTH];
                 mem_result[z] = result_value;
               //if (result_value!==mem_expect[ida+idb]) begin
                 if (result_value!==mem_expect[z]) begin
                     error = error + 1;
                     $display("%m [%0d:%0dx%0d] V:0x%0X E:0x%0X (%0d).",
                                idc,
                               (ida+idb)/result_width, 
                               (ida+idb)%result_width, 
                               result_value,
                               mem_expect[z], z); //mem_expect[ida+idb]);
                 end
                 z = z + 1;
            end // if (idb
            addr = addr + WIDTH_DS;
       end // if (ida
       end // if (idc
       if (error==0) $display("%0t %m OK %0d.", $time, feature_channel*result_width*result_height);
       else          $display("%0t %m mis-match %0d out of %0d.", $time, error, feature_channel*result_width*result_height);
if ($value$plusargs("VERBOSE=%d", arg) && (arg>0)) begin
       // display
       $display("chnnel=%0d feature=%0dx%0d kernel=%0dx%0d stride=%0d", feature_channel, feature_width, feature_height, kernel_width, kernel_height, feature_stride);
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
          end // for (yid
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
   task kernel_set;
        input [ 3:0] width; // width (num of items)
        input [ 3:0] height;
        reg [31:0] data;
   begin
        data = {24'h0,height,width};
        write_word_task(CSRA_KNL_CFG  ,data);
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
       input integer channel;
       integer kernel_width, kernel_height;
       integer result_width, result_height, result_leng;
       integer Q, N, bytes;
       integer fl, rl;
       reg [31:0] dataW, dataR;
   begin
        // initialize feature
        feature_fill(addr, width, height, channel);
        feature_set( addr // input [31:0] addr_mem; // space for filter(kernel)
                   , width // input [ 3:0] size; // width (num of items)
                   , height
                   , stride
                   , padding_pre
                   , padding_post
                   , leng // input [ 7:0] leng; // burst length (not AxLENG format)
                   , channel
                   );
        read_word_task(CSRA_KNL_CFG,dataR);
        pool_get_config(Q,N,fl,rl);
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
                  , channel
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
        dataW = dataR | 'b11; // result/feature go
        write_word_task(CSRA_CONTROL,dataW);
        if (blocking) begin
            dataR = 'b11; // feature_go clean automatically
            while (dataR[0]) begin
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
       input integer channel;
       integer Q, N, bytes;
       integer w, x;
       integer idx;
       reg [31:0] dataW;
   begin
       pool_get_config(Q,N,w,x);
       if (Q!=0) $display("%t %m ERROR Q %d.", $time, Q);
        bytes = N/8;
        // initialize feature
        for (idx=0; idx<(channel*width*height); idx=idx+1) begin
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
        input [15:0] channel;
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
        write_word_task(CSRA_FTU_CHANNEL,channel);
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
       input integer channel;
       integer Q, N, bytes;
       integer w,x;
       integer idx, idy;
       reg [31:0] dataW;
   begin
        pool_get_config(Q,N,w,x);
        bytes = N/8;
        // clear result
        for (idy=0; idy<bytes; idy=idy+1) dataWB[idy] = 0;
        dataW = 0;
        for (idx=0; idx<(channel*width*height); idx=idx+1) begin
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
        input [15:0] channel; // not used since the num of channels of result must be the same as the num of channels of features
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
      output [31:0] profile_cycles;
      output [31:0] profile_cnt_rd;
      output [31:0] profile_cnt_wr;
      reg [31:0] dataW, dataR;
     begin
      dataW = 31'h1;
      write_word_task(CSRA_PROFILE_CTL, dataW);
      dataR = dataW;
      while (dataR[1:0]!=2'b0) read_word_task(CSRA_PROFILE_CTL, dataR);
      read_word_task(CSRA_PROFILE_CYCLES,profile_cycles );
      read_word_task(CSRA_PROFILE_CNT_RD,profile_cnt_rd );
      read_word_task(CSRA_PROFILE_CNT_WR,profile_cnt_wr );
    end
    endtask

    //---------------------------------------------------------------------------
    task profile_put;
      reg [31:0] profile_cycles;
      reg [31:0] profile_cnt_rd;
      reg [31:0] profile_cnt_wr;
     begin
      read_word_task(CSRA_PROFILE_CYCLES,profile_cycles);
      read_word_task(CSRA_PROFILE_CNT_RD,profile_cnt_rd);
      read_word_task(CSRA_PROFILE_CNT_WR,profile_cnt_wr);
      $display("PROFILE_CYCLES(x10): %-d", profile_cycles);
      $display("PROFILE_CNT_RD     : %-d", profile_cnt_rd);
      $display("PROFILE_CNT_WR     : %-d", profile_cnt_wr);
    end
    endtask
    //==========================================================================
