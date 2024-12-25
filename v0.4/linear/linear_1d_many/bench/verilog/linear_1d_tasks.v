
   localparam CSRA_VERSION           =(ADDR_BASE_LINEAR+'h00)
            , CSRA_CONTROL           =(ADDR_BASE_LINEAR+'h10)
            , CSRA_CONFIG            =(ADDR_BASE_LINEAR+'h14)
            , CSRA_CONFIG_FIFO       =(ADDR_BASE_LINEAR+'h18)

            , CSRA_INPUT_ADDR_LOW    =(ADDR_BASE_LINEAR+'h20)
            , CSRA_INPUT_ADDR_HIGH   =(ADDR_BASE_LINEAR+'h24)
            , CSRA_INPUT_CFG         =(ADDR_BASE_LINEAR+'h28)
            , CSRA_INPUT_BURST       =(ADDR_BASE_LINEAR+'h30)

            , CSRA_WEIGHT_ADDR_LOW   =(ADDR_BASE_LINEAR+'h40)
            , CSRA_WEIGHT_ADDR_HIGH  =(ADDR_BASE_LINEAR+'h44)
            , CSRA_WEIGHT_CFG        =(ADDR_BASE_LINEAR+'h48)
            , CSRA_WEIGHT_ITEMS      =(ADDR_BASE_LINEAR+'h4C)
            , CSRA_WEIGHT_BURST      =(ADDR_BASE_LINEAR+'h50)

            , CSRA_BIAS_ADDR_LOW     =(ADDR_BASE_LINEAR+'h60)
            , CSRA_BIAS_ADDR_HIGH    =(ADDR_BASE_LINEAR+'h64)
            , CSRA_BIAS_CFG          =(ADDR_BASE_LINEAR+'h68)

            , CSRA_RST_ADDR_LOW      =(ADDR_BASE_LINEAR+'h70)
            , CSRA_RST_ADDR_HIGH     =(ADDR_BASE_LINEAR+'h74)
            , CSRA_RST_CFG           =(ADDR_BASE_LINEAR+'h78)
            , CSRA_RST_BURST         =(ADDR_BASE_LINEAR+'h80)

            , CSRA_LINEAR_ACTIV_FUNC =(ADDR_BASE_LINEAR+'h90)
            , CSRA_LINEAR_ACTIV_PARAM=(ADDR_BASE_LINEAR+'h94)

            , CSRA_PROFILE_CTL       =(ADDR_BASE_LINEAR+'hA0)
            , CSRA_PROFILE_CYCLES    =(ADDR_BASE_LINEAR+'hA4)
            , CSRA_PROFILE_MAC_NUM   =(ADDR_BASE_LINEAR+'hA8)
            , CSRA_PROFILE_MAC_OVR   =(ADDR_BASE_LINEAR+'hAC)
            , CSRA_PROFILE_BIA_OVR   =(ADDR_BASE_LINEAR+'hB0)
            , CSRA_PROFILE_ACT_OVR   =(ADDR_BASE_LINEAR+'hB4)
            , CSRA_PROFILE_CNT_RD    =(ADDR_BASE_LINEAR+'hB8)
            , CSRA_PROFILE_CNT_WR    =(ADDR_BASE_LINEAR+'hBC)
            ;

   //---------------------------------------------------------------------------
   task csr_test;
       reg [31:0] data;
   begin
      read_word_task(CSRA_VERSION           ,data); $display("%m %s A:0x%08X D:0x%08X", "VERSION           ", CSRA_VERSION            , data);
      read_word_task(CSRA_CONTROL           ,data); $display("%m %s A:0x%08X D:0x%08X", "CONTROL           ", CSRA_CONTROL            , data);
      read_word_task(CSRA_CONFIG            ,data); $display("%m %s A:0x%08X D:0x%08X", "CONFIG            ", CSRA_CONFIG             , data);
      read_word_task(CSRA_CONFIG_FIFO       ,data); $display("%m %s A:0x%08X D:0x%08X", "CONFIG_FIFO       ", CSRA_CONFIG_FIFO        , data);

      read_word_task(CSRA_INPUT_ADDR_LOW    ,data); $display("%m %s A:0x%08X D:0x%08X", "INPUT_ADDR_LOW    ", CSRA_INPUT_ADDR_LOW     , data);
      read_word_task(CSRA_INPUT_ADDR_HIGH   ,data); $display("%m %s A:0x%08X D:0x%08X", "INPUT_ADDR_HIGH   ", CSRA_INPUT_ADDR_HIGH    , data);
      read_word_task(CSRA_INPUT_CFG         ,data); $display("%m %s A:0x%08X D:0x%08X", "INPUT_CFG         ", CSRA_INPUT_CFG          , data);
      read_word_task(CSRA_INPUT_BURST       ,data); $display("%m %s A:0x%08X D:0x%08X", "INPUT_BURST       ", CSRA_INPUT_BURST        , data);

      read_word_task(CSRA_WEIGHT_ADDR_LOW   ,data); $display("%m %s A:0x%08X D:0x%08X", "WEIGHT_ADDR_LOW   ", CSRA_WEIGHT_ADDR_LOW    , data);
      read_word_task(CSRA_WEIGHT_ADDR_HIGH  ,data); $display("%m %s A:0x%08X D:0x%08X", "WEIGHT_ADDR_HIGH  ", CSRA_WEIGHT_ADDR_HIGH   , data);
      read_word_task(CSRA_WEIGHT_CFG        ,data); $display("%m %s A:0x%08X D:0x%08X", "WEIGHT_CFG        ", CSRA_WEIGHT_CFG         , data);
      read_word_task(CSRA_WEIGHT_ITEMS      ,data); $display("%m %s A:0x%08X D:0x%08X", "WEIGHT_ITEMS      ", CSRA_WEIGHT_ITEMS       , data);
      read_word_task(CSRA_WEIGHT_BURST      ,data); $display("%m %s A:0x%08X D:0x%08X", "WEIGHT_BURST      ", CSRA_WEIGHT_BURST       , data);

      read_word_task(CSRA_BIAS_ADDR_LOW     ,data); $display("%m %s A:0x%08X D:0x%08X", "BIAS_ADDR_LOW     ", CSRA_BIAS_ADDR_LOW      , data);
      read_word_task(CSRA_BIAS_ADDR_HIGH    ,data); $display("%m %s A:0x%08X D:0x%08X", "BIAS_ADDR_HIGH    ", CSRA_BIAS_ADDR_HIGH     , data);
      read_word_task(CSRA_BIAS_CFG          ,data); $display("%m %s A:0x%08X D:0x%08X", "BIAS_CFG          ", CSRA_BIAS_CFG           , data);

      read_word_task(CSRA_RST_ADDR_LOW      ,data); $display("%m %s A:0x%08X D:0x%08X", "RST_ADDR_LOW      ", CSRA_RST_ADDR_LOW       , data);
      read_word_task(CSRA_RST_ADDR_HIGH     ,data); $display("%m %s A:0x%08X D:0x%08X", "RST_ADDR_HIGH     ", CSRA_RST_ADDR_HIGH      , data);
      read_word_task(CSRA_RST_CFG           ,data); $display("%m %s A:0x%08X D:0x%08X", "RST_CFG           ", CSRA_RST_CFG            , data);
      read_word_task(CSRA_RST_BURST         ,data); $display("%m %s A:0x%08X D:0x%08X", "RST_BURST         ", CSRA_RST_BURST          , data);

      read_word_task(CSRA_LINEAR_ACTIV_FUNC ,data); $display("%m %s A:0x%08X D:0x%08X", "LINEAR_ACTIV_FUNC ", CSRA_LINEAR_ACTIV_FUNC  , data);
      read_word_task(CSRA_LINEAR_ACTIV_PARAM,data); $display("%m %s A:0x%08X D:0x%08X", "LINEAR_ACTIV_PARAM", CSRA_LINEAR_ACTIV_PARAM , data);

      read_word_task(CSRA_PROFILE_CTL       ,data); $display("%m %s A:0x%08X D:0x%08X", "PROFILE_CTL       ", CSRA_PROFILE_CTL        , data);
      read_word_task(CSRA_PROFILE_CYCLES    ,data); $display("%m %s A:0x%08X D:0x%08X", "PROFILE_CYCLES    ", CSRA_PROFILE_CYCLES     , data);
      read_word_task(CSRA_PROFILE_MAC_NUM   ,data); $display("%m %s A:0x%08X D:0x%08X", "PROFILE_MAC_NUM   ", CSRA_PROFILE_MAC_NUM    , data);
      read_word_task(CSRA_PROFILE_MAC_OVR   ,data); $display("%m %s A:0x%08X D:0x%08X", "PROFILE_MAC_OVR   ", CSRA_PROFILE_MAC_OVR    , data);
      read_word_task(CSRA_PROFILE_BIA_OVR   ,data); $display("%m %s A:0x%08X D:0x%08X", "PROFILE_BIA_OVR   ", CSRA_PROFILE_BIA_OVR    , data);
      read_word_task(CSRA_PROFILE_ACT_OVR   ,data); $display("%m %s A:0x%08X D:0x%08X", "PROFILE_ACT_OVR   ", CSRA_PROFILE_ACT_OVR    , data);
      read_word_task(CSRA_PROFILE_CNT_RD    ,data); $display("%m %s A:0x%08X D:0x%08X", "PROFILE_CNT_RD    ", CSRA_PROFILE_CNT_RD     , data);
      read_word_task(CSRA_PROFILE_CNT_WR    ,data); $display("%m %s A:0x%08X D:0x%08X", "PROFILE_CNT_WR    ", CSRA_PROFILE_CNT_WR     , data);
   end
   endtask

   //===========================================================================
   task linear_init;
       reg [31:0] dataW, dataR;
   begin
        read_word_task(CSRA_CONTROL,dataR);
        dataW = dataR | (1'b1<<31); // auto clean automatically
        write_word_task(CSRA_CONTROL,dataW);
        read_word_task(CSRA_CONTROL,dataR);
        if (!(dataR&(1<<30))) $display("%0t %m linear_ready should be 1.", $time);
        if   (dataR&(1<<31))  $display("%0t %m linear_init should be 0.", $time);
   end
   endtask
   //---------------------------------------------------------------------------
   task linear_get_config;
       output integer Q;
       output integer N;
       output integer input_fifo_dpeth;
       output integer weight_fifo_dpeth;
       output integer result_fifo_dpeth;
       reg [31:0] dataR;
   begin
       read_word_task(CSRA_CONFIG,dataR);
       N = dataR[7:0];
       Q = dataR[15:8];
       read_word_task(CSRA_CONFIG_FIFO,dataR);
       input_fifo_dpeth  = dataR[ 7: 0];
       weight_fifo_dpeth = dataR[15: 8];
       result_fifo_dpeth = dataR[23:16];
   end
   endtask
   //---------------------------------------------------------------------------
   task linear_go_wait;
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
   task linear_clear_interrupt;
       reg [31:0] dataW, dataR;
   begin
        read_word_task(CSRA_CONTROL,dataR);
        dataW = dataR & ~(2'b11<<28);
        write_word_task(CSRA_CONTROL,dataW);
   end
   endtask
   //---------------------------------------------------------------------------
   task linear_set;
        input integer input_addr;
        input integer input_size;
        input integer input_leng;
        input integer weight_addr;
        input integer weight_width; // =input_size
        input integer weight_height;
        input integer weight_leng;
        input integer bias_addr;
        input integer bias_size; // set 0 for no-bias
        input integer result_addr; // =previous_addr
        input integer result_size; // =weight_height (not AxLENG format)
        input integer result_leng; // =bias_leng (not AxLENG format)
        input integer          activ_func;
        input [DATA_WIDTH-1:0] activ_param;
        input fill; // 0=no-fill, 1=fill
        input random;
        reg [31:0] data;
   begin
        if (input_size!=weight_width) $display("%0t %m ERROR input_size!=weight_width", $time);
        if ((bias_size!=0)&&(bias_size!=weight_height)) $display("%0t %m ERROR bias_size!=weight_height", $time);
        if (result_size!=weight_height) $display("%0t %m ERROR result_size!=weight_height", $time);

        input_set   ( input_addr, input_size, input_leng );
        weight_set  ( weight_addr, weight_width, weight_height, weight_leng );
        bias_set    ( bias_addr, bias_size);
        result_set  ( result_addr, result_size, result_leng );
        activ_set   ( activ_func, activ_param );

        input_fill   ( input_addr, input_size, random);
        weight_fill  ( weight_addr, weight_width, weight_height, random);
        bias_fill    ( bias_addr, bias_size, random);
        result_fill  ( result_addr, result_size);
   end
   endtask
   //---------------------------------------------------------------------------
   task check_result;
        input integer input_addr;
        input integer input_size;
        input integer weight_addr;
        input integer weight_width; // =input_size
        input integer weight_height;
        input integer bias_addr;
        input integer bias_size; // set 0 for no-bias
        input integer result_addr; // =previous_addr
        input integer result_size; // =weight_height (not AxLENG format)
        input integer          activ_func;
        input [DATA_WIDTH-1:0] activ_param;

        reg   [DATA_WIDTH-1:0] mem_input[0:MAX_WEIGHT_WIDTH-1];
        reg   [DATA_WIDTH-1:0] mem_weight[0:MAX_WEIGHT_WIDTH*MAX_WEIGHT_HEIGHT-1];
        reg   [DATA_WIDTH-1:0] mem_bias[0:MAX_WEIGHT_HEIGHT-1];
        reg   [DATA_WIDTH-1:0] mem_expect[0:MAX_WEIGHT_HEIGHT-1];
        reg   [DATA_WIDTH-1:0] mem_result[0:MAX_WEIGHT_HEIGHT-1];

        reg   [WIDTH_AD-1:0] addr;
        reg   [WIDTH_DA-1:0] data;
        reg   [DATA_WIDTH-1:0] sum;
        integer ida, idb, idc;
        integer error;
        integer xid, yid;
   begin
       if (input_size!=weight_width) $display("%0t %m ERROR input size.", $time);
       if ((bias_size>0)&&(bias_size!=weight_height)) $display("%0t %m ERROR bias size.", $time);
       if (result_size!=weight_height) $display("%0t %m ERROR result size.", $time);
       if (weight_width>MAX_WEIGHT_WIDTH) $display("%0t %m ERROR weight width.", $time);
       if (weight_height>MAX_WEIGHT_HEIGHT) $display("%0t %m ERROR weight height.", $time);
       // get values
       addr = input_addr;
       for (ida=0; ida<input_size; ida=ida+(WIDTH_DA/DATA_WIDTH)) begin
            data = top.u_mem.read_word(addr);
            for (idb=0; idb<(WIDTH_DA/DATA_WIDTH); idb=idb+1) begin
                 mem_input[ida+idb] = data[DATA_WIDTH*idb +: DATA_WIDTH];
            end // for (idb=0
            addr = addr + WIDTH_DS;
       end // for (ida=0
       addr = weight_addr;
       for (ida=0; ida<weight_width*weight_height; ida=ida+(WIDTH_DA/DATA_WIDTH)) begin
            data = top.u_mem.read_word(addr);
            for (idb=0; idb<(WIDTH_DA/DATA_WIDTH); idb=idb+1) begin
                 mem_weight[ida+idb] = data[DATA_WIDTH*idb +: DATA_WIDTH];
            end // for (idb=0
            addr = addr + WIDTH_DS;
       end // for (ida=0
       if (bias_size>0) begin
           addr = bias_addr;
           for (ida=0; ida<input_size; ida=ida+(WIDTH_DA/DATA_WIDTH)) begin
                data = top.u_mem.read_word(addr);
                for (idb=0; idb<(WIDTH_DA/DATA_WIDTH); idb=idb+1) begin
                     mem_bias[ida+idb] = data[DATA_WIDTH*idb +: DATA_WIDTH];
                end // for (idb=0
                addr = addr + WIDTH_DS;
           end // for (ida=0
       end // if (bias_size>0)
       addr = result_addr;
       for (ida=0; ida<input_size; ida=ida+(WIDTH_DA/DATA_WIDTH)) begin
            data = top.u_mem.read_word(addr);
            for (idb=0; idb<(WIDTH_DA/DATA_WIDTH); idb=idb+1) begin
                 mem_result[ida+idb] = data[DATA_WIDTH*idb +: DATA_WIDTH];
            end // for (idb=0
            addr = addr + WIDTH_DS;
       end // for (ida=0
       // calculate expected value
       idc = 0;
       for (ida=0; ida<weight_height; ida=ida+1) begin
           // * The result changes depending on whether the bias is used as the initial value of the operation or is processed after the operation.
           // - If bias is applied after calculation, there is a change in saturation due to overflow.
           if (bias_size>0) sum = mem_bias[idc];
           else             sum = 0;
           for (idb=0; idb<weight_width; idb=idb+1) begin
                sum = func_mac(sum, mem_input[idb], mem_weight[ida*weight_width+idb]);
           end //for (idb=0
           if (activ_func==1) begin // ReLU
               mem_expect[idc] = (sum<0) ? 0 : sum;
           end else if (activ_func==2) begin // LeakyReLU
               mem_expect[idc] = (sum>0) ? sum : sum;
           end else begin
               mem_expect[idc] = sum;
           end
           idc = idc + 1;
       end //for (ida=0
       // check result
       error = 0;
       for (ida=0; ida<weight_height; ida=ida+1) begin
           if (mem_expect[ida]!==mem_result[ida]) begin
               error = error + 1;
           end
       end // for (ida=0
       if (error==0) $display("%0t %m OK %0d.", $time, weight_height);
       else begin
            $display("%0t %m MIS-MATCH %0d out of %0d.", $time, error, weight_height);
            if (DATA_WIDTH==8) begin
               $display("%0t %m MIS-MATCH due to overflow.", $time);
            end
       end
       //-----------------------------------------------------------------------
if ($value$plusargs("VERBOSE=%d", arg) && (arg>0)) begin
       // display
       $display("input-vector=%0d weight=%0dx%0d bias=%0d activation=%-s",
                 input_size, weight_width, weight_height, bias_size,
                 (activ_func==0) ? "none" :
                 (activ_func==1) ? "ReLU" :
                 (activ_func==2) ? "LeakyReLU" : "not-defined");
       if (DATA_WIDTH==8) begin
          for (xid=0; xid<input_size; xid=xid+1) $write("%s", " --");
          $write("\n");
          for (xid=0; xid<input_size; xid=xid+1) begin
               $write("|%02X", mem_input[xid]);
               //$write("|%02d", $signed(mem_input[xid]));
               if ((xid+1)==input_size) $write("| ");
          end
          $write("\n");
          for (xid=0; xid<input_size; xid=xid+1) $write("%s", " --");
          $write("\n");

          for (yid=0; yid<weight_height; yid=yid+1) begin
              for (xid=0; xid<weight_width; xid=xid+1) begin
                   $write("|%02X", mem_weight[yid*weight_width+xid]);
                   if ((xid+1)==weight_width) $write("| ");
              end
              $write("\n");
          end
          for (xid=0; xid<weight_width; xid=xid+1) $write("%s", " --");
          $write("\n");

          for (xid=0; xid<result_size; xid=xid+1) $write("%s", " --");
          $write("\n");
          for (xid=0; xid<result_size; xid=xid+1) begin
               $write("|%02X", mem_result[xid]);
               //$write("|%02d", $signed(mem_result[xid]));
               if ((xid+1)==result_size) $write("| ");
          end
          $write("\n");
          for (xid=0; xid<result_size; xid=xid+1) $write("%s", " --");
          $write("\n");

          if (error>0) begin
              for (xid=0; xid<result_size; xid=xid+1) $write("%s", " --");
              $write("\n");
              for (xid=0; xid<result_size; xid=xid+1) begin
                   $write("|%02X", mem_expect[xid]);
                   //$write("|%02d", $signed(mem_expect[xid]));
                   if ((xid+1)==result_size) $write("| ");
              end
              $write("\n");
              for (xid=0; xid<result_size; xid=xid+1) $write("%s", " --");
              $write("\n");
          end
       end
       if (DATA_WIDTH==16) begin
          for (xid=0; xid<input_size; xid=xid+1) $write("%s", " ----");
          $write("\n");
          for (xid=0; xid<input_size; xid=xid+1) begin
               $write("|%04X", mem_input[xid]);
               //$write("|%04d", $signed(mem_input[xid]));
               if ((xid+1)==input_size) $write("| ");
          end
          $write("\n");
          for (xid=0; xid<input_size; xid=xid+1) $write("%s", " ----");
          $write("\n");

          for (yid=0; yid<weight_height; yid=yid+1) begin
              for (xid=0; xid<weight_width; xid=xid+1) begin
                   $write("|%04X", mem_weight[yid*weight_width+xid]);
                   if ((xid+1)==weight_width) $write("| ");
              end
              $write("\n");
          end
          for (xid=0; xid<weight_width; xid=xid+1) $write("%s", " ----");
          $write("\n");

          for (xid=0; xid<result_size; xid=xid+1) $write("%s", " ----");
          $write("\n");
          for (xid=0; xid<result_size; xid=xid+1) begin
               $write("|%04X", mem_result[xid]);
               //$write("|%04d", $signed(mem_result[xid]));
               if ((xid+1)==result_size) $write("| ");
          end
          $write("\n");
          for (xid=0; xid<result_size; xid=xid+1) $write("%s", " ----");
          $write("\n");

          if (error>0) begin
              for (xid=0; xid<result_size; xid=xid+1) $write("%s", " ----");
              $write("\n");
              for (xid=0; xid<result_size; xid=xid+1) begin
                   $write("|%04X", mem_expect[xid]);
                   //$write("|%04d", $signed(mem_expect[xid]));
                   if ((xid+1)==result_size) $write("| ");
              end
              $write("\n");
              for (xid=0; xid<result_size; xid=xid+1) $write("%s", " ----");
              $write("\n");
          end
       end
       if (DATA_WIDTH==32) begin
          for (xid=0; xid<input_size; xid=xid+1) $write("%s", " --------");
          $write("\n");
          for (xid=0; xid<input_size; xid=xid+1) begin
               $write("|%08X", mem_input[xid]);
               //$write("|%08d", $signed(mem_input[xid]));
               if ((xid+1)==input_size) $write("| ");
          end
          $write("\n");
          for (xid=0; xid<input_size; xid=xid+1) $write("%s", " --------");
          $write("\n");

          for (yid=0; yid<weight_height; yid=yid+1) begin
              for (xid=0; xid<weight_width; xid=xid+1) begin
                   $write("|%08X", mem_weight[yid*weight_width+xid]);
                   if ((xid+1)==weight_width) $write("| ");
              end
              $write("\n");
          end
          for (xid=0; xid<weight_width; xid=xid+1) $write("%s", " --------");
          $write("\n");

          for (xid=0; xid<result_size; xid=xid+1) $write("%s", " --------");
          $write("\n");
          for (xid=0; xid<result_size; xid=xid+1) begin
               $write("|%08X", mem_result[xid]);
               //$write("|%08d", $signed(mem_result[xid]));
               if ((xid+1)==result_size) $write("| ");
          end
          $write("\n");
          for (xid=0; xid<result_size; xid=xid+1) $write("%s", " --------");
          $write("\n");

          if (error>0) begin
              for (xid=0; xid<result_size; xid=xid+1) $write("%s", " --------");
              $write("\n");
              for (xid=0; xid<result_size; xid=xid+1) begin
                   $write("|%08X", mem_expect[xid]);
                   //$write("|%08d", $signed(mem_expect[xid]));
                   if ((xid+1)==result_size) $write("| ");
              end
              $write("\n");
              for (xid=0; xid<result_size; xid=xid+1) $write("%s", " --------");
              $write("\n");
          end
       end
end
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

   //===========================================================================
   task input_set;
        input integer input_addr;
        input integer input_size;
        input integer input_leng; // not AxLENG format
        reg [31:0] data;
        integer Q, N, w, x, y;
   begin
        linear_get_config(Q,N,w,x,y);
        if (input_leng>w) $display("%0t %m WARNING input leng is bigger than FIFO depth.", $time);
        data = input_addr;
        write_word_task(CSRA_INPUT_ADDR_LOW ,data);
        write_word_task(CSRA_INPUT_ADDR_HIGH,32'h0);
        data = {16'h0,input_size[15:0]};
        write_word_task(CSRA_INPUT_CFG  ,data);
        data = (input_leng==0) ? 0 :
               (input_leng>w) ? w-1 : input_leng-1; // mind AxLENG format
        write_word_task(CSRA_INPUT_BURST,data);
   end
   endtask
   //---------------------------------------------------------------------------
   task input_fill;
        input integer input_addr;
        input integer input_size;
        input integer random;
       integer Q, N, bytes, items;
       integer w, x, y;
       integer idx, seed;
       integer value;
       real rvalue;
       reg [31:0] dataW;
   begin
        linear_get_config(Q,N,w,x,y);
        if (Q!=0) $display("%t %m ERROR Q %d.", $time, Q);
        bytes = N/8;
        seed = random;
        for (idx=0; idx<input_size; idx=idx+1) begin
`ifdef xxyy
             {dataWB[3],dataWB[2],dataWB[1],dataWB[0]} = (idx+1)<<Q;
             write_task(2, input_addr+(idx*bytes), bytes, 1, 1); // through BUS
`else
             if (random>0) begin
                 value = $random(seed)/(1<<(N>>1));
                 dataW = $unsigned(value);
             end else begin
                 rvalue = $itor((1<<(N-1)));
                 value  = $rtoi(rvalue);
                 dataW = ((idx+1)<<Q)%value;
             end
             top.u_mem.write(input_addr+(idx*bytes), dataW, bytes); // direct call task
`endif
       end // for
   end
   endtask
   //===========================================================================
   task weight_set;
        input integer weight_addr;
        input integer weight_width;
        input integer weight_height;
        input integer weight_leng; // not AxLENG format
        reg [31:0] data;
        integer Q, N, w, x, y;
   begin
        linear_get_config(Q,N,w,x,y);
        if (weight_leng>x) $display("%0t %m WARNING weight leng is bigger than FIFO depth.", $time);
        data = weight_addr;
        write_word_task(CSRA_WEIGHT_ADDR_LOW ,data);
        write_word_task(CSRA_WEIGHT_ADDR_HIGH,32'h0);
        data = {weight_height[15:0],weight_width[15:0]};
        write_word_task(CSRA_WEIGHT_CFG,data);
        data = weight_height*weight_width;
        write_word_task(CSRA_WEIGHT_ITEMS,data);
        data = (weight_leng==0) ? 0 :
               (weight_leng>x) ? x-1 : weight_leng-1; // mind AxLENG format
        write_word_task(CSRA_WEIGHT_BURST,data);
   end
   endtask
   //---------------------------------------------------------------------------
   task weight_fill;
        input integer weight_addr;
        input integer weight_width;
        input integer weight_height;
        input integer random;
       integer Q, N, bytes, items;
       integer w, x, y;
       integer idx, seed;
       integer value;
       real rvalue;
       reg [31:0] dataW;
   begin
       linear_get_config(Q,N,w,x,y);
       if (Q!=0) $display("%t %m ERROR Q %d.", $time, Q);
        bytes = N/8;
        seed = random;
        for (idx=0; idx<(weight_width*weight_height); idx=idx+1) begin
`ifdef xxyy
             {dataWB[3],dataWB[2],dataWB[1],dataWB[0]} = (idx+1)<<Q;
             write_task(3, weight_addr+(idx*bytes), bytes, 1, 1); // through BUS
`else
             if (random>0) begin
                 value = $random(seed)/(1<<(N>>1));
                 dataW = $unsigned(value);
             end else begin
                 rvalue = $itor((1<<(N-1)));
                 value  = $rtoi(rvalue);
                 dataW = ((idx+1)<<Q)%value;
             end
             top.u_mem.write(weight_addr+(idx*bytes), dataW, bytes); // direct call task
`endif
        end // for
   end
   endtask
   //===========================================================================
   task bias_set;
        input integer bias_addr;
        input integer bias_size;
        reg [31:0] data;
        integer Q, N, w, x, y, z;
   begin
        data = bias_addr;
        write_word_task(CSRA_BIAS_ADDR_LOW ,data);
        write_word_task(CSRA_BIAS_ADDR_HIGH,32'h0);
        data = {16'h0,bias_size[15:0]};
        write_word_task(CSRA_BIAS_CFG  ,data);
   end
   endtask
   //---------------------------------------------------------------------------
   task bias_fill;
        input integer bias_addr;
        input integer bias_size;
        input integer random;
       integer Q, N, bytes;
       integer w, x, y;
       integer idx, seed;
       integer value;
       real rvalue;
       reg [31:0] dataW;
   begin
        linear_get_config(Q,N,w,x,y);
        if (Q!=0) $display("%t %m ERROR Q %d.", $time, Q);
        bytes = N/8;
        seed = random;
        for (idx=0; idx<bias_size; idx=idx+1) begin
`ifdef xxyy
             {dataWB[3],dataWB[2],dataWB[1],dataWB[0]} = (idx+1)<<Q;
             write_task(2, bias_addr+(idx*bytes), bytes, 1, 1); // through BUS
`else
             if (random>0) begin
                 value = $random(seed)/(1<<(N>>1));
                 dataW = $unsigned(value);
             end else begin
                 rvalue = $itor((1<<(N-1)));
                 value  = $rtoi(rvalue);
                 dataW = ((idx+1)<<Q)%value;
             end
             top.u_mem.write(bias_addr+(idx*bytes), dataW, bytes); // direct call task
`endif
        end // for
   end
   endtask
   //===========================================================================
   task activ_set;
        input integer          activ_func;
        input [DATA_WIDTH-1:0] activ_param;
        reg [31:0] data;
   begin
        data = {28'h0,activ_func[3:0]};
        write_word_task(CSRA_LINEAR_ACTIV_FUNC ,data);
        data = {{32-DATA_WIDTH{1'b0}},activ_param};
        write_word_task(CSRA_LINEAR_ACTIV_PARAM,data);
   end
   endtask
   //===========================================================================
   task result_set;
        input integer result_addr;
        input integer result_size;
        input integer result_leng; // not AxLENG format
        reg [31:0] data;
        integer Q, N, w, x, y;
   begin
        linear_get_config(Q,N,w,x,y);
        if (result_leng>y) $display("%0t %m WARNING result leng is bigger than FIFO depth: %0d %0d", $time, result_leng, y);
        data = result_addr;
        write_word_task(CSRA_RST_ADDR_LOW ,data);
        write_word_task(CSRA_RST_ADDR_HIGH,32'h0);
        data = {16'h0,result_size[15:0]};
        write_word_task(CSRA_RST_CFG  ,data);
        data = (result_leng==0) ? 0
             : (result_leng>y ) ? y-1 : result_leng-1; // mind AxLENG format
        write_word_task(CSRA_RST_BURST,data);
   end
   endtask
   //---------------------------------------------------------------------------
   task result_fill;
        input integer result_addr;
        input integer result_size;
       integer Q, N, bytes;
       integer w, x, y;
       integer idx;
       reg [31:0] dataW;
   begin
        linear_get_config(Q,N,w,x,y);
        if (Q!=0) $display("%t %m ERROR Q %d.", $time, Q);
        bytes = N/8;
        // initialize kernel
        for (idx=0; idx<result_size; idx=idx+1) begin
`ifdef xxyy
             {dataWB[3],dataWB[2],dataWB[1],dataWB[0]} = (idx+1)<<Q;
             write_task(2, result_addr+(idx*bytes), bytes, 1, 1); // through BUS
`else
             dataW = (idx+1)<<Q;
             top.u_mem.write(result_addr+(idx*bytes), dataW, bytes); // direct call task
`endif
        end // for
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
      output [31:0] profile_cycles ;
      output [31:0] profile_mac_num;
      output [31:0] profile_mac_ovr;
      output [31:0] profile_bia_ovr;
      output [31:0] profile_act_ovr;
      output [31:0] profile_cnt_rd ;
      output [31:0] profile_cnt_wr ;
      reg [31:0] data;
     begin
      data = 32'h1;
      write_word_task(CSRA_PROFILE_CTL, data);
      while (data[1:0]!=2'b0) read_word_task(CSRA_PROFILE_CTL, data);
      read_word_task(CSRA_PROFILE_CYCLES ,profile_cycles );
      read_word_task(CSRA_PROFILE_MAC_NUM,profile_mac_num);
      read_word_task(CSRA_PROFILE_MAC_OVR,profile_mac_ovr);
      read_word_task(CSRA_PROFILE_BIA_OVR,profile_bia_ovr);
      read_word_task(CSRA_PROFILE_ACT_OVR,profile_act_ovr);
      read_word_task(CSRA_PROFILE_CNT_RD ,profile_cnt_rd );
      read_word_task(CSRA_PROFILE_CNT_WR ,profile_cnt_wr );
    end
    endtask

    //---------------------------------------------------------------------------
    task profile_put;
      reg [31:0] profile_cycles ;
      reg [31:0] profile_mac_num;
      reg [31:0] profile_mac_ovr;
      reg [31:0] profile_bia_ovr;
      reg [31:0] profile_act_ovr;
      reg [31:0] profile_cnt_rd ;
      reg [31:0] profile_cnt_wr ;
     begin
      read_word_task(CSRA_PROFILE_CYCLES ,profile_cycles );
      read_word_task(CSRA_PROFILE_MAC_NUM,profile_mac_num);
      read_word_task(CSRA_PROFILE_MAC_OVR,profile_mac_ovr);
      read_word_task(CSRA_PROFILE_BIA_OVR,profile_bia_ovr);
      read_word_task(CSRA_PROFILE_ACT_OVR,profile_act_ovr);
      read_word_task(CSRA_PROFILE_CNT_RD ,profile_cnt_rd );
      read_word_task(CSRA_PROFILE_CNT_WR ,profile_cnt_wr );
      $display("PROFILE_CYCLES(x10): %-d", profile_cycles );
      $display("PROFILE_MAC_NUM    : %-d", profile_mac_num);
      $display("PROFILE_MAC_OVR    : %-d", profile_mac_ovr);
      $display("PROFILE_BIA_OVR    : %-d", profile_bia_ovr);
      $display("PROFILE_ACT_OVR    : %-d", profile_act_ovr);
      $display("PROFILE_CNT_RD     : %-d", profile_cnt_rd );
      $display("PROFILE_CNT_WR     : %-d", profile_cnt_wr );
    end
    endtask

   //===========================================================================
