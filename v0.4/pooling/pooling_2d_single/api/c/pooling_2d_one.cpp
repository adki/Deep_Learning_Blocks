#include "pooling_2d_one.hpp"

#ifndef DPU_ADDR_BASE_MEM
#define DPU_ADDR_BASE_MEM 0x0
#endif

extern "C" {

void Pooling2dMaxInt
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
)
{
    const uint64_t  hw_result_addr = DPU_ADDR_BASE_MEM; // out_channel x out_size x out_size
    const uint64_t  hw_feature_addr= hw_result_addr + (channel*out_size*out_size*sizeof(int)+0x1000)&~0xFFF;

    dlb::Pooling2d<int> (
          out_data
        , in_data
        , POOLING_MAX
        , hw_result_addr
        , hw_feature_addr
        , out_size
        , in_size
        , kernel_size
        , channel
        , stride
        , padding
        , 0 // interrupt enabled if 1
        , rigor
        , verbose
        , 0 // performance gathering enabled if 1
    );
}

void Pooling2dMaxFloat
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
)
{
    const uint64_t  hw_result_addr =0; // out_channel x out_size x out_size
    const uint64_t  hw_feature_addr= hw_result_addr + (channel*out_size*out_size*sizeof(float)+0x1000)&~0xFFF;

    dlb::Pooling2d<float> (
          out_data
        , in_data
        , POOLING_MAX
        , hw_result_addr
        , hw_feature_addr
        , out_size
        , in_size
        , kernel_size
        , channel
        , stride
        , padding
        , 0 // interrupt enabled if 1
        , rigor
        , verbose
        , 0 // performance gathering enabled if 1
    );
}

} // extern "C"
