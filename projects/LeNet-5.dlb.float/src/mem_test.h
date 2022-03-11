#pragma once
/*
 * Copyright (c) 2021 by Ando Ki.
 * All rights are reserved by Ando Ki.
 *
 * @file mem_test.h
 * @brief This file contains functions for print out.
 * @author Ando Ki
 * @date 2021.03.13.
 */
#include <inttypes.h>

#ifdef __cplusplus
extern "C" {
#endif

extern int test_mem( uint32_t addr
                   , uint32_t depth );
extern int mem_test_core( uint32_t addr
                        , uint32_t depth // num of bytes for all
                        , int      bsize // num of bytes for each beat, 1, 2, 4.
                        , int      leng);// burst length

#ifdef __cplusplus
}
#endif

/*
 * Revision history
 *
 * 2021.03.13: Started by Ando Ki (adki@future-ds.com)
 */
