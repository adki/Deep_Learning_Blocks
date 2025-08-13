//--------------------------------------------------------
// Copyright (c) 2025 by Future Design Systems, Ltd.
// All right reserved.
//
// http://www.future-ds.com
//--------------------------------------------------------
// VERSION = 2025.01.15.
//--------------------------------------------------------
#include <stdio.h>
#include <string.h>

#include "defines_dpu.h"
#include "dpu_config.h"
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
#ifdef  DPU_ADDR_BASE_CONFIG
//#pragma GCC warning DPU_ADDR_BASE_CONV should be defined.
static unsigned long int  CSRA_CONFIG_BASE=DPU_ADDR_BASE_CONFIG
#else
static unsigned long int  CSRA_CONFIG_BASE=0xC0000000L;
#endif

static unsigned long int CSRA_CONFIG_VERSION = (CSRA_CONFIG_BASE+0x00);
static unsigned long int CSRA_CONFIG_BUS     = (CSRA_CONFIG_BASE+0x10);
static unsigned long int CSRA_CONFIG_TYPE    = (CSRA_CONFIG_BASE+0x14);
static unsigned long int CSRA_CONFIG_BITS    = (CSRA_CONFIG_BASE+0x18);
static unsigned long int CSRA_CONFIG_MODULE  = (CSRA_CONFIG_BASE+0x1C);

//------------------------------------------------------------------------------
#if defined(DEBUG) || defined(RIGOR)
#define PRINTF(format, ...) printf("%s(): " format, __func__, ##__VA_ARGS__)
#else
#define PRINTF(...) do { } while (0)
#endif

//------------------------------------------------------------------------------
int config_get_config( char     * const data_type
                     , uint8_t  * const Q // num of bits of fractional part
                     , uint8_t  * const N // num of bits of whole part
                     , uint16_t * const bus_width_addr
                     , uint16_t * const bus_width_data
                     , uint16_t * const modules) // {mover(3),linear(2),pooling(1),conv(0)}
{
    uint32_t dataR;
    BFM_READ(CSRA_CONFIG_TYPE, dataR);
    if (data_type) {
        uint16_t dt = (dataR)&0xFFFF;
        memcpy(data_type, (void*)&dt, 2);
    }
    BFM_READ(CSRA_CONFIG_BITS, dataR);
    if (N) *N =  dataR&0xFF;
    if (Q) *Q = (dataR>>16)&0xFF;
    BFM_READ(CSRA_CONFIG_BUS, dataR);
    if (bus_width_addr) *bus_width_addr =  dataR&0xFFFF;
    if (bus_width_data) *bus_width_data = (dataR>>16)&0xFFFF;

    BFM_READ(CSRA_CONFIG_MODULE, dataR);
    if (modules ) *modules  = (dataR&0xFFFF);
    return 0;
}

//------------------------------------------------------------------------------
// Get the version
uint32_t config_version( void )
{
    uint32_t dataR;
    BFM_READ(CSRA_CONFIG_VERSION, dataR);
    return dataR;
}

//------------------------------------------------------------------------------
int config_csr_test( void )
{
    uint32_t data;
    #define RCT(A,S) BFM_READ((A),data); PRINTF("A:0x%08lX D:0x%08X %s\n", (A), data, #S)
    RCT(CSRA_CONFIG_VERSION ,"VERSION");
    RCT(CSRA_CONFIG_BUS     ,"BUS    ");
    RCT(CSRA_CONFIG_TYPE    ,"TYPE   ");
    RCT(CSRA_CONFIG_BITS    ,"BITS   ");
    RCT(CSRA_CONFIG_MODULE  ,"MODULE ");
    #undef RCT
    return 0;
}

//------------------------------------------------------------------------------
// It checks data type and return 0 on match, oterwise return negative number.
// * host_dt: data type name, e.g, int, int32_t, float, ap_fixed, half
// * hN: whle bits
// * hQ: fractional bits; valid for only fixed-point
int config_check_data_type( const char * const host_dt
                          , const int hN
                          , const int hQ )
{
    char data_type[3];
    uint8_t Q, N;
    config_get_config(data_type, &Q, &N, NULL, NULL, NULL);
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

int config_set_addr( unsigned long int base )
{
    CSRA_CONFIG_BASE = base;

    CSRA_CONFIG_VERSION = (base+0x00);
    CSRA_CONFIG_BUS     = (base+0x10);
    CSRA_CONFIG_TYPE    = (base+0x14);
    CSRA_CONFIG_BITS    = (base+0x18);
    CSRA_CONFIG_MODULE  = (base+0x1C);

    return 0;
}

unsigned long int config_get_addr( void )
{
    return CSRA_CONFIG_BASE;
}

//------------------------------------------------------------------------------
#undef PRINTF
#undef BFM_WRITE
#undef BFM_READ
#undef BFM_WRITE_BURST
#undef BFM_READ_BURST

//--------------------------------------------------------
// Revision History
//
// 2025.01.15: Start by Ando Ki (adki@future-ds.com)
//--------------------------------------------------------
