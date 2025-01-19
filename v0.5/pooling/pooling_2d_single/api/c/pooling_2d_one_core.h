#ifndef POOLING_2D_ONE_CORE_H
#    define POOLING_2D_ONE_CORE_H
//--------------------------------------------------------
// Copyright (c) 2021-2024 by Future Design Systems, Ltd.
// All right reserved.
//
// http://www.future-ds.com
//--------------------------------------------------------
// VERSION = 2024.12.25.
//--------------------------------------------------------
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define POOLING_NOP   0x0
#define POOLING_MAX   0x1
#define POOLING_AVG   0x2 

extern int pool_set( const uint8_t  command
                   , const uint64_t result_addr
                   , const uint16_t result_leng
                   , const uint64_t feature_addr
                   , const uint16_t feature_width
                   , const uint16_t feature_height
                   , const uint8_t  feature_stride
                   , const uint8_t  feature_padding_pre
                   , const uint8_t  feature_padding_post
                   , const uint16_t feature_leng
                   , const uint16_t feature_channel
                   , const uint8_t  kernel_width
                   , const uint8_t  kernel_height);
extern int pool_go_wait( const uint8_t ie
                       , const uint8_t blocking);

extern int pool_init( void );
extern int pool_clear_interrupt( void );
extern int pool_get_interrupt( uint8_t * const ip
                             , uint8_t * const ie );
extern int pool_get_config( char    * const data_type
                          , uint8_t * const Q
                          , uint8_t * const N
                          , uint8_t * const feature_fifo_dpeth
                          , uint8_t * const result_fifo_dpeth );
extern uint32_t pool_version( void );
extern int pool_profile_init( void );
extern int pool_profile_get( uint32_t * const profile_cycles
                           , uint32_t * const profile_cnt_rd
                           , uint32_t * const profile_cnt_wr);
extern int pool_csr_test( void );

extern int pool_write_block_to_hw( const uint64_t hw_dst // hw address
                                 ,       uint8_t * const sw_src // sw address
                                 , const uint32_t bnum );
extern int pool_read_block_from_hw(       uint8_t * const sw_dst // sw address
                                  , const uint64_t hw_src // hw address
                                  , const uint32_t bnum );
extern int pool_check_data_type( const char * const host_dt
                               , const int hN
                               , const int hQ );

extern int pool_set_addr( unsigned long int base );
extern unsigned long int pool_get_addr (void );

#ifdef __cplusplus
}
#endif
//--------------------------------------------------------
// Revision History
//
// 2024.12.25: Start by Ando Ki (adki@future-ds.com)
// 2021.08.20: Start by Ando Ki (adki@future-ds.com)
//--------------------------------------------------------
#endif
