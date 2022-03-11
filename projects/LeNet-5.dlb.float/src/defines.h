#pragma once
//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All rights are reserved by Ando Ki.
//------------------------------------------------------------------------------
#ifdef __cplusplus
extern "C" {
#endif

#define IMAGE_GREY    1
#define IMAGE_RGB     3
#define IMAGE_COLORS  IMAGE_GREY
#define IMAGE_WIDTH   32
#define IMAGE_HEIGHT  32
#define IMAGE_SIZE   (IMAGE_COLORS*IMAGE_HEIGHT*IMAGE_WIDTH)

#ifndef IMAGE_T
#define IMAGE_T
typedef struct {
    int w; // width, cols
    int h; // height, rows
    int c; // channels
    float *data; // [c][h][w] (free after use)
} image_float_t;
#endif
typedef struct {
    int w; // width, cols
    int h; // height, rows
    int c; // channels
    unsigned char *data; // [c][h][w] (free after use)
} image_uchar_t;

#ifdef __cplusplus
}
#endif
