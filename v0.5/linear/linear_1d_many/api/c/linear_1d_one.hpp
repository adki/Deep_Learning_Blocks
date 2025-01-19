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
#include "linear_1d_one_core.h"

//------------------------------------------------------------------------------
#if defined(DEBUG)||defined(RIGOR)
#define PRINTF(format, ...) printf("%s(): " format, __func__, ##__VA_ARGS__)
#else
#define PRINTF(...) do { } while (0)
#endif

namespace dlb { // deep learning blocks

//------------------------------------------------------------------------------
//                             (transposed matrix)
//   |<--in_size--------->|   |<--in_size--------->|     |<--out_size---->|
//   +--------------------+   +--------------------+--   +----------------+
//   | in_data            | x | weight             | | + | bias           |
//   +--------------------+   |                    | |   +----------------+
//                            |                    | |
//                            |                    | |out_size
//                            |                    | |
//                            |                    | |
//                            +--------------------+--
// It calls a hardware 1D linear that handles single-out-channel/single-in-channel.
// It uses SW data if 'sw_out/in_data' is not null after copying data to the hw memory.
// It uses HW data if 'sw_out/in_data' is null in order to support hw-in-memory data.
//
template<class TYPE=int32_t>
void Linear1d
(           TYPE * const sw_out_data // out_size
    , const TYPE * const sw_in_data  // in_size
    , const TYPE * const sw_weight   // out_size x in_size
    , const TYPE * const sw_bias     // out_size
    , const uint64_t  hw_result_addr // out_size
    , const uint64_t  hw_feature_addr// in_size
    , const uint64_t  hw_weight_addr // out_size x in_size
    , const uint64_t  hw_bias_addr   // out_size
    , const uint16_t  out_size
    , const uint16_t  in_size
    , const uint16_t  bias_size   // should be 0 or out_size
    , const uint8_t   activ_func
    , const uint32_t  activ_param
    , const int       interrupt=0 // interrupt enabled when 1
    , const int       rigor=0     // check rigorously when 1
    , const int       verbose=0   // verbose level
    , const int       performance=0
)
{
    if (verbose) {
      #define QuoteIdent(ident) #ident
      #define QuoteMacro(macro) QuoteIdent(macro)
      //PRINTF("data type  =%s\n",    QuoteMacro(TYPE));
      //PRINTF("data type  =%s\n",    typeid(TYPE).name());
        PRINTF("out_size   =%d\n",    out_size );
        PRINTF("in_size    =%d\n",    in_size  );
        PRINTF("weight_size=%dx%d\n", out_size, in_size);
        PRINTF("bias_size  =%d\n",    bias_size   );
        fflush(stderr); fflush(stdout);
      #undef QuoteMacro
      #undef QuoteIdent
    }
    if (rigor) {
        assert (in_size>=4); // make block_size 1 at least
        assert (out_size>0);
        assert ((bias_size==0)||(out_size==bias_size));
    }

    if (sw_in_data!=NULL) {
        linear_write_block_to_hw( (uint64_t)hw_feature_addr // dst in HW memory
                                , (uint8_t*)sw_in_data // src in SW memory
                                , in_size*sizeof(TYPE));
    }
    if (sw_weight!=NULL) {
        linear_write_block_to_hw( (uint64_t)hw_weight_addr // dst in HW memory
                                , (uint8_t*)sw_weight // src in SW memory
                                , in_size*out_size*sizeof(TYPE));
    }
    if (sw_bias!=NULL) {
        linear_write_block_to_hw( (uint64_t)hw_bias_addr // dst in HW memory
                                , (uint8_t*)sw_bias // src in SW memory
                                , out_size*sizeof(TYPE));
    }

    // HW address
    TYPE *hw_previous_addr = (TYPE*)hw_result_addr;
    uint16_t input_size    = in_size;
    uint16_t weight_width  = input_size; // transposed matrix
    uint16_t weight_height = out_size; // transposed matrix
    uint16_t result_size   = out_size;
    uint16_t input_leng    = 8;
    uint16_t weight_leng   = input_leng;
    uint16_t result_leng   = input_size;

    linear_init();
    if (performance) linear_profile_init();
    linear_set((uint64_t)hw_result_addr  // const uint64_t result_addr
              ,(uint16_t)result_size     // const uint16_t result_size
              ,(uint16_t)result_leng     // const uint16_t result_leng
              ,(uint64_t)hw_feature_addr // const uint64_t input_addr
              ,(uint16_t)input_size      // const uint16_t input_size
              ,(uint16_t)input_leng      // const uint16_t input_leng
              ,(uint64_t)hw_weight_addr  // const uint64_t weight_addr
              ,(uint16_t)weight_width    // const uint16_t weight_width
              ,(uint16_t)weight_height   // const uint16_t weight_height
              ,(uint16_t)weight_leng     // const uint16_t weight_leng
              ,(uint64_t)hw_bias_addr    // const uint64_t bias_addr
              ,(uint16_t)bias_size       // const uint16_t bias_size
              ,(uint8_t )activ_func      // const uint8_t  activ_func
              ,(uint32_t)activ_param  ); // const uint32_t activ_param );

    linear_go_wait( interrupt // ie
                  , 1 ); // blocking

    if (interrupt) {
        uint8_t ip, ie;
        linear_get_interrupt(&ip, &ie);
        if ((ip==0)||(ie==0)) PRINTF("interrupt assertion error.\n");
        linear_clear_interrupt();
        linear_get_interrupt(&ip, &ie);
        if (ip==1) PRINTF("interrupt de-assertion error.\n");
    }

    if (sw_out_data!=NULL) {
        linear_read_block_from_hw( (uint8_t*)sw_out_data
                                 , (uint64_t)hw_result_addr
                                 , out_size*sizeof(TYPE));
    }

    if (performance) {
        uint32_t profile_cycles ;
        uint32_t profile_mac_num;
        uint32_t profile_mac_ovr;
        uint32_t profile_bia_ovr;
        uint32_t profile_act_ovr;
        uint32_t profile_cnt_rd ;
        uint32_t profile_cnt_wr ;
        linear_profile_get(&profile_cycles
                          ,&profile_mac_num
                          ,&profile_mac_ovr
                          ,&profile_bia_ovr
                          ,&profile_act_ovr
                          ,&profile_cnt_rd
                          ,&profile_cnt_wr);
        PRINTF("PROFILE CYCLES  %d\n", profile_cycles );
        PRINTF("PROFILE MAC NUM %d\n", profile_mac_num);
        PRINTF("PRFILE CNT RD   %d\n", profile_cnt_rd );
        PRINTF("PRFILE CNT WR   %d\n", profile_cnt_wr );
        PRINTF("overflow MAC    %d\n", profile_mac_ovr);
        PRINTF("overflow BIAS   %d\n", profile_bia_ovr);
        PRINTF("overflow ACT    %d\n", profile_act_ovr);
    }

    if (rigor) {
        if (sw_in_data!=NULL) {
            TYPE *in_data_mem  = (TYPE*)calloc(in_size, sizeof(TYPE));
            linear_read_block_from_hw( (uint8_t*)in_data_mem
                                     , (uint64_t)hw_feature_addr
                                     , in_size*sizeof(TYPE));
            int miss=0;
            int idx=0;
            for (int i=0; i<in_size; i++) {
                if (in_data_mem[i]!=sw_in_data[i]) {
                    miss++;
                }
            }
            if (miss>0) PRINTF("input vector: %d\n", miss);
            else        PRINTF("input vector unchanged (OK).\n");
            if (in_data_mem!=NULL) free(in_data_mem);
        }

        if (sw_weight!=NULL) {
            TYPE *weight_mem   = (TYPE*)calloc(in_size*out_size, sizeof(TYPE));
            linear_read_block_from_hw( (uint8_t*)weight_mem
                                     , (uint64_t)hw_weight_addr
                                     , in_size*out_size*sizeof(TYPE));
            int miss=0;
            int idx=0;
            for (int i=0; i<out_size; i++) {
            for (int j=0; j<in_size; j++) {
                if (weight_mem[idx]!=sw_weight[idx]) {
                    miss++;
                }
                idx++;
            }}
            if (miss>0) PRINTF("weight: %d\n", miss);
            else        PRINTF("weight unchanged (OK).\n");
            if (weight_mem !=NULL) free(weight_mem );
        }

        if (sw_bias!=NULL) {
            TYPE *bias_mem     = (TYPE*)calloc(out_size, sizeof(TYPE));
            linear_read_block_from_hw( (uint8_t*)bias_mem
                                     , (uint64_t)hw_bias_addr
                                     , out_size*sizeof(TYPE));
            int miss=0;
            for (int i=0; i<bias_size; i++) {
                if (bias_mem[i]!=sw_bias[i]) {
                    miss++;
                }
            }
            if (miss>0) PRINTF("bias: %d\n", miss);
            else        PRINTF("bias unchanged (OK).\n");
            if (bias_mem   !=NULL) free(bias_mem   );
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
