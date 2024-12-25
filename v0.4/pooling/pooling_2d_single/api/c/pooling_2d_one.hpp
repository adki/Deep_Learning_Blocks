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
#include <stdio.h>
#include <stdlib.h>
#include "pooling_2d_one_core.h"

//------------------------------------------------------------------------------
#if defined(DEBUG)||defined(RIGOR)
#define PRINTF(format, ...) printf("%s(): " format, __func__, ##__VA_ARGS__)
#else
#define PRINTF(...) do { } while (0)
#endif

namespace dlb { // deep learning blocks

//------------------------------------------------------------------------------
// It calls a hardware 2D pooling that handles single-out-channel/single-in-channel.
// It uses SW data if 'sw_out/in_data' is not null after copying data to the hw memory.
// It uses HW data if 'sw_out/in_data' is null in order to support hw-in-memory data.
//
template<class TYPE=int32_t>
void Pooling2d
(           TYPE * const sw_out_data // out_channel x out_size x out_size
    , const TYPE * const sw_in_data  // in_channel x in_size x in_size
    , const uint8_t   command        // pooling command
    , const uint64_t  hw_result_addr  // out_channel x out_size x out_size
    , const uint64_t  hw_feature_addr // in_channel x in_size x in_size
    , const uint16_t  out_size    // only for square matrix
    , const uint16_t  in_size     // only for square matrix
    , const uint8_t   kernel_size // only for square matrix
    , const uint16_t  channel     // number of input/output channels
    , const uint8_t   stride=1
    , const uint8_t   padding=0
    , const int       interrupt=0 // interrupt enabled if 1
    , const int rigor=0
    , const int verbose=0
    , const int performance=0
)
{
    if (verbose) {
      #define QuoteIdent(ident) #ident
      #define QuoteMacro(macro) QuoteIdent(macro)
      //PRINTFF("data type  =%s\n", QuoteMacro(TYPE));
      //PRINTFF("data type  =%s\n", typeid(TYPE).name());
        PRINTF("out_size   =%d\n", out_size    );
        PRINTF("in_size    =%d\n", in_size     );
        PRINTF("kernel_size=%d\n", kernel_size );
        PRINTF("channel    =%d\n", channel     );
        PRINTF("stride     =%d\n", stride      );
        PRINTF("padding    =%d\n", padding     );
        fflush(stderr); fflush(stdout);
      #undef QuoteMacro
      #undef QuoteIdent
    }

    if (rigor) {
        assert (channel>0);
        assert (out_size==(((in_size-kernel_size+2*padding)/stride)+1));
        assert ((kernel_size%2)==0);
        assert (stride>0);
        assert (padding>=0);
        assert (padding<=(kernel_size/2));
    }

    if (sw_in_data!=NULL) {
        pool_write_block_to_hw( (uint64_t)hw_feature_addr
                              , (uint8_t*)sw_in_data
                              , channel*in_size*in_size*sizeof(TYPE));
    }

    uint16_t feature_leng = kernel_size;
    uint16_t result_leng  = kernel_size;
    if (performance) { pool_profile_init(); }
    pool_set((uint8_t )command      // const uint8_t  command
            ,(uint64_t)hw_result_addr  // const uint64_t result_addr
            ,(uint16_t)result_leng  // const uint16_t result_leng
            ,(uint64_t)hw_feature_addr // const uint64_t feature_addr
            ,(uint16_t)in_size      // const uint16_t feature_width
            ,(uint16_t)in_size      // const uint16_t feature_height
            ,(uint8_t )stride       // const uint8_t  feature_stride
            ,(uint8_t )padding      // const uint8_t  feature_padding_pre
            ,(uint8_t )padding      // const uint8_t  feature_padding_post
            ,(uint16_t)feature_leng // const uint16_t feature_leng
            ,(uint16_t)channel      // const uint16_t feature_channel
            ,(uint8_t )kernel_size  // const uint8_t  kernel_width
            ,(uint8_t )kernel_size);// const uint8_t  kernel_height
    pool_go_wait( interrupt   // const uint32_t ie
                , 1); // const uint32_t blocking

    if (interrupt) {
        uint8_t ip, ie;
        pool_get_interrupt(&ip, &ie);
        if ((ip==0)||(ie==0)) PRINTF("interrupt assertion error.\n");
        pool_clear_interrupt();
        pool_get_interrupt(&ip, &ie);
        if (ip==1) PRINTF("interrupt de-assertion error.\n");
    }

    if (sw_out_data!=NULL) {
        pool_read_block_from_hw( (uint8_t*)sw_out_data
                               , (uint64_t)hw_result_addr
                               , channel*out_size*out_size*sizeof(TYPE));
    }

    if (performance) {
        uint32_t profile_cycles;
        uint32_t profile_cnt_rd;
        uint32_t profile_cnt_wr;
        pool_profile_get( &profile_cycles
                        , &profile_cnt_rd
                        , &profile_cnt_wr);
        PRINTF("PROFILE CYCLES %d\n", profile_cycles);
        PRINTF("PROFILE CNT RD %d\n", profile_cnt_rd);
        PRINTF("PROFILE CNT WR %d\n", profile_cnt_wr);
    }

    if (rigor) {
        if (sw_in_data!=NULL) {
            TYPE *in_data_mem  = (TYPE*)calloc(channel*in_size*in_size, sizeof(TYPE));
            pool_read_block_from_hw( (uint8_t*)in_data_mem
                                   , (uint64_t)hw_feature_addr
                                   , channel*in_size*in_size*sizeof(TYPE));
            int miss=0;
            int idx=0;
            for (int i=0; i<channel; i++) {
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
    }
}

} // namespace dlb

#undef PRINTF

//------------------------------------------------------------------------------
// Revision History
//
// 2021.08.20: Start by Ando Ki (adki@future-ds.com)
//------------------------------------------------------------------------------
