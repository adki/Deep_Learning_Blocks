#ifndef DPU_CONFIG_H
#    define DPU_CONFIG_H
//--------------------------------------------------------
// Copyright (c) 2025 by Future Design Systems, Ltd.
// All right reserved.
//
// http://www.future-ds.com
//--------------------------------------------------------
// VERSION = 2025.01.15.
//--------------------------------------------------------
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif
extern int config_get_config( char     * const data_type
                     , uint8_t  * const Q // num of bits of fractional part
                     , uint8_t  * const N // num of bits of whole part
                     , uint16_t * const bus_width_addr
                     , uint16_t * const bus_width_data
                     , uint16_t * const modules);// {mover(3),linear(2),pooling(1),conv(0)}

extern uint32_t config_version( void );
extern int config_csr_test( void );
extern int config_check_data_type( const char * const host_dt
                                 , const int hN
                                 , const int hQ );

extern int config_set_addr( unsigned long int base );
extern unsigned long int config_get_addr( void );
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
// 2025.01.15: Start by Ando Ki (adki@future-ds.com)
//--------------------------------------------------------
#endif
