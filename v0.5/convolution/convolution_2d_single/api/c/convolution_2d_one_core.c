//------------------------------------------------------------------------------
// Copyright (c) 2021-2024-2025 by Future Design Systems, Ltd.
// All right reserved.
//
// http://www.future-ds.com
//------------------------------------------------------------------------------
// VERSION = 2025.01.11.
//------------------------------------------------------------------------------
#include <stdio.h>
#include <string.h>

#include "defines_dpu.h"
#include "convolution_2d_one_core.h"

//------------------------------------------------------------------------------
// Register or Memory access macros
// BFM_WRITE(): write a word (32-bit)
// BFM_READ(): read a word (32-bit)
// BFM_WRITE_BURST(): write a burst of words
// BFM_READ_BURST(): read a burst of words
//
#if defined(COSIM_BFM)
    #   include "cosim_bfm_api.h"
        // move 4-byte single
    #   define BFM_WRITE(A, B)           bfm_write((uint32_t)(A), (uint8_t*)&(B), 4, 1)
    #   define BFM_READ(A, B)            bfm_read ((uint32_t)(A), (uint8_t*)&(B), 4, 1)
        // move 4-byte burst
    #   define BFM_WRITE_BURST(A, P, L)  bfm_write((uint32_t)(A), (uint8_t*)(P), 4, (int)(L))
    #   define BFM_READ_BURST(A, P, L)   bfm_read ((uint32_t)(A), (uint8_t*)(P), 4, (int)(L))
        // move S-byte burst
    #   define BFM_WRITE_ONE(A, P, S, L) bfm_write((uint32_t)(A), (uint8_t*)(P), (S), (L))
    #   define BFM_READ_ONE(A, P, S, L)  bfm_read ((uint32_t)(A), (uint8_t*)(P), (S), (L))
#elif defined(TRX_BFM)||defined(TRX_AXI)||defined(TRX_AHB)
    #   include "bfm_api.h"
        extern con_Handle_t handle;
    #   define BFM_WRITE(A, B)          BfmWrite(handle, (unsigned int)(A), (unsigned int*)&(B), 4, 1)
    #   define BFM_READ(A, B)           BfmRead (handle, (unsigned int)(A), (unsigned int*)&(B), 4, 1)
    #   define BFM_WRITE_BURST(A, P, L) BfmWrite(handle, (unsigned int)(A), (unsigned int*)(P), 4, (unsigned int)(L))
    #   define BFM_READ_BURST(A, P, L)  BfmRead (handle, (unsigned int)(A), (unsigned int*)(P), 4, (unsigned int)(L))
#else
    #   define BFM_WRITE(A, B)          *(unsigned int *)(A) = (B);
    #   define BFM_READ(A, B)           (B) = *(unsigned int *)(A);
    #   define BFM_WRITE_BURST(A, P, L) for (int i=0; i<(L); i++) { *(unsigned *)(A) = (B); ((unsigned int *)(A))++; ((unsigned int *)(B))++; }
    #   define BFM_READ_BURST(A, P, L)  for (int i=0; i<(L); i++) { (B) = *(unsigned int *)(A); ((unsigned int *)(A))++; ((unsigned int *)(B))++; }
#endif

//------------------------------------------------------------------------------
// Hardware address
#ifdef  DPU_ADDR_BASE_CONV
//#pragma GCC warning DPU_ADDR_BASE_CONV should be defined.
static unsigned long int  CSRA_CONV2D_BASE=DPU_ADDR_BASE_CONV;
#else
static unsigned long int  CSRA_CONV2D_BASE=0xC0000000L;
#endif

static unsigned long int  CSRA_CONV2D_VERSION        =(CSRA_CONV2D_BASE+0x00);
static unsigned long int  CSRA_CONV2D_CONTROL        =(CSRA_CONV2D_BASE+0x10);
static unsigned long int  CSRA_CONV2D_CONFIG         =(CSRA_CONV2D_BASE+0x14);
static unsigned long int  CSRA_CONV2D_CONFIG_FIFO    =(CSRA_CONV2D_BASE+0x18);

static unsigned long int  CSRA_CONV2D_KNL_ADDR_LOW   =(CSRA_CONV2D_BASE+0x20);
static unsigned long int  CSRA_CONV2D_KNL_ADDR_HIGH  =(CSRA_CONV2D_BASE+0x24);
static unsigned long int  CSRA_CONV2D_KNL_CFG        =(CSRA_CONV2D_BASE+0x28);
static unsigned long int  CSRA_CONV2D_KNL_BURST      =(CSRA_CONV2D_BASE+0x30);

static unsigned long int  CSRA_CONV2D_FTU_ADDR_LOW   =(CSRA_CONV2D_BASE+0x40);
static unsigned long int  CSRA_CONV2D_FTU_ADDR_HIGH  =(CSRA_CONV2D_BASE+0x44);
static unsigned long int  CSRA_CONV2D_FTU_CFG_SIZE   =(CSRA_CONV2D_BASE+0x48);
static unsigned long int  CSRA_CONV2D_FTU_CFG_KNL    =(CSRA_CONV2D_BASE+0x4C);
static unsigned long int  CSRA_CONV2D_FTU_ITEMS      =(CSRA_CONV2D_BASE+0x50);
static unsigned long int  CSRA_CONV2D_FTU_BURST      =(CSRA_CONV2D_BASE+0x54);

static unsigned long int  CSRA_CONV2D_CHN_ADDR_LOW   =(CSRA_CONV2D_BASE+0x60);
static unsigned long int  CSRA_CONV2D_CHN_ADDR_HIGH  =(CSRA_CONV2D_BASE+0x64);
static unsigned long int  CSRA_CONV2D_CHN_CFG_SIZE   =(CSRA_CONV2D_BASE+0x68);
static unsigned long int  CSRA_CONV2D_CHN_ITEMS      =(CSRA_CONV2D_BASE+0x6C);
static unsigned long int  CSRA_CONV2D_CHN_BURST      =(CSRA_CONV2D_BASE+0x70);

static unsigned long int  CSRA_CONV2D_RST_ADDR_LOW   =(CSRA_CONV2D_BASE+0x80);
static unsigned long int  CSRA_CONV2D_RST_ADDR_HIGH  =(CSRA_CONV2D_BASE+0x84);
static unsigned long int  CSRA_CONV2D_RST_CFG_SIZE   =(CSRA_CONV2D_BASE+0x88);
static unsigned long int  CSRA_CONV2D_RST_ITEMS      =(CSRA_CONV2D_BASE+0x8C);
static unsigned long int  CSRA_CONV2D_RST_BURST      =(CSRA_CONV2D_BASE+0x90);

static unsigned long int  CSRA_CONV2D_MAC_BIAS       =(CSRA_CONV2D_BASE+0xA0);
static unsigned long int  CSRA_CONV2D_MAC_ACTIV_FUNC =(CSRA_CONV2D_BASE+0xA4);
static unsigned long int  CSRA_CONV2D_MAC_ACTIV_PARAM=(CSRA_CONV2D_BASE+0xA8);

static unsigned long int  CSRA_CONV2D_PROFILE_CTL    =(CSRA_CONV2D_BASE+0xB0);
static unsigned long int  CSRA_CONV2D_PROFILE_CYCLES =(CSRA_CONV2D_BASE+0xB4); // num of cycles (x10)
static unsigned long int  CSRA_CONV2D_PROFILE_MAC_NUM=(CSRA_CONV2D_BASE+0xB8); // num of MAC operations
static unsigned long int  CSRA_CONV2D_PROFILE_MAC_OVR=(CSRA_CONV2D_BASE+0xBC); // num of overflow while MAC operations
static unsigned long int  CSRA_CONV2D_PROFILE_CHN_OVR=(CSRA_CONV2D_BASE+0xC0); // num of overflow while adding channels
static unsigned long int  CSRA_CONV2D_PROFILE_BIA_OVR=(CSRA_CONV2D_BASE+0xC4); // num of overflow while adding bias
static unsigned long int  CSRA_CONV2D_PROFILE_ACT_OVR=(CSRA_CONV2D_BASE+0xC8); // num of overflow while activation
static unsigned long int  CSRA_CONV2D_PROFILE_CNT_RD =(CSRA_CONV2D_BASE+0xCC); // num of read
static unsigned long int  CSRA_CONV2D_PROFILE_CNT_WR =(CSRA_CONV2D_BASE+0xD0); // num of write

//------------------------------------------------------------------------------
#define OFFSET_CONV2D_ctl_init         31
#define OFFSET_CONV2D_ctl_ready        30
#define OFFSET_CONV2D_ctl_ip           29
#define OFFSET_CONV2D_ctl_ie           28
#define OFFSET_CONV2D_ctl_result_done  11
#define OFFSET_CONV2D_ctl_channel_done 10
#define OFFSET_CONV2D_ctl_feature_done 9
#define OFFSET_CONV2D_ctl_kernel_done  8
#define OFFSET_CONV2D_ctl_result_go    3
#define OFFSET_CONV2D_ctl_channel_go   2
#define OFFSET_CONV2D_ctl_feature_go   1
#define OFFSET_CONV2D_ctl_kernel_go    0

#define OFFSET_CONV2D_cfg_data_type    16
#define OFFSET_CONV2D_cfg_data_Q       8
#define OFFSET_CONV2D_cfg_data_N       0

#define OFFSET_CONV2D_kernel_items     8  //15:8
#define OFFSET_CONV2D_kernel_height    4  //7:4
#define OFFSET_CONV2D_kernel_width     0  //3:0

#define OFFSET_CONV2D_feature_height       16 // bit-31:16
#define OFFSET_CONV2D_feature_width        0  // bit-15:0
#define OFFSET_CONV2D_feature_padding_post 12 // bit-15:12
#define OFFSET_CONV2D_feature_padding_pre  8  // bit-11:8
#define OFFSET_CONV2D_feature_stride       0  // bit-3:0

#define OFFSET_CONV2D_result_height   16 // bit-31:16
#define OFFSET_CONV2D_result_width    0  // bit-15:0

#define OFFSET_CONV2D_channel_height  16 // bit-31:16
#define OFFSET_CONV2D_channel_width   0  // bit-15:0

#define ACTIV_FUNC_BYPASS       0x0
#define ACTIV_FUNC_RELU         0x1
#define ACTIV_FUNC_LEAKY_RELU   0x2
#define ACTIV_FUNC_SIGMOID      0x3
#define ACTIV_FUNC_TANH         0x4

//------------------------------------------------------------------------------
#if defined(DEBUG) || defined(RIGOR)
#define PRINTF(format, ...) printf("%s(): " format, __func__, ##__VA_ARGS__)
#else
#define PRINTF(...) do { } while (0)
#endif

static int func_result_size( const uint8_t  kernel_size
                           , const uint16_t feature_size
                           , const uint8_t  stride
                           , const uint8_t  padding_pre
                           , const uint8_t  padding_post);
static int kernel_set( const uint64_t addr_mem  // space for filter(kernel)
                     , const uint8_t  width // 4-bit width (num of items)
                     , const uint8_t  height // 4-bit
                     , const uint16_t leng);// upto 256, burst length (not AxLENG format)
static int feature_set( const uint64_t addr_mem // space for filter(feature)
                      , const uint16_t width // width (num of items)
                      , const uint16_t height // width (num of items)
                      , const uint8_t  stride // width (num of items)
                      , const uint8_t  padding_pre // width (num of items)
                      , const uint8_t  padding_post // width (num of items)
                      , const uint16_t leng);// burst length (not AxLENG format)
static int result_set( const uint64_t addr_mem // space for filter(feature)
                     , const uint16_t width // width (num of items)
                     , const uint16_t height
                     , const uint16_t leng);// burst length (not AxLENG format)
static int channel_set( const uint64_t addr_mem // space for filter(feature)
                      , const uint16_t width // width (num of items)
                      , const uint16_t height
                      , const uint16_t leng);// burst length (not AxLENG format)

//------------------------------------------------------------------------------
// It only sets up HW to deal with one convolution,
// 'conv_go_wait()' should be called to carry out convolution.
//
// Note:
// * result_width/height is calculated by using kernel_width/height, feature_width/height
//                                      stride, padding.
// * channel_width/height is the same as result_width/height.
// * kerenel_num is calculated by using result_width/height;
int conv_set( const uint64_t result_addr
            , const uint16_t result_leng // not AxLENG format
            , const uint64_t feature_addr
            , const uint16_t feature_width
            , const uint16_t feature_height
            , const uint8_t  feature_stride
            , const uint8_t  feature_padding_pre
            , const uint8_t  feature_padding_post
            , const uint16_t feature_leng // not AxLENG format
            , const uint64_t kernel_addr
            , const uint8_t  kernel_width
            , const uint8_t  kernel_height
            , const uint16_t kernel_leng // not AxLENG format
            , const uint64_t channel_addr // to deal of multi-in-channel case
            , const uint16_t channel_leng // 0 if not used (not AxLENG format)
            , const uint32_t bias_value
            , const uint8_t  activ_func
            , const uint32_t activ_param )
{
    #if defined(DEBUG)
    PRINTF("result_addr         : 0x%lX\n",  result_addr         );
    PRINTF("result_leng         : 0x%u\n",   result_leng         );
    PRINTF("feature_addr        : 0x%lX\n",  feature_addr        );
    PRINTF("feature_width       : %u\n",     feature_width       );
    PRINTF("feature_height      : %u\n",     feature_height      );
    PRINTF("feature_stride      : %u\n",     feature_stride      );
    PRINTF("feature_padding_pre : %u\n",     feature_padding_pre );
    PRINTF("feature_padding_post: %u\n",     feature_padding_post);
    PRINTF("feature_leng        : %u\n",     feature_leng        );
    PRINTF("kernel_addr         : 0x%lX\n",  kernel_addr         );
    PRINTF("kernel_width        : %u\n",     kernel_width        );
    PRINTF("kernel_height       : %u\n",     kernel_height       );
    PRINTF("kernel_leng         : %u\n",     kernel_leng         );
    PRINTF("channel_addr        : 0x%lX\n",  channel_addr        );
    PRINTF("channel_leng        : %u\n",     channel_leng        );
    PRINTF("bias_value          : 0x%08X\n", bias_value          );
    PRINTF("activ_func          : %d\n",     activ_func          );
    PRINTF("activ_param         : 0x%08X\n", activ_param         ); fflush(stdout);
    #endif

    uint16_t channel_width; // 0 if not used
    uint16_t channel_height; // 0 if not used
    uint16_t result_width;
    uint16_t result_height;

    result_width = func_result_size( kernel_width, feature_width, feature_stride
                                   , feature_padding_pre, feature_padding_post);
    result_height = func_result_size( kernel_height, feature_height, feature_stride
                                    , feature_padding_pre, feature_padding_post);

    #if defined(RIGOR)
    uint8_t N;
    conv_get_config(NULL, NULL, &N, NULL, NULL, NULL, NULL);

    uint64_t result_end  = result_addr + result_width*result_height*(N/8) - 1;
    uint64_t feature_end = feature_addr+ feature_width*feature_height*(N/8) - 1;
    uint64_t kernel_end  = kernel_addr + kernel_width*kernel_height*(N/8) - 1;

    if ((((result_addr>=feature_addr)&&(result_addr<=feature_end)))||
        (((result_end >=feature_addr)&&(result_end <=feature_end)))) {
        PRINTF("ERROR result-feature overlapped: feature=0x%08lX:%08lX result=0x%08lX:%08lX.\n",
                feature_addr, feature_end, result_addr, result_end);
    }
    if ((((result_addr>=kernel_addr )&&(result_addr<=kernel_end )))||
        (((result_end >=kernel_addr )&&(result_end <=kernel_end )))) {
        PRINTF("ERROR result-kernel overlapped: kernel=0x%08lX:%08lX result=0x%08lX:%08lX.\n",
                kernel_addr, kernel_end, result_addr, result_end);
    }
    if ((((feature_addr>=kernel_addr)&&(feature_addr<=kernel_end)))||
        (((feature_end >=kernel_addr)&&(feature_end <=kernel_end)))) {
        PRINTF("ERROR feature-kernel overlapped: feature=0x%08lX:%08lX kernel=0x%08lX:%08lX.\n",
                feature_addr, feature_end, kernel_addr, kernel_end);
    }
    #endif


    kernel_set( kernel_addr
              , kernel_width
              , kernel_height
              , kernel_leng);
    //kernel_fill(kernel_addr, kernel_width, kernel_height);

    feature_set( feature_addr
               , feature_width
               , feature_height
               , feature_stride
               , feature_padding_pre
               , feature_padding_post
               , feature_leng);
    //feature_fill(feature_addr, feature_width, feature_height);

    result_set(result_addr, result_width, result_height, result_leng);
    //result_clear(result_addr, result_width, result_height);

    if (channel_leng==0) {
        channel_width = 0;
        channel_height = 0;
    } else {
        channel_width  = result_width;
        channel_height = result_height;
    }
    channel_set(channel_addr, channel_width, channel_height, channel_leng);

    BFM_WRITE(CSRA_CONV2D_MAC_BIAS, bias_value);

    uint32_t activ_func32 = activ_func;
    BFM_WRITE(CSRA_CONV2D_MAC_ACTIV_FUNC , activ_func32);
    BFM_WRITE(CSRA_CONV2D_MAC_ACTIV_PARAM, activ_param );
    #if defined(RIGOR)
    if ((activ_func==ACTIV_FUNC_SIGMOID)||
        (activ_func==ACTIV_FUNC_TANH)) {
        PRINTF("activation function not implemented yet.\n");
    }
    #endif

    return 0;
}

//------------------------------------------------------------------------------
int conv_go_wait( const uint8_t ie // make interrupt enabled
                , const uint8_t blocking) // make blocking to wait for complete
{
    uint32_t dataW, dataR;
    BFM_READ(CSRA_CONV2D_CONTROL, dataR);
    dataW = dataR
          | (1<<OFFSET_CONV2D_ctl_result_go )
          | (1<<OFFSET_CONV2D_ctl_channel_go)
          | (1<<OFFSET_CONV2D_ctl_feature_go)
          | (1<<OFFSET_CONV2D_ctl_kernel_go );
    if (ie) dataW |= (1<<OFFSET_CONV2D_ctl_ie);
    BFM_WRITE(CSRA_CONV2D_CONTROL, dataW);
    if (blocking) {
        do { BFM_READ(CSRA_CONV2D_CONTROL, dataR);
        } while (dataR&((1<<OFFSET_CONV2D_ctl_result_go )
                       |(1<<OFFSET_CONV2D_ctl_channel_go)
                       |(1<<OFFSET_CONV2D_ctl_feature_go)
                       |(1<<OFFSET_CONV2D_ctl_kernel_go )));
    }
    #if defined(RIGOR)
    BFM_READ(CSRA_CONV2D_CONTROL, dataR);
    if (dataR&( (1<<OFFSET_CONV2D_ctl_result_done )
               |(1<<OFFSET_CONV2D_ctl_channel_done)
               |(1<<OFFSET_CONV2D_ctl_feature_done)
               |(1<<OFFSET_CONV2D_ctl_kernel_done ) 
               |(1<<OFFSET_CONV2D_ctl_result_go   )
               |(1<<OFFSET_CONV2D_ctl_channel_go  )
               |(1<<OFFSET_CONV2D_ctl_feature_go  )
               |(1<<OFFSET_CONV2D_ctl_kernel_go   ))) {
        PRINTF("go-done error.");
    }
    #endif
    return 0;
}

//------------------------------------------------------------------------------
static int func_result_size( const uint8_t  kernel_size
                           , const uint16_t feature_size
                           , const uint8_t  stride
                           , const uint8_t  padding_pre
                           , const uint8_t  padding_post)
{
    return (((feature_size-kernel_size+(padding_pre+padding_post))/stride)+1);
}

//------------------------------------------------------------------------------
static int kernel_set( const uint64_t addr_mem  // space for filter(kernel)
                     , const uint8_t  width // 4-bit width (num of items)
                     , const uint8_t  height // 4-bit
                     , const uint16_t leng) // upto 256, burst length (not AxLENG format)
{
    uint16_t items;
    uint32_t data;
    data = addr_mem&0xFFFFFFFF;
    BFM_WRITE(CSRA_CONV2D_KNL_ADDR_LOW, data);
    data = (addr_mem>>32)&0xFFFFFFFF;
    BFM_WRITE(CSRA_CONV2D_KNL_ADDR_HIGH, data);
    items = width*height;
    data = (items&0xFF)<<OFFSET_CONV2D_kernel_items
         | (height&0xF)<<OFFSET_CONV2D_kernel_height
         | (width&0xF)<<OFFSET_CONV2D_kernel_width;
    BFM_WRITE(CSRA_CONV2D_KNL_CFG, data);
    data = (leng<=0) ? 0 : (leng-1)&0xFF; // mind AxLENG format
    BFM_WRITE(CSRA_CONV2D_KNL_BURST, data);
    return 0;
}

//------------------------------------------------------------------------------
static int feature_set( const uint64_t addr_mem // space for filter(feature)
                      , const uint16_t width // width (num of items)
                      , const uint16_t height // width (num of items)
                      , const uint8_t  stride // width (num of items)
                      , const uint8_t  padding_pre // width (num of items)
                      , const uint8_t  padding_post // width (num of items)
                      , const uint16_t leng) // burst length (not AxLENG format)
{
    uint32_t data;
    data = addr_mem&0xFFFFFFFF;
    BFM_WRITE(CSRA_CONV2D_FTU_ADDR_LOW, data);
    data = (addr_mem>>32)&0xFFFFFFFF;
    BFM_WRITE(CSRA_CONV2D_FTU_ADDR_HIGH, data);
    data = (height&0xFFFF)<<OFFSET_CONV2D_feature_height
         | (width&0xFFFF)<<OFFSET_CONV2D_feature_width;
    BFM_WRITE(CSRA_CONV2D_FTU_CFG_SIZE, data);
    data = (padding_post&0xF)<<OFFSET_CONV2D_feature_padding_post
         | (padding_pre&0xF)<<OFFSET_CONV2D_feature_padding_pre
         | (stride&0xF)<<OFFSET_CONV2D_feature_stride;
    BFM_WRITE(CSRA_CONV2D_FTU_CFG_KNL, data);
    data = width*height;
    BFM_WRITE(CSRA_CONV2D_FTU_ITEMS, data);
    data = (leng<=0) ? 0 : (leng-1)&0xFF; // make AxLENG format
    BFM_WRITE(CSRA_CONV2D_FTU_BURST, data); // mind AxLENG format
    return 0;
}

//------------------------------------------------------------------------------
static int result_set( const uint64_t addr_mem // space for filter(feature)
                     , const uint16_t width // width (num of items)
                     , const uint16_t height
                     , const uint16_t leng) // burst length (not AxLENG format)
{
    uint32_t data;
    data = addr_mem&0xFFFFFFFF;
    BFM_WRITE(CSRA_CONV2D_RST_ADDR_LOW, data);
    data = (addr_mem>>32)&0xFFFFFFFF;
    BFM_WRITE(CSRA_CONV2D_RST_ADDR_HIGH, data);
    data = (height&0xFFFF)<< OFFSET_CONV2D_result_height
         | (width&0xFFFF)<<OFFSET_CONV2D_result_width;
    BFM_WRITE(CSRA_CONV2D_RST_CFG_SIZE, data);
    data = height*width;
    BFM_WRITE(CSRA_CONV2D_RST_ITEMS, data);
    data = (leng<=0) ? 0 : (leng-1)&0xFF; // make AxLENG format
    BFM_WRITE(CSRA_CONV2D_RST_BURST, data); // mind AxLENG format
    return 0;
}

//------------------------------------------------------------------------------
// previous convolution result.
static int channel_set( const uint64_t addr_mem // space for filter(feature)
                      , const uint16_t width // width (num of items)
                      , const uint16_t height
                      , const uint16_t leng) // burst length (not AxLENG format)
{
    uint32_t data;
    data = addr_mem&0xFFFFFFFF;
    BFM_WRITE(CSRA_CONV2D_CHN_ADDR_LOW, data);
    data = (addr_mem>>32)&0xFFFFFFFF;
    BFM_WRITE(CSRA_CONV2D_CHN_ADDR_HIGH, data);
    data = (height&0xFFFF)<<OFFSET_CONV2D_channel_height
         | (width&0xFFFF)<<OFFSET_CONV2D_channel_width;
    BFM_WRITE(CSRA_CONV2D_CHN_CFG_SIZE, data);
    data = width*height;
    BFM_WRITE(CSRA_CONV2D_CHN_ITEMS, data);
    data = (leng<=0) ? 0 : (leng-1)&0xFF;
    BFM_WRITE(CSRA_CONV2D_CHN_BURST, data); // mind AxLENG format
    return 0;
}

//------------------------------------------------------------------------------
// Drive a pulse of 'init' signal, which auto clean.
int conv_init( void )
{
    uint32_t dataR, dataW;
    BFM_READ(CSRA_CONV2D_CONTROL, dataR);
    dataW = dataR | (1<<OFFSET_CONV2D_ctl_init);

    BFM_WRITE(CSRA_CONV2D_CONTROL, dataR);
    #if defined(RIGOR)
    BFM_READ(CSRA_CONV2D_CONTROL, dataR);
    if (!(dataR&(1<<30))) PRINTF("conv_ready should be 1.");
    if   (dataR&(1<<31))  PRINTF("conv_init should be 0.");
    #endif
    return 0;
}

//------------------------------------------------------------------------------
int conv_clear_interrupt( void )
{
    uint32_t dataW, dataR;
    BFM_READ(CSRA_CONV2D_CONTROL, dataR);
    dataW = dataR & ~(1<<OFFSET_CONV2D_ctl_ip);
    BFM_WRITE(CSRA_CONV2D_CONTROL, dataW);
    return 0;
}

//------------------------------------------------------------------------------
int conv_get_interrupt( uint8_t * const ip
                      , uint8_t * const ie )
{
    uint32_t dataR;
    BFM_READ(CSRA_CONV2D_CONTROL, dataR);
    if (ip) *ip = (dataR&(1<<OFFSET_CONV2D_ctl_ip)) ? 1 : 0;
    if (ie) *ie = (dataR&(1<<OFFSET_CONV2D_ctl_ie)) ? 1 : 0;
    return 0;
}

//------------------------------------------------------------------------------
int conv_get_config( char    * const data_type
                   , uint8_t * const Q // num of bits of fractional part
                   , uint8_t * const N // num of bits of whole part
                   , uint8_t * const kernel_fifo_dpeth
                   , uint8_t * const feature_fifo_dpeth
                   , uint8_t * const channel_fifo_dpeth
                   , uint8_t * const result_fifo_dpeth )
{
    uint32_t dataR;
    BFM_READ(CSRA_CONV2D_CONFIG, dataR);
    if (data_type) {
        uint16_t dt = (dataR>>OFFSET_CONV2D_cfg_data_type)&0xFFFF;
        memcpy(data_type, (void*)&dt, 2);
    }
    if (N) *N =  dataR&0xFF;
    if (Q) *Q = (dataR>>OFFSET_CONV2D_cfg_data_Q)&0xFF;
    BFM_READ(CSRA_CONV2D_CONFIG_FIFO, dataR);
    if (kernel_fifo_dpeth ) *kernel_fifo_dpeth  = (dataR&0x000000FF)>> 0;
    if (feature_fifo_dpeth) *feature_fifo_dpeth = (dataR&0x0000FF00)>> 8;
    if (channel_fifo_dpeth) *channel_fifo_dpeth = (dataR&0x00FF0000)>>16;
    if (result_fifo_dpeth ) *result_fifo_dpeth  = (dataR&0xFF000000)>>24;
    return 0;
}

//------------------------------------------------------------------------------
// Get the version
uint32_t conv_version()
{
    uint32_t dataR;
    BFM_READ(CSRA_CONV2D_VERSION, dataR);
    return dataR;
}

//------------------------------------------------------------------------------
int conv_profile_init( void )
{
    uint32_t dataW = 1<<31;
    BFM_WRITE(CSRA_CONV2D_PROFILE_CTL, dataW);
    return 0;
}

//------------------------------------------------------------------------------
int conv_profile_get( uint32_t * const profile_cycles
                    , uint32_t * const profile_mac_num
                    , uint32_t * const profile_mac_ovr
                    , uint32_t * const profile_chn_ovr
                    , uint32_t * const profile_bia_ovr
                    , uint32_t * const profile_act_ovr
                    , uint32_t * const profile_cnt_rd
                    , uint32_t * const profile_cnt_wr)
{
    uint32_t data=1;
    BFM_WRITE(CSRA_CONV2D_PROFILE_CTL, data);
    do { BFM_READ(CSRA_CONV2D_PROFILE_CTL, data);
    } while ((data&0x3)!=0);
    if (profile_cycles ) { BFM_READ(CSRA_CONV2D_PROFILE_CYCLES ,data); *profile_cycles =data; }
    if (profile_mac_num) { BFM_READ(CSRA_CONV2D_PROFILE_MAC_NUM,data); *profile_mac_num=data; }
    if (profile_mac_ovr) { BFM_READ(CSRA_CONV2D_PROFILE_MAC_OVR,data); *profile_mac_ovr=data; }
    if (profile_chn_ovr) { BFM_READ(CSRA_CONV2D_PROFILE_CHN_OVR,data); *profile_chn_ovr=data; }
    if (profile_bia_ovr) { BFM_READ(CSRA_CONV2D_PROFILE_BIA_OVR,data); *profile_bia_ovr=data; }
    if (profile_act_ovr) { BFM_READ(CSRA_CONV2D_PROFILE_ACT_OVR,data); *profile_act_ovr=data; }
    if (profile_cnt_rd ) { BFM_READ(CSRA_CONV2D_PROFILE_CNT_RD ,data); *profile_cnt_rd =data; }
    if (profile_cnt_wr ) { BFM_READ(CSRA_CONV2D_PROFILE_CNT_WR ,data); *profile_cnt_wr =data; }
    return 0;
}

//------------------------------------------------------------------------------
int conv_csr_test( void )
{
    uint32_t data;
    #define RCT(A,S) BFM_READ((A),data); PRINTF("A:0x%08lX D:0x%08X %s\n", (A), data, #S)
    RCT(CSRA_CONV2D_VERSION        ,"VERSION        ");
    RCT(CSRA_CONV2D_CONTROL        ,"CONTROL        ");
    RCT(CSRA_CONV2D_CONFIG         ,"CONFIG         ");
    RCT(CSRA_CONV2D_CONFIG_FIFO    ,"CONFIG_FIFO    ");
    RCT(CSRA_CONV2D_KNL_ADDR_LOW   ,"KNL_ADDR_LOW   ");
    RCT(CSRA_CONV2D_KNL_ADDR_HIGH  ,"KNL_ADDR_HIGH  ");
    RCT(CSRA_CONV2D_KNL_CFG        ,"KNL_CFG        ");
    RCT(CSRA_CONV2D_KNL_BURST      ,"KNL_BURST      ");
    RCT(CSRA_CONV2D_FTU_ADDR_LOW   ,"FTU_ADDR_LOW   ");
    RCT(CSRA_CONV2D_FTU_ADDR_HIGH  ,"FTU_ADDR_HIGH  ");
    RCT(CSRA_CONV2D_FTU_CFG_SIZE   ,"FTU_CFG_SIZE   ");
    RCT(CSRA_CONV2D_FTU_CFG_KNL    ,"FTU_CFG_KNL    ");
    RCT(CSRA_CONV2D_FTU_ITEMS      ,"FTU_ITEMS      ");
    RCT(CSRA_CONV2D_FTU_BURST      ,"FTU_BURST      ");
    RCT(CSRA_CONV2D_CHN_ADDR_LOW   ,"CHN_ADDR_LOW   ");
    RCT(CSRA_CONV2D_CHN_ADDR_HIGH  ,"CHN_ADDR_HIGH  ");
    RCT(CSRA_CONV2D_CHN_CFG_SIZE   ,"CHN_CFG_SIZE   ");
    RCT(CSRA_CONV2D_CHN_ITEMS      ,"CHN_ITEMS      ");
    RCT(CSRA_CONV2D_CHN_BURST      ,"CHN_BURST      ");
    RCT(CSRA_CONV2D_RST_ADDR_LOW   ,"RST_ADDR_LOW   ");
    RCT(CSRA_CONV2D_RST_ADDR_HIGH  ,"RST_ADDR_HIGH  ");
    RCT(CSRA_CONV2D_RST_CFG_SIZE   ,"RST_CFG_SIZE   ");
    RCT(CSRA_CONV2D_RST_ITEMS      ,"RST_ITEMS      ");
    RCT(CSRA_CONV2D_RST_BURST      ,"RST_BURST      ");
    RCT(CSRA_CONV2D_MAC_BIAS       ,"MAC_BIAS       ");
    RCT(CSRA_CONV2D_MAC_ACTIV_FUNC ,"MAC_ACTIV_FUNC ");
    RCT(CSRA_CONV2D_MAC_ACTIV_PARAM,"MAC_ACTIV_PARAM");
    RCT(CSRA_CONV2D_PROFILE_CTL    ,"PROFILE_CTL    ");
    RCT(CSRA_CONV2D_PROFILE_CYCLES ,"PROFILE_CYCLES ");
    RCT(CSRA_CONV2D_PROFILE_MAC_NUM,"PROFILE_MAC_NUM");
    RCT(CSRA_CONV2D_PROFILE_MAC_OVR,"PROFILE_MAC_OVR");
    RCT(CSRA_CONV2D_PROFILE_CHN_OVR,"PROFILE_CHN_OVR");
    RCT(CSRA_CONV2D_PROFILE_BIA_OVR,"PROFILE_BIA_OVR");
    RCT(CSRA_CONV2D_PROFILE_ACT_OVR,"PROFILE_ACT_OVR");
    RCT(CSRA_CONV2D_PROFILE_CNT_RD ,"PROFILE_CNT_RD ");
    RCT(CSRA_CONV2D_PROFILE_CNT_WR ,"PROFILE_CNT_WR ");
    #undef RCT
    return 0;
}

//------------------------------------------------------------------------------
// It reads a block from SW buffer and then writes them to the HW.
int conv_write_block_to_hw( const uint64_t hw_dst // hw address
                          ,       uint8_t * const sw_src // sw address
                          , const uint32_t bnum ) // num of bytes
{
    if (((hw_dst&0x3L)!=0)||((((unsigned long long)sw_src)&0x3L)!=0)) {
        PRINTF("ERROR mis-aligned access\n");
    }
    uint32_t addr_dst=hw_dst&0xFFFFFFFF;
    uint8_t *addr_src=sw_src;
    uint32_t moved=0;
    while ((bnum-moved)>=(256*4)) {
        BFM_WRITE_BURST(addr_dst, addr_src, 256); // 4-byte word unit
        addr_dst += 256*4;
        addr_src += 256*4;
        moved    += 256*4;
    }
    if ((bnum-moved)>0) {
        int len=(bnum-moved)/4;
        BFM_WRITE_BURST(addr_dst, addr_src, len); // 4-byte word unit
        addr_dst += len*4;
        addr_src += len*4;
        moved    += len*4;
    }
    if ((bnum-moved)>0) {
        #if defined(BFM_AXI)||defined(TRX_AXI)
            unsigned int tmp[4];
            unsigned char *pt= (unsigned char*)addr_src;
            for (int x=0; x<bnum-moved; x++) {
                 tmp[x] = (*pt&0xFF);
                 pt++;
            }
            #if defined(NEW_BFM)
                // use partial-bust enabled BFM (version 2021.10.04)
                BfmWrite(handle, addr_dst, tmp, 1, bnum-moved); // 1-byte word unit
            #else
                for (int x=0; x<bnum-moved; x++) {
printf("write x=%d\n", x);
                     BfmWrite(handle, addr_dst, &tmp[x], 1, 1); // 1-byte word unit
                     addr_dst++;
                }
            #endif
        #else
            int len=bnum-moved;
            BFM_WRITE_ONE(addr_dst, addr_src, 1, len); // 1-byte unit
            moved    += len;
        #endif
    }
    return 0;
}

//------------------------------------------------------------------------------
// It reads a block from HW and then writes them to the SW buffer.
int conv_read_block_from_hw(       uint8_t * const sw_dst // sw address
                           , const uint64_t  hw_src // hw address
                           , const uint32_t  bnum ) // num of bytes
{
    if (((((unsigned long long)sw_dst)&0x3L)!=0)||((hw_src&0x3L)!=0)) {
        PRINTF("ERROR mis-aligned access\n");
    }
    uint8_t *addr_dst=sw_dst; // will be used as a pointer
    uint32_t  addr_src=hw_src&0xFFFFFFFF;
    uint32_t  moved=0;
    while ((bnum-moved)>=(256*4)) {
        BFM_READ_BURST(addr_src, addr_dst, 256); // 4-byte word unit
        addr_dst += 256*4;
        addr_src += 256*4;
        moved    += 256*4;
    }
    if ((bnum-moved)>0) {
        int len=(bnum-moved)/4;
        BFM_READ_BURST(addr_src, addr_dst, len); // 4-byte word unit
        addr_dst += len*4;
        addr_src += len*4;
        moved    += len*4;
    }
    if ((bnum-moved)>0) {
        #if defined(BFM_AXI)||defined(TRX_AXI)
            unsigned int tmp[4];
            unsigned char *pt= (unsigned char*)addr_dst;
            #if defined(NEW_BFM)
                // use partial-bust enabled BFM (version 2021.10.04)
                BfmRead(handle, addr_src, tmp, 1, bnum-moved); // 1-byte word unit
                for (int x=0; x<bnum-moved; x++) {
                     *pt = tmp[x]&0xFF;
                     pt++;
                }
            #else
                for (int x=0; x<bnum-moved; x++) {
printf("read x=%d\n", x);
                    BfmRead(handle, addr_src, &tmp[x], 1, 1); // 1-byte word unit
                    *pt = tmp[x]&0xFF;
                    pt++;
                    addr_src++;
                }
            #endif
        #else
            int len=bnum-moved;
            BFM_READ_ONE(addr_src, addr_dst, 1, len); // 1-byte unit
            moved    += len;
        #endif
    }
    return 0;
}

//------------------------------------------------------------------------------
// It checks data type and return 0 on match, oterwise return negative number.
// * host_dt: data type name, e.g, int, int32_t, float, ap_fixed, half
// * hN: whle bits
// * hQ: fractional bits; valid for only fixed-point
int conv_check_data_type( const char * const host_dt
                        , const int hN
                        , const int hQ )
{
    char data_type[3];
    uint8_t Q, N;
    conv_get_config(data_type, &Q, &N, NULL, NULL, NULL, NULL);
    data_type[2]='\0'; // make normal string
    #define QuoteIdent(ident) #ident
    #define QuoteMacro(macro) QuoteIdent(macro)
    PRINTF("%s %s\n", QuoteMacro(TYPE), data_type);
    if (!strncmp(data_type,"IT", 2)) {
        if (N==32) {
            if (strcmp(host_dt,"int")&&
                strcmp(host_dt,"int32_t")) {
                PRINTF("data type mis-match: %d\n", N);
                return -1;
            }
        } else if (N==16) {
            if (strcmp(host_dt,"short")&&
                strcmp(host_dt,"int16_t")) {
                PRINTF("data type mis-match: %d\n", N);
                return -1;
            }
        } else if (N==8) {
            if (strcmp(host_dt,"char")&&
                strcmp(host_dt,"int8_t")) {
                PRINTF("data type mis-match: %d\n", N);
                return -1;
            }
        } else {
            PRINTF("data type mis-match: %d\n", N);
            return -1;
        }
    } else if (!strncmp(data_type,"FP", 2)) {
        if (strcmp(host_dt,"float")) {
            PRINTF("data type mis-match.\n");
            return -1;
        }
    } else if (!strncmp(data_type,"FX", 2)) {
        PRINTF("data type not supported yet.\n");
        return -1;
    } else {
        PRINTF("data type unsupported.\n");
        return -1;
    }
    return 0;
    #undef QuoteIdent
    #undef QuoteMacro
}

int conv_set_addr( unsigned long int base )
{
    CSRA_CONV2D_BASE = base;

    CSRA_CONV2D_VERSION        =(CSRA_CONV2D_BASE+0x00);
    CSRA_CONV2D_CONTROL        =(CSRA_CONV2D_BASE+0x10);
    CSRA_CONV2D_CONFIG         =(CSRA_CONV2D_BASE+0x14);
    CSRA_CONV2D_CONFIG_FIFO    =(CSRA_CONV2D_BASE+0x18);
    
    CSRA_CONV2D_KNL_ADDR_LOW   =(CSRA_CONV2D_BASE+0x20);
    CSRA_CONV2D_KNL_ADDR_HIGH  =(CSRA_CONV2D_BASE+0x24);
    CSRA_CONV2D_KNL_CFG        =(CSRA_CONV2D_BASE+0x28);
    CSRA_CONV2D_KNL_BURST      =(CSRA_CONV2D_BASE+0x30);
    
    CSRA_CONV2D_FTU_ADDR_LOW   =(CSRA_CONV2D_BASE+0x40);
    CSRA_CONV2D_FTU_ADDR_HIGH  =(CSRA_CONV2D_BASE+0x44);
    CSRA_CONV2D_FTU_CFG_SIZE   =(CSRA_CONV2D_BASE+0x48);
    CSRA_CONV2D_FTU_CFG_KNL    =(CSRA_CONV2D_BASE+0x4C);
    CSRA_CONV2D_FTU_ITEMS      =(CSRA_CONV2D_BASE+0x50);
    CSRA_CONV2D_FTU_BURST      =(CSRA_CONV2D_BASE+0x54);
    
    CSRA_CONV2D_CHN_ADDR_LOW   =(CSRA_CONV2D_BASE+0x60);
    CSRA_CONV2D_CHN_ADDR_HIGH  =(CSRA_CONV2D_BASE+0x64);
    CSRA_CONV2D_CHN_CFG_SIZE   =(CSRA_CONV2D_BASE+0x68);
    CSRA_CONV2D_CHN_ITEMS      =(CSRA_CONV2D_BASE+0x6C);
    CSRA_CONV2D_CHN_BURST      =(CSRA_CONV2D_BASE+0x70);
    
    CSRA_CONV2D_RST_ADDR_LOW   =(CSRA_CONV2D_BASE+0x80);
    CSRA_CONV2D_RST_ADDR_HIGH  =(CSRA_CONV2D_BASE+0x84);
    CSRA_CONV2D_RST_CFG_SIZE   =(CSRA_CONV2D_BASE+0x88);
    CSRA_CONV2D_RST_ITEMS      =(CSRA_CONV2D_BASE+0x8C);
    CSRA_CONV2D_RST_BURST      =(CSRA_CONV2D_BASE+0x90);
    
    CSRA_CONV2D_MAC_BIAS       =(CSRA_CONV2D_BASE+0xA0);
    CSRA_CONV2D_MAC_ACTIV_FUNC =(CSRA_CONV2D_BASE+0xA4);
    CSRA_CONV2D_MAC_ACTIV_PARAM=(CSRA_CONV2D_BASE+0xA8);
    
    CSRA_CONV2D_PROFILE_CTL    =(CSRA_CONV2D_BASE+0xB0);
    CSRA_CONV2D_PROFILE_CYCLES =(CSRA_CONV2D_BASE+0xB4); // num of cycles (x10)
    CSRA_CONV2D_PROFILE_MAC_NUM=(CSRA_CONV2D_BASE+0xB8); // num of MAC operations
    CSRA_CONV2D_PROFILE_MAC_OVR=(CSRA_CONV2D_BASE+0xBC); // num of overflow while MAC operations
    CSRA_CONV2D_PROFILE_CHN_OVR=(CSRA_CONV2D_BASE+0xC0); // num of overflow while adding channels
    CSRA_CONV2D_PROFILE_BIA_OVR=(CSRA_CONV2D_BASE+0xC4); // num of overflow while adding bias
    CSRA_CONV2D_PROFILE_ACT_OVR=(CSRA_CONV2D_BASE+0xC8); // num of overflow while activation
    CSRA_CONV2D_PROFILE_CNT_RD =(CSRA_CONV2D_BASE+0xCC); // num of read
    CSRA_CONV2D_PROFILE_CNT_WR =(CSRA_CONV2D_BASE+0xD0); // num of write

    return 0;
}

unsigned long int conv_get_addr( void )
{
    return CSRA_CONV2D_BASE;
}

//------------------------------------------------------------------------------
#undef PRINTF
#undef BFM_WRITE
#undef BFM_READ
#undef BFM_WRITE_BURST
#undef BFM_READ_BURST

//------------------------------------------------------------------------------
// Revision History
//
// 2025.01.11: minor update
// 2024.12.25: conv_set_addr()/conv_get_addr() added.
// 2021.08.10: Started by Ando Ki (adki@future-ds.com)
//------------------------------------------------------------------------------
