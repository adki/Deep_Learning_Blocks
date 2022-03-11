#pragma once
//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All rights are reserved by Ando Ki.
//------------------------------------------------------------------------------

#include "defines.h"
#include "defines_dpu.h"
#include "lenet5_params.h"

#include "convolution_2d_one.hpp"
#include "pooling_2d_one.hpp"
#include "linear_1d_one.hpp"

#define get_size(in_size,kernel_size,stride,padding)\
        ((((in_size)-(kernel_size)+(2*(padding)))/(stride))+1)

//------------------------------------------------------------------------------
// It reads 'image_file' and makes 32x32 grey normalized image data.
template<class TYPE=float>
int lenet5_infer(       TYPE * const results // [10]
                , const TYPE * const image_normalized // [32][32]
                , const int rigor=0
                , const int verbose=0
                , const int performance=0)
{
    //--------------------------------------------------------------------------
    // *: convolution
    // +: addition
    // /: pooling
    // x: linear
    // convolution 1: [32][32]*[6][5][5]+[6] 1-stride 0-padding ==> [6][28][28]
    // maxpooling 1:  [6][28][28]/[2][2] 2-stride 0-padding  ==> [6][14][14]
    // convolution 2: [6][14][14]*[16][5][5]+[16] 1-stride 0-padding ==> [16][10][10]
    // maxpooling 2:  [16][10][10]/[2][2] 2-stride 0-padding ==> [16][5][5]
    // linear 1:      [16][5][5]x[120][400]+[120] ==> [120]
    // linear 2:      [120]x[84][120]+[84] ==> [84]
    // linear 3:      [84]x[10][84]+[10] ==> [10]
    //--------------------------------------------------------------------------
    // Note "???_sw_???" represents data in software variable from "lenet5_params.h".
    TYPE     *conv_sw_out_data    [2]={NULL,NULL}; // no interface to the SW memory for convolultion output (simple goes to pooling)
    TYPE     *conv_sw_in_data     [2]={const_cast<TYPE*>(image_normalized),NULL}; // only input is for the SW memory
    TYPE     *conv_sw_kernel      [2]={const_cast<TYPE*>(conv1_weight),const_cast<TYPE*>(conv2_weight)};
    TYPE     *conv_sw_bias        [2]={const_cast<TYPE*>(conv1_bias),const_cast<TYPE*>(conv2_bias)};
    uint64_t  conv_hw_result_addr [2];
    uint64_t  conv_hw_feature_addr[2];
    uint64_t  conv_hw_kernel_addr [2];
    uint16_t  conv_out_size       [2];
    uint16_t  conv_in_size        [2];
    uint8_t   conv_kernel_size    [2]={(uint8_t)conv1_kernel_size[0],(uint8_t)conv2_kernel_size[0]}; // square matrix
    uint16_t  conv_bias_size      [2]={(uint16_t)conv1_num_bias,(uint16_t)conv2_num_bias};
    uint16_t  conv_in_channel     [2]={(uint16_t)conv1_in_channel,(uint16_t)conv2_in_channel};
    uint16_t  conv_out_channel    [2]={(uint16_t)conv1_out_channel,(uint16_t)conv2_out_channel};
    uint8_t   conv_stride         [2]={(uint8_t)conv1_stride[0],(uint8_t)conv2_stride[0]};
    uint8_t   conv_padding        [2]={(uint8_t)conv1_padding[0],(uint8_t)conv2_padding[1]};
    uint8_t   conv_activ_func     [2]={ACTIV_FUNC_RELU, ACTIV_FUNC_RELU};
    uint32_t  conv_activ_param    [2]={ 0, 0};
    TYPE     *pool_sw_out_data    [2]={NULL,NULL}; // no interface to the SW memory
    TYPE     *pool_sw_in_data     [2]={NULL,NULL}; // no interface to the SW memory
    uint64_t  pool_hw_result_addr [2];
    uint64_t  pool_hw_feature_addr[2];
    uint16_t  pool_out_size       [2];
    uint16_t  pool_in_size        [2];
    uint8_t   pool_kernel_size    [2]={(uint8_t)pool1_kernel_size[0],(uint8_t)pool2_kernel_size[0]}; // square matrix
    uint16_t  pool_channel        [2]={(uint8_t)conv1_out_channel,(uint8_t)conv2_out_channel};
    uint8_t   pool_stride         [2]={(uint8_t)pool1_stride[0],(uint8_t)pool2_stride[0]};
    uint8_t   pool_padding        [2]={(uint8_t)pool1_padding[0],(uint8_t)pool2_padding[0]};
    TYPE     *fc_sw_out_data      [3]={NULL,NULL,results}; // only results are for SW memory
    TYPE     *fc_sw_in_data       [3]={NULL,NULL,NULL}; // not interface to the SW memory
    TYPE     *fc_sw_weight        [3]={const_cast<TYPE*>(fc1_weight),const_cast<TYPE*>(fc2_weight),const_cast<TYPE*>(fc3_weight)};
    TYPE     *fc_sw_bias          [3]={const_cast<TYPE*>(fc1_bias),const_cast<TYPE*>(fc2_bias),const_cast<TYPE*>(fc3_bias)};
    uint64_t  fc_hw_result_addr   [3];
    uint64_t  fc_hw_feature_addr  [3];
    uint64_t  fc_hw_weight_addr   [3];
    uint64_t  fc_hw_bias_addr     [3];
    uint16_t  fc_out_size         [3]={(uint16_t)fc1_out_features,(uint16_t)fc2_out_features,(uint16_t)fc3_out_features};
    uint16_t  fc_in_size          [3]={(uint16_t)fc1_in_features,(uint16_t)fc2_in_features,(uint16_t)fc3_in_features};
    uint16_t  fc_bias_size        [3]={(uint16_t)fc1_num_bias,(uint16_t)fc2_num_bias,(uint16_t)fc3_num_bias};
    uint8_t   fc_activ_func       [3]={ACTIV_FUNC_RELU,  ACTIV_FUNC_RELU, 0};
    uint32_t  fc_activ_param      [3]={ 0, 0, 0};
    //--------------------------------------------------------------------------
    conv_in_size [0]=IMAGE_WIDTH; // square
    conv_out_size[0]=get_size(conv_in_size[0],conv1_kernel_size[0],conv1_stride[0],conv1_padding[0]);
    pool_in_size [0]=conv_out_size[0]; // square
    pool_out_size[0]=get_size(pool_in_size[0],pool1_kernel_size[0],pool1_stride[0],pool1_padding[0]);
    //--------------------------------------------------------------------------
    conv_in_size [1]=pool_out_size[0]; // square
    conv_out_size[1]=get_size(conv_in_size[1],conv2_kernel_size[0],conv2_stride[0],conv2_padding[0]);
    pool_in_size [1]=conv_out_size[1]; // square
    pool_out_size[1]=get_size(pool_in_size[1],pool2_kernel_size[0],pool2_stride[0],pool2_padding[0]);
    //--------------------------------------------------------------------------
    // CONV1    POOL     CONV2    POOL     FC1      FC2      FC3   
    // +----+   +----+   +----+   +----+   +----+   +----+   +----+      
    // |FTU |   |RST |==>|FTU |   |RST |==>|FTU |   |RST |==>|FTU |
    // |    |   |    |   |    |   |    |   |    |   |    |   |    |
    // +----+   +----+   +----+   +----+   +----+   +----+   +----+     
    // |KNL |   |    |   |KNL |   |    |   |WEI |   |WEI |   |WEI |
    // |    |   |    |   |    |   |    |   |    |   |    |   |    |
    // +----+   |    |   +----+   |    |   +----+   +----+   +----+     
    // |    |   |    |   |    |   |    |   |BIA |   |BIA |   |BIA |
    // |    |   |    |   |    |   |    |   +----+   +----+   +----+
    // |    |   |    |   |    |   |    |   |    |   |    |   |    |
    // |    |   |    |   |    |   |    |   |    |   |    |   |    |
    // +----+   +----+   +----+   +----+   +----+   +----+   +----+     
    // |RST |==>|FTU |   |RST |==>|FTU |   |RST |==>|FTU |   |RST |
    // |    |   |    |   |    |   |    |   |    |   |    |   |    |
    // +----+   +----+   +----+   +----+   +----+   +----+   +----+     
    //--------------------------------------------------------------------------
    conv_hw_feature_addr[0]=DPU_ADDR_BASE_MEM;
    conv_hw_kernel_addr [0]=conv_hw_feature_addr[0]+conv_in_channel[0]*conv_in_size[0]*conv_in_size[0]*sizeof(TYPE);
    conv_hw_result_addr [0]=(DPU_ADDR_BASE_MEM+DPU_SIZE_MEM
                           -(conv_out_channel[0]*conv_out_size[0]*conv_out_size[0]*sizeof(TYPE))
                           -0x1F)&~0x1F;

    pool_hw_feature_addr[0]=conv_hw_result_addr [0];
    pool_hw_result_addr [0]=conv_hw_feature_addr[0]; //DPU_ADDR_BASE_MEM;

    conv_hw_feature_addr[1]=pool_hw_result_addr [0]; //DPU_ADDR_BASE_MEM;
    conv_hw_kernel_addr [1]=conv_hw_feature_addr[1]+conv_in_channel[1]*conv_in_size[1]*conv_in_size[1]*sizeof(TYPE);
    conv_hw_result_addr [1]=(DPU_ADDR_BASE_MEM+DPU_SIZE_MEM
                           -(conv_out_channel[1]*conv_out_size[1]*conv_out_size[1]*sizeof(TYPE))
                           -0x1F)&~0x1F;

    pool_hw_feature_addr[1]=conv_hw_result_addr [1];
    pool_hw_result_addr [1]=conv_hw_feature_addr[1]; //DPU_ADDR_BASE_MEM;

    fc_hw_feature_addr  [0]=pool_hw_result_addr [1]; //DPU_ADDR_BASE_MEM
    fc_hw_weight_addr   [0]=fc_hw_feature_addr  [0]+fc_in_size[0]*sizeof(TYPE);
    fc_hw_bias_addr     [0]=fc_hw_weight_addr   [0]+fc_in_size[0]*fc_out_size[0]*sizeof(TYPE);
    fc_hw_result_addr   [0]=(DPU_ADDR_BASE_MEM+DPU_SIZE_MEM
                           -(fc_out_size[0]*sizeof(TYPE)-0x1F))&~0x1F;

    fc_hw_feature_addr  [1]=fc_hw_result_addr   [0];
    fc_hw_result_addr   [1]=fc_hw_feature_addr  [0]; //DPU_ADDR_BASE_MEM;
    fc_hw_weight_addr   [1]=fc_hw_result_addr   [1]+fc_out_size[1]*sizeof(TYPE);
    fc_hw_bias_addr     [1]=fc_hw_weight_addr   [1]+fc_in_size[1]*fc_out_size[1]*sizeof(TYPE);

    fc_hw_feature_addr  [2]=fc_hw_result_addr   [1]; //DPU_ADDR_BASE_MEM
    fc_hw_weight_addr   [2]=fc_hw_feature_addr  [2]+fc_in_size[2]*sizeof(TYPE);
    fc_hw_bias_addr     [2]=fc_hw_weight_addr   [2]+fc_in_size[2]*fc_out_size[2]*sizeof(TYPE);
    fc_hw_result_addr   [2]=fc_hw_bias_addr     [2]+fc_out_size[2]*sizeof(TYPE);
    //--------------------------------------------------------------------------
    #if defined(DEBUG)
    printf("conv_hw_feature_addr[0]=0x%08lX\n", conv_hw_feature_addr[0]);
    printf("conv_hw_result_addr [0]=0x%08lX\n", conv_hw_result_addr [0]);
    printf("conv_hw_kernel_addr [0]=0x%08lX\n", conv_hw_kernel_addr [0]);
    printf("pool_hw_feature_addr[0]=0x%08lX\n", pool_hw_feature_addr[0]);
    printf("pool_hw_result_addr [0]=0x%08lX\n", pool_hw_result_addr [0]);
    printf("conv_hw_feature_addr[1]=0x%08lX\n", conv_hw_feature_addr[1]);
    printf("conv_hw_result_addr [1]=0x%08lX\n", conv_hw_result_addr [1]);
    printf("conv_hw_kernel_addr [1]=0x%08lX\n", conv_hw_kernel_addr [1]);
    printf("pool_hw_feature_addr[1]=0x%08lX\n", pool_hw_feature_addr[1]);
    printf("pool_hw_result_addr [1]=0x%08lX\n", pool_hw_result_addr [1]);
    printf("fc_hw_feature_addr  [0]=0x%08lX\n", fc_hw_feature_addr  [0]);
    printf("fc_hw_result_addr   [0]=0x%08lX\n", fc_hw_result_addr   [0]);
    printf("fc_hw_weight_addr   [0]=0x%08lX\n", fc_hw_weight_addr   [0]);
    printf("fc_hw_bias_addr     [0]=0x%08lX\n", fc_hw_bias_addr     [0]);
    printf("fc_hw_feature_addr  [1]=0x%08lX\n", fc_hw_feature_addr  [1]);
    printf("fc_hw_result_addr   [1]=0x%08lX\n", fc_hw_result_addr   [1]);
    printf("fc_hw_weight_addr   [1]=0x%08lX\n", fc_hw_weight_addr   [1]);
    printf("fc_hw_bias_addr     [1]=0x%08lX\n", fc_hw_bias_addr     [1]);
    printf("fc_hw_feature_addr  [2]=0x%08lX\n", fc_hw_feature_addr  [2]);
    printf("fc_hw_result_addr   [2]=0x%08lX\n", fc_hw_result_addr   [2]);
    printf("fc_hw_weight_addr   [2]=0x%08lX\n", fc_hw_weight_addr   [2]);
    printf("fc_hw_bias_addr     [2]=0x%08lX\n", fc_hw_bias_addr     [2]);
    fflush(stdout);
    #endif
    //--------------------------------------------------------------------------
    // overlapping check
    #if defined(RIGOR)
    if ((conv_hw_feature_addr[0]+conv_in_size[0]*conv_in_size[0]*sizeof(TYPE))>conv_hw_kernel_addr[0]) {
        myError("Convolution-Feature-Kernel 1 overlapping.\n");
    }
    if ((conv_hw_kernel_addr[0]+conv1_num_weight*sizeof(TYPE))>conv_hw_result_addr[0]) {
        myError("Convolution-Kernel-Result 1 overlapping.\n");
    }
    if ((conv_hw_result_addr[0]+conv_out_size[0]*conv_out_size[0]*sizeof(TYPE))>DPU_SIZE_MEM) {
        myError("Convolution-Result 1 overflow.\n");
    }
    if ((pool_hw_result_addr[0]+pool_in_size[0]*pool_in_size[0]*sizeof(TYPE))>pool_hw_feature_addr[0]) {
        myError("Pooling 1 overlapping.\n");
    }
    if ((conv_hw_feature_addr[1]+conv_in_size[1]*conv_in_size[1]*sizeof(TYPE))>conv_hw_kernel_addr[1]) {
        myError("Convolution-Feature-Kernel 2 overlapping.\n");
    }
    if ((conv_hw_kernel_addr[1]+conv2_num_weight*sizeof(TYPE))>conv_hw_result_addr[1]) {
        myError("Convolution-Kernel-Result 2 overlapping.\n");
    }
    if ((conv_hw_result_addr[1]+conv_out_size[1]*conv_out_size[1]*sizeof(TYPE))>DPU_SIZE_MEM) {
        myError("Convolution-Result 2 overlapping.\n");
    }
    if ((pool_hw_result_addr[1]+pool_in_size[1]*pool_in_size[1]*sizeof(TYPE))>pool_hw_feature_addr[1]) {
        myError("Pooling 2 overlapping.\n");
    }
    if ((fc_hw_feature_addr[0]+fc1_in_features*sizeof(TYPE))>fc_hw_weight_addr[0]) {
        myError("Linear-Feature-Weight 1 overlapping.\n");
    }
    if ((fc_hw_feature_addr[0]+(fc1_in_features+fc1_num_weight)*sizeof(TYPE))>fc_hw_bias_addr[0]) {
        myError("Linear-Weight-Bias 1 overlapping.\n");
    }
    if ((fc_hw_feature_addr[0]+(fc1_in_features+fc1_num_weight+fc1_num_bias)*sizeof(TYPE))>fc_hw_result_addr[0]) {
        myError("Linear-Bias-Result 1 overlapping.\n");
    }
    if ((fc_hw_result_addr[0]+fc1_out_features*sizeof(TYPE))>DPU_SIZE_MEM) {
        myError("Linear-Result 1 overflow.\n");
    }
    if ((fc_hw_result_addr[1]+fc2_out_features*sizeof(TYPE))>fc_hw_weight_addr[1]) {
        myError("Linear-Feature-Weight 2 overlapping.\n");
    }
    if ((fc_hw_result_addr[1]+(fc2_out_features+fc2_num_weight)*sizeof(TYPE))>fc_hw_bias_addr[1]) {
        myError("Linear-Weight-Bias 2 overlapping.\n");
    }
    if ((fc_hw_result_addr[1]+(fc2_out_features+fc2_num_weight+fc2_num_bias)*sizeof(TYPE))>fc_hw_feature_addr[1]) {
        myError("Linear-Bias-Result 2 overlapping.\n");
    }
    if ((fc_hw_feature_addr[2]+fc3_in_features*sizeof(TYPE))>fc_hw_weight_addr[2]) {
        myError("Linear-Feature-Weight 3 overlapping.\n");
    }
    if ((fc_hw_feature_addr[2]+(fc3_in_features+fc3_num_weight)*sizeof(TYPE))>fc_hw_bias_addr[2]) {
        myError("Linear-Weight-Bias 3 overlapping.\n");
    }
    if ((fc_hw_feature_addr[2]+(fc3_in_features+fc3_num_weight+fc3_num_bias)*sizeof(TYPE))>fc_hw_result_addr[2]) {
        myError("Linear-Bias-Result 3 overlapping.\n");
    }
    if ((fc_hw_result_addr[2]+fc3_out_features*sizeof(TYPE))>DPU_SIZE_MEM) {
        myError("Linear-Result 3 overflow.\n");
    }
    #endif
    //--------------------------------------------------------------------------
    const int interrupt=1;// interrupt enabled when 1
    //--------------------------------------------------------------------------
    for (int idx=0; idx<2; idx++) {
        #if defined(DEBUG)
        myInfo("=========== [Convolution2d %d]\n", idx);
        #endif
        dlb::Convolution2d<TYPE>
            (conv_sw_out_data    [idx]//      TYPE * const sw_out_data // out_channel x out_size x out_size
            ,conv_sw_in_data     [idx]//const TYPE * const sw_in_data  // in_channel x in_size x in_size
            ,conv_sw_kernel      [idx]//const TYPE * const sw_kernel   // out_channel x in_channel x kernel_size x kernel_size
            ,conv_sw_bias        [idx]//const TYPE * const sw_bias     // out_channel
            ,conv_hw_result_addr [idx]//const uint64_t  hw_result_addr // out_channel x out_size x out_size
            ,conv_hw_feature_addr[idx]//const uint64_t  hw_feature_addr  // in_channel x in_size x in_size
            ,conv_hw_kernel_addr [idx]//const uint64_t  hw_kernel_addr // out_channel x in_channel x kernel_size x kernel_size
            ,conv_out_size       [idx]//const uint16_t  out_size    // only for square matrix
            ,conv_in_size        [idx]//const uint16_t  in_size     // only for square matrix
            ,conv_kernel_size    [idx]//const uint8_t   kernel_size // only for square matrix
            ,conv_bias_size      [idx]//const uint16_t  bias_size   // out_channel
            ,conv_in_channel     [idx]//const uint16_t  in_channel  // number of input channels
            ,conv_out_channel    [idx]//const uint16_t  out_channel // number of filters (kernels)
            ,conv_stride         [idx]//const uint8_t   stride=1
            ,conv_padding        [idx]//const uint8_t   padding=0
            ,conv_activ_func     [idx]//const uint8_t   activ_func=0
            ,conv_activ_param    [idx]//const uint32_t  activ_param=0
            ,interrupt //const int interrupt=0 // interrupt enabled when 1
            ,rigor     //const int rigor=0
            ,verbose   //const int verbose=0
            ,performance     //const int performance=0
            );
        //----------------------------------------------------------------------
        #if defined(DEBUG)
        myInfo("=========== [Pooling2d %d]\n", idx);
        #endif
        dlb::Pooling2d<TYPE>
            (pool_sw_out_data    [idx]//      TYPE * const sw_out_data // out_channel x out_size x out_size
            ,pool_sw_in_data     [idx]//const TYPE * const sw_in_data  // in_channel x in_size x in_size
            ,POOLING_MAX              //const uint8_t   command
            ,pool_hw_result_addr [idx]//const uint64_t  hw_result_addr // out_channel x out_size x out_size
            ,pool_hw_feature_addr[idx]//const uint64_t  hw_feature_addr  // in_channel x in_size x in_size
            ,pool_out_size       [idx]//const uint16_t  out_size    // only for square matrix
            ,pool_in_size        [idx]//const uint16_t  in_size     // only for square matrix
            ,pool_kernel_size    [idx]//const uint8_t   kernel_size // only for square matrix
            ,pool_channel        [idx]//const uint16_t  channel  // number of input/output channels
            ,pool_stride         [idx]//const uint8_t   stride=1
            ,pool_padding        [idx]//const uint8_t   padding=0
            ,interrupt //const int interrupt=0 // interrupt enabled when 1
            ,rigor     //const int rigor=0
            ,verbose   //const int verbose=0
            ,performance     //const int performance=0
            );
    }
    //--------------------------------------------------------------------------
    for (int idx=0; idx<3; idx++) {
        #if defined(DEBUG)
        myInfo("=========== [Linear1d %d]\n", idx);
        #endif
        dlb::Linear1d<TYPE>
            (fc_sw_out_data    [idx]//      TYPE * const sw_out_data // out_size
            ,fc_sw_in_data     [idx]//const TYPE * const sw_in_data  // in_size
            ,fc_sw_weight      [idx]//const TYPE * const sw_weight   // out_size x in_size
            ,fc_sw_bias        [idx]//const TYPE * const sw_bias     // out_size
            ,fc_hw_result_addr [idx]//const uint32_t  hw_result_addr // out_size
            ,fc_hw_feature_addr[idx]//const uint32_t  hw_feature_addr // in_size
            ,fc_hw_weight_addr [idx]//const uint32_t  hw_weight_addr  // out_size x in_size
            ,fc_hw_bias_addr   [idx]//const uint32_t  hw_bias_addr  // out_size
            ,fc_out_size       [idx]//const uint16_t  out_size
            ,fc_in_size        [idx]//const uint16_t  in_size
            ,fc_bias_size      [idx]//const uint16_t  bias_size    // should be 0 or out_size
            ,fc_activ_func     [idx]//const uint8_t   activ_func=0
            ,fc_activ_param    [idx]//const uint32_t  activ_param=0
            ,interrupt //const int interrupt=0 // interrupt enabled when 1
            ,rigor     //const int rigor=0
            ,verbose   //const int verbose=0
            ,performance     //const int performance=0
            );
    }
    //--------------------------------------------------------------------------
    return 0;
}

//------------------------------------------------------------------------------
