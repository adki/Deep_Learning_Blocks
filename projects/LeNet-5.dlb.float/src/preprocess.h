#pragma once
/*
 * Copyright (c) 2021 by Ando Ki.
 * All rights reserved.
 */

#include "defines.h"

#ifdef __cplusplus
extern "C" {
#endif

extern int do_scale_normalize_image( const char          * const file_name
                                   ,       image_float_t *       buff_image
                                   , const int width
                                   , const int height
                                   , const int colors
                                   , const int auto_inversion);
extern int do_scale_image( const char          * const file_name
                         ,       image_uchar_t *       buff_image
                         , const int width
                         , const int height
                         , const int colors );
extern int do_normalize_image( const image_uchar_t * const image_uchar
                             ,       image_float_t *       image_float );

#ifdef __cplusplus
}
#endif

/*
 * Revision history
 *
 * 2021.04.13: started by Ando Ki (adki@future-ds.com)
 */
