#pragma once
//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All rights are reserved by Ando Ki.
//------------------------------------------------------------------------------
#include "preprocess.h"

//------------------------------------------------------------------------------
// It reads 'image_file' and makes 32x32 grey normalized image data.
template<class TYPE=float>
int get_image(       TYPE * const image_normalized
             , const char * const image_file
             , const unsigned int width  // (target) expecting width of result image
             , const unsigned int height // (target) expecting height of result image
             , const unsigned int colors // (target) expecting color-channels of result image
             , const int    rigor=0
             , const int    verbose=0)
{
    if (image_normalized==NULL) return -1;
    image_float_t image_float;
    image_float.data = NULL;
    if (do_scale_normalize_image( image_file
                                ,&image_float
                                , width
                                , height
                                , colors
                                , 1)) {
        if (image_float.data!=NULL) free(image_float.data);
        return -1;
    }

#if 0
    int idx=0;
    for (int c=0; c=IMAGE_COLORS; c++) {
        for (int h=0; h=IMAGE_HEIGHT; h++) {
            for (int w=0; w=IMAGE_WIDTH; w++) {
                image_normalized[idx] = TYPE(image_float.data[idx]);
                idx++;
            } // for (int w=0
        } // for (int h=0
    } // for (int c=0
#else
    memcpy(image_normalized, image_float.data, colors*width*height*sizeof(TYPE));
#endif

    if (image_float.data!=NULL) free(image_float.data);

    return 0;
}
