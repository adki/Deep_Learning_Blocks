//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All rights are reserved by Ando Ki.
//------------------------------------------------------------------------------
// pooling.cpp
//------------------------------------------------------------------------------
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include <iostream>

#include "defines_dpu.h"
#include "pooling_2d_one.hpp" // Deep Learning Block API
#include "pooling_2d_max.hpp" // Deep Learning Routines

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
static uint8_t pooling_get_end_stride(int test_level, uint8_t start_stride, uint8_t kernel_size)
{
         if (test_level==1) return start_stride+1;
    else if (test_level==2) return kernel_size;
    else                    return start_stride;
}

static uint8_t pooling_get_end_padding(int test_level, uint8_t start_padding, uint8_t stride)
{
         if (test_level==1) return start_padding+1;
    else if (test_level==2) return (uint8_t)(stride/2);
    else                    return start_padding;
}

//------------------------------------------------------------------------------
int test_pooling_2d( int test_level, int verbose )
{
    extern int test_pooling_2d_core( uint16_t  out_size    // only for square matrix
                                   , uint16_t  in_size     // only for square matrix
                                   , uint8_t   kernel_size // only for square matrix
                                   , uint16_t  channel     // number of input/output channels
                                   , uint8_t   stride 
                                   , uint8_t   padding
                                   , int       rigor
                                   , int       verbose );
    #if defined(DEBUG)
    pool_version();
    pool_csr_test();
    #endif

    #if defined(RIGOR)||defined(DEBUG)
    if (pool_check_data_type(QuoteMacro(TYPE), sizeof(TYPE)*8, 0)) {
        char data_type[3];
        uint8_t Q, N;
        pool_get_config(data_type, &Q, &N, NULL, NULL);
        data_type[2]='\0'; // make normal string
        PRINTF("data type mis-match: \"%s:%d:%d\" \"%s\"\n",
                data_type, N, Q, QuoteMacro(TYPE));
    }
    #endif

    uint16_t  out_size;   // only for square matrix
    uint16_t  in_size    , start_in_size    =10, end_in_size    ;// only for square matrix
    uint16_t  channel    , start_channel    = 1, end_channel    ;// number of input/output channels
    uint8_t   kernel_size, start_kernel_size= 2, end_kernel_size;// only for square matrix
    uint8_t   stride     , start_stride =1;
    uint8_t   padding    , start_padding=0;
    int       rigor=1;

    if (test_level==1) {
        end_in_size    = start_in_size    +1;
        end_channel    = start_channel    +1;
        end_kernel_size= start_kernel_size+2; // make even
    } else if (test_level==2) {
        end_in_size    = start_in_size    +5;
        end_channel    = start_channel    +2;
        end_kernel_size= start_kernel_size+2; // make even
    } else { // if (test_level==0) {
        end_in_size    = start_in_size    ;
        end_channel    = start_channel    ;
        end_kernel_size= start_kernel_size;
    }

    for (in_size    =start_in_size    ; in_size    <=end_in_size    ; in_size++     ) {
    for (channel    =start_channel    ; channel    <=end_channel    ; channel++     ) {
    for (kernel_size=start_kernel_size; kernel_size<=end_kernel_size; kernel_size+=2) { // make even
    for (stride     =start_stride     ; stride     <=pooling_get_end_stride(test_level, start_stride, kernel_size); stride++) {
    for (padding    =start_padding    ; padding    <=pooling_get_end_padding(test_level, start_padding, stride); padding++) {
        out_size    = 1+(in_size-kernel_size+2*padding)/stride;
        PRINTF("================================\n");
        PRINTF("out_size   = %0d\n", out_size   );
        PRINTF("in_size    = %0d\n", in_size    );
        PRINTF("kernel_size= %0d\n", kernel_size);
        PRINTF("channel    = %0d\n", channel    );
        PRINTF("stride     = %0d\n", stride     );
        PRINTF("padding    = %0d\n", padding    );
        if (test_pooling_2d_core( out_size    // only for square matrix
                                , in_size     // only for square matrix
                                , kernel_size // only for square matrix
                                , channel     // number of input/output channels
                                , stride 
                                , padding
                                , rigor
                                , verbose)!=0) {
            PRINTF("ERROR occurs ****************************************\n");
        }
    } //for (padding    
    } //for (stride     
    } //for (kernel_size
    } //for (channel    
    } //for (in_size    

    #undef end_stride
    #undef end_padding

    return 0;
}

//------------------------------------------------------------------------------
int test_pooling_2d_core( uint16_t  out_size    // only for square matrix
                        , uint16_t  in_size     // only for square matrix
                        , uint8_t   kernel_size // only for square matrix
                        , uint16_t  channel     // number of input/output channels
                        , uint8_t   stride 
                        , uint8_t   padding
                        , int       rigor
                        , int       verbose )
{
    TYPE *in_data  = (TYPE*)calloc(channel*in_size*in_size, sizeof(TYPE));
    TYPE *out_data = (TYPE*)calloc(channel*out_size*out_size, sizeof(TYPE));

    int k=0;
    for (int i=0; i<channel; i++) {
    for (int j=0; j<in_size*in_size; j++) {
        if (!strcmp(QuoteMacro(TYPE),"float")) {
            in_data[k] = (TYPE)((k+1)+(k/10.0));
        } else {
            in_data[k] = (TYPE)(k+1);
        }
        k++;
    }}

    uint8_t  command=POOLING_MAX;
    uint64_t hw_feature_addr=DPU_ADDR_BASE_MEM;
    uint64_t hw_result_addr =DPU_ADDR_BASE_MEM+channel*in_size*in_size*sizeof(TYPE);

    dlb::Pooling2d<TYPE> (
          out_data    //       TYPE * const out_data
        , in_data     // const TYPE * const in_data
        , command     // const uint8_t command
        , hw_result_addr  // const uint64_t hw_result_addr
        , hw_feature_addr // const uint64_t hw_feature_addr
        , out_size    // const uint16_t  out_size
        , in_size     // const uint16_t  in_size
        , kernel_size // const uint8_t   kernel_size
        , channel     // const uint16_t  channel
        , stride      // const uint8_t   stride
        , padding     // const uint8_t   padding
        , 1           // const int       interrupt
        , rigor       // const int rigor
        , verbose     // const int verbose
        , 1           // const int check
    );

    TYPE *out_data_ref;// out_channel x out_size x out_size
    out_data_ref = (TYPE*)calloc(channel*out_size*out_size, sizeof(TYPE));

    dlr::Pooling2dMax<TYPE> (
          out_data_ref //       TYPE     *out_data
        , in_data      // const TYPE     *in_data
        , out_size     // const uint16_t  out_size
        , in_size      // const uint16_t  in_size
        , kernel_size  // const uint8_t   kernel_size
        , channel      // const uint16_t  channel
        , stride       // const uint8_t   stride
        , padding      // const uint8_t   padding
        , 0            // const int       ceil_mode
        , rigor        // const int       rigor
        , verbose      // const int       verbose
    );

#ifndef ERROR_MARGIN
#define ERROR_MARGIN  0.01
#endif

    k = 0;
    int error=0;
    for (int i=0; i<channel; i++) {
    for (int j=0; j<out_size*out_size; j++) {
        float delta = fabs(double(out_data[k]-out_data_ref[k]));
        if ((out_data[k]!=out_data_ref[k])&&(delta>ERROR_MARGIN)) {
PRINTF("[%d] ", k);
std::cout << out_data[k] << ":" << out_data_ref[k] << ":" << delta << std::endl;
//PRINTF("[%d]=0x%0X:0x%0X\n", k, out_data[k], out_data_ref[k]);
            error++;
        }
//else {
//PRINTF("[%d]=", k);
//std::cout << out_data[k] << ":" << out_data_ref[k] << ":" << delta << std::endl;
//}
        k++;
    }}
    if (error>0) PRINTF("mis-match %d out of %d.\n", error, channel*out_size*out_size);
    else         PRINTF("OK %d items.\n", channel*out_size*out_size);

    if (in_data !=NULL) free(in_data );
    if (out_data!=NULL) free(out_data);
    if (out_data_ref!=NULL) free(out_data_ref);

    return (error) ? -error : 0;
}

//------------------------------------------------------------------------------
// Revision history
//
// 2021.08.01: Started by Ando Ki.
//------------------------------------------------------------------------------
