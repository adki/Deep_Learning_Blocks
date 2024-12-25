//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All rights are reserved by Ando Ki.
//------------------------------------------------------------------------------
// linear.cpp
//------------------------------------------------------------------------------
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include <math.h>
#include <iostream>

#include "defines_dpu.h"
#include "linear_1d_one.hpp" // Deep Learning Block API
#include "linear_1d.hpp" // Deep Learning Routines

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
int test_linear_1d( int test_level, int verbose )
{
    extern int test_linear_1d_core( uint16_t  out_size
                                  , uint16_t  in_size
                                  , uint16_t  bias_size
                                  , uint8_t   activ_func
                                  , uint32_t  activ_param
                                  , int       rigor
                                  , int       verbose );
    #if defined(DEBUG)
    linear_version();
    linear_csr_test();
    #endif

    #if defined(RIGOR)||defined(DEBUG)
    if (linear_check_data_type(QuoteMacro(TYPE), sizeof(TYPE)*8, 0)) {
        char data_type[3];
        uint8_t Q, N;
        linear_get_config(data_type, &Q, &N, NULL, NULL, NULL);
        data_type[2]='\0'; // make normal string
        PRINTF("data type mis-match: \"%s:%d:%d\" \"%s\"\n",
                data_type, N, Q, QuoteMacro(TYPE));
    }
    #endif

    uint16_t out_size, start_out_size=5, end_out_size;
    uint16_t in_size , start_in_size =4, end_in_size ; // >=4
    uint16_t bias_size;
    uint8_t  activ_func=ACTIV_FUNC_NOP;
    uint32_t activ_param=0;
    int      rigor=1  ;// check rigorously when 1

    if (test_level==1) {
        end_out_size = start_out_size+2;
        end_in_size  = start_in_size+2;
    } else if (test_level==2) {
        end_out_size = start_out_size+5;
        end_in_size  = start_in_size+5;
    } else { // if (test_level==0) {
        end_out_size = start_out_size;
        end_in_size  = start_in_size ;
    }

    for (in_size =start_in_size ; in_size <=end_in_size ; in_size ++) {
    for (out_size=start_out_size; out_size<=end_out_size; out_size++) {
        bias_size = out_size;// should be 0 or out_size
        PRINTF("================================\n");
        PRINTF("out_size = %0d\n", out_size );
        PRINTF("in_size  = %0d\n", in_size  );
        PRINTF("bias_size= %0d\n", bias_size);
        if (test_linear_1d_core( out_size
                               , in_size
                               , bias_size
                               , activ_func
                               , activ_param
                               , rigor
                               , verbose)!=0) {
            PRINTF("ERROR occurs ****************************************\n");
        }
    } // for (out_size
    } // for (in_size

    return 0;
}

//------------------------------------------------------------------------------
int test_linear_1d_core( uint16_t  out_size
                       , uint16_t  in_size
                       , uint16_t  bias_size
                       , uint8_t   activ_func
                       , uint32_t  activ_param
                       , int       rigor
                       , int       verbose )
{
    TYPE *out_data = (TYPE*)calloc(out_size, sizeof(TYPE));
    TYPE *in_data  = (TYPE*)calloc(in_size, sizeof(TYPE));
    TYPE *weight   = (TYPE*)calloc(in_size*out_size, sizeof(TYPE));
    TYPE *bias     = (TYPE*)calloc(out_size, sizeof(TYPE));

    // fill buffer
    for (int i=0; i<in_size; i++) {
        if (!strcmp(QuoteMacro(TYPE),"float")) {
            in_data[i] = (TYPE)((i+1)+(i/10.0));
        } else {
            in_data[i] = (TYPE)(i+1);
        }
    }
    int k=0;
    for (int i=0; i<out_size; i++) {
    for (int j=0; j<in_size; j++) {
        if (!strcmp(QuoteMacro(TYPE),"float")) {
            weight[k] = (TYPE)((k+1)+(k/10.0));
        } else {
            weight[k] = (TYPE)(k+1);
        }
        k++;
    }}
    if (bias_size>0) {
        for (int i=0; i<bias_size; i++) {
            if (!strcmp(QuoteMacro(TYPE),"float")) {
                bias[i] = (TYPE)((i+1)+(i/10.0));
            } else {
                bias[i] = (TYPE)(i+1);
            }
        }
    }

    uint64_t hw_feature_addr=DPU_ADDR_BASE_MEM;
    uint64_t hw_weight_addr =DPU_ADDR_BASE_MEM+in_size*sizeof(TYPE);
    uint64_t hw_bias_addr   =DPU_ADDR_BASE_MEM+in_size*sizeof(TYPE)
                                              +in_size*out_size*sizeof(TYPE);
    uint64_t hw_result_addr =DPU_ADDR_BASE_MEM+in_size*sizeof(TYPE)
                                              +in_size*out_size*sizeof(TYPE)
                                              +bias_size*sizeof(TYPE);
    dlb::Linear1d<TYPE> (
          out_data  //       TYPE * const sw_out_data
        , in_data   // const TYPE * const sw_in_data
        , weight    // const TYPE * const sw_weight
        , bias      // const TYPE * const sw_bias
        , hw_result_addr  // const uint64_t hw_result_addr
        , hw_feature_addr // const uint64_t hw_feature_addr
        , hw_weight_addr  // const uint64_t hw_weight_addr
        , hw_bias_addr    // const uint64_t hw_bias_addr
        , out_size  // const uint16_t  out_size
        , in_size   // const uint16_t  in_size
        , bias_size // const uint16_t  bias_size
        , activ_func  // const uint8_t  activ_func
        , activ_param // const uint32_t activ_param
        , 1         // const int       interrupt
        , rigor     // const int       rigor=0
        , verbose   // const int       verbose=0
        , 1         // const int       check=0
    );

    TYPE *out_data_ref;// out_size
    out_data_ref = (TYPE*)calloc(out_size, sizeof(TYPE));

    dlr::Linear1d<TYPE> (
          out_data_ref //       TYPE    *out_data
        , in_data      // const TYPE    *in_data
        , weight       // const TYPE    *weight
        , bias         // const TYPE    *bias
        , out_size     // const uint16_t  out_size
        , in_size      // const uint16_t  in_size
        , bias_size    // const uint16_t  bias_size
        , rigor        // const int       rigor=0
        , verbose      // const int       verbose=0
    );

#ifndef ERROR_MARGIN
#define ERROR_MARGIN  0.01
#endif

    k = 0;
    int error=0;
    for (int i=0; i<out_size; i++) {
        float delta = fabs(double(out_data[k]-out_data_ref[k]));
        if ((out_data[k]!=out_data_ref[k])&&(delta>ERROR_MARGIN)) {
PRINTF("[%d] ", k);
std::cout << out_data[k] << ":" << out_data_ref[k] << ":" << delta << std::endl;
PRINTF("[%d]=0x%0X:0x%0X\n", k, *(unsigned int*)&out_data[k], *(unsigned int*)&out_data_ref[k]);
            error++;
        }
//else {
//PRINTF("[%d]=", k);
//std::cout << out_data[k] << ":" << out_data_ref[k] << std::endl;
//}
        k++;
    }
    if (error>0) PRINTF("mis-match %d out of %d.\n", error, out_size);
    else         PRINTF("OK %d items.\n", out_size);

    if (out_data!=NULL) free(out_data);
    if (in_data !=NULL) free(in_data );
    if (weight  !=NULL) free(weight  );
    if (bias    !=NULL) free(bias    );
    if (out_data_ref!=NULL) free(out_data_ref);

    return (error) ? -error : 0;
}

//------------------------------------------------------------------------------
// Revision history
//
// 2021.08.01: Started by Ando Ki.
//------------------------------------------------------------------------------
