#pragma once
#include <stding.h>

#ifdef __cplusplus
extern "C" {
#endif

#define Pooling2dMax Pooling2dMaxFloat

extern void Pooling2dMaxInt
(           int      *out_data    // out_channel x out_size x out_size
    , const int      *in_data     // in_channel x in_size x in_size
    , const uint16_t  out_size    // only for square matrix
    , const uint16_t  in_size     // only for square matrix
    , const uint8_t   kernel_size // only for square matrix
    , const uint16_t  channel     // in/out channel
    , const uint8_t   stride
    , const uint8_t   padding
    , const int       ceil_mode   // not implemented yet
    , const int       rigor // check rigorously when 1
    , const int       verbose
);

extern void Pooling2dMaxFloat
(           float    *out_data    // out_channel x out_size x out_size
    , const float    *in_data     // in_channel x in_size x in_size
    , const uint16_t  out_size    // only for square matrix
    , const uint16_t  in_size     // only for square matrix
    , const uint8_t   kernel_size // only for square matrix
    , const uint16_t  channel     // in/out channel
    , const uint8_t   stride
    , const uint8_t   padding
    , const int       ceil_mode   // not implemented yet
    , const int       rigor // check rigorously when 1
    , const int       verbose
);

#ifdef __cplusplus
}
#endif
