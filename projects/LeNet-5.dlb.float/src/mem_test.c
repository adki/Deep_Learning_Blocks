//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All rights are reserved by Ando Ki.
//------------------------------------------------------------------------------
// mem_test.c
//------------------------------------------------------------------------------
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "mem_test.h"

#define PRINTF(format, ...) printf("%s(): " format, __func__, ##__VA_ARGS__)

//------------------------------------------------------------------------------
int test_mem( uint32_t  addr
            , uint32_t  depth ) // num of bytes from addr
{
    for (int leng=1; leng<=16; leng*=2) {
    for (int bsize=1; bsize<=4; bsize*=2) {
        if (mem_test_core(addr, depth, bsize, leng)!=0) {
            PRINTF("ERROR occurs ****************************************\n");
        }
        fflush(stdout);
    } // for (int bsize
    } // for (int leng

    return 0;
}

//------------------------------------------------------------------------------
#if defined(COSIM_BFM)
#	include "cosim_bfm_api.h"
#elif defined(TRX_AXI)||defined(BFM_AXI)
#	include "trx_axi_api.h"
#endif

#if defined(TRX_AXI)||defined(BFM_AXI)
    extern con_Handle_t handle;
#endif

//------------------------------------------------------------------------------
#if defined(COSIM_BFM)
#      define MEM_WRITE(A, B)        bfm_write((uint32_t)(A), (uint8_t*)(B), 4, 1);
#      define MEM_READ(A, B)         bfm_read((uint32_t)(A), (uint8_t*)(B), 4, 1);
#      define MEM_WRITE_G(A,D,S,L)   bfm_write((uint32_t)(A), (uint8_t*)(D), (S), (L));
#      define MEM_READ_G(A,D,S,L)    bfm_read((uint32_t)(A), (uint8_t*)(D), (S), (L));
#elif defined(TRX_AXI)||defined(BFM_AXI)
#      define MEM_WRITE(A, B)        BfmWrite(handle, (unsigned int)(A), (unsigned int*)&(B), 4, 1)
#      define MEM_READ(A, B)         BfmRead (handle, (unsigned int)(A), (unsigned int*)&(B), 4, 1)
#      define MEM_WRITE_G(A,D,S,L)   BfmWrite(handle, (unsigned int)(A), (unsigned int*)(D), (unsigned int)(S), (unsigned int)(L))
#      define MEM_READ_G(A,D,S,L)    BfmRead(handle, (unsigned int)(A), (unsigned int*)(D), (unsigned int)(S), (unsigned int)(L))
#else
#      define MEM_WRITE(A, B)        *(unsigned *)A = B;
#      define MEM_READ(A, B)         B = *(unsigned *)A;
#endif

//------------------------------------------------------------------------------
// It writes known data to the location from addr to (addr+depth) in bsize-bytes wise.
// It reads data from the location from addr to (addr+depth) in bsize-bytes wise.
// It compares read data to the known data.
int mem_test_core( uint32_t addr
                 , uint32_t depth // num of bytes for all
                 , int      bsize // num of bytes for each beat, 1, 2, 4.
                 , int      leng) // burst length
{
    //--------------------------------------------------------------------------
    #define WLENGTH 1024
    #define BLENGTH 4*WLENGTH
    uint8_t dataBW[BLENGTH];
    uint8_t dataBR[BLENGTH];

    if (depth>BLENGTH) {
        PRINTF("ERROR depth exceeds.\n");
    }

    for (int idx=0; idx<BLENGTH; idx++) {
         // note that dataBW carries byte-stream in little-endian style.
         dataBW[idx] = (idx+1)&0xFF;
         dataBR[idx] = 0;
    }

    //--------------------------------------------------------------------------
    uint32_t offset;
    #if defined(TRX_AXI)||defined(BFM_AXI)
    uint32_t *pBW=(uint32_t*)dataBW;
    #else
    uint8_t *pBW=dataBW;
    #endif
    for (offset=0x0; (offset+bsize*leng)<depth; offset+=(bsize*leng)) {
        MEM_WRITE_G(addr+offset, pBW, bsize, leng);
        #if defined(TRX_AXI)||defined(BFM_AXI)
        pBW += leng;
        #else
        pBW += (bsize*leng);
        #endif
    }
    if (offset<depth) {
        int ln = (depth-offset)/bsize;
        if (ln>0) {
            MEM_WRITE_G(addr+offset, pBW, bsize, ln);
            offset += (bsize*ln);
            #if defined(TRX_AXI)||defined(BFM_AXI)
            pBW += leng;
            #else
            pBW += (bsize*ln);
            #endif
        }
    }
    if (offset<depth) {
        MEM_WRITE_G(addr+offset, pBW, 1, depth-offset);
        #if defined(TRX_AXI)||defined(BFM_AXI)
        pBW += leng;
        #else
        pBW += (depth-offset);
        #endif
        offset += depth-offset;
    }

    #if defined(TRX_AXI)||defined(BFM_AXI)
    uint32_t *pBR=(uint32_t*)dataBR;
    #else
    uint8_t *pBR=dataBR;
    #endif
    for (offset=0x0; (offset+bsize*leng)<depth; offset+=(bsize*leng)) {
        MEM_READ_G(addr+offset, pBR, bsize, leng);
        #if defined(TRX_AXI)||defined(BFM_AXI)
        pBR += leng;
        #else
        pBR += (bsize*leng);
        #endif
    }
    if (offset<depth) {
        int ln = (depth-offset)/bsize;
        if (ln>0) {
            MEM_READ_G(addr+offset, pBR, bsize, ln);
            #if defined(TRX_AXI)||defined(BFM_AXI)
            pBR += leng;
            #else
            offset += (bsize*ln);
            #endif
            pBR += (bsize*ln);
        }
    }
    if (offset<depth) {
        MEM_READ_G(addr+offset, pBR, 1, (depth-offset));
        #if defined(TRX_AXI)||defined(BFM_AXI)
        pBR += leng;
        #else
        pBR += (depth-offset);
        #endif
        offset += depth-offset;
    }

    #if !defined(TRX_AXI)&&!defined(BFM_AXI)
        int error=0;
        for (int idx=0; idx<depth; idx+=1) {
             if (dataBW[idx]!=dataBR[idx]) {
                 printf("[%d] 0x%02X:%02X\n", idx, dataBW[idx], dataBR[idx]);
                 error++;
             }
        }
        if (error==0) printf("Memory test %d-byte size %d-leng OK %d.\n", bsize, leng, depth);
        else          printf("Memory test %d-byte size %d-leng mis-match %d out of %d.\n", bsize, leng, error, depth);
    #else
        pBW=(uint32_t*)dataBW;
        pBR=(uint32_t*)dataBR;
        uint32_t mask;
        switch (bsize) {
         case 1:  mask = 0x000000ff; break;
         case 2:  mask = 0x0000ffff; break;
         case 4:
         default: mask = 0xffffffff; break;
        }
        uint32_t loc=addr;
        int error=0;
        for (int idx=0; idx<(depth/bsize); idx+=1) {
             if ((pBW[idx]&mask)!=(pBR[idx]&mask)) {
                 printf("[0x%08X] 0x%0X:%0X\n", loc, (pBW[idx]&mask), (pBR[idx]&mask));
                 error++;
             }
             loc += bsize;
        }
        if (loc!=(addr+depth)) {
             printf("%s() ERROR not fully tested.\n", __func__);
        }
        if (error==0) printf("Memory test %d-byte size %d-leng OK %d.\n", bsize, leng, depth);
        else          printf("Memory test %d-byte size %d-leng mis-match %d out of %d.\n", bsize, leng, error, depth);
    #endif

    return (error) ? -error : 0;
}

//------------------------------------------------------------------------------
// Revision history
//
// 2021.08.01: Started by Ando Ki.
//------------------------------------------------------------------------------
