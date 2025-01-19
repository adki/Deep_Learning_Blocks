//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All rights are reserved by Ando Ki.
//------------------------------------------------------------------------------
// mover.cpp
//------------------------------------------------------------------------------
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include <iostream>

#include "defines_dpu.h"
#include "mover_2d_one.hpp" // Deep Learning Block API

// It should reflect 'DATA_TYPE/DATA_WIDTH/DATA_WIDTH_Q' macros
// in 'defines_system.v' file in HW.
#ifdef DATA_TYPE
#define TYPE DATA_TYPE
#else
#define TYPE int32_t
#endif

#define QuoteIdent(ident) #ident
#define QuoteMacro(macro) QuoteIdent(macro)
#define PRINTF(format, ...) printf("%s(): " format, __func__, ##__VA_ARGS__)

//------------------------------------------------------------------------------
int test_mover_2d_fill( uint32_t base, __attribute__((unused)) int test_level
                      , int verbose )
{
    extern int test_mover_2d_fill_core( uint16_t  width
                                      , uint16_t  height
                                      , TYPE      value
                                      , int       rigor
                                      , int       verbose );
    mover_set_addr((unsigned long int)base );
    #if defined(RIGOR)||defined(DEBUG)
    unsigned long int caddr = mover_get_addr();
    if (base!=(uint32_t)caddr) {
        PRINTF("mover_2d at 0x%08lX, but 0x%08X expected\n", caddr, base);
    }
    #endif
    #if defined(DEBUG)
    mover_version();
    mover_csr_test();
    #endif

    #if defined(RIGOR)||defined(DEBUG)
    if (mover_check_data_type(QuoteMacro(TYPE), sizeof(TYPE)*8, 0)) {
        char data_type[3];
        uint8_t Q, N;
        mover_get_config(data_type, &Q, &N, NULL, NULL);
        data_type[2]='\0'; // make normal string
        PRINTF("data type mis-match: \"%s:%d:%d\" \"%s\"\n",
                data_type, N, Q, QuoteMacro(TYPE));
    }
    #endif

    uint16_t  width =10;
    uint16_t  height=11;
    TYPE      value =(TYPE)0;
    int       rigor=1;

#ifndef  DPU_ADDR_BASE_MEM
//#warning DPU_ADDR_BASE_MEM should be defined.
#define  DPU_ADDR_BASE_MEM 0x00000000
#endif

    uint64_t hw_addr = (uint64_t)DPU_ADDR_BASE_MEM;

    PRINTF("================================\n");

    dlb::MoverFill2d<TYPE> ( hw_addr
                           , width
                           , height
                           , value
                           , 1
                           , rigor
                           , verbose);

    // check values
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
    if (miss>0) PRINTF("mis-matches: %d out of %d\n", miss, idx);
    else        PRINTF("all-matches (OK) %d.\n", idx);

    if (data_mem!=NULL) free(data_mem);

    return 0;
}

//------------------------------------------------------------------------------
int test_mover_2d_copy( uint32_t base, int test_level, int verbose )
{
    mover_set_addr((unsigned long int)base );
    #if defined(RIGOR)||defined(DEBUG)
    unsigned long int caddr = mover_get_addr();
    if (base!=(uint32_t)caddr) {
        PRINTF("mover_2d at 0x%08lX, but 0x%08X expected\n", caddr, base);
    }
    #endif
    #if defined(DEBUG)
    mover_version();
    mover_csr_test();
    #endif

    #if defined(RIGOR)||defined(DEBUG)
    if (mover_check_data_type(QuoteMacro(TYPE), sizeof(TYPE)*8, 0)) {
        char data_type[3];
        uint8_t Q, N;
        mover_get_config(data_type, &Q, &N, NULL, NULL);
        data_type[2]='\0'; // make normal string
        PRINTF("data type mis-match: \"%s:%d:%d\" \"%s\"\n",
                data_type, N, Q, QuoteMacro(TYPE));
    }
    #endif

    uint8_t  activ_func=ACTIV_FUNC_NOP;
    uint32_t activ_param=0;
    int rigor=1;

#ifndef  DPU_ADDR_BASE_MEM
//#warning DPU_ADDR_BASE_MEM should be defined.
#define  DPU_ADDR_BASE_MEM 0x00000000
#endif
    
    uint16_t width =10;
    uint16_t height=11;
    uint32_t align_size = ((width*height+3)/4)*4;
    TYPE *hw_src_addr = (TYPE*)DPU_ADDR_BASE_MEM;
    TYPE *hw_dst_addr = hw_src_addr + align_size;

    TYPE *src_data  = (TYPE*)calloc(width*height, sizeof(TYPE));
    int idx=0;
    for (int y=0; y<height; y++) {
    for (int x=0; x<width ; x++) {
        src_data[idx] = (TYPE)idx;
        idx++;
    }}

    PRINTF("================================\n");

    mover_write_block_to_hw( (uint64_t)hw_src_addr
                           , (uint8_t*)src_data
                           , width*height*sizeof(TYPE));

    dlb::MoverCopy2d<TYPE> ( (uint64_t)hw_dst_addr
                           , (uint64_t)hw_src_addr
                           , (uint16_t)width
                           , (uint16_t)height
                           , activ_func
                           , activ_param
                           , 1 // interrupt
                           , rigor
                           , verbose);

    // check values
    TYPE *dst_data  = (TYPE*)calloc(width*height, sizeof(TYPE));
    mover_read_block_from_hw( (uint8_t*)dst_data
                            , (uint64_t)hw_dst_addr
                            , width*height*sizeof(TYPE));

    int miss=0;
    int idy=0;
    for (int y=0; y<height; y++) {
    for (int x=0; x<width ; x++) {
        if (src_data[idy]!=dst_data[idy]) {
            miss++;
PRINTF("[%d] 0x%08X:%08X\n", idy, *(unsigned int *)&src_data[idy], *(unsigned int *)&dst_data[idy]);
        }
        idy++;
    }}
    if (miss>0) PRINTF("mis-match: %d out of %d\n", miss, idy);
    else        PRINTF("mached (OK). %d\n", idy);

    if (src_data!=NULL) free(src_data);
    if (dst_data!=NULL) free(dst_data);

    return 0;
}

//------------------------------------------------------------------------------
int test_mover_2d_residual( uint32_t base, int test_level, int verbose )
{
    mover_set_addr((unsigned long int)base );
    #if defined(RIGOR)||defined(DEBUG)
    unsigned long int caddr = mover_get_addr();
    if (base!=(uint32_t)caddr) {
        PRINTF("mover_2d at 0x%08lX, but 0x%08X expected\n", caddr, base);
    }
    #endif
    #if defined(DEBUG)
    mover_version();
    mover_csr_test();
    #endif

    #if defined(RIGOR)||defined(DEBUG)
    if (mover_check_data_type(QuoteMacro(TYPE), sizeof(TYPE)*8, 0)) {
        char data_type[3];
        uint8_t Q, N;
        mover_get_config(data_type, &Q, &N, NULL, NULL);
        data_type[2]='\0'; // make normal string
        PRINTF("data type mis-match: \"%s:%d:%d\" \"%s\"\n",
                data_type, N, Q, QuoteMacro(TYPE));
    }
    #endif

    uint8_t  activ_func=0;
    uint32_t activ_param=0;
    int rigor=1;

#ifndef  DPU_ADDR_BASE_MEM
//#warning DPU_ADDR_BASE_MEM should be defined.
#define  DPU_ADDR_BASE_MEM 0x00000000
#endif
    
    uint16_t width =10;
    uint16_t height=11;
    uint32_t align_size = ((width*height+3)/4)*4;
    TYPE *hw_srcA_addr = (TYPE*)DPU_ADDR_BASE_MEM;
    TYPE *hw_srcB_addr = hw_srcA_addr + align_size;
    TYPE *hw_dst_addr = hw_srcB_addr + align_size;

    TYPE *srcA_data  = (TYPE*)calloc(width*height, sizeof(TYPE));
    int idx=0;
    for (int y=0; y<height; y++) {
    for (int x=0; x<width ; x++) {
        srcA_data[idx] = (TYPE)idx;
        idx++;
    }}
    TYPE *srcB_data  = (TYPE*)calloc(width*height, sizeof(TYPE));
    int idy=0;
    for (int y=0; y<height; y++) {
    for (int x=0; x<width ; x++) {
      //srcB_data[idy] = (TYPE)(width*height-idy);
        srcB_data[idy] = (TYPE)idy;
        idy++;
    }}

    PRINTF("================================\n");

    mover_write_block_to_hw( (uint64_t)hw_srcA_addr
                           , (uint8_t*)srcA_data
                           , width*height*sizeof(TYPE));

    mover_write_block_to_hw( (uint64_t)hw_srcB_addr
                           , (uint8_t*)srcB_data
                           , width*height*sizeof(TYPE));

    dlb::MoverResidual2d<TYPE> ( (uint64_t)hw_dst_addr
                               , (uint64_t)hw_srcA_addr
                               , (uint64_t)hw_srcB_addr
                               , (uint16_t)width
                               , (uint16_t)height
                               , activ_func
                               , activ_param
                               , 1 // interrupt
                               , rigor
                               , verbose);

    // check values
    TYPE *dst_data  = (TYPE*)calloc(width*height, sizeof(TYPE));
    mover_read_block_from_hw( (uint8_t*)dst_data
                            , (uint64_t)hw_dst_addr
                            , width*height*sizeof(TYPE));

    int miss=0;
    int idz=0;
    for (int y=0; y<height; y++) {
    for (int x=0; x<width ; x++) {
        if ((srcA_data[idz]+srcB_data[idz])!=dst_data[idz]) miss++;
        idz++;
    }}
    if (miss>0) PRINTF("mis-match: %d out of %d\n", miss, idz);
    else        PRINTF("mached (OK). %d\n", idz);

    if (srcA_data!=NULL) free(srcA_data);
    if (srcB_data!=NULL) free(srcB_data);
    if (dst_data!=NULL) free(dst_data);

    return 0;
}

//------------------------------------------------------------------------------
int test_mover_2d_concat0( uint32_t base, int test_level, int verbose )
{
    mover_set_addr((unsigned long int)base );
    #if defined(RIGOR)||defined(DEBUG)
    unsigned long int caddr = mover_get_addr();
    if (base!=(uint32_t)caddr) {
        PRINTF("mover_2d at 0x%08lX, but 0x%08X expected\n", caddr, base);
    }
    #endif
    #if defined(DEBUG)
    mover_version();
    mover_csr_test();
    #endif

    #if defined(RIGOR)||defined(DEBUG)
    if (mover_check_data_type(QuoteMacro(TYPE), sizeof(TYPE)*8, 0)) {
        char data_type[3];
        uint8_t Q, N;
        mover_get_config(data_type, &Q, &N, NULL, NULL);
        data_type[2]='\0'; // make normal string
        PRINTF("data type mis-match: \"%s:%d:%d\" \"%s\"\n",
                data_type, N, Q, QuoteMacro(TYPE));
    }
    #endif

    int rigor=1;

#ifndef  DPU_ADDR_BASE_MEM
//#warning DPU_ADDR_BASE_MEM should be defined.
#define  DPU_ADDR_BASE_MEM 0x00000000
#endif
    
    uint16_t srcA_width =10;
    uint16_t srcA_height=11;
    uint16_t srcB_width =srcA_width;
    uint16_t srcB_height=12;
    uint32_t align_size = ((srcA_width*srcA_height+3)/4)*4;
    TYPE *hw_srcA_addr = (TYPE*)DPU_ADDR_BASE_MEM;
    TYPE *hw_srcB_addr = hw_srcA_addr + align_size;
    align_size = ((srcB_width*srcB_height+3)/4)*4;
    TYPE *hw_dst_addr = hw_srcB_addr + align_size;

    TYPE *srcA_data  = (TYPE*)calloc(srcA_width*srcA_height, sizeof(TYPE));
    int idx=0;
    for (int y=0; y<srcA_height; y++) {
    for (int x=0; x<srcA_width ; x++) {
        srcA_data[idx] = (TYPE)idx;
        idx++;
    }}
    TYPE *srcB_data  = (TYPE*)calloc(srcB_width*srcB_height, sizeof(TYPE));
    int idy=0;
    for (int y=0; y<srcB_height; y++) {
    for (int x=0; x<srcB_width ; x++) {
        srcB_data[idy] = (TYPE)(srcB_width*srcB_height-idy);
        idy++;
    }}

    PRINTF("================================\n");

    mover_write_block_to_hw( (uint64_t)hw_srcA_addr
                           , (uint8_t*)srcA_data
                           , srcA_width*srcA_height*sizeof(TYPE));

    mover_write_block_to_hw( (uint64_t)hw_srcB_addr
                           , (uint8_t*)srcB_data
                           , srcB_width*srcB_height*sizeof(TYPE));

    dlb::MoverConcat02d<TYPE> ( (uint64_t)hw_dst_addr
                              , (uint64_t)hw_srcA_addr
                              , (uint64_t)hw_srcB_addr
                              , (uint16_t)srcA_width
                              , (uint16_t)srcA_height
                              , (uint16_t)srcB_width
                              , (uint16_t)srcB_height
                              , (uint16_t)srcA_width
                              , (uint16_t)(srcA_height+srcB_height)
                              , 1 // interrupt
                              , rigor
                              , verbose);

    // check values
    TYPE *dst_data  = (TYPE*)calloc(srcA_width*srcA_height+srcB_width*srcB_height, sizeof(TYPE));
    mover_read_block_from_hw( (uint8_t*)dst_data
                            , (uint64_t)hw_dst_addr
                            , srcA_width*srcA_height*sizeof(TYPE)+srcB_width*srcB_height*sizeof(TYPE));

    int miss=0;
    int idz=0;
    for (int y=0; y<srcA_height; y++) {
    for (int x=0; x<srcA_width ; x++) {
        if (srcA_data[idz]!=dst_data[idz]) miss++;
        idz++;
    }}
    int idw=0;
    for (int y=0; y<srcB_height; y++) {
    for (int x=0; x<srcB_width ; x++) {
        if (srcB_data[idw]!=dst_data[idz]) miss++;
        idw++;
        idz++;
    }}
    if (miss>0) PRINTF("mis-match: %d out of %d\n", miss, idz);
    else        PRINTF("mached (OK). %d\n", idz);

    if (srcA_data!=NULL) free(srcA_data);
    if (srcB_data!=NULL) free(srcB_data);
    if (dst_data!=NULL) free(dst_data);

    return 0;
}

//------------------------------------------------------------------------------
int test_mover_2d_concat1( uint32_t base, int test_level, int verbose )
{
    mover_set_addr((unsigned long int)base );
    #if defined(RIGOR)||defined(DEBUG)
    unsigned long int caddr = mover_get_addr();
    if (base!=(uint32_t)caddr) {
        PRINTF("mover_2d at 0x%08lX, but 0x%08X expected\n", caddr, base);
    }
    #endif
    #if defined(DEBUG)
    mover_version();
    mover_csr_test();
    #endif

    #if defined(RIGOR)||defined(DEBUG)
    if (mover_check_data_type(QuoteMacro(TYPE), sizeof(TYPE)*8, 0)) {
        char data_type[3];
        uint8_t Q, N;
        mover_get_config(data_type, &Q, &N, NULL, NULL);
        data_type[2]='\0'; // make normal string
        PRINTF("data type mis-match: \"%s:%d:%d\" \"%s\"\n",
                data_type, N, Q, QuoteMacro(TYPE));
    }
    #endif

    int rigor=1;

#ifndef  DPU_ADDR_BASE_MEM
//#warning DPU_ADDR_BASE_MEM should be defined.
#define  DPU_ADDR_BASE_MEM 0x00000000
#endif
    
    uint16_t srcA_width =10;
    uint16_t srcA_height=11;
    uint16_t srcB_width =14;
    uint16_t srcB_height=srcA_height;
    uint32_t align_size = ((srcA_width*srcA_height+3)/4)*4;
    TYPE *hw_srcA_addr = (TYPE*)DPU_ADDR_BASE_MEM;
    TYPE *hw_srcB_addr = hw_srcA_addr + align_size;
    align_size = ((srcB_width*srcB_height+3)/4)*4;
    TYPE *hw_dst_addr = hw_srcB_addr + align_size;

    TYPE *srcA_data  = (TYPE*)calloc(srcA_width*srcA_height, sizeof(TYPE));
    int idx=0;
    for (int y=0; y<srcA_height; y++) {
    for (int x=0; x<srcA_width ; x++) {
        srcA_data[idx] = (TYPE)idx;
        idx++;
    }}
    TYPE *srcB_data  = (TYPE*)calloc(srcB_width*srcB_height, sizeof(TYPE));
    int idy=0;
    for (int y=0; y<srcB_height; y++) {
    for (int x=0; x<srcB_width ; x++) {
        srcB_data[idy] = (TYPE)(srcB_width*srcB_height-idy);
        idy++;
    }}

    PRINTF("================================\n");

    mover_write_block_to_hw( (uint64_t)hw_srcA_addr
                           , (uint8_t*)srcA_data
                           , srcA_width*srcA_height*sizeof(TYPE));

    mover_write_block_to_hw( (uint64_t)hw_srcB_addr
                           , (uint8_t*)srcB_data
                           , srcB_width*srcB_height*sizeof(TYPE));

    dlb::MoverConcat12d<TYPE> ( (uint64_t)hw_dst_addr
                              , (uint64_t)hw_srcA_addr
                              , (uint64_t)hw_srcB_addr
                              , (uint16_t)srcA_width
                              , (uint16_t)srcA_height
                              , (uint16_t)srcB_width
                              , (uint16_t)srcB_height
                              , (uint16_t)(srcA_width+srcB_width)
                              , (uint16_t)srcA_height
                              , 1 // interrupt
                              , rigor
                              , verbose);

    // check values
    TYPE *dst_data  = (TYPE*)calloc(srcA_width*srcA_height+srcB_width*srcB_height, sizeof(TYPE));
    mover_read_block_from_hw( (uint8_t*)dst_data
                            , (uint64_t)hw_dst_addr
                            , srcA_width*srcA_height*sizeof(TYPE)+srcB_width*srcB_height*sizeof(TYPE));

    int miss=0;
    int ida=0;
    int idb=0;
    int idc=0;
    for (int y=0; y<srcA_height; y++) {
        for (int x=0; x<srcA_width; x++) {
            if (srcA_data[ida]!=dst_data[idc]) miss++;
            ida++;
            idc++;
        }
        for (int z=0; z<srcB_width; z++) {
            if (srcB_data[idb]!=dst_data[idc]) miss++;
            idb++;
            idc++;
        }
    }
    if (miss>0) PRINTF("mis-match: %d out of %d\n", miss, idc);
    else        PRINTF("mached (OK). %d\n", idc);

    if (srcA_data!=NULL) free(srcA_data);
    if (srcB_data!=NULL) free(srcB_data);
    if (dst_data!=NULL) free(dst_data);

    return 0;
}

//------------------------------------------------------------------------------
// Revision history
//
// 2021.08.01: Started by Ando Ki.
//------------------------------------------------------------------------------
