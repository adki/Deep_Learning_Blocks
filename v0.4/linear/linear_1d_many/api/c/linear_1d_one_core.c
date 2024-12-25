//------------------------------------------------------------------------------
// Copyright (c) 2021 by Future Design Systems, Ltd.
// All right reserved.
//
// http://www.future-ds.com
//------------------------------------------------------------------------------
// VERSION = 2021.08.10.
//------------------------------------------------------------------------------
#include <stdio.h>
#include <string.h>

#include "defines_dpu.h"
#include "linear_1d_one_core.h"

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
#ifdef  DPU_ADDR_BASE_LINEAR
//#pragma GCC warning DPU_ADDR_BASE_LINEAR should be defined.
static unsigned long int  CSRA_LINEAR1D_BASE=DPU_ADDR_BASE_LINEAR;
#else
static unsigned long int  CSRA_LINEAR1D_BASE=0xC0002000;
#endif

static unsigned long int CSRA_LINEAR1D_VERSION           =(CSRA_LINEAR1D_BASE+0x00);
static unsigned long int CSRA_LINEAR1D_CONTROL           =(CSRA_LINEAR1D_BASE+0x10);
static unsigned long int CSRA_LINEAR1D_CONFIG            =(CSRA_LINEAR1D_BASE+0x14);
static unsigned long int CSRA_LINEAR1D_CONFIG_FIFO       =(CSRA_LINEAR1D_BASE+0x18);

static unsigned long int CSRA_LINEAR1D_INPUT_ADDR_LOW    =(CSRA_LINEAR1D_BASE+0x20);
static unsigned long int CSRA_LINEAR1D_INPUT_ADDR_HIGH   =(CSRA_LINEAR1D_BASE+0x24);
static unsigned long int CSRA_LINEAR1D_INPUT_CFG         =(CSRA_LINEAR1D_BASE+0x28);
static unsigned long int CSRA_LINEAR1D_INPUT_BURST       =(CSRA_LINEAR1D_BASE+0x30);

static unsigned long int CSRA_LINEAR1D_WEIGHT_ADDR_LOW   =(CSRA_LINEAR1D_BASE+0x40);
static unsigned long int CSRA_LINEAR1D_WEIGHT_ADDR_HIGH  =(CSRA_LINEAR1D_BASE+0x44);
static unsigned long int CSRA_LINEAR1D_WEIGHT_CFG        =(CSRA_LINEAR1D_BASE+0x48);
static unsigned long int CSRA_LINEAR1D_WEIGHT_ITEMS      =(CSRA_LINEAR1D_BASE+0x4C);
static unsigned long int CSRA_LINEAR1D_WEIGHT_BURST      =(CSRA_LINEAR1D_BASE+0x50);

static unsigned long int CSRA_LINEAR1D_BIAS_ADDR_LOW     =(CSRA_LINEAR1D_BASE+0x60);
static unsigned long int CSRA_LINEAR1D_BIAS_ADDR_HIGH    =(CSRA_LINEAR1D_BASE+0x64);
static unsigned long int CSRA_LINEAR1D_BIAS_CFG          =(CSRA_LINEAR1D_BASE+0x68);

static unsigned long int CSRA_LINEAR1D_RST_ADDR_LOW      =(CSRA_LINEAR1D_BASE+0x70);
static unsigned long int CSRA_LINEAR1D_RST_ADDR_HIGH     =(CSRA_LINEAR1D_BASE+0x74);
static unsigned long int CSRA_LINEAR1D_RST_CFG           =(CSRA_LINEAR1D_BASE+0x78);
static unsigned long int CSRA_LINEAR1D_RST_BURST         =(CSRA_LINEAR1D_BASE+0x80);

static unsigned long int CSRA_LINEAR1D_LINEAR_ACTIV_FUNC =(CSRA_LINEAR1D_BASE+0x90);
static unsigned long int CSRA_LINEAR1D_LINEAR_ACTIV_PARAM=(CSRA_LINEAR1D_BASE+0x94);

static unsigned long int CSRA_LINEAR1D_PROFILE_CTL       =(CSRA_LINEAR1D_BASE+0xA0);
static unsigned long int CSRA_LINEAR1D_PROFILE_CYCLES    =(CSRA_LINEAR1D_BASE+0xA4);
static unsigned long int CSRA_LINEAR1D_PROFILE_MAC_NUM   =(CSRA_LINEAR1D_BASE+0xA8);
static unsigned long int CSRA_LINEAR1D_PROFILE_MAC_OVR   =(CSRA_LINEAR1D_BASE+0xAC);
static unsigned long int CSRA_LINEAR1D_PROFILE_BIA_OVR   =(CSRA_LINEAR1D_BASE+0xB0);
static unsigned long int CSRA_LINEAR1D_PROFILE_ACT_OVR   =(CSRA_LINEAR1D_BASE+0xB4);
static unsigned long int CSRA_LINEAR1D_PROFILE_CNT_RD    =(CSRA_LINEAR1D_BASE+0xB8);
static unsigned long int CSRA_LINEAR1D_PROFILE_CNT_WR    =(CSRA_LINEAR1D_BASE+0xBC);

//------------------------------------------------------------------------------
#define OFFSET_LINEAR1D_ctl_init         31
#define OFFSET_LINEAR1D_ctl_ready        30
#define OFFSET_LINEAR1D_ctl_ip           29
#define OFFSET_LINEAR1D_ctl_ie           28
#define OFFSET_LINEAR1D_ctl_result_done  11
#define OFFSET_LINEAR1D_ctl_bias_done    10
#define OFFSET_LINEAR1D_ctl_weight_done  9
#define OFFSET_LINEAR1D_ctl_input_done   8
#define OFFSET_LINEAR1D_ctl_result_go    3
#define OFFSET_LINEAR1D_ctl_bias_go      2
#define OFFSET_LINEAR1D_ctl_weight_go    1
#define OFFSET_LINEAR1D_ctl_input_go     0

#define OFFSET_LINEAR1D_cfg_data_type    16
#define OFFSET_LINEAR1D_cfg_data_Q       8
#define OFFSET_LINEAR1D_cfg_data_N       0

#define OFFSET_LINEAR1D_input_size       0 // 15:0

#define OFFSET_LINEAR1D_weight_height    16 // 31:16
#define OFFSET_LINEAR1D_weight_width     0 // 15:0

#define OFFSET_LINEAR1D_bias_size        0 // 15:0

//------------------------------------------------------------------------------
#if defined(DEBUG)||defined(RIGOR)
#define PRINTF(format, ...) printf("%s(): " format, __func__, ##__VA_ARGS__)
#else
#define PRINTF(...) do { } while (0)
#endif

static int input_set( const uint64_t input_addr
                    , const uint16_t input_size
                    , const uint16_t input_leng);
static int weight_set( const uint64_t weight_addr
                     , const uint16_t weight_width
                     , const uint16_t weight_height
                     , const uint16_t weight_leng);
static int bias_set( const uint64_t bias_addr
                   , const uint16_t bias_size);
static int activ_set( const uint8_t  activ_func
                    , const uint32_t activ_param);
static int result_set( const uint64_t result_addr
                     , const uint16_t result_size
                     , const uint16_t result_leng);

//------------------------------------------------------------------------------
// It only sets up HW to deal with one linear operation,
// 'linear_go_wait()' should be called to carry out vector-matrix multiplication.
//
// Note:
// * result_width/height is calculated by using kernel_width/height, feature_width/height
//                                      stride, padding.
// * channel_width/height is the same as result_width/height.
// * kerenel_num is calculated by using result_width/height;
int linear_set( const uint64_t result_addr // =previous_addr
              , const uint16_t result_size // =weight_height
              , const uint16_t result_leng // =bias_leng (not AxLENG format)
              , const uint64_t input_addr
              , const uint16_t input_size
              , const uint16_t input_leng
              , const uint64_t weight_addr
              , const uint16_t weight_width // =input_size
              , const uint16_t weight_height
              , const uint16_t weight_leng
              , const uint64_t bias_addr
              , const uint16_t bias_size // set 0 for no-bias
              , const uint8_t  activ_func
              , const uint32_t activ_param )
{
    #if defined(DEBUG)
    PRINTF("result_addr  : 0x%lX\n", result_addr  );
    PRINTF("result_size  : %u\n",    result_size  );
    PRINTF("result_leng  : %u\n",    result_leng  );
    PRINTF("input_addr   : 0x%lX\n", input_addr   );
    PRINTF("input_size   : %u\n",    input_size   );
    PRINTF("input_leng   : %u\n",    input_leng   );
    PRINTF("weight_addr  : 0x%lX\n", weight_addr  );
    PRINTF("weight_width : %u\n",    weight_width );
    PRINTF("weight_height: %u\n",    weight_height);
    PRINTF("weight_leng  : %u\n",    weight_leng  );
    PRINTF("bias_addr    : 0x%lX\n", bias_addr    );
    PRINTF("bias_size    : %u\n",    bias_size    );
    PRINTF("activ_func   : %u\n",    activ_func   );
    PRINTF("activ_param  : 0x%X\n",  activ_param  ); fflush(stdout);
    #endif
    #if defined(RIGOR)
    if (input_size!=weight_width)     PRINTF("input_size!=weight_width\n");
    if ((bias_size!=0)&&
        (bias_size!=weight_height))   PRINTF("bias_size!=weight_height\n");
    if (result_size!=weight_height)   PRINTF("result_size!=weight_height\n");
    if (input_leng!=weight_leng)      PRINTF("input_leng!=weight_leng\n");

    uint8_t N;
    linear_get_config( NULL   // data_type
                     , NULL   // Q
                     ,&N      // N
                     , NULL   // input_fifo_dpeth
                     , NULL   // weight_fifo_dpeth
                     , NULL); // result_fifo_dpeth )
    uint64_t result_end = result_addr+result_size*(N/8)-1;
    uint64_t input_end  = input_addr+input_size*(N/8)-1;
    uint64_t weight_end = weight_addr+weight_width*weight_height*(N/8)-1;
    uint64_t bias_end   = bias_addr+bias_size*(N/8)-1;
    if ((((result_addr>=input_addr )&&(result_addr<=input_end )))||
        (((result_end >=input_addr )&&(result_end <=input_end )))) {
        PRINTF("ERROR result-input overlapped: result=0x%08lX:%08lX input=0x%08lX:%08lX.\n",
                result_addr, result_end, input_addr, input_end);
    }
    if ((((result_addr>=weight_addr)&&(result_addr<=weight_end)))||
        (((result_end >=weight_addr)&&(result_end <=weight_end)))) {
        PRINTF("ERROR result-weight overlapped: result=0x%08lX:%08lX weight=0x%08lX:%08lX.\n",
                result_addr, result_end, weight_addr, weight_end);
    }
    if ((((result_addr>=bias_addr  )&&(result_addr<=bias_end  )))||
        (((result_end >=bias_addr  )&&(result_end <=bias_end  )))) {
        PRINTF("ERROR result-bias overlapped: result=0x%08lX:%08lX bias=0x%08lX:%08lX.\n",
                result_addr, result_end, bias_addr, bias_end);
    }

    if ((((input_addr>=weight_addr)&&(input_addr<=weight_end)))||
        (((input_end >=weight_addr)&&(input_end <=weight_end)))) {
        PRINTF("ERROR input-weight overlapped: input=0x%08lX:%08lX weight=0x%08lX:%08lX.\n",
                input_addr, input_end, weight_addr, weight_end);
    }
    if ((((input_addr>=bias_addr  )&&(input_addr<=bias_end  )))||
        (((input_end >=bias_addr  )&&(input_end <=bias_end  )))) {
        PRINTF("ERROR input-bias overlapped: input=0x%08lX:%08lX bias=0x%08lX:%08lX.\n",
                input_addr, input_end, bias_addr, bias_end);
    }
    if ((((weight_addr>=bias_addr)&&(weight_addr<=bias_end)))||
        (((weight_end >=bias_addr)&&(weight_end <=bias_end)))) {
        PRINTF("ERROR weight-bias overlapped: weight=0x%08lX:%08lX bias=0x%08lX:%08lX.\n",
                weight_addr, weight_end, bias_addr, bias_end);
    }
    #endif

    uint32_t data;

    input_set   ( input_addr, input_size, input_leng );
    weight_set  ( weight_addr, weight_width, weight_height, weight_leng );
    bias_set    ( bias_addr, bias_size );
    result_set  ( result_addr, result_size, result_leng );
    activ_set   ( activ_func, activ_param );

    return 0;
}

//------------------------------------------------------------------------------
int linear_go_wait( const uint8_t ie // make interrupt enabled
                  , const uint8_t blocking) // make blocking to wait for complete
{
    uint32_t dataW, dataR;
    BFM_READ(CSRA_LINEAR1D_CONTROL, dataR);
    dataW = dataR
          | (1<<OFFSET_LINEAR1D_ctl_result_go)
          | (1<<OFFSET_LINEAR1D_ctl_bias_go  )
          | (1<<OFFSET_LINEAR1D_ctl_weight_go)
          | (1<<OFFSET_LINEAR1D_ctl_input_go );
    if (ie) dataW |= (1<<OFFSET_LINEAR1D_ctl_ie);
    BFM_WRITE(CSRA_LINEAR1D_CONTROL, dataW);
    if (blocking) {
        do { BFM_READ(CSRA_LINEAR1D_CONTROL, dataR);
        } while (dataR&((1<<OFFSET_LINEAR1D_ctl_result_go )
                       |(1<<OFFSET_LINEAR1D_ctl_bias_go   )
                       |(1<<OFFSET_LINEAR1D_ctl_weight_go )
                       |(1<<OFFSET_LINEAR1D_ctl_input_go  )));
    }
    #if defined(RIGOR)
    BFM_READ(CSRA_LINEAR1D_CONTROL, dataR);
    if (dataR&( (1<<OFFSET_LINEAR1D_ctl_result_done )
               |(1<<OFFSET_LINEAR1D_ctl_bias_done   )
               |(1<<OFFSET_LINEAR1D_ctl_weight_done )
               |(1<<OFFSET_LINEAR1D_ctl_input_done  )
               |(1<<OFFSET_LINEAR1D_ctl_result_go   )
               |(1<<OFFSET_LINEAR1D_ctl_bias_go     )
               |(1<<OFFSET_LINEAR1D_ctl_weight_go   )
               |(1<<OFFSET_LINEAR1D_ctl_input_go    ))) {
        PRINTF("go-done error.");
    }
    #endif
    return 0;
}


//------------------------------------------------------------------------------
static int input_set( const uint64_t input_addr
                    , const uint16_t input_size
                    , const uint16_t input_leng)
{
    uint8_t ileng;
    linear_get_config( NULL   // data_type
                     , NULL   // Q
                     , NULL   // N
                     ,&ileng  // input_fifo_dpeth
                     , NULL   // weight_fifo_dpeth
                     , NULL); // result_fifo_dpeth )
    #if defined(RIGOR)
    if (input_leng>ileng) PRINTF("input leng is bigger than FIFO depth.\n");
    #endif
    uint32_t data;
    data = input_addr&0xFFFFFFFF;
    BFM_WRITE(CSRA_LINEAR1D_INPUT_ADDR_LOW, data);
    data = (input_addr>>32)&0xFFFFFFFF;
    BFM_WRITE(CSRA_LINEAR1D_INPUT_ADDR_HIGH, data);
    data = input_size&0xFFFF;
    BFM_WRITE(CSRA_LINEAR1D_INPUT_CFG, data);
    data = (input_leng==0) ? 0 :
           (input_leng>ileng) ? ileng-1 : input_leng-1; // mind AxLENG format
    BFM_WRITE(CSRA_LINEAR1D_INPUT_BURST,data);
    return 0;
}

//------------------------------------------------------------------------------
static int weight_set( const uint64_t weight_addr
                     , const uint16_t weight_width
                     , const uint16_t weight_height
                     , const uint16_t weight_leng) // not AxLENG format
{
    uint8_t wleng;
    linear_get_config( NULL   // data_type
                     , NULL   // Q
                     , NULL   // N
                     , NULL   // input_fifo_dpeth
                     ,&wleng  // weight_fifo_dpeth
                     , NULL); // result_fifo_dpeth )
    #if defined(RIGOR)
    if (weight_leng>wleng) PRINTF("weight leng is bigger than FIFO depth.\n");
    #endif
    uint32_t data;
    data = weight_addr&0xFFFFFFFF;
    BFM_WRITE(CSRA_LINEAR1D_WEIGHT_ADDR_LOW,data);
    data = (weight_addr>>32)&0xFFFFFFFF;
    BFM_WRITE(CSRA_LINEAR1D_WEIGHT_ADDR_HIGH,data);
    data = (weight_height&0xFFFF)<<OFFSET_LINEAR1D_weight_height
         | (weight_width&0xFFFF);
    BFM_WRITE(CSRA_LINEAR1D_WEIGHT_CFG,data);
    data = weight_height*weight_width;
    BFM_WRITE(CSRA_LINEAR1D_WEIGHT_ITEMS,data);
    data = (weight_leng==0) ? 0 :
           (weight_leng>wleng) ? wleng-1 : weight_leng-1; // mind AxLENG format
    BFM_WRITE(CSRA_LINEAR1D_WEIGHT_BURST,data);
    return 0;
}

//------------------------------------------------------------------------------
static int bias_set( const uint64_t bias_addr
                   , const uint16_t bias_size )
{
    uint32_t data;
    data = bias_addr&0xFFFFFFFF;
    BFM_WRITE(CSRA_LINEAR1D_BIAS_ADDR_LOW,data);
    data = (bias_addr>>32)&0xFFFFFFFF;
    BFM_WRITE(CSRA_LINEAR1D_BIAS_ADDR_HIGH,data);
    data = bias_size&0xFFFF;
    BFM_WRITE(CSRA_LINEAR1D_BIAS_CFG,data);
    return 0;
}

//------------------------------------------------------------------------------
static int activ_set( const uint8_t  activ_func
                    , const uint32_t activ_param)
{
    uint32_t data;
    data = (activ_func&0xF);
    BFM_WRITE(CSRA_LINEAR1D_LINEAR_ACTIV_FUNC,data);
    data = activ_param;
    BFM_WRITE(CSRA_LINEAR1D_LINEAR_ACTIV_PARAM,data);
    return 0;
}

//------------------------------------------------------------------------------
static int result_set( const uint64_t result_addr
                     , const uint16_t result_size
                     , const uint16_t result_leng) // not AxLENG format
{
    uint8_t rleng;
    linear_get_config( NULL   // data_type
                     , NULL   // Q
                     , NULL   // N
                     , NULL   // input_fifo_dpeth
                     , NULL   // weight_fifo_dpeth
                     ,&rleng);// result_fifo_dpeth )
    #if defined(RIGOR)
    if (result_leng>rleng) PRINTF("result leng is bigger than FIFO depth: %d:%d\n", result_leng, rleng);
    #endif
    uint32_t data;
    data = result_addr&0xFFFFFFFF;
    BFM_WRITE(CSRA_LINEAR1D_RST_ADDR_LOW,data);
    data = (result_addr>>32)&0xFFFFFFFF;
    BFM_WRITE(CSRA_LINEAR1D_RST_ADDR_HIGH,data);
    data = result_size&0xFFFF;
    BFM_WRITE(CSRA_LINEAR1D_RST_CFG  ,data);
    data = (result_leng==0) ? 0 :
           (result_leng>rleng) ? rleng-1 : result_leng-1; // mind AxLENG format
    BFM_WRITE(CSRA_LINEAR1D_RST_BURST,data);
    return 0;
}

//------------------------------------------------------------------------------
// Drive a pulse of 'init' signal, which auto clean.
int linear_init( void )
{
    uint32_t dataR, dataW;
    BFM_READ(CSRA_LINEAR1D_CONTROL, dataR);
    dataW = dataR | (1<<OFFSET_LINEAR1D_ctl_init);

    BFM_WRITE(CSRA_LINEAR1D_CONTROL, dataW);

    #if defined(RIGOR)
    int num=10;
    dataR = dataW;
    do { BFM_READ(CSRA_LINEAR1D_CONTROL, dataR);
         num--;
    } while ( (num>0) && (!(dataR&(1<<30)) || (dataR&(1<<31))) );
    if (!(dataR&(1<<30))) PRINTF("linear_ready should be 1.");
    if   (dataR&(1<<31))  PRINTF("linear_init should be 0.");
    #endif
    return 0;
}

//------------------------------------------------------------------------------
int linear_clear_interrupt( void )
{
    uint32_t dataW, dataR;
    BFM_READ(CSRA_LINEAR1D_CONTROL, dataR);
    dataW = dataR & ~(1<<OFFSET_LINEAR1D_ctl_ip);
    BFM_WRITE(CSRA_LINEAR1D_CONTROL, dataW);
    return 0;
}

//------------------------------------------------------------------------------
int linear_get_interrupt( uint8_t * const ip
                        , uint8_t * const ie )
{
    uint32_t dataR;
    BFM_READ(CSRA_LINEAR1D_CONTROL, dataR);
    if (ip) *ip = (dataR&(1<<OFFSET_LINEAR1D_ctl_ip)) ? 1 : 0;
    if (ie) *ie = (dataR&(1<<OFFSET_LINEAR1D_ctl_ie)) ? 1 : 0;
    return 0;
}

//------------------------------------------------------------------------------
int linear_get_config( char    * const data_type
                     , uint8_t * const Q // num of bits of fractional part
                     , uint8_t * const N // num of bits of whole part
                     , uint8_t * const input_fifo_dpeth
                     , uint8_t * const weight_fifo_dpeth
                     , uint8_t * const result_fifo_dpeth )
{
    uint32_t dataR;
    BFM_READ(CSRA_LINEAR1D_CONFIG, dataR);
    if (data_type) {
        uint16_t dt = (dataR>>OFFSET_LINEAR1D_cfg_data_type)&0xFFFF;
        memcpy(data_type, (void*)&dt, 2);
    }
    if (N) *N =  dataR&0xFF;
    if (Q) *Q = (dataR>>OFFSET_LINEAR1D_cfg_data_Q)&0xFF;
    BFM_READ(CSRA_LINEAR1D_CONFIG_FIFO, dataR);
    if (input_fifo_dpeth  ) *input_fifo_dpeth  = (dataR&0x000000FF)>> 0;
    if (weight_fifo_dpeth ) *weight_fifo_dpeth = (dataR&0x0000FF00)>> 8;
    if (result_fifo_dpeth ) *result_fifo_dpeth = (dataR&0x00FF0000)>>16;
    return 0;
}

//------------------------------------------------------------------------------
// Get the version
uint32_t linear_version( void )
{
    uint32_t dataR;
    BFM_READ(CSRA_LINEAR1D_VERSION, dataR);
    return dataR;
}

//------------------------------------------------------------------------------
int linear_profile_init( void )
{
    uint32_t dataW=1<<31;
    BFM_WRITE(CSRA_LINEAR1D_PROFILE_CTL, dataW);
    return 0;
}

//------------------------------------------------------------------------------
int linear_profile_get( uint32_t * const profile_cycles
                      , uint32_t * const profile_mac_num
                      , uint32_t * const profile_mac_ovr
                      , uint32_t * const profile_bia_ovr
                      , uint32_t * const profile_act_ovr
                      , uint32_t * const profile_cnt_rd 
                      , uint32_t * const profile_cnt_wr )
{
    uint32_t data=1;
    BFM_WRITE(CSRA_LINEAR1D_PROFILE_CTL, data);
    do { BFM_READ(CSRA_LINEAR1D_PROFILE_CTL, data);
    } while ((data&0x3)!=0);
    if (profile_cycles ) { BFM_READ(CSRA_LINEAR1D_PROFILE_CYCLES ,data); *profile_cycles  = data; }
    if (profile_mac_num) { BFM_READ(CSRA_LINEAR1D_PROFILE_MAC_NUM,data); *profile_mac_num = data; }
    if (profile_mac_ovr) { BFM_READ(CSRA_LINEAR1D_PROFILE_MAC_OVR,data); *profile_mac_ovr = data; }
    if (profile_bia_ovr) { BFM_READ(CSRA_LINEAR1D_PROFILE_BIA_OVR,data); *profile_bia_ovr = data; }
    if (profile_act_ovr) { BFM_READ(CSRA_LINEAR1D_PROFILE_ACT_OVR,data); *profile_act_ovr = data; }
    if (profile_cnt_rd ) { BFM_READ(CSRA_LINEAR1D_PROFILE_CNT_RD ,data); *profile_cnt_rd  = data; }
    if (profile_cnt_wr ) { BFM_READ(CSRA_LINEAR1D_PROFILE_CNT_WR ,data); *profile_cnt_wr  = data; }
    return 0;
}

//------------------------------------------------------------------------------
int linear_csr_test( void )
{
    uint32_t data;
    #define RCT(A,S) BFM_READ((A),data); PRINTF("A:0x%08lX D:0x%08X %s\n", (A), data, #S)
    RCT(CSRA_LINEAR1D_VERSION           ,"VERSION           ");
    RCT(CSRA_LINEAR1D_CONTROL           ,"CONTROL           ");
    RCT(CSRA_LINEAR1D_CONFIG            ,"CONFIG            ");
    RCT(CSRA_LINEAR1D_CONFIG_FIFO       ,"CONFIG_FIFO       ");

    RCT(CSRA_LINEAR1D_INPUT_ADDR_LOW    ,"INPUT_ADDR_LOW    ");
    RCT(CSRA_LINEAR1D_INPUT_ADDR_HIGH   ,"INPUT_ADDR_HIGH   ");
    RCT(CSRA_LINEAR1D_INPUT_CFG         ,"INPUT_CFG         ");
    RCT(CSRA_LINEAR1D_INPUT_BURST       ,"INPUT_BURST       ");

    RCT(CSRA_LINEAR1D_WEIGHT_ADDR_LOW   ,"WEIGHT_ADDR_LOW   ");
    RCT(CSRA_LINEAR1D_WEIGHT_ADDR_HIGH  ,"WEIGHT_ADDR_HIGH  ");
    RCT(CSRA_LINEAR1D_WEIGHT_CFG        ,"WEIGHT_CFG        ");
    RCT(CSRA_LINEAR1D_WEIGHT_ITEMS      ,"WEIGHT_ITEMS      ");
    RCT(CSRA_LINEAR1D_WEIGHT_BURST      ,"WEIGHT_BURST      ");

    RCT(CSRA_LINEAR1D_BIAS_ADDR_LOW     ,"BIAS_ADDR_LOW     ");
    RCT(CSRA_LINEAR1D_BIAS_ADDR_HIGH    ,"BIAS_ADDR_HIGH    ");
    RCT(CSRA_LINEAR1D_BIAS_CFG          ,"BIAS_CFG          ");

    RCT(CSRA_LINEAR1D_RST_ADDR_LOW      ,"RST_ADDR_LOW      ");
    RCT(CSRA_LINEAR1D_RST_ADDR_HIGH     ,"RST_ADDR_HIGH     ");
    RCT(CSRA_LINEAR1D_RST_CFG           ,"RST_CFG           ");
    RCT(CSRA_LINEAR1D_RST_BURST         ,"RST_BURST         ");

    RCT(CSRA_LINEAR1D_LINEAR_ACTIV_FUNC ,"LINEAR_ACTIV_FUNC ");
    RCT(CSRA_LINEAR1D_LINEAR_ACTIV_PARAM,"LINEAR_ACTIV_PARAM");

    RCT(CSRA_LINEAR1D_PROFILE_CTL       ,"PROFILE_CTL       ");
    RCT(CSRA_LINEAR1D_PROFILE_CYCLES    ,"PROFILE_CYCLES    ");
    RCT(CSRA_LINEAR1D_PROFILE_MAC_NUM   ,"PROFILE_MAC_NUM   ");
    RCT(CSRA_LINEAR1D_PROFILE_MAC_OVR   ,"PROFILE_MAC_OVR   ");
    RCT(CSRA_LINEAR1D_PROFILE_BIA_OVR   ,"PROFILE_BIA_OVR   ");
    RCT(CSRA_LINEAR1D_PROFILE_ACT_OVR   ,"PROFILE_ACT_OVR   ");
    RCT(CSRA_LINEAR1D_PROFILE_CNT_RD    ,"PROFILE_CNT_RD    ");
    RCT(CSRA_LINEAR1D_PROFILE_CNT_WR    ,"PROFILE_CNT_WR    ");

    #undef RCT
    return 0;
}

//------------------------------------------------------------------------------
// It reads a block from SW buffer and then writes them to the HW.
int linear_write_block_to_hw( const uint64_t hw_dst // hw address
                            ,       uint8_t * const sw_src // sw address
                            , const uint32_t bnum ) // num of bytes
{
    if (((hw_dst&0x3L)!=0)||((((unsigned long long)sw_src)&0x3L)!=0)) {
        PRINTF("ERROR mis-aligned access\n");
    }
    uint32_t addr_dst=hw_dst&0xFFFFFFFF;
    uint8_t *addr_src=sw_src;
    uint32_t moved=0; // num of bytes has been moved
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
int linear_read_block_from_hw(       uint8_t * const sw_dst // sw address
                             , const uint64_t  hw_src // hw address
                             , const uint32_t  bnum ) // num of bytes
{
    if (((((unsigned long long)sw_dst)&0x3L)!=0)||((hw_src&0x3L)!=0)) {
        PRINTF("ERROR mis-aligned access\n");
    }
    uint8_t  *addr_dst=sw_dst; // will be used as a pointer
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
int linear_check_data_type( const char * const host_dt
                          , const int hN
                          , const int hQ )
{
   char data_type[3];
    uint8_t Q, N;
    linear_get_config(data_type, &Q, &N, NULL, NULL, NULL);
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

int linear_set_addr( unsigned long int offset)
{
    CSRA_LINEAR1D_BASE=offset;

    CSRA_LINEAR1D_VERSION           =(offset+0x00);
    CSRA_LINEAR1D_CONTROL           =(offset+0x10);
    CSRA_LINEAR1D_CONFIG            =(offset+0x14);
    CSRA_LINEAR1D_CONFIG_FIFO       =(offset+0x18);
    
    CSRA_LINEAR1D_INPUT_ADDR_LOW    =(offset+0x20);
    CSRA_LINEAR1D_INPUT_ADDR_HIGH   =(offset+0x24);
    CSRA_LINEAR1D_INPUT_CFG         =(offset+0x28);
    CSRA_LINEAR1D_INPUT_BURST       =(offset+0x30);
    
    CSRA_LINEAR1D_WEIGHT_ADDR_LOW   =(offset+0x40);
    CSRA_LINEAR1D_WEIGHT_ADDR_HIGH  =(offset+0x44);
    CSRA_LINEAR1D_WEIGHT_CFG        =(offset+0x48);
    CSRA_LINEAR1D_WEIGHT_ITEMS      =(offset+0x4C);
    CSRA_LINEAR1D_WEIGHT_BURST      =(offset+0x50);
    
    CSRA_LINEAR1D_BIAS_ADDR_LOW     =(offset+0x60);
    CSRA_LINEAR1D_BIAS_ADDR_HIGH    =(offset+0x64);
    CSRA_LINEAR1D_BIAS_CFG          =(offset+0x68);
    
    CSRA_LINEAR1D_RST_ADDR_LOW      =(offset+0x70);
    CSRA_LINEAR1D_RST_ADDR_HIGH     =(offset+0x74);
    CSRA_LINEAR1D_RST_CFG           =(offset+0x78);
    CSRA_LINEAR1D_RST_BURST         =(offset+0x80);
    
    CSRA_LINEAR1D_LINEAR_ACTIV_FUNC =(offset+0x90);
    CSRA_LINEAR1D_LINEAR_ACTIV_PARAM=(offset+0x94);
    
    CSRA_LINEAR1D_PROFILE_CTL       =(offset+0xA0);
    CSRA_LINEAR1D_PROFILE_CYCLES    =(offset+0xA4);
    CSRA_LINEAR1D_PROFILE_MAC_NUM   =(offset+0xA8);
    CSRA_LINEAR1D_PROFILE_MAC_OVR   =(offset+0xAC);
    CSRA_LINEAR1D_PROFILE_BIA_OVR   =(offset+0xB0);
    CSRA_LINEAR1D_PROFILE_ACT_OVR   =(offset+0xB4);
    CSRA_LINEAR1D_PROFILE_CNT_RD    =(offset+0xB8);
    CSRA_LINEAR1D_PROFILE_CNT_WR    =(offset+0xBC);

    return 0;
}

unsigned long int linear_get_addr( void )
{
    return CSRA_LINEAR1D_BASE;
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
// 2021.08.10: Started by Ando Ki (adki@future-ds.com)
//------------------------------------------------------------------------------
