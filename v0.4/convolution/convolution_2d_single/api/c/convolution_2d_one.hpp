#pragma once
//------------------------------------------------------------------------------
// Copyright (c) 2021 by Future Design Systems, Ltd.
// All right reserved.
//
// http://www.future-ds.com
//------------------------------------------------------------------------------
// VERSION = 2021.08.20.
//------------------------------------------------------------------------------
#include <assert.h>
#include "convolution_2d_one_core.h"

//------------------------------------------------------------------------------
#if defined(DEBUG)||defined(RIGOR)
#define PRINTF(format, ...) printf("%s(): " format, __func__, ##__VA_ARGS__)
#else
#define PRINTF(...) do { } while (0)
#endif

namespace dlb { // deep learning block

//------------------------------------------------------------------------------
// It calls a hardware 2D convolution that handles single-out-channel/single-in-channel.
// It accumulates convolution results for multi-in-channel.
// It uses SW data if 'sw_out/in_data' is not null after copying data to the hw memory.
// It uses HW data if 'sw_out/in_data' is null in order to support hw-in-memory data.
//
template<class TYPE=int32_t>
void Convolution2d
(           TYPE * const sw_out_data // out_channel x out_size x out_size
    , const TYPE * const sw_in_data  // in_channel x in_size x in_size
    , const TYPE * const sw_kernel   // out_channel x in_channel x kernel_size x kernel_size
    , const TYPE * const sw_bias     // out_channel
    , const uint64_t  hw_result_addr // out_channel x out_size x out_size
    , const uint64_t  hw_feature_addr  // in_channel x in_size x in_size
    , const uint64_t  hw_kernel_addr // out_channel x in_channel x kernel_size x kernel_size
    , const uint16_t  out_size    // only for square matrix
    , const uint16_t  in_size     // only for square matrix
    , const uint8_t   kernel_size // only for square matrix
    , const uint16_t  bias_size   // out_channel
    , const uint16_t  in_channel  // number of input channels
    , const uint16_t  out_channel // number of filters (kernels)
    , const uint8_t   stride=1
    , const uint8_t   padding=0
    , const uint8_t   activ_func=0
    , const uint32_t  activ_param=0
    , const int       interrupt=0 // interrupt enabled when 1
    , const int rigor=0
    , const int verbose=0
    , const int performance=0 // check performance
)
{
    if (verbose) {
      #define QuoteIdent(ident) #ident
      #define QuoteMacro(macro) QuoteIdent(macro)
      //PRINTFF("data type  =%s\n", QuoteMacro(TYPE));
      //PRINTFF("data type  =%s\n", typeid(TYPE).name());
        PRINTF("hw_result_addr =%p\n", (void*)hw_result_addr );
        PRINTF("hw_feature_addr=%p\n", (void*)hw_feature_addr);
        PRINTF("hw_kernel_addr =%p\n", (void*)hw_kernel_addr );
        PRINTF("out_size   =%d\n", out_size   );
        PRINTF("in_size    =%d\n", in_size    );
        PRINTF("kernel_size=%d\n", kernel_size);
        PRINTF("bias_size  =%d\n", bias_size  );
        PRINTF("in_channel =%d\n", in_channel );
        PRINTF("out_channel=%d\n", out_channel);
        PRINTF("stride     =%d\n", stride     );
        PRINTF("padding    =%d\n", padding    );
        PRINTF("activ_func =%d\n", activ_func );
        PRINTF("activ_param=%d\n", activ_param);
        fflush(stderr); fflush(stdout);
      #undef QuoteMacro
      #undef QuoteIdent
    }

    if (rigor) {
        assert (in_channel>0);
        assert (out_channel>0);
        assert (out_size==(((in_size-kernel_size+2*padding)/stride)+1));
        assert ((kernel_size%2)==1);
        assert (stride>0);
        assert (padding>=0);
        assert (padding<=(kernel_size/2));
        assert ((bias_size==0)||(out_channel==bias_size));
    }

    if (sw_in_data!=NULL) {
        conv_write_block_to_hw( (uint64_t)hw_feature_addr // dst in HW memory
                              , (uint8_t*)sw_in_data // src in SW memory
                              , in_channel*in_size*in_size*sizeof(TYPE));
    }
    if (sw_kernel!=NULL) {
        conv_write_block_to_hw( (uint64_t)hw_kernel_addr // dst in HW memory
                              , (uint8_t*)sw_kernel // src in SW memory
                              , out_channel*in_channel*kernel_size*kernel_size*sizeof(TYPE));
    }
    TYPE *bias_addr    = (TYPE *)sw_bias;
    TYPE *feature_addr = (TYPE *)hw_feature_addr;
    TYPE *kernel_addr  = (TYPE *)hw_kernel_addr;
    TYPE *result_addr  = (TYPE *)hw_result_addr;
    TYPE *channel_addr = (TYPE *)0; // to accumulate
    uint32_t bias_value   = 0;
    uint8_t  kernel_leng  = kernel_size;
    uint16_t feature_leng = kernel_size;
    uint16_t result_leng  = kernel_size;
    uint16_t channel_leng = 0; // make none for the first.
    if (performance) { conv_profile_init(); }
    for (int oc=0; oc<out_channel; ++oc) {
        channel_leng = 0; // make none for the first.
        bias_value = (bias_size) ? *(uint32_t*)&sw_bias[oc] : 0;
        for (int ic=0; ic<in_channel; ++ic) {
            // conv_set only takes care of singe-channel and single kernel
#if defined(DEBUG)
PRINTF("out_channel=%d in_channel=%d\n", oc, ic);
#endif
            conv_set((uint64_t)result_addr  // const uint64_t result_addr
                    ,(uint16_t)result_leng  // const uint16_t result_leng
                    ,(uint64_t)feature_addr // const uint64_t feature_addr
                    ,(uint16_t)in_size      // const uint16_t feature_width
                    ,(uint16_t)in_size      // const uint16_t feature_height
                    ,(uint8_t )stride       // const uint8_t  feature_stride
                    ,(uint8_t )padding      // const uint8_t  feature_padding_pre
                    ,(uint8_t )padding      // const uint8_t  feature_padding_post
                    ,(uint16_t)feature_leng // const uint16_t feature_leng
                    ,(uint64_t)kernel_addr  // const uint64_t kernel_addr
                    ,(uint8_t )kernel_size  // const uint8_t  kernel_width
                    ,(uint8_t )kernel_size  // const uint8_t  kernel_height
                    ,(uint16_t)kernel_leng  // const uint16_t kernel_leng
                    ,(uint64_t)channel_addr // const uint64_t channel_addr
                    ,(uint16_t)channel_leng // const uint16_t channel_leng
                    ,(uint32_t)bias_value   // const uint32_t bias
                    ,(ic==(in_channel-1)) ? activ_func : 0// const uint8_t activ_func
                    ,(ic==(in_channel-1)) ? activ_param : 0// const uint32_t activ_param
                    );
            conv_go_wait( interrupt   // const uint32_t ie
                        , 1); // const uint32_t blocking
            feature_addr += in_size*in_size; // for the next in feature(in-channel)
            kernel_addr  += kernel_size*kernel_size; // for the next kernel
            channel_addr = result_addr; // make accumulate for the next in-channel
            channel_leng = result_leng; // make accumulate for the next in-channel
            bias_value   = 0; // make sure to add only once
        }
        result_addr  += out_size*out_size;
        bias_addr    += (bias_size) ? 1 : 0; // this is meaningless for this implementation
        feature_addr = (TYPE *)hw_feature_addr;
    }
    if (interrupt) {
        uint8_t ip, ie;
        conv_get_interrupt(&ip, &ie);
        if ((ip==0)||(ie==0)) PRINTF("interrupt assertion error.\n");
        conv_clear_interrupt();
        conv_get_interrupt(&ip, &ie);
        if (ip==1) PRINTF("interrupt de-assertion error.\n");
    }
    if (sw_out_data!=NULL) {
        conv_read_block_from_hw( (uint8_t*)sw_out_data // dst in SW memory
                               , (uint64_t)hw_result_addr // src in HW memory
                               , out_channel*out_size*out_size*sizeof(TYPE));
    }

    if (performance) {
        uint32_t profile_cycles ;
        uint32_t profile_mac_num;
        uint32_t profile_mac_ovr;
        uint32_t profile_chn_ovr;
        uint32_t profile_bia_ovr;
        uint32_t profile_act_ovr;
        uint32_t profile_cnt_rd ;
        uint32_t profile_cnt_wr ;
        conv_profile_get( &profile_cycles 
                        , &profile_mac_num
                        , &profile_mac_ovr
                        , &profile_chn_ovr
                        , &profile_bia_ovr
                        , &profile_act_ovr
                        , &profile_cnt_rd
                        , &profile_cnt_wr);
        PRINTF("PROFILE CYCLES  %d\n", profile_cycles );
        PRINTF("PROFILE MAC NUM %d\n", profile_mac_num);
        PRINTF("PRFILE CNT RD   %d\n", profile_cnt_rd );
        PRINTF("PRFILE CNT WR   %d\n", profile_cnt_wr );
        PRINTF("overflow MAC    %d\n", profile_mac_ovr);
        PRINTF("overflow CHN    %d\n", profile_chn_ovr);
        PRINTF("overflow BIA    %d\n", profile_bia_ovr);
        PRINTF("overflow ACT    %d\n", profile_act_ovr);
    }

    if (rigor) {
        if (sw_in_data!=NULL) {
            TYPE *in_data_mem = (TYPE*)calloc(in_channel*in_size*in_size, sizeof(TYPE));
            conv_read_block_from_hw( (uint8_t*)in_data_mem // dst in SW
                                   , (uint64_t)hw_feature_addr // src in HW
                                   , in_channel*in_size*in_size*sizeof(TYPE));
            int miss = 0;
            int idx=0;
            for (int i=0; i<in_channel; i++) {
            for (int j=0; j<in_size; j++) {
            for (int k=0; k<in_size; k++) {
                if (in_data_mem[idx]!=sw_in_data[idx]) {
                    miss++;
                }
                idx++;
            }}}
            if (miss>0) PRINTF("feature altered: %d\n", miss);
            else        PRINTF("feature unchanged (OK).\n");

            if (in_data_mem!=NULL) free(in_data_mem);
        }

        if (sw_kernel!=NULL) {
            TYPE *kernel_mem  = (TYPE*)calloc(out_channel*in_channel*kernel_size*kernel_size, sizeof(TYPE));
            conv_read_block_from_hw( (uint8_t*)kernel_mem
                                   , (uint64_t)hw_kernel_addr
                                   , out_channel*in_channel*kernel_size*kernel_size*sizeof(TYPE));
            int miss=0;
            int idx = 0;
            for (int a=0; a<out_channel; a++) {
            for (int b=0; b<in_channel; b++) {
            for (int c=0; c<kernel_size; c++) {
            for (int d=0; d<kernel_size; d++) {
                if (kernel_mem[idx]!=sw_kernel[idx]) {
                    miss++;
                }
                idx++;
            }}}}
            if (miss>0) PRINTF("kernel altered: %d\n", miss);
            else        PRINTF("kernel unchanged (OK).\n");
            if (kernel_mem!=NULL) free(kernel_mem);
        }
    }
}

} // namespace dlb

#undef PRINTF

//------------------------------------------------------------------------------
// Revision History
//
// 2021.08.20: Start by Ando Ki (adki@future-ds.com)
//------------------------------------------------------------------------------
