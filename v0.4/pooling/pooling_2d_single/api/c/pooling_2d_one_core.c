//------------------------------------------------------------------------------
// Copyright (c) 2021-2024 by Future Design Systems, Ltd.
// All right reserved.
//
// http://www.future-ds.com
//------------------------------------------------------------------------------
// VERSION = 2024.12.25.
//------------------------------------------------------------------------------
#include <stdio.h>
#include <string.h>

#include "defines_dpu.h"
#include "pooling_2d_one_core.h"

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
#ifdef  DPU_ADDR_BASE_POOL
//#pragma GCC warning DPU_ADDR_BASE_POOL should be defined.
static unsigned long int  CSRA_POOL2D_BASE=DPU_ADDR_BASE_POOL;
#else
static unsigned long int  CSRA_POOL2D_BASE=0xC0001000;
#endif

static unsigned long int CSRA_POOL2D_VERSION       =(CSRA_POOL2D_BASE+0x00);
static unsigned long int CSRA_POOL2D_CONTROL       =(CSRA_POOL2D_BASE+0x10);
static unsigned long int CSRA_POOL2D_CONFIG        =(CSRA_POOL2D_BASE+0x14);
static unsigned long int CSRA_POOL2D_CONFIG_FIFO   =(CSRA_POOL2D_BASE+0x18);

static unsigned long int CSRA_POOL2D_COMMAND       =(CSRA_POOL2D_BASE+0x20);
static unsigned long int CSRA_POOL2D_KNL_CFG       =(CSRA_POOL2D_BASE+0x24);

static unsigned long int CSRA_POOL2D_FTU_ADDR_LOW  =(CSRA_POOL2D_BASE+0x30);
static unsigned long int CSRA_POOL2D_FTU_ADDR_HIGH =(CSRA_POOL2D_BASE+0x34);
static unsigned long int CSRA_POOL2D_FTU_CFG_SIZE  =(CSRA_POOL2D_BASE+0x38);
static unsigned long int CSRA_POOL2D_FTU_CFG_KNL   =(CSRA_POOL2D_BASE+0x3C);
static unsigned long int CSRA_POOL2D_FTU_ITEMS     =(CSRA_POOL2D_BASE+0x40);
static unsigned long int CSRA_POOL2D_FTU_BURST     =(CSRA_POOL2D_BASE+0x44);
static unsigned long int CSRA_POOL2D_FTU_CHANNEL   =(CSRA_POOL2D_BASE+0x48);

static unsigned long int CSRA_POOL2D_RST_ADDR_LOW  =(CSRA_POOL2D_BASE+0x50);
static unsigned long int CSRA_POOL2D_RST_ADDR_HIGH =(CSRA_POOL2D_BASE+0x54);
static unsigned long int CSRA_POOL2D_RST_CFG_SIZE  =(CSRA_POOL2D_BASE+0x58);
static unsigned long int CSRA_POOL2D_RST_ITEMS     =(CSRA_POOL2D_BASE+0x5C);
static unsigned long int CSRA_POOL2D_RST_BURST     =(CSRA_POOL2D_BASE+0x60);

static unsigned long int CSRA_POOL2D_PROFILE_CTL   =(CSRA_POOL2D_BASE+0x70);
static unsigned long int CSRA_POOL2D_PROFILE_CYCLES=(CSRA_POOL2D_BASE+0x74);
static unsigned long int CSRA_POOL2D_PROFILE_CNT_RD=(CSRA_POOL2D_BASE+0x78);
static unsigned long int CSRA_POOL2D_PROFILE_CNT_WR=(CSRA_POOL2D_BASE+0x7C);

//------------------------------------------------------------------------------
#define OFFSET_POOL2D_ctl_init         31
#define OFFSET_POOL2D_ctl_ready        30
#define OFFSET_POOL2D_ctl_ip           29
#define OFFSET_POOL2D_ctl_ie           28
#define OFFSET_POOL2D_ctl_result_done  9
#define OFFSET_POOL2D_ctl_feature_done 8
#define OFFSET_POOL2D_ctl_result_go    1
#define OFFSET_POOL2D_ctl_feature_go   0

#define OFFSET_POOL2D_cfg_data_type    16
#define OFFSET_POOL2D_cfg_data_Q       8
#define OFFSET_POOL2D_cfg_data_N       0

#define OFFSET_POOL2D_kernel_height    4  //7:4
#define OFFSET_POOL2D_kernel_width     0  //3:0

#define OFFSET_POOL2D_feature_height   16 // bit-31:16
#define OFFSET_POOL2D_feature_width    0  // bit-15:0

#define OFFSET_POOL2D_feature_padding_post 12 // bit-15:12
#define OFFSET_POOL2D_feature_padding_pre  8  // bit-11:8
#define OFFSET_POOL2D_feature_stride       0  // bit-3:0

#define OFFSET_POOL2D_result_height   16 // bit-31:16
#define OFFSET_POOL2D_result_width    0  // bit-15:0

//------------------------------------------------------------------------------
#if defined(DEBUG)||defined(RIGOR)
#define PRINTF(format, ...) printf("%s(): " format, __func__, ##__VA_ARGS__)
#else
#define PRINTF(...) do { } while (0)
#endif

static int func_result_size( const uint8_t  kernel_size
                           , const uint16_t feature_size
                           , const uint8_t  stride
                           , const uint8_t  padding_pre
                           , const uint8_t  padding_post);
static int kernel_set( const uint8_t width // 4-bit width (num of items)
                     , const uint8_t height); // 4-bit
static int feature_set( const uint64_t addr_mem // space for filter(feature)
                      , const uint16_t width // width (num of items)
                      , const uint16_t height // width (num of items)
                      , const uint8_t  stride // width (num of items)
                      , const uint8_t  padding_pre // width (num of items)
                      , const uint8_t  padding_post // width (num of items)
                      , const uint16_t leng // burst length (not AxLENG format)
                      , const uint16_t channel);// num of channels (input and output)
static int result_set( const uint64_t addr_mem // space for filter(feature)
                     , const uint16_t width // width (num of items)
                     , const uint16_t height
                     , const uint16_t leng);// burst length (not AxLENG format)

//------------------------------------------------------------------------------
// It only sets up HW to deal with one pooling,
// 'pool_go_wait()' should be called to carry out pooling.
//
// Note:
// * result_width/height is calculated by using kernel_width/height, feature_width/height
//                                      stride, padding.
int pool_set( const uint8_t  command
            , const uint64_t result_addr
            , const uint16_t result_leng // not AxLENG format
            , const uint64_t feature_addr
            , const uint16_t feature_width
            , const uint16_t feature_height
            , const uint8_t  feature_stride
            , const uint8_t  feature_padding_pre
            , const uint8_t  feature_padding_post
            , const uint16_t feature_leng // not AxLENG format
            , const uint16_t feature_channel
            , const uint8_t  kernel_width
            , const uint8_t  kernel_height )
{
    #if defined(DEBUG)
    PRINTF("command             : %d\n",     command             );
    PRINTF("result_addr         : 0x%lX\n",  result_addr         );
    PRINTF("result_leng         : %u\n",     result_leng         );
    PRINTF("feature_addr        : 0x%lX\n",  feature_addr        );
    PRINTF("feature_width       : %u\n",     feature_width       );
    PRINTF("feature_height      : %u\n",     feature_height      );
    PRINTF("feature_stride      : %u\n",     feature_stride      );
    PRINTF("feature_padding_pre : %u\n",     feature_padding_pre );
    PRINTF("feature_padding_post: %u\n",     feature_padding_post);
    PRINTF("feature_leng        : %u\n",     feature_leng        );
    PRINTF("feature_channel     : %u\n",     feature_channel     );
    PRINTF("kernel_width        : %u\n",     kernel_width        );
    PRINTF("kernel_height       : %u\n",     kernel_height       ); fflush(stdout);
    #endif

    uint16_t result_width;
    uint16_t result_height;

    result_width = func_result_size( kernel_width, feature_width, feature_stride
                                   , feature_padding_pre, feature_padding_post);
    result_height = func_result_size( kernel_height, feature_height, feature_stride
                                    , feature_padding_pre, feature_padding_post);

    kernel_set( kernel_width
              , kernel_height);

    feature_set( feature_addr
               , feature_width
               , feature_height
               , feature_stride
               , feature_padding_pre
               , feature_padding_post
               , feature_leng
               , feature_channel);

    result_set(result_addr, result_width, result_height, result_leng);

    uint32_t dataW = command;
    BFM_WRITE(CSRA_POOL2D_COMMAND, dataW);

    return 0;
}

//------------------------------------------------------------------------------
int pool_go_wait( const uint8_t ie // make interrupt enabled
                , const uint8_t blocking) // make blocking to wait for complete
{
    uint32_t dataW, dataR;
    BFM_READ(CSRA_POOL2D_CONTROL, dataR);
    dataW = dataR
          | (1<<OFFSET_POOL2D_ctl_result_go )
          | (1<<OFFSET_POOL2D_ctl_feature_go);
    if (ie) dataW |= (1<<OFFSET_POOL2D_ctl_ie);
    BFM_WRITE(CSRA_POOL2D_CONTROL, dataW);
    BFM_READ(CSRA_POOL2D_CONTROL, dataR);
    if (blocking) {
        do { BFM_READ(CSRA_POOL2D_CONTROL, dataR);
        } while (dataR&((1<<OFFSET_POOL2D_ctl_result_go )
                       |(1<<OFFSET_POOL2D_ctl_feature_go)));
    }
    #if defined(RIGOR)
    BFM_READ(CSRA_POOL2D_CONTROL, dataR);
    if (dataR&( (1<<OFFSET_POOL2D_ctl_result_done )
               |(1<<OFFSET_POOL2D_ctl_feature_done)
               |(1<<OFFSET_POOL2D_ctl_result_go   )
               |(1<<OFFSET_POOL2D_ctl_feature_go  ))) {
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
static int kernel_set( const uint8_t width // 4-bit width (num of items)
                     , const uint8_t height) // 4-bit
{
    uint32_t data;
    data = (height&0xF)<<OFFSET_POOL2D_kernel_height
         | (width &0xF)<<OFFSET_POOL2D_kernel_width;
    BFM_WRITE(CSRA_POOL2D_KNL_CFG, data);
    return 0;
}

//------------------------------------------------------------------------------
static int feature_set( const uint64_t addr_mem // space for filter(feature)
                      , const uint16_t width // width (num of items)
                      , const uint16_t height // width (num of items)
                      , const uint8_t  stride // width (num of items)
                      , const uint8_t  padding_pre // width (num of items)
                      , const uint8_t  padding_post // width (num of items)
                      , const uint16_t leng // burst length (not AxLENG format)
                      , const uint16_t channel) // num of channels
{
    uint32_t data;
    data = addr_mem&0xFFFFFFFF;
    BFM_WRITE(CSRA_POOL2D_FTU_ADDR_LOW, data);
    data = (addr_mem>>32)&0xFFFFFFFF;
    BFM_WRITE(CSRA_POOL2D_FTU_ADDR_HIGH, data);
    data = (height&0xFFFF)<<OFFSET_POOL2D_feature_height
         | (width&0xFFFF)<<OFFSET_POOL2D_feature_width;
    BFM_WRITE(CSRA_POOL2D_FTU_CFG_SIZE, data);
    data = (padding_post&0xF)<<OFFSET_POOL2D_feature_padding_post
         | (padding_pre&0xF)<<OFFSET_POOL2D_feature_padding_pre
         | (stride&0xF)<<OFFSET_POOL2D_feature_stride;
    BFM_WRITE(CSRA_POOL2D_FTU_CFG_KNL, data);
    data = width*height;
    BFM_WRITE(CSRA_POOL2D_FTU_ITEMS, data);
    data = (leng<=0) ? 0 : (leng-1)&0xFF; // make AxLENG format
    BFM_WRITE(CSRA_POOL2D_FTU_BURST, data); // mind AxLENG format
    data = channel;
    BFM_WRITE(CSRA_POOL2D_FTU_CHANNEL, data); // mind AxLENG format
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
    BFM_WRITE(CSRA_POOL2D_RST_ADDR_LOW, data);
    data = (addr_mem>>32)&0xFFFFFFFF;
    BFM_WRITE(CSRA_POOL2D_RST_ADDR_HIGH, data);
    data = (height&0xFFFF)<< OFFSET_POOL2D_result_height
         | (width&0xFFFF)<<OFFSET_POOL2D_result_width;
    BFM_WRITE(CSRA_POOL2D_RST_CFG_SIZE, data);
    data = height*width;
    BFM_WRITE(CSRA_POOL2D_RST_ITEMS, data);
    data = (leng<=0) ? 0 : (leng-1)&0xFF; // make AxLENG format
    BFM_WRITE(CSRA_POOL2D_RST_BURST, data); // mind AxLENG format
    return 0;
}

//------------------------------------------------------------------------------
// Drive a pulse of 'init' signal, which auto clean.
int pool_init( void )
{
    uint32_t dataR, dataW;
    BFM_READ(CSRA_POOL2D_CONTROL, dataR);
    dataW = dataR | (1<<OFFSET_POOL2D_ctl_init);

    BFM_WRITE(CSRA_POOL2D_CONTROL, dataR);
    #if defined(RIGOR)
    BFM_READ(CSRA_POOL2D_CONTROL, dataR);
    if (!(dataR&(1<<30))) PRINTF("pool_ready should be 1.");
    if   (dataR&(1<<31))  PRINTF("pool_init should be 0.");
    #endif
    return 0;
}

//------------------------------------------------------------------------------
int pool_clear_interrupt( void )
{
    uint32_t dataW, dataR;
    BFM_READ(CSRA_POOL2D_CONTROL, dataR);
    dataW = dataR & ~(1<<OFFSET_POOL2D_ctl_ip);
    BFM_WRITE(CSRA_POOL2D_CONTROL, dataW);
    return 0;
}

//------------------------------------------------------------------------------
int pool_get_interrupt( uint8_t * const ip
                      , uint8_t * const ie )
{
    uint32_t dataR;
    BFM_READ(CSRA_POOL2D_CONTROL, dataR);
    if (ip) *ip = (dataR&(1<<OFFSET_POOL2D_ctl_ip)) ? 1 : 0;
    if (ie) *ie = (dataR&(1<<OFFSET_POOL2D_ctl_ie)) ? 1 : 0;
    return 0;
}

//------------------------------------------------------------------------------
int pool_get_config( char    * const data_type
                   , uint8_t * const Q // num of bits of fractional part
                   , uint8_t * const N // num of bits of whole part
                   , uint8_t * const feature_fifo_dpeth
                   , uint8_t * const result_fifo_dpeth )
{
    uint32_t dataR;
    BFM_READ(CSRA_POOL2D_CONFIG, dataR);
    if (data_type) {
        uint16_t dt = (dataR>>OFFSET_POOL2D_cfg_data_type)&0xFFFF;
        memcpy(data_type, (void*)&dt, 2);
    }
    if (N) *N =  dataR&0xFF;
    if (Q) *Q = (dataR>>OFFSET_POOL2D_cfg_data_Q)&0xFF;
    BFM_READ(CSRA_POOL2D_CONFIG_FIFO, dataR);
    if (feature_fifo_dpeth) *feature_fifo_dpeth = (dataR&0x000000FF);
    if (result_fifo_dpeth ) *result_fifo_dpeth  = (dataR&0x0000FF00)>>8;
    return 0;
}

//------------------------------------------------------------------------------
// Get the version
uint32_t pool_version( void )
{
    uint32_t dataR;
    BFM_READ(CSRA_POOL2D_VERSION, dataR);
    return dataR;
}

//------------------------------------------------------------------------------
int pool_profile_init( void )
{
    uint32_t dataW = 1<<31;
    BFM_WRITE(CSRA_POOL2D_PROFILE_CTL, dataW);
    return 0;
}

//------------------------------------------------------------------------------
int pool_profile_get( uint32_t * const profile_cycles
                    , uint32_t * const profile_cnt_rd
                    , uint32_t * const profile_cnt_wr)
{
    uint32_t data=1;
    BFM_WRITE(CSRA_POOL2D_PROFILE_CTL, data);
    do { BFM_READ(CSRA_POOL2D_PROFILE_CTL, data);
    } while ((data&0x3)!=0);
    if (profile_cycles) { BFM_READ(CSRA_POOL2D_PROFILE_CYCLES, data); *profile_cycles = data; }
    if (profile_cnt_rd) { BFM_READ(CSRA_POOL2D_PROFILE_CNT_RD, data); *profile_cnt_rd = data; }
    if (profile_cnt_wr) { BFM_READ(CSRA_POOL2D_PROFILE_CNT_WR, data); *profile_cnt_wr = data; }
    return 0;
}

//------------------------------------------------------------------------------
int pool_csr_test( void )
{
    uint32_t data;
    #define PRINTFX(format, ...) printf("%s(): " format, __func__, ##__VA_ARGS__)
    #define RCT(A,S) BFM_READ((A),data); PRINTFX("A:0x%08lX D:0x%08X %s\n", (A), data, #S)
    RCT(CSRA_POOL2D_VERSION       ,"VERSION       ");
    RCT(CSRA_POOL2D_CONTROL       ,"CONTROL       ");
    RCT(CSRA_POOL2D_CONFIG        ,"CONFIG        ");
    RCT(CSRA_POOL2D_CONFIG_FIFO   ,"CONFIG_FIFO   ");
    RCT(CSRA_POOL2D_KNL_CFG       ,"KNL_CFG       ");
    RCT(CSRA_POOL2D_FTU_ADDR_LOW  ,"FTU_ADDR_LOW  ");
    RCT(CSRA_POOL2D_FTU_ADDR_HIGH ,"FTU_ADDR_HIGH ");
    RCT(CSRA_POOL2D_FTU_CFG_SIZE  ,"FTU_CFG_SIZE  ");
    RCT(CSRA_POOL2D_FTU_CFG_KNL   ,"FTU_CFG_KNL   ");
    RCT(CSRA_POOL2D_FTU_ITEMS     ,"FTU_ITEMS     ");
    RCT(CSRA_POOL2D_FTU_BURST     ,"FTU_BURST     ");
    RCT(CSRA_POOL2D_RST_ADDR_LOW  ,"RST_ADDR_LOW  ");
    RCT(CSRA_POOL2D_RST_ADDR_HIGH ,"RST_ADDR_HIGH ");
    RCT(CSRA_POOL2D_RST_CFG_SIZE  ,"RST_CFG_SIZE  ");
    RCT(CSRA_POOL2D_RST_ITEMS     ,"RST_ITEMS     ");
    RCT(CSRA_POOL2D_PROFILE_CTL   ,"PROFILE_CTL   ");
    RCT(CSRA_POOL2D_PROFILE_CYCLES,"PROFILE_CYCLES");
    RCT(CSRA_POOL2D_PROFILE_CNT_RD,"PROFILE_CNT_RD");
    RCT(CSRA_POOL2D_PROFILE_CNT_WR,"PROFILE_CNT_WR");
    #undef RCT
    return 0;
}

//------------------------------------------------------------------------------
// It reads a block from SW buffer and then writes them to the HW.
int pool_write_block_to_hw( const uint64_t hw_dst // hw address
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
int pool_read_block_from_hw(       uint8_t * const sw_dst // sw address
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
int pool_check_data_type( const char * const host_dt
                        , const int hN
                        , const int hQ )
{
    char data_type[3];
    uint8_t Q, N;
    pool_get_config(data_type, &Q, &N, NULL, NULL);
    data_type[2]='\0'; // make normal string
    #define QuoteIdent(ident) #ident
    #define QuoteMacro(macro) QuoteIdent(macro)
    PRINTF("%s %s Q=%d N=%d host_dt=%s\n", QuoteMacro(TYPE), data_type, Q, N, host_dt);
    if (!strncmp(data_type,"IT", 2)) {
        if (N==32) {
            if (strcmp(host_dt,"int")&&
                strcmp(host_dt,"int32_t")) {
                PRINTF("data type mis-match A: %d\n", N);
                return -1;
            }
        } else if (N==16) {
            if (strcmp(host_dt,"short")&&
                strcmp(host_dt,"int16_t")) {
                PRINTF("data type mis-match B: %d\n", N);
                return -1;
            }
        } else if (N==8) {
            if (strcmp(host_dt,"char")&&
                strcmp(host_dt,"int8_t")) {
                PRINTF("data type mis-match C: %d\n", N);
                return -1;
            }
        } else {
            PRINTF("data type mis-match C: %d\n", N);
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

int pool_set_addr( unsigned long int offset )
{
    CSRA_POOL2D_BASE = offset;

    CSRA_POOL2D_VERSION       =(offset+0x00);
    CSRA_POOL2D_CONTROL       =(offset+0x10);
    CSRA_POOL2D_CONFIG        =(offset+0x14);
    CSRA_POOL2D_CONFIG_FIFO   =(offset+0x18);
    
    CSRA_POOL2D_COMMAND       =(offset+0x20);
    CSRA_POOL2D_KNL_CFG       =(offset+0x24);
    
    CSRA_POOL2D_FTU_ADDR_LOW  =(offset+0x30);
    CSRA_POOL2D_FTU_ADDR_HIGH =(offset+0x34);
    CSRA_POOL2D_FTU_CFG_SIZE  =(offset+0x38);
    CSRA_POOL2D_FTU_CFG_KNL   =(offset+0x3C);
    CSRA_POOL2D_FTU_ITEMS     =(offset+0x40);
    CSRA_POOL2D_FTU_BURST     =(offset+0x44);
    CSRA_POOL2D_FTU_CHANNEL   =(offset+0x48);
    
    CSRA_POOL2D_RST_ADDR_LOW  =(offset+0x50);
    CSRA_POOL2D_RST_ADDR_HIGH =(offset+0x54);
    CSRA_POOL2D_RST_CFG_SIZE  =(offset+0x58);
    CSRA_POOL2D_RST_ITEMS     =(offset+0x5C);
    CSRA_POOL2D_RST_BURST     =(offset+0x60);
    
    CSRA_POOL2D_PROFILE_CTL   =(offset+0x70);
    CSRA_POOL2D_PROFILE_CYCLES=(offset+0x74);
    CSRA_POOL2D_PROFILE_CNT_RD=(offset+0x78);
    CSRA_POOL2D_PROFILE_CNT_WR=(offset+0x7C);

    return 0;
}

unsigned long int pool_get_addr( void )
{
    return CSRA_POOL2D_BASE;
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
// 2024.12.25: 
// 2021.08.10: Started by Ando Ki (adki@future-ds.com)
//------------------------------------------------------------------------------
