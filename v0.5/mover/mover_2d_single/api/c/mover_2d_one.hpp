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
#include "mover_2d_one_core.h"

//------------------------------------------------------------------------------
#if defined(DEBUG)||defined(RIGOR)
#define PRINTF(format, ...) printf("%s(): " format, __func__, ##__VA_ARGS__)
#else
#define PRINTF(...) do { } while (0)
#endif

namespace dlb { // deep learning blocks

//------------------------------------------------------------------------------
// It fills a region of HW memory with the given value.
template<class TYPE=int32_t>
void MoverFill2d
(     const uint64_t  hw_addr // width x height
    , const uint16_t  width // num of items
    , const uint16_t  height // num of items
    , const TYPE      value // value of pattern (an item)
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
        PRINTF("hw addr  =%lld\n", (unsigned long long)hw_addr);
        PRINTF("width    =%d\n", width);
        PRINTF("height   =%d\n", height);
        fflush(stderr); fflush(stdout);
      #undef QuoteMacro
      #undef QuoteIdent
    }

    if (performance) mover_profile_init();
    mover_fill_set((uint64_t)hw_addr
                  ,(uint16_t)width
                  ,(uint16_t)height
                  ,(uint32_t)*(uint32_t*)&value);
    mover_go_wait( interrupt   // const uint32_t ie
                 , 1); // const uint32_t blocking

    if (interrupt) {
        uint8_t ip, ie;
        mover_get_interrupt(&ip, &ie);
        if ((ip==0)||(ie==0)) PRINTF("interrupt assertion error.\n");
        mover_clear_interrupt();
        mover_get_interrupt(&ip, &ie);
        if (ip==1) PRINTF("interrupt de-assertion error.\n");
    }

    if (performance) {
        uint32_t profile_cycles ;
        uint32_t profile_cnt_rd ;
        uint32_t profile_cnt_wr ;
        mover_profile_get(&profile_cycles
                         , NULL
                         ,&profile_cnt_rd
                         ,&profile_cnt_wr);
        PRINTF("PROFILE CYCLES  %d\n", profile_cycles );
        PRINTF("PRFILE CNT RD   %d\n", profile_cnt_rd );
        PRINTF("PRFILE CNT WR   %d\n", profile_cnt_wr );
    }

    if (rigor) {
        TYPE *data_mem  = (TYPE*)calloc(width*height, sizeof(TYPE));
        mover_read_block_from_hw( (uint8_t*)data_mem
                                , (uint64_t)hw_addr
                                , width*height*sizeof(TYPE));

        int miss=0;
        int idx=0;
        for (int i=0; i<height; i++) {
        for (int j=0; j<width; j++) {
            if (data_mem[idx]!=value) {
                miss++;
            }
            idx++;
        }}
        if (miss>0) PRINTF("mis-matches: %d\n", miss);
        else        PRINTF("all-matches (OK).\n");

        if (data_mem!=NULL) free(data_mem);
    }
}

//------------------------------------------------------------------------------
// Copy a block of hw memory from one location to the other location.
template<class TYPE=int32_t>
void MoverCopy2d
(     const uint64_t  hw_dst_addr
    , const uint64_t  hw_src_addr
    , const uint16_t  width
    , const uint16_t  height
    , const uint8_t   activ_func
    , const uint32_t  activ_param
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
        PRINTF("width  =%d\n", width);
        PRINTF("height =%d\n", height);
        fflush(stderr); fflush(stdout);
      #undef QuoteMacro
      #undef QuoteIdent
    }

    if (performance) mover_profile_init();
    mover_copy_set((uint64_t)hw_dst_addr
                  ,(uint64_t)hw_src_addr
                  ,(uint16_t)width
                  ,(uint16_t)height
                  ,activ_func
                  ,activ_param);
    mover_go_wait( interrupt   // const uint32_t ie
                 , 1); // const uint32_t blocking

    if (interrupt) {
        uint8_t ip, ie;
        mover_get_interrupt(&ip, &ie);
        if ((ip==0)||(ie==0)) PRINTF("interrupt assertion error.\n");
        mover_clear_interrupt();
        mover_get_interrupt(&ip, &ie);
        if (ip==1) PRINTF("interrupt de-assertion error.\n");
    }

    if (performance) {
        uint32_t profile_cycles ;
        uint32_t profile_cnt_rd ;
        uint32_t profile_cnt_wr ;
        mover_profile_get(&profile_cycles
                         , NULL
                         ,&profile_cnt_rd
                         ,&profile_cnt_wr);
        PRINTF("PROFILE CYCLES  %d\n", profile_cycles );
        PRINTF("PRFILE CNT RD   %d\n", profile_cnt_rd );
        PRINTF("PRFILE CNT WR   %d\n", profile_cnt_wr );
    }

    if (rigor) {
        TYPE *src_data_mem  = (TYPE*)calloc(width*height, sizeof(TYPE));
        mover_read_block_from_hw( (uint8_t*)src_data_mem
                                , (uint64_t)hw_src_addr
                                , width*height*sizeof(TYPE));
        TYPE *dst_data_mem  = (TYPE*)calloc(width*height, sizeof(TYPE));
        mover_read_block_from_hw( (uint8_t*)dst_data_mem
                                , (uint64_t)hw_dst_addr
                                , width*height*sizeof(TYPE));

        int miss=0;
        int idx=0;
        for (int i=0; i<height; i++) {
        for (int j=0; j<width; j++) {
            if (src_data_mem[idx]!=dst_data_mem[idx]) {
                miss++;
            }
            idx++;
        }}
        if (miss>0) PRINTF("mis-match: %d\n", miss);
        else        PRINTF("match: (OK).\n");

        if (src_data_mem!=NULL) free(src_data_mem);
        if (dst_data_mem!=NULL) free(dst_data_mem);
    }
}

//------------------------------------------------------------------------------
template<class TYPE=int32_t>
void MoverResidual2d
(     const uint64_t  hw_dst_addr
    , const uint64_t  hw_srcA_addr
    , const uint64_t  hw_srcB_addr
    , const uint16_t  width
    , const uint16_t  height
    , const uint8_t   activ_func
    , const uint32_t  activ_param
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
        PRINTF("width  =%d\n", width);
        PRINTF("height =%d\n", height);
        fflush(stderr); fflush(stdout);
      #undef QuoteMacro
      #undef QuoteIdent
    }

    if (performance) mover_profile_init();
    mover_residual_set((uint64_t)hw_dst_addr
                      ,(uint64_t)hw_srcA_addr
                      ,(uint64_t)hw_srcB_addr
                      ,(uint16_t)width
                      ,(uint16_t)height
                      ,activ_func
                      ,activ_param);
    mover_go_wait( interrupt   // const uint32_t ie
                 , 1); // const uint32_t blocking

    if (interrupt) {
        uint8_t ip, ie;
        mover_get_interrupt(&ip, &ie);
        if ((ip==0)||(ie==0)) PRINTF("interrupt assertion error.\n");
        mover_clear_interrupt();
        mover_get_interrupt(&ip, &ie);
        if (ip==1) PRINTF("interrupt de-assertion error.\n");
    }

    if (performance) {
        uint32_t profile_cycles ;
        uint32_t profile_res_ovr;
        uint32_t profile_cnt_rd ;
        uint32_t profile_cnt_wr ;
        mover_profile_get(&profile_cycles
                         ,&profile_res_ovr
                         ,&profile_cnt_rd
                         ,&profile_cnt_wr);
        PRINTF("PROFILE CYCLES  %d\n", profile_cycles );
        PRINTF("PRFILE CNT RD   %d\n", profile_cnt_rd );
        PRINTF("PRFILE CNT WR   %d\n", profile_cnt_wr );
        PRINTF("overflow RES    %d\n", profile_res_ovr);
    }
}

//------------------------------------------------------------------------------
template<class TYPE=int32_t>
void MoverConcat02d
(     const uint64_t  hw_dst_addr
    , const uint64_t  hw_srcA_addr
    , const uint64_t  hw_srcB_addr
    , const uint16_t  srcA_width
    , const uint16_t  srcA_height
    , const uint16_t  srcB_width
    , const uint16_t  srcB_height
    , const uint16_t  dst_width
    , const uint16_t  dst_height
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
        PRINTF("inA_width  =%d\n", srcA_width);
        PRINTF("inA_height =%d\n", srcA_height);
        PRINTF("inB_width  =%d\n", srcB_width);
        PRINTF("inB_height =%d\n", srcB_height);
        fflush(stderr); fflush(stdout);
      #undef QuoteMacro
      #undef QuoteIdent
    }

    if (performance) mover_profile_init();
    mover_concat0_set ((uint64_t)hw_dst_addr
                      ,(uint16_t)dst_width
                      ,(uint16_t)dst_height
                      ,(uint64_t)hw_srcA_addr
                      ,(uint16_t)srcA_width
                      ,(uint16_t)srcA_height
                      ,(uint64_t)hw_srcB_addr
                      ,(uint16_t)srcB_width
                      ,(uint16_t)srcB_height);
    mover_go_wait( interrupt   // const uint32_t ie
                 , 1); // const uint32_t blocking

    if (interrupt) {
        uint8_t ip, ie;
        mover_get_interrupt(&ip, &ie);
        if ((ip==0)||(ie==0)) PRINTF("interrupt assertion error.\n");
        mover_clear_interrupt();
        mover_get_interrupt(&ip, &ie);
        if (ip==1) PRINTF("interrupt de-assertion error.\n");
    }

    if (performance) {
        uint32_t profile_cycles ;
        uint32_t profile_cnt_rd ;
        uint32_t profile_cnt_wr ;
        mover_profile_get(&profile_cycles
                         , NULL
                         ,&profile_cnt_rd
                         ,&profile_cnt_wr);
        PRINTF("PROFILE CYCLES  %d\n", profile_cycles );
        PRINTF("PRFILE CNT RD   %d\n", profile_cnt_rd );
        PRINTF("PRFILE CNT WR   %d\n", profile_cnt_wr );
    }
}

//------------------------------------------------------------------------------
template<class TYPE=int32_t>
void MoverConcat12d
(     const uint64_t  hw_dst_addr
    , const uint64_t  hw_srcA_addr
    , const uint64_t  hw_srcB_addr
    , const uint16_t  srcA_width
    , const uint16_t  srcA_height
    , const uint16_t  srcB_width
    , const uint16_t  srcB_height
    , const uint16_t  dst_width
    , const uint16_t  dst_height
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
        PRINTF("inA_width  =%d\n", srcA_width);
        PRINTF("inA_height =%d\n", srcA_height);
        PRINTF("inB_width  =%d\n", srcB_width);
        PRINTF("inB_height =%d\n", srcB_height);
        fflush(stderr); fflush(stdout);
      #undef QuoteMacro
      #undef QuoteIdent
    }

    if (performance) mover_profile_init();
    mover_concat1_set ((uint64_t)hw_dst_addr
                      ,(uint16_t)dst_width
                      ,(uint16_t)dst_height
                      ,(uint64_t)hw_srcA_addr
                      ,(uint16_t)srcA_width
                      ,(uint16_t)srcA_height
                      ,(uint64_t)hw_srcB_addr
                      ,(uint16_t)srcB_width
                      ,(uint16_t)srcB_height);
    mover_go_wait( interrupt   // const uint32_t ie
                 , 1); // const uint32_t blocking

    if (interrupt) {
        uint8_t ip, ie;
        mover_get_interrupt(&ip, &ie);
        if ((ip==0)||(ie==0)) PRINTF("interrupt assertion error.\n");
        mover_clear_interrupt();
        mover_get_interrupt(&ip, &ie);
        if (ip==1) PRINTF("interrupt de-assertion error.\n");
    }

    if (performance) {
        uint32_t profile_cycles ;
        uint32_t profile_cnt_rd ;
        uint32_t profile_cnt_wr ;
        mover_profile_get(&profile_cycles
                         , NULL
                         ,&profile_cnt_rd
                         ,&profile_cnt_wr);
        PRINTF("PROFILE CYCLES  %d\n", profile_cycles );
        PRINTF("PRFILE CNT RD   %d\n", profile_cnt_rd );
        PRINTF("PRFILE CNT WR   %d\n", profile_cnt_wr );
    }
}

} // namespace dlb

#undef PRINTF

//------------------------------------------------------------------------------
// Revision History
//
// 2021.08.20: Start by Ando Ki (adki@future-ds.com)
//------------------------------------------------------------------------------
