//------------------------------------------------------------------------------
// Copyright (c) 2025 by Ando Ki.
// All rights are reserved by Ando Ki.
//------------------------------------------------------------------------------
// dpu_config.cpp
//------------------------------------------------------------------------------
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include <iostream>

#include "defines_dpu.h"
#include "dpu_config.h" // Deep Learning Block API

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
int test_dpu_config( uint32_t base, int test_level, int verbose )
{
    config_set_addr((unsigned long int)base );
    #if defined(RIGOR)||defined(DEBUG)
    unsigned long int caddr = config_get_addr();
    if (base!=(uint32_t)caddr) {
        PRINTF("DPU config at 0x%08lX, but 0x%08X expected\n", caddr, base);
    }
    #endif
    #if defined(DEBUG)
    config_version();
    config_csr_test();
    #endif

    #if defined(RIGOR)||defined(DEBUG)
    if (config_check_data_type(QuoteMacro(TYPE), sizeof(TYPE)*8, 0)) {
        char data_type[3];
        uint8_t Q, N;
        config_get_config(data_type, &Q, &N, NULL, NULL, NULL);
        data_type[2]='\0'; // make normal string
        PRINTF("data type mis-match: \"%s:%d:%d\" \"%s\"\n",
                data_type, N, Q, QuoteMacro(TYPE));
    }
    #endif

    return 0;
}

//------------------------------------------------------------------------------
// Revision history
//
// 2025.01.15: Started by Ando Ki.
//------------------------------------------------------------------------------
