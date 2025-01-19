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
#include "mover_2d_one_core.h"

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
#ifdef  DPU_ADDR_BASE_MOVER
//#pragma GCC warning DPU_ADDR_BASE_MOVER should be defined.
static unsigned long int  CSRA_MOVER2D_BASE=DPU_ADDR_BASE_MOVER;
#else
static unsigned long int  CSRA_MOVER2D_BASE=0xC0003000;
#endif

static unsigned long int CSRA_MOVER2D_VERSION       =(CSRA_MOVER2D_BASE+0x00);
static unsigned long int CSRA_MOVER2D_CONTROL       =(CSRA_MOVER2D_BASE+0x10);
static unsigned long int CSRA_MOVER2D_CONFIG        =(CSRA_MOVER2D_BASE+0x14);
static unsigned long int CSRA_MOVER2D_CONFIG_FIFO   =(CSRA_MOVER2D_BASE+0x18);

static unsigned long int CSRA_MOVER2D_COMMAND       =(CSRA_MOVER2D_BASE+0x20);

static unsigned long int CSRA_MOVER2D_SRCA_ADDR_LOW =(CSRA_MOVER2D_BASE+0x30);
static unsigned long int CSRA_MOVER2D_SRCA_ADDR_HIGH=(CSRA_MOVER2D_BASE+0x34);
static unsigned long int CSRA_MOVER2D_SRCA_CFG_SIZE =(CSRA_MOVER2D_BASE+0x38);
static unsigned long int CSRA_MOVER2D_SRCA_ITEMS    =(CSRA_MOVER2D_BASE+0x3C);
static unsigned long int CSRA_MOVER2D_SRCA_BURST    =(CSRA_MOVER2D_BASE+0x40);

static unsigned long int CSRA_MOVER2D_SRCB_ADDR_LOW =(CSRA_MOVER2D_BASE+0x50);
static unsigned long int CSRA_MOVER2D_SRCB_ADDR_HIGH=(CSRA_MOVER2D_BASE+0x54);
static unsigned long int CSRA_MOVER2D_SRCB_CFG_SIZE =(CSRA_MOVER2D_BASE+0x58);
static unsigned long int CSRA_MOVER2D_SRCB_ITEMS    =(CSRA_MOVER2D_BASE+0x5C);
static unsigned long int CSRA_MOVER2D_SRCB_BURST    =(CSRA_MOVER2D_BASE+0x60);

static unsigned long int CSRA_MOVER2D_RST_ADDR_LOW  =(CSRA_MOVER2D_BASE+0x70);
static unsigned long int CSRA_MOVER2D_RST_ADDR_HIGH =(CSRA_MOVER2D_BASE+0x74);
static unsigned long int CSRA_MOVER2D_RST_CFG_SIZE  =(CSRA_MOVER2D_BASE+0x78);
static unsigned long int CSRA_MOVER2D_RST_ITEMS     =(CSRA_MOVER2D_BASE+0x7C);
static unsigned long int CSRA_MOVER2D_RST_BURST     =(CSRA_MOVER2D_BASE+0x80);

static unsigned long int CSRA_MOVER2D_FILL_VALUE    =(CSRA_MOVER2D_BASE+0x90);
static unsigned long int CSRA_MOVER2D_ACTIV_FUNC    =(CSRA_MOVER2D_BASE+0x94);
static unsigned long int CSRA_MOVER2D_ACTIV_PARAM   =(CSRA_MOVER2D_BASE+0x98);

static unsigned long int CSRA_MOVER2D_PROFILE_CTL              =(CSRA_MOVER2D_BASE+0xA0);
static unsigned long int CSRA_MOVER2D_PROFILE_RESIDUAL_OVERFLOW=(CSRA_MOVER2D_BASE+0xA4);
static unsigned long int CSRA_MOVER2D_PROFILE_CYCLES           =(CSRA_MOVER2D_BASE+0xA8);
static unsigned long int CSRA_MOVER2D_PROFILE_CNT_RD           =(CSRA_MOVER2D_BASE+0xAC);
static unsigned long int CSRA_MOVER2D_PROFILE_CNT_WR           =(CSRA_MOVER2D_BASE+0xB0);

//------------------------------------------------------------------------------
#define OFFSET_MOVER2D_ctl_init         31
#define OFFSET_MOVER2D_ctl_ready        30
#define OFFSET_MOVER2D_ctl_ip           29
#define OFFSET_MOVER2D_ctl_ie           28
#define OFFSET_MOVER2D_ctl_result_done  10
#define OFFSET_MOVER2D_ctl_srcB_done    9
#define OFFSET_MOVER2D_ctl_srcA_done    8
#define OFFSET_MOVER2D_ctl_result_go    2
#define OFFSET_MOVER2D_ctl_srcB_go      1
#define OFFSET_MOVER2D_ctl_srcA_go      0

#define OFFSET_MOVER2D_cfg_data_type    16
#define OFFSET_MOVER2D_cfg_data_Q       8
#define OFFSET_MOVER2D_cfg_data_N       0

#define OFFSET_MOVER2D_command          0

#define OFFSET_MOVER2D_srcA_height      16
#define OFFSET_MOVER2D_srcA_width       0
#define OFFSET_MOVER2D_srcA_items       0
#define OFFSET_MOVER2D_srcA_leng        0

#define OFFSET_MOVER2D_srcB_height      16
#define OFFSET_MOVER2D_srcB_width       0
#define OFFSET_MOVER2D_srcB_items       0
#define OFFSET_MOVER2D_srcB_leng        0

#define OFFSET_MOVER2D_result_height    16
#define OFFSET_MOVER2D_result_width     0
#define OFFSET_MOVER2D_result_items     0
#define OFFSET_MOVER2D_result_leng      0

//------------------------------------------------------------------------------
#if defined(DEBUG)
#define PRINTF(format, ...) printf("%s(): " format, __func__, ##__VA_ARGS__)
#else
#define PRINTF(...) do { } while (0)
#endif

static int srcA_set( const uint64_t addr_mem
                   , const uint16_t width
                   , const uint16_t height
                   , const uint16_t leng);// burst length (not AxLENG format)
static int srcB_set( const uint64_t addr_mem
                   , const uint16_t width
                   , const uint16_t height
                   , const uint16_t leng);// burst length (not AxLENG format)
static int result_set( const uint64_t addr_mem
                     , const uint16_t width // width (num of items)
                     , const uint16_t height
                     , const uint16_t leng);// burst length (not AxLENG format)

//------------------------------------------------------------------------------
// It only sets up HW to deal with one DMA move.
// 'mover_go_wait()' should be called to carry out DMA.
//
int mover_fill_set( const uint64_t dst_addr
                  , const uint16_t width
                  , const uint16_t height
                  , const uint32_t value )
{
    uint8_t data_width; // bit-width of data item
    uint8_t fifo_depth;
    mover_get_config( NULL // char    * const data_type
                    , NULL // uint8_t * const Q // num of bits of fractional part
                    ,&data_width // uint8_t * const N // num of bits of whole part
                    , NULL // uint8_t * const src_fifo_dpeth
                    ,&fifo_depth); // uint8_t * const result_fifo_dpeth )
    if (fifo_depth==0)  fifo_depth = 1;
    result_set( dst_addr
              , width 
              , height
              , fifo_depth ); // burst length (not AxLENG format)
    BFM_WRITE(CSRA_MOVER2D_FILL_VALUE, value);
    uint32_t command = MOVER_COMMAND_FILL;
    BFM_WRITE(CSRA_MOVER2D_COMMAND, command);
    command = ACTIV_FUNC_BYPASS;
    BFM_WRITE(CSRA_MOVER2D_ACTIV_FUNC, command);
    return 0;
}

//------------------------------------------------------------------------------
// 'dst_addr' and 'src_addr' can be the same.
// Activation layer can be done using activ_func/param with the same 'dst/src_addr'.
int mover_copy_set( const uint64_t dst_addr
                  , const uint64_t src_addr
                  , const uint16_t width
                  , const uint16_t height
                  , const uint8_t  activ_func
                  , const uint32_t activ_param )
{
    uint8_t fifo_depth;
    mover_get_config( NULL // char    * const data_type
                    , NULL // uint8_t * const Q // num of bits of fractional part
                    , NULL // uint8_t * const N // num of bits of whole part
                    , NULL // uint8_t * const src_fifo_dpeth
                    ,&fifo_depth); // uint8_t * const result_fifo_dpeth )
    if (fifo_depth==0)  fifo_depth = 1;
    srcA_set( src_addr
            , width 
            , height
            , fifo_depth ); // burst length (not AxLENG format)
    result_set( dst_addr
              , width 
              , height
              , fifo_depth ); // burst length (not AxLENG format)
    uint32_t command = MOVER_COMMAND_COPY;
    BFM_WRITE(CSRA_MOVER2D_COMMAND, command);

    uint32_t dataW = activ_func;
    BFM_WRITE(CSRA_MOVER2D_ACTIV_FUNC , dataW );
    BFM_WRITE(CSRA_MOVER2D_ACTIV_PARAM, activ_param);

    return 0;
}

//------------------------------------------------------------------------------
int mover_residual_set( const uint64_t dst_addr
                      , const uint64_t srcA_addr
                      , const uint64_t srcB_addr
                      , const uint16_t width
                      , const uint16_t height
                      , const uint8_t  activ_func
                      , const uint32_t activ_param )
{
    uint8_t fifo_depth;
    mover_get_config( NULL // char    * const data_type
                    , NULL // uint8_t * const Q // num of bits of fractional part
                    , NULL // uint8_t * const N // num of bits of whole part
                    , NULL // uint8_t * const src_fifo_dpeth
                    ,&fifo_depth); // uint8_t * const result_fifo_dpeth )
    if (fifo_depth==0)  fifo_depth = 1;
    srcA_set( srcA_addr
            , width 
            , height
            , fifo_depth ); // burst length (not AxLENG format)
    srcB_set( srcB_addr
            , width 
            , height
            , fifo_depth ); // burst length (not AxLENG format)
    result_set( dst_addr
              , width 
              , height
              , fifo_depth ); // burst length (not AxLENG format)
    uint32_t command = MOVER_COMMAND_RESIDUAL;
    BFM_WRITE(CSRA_MOVER2D_COMMAND, command);

    uint32_t dataW = activ_func;
    BFM_WRITE(CSRA_MOVER2D_ACTIV_FUNC , dataW );
    BFM_WRITE(CSRA_MOVER2D_ACTIV_PARAM, activ_param);
    return 0;
}

//------------------------------------------------------------------------------
int mover_concat0_set( const uint64_t dst_addr
                     , const uint16_t dst_width
                     , const uint16_t dst_height
                     , const uint64_t srcA_addr
                     , const uint16_t srcA_width
                     , const uint16_t srcA_height
                     , const uint64_t srcB_addr
                     , const uint16_t srcB_width
                     , const uint16_t srcB_height)
{
   #if defined(RIGOR)
   if (srcA_width!=srcB_width) {
       PRINTF("width differs.\n");
       return -1;
   }
   if (srcA_width!=dst_width) {
       PRINTF("width differs.\n");
       return -1;
   }
   if (dst_height!=(srcA_height+srcB_height)) {
       PRINTF("height differs.\n");
       return -1;
   }
   #endif
    uint8_t fifo_depth;
    mover_get_config( NULL // char    * const data_type
                    , NULL // uint8_t * const Q // num of bits of fractional part
                    , NULL // uint8_t * const N // num of bits of whole part
                    , NULL // uint8_t * const src_fifo_dpeth
                    ,&fifo_depth); // uint8_t * const result_fifo_dpeth )
    if (fifo_depth==0)  fifo_depth = 1;
    srcA_set( srcA_addr
            , srcA_width 
            , srcA_height
            , fifo_depth ); // burst length (not AxLENG format)
    srcB_set( srcB_addr
            , srcB_width 
            , srcB_height
            , fifo_depth ); // burst length (not AxLENG format)
    result_set( dst_addr
              , dst_width 
              , dst_height
              , fifo_depth ); // burst length (not AxLENG format)
    uint32_t command = MOVER_COMMAND_CONCAT0;
    BFM_WRITE(CSRA_MOVER2D_COMMAND, command);
    command = ACTIV_FUNC_BYPASS;
    BFM_WRITE(CSRA_MOVER2D_ACTIV_FUNC, command);
    return 0;
}

//------------------------------------------------------------------------------
int mover_concat1_set( const uint64_t dst_addr
                     , const uint16_t dst_width
                     , const uint16_t dst_height
                     , const uint64_t srcA_addr
                     , const uint16_t srcA_width
                     , const uint16_t srcA_height
                     , const uint64_t srcB_addr
                     , const uint16_t srcB_width
                     , const uint16_t srcB_height)
{
   #if defined(RIGOR)
   if (srcA_height!=srcB_height) {
       PRINTF("height differs.\n");
       return -1;
   }
   if (srcA_height!=dst_height) {
       PRINTF("height differs.\n");
       return -1;
   }
   if (dst_width!=(srcA_width+srcB_width)) {
       PRINTF("width differs.\n");
       return -1;
   }
   #endif
    uint8_t fifo_depth;
    mover_get_config( NULL // char    * const data_type
                    , NULL // uint8_t * const Q // num of bits of fractional part
                    , NULL // uint8_t * const N // num of bits of whole part
                    , NULL // uint8_t * const src_fifo_dpeth
                    ,&fifo_depth); // uint8_t * const result_fifo_dpeth )
    if (fifo_depth==0)  fifo_depth = 1;
    srcA_set( srcA_addr
            , srcA_width 
            , srcA_height
            , fifo_depth ); // burst length (not AxLENG format)
    srcB_set( srcB_addr
            , srcB_width 
            , srcB_height
            , fifo_depth ); // burst length (not AxLENG format)
    result_set( dst_addr
              , dst_width 
              , dst_height
              , fifo_depth ); // burst length (not AxLENG format)
    uint32_t command = MOVER_COMMAND_CONCAT1;
    BFM_WRITE(CSRA_MOVER2D_COMMAND, command);
    command = ACTIV_FUNC_BYPASS;
    BFM_WRITE(CSRA_MOVER2D_ACTIV_FUNC, command);
    return 0;
}

//------------------------------------------------------------------------------
int mover_go_wait( const uint8_t ie // make interrupt enabled
                 , const uint8_t blocking) // make blocking to wait for complete
{
    uint32_t dataW, dataR;
    BFM_READ(CSRA_MOVER2D_CONTROL, dataR);
    dataW = dataR
          | (1<<OFFSET_MOVER2D_ctl_result_go )
          | (1<<OFFSET_MOVER2D_ctl_srcB_go)
          | (1<<OFFSET_MOVER2D_ctl_srcA_go);
    if (ie) dataW |= (1<<OFFSET_MOVER2D_ctl_ie);
    BFM_WRITE(CSRA_MOVER2D_CONTROL, dataW);
    BFM_READ(CSRA_MOVER2D_CONTROL, dataR);
    if (blocking) {
        do { BFM_READ(CSRA_MOVER2D_CONTROL, dataR);
        } while (dataR&((1<<OFFSET_MOVER2D_ctl_result_go)
                       |(1<<OFFSET_MOVER2D_ctl_srcB_go  )
                       |(1<<OFFSET_MOVER2D_ctl_srcA_go  )));
    }
    #if defined(RIGOR)
    BFM_READ(CSRA_MOVER2D_CONTROL, dataR);
    if (dataR&( (1<<OFFSET_MOVER2D_ctl_result_done )
               |(1<<OFFSET_MOVER2D_ctl_srcB_done   )
               |(1<<OFFSET_MOVER2D_ctl_srcA_done   )
               |(1<<OFFSET_MOVER2D_ctl_result_go   )
               |(1<<OFFSET_MOVER2D_ctl_srcB_go     )
               |(1<<OFFSET_MOVER2D_ctl_srcA_go     ))) {
        PRINTF("go-done error.");
    }
    #endif
    return 0;
}

//------------------------------------------------------------------------------
static int srcA_set( const uint64_t addr_mem
                   , const uint16_t width 
                   , const uint16_t height
                   , const uint16_t leng) // burst length (not AxLENG format)
{
    uint32_t data;
    data = addr_mem&0xFFFFFFFF;
    BFM_WRITE(CSRA_MOVER2D_SRCA_ADDR_LOW, data);
    data = (addr_mem>>32)&0xFFFFFFFF;
    BFM_WRITE(CSRA_MOVER2D_SRCA_ADDR_HIGH, data);
    data = (height&0xF)<<OFFSET_MOVER2D_srcA_height
         | (width &0xF)<<OFFSET_MOVER2D_srcA_width;
    BFM_WRITE(CSRA_MOVER2D_SRCA_CFG_SIZE, data);
    data = width*height;
    BFM_WRITE(CSRA_MOVER2D_SRCA_ITEMS, data);
    data = (leng<=0) ? 0 : (leng-1)&0xFF; // make AxLENG format
    BFM_WRITE(CSRA_MOVER2D_SRCA_BURST, data); // mind AxLENG format
    return 0;
}

//------------------------------------------------------------------------------
static int srcB_set( const uint64_t addr_mem
                   , const uint16_t width 
                   , const uint16_t height
                   , const uint16_t leng) // burst length (not AxLENG format)
{
    uint32_t data;
    data = addr_mem&0xFFFFFFFF;
    BFM_WRITE(CSRA_MOVER2D_SRCB_ADDR_LOW, data);
    data = (addr_mem>>32)&0xFFFFFFFF;
    BFM_WRITE(CSRA_MOVER2D_SRCB_ADDR_HIGH, data);
    data = (height&0xF)<<OFFSET_MOVER2D_srcB_height
         | (width &0xF)<<OFFSET_MOVER2D_srcB_width;
    BFM_WRITE(CSRA_MOVER2D_SRCB_CFG_SIZE, data);
    data = width*height;
    BFM_WRITE(CSRA_MOVER2D_SRCB_ITEMS, data);
    data = (leng<=0) ? 0 : (leng-1)&0xFF; // make AxLENG format
    BFM_WRITE(CSRA_MOVER2D_SRCB_BURST, data); // mind AxLENG format
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
    BFM_WRITE(CSRA_MOVER2D_RST_ADDR_LOW, data);
    data = (addr_mem>>32)&0xFFFFFFFF;
    BFM_WRITE(CSRA_MOVER2D_RST_ADDR_HIGH, data);
    data = (height&0xFFFF)<< OFFSET_MOVER2D_result_height
         | (width&0xFFFF)<<OFFSET_MOVER2D_result_width;
    BFM_WRITE(CSRA_MOVER2D_RST_CFG_SIZE, data);
    data = height*width;
    BFM_WRITE(CSRA_MOVER2D_RST_ITEMS, data);
    data = (leng<=0) ? 0 : (leng-1)&0xFF; // make AxLENG format
    BFM_WRITE(CSRA_MOVER2D_RST_BURST, data); // mind AxLENG format
    return 0;
}

//------------------------------------------------------------------------------
// Drive a pulse of 'init' signal, which auto clean.
int mover_init( void )
{
    uint32_t dataR, dataW;
    BFM_READ(CSRA_MOVER2D_CONTROL, dataR);
    dataW = dataR | (1<<OFFSET_MOVER2D_ctl_init);

    BFM_WRITE(CSRA_MOVER2D_CONTROL, dataR);
    #if defined(RIGOR)
    BFM_READ(CSRA_MOVER2D_CONTROL, dataR);
    if (!(dataR&(1<<30))) PRINTF("mover_ready should be 1.");
    if   (dataR&(1<<31))  PRINTF("mover_init should be 0.");
    #endif
    return 0;
}

//------------------------------------------------------------------------------
int mover_clear_interrupt( void )
{
    uint32_t dataW, dataR;
    BFM_READ(CSRA_MOVER2D_CONTROL, dataR);
    dataW = dataR & ~(1<<OFFSET_MOVER2D_ctl_ip);
    BFM_WRITE(CSRA_MOVER2D_CONTROL, dataW);
    return 0;
}

//------------------------------------------------------------------------------
int mover_get_interrupt( uint8_t * const ip
                       , uint8_t * const ie )
{
    uint32_t dataR;
    BFM_READ(CSRA_MOVER2D_CONTROL, dataR);
    if (ip) *ip = (dataR&(1<<OFFSET_MOVER2D_ctl_ip)) ? 1 : 0;
    if (ie) *ie = (dataR&(1<<OFFSET_MOVER2D_ctl_ie)) ? 1 : 0;
    return 0;
}

//------------------------------------------------------------------------------
int mover_get_config( char    * const data_type
                    , uint8_t * const Q // num of bits of fractional part
                    , uint8_t * const N // num of bits of whole part
                    , uint8_t * const src_fifo_dpeth
                    , uint8_t * const result_fifo_dpeth )
{
    uint32_t dataR;
    BFM_READ(CSRA_MOVER2D_CONFIG, dataR);
    if (data_type) {
        uint16_t dt = (dataR>>OFFSET_MOVER2D_cfg_data_type)&0xFFFF;
        memcpy(data_type, (void*)&dt, 2);
    }
    if (N) *N =  dataR&0xFF;
    if (Q) *Q = (dataR>>OFFSET_MOVER2D_cfg_data_Q)&0xFF;
    BFM_READ(CSRA_MOVER2D_CONFIG_FIFO, dataR);
    if (src_fifo_dpeth) *src_fifo_dpeth = (dataR&0x000000FF);
    if (result_fifo_dpeth ) *result_fifo_dpeth  = (dataR&0x0000FF00)>>8;
    return 0;
}

//------------------------------------------------------------------------------
// Get the version
uint32_t mover_version( void )
{
    uint32_t dataR;
    BFM_READ(CSRA_MOVER2D_VERSION, dataR);
    return dataR;
}

//------------------------------------------------------------------------------
int mover_profile_init( void )
{
    uint32_t dataW = 1<<31;
    BFM_WRITE(CSRA_MOVER2D_PROFILE_CTL, dataW);
    return 0;
}

//------------------------------------------------------------------------------
int mover_profile_get( uint32_t * const profile_cycles
                     , uint32_t * const profile_residual_overflow
                     , uint32_t * const profile_cnt_rd
                     , uint32_t * const profile_cnt_wr)
{
    uint32_t data=1;
    BFM_WRITE(CSRA_MOVER2D_PROFILE_CTL, data);
    do { BFM_READ(CSRA_MOVER2D_PROFILE_CTL, data);
    } while ((data&0x3)!=0);
    if (profile_cycles) { BFM_READ(CSRA_MOVER2D_PROFILE_CYCLES, data); *profile_cycles = data; }
    if (profile_residual_overflow) { BFM_READ(CSRA_MOVER2D_PROFILE_RESIDUAL_OVERFLOW, data); *profile_residual_overflow = data; }
    if (profile_cnt_rd) { BFM_READ(CSRA_MOVER2D_PROFILE_CNT_RD, data); *profile_cnt_rd = data; }
    if (profile_cnt_wr) { BFM_READ(CSRA_MOVER2D_PROFILE_CNT_WR, data); *profile_cnt_wr = data; }
    return 0;
}

//------------------------------------------------------------------------------
int mover_csr_test( void )
{
    uint32_t data;
    #define PRINTFX(format, ...) printf("%s(): " format, __func__, ##__VA_ARGS__)
    #define RCT(A,S) BFM_READ((A),data); PRINTFX("A:0x%08lX D:0x%08X %s\n", (A), data, #S)
    RCT(CSRA_MOVER2D_VERSION       ,"VERSION       ");
    RCT(CSRA_MOVER2D_CONTROL       ,"CONTROL       ");
    RCT(CSRA_MOVER2D_CONFIG        ,"CONFIG        ");
    RCT(CSRA_MOVER2D_CONFIG_FIFO   ,"CONFIG_FIFO   ");
    RCT(CSRA_MOVER2D_COMMAND       ,"COMMAND       ");
    RCT(CSRA_MOVER2D_SRCA_ADDR_LOW ,"SRCA_ADDR_LOW ");
    RCT(CSRA_MOVER2D_SRCA_ADDR_HIGH,"SRCA_ADDR_HIGH");
    RCT(CSRA_MOVER2D_SRCA_CFG_SIZE ,"SRCA_CFG_SIZE ");
    RCT(CSRA_MOVER2D_SRCA_ITEMS    ,"SRCA_ITEMS    ");
    RCT(CSRA_MOVER2D_SRCA_BURST    ,"SRCA_BURST    ");
    RCT(CSRA_MOVER2D_SRCB_ADDR_LOW ,"SRCB_ADDR_LOW ");
    RCT(CSRA_MOVER2D_SRCB_ADDR_HIGH,"SRCB_ADDR_HIGH");
    RCT(CSRA_MOVER2D_SRCB_CFG_SIZE ,"SRCB_CFG_SIZE ");
    RCT(CSRA_MOVER2D_SRCB_ITEMS    ,"SRCB_ITEMS    ");
    RCT(CSRA_MOVER2D_SRCB_BURST    ,"SRCB_BURST    ");
    RCT(CSRA_MOVER2D_RST_ADDR_LOW  ,"RST_ADDR_LOW  ");
    RCT(CSRA_MOVER2D_RST_ADDR_HIGH ,"RST_ADDR_HIGH ");
    RCT(CSRA_MOVER2D_RST_CFG_SIZE  ,"RST_CFG_SIZE  ");
    RCT(CSRA_MOVER2D_RST_ITEMS     ,"RST_ITEMS     ");
    RCT(CSRA_MOVER2D_RST_BURST     ,"RST_BURST     ");
    RCT(CSRA_MOVER2D_FILL_VALUE    ,"FILL_VALUE    ");
    RCT(CSRA_MOVER2D_PROFILE_CTL   ,"PROFILE_CTL   ");
    RCT(CSRA_MOVER2D_PROFILE_CYCLES,"PROFILE_CYCLES");
    RCT(CSRA_MOVER2D_PROFILE_CNT_RD,"PROFILE_CNT_RD");
    RCT(CSRA_MOVER2D_PROFILE_CNT_WR,"PROFILE_CNT_WR");
    #undef RCT
    return 0;
}

//------------------------------------------------------------------------------
// It reads a block from SW buffer and then writes them to the HW.
int mover_write_block_to_hw( const uint64_t hw_dst // hw address
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
        addr_src += 256*4; // note it is char pointer
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
int mover_read_block_from_hw(       uint8_t * const sw_dst // sw address
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
        addr_dst += 256*4; // note it is char pointer
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
int mover_check_data_type( const char * const host_dt
                         , const int hN
                         , const int hQ )
{
   char data_type[3];
    uint8_t Q, N;
    mover_get_config(data_type, &Q, &N, NULL, NULL);
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

int mover_set_addr( unsigned long int base )
{
    CSRA_MOVER2D_BASE = base;

    CSRA_MOVER2D_VERSION       =(base+0x00);
    CSRA_MOVER2D_CONTROL       =(base+0x10);
    CSRA_MOVER2D_CONFIG        =(base+0x14);
    CSRA_MOVER2D_CONFIG_FIFO   =(base+0x18);
    
    CSRA_MOVER2D_COMMAND       =(base+0x20);
    
    CSRA_MOVER2D_SRCA_ADDR_LOW =(base+0x30);
    CSRA_MOVER2D_SRCA_ADDR_HIGH=(base+0x34);
    CSRA_MOVER2D_SRCA_CFG_SIZE =(base+0x38);
    CSRA_MOVER2D_SRCA_ITEMS    =(base+0x3C);
    CSRA_MOVER2D_SRCA_BURST    =(base+0x40);
    
    CSRA_MOVER2D_SRCB_ADDR_LOW =(base+0x50);
    CSRA_MOVER2D_SRCB_ADDR_HIGH=(base+0x54);
    CSRA_MOVER2D_SRCB_CFG_SIZE =(base+0x58);
    CSRA_MOVER2D_SRCB_ITEMS    =(base+0x5C);
    CSRA_MOVER2D_SRCB_BURST    =(base+0x60);
    
    CSRA_MOVER2D_RST_ADDR_LOW  =(base+0x70);
    CSRA_MOVER2D_RST_ADDR_HIGH =(base+0x74);
    CSRA_MOVER2D_RST_CFG_SIZE  =(base+0x78);
    CSRA_MOVER2D_RST_ITEMS     =(base+0x7C);
    CSRA_MOVER2D_RST_BURST     =(base+0x80);
    
    CSRA_MOVER2D_FILL_VALUE    =(base+0x90);
    CSRA_MOVER2D_ACTIV_FUNC    =(base+0x94);
    CSRA_MOVER2D_ACTIV_PARAM   =(base+0x98);
    
    CSRA_MOVER2D_PROFILE_CTL              =(base+0xA0);
    CSRA_MOVER2D_PROFILE_RESIDUAL_OVERFLOW=(base+0xA4);
    CSRA_MOVER2D_PROFILE_CYCLES           =(base+0xA8);
    CSRA_MOVER2D_PROFILE_CNT_RD           =(base+0xAC);
    CSRA_MOVER2D_PROFILE_CNT_WR           =(base+0xB0);

    return 0;
}

unsigned long int mover_get_addr ( void )
{
    return CSRA_MOVER2D_BASE;
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
