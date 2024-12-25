#ifndef MOVER_2D_ONE_CORE_H
#    define MOVER_2D_ONE_CORE_H
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

#define MOVER_COMMAND_NOP        0x0
#define MOVER_COMMAND_FILL       0x1
#define MOVER_COMMAND_COPY       0x2
#define MOVER_COMMAND_RESIDUAL   0x3 // point-to-point adder
#define MOVER_COMMAND_CONCAT0    0x4
#define MOVER_COMMAND_CONCAT1    0x5
#define MOVER_COMMAND_TRANSPOSE  0x6

#define ACTIV_FUNC_BYPASS        0x0
#define ACTIV_FUNC_RELU          0x1
#define ACTIV_FUNC_LEAKY_RELU    0x2
#define ACTIV_FUNC_SIGMOID       0x3 // not yet
#define ACTIV_FUNC_TANH          0x4 // not yet

extern int mover_fill_set( const uint64_t dst_addr // hw address
                         , const uint16_t width
                         , const uint16_t height
                         , const uint32_t value );
extern int mover_copy_set( const uint64_t dst_addr // hw address
                         , const uint64_t src_addr // hw address
                         , const uint16_t width
                         , const uint16_t height
                         , const uint8_t  activ_func
                         , const uint32_t activ_param);
extern int mover_residual_set( const uint64_t dst_addr // hw address
                             , const uint64_t srcA_addr // hw address
                             , const uint64_t srcB_addr // hw address
                             , const uint16_t width
                             , const uint16_t height
                             , const uint8_t  activ_func
                             , const uint32_t activ_param);
extern int mover_concat0_set( const uint64_t dst_addr // hw address
                            , const uint16_t dst_width
                            , const uint16_t dst_height
                            , const uint64_t srcA_addr // hw address
                            , const uint16_t srcA_width
                            , const uint16_t srcA_height
                            , const uint64_t srcB_addr // hw address
                            , const uint16_t srcB_width
                            , const uint16_t srcB_height);
extern int mover_concat1_set( const uint64_t dst_addr // hw address
                            , const uint16_t dst_width
                            , const uint16_t dst_height
                            , const uint64_t srcA_addr // hw address
                            , const uint16_t srcA_width
                            , const uint16_t srcA_height
                            , const uint64_t srcB_addr // hw address
                            , const uint16_t srcB_width
                            , const uint16_t srcB_height);
extern int mover_go_wait( const uint8_t ie
                        , const uint8_t blocking);

extern int mover_init( void );
extern int mover_clear_interrupt( void );
extern int mover_get_interrupt( uint8_t * const ip
                              , uint8_t * const ie );
extern int mover_get_config( char    * const data_type
                           , uint8_t * const Q
                           , uint8_t * const N
                           , uint8_t * const feature_fifo_dpeth
                           , uint8_t * const result_fifo_dpeth );
extern uint32_t mover_version( void );
extern int mover_profile_init( void );
extern int mover_profile_get( uint32_t * const profile_cycles
                            , uint32_t * const profile_residual_overflow
                            , uint32_t * const profile_cnt_rd
                            , uint32_t * const profile_cnt_wr);
extern int mover_csr_test( void );

extern int mover_write_block_to_hw( const uint64_t hw_dst // hw address
                                  ,       uint8_t * const sw_src // sw address
                                  , const uint32_t bnum );
extern int mover_read_block_from_hw(       uint8_t * const sw_dst // sw address
                                   , const uint64_t hw_src // hw address
                                   , const uint32_t bnum );
extern int mover_check_data_type( const char * const host_dt
                                , const int hN
                                , const int hQ );
extern int mover_set_addr( unsigned long int offset );
extern unsigned long int mover_get_addr( void );

#ifdef __cplusplus
}
#endif
//--------------------------------------------------------
// Revision History
//
// 2021.08.20: Start by Ando Ki (adki@future-ds.com)
//--------------------------------------------------------
#endif
