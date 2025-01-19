#ifndef LINEAR_1D_ONE_CORE_H
#    define LINEAR_1D_ONE_CORE_H
//--------------------------------------------------------
// Copyright (c) 2021 by Future Design Systems, Ltd.
// All right reserved.
//
// http://www.future-ds.com
//--------------------------------------------------------
// VERSION = 2021.08.20.
//--------------------------------------------------------
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define ACTIV_FUNC_BYPASS       0x0
#define ACTIV_FUNC_RELU         0x1
#define ACTIV_FUNC_LEAKY_RELU   0x2
#define ACTIV_FUNC_SIGMOID      0x3
#define ACTIV_FUNC_TANH         0x4

extern int linear_set( const uint64_t result_addr // =previous_addr
                     , const uint16_t result_size // =weight_height (not AxLENG format)
                     , const uint16_t result_leng // =bias_leng (not AxLENG format)
                     , const uint64_t input_addr
                     , const uint16_t input_size
                     , const uint16_t input_leng // not AxLENG format
                     , const uint64_t weight_addr
                     , const uint16_t weight_width // =input_size
                     , const uint16_t weight_height
                     , const uint16_t weight_leng // not AxLENG format
                     , const uint64_t bias_addr
                     , const uint16_t bias_size // set 0 for no-bias
                     , const uint8_t  activ_func
                     , const uint32_t activ_param );
extern int linear_go_wait( const uint8_t ie // make interrupt enabled
                         , const uint8_t blocking);// make blocking to wait for complete

extern int linear_init( void );
extern int linear_clear_interrupt( void );
extern int linear_get_interrupt( uint8_t * const ip
                               , uint8_t * const ie );
extern int linear_get_config( char    * const data_type
                            , uint8_t * const Q // num of bits of fractional part
                            , uint8_t * const N // num of bits of whole part
                            , uint8_t * const input_fifo_dpeth
                            , uint8_t * const weight_fifo_dpeth
                            , uint8_t * const result_fifo_dpeth );
extern uint32_t linear_version( void );
extern int linear_profile_init( void );
extern int linear_profile_get( uint32_t * const profile_cycles
                             , uint32_t * const profile_mac_num
                             , uint32_t * const profile_mac_ovr
                             , uint32_t * const profile_bia_ovr
                             , uint32_t * const profile_act_ovr
                             , uint32_t * const profile_cnt_rd 
                             , uint32_t * const profile_cnt_wr );
extern int linear_csr_test( void );

extern int linear_write_block_to_hw( const uint64_t hw_dst // hw address
                                   ,       uint8_t * const sw_src // sw address
                                   , const uint32_t bnum );
extern int linear_read_block_from_hw(       uint8_t * const sw_dst // sw address
                                    , const uint64_t hw_src // hw address
                                    , const uint32_t bnum );
extern int linear_check_data_type( const char * const host_dt
                                 , const int hN
                                 , const int hQ );
extern int linear_set_addr ( unsigned long int base );
extern unsigned long int linear_get_addr (void );

#ifdef __cplusplus
}
#endif
//--------------------------------------------------------
// Revision History
//
// 2021.08.20: Start by Ando Ki (adki@future-ds.com)
//--------------------------------------------------------
#endif
