//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All rights are reserved by Ando Ki.
//------------------------------------------------------------------------------
// convolution.cpp
//------------------------------------------------------------------------------
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include <math.h>
#include <iostream>

#include "defines_dpu.h"
#include "convolution_2d_one.hpp" // Deep Learning Block API
#include "convolution_2d.hpp" // Deep Learning Routines

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
static uint8_t conv_get_end_stride( int test_level
                                  , uint8_t start_stride
                                  , uint8_t kernel_size)
{
         if (test_level==1) return start_stride+1;
    else if (test_level==2) return kernel_size;
    else                    return start_stride;
}

static uint8_t conv_get_end_padding(int test_level, uint8_t start_padding, uint8_t stride)
{
         if (test_level==1) return start_padding+1;
    else if (test_level==2) return (uint8_t)(stride/2);
    else                    return start_padding;
}

constexpr int c_strcmp( char const* lhs, char const* rhs )
{
    return (('\0' == lhs[0]) && ('\0' == rhs[0])) ? 0
        :  (lhs[0] != rhs[0]) ? ((int)lhs[0] - (int)rhs[0])
        : c_strcmp( lhs+1, rhs+1 );
}

//------------------------------------------------------------------------------
int test_convolution_2d( int test_level, int verbose )
{
    extern int test_convolution_2d_core(
                              uint16_t  out_size    // only for square matrix
                            , uint16_t  in_size     // only for square matrix
                            , uint8_t   kernel_size // only for square matrix
                            , uint16_t  bias_size   // out_channel
                            , uint16_t  in_channel  // number of input channels
                            , uint16_t  out_channel // number of filters (kernels)
                            , uint8_t   stride
                            , uint8_t   padding
                            , uint8_t   activ_func
                            , uint32_t  activ_param
                            , int       rigor
                            , int       verbose );
    #if defined(DEBUG)
    conv_version();
    conv_csr_test();
    #endif

    #if defined(RIGOR)||defined(DEBUG)
    if (conv_check_data_type(QuoteMacro(TYPE), sizeof(TYPE)*8, 0)) {
        char data_type[3];
        uint8_t Q, N;
        conv_get_config(data_type, &Q, &N, NULL, NULL, NULL, NULL);
        data_type[2]='\0'; // make normal string
        PRINTF("data type mis-match: \"%s:%d:%d\" \"%s\"\n",
                data_type, N, Q, QuoteMacro(TYPE));
    }
    #endif

    uint16_t  out_size   ;// only for square matrix
    uint16_t  bias_size  ;// out_channel
    uint16_t  in_size    , start_in_size    =10, end_in_size    ;// only for square matrix
    uint16_t  in_channel , start_in_channel = 1, end_in_channel ;// number of input channels
    uint16_t  out_channel, start_out_channel= 1, end_out_channel;// number of filters (kernels)
    uint8_t   kernel_size, start_kernel_size= 3, end_kernel_size;// only for square matrix
    uint8_t   stride     , start_stride     = 1;
    uint8_t   padding    , start_padding    = 0;
    uint8_t   activ_func=ACTIV_FUNC_NOP;
    uint32_t  activ_param=0;
    int       rigor=1;

    if (test_level==1) {
        end_in_size    =start_in_size    +1;
        end_in_channel =start_in_channel +1;
        end_out_channel=start_out_channel+1;
        end_kernel_size=start_kernel_size+2; // make odd
    } else if (test_level==2) {
        end_in_size    =start_in_size    +10;
        end_in_channel =start_in_channel +2;
        end_out_channel=start_out_channel+2;
        end_kernel_size=start_kernel_size+4; // make odd
    } else { // if (test_level==0) {
        end_in_size    =start_in_size    ;
        end_in_channel =start_in_channel ;
        end_out_channel=start_out_channel;
        end_kernel_size=start_kernel_size;
    }

    for (in_size    =start_in_size    ; in_size    <=end_in_size    ; in_size++     ) {
    for (in_channel =start_in_channel ; in_channel <=end_in_channel ; in_channel++  ) {
    for (out_channel=start_out_channel; out_channel<=end_out_channel; out_channel++ ) {
    for (kernel_size=start_kernel_size; kernel_size<=end_kernel_size; kernel_size+=2) { // make odd
    for (stride     =start_stride     ; stride     <=conv_get_end_stride (test_level, start_stride, kernel_size); stride++) {
    for (padding    =start_padding    ; padding    <=conv_get_end_padding(test_level, start_padding, stride); padding++) {
        bias_size  =out_channel; // no bias or out_channel if any.
        out_size   =1+(in_size-kernel_size+2*padding)/stride;
        PRINTF("================================\n");
        PRINTF("out_size   = %0d\n", out_size    );
        PRINTF("in_size    = %0d\n", in_size     );
        PRINTF("kernel_size= %0d\n", kernel_size );
        PRINTF("bias_size  = %0d\n", bias_size   );
        PRINTF("in_channel = %0d\n", in_channel  );
        PRINTF("out_channel= %0d\n", out_channel );
        PRINTF("stride     = %0d\n", stride      );
        PRINTF("padding    = %0d\n", padding     );
        if (test_convolution_2d_core( out_size    // only for square matrix
                                    , in_size     // only for square matrix
                                    , kernel_size // only for square matrix
                                    , bias_size   // out_channel
                                    , in_channel  // number of input channels
                                    , out_channel // number of filters (kernels)
                                    , stride
                                    , padding
                                    , activ_func
                                    , activ_param
                                    , rigor
                                    , verbose )!=0) {
            PRINTF("ERROR occurs ****************************************\n");
        }

    } //for (padding    
    } //for (stride     
    } //for (kernel_size
    } //for (out_channel
    } //for (in_channel 
    } //for (in_size    

    #undef end_stride
    #undef end_padding

    return 0;
}

//------------------------------------------------------------------------------
int test_convolution_2d_core( uint16_t  out_size    // only for square matrix
                            , uint16_t  in_size     // only for square matrix
                            , uint8_t   kernel_size // only for square matrix
                            , uint16_t  bias_size   // out_channel
                            , uint16_t  in_channel  // number of input channels
                            , uint16_t  out_channel // number of filters (kernels)
                            , uint8_t   stride
                            , uint8_t   padding
                            , uint8_t   activ_func
                            , uint32_t  activ_param
                            , int       rigor
                            , int       verbose )
{
    TYPE     *in_data;     // in_channel x in_size x in_size
    TYPE     *kernel;      // out_channel x in_channel x kernel_size x kernel_size
    TYPE     *bias;        // out_channel
    TYPE     *out_data;    // out_channel x out_size x out_size
    in_data  = (TYPE*)calloc(in_channel*in_size*in_size, sizeof(TYPE));
    kernel   = (TYPE*)calloc(out_channel*in_channel*kernel_size*kernel_size, sizeof(TYPE));
    bias     = (TYPE*)calloc(out_channel, sizeof(TYPE)); // make sure all 0
    out_data = (TYPE*)calloc(out_channel*out_size*out_size, sizeof(TYPE)); // make sure all 0

    // fill buffer
    int d = 0;
    for (int a=0; a<out_channel; a++) {
    for (int b=0; b<in_channel; b++) {
    for (int c=0; c<kernel_size*kernel_size; c++) {
        if (!strcmp(QuoteMacro(TYPE),"float")) {
            kernel[d] = (TYPE)((d+1)+(d/10.0));
        } else {
            kernel[d] = (TYPE)(d+1);
        }
        d++;
    }}}
    int k=0;
    for (int i=0; i<in_channel; i++) {
    for (int j=0; j<in_size*in_size; j++) {
        if (!strcmp(QuoteMacro(TYPE),"float")) {
            in_data[k] = (TYPE)((k+1)+(k/10.0));
        } else {
            in_data[k] = (TYPE)(k+1);
        }
        k++;
    }}
    if (out_channel>0) {
        for (int i=0; i<bias_size; i++) {
            if (!strcmp(QuoteMacro(TYPE),"float")) {
                bias[i] = (TYPE)((i+1)+(i/10.0));
            } else {
                bias[i] = (TYPE)(i+1);
            }
        }
    }

    uint64_t hw_feature_addr=DPU_ADDR_BASE_MEM;
    uint64_t hw_kernel_addr =DPU_ADDR_BASE_MEM+in_channel*in_size*in_size*sizeof(TYPE);
    uint64_t hw_result_addr =DPU_ADDR_BASE_MEM+in_channel*in_size*in_size*sizeof(TYPE)
                                              +out_channel*in_channel*kernel_size*kernel_size*sizeof(TYPE);

    // dlb::Convolution2d<uint32_t> moves host data to the HW memory
    // for each convolution.
    dlb::Convolution2d<TYPE>  (
             out_data    //       TYPE * const sw_out_data
           , in_data     // const TYPE * const sw_in_data
           , kernel      // const TYPE * const sw_kernel
           , bias        // const TYPE * const sw_bias
           , hw_result_addr // const uint64_t hw_result_addr
           , hw_feature_addr// const uint64_t hw_feature_addr
           , hw_kernel_addr // const uint64_t hw_kernel_addr
           , out_size    // const uint16_t  out_size
           , in_size     // const uint16_t  in_size
           , kernel_size // const uint8_t   kernel_size
           , bias_size   // const uint16_t  bias_size
           , in_channel  // const uint16_t  in_channel
           , out_channel // const uint16_t  out_channel
           , stride      // const uint8_t   stride
           , padding     // const uint8_t   padding
           , activ_func  // const uint8_t   activ_func
           , activ_param // const uint32_t  activ_param
           , 1           // const int       interrupt
           , rigor       // const int rigor
           , verbose     // const int verbose
           , 1           // const int check
           );

    TYPE *out_data_ref;// out_channel x out_size x out_size
    out_data_ref = (TYPE*)calloc(out_channel*out_size*out_size, sizeof(TYPE));

    dlr::Convolution2d<TYPE>  (
             out_data_ref // const TYPE * const out_data
           , in_data   // const TYPE * const in_data
           , kernel    // const TYPE * const kernel
           , bias      // const TYPE * const bias
           , out_size     // const uint16_t  out_size
           , in_size      // const uint16_t  in_size
           , kernel_size  // const uint8_t   kernel_size
           , bias_size    // const uint16_t  bias_size
           , in_channel   // const uint16_t  in_channel
           , out_channel  // const uint16_t  out_channel
           , stride       // const uint8_t   stride
           , padding      // const uint8_t   padding
           , rigor        // const int rigor
           , verbose      // const int verbose
           );
#ifndef ERROR_MARGIN
#define ERROR_MARGIN  0.07
#endif

    k = 0;
    int error=0;
    for (int i=0; i<out_channel; i++) {
    for (int j=0; j<out_size*out_size; j++) {
        float delta = fabs(double(out_data[k]-out_data_ref[k]));
        if ((out_data[k]!=out_data_ref[k])&&(delta>ERROR_MARGIN)) {
PRINTF("[%d] ", k);
std::cout << out_data[k] << ":(E)" << out_data_ref[k] << ":" << delta <<std::endl;
//#define cbrt(X) _Generic((X), int32_t: "0x%08X", int16_t: "0x%04X", int8_t: "0x%02X", float: "%f")
//PRINTF("[%d]=" cbrt(TYPE) ":" cbrt(TYPE) "\n", k, out_data[k], out_data_ref[k]);
//#if    QuoteMacro(TYPE) == "int32_t"
//#if    QuoteMacro(TYPE) == 0x696e7433325f74
//#if    QuoteIndent(TYPE) == 0x696e7433325f74
//#if      0 == c_strcmp( QuoteMacro(TYPE), "int32_t" )
//PRINTF("[%d]=0x%08X:0x%08X\n", k, out_data[k], out_data_ref[k]);
//#elif (QuoteMacro(TYPE)=="int16_t")
//PRINTF("[%d]=0x%04X:0x%04X\n", k, out_data[k], out_data_ref[k]);
//#elif (QuoteMacro(TYPE)=="int8_t")
//PRINTF("[%d]=0x%02X:0x%02X\n", k, out_data[k], out_data_ref[k]);
//#elif (QuoteMacro(TYPE)=="float")
//PRINTF("[%d]=%f:%f\n", k, out_data[k], out_data_ref[k]);
//#else
//PRINTF("ERROR data type %s not supported.\n", QuoteMacro(TYPE));
//#endif
            error++;
        }
//else {
//PRINTF("[%d]=", k);
//std::cout << out_data[k] << ":" << out_data_ref[k] << ":" << delta << std::endl;
//}
        k++;
    }}
    if (error>0) PRINTF("mis-match %d out of %d.\n", error, out_channel*out_size*out_size);
    else         PRINTF("OK %d items.\n", out_channel*out_size*out_size);

    if (kernel  !=NULL) free(kernel  );
    if (in_data !=NULL) free(in_data );
    if (out_data!=NULL) free(out_data);
    if (bias    !=NULL) free(bias    );
    if (out_data_ref!=NULL) free(out_data_ref);

    return (error) ? -error : 0;
}

//------------------------------------------------------------------------------
// Revision history
//
// 2021.08.01: Started by Ando Ki.
//------------------------------------------------------------------------------
