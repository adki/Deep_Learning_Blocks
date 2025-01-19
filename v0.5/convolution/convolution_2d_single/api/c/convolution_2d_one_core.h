#ifndef CONVOLUTION_2D_ONE_CORE_H
#    define CONVOLUTION_2D_ONE_CORE_H
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

extern int conv_set( const uint64_t result_addr
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
                   , const uint64_t channel_addr
                   , const uint16_t channel_leng // 0 if not used (not AxLENG format)
                   , const uint32_t bias_value
                   , const uint8_t  activ_func
                   , const uint32_t activ_param );
extern int conv_go_wait( const uint8_t ie
                       , const uint8_t blocking);
extern int conv_init( void );
extern int conv_clear_interrupt( void );
extern int conv_get_interrupt( uint8_t * const ip
                             , uint8_t * const ie );
extern int conv_get_config( char     * const data_type
                          , uint8_t  * const Q
                          , uint8_t  * const N
                          , uint8_t  * const kernel_fifo_dpeth
                          , uint8_t  * const feature_fifo_dpeth
                          , uint8_t  * const channel_fifo_dpeth
                          , uint8_t  * const result_fifo_dpeth );
extern uint32_t conv_version( void );
extern int conv_profile_init( void );
extern int conv_profile_get( uint32_t * const profile_cycles
                           , uint32_t * const profile_mac_num
                           , uint32_t * const profile_mac_ovr
                           , uint32_t * const profile_chn_ovr
                           , uint32_t * const profile_bia_ovr
                           , uint32_t * const profile_act_ovr
                           , uint32_t * const profile_cnt_rd
                           , uint32_t * const profile_cnt_wr);
extern int conv_csr_test( void );
extern int conv_write_block_to_hw( const uint64_t hw_dst // hw address
                                 ,       uint8_t * const sw_src // sw address
                                 , const uint32_t  bnum );
extern int conv_read_block_from_hw(       uint8_t * const sw_dst // sw address
                                  , const uint64_t  hw_src // hw address
                                  , const uint32_t  bnum );
extern int conv_check_data_type( const char * const host_dt
                               , const int hN
                               , const int hQ );

extern int conv_set_addr( unsigned long int base );
extern unsigned long int conv_get_addr( void );
#ifdef __cplusplus
}
#endif
//--------------------------------------------------------
// Note
// "int const *"/"const int *" is pointer to constant integer
// "int * const" is a constant pointer to integer
// "const int * const" is a constant pointer to constant integer
//--------------------------------------------------------
// Revision History
//
// 2024.12.25: conv_set_addr()/conv_get_addr() added.
// 2021.08.20: Start by Ando Ki (adki@future-ds.com)
//--------------------------------------------------------
#endif
