/*
 * Copyright (c) 2021 by Ando Ki.
 * All rights are reserved by Ando Ki.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <libgen.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include "defines.h"
#include "etc.h"
#include "preprocess.h"
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"
#define STB_IMAGE_RESIZE_IMPLEMENTATION
#include "stb_image_resize.h"

/* @brief do_scale_image()
 *        - read image file
 *        - prepare pixel buffers
 *        - get pixel data
 *        - scale image if requires
 *
 * @param[in]   file_name
 * @param[out]  buff_image
 * @param[in]   width (target)
 * @param[in]   height (target)
 * @param[in]   colors (target)
 *
 * @return 0 on success, othewise return negative number.
 */
int do_scale_image( const char          * const file_name
                  ,       image_uchar_t *       buff_image
                  , const int width
                  , const int height
                  , const int colors )
{
    if (buff_image==NULL) return 0;
    if (buff_image->data!=NULL) {
        myError("not clean data.\n");
    }
    int status=0;
    int t_width, t_height, t_channels;
    // do not free "uchar_img" unless error occurs.
    unsigned char *uchar_img
          = (unsigned char *)malloc(sizeof(unsigned char)*colors*height*width);
    unsigned char *stb_img = stbi_load(file_name, &t_width, &t_height, &t_channels, colors);
    if (stb_img==NULL) {
        myError("image loading error: %s\n", file_name);
        status=-1; goto cleanup;
    }
    if ((t_channels!=1)&&(t_channels!=3)&&(t_channels!=4)) {
        myError("image: %s %d channles not supported.\n", file_name, t_channels);
        status=-1; goto cleanup;
    }
  //if ((t_width!=width)||(t_height!=height)||((t_channels!=3)&&(t_channels!=4))) {
    if ((t_width!=width)||(t_height!=height)) {
        unsigned char *resized_img = (unsigned char *)malloc(colors*height*width);
        if (stbir_resize_uint8( stb_img, t_width, t_height, 0
                              , resized_img, width, height, 0, colors)!=1) {
            // stbir_resize_uint8() returns 1 on success.
            stbi_image_free(resized_img);
            myError("error while resizing.\n");
            status=-1; goto cleanup;
        }
        if (stb_img!=NULL) stbi_image_free(stb_img);
        stb_img = resized_img;
#if defined(DEBUG)
if (1) {
        char *t_path = strdup(file_name);
        char *t_name = basename(t_path);
        char *t_ff   = (char *)malloc(strlen(t_name)+10);
        sprintf(t_ff, "/tmp/resized_%s", t_name);
        printf("%s\n", t_ff);
        stbi_write_png(t_ff, width, height, colors, stb_img, width*colors);
        free(t_path);
        free(t_ff);
}
#endif
        buff_image->w = width;
        buff_image->h = height;
        buff_image->c = colors;
    } else {
        buff_image->w = t_width;
        buff_image->h = t_height;
        buff_image->c = t_channels;
    }
    for (int h=0; h<height; h++) {
        int idx=h*width*colors;
        for (int w=0; w<width; w++) {
            for (int c=0; c<colors; c++) {
                uchar_img[idx] = stb_img[idx];
                idx++;
            }
        }
    }

cleanup:
    if (stb_img!=NULL) stbi_image_free(stb_img);
    if (status!=0) {
        free(uchar_img);
    } else {
        if (buff_image!=NULL) {
            buff_image->data = (unsigned char *)uchar_img;
        } else {
            free(uchar_img);
        }
    }
    return status;
}


/* @brief do_normalize_image()
 *        - get pixe data, which are unsigned char (i.e., 8-bit pre color)
 *        - prepare pixel buffers for float
 *        - noramize pixel data: [0:255]->[0.0:1.0]
 *
 * @param[in]    image_uchar
 * @param[in]    image_flat
 *
 * @return 0 on success, othewise return negative number.
 */
int do_normalize_image( const image_uchar_t * const image_uchar
                      ,       image_float_t *       image_float )
{
    if ((image_uchar==NULL)||(image_float==NULL)) return 0;
    if (image_uchar->data==NULL) {
        myError("no pixel data.\n");
    }
    if (image_float->data!=NULL) {
        myError("not clean data.\n");
    }
    int status=0;
    image_float->w = image_uchar->w;
    image_float->h = image_uchar->h;
    image_float->c = image_uchar->c;
    // do not free "float_img" unless error occurs.
    float *float_img = (float *)malloc(sizeof(float)*image_uchar->c*image_uchar->h*image_uchar->w);
    int idx=0;
    float *pt_float = float_img;
    unsigned char *pt_uchar = image_uchar->data;
    for (int idx=0; idx<(image_uchar->c*image_uchar->h*image_uchar->w); idx++) {
         pt_float[idx]  = ((float)pt_uchar[idx])/255.0;
    }

cleanup:
    if (status!=0) {
        free(float_img);
    } else {
        if (image_float!=NULL) {
            image_float->data = (float *)float_img;
        } else {
            free(float_img);
        }
    }
    return status;
}

/* @brief do_scale_normalize_image()
 *        - read image file
 *        - prepare pixel buffers
 *        - get pixel data
 *        - scale image if requires
 *        - noramize pixel data
 *
 * @param[in]   file_name
 * @param[out]  buff_image
 * @param[in]   width (target)
 * @param[in]   height (target)
 * @param[in]   colors (target)
 *
 * @return 0 on success, othewise return negative number.
 */
int do_scale_normalize_image( const char          * const file_name
                            ,       image_float_t *       buff_image
                            , const int width
                            , const int height
                            , const int colors
                            , const int auto_inversion)
{
    if ((file_name==NULL)||(buff_image==NULL)) return 0;
    if (buff_image->data!=NULL) {
        myError("no pixel data.\n");
    }
    int ret;
    image_uchar_t image_uchar;
    image_uchar.data = NULL;
    if ((ret=do_scale_image( file_name
                           ,&image_uchar
                           , width
                           , height
                           , colors ))) {
        return ret;
    }
    if (auto_inversion==1) {
        unsigned int value=0;
        int idx=0;
        for (int h=0; h<image_uchar.h; h++) {
        for (int w=0; w<image_uchar.w; w++) {
        for (int c=0; c<image_uchar.c; c++) {
             value += image_uchar.data[idx++];
        }}}
        if (value>(255*idx)/2) {
            idx = 0;
            for (int h=0; h<image_uchar.h; h++) {
            for (int w=0; w<image_uchar.w; w++) {
            for (int c=0; c<image_uchar.c; c++) {
                 image_uchar.data[idx] = 255 - image_uchar.data[idx];
                 idx++;
            }}}
#if defined(DEBUG)
if (1) {
        char *t_path = strdup(file_name);
        char *t_name = basename(t_path);
        char *t_ff   = (char *)malloc(strlen(t_name)+10);
        sprintf(t_ff, "/tmp/inverted_%s", t_name);
        printf("%s\n", t_ff);
        stbi_write_png(t_ff, width, height, colors, image_uchar.data, width*colors);
        free(t_path);
        free(t_ff);
}
#endif
        }
    }
    if ((ret=do_normalize_image(&image_uchar
                               , buff_image))) {
        return ret;
    }

    return 0;
}

int do_scale_normalize_image_old( const char          * const file_name
                            ,       image_float_t *       buff_image
                            , const int width
                            , const int height
                            , const int colors )
{
    if (buff_image==NULL) return 0;
    int status=0;
    int t_width, t_height, t_channels;
    // do not free "float_img" unless error occurs.
    float (*float_img)[height][width]
          = (float (*)[height][width])malloc(sizeof(float)*colors*height*width);
    unsigned char *stb_img = stbi_load(file_name, &t_width, &t_height, &t_channels, colors);
    if (stb_img==NULL) {
        myError("image loading error: %s\n", file_name);
        status=-1; goto cleanup;
    }
    if ((t_channels!=1)&&(t_channels!=3)&&(t_channels!=4)) {
        myError("image: %s %d channles not supported.\n", file_name, t_channels);
        status=-1; goto cleanup;
    }
    if ((t_width!=width)||(t_height!=height)) {
        unsigned char *resized_img;// = (unsigned char *)malloc(colors*height*width);
        if (stbir_resize_uint8( stb_img, t_width, t_height, 0
                              , resized_img, width, height, 0, colors)!=1) {
            // stbir_resize_uint8() returns 1 on success.
            stbi_image_free(resized_img);
            myError("error while resizing.\n");
            status=-1; goto cleanup;
        }
        if (stb_img!=NULL) stbi_image_free(stb_img);
        stb_img = resized_img;
#if defined(DEBUG)
if (0) {
        char *t_path = strdup(file_name);
        char *t_name = basename(t_path);
        char *t_ff   = (char *)malloc(strlen(t_name)+10);
        sprintf(t_ff, "/tmp/resized_%s", t_name);
        printf("%s\n", t_ff);
        stbi_write_png(t_ff, width, height, colors, stb_img, width*colors);
        free(t_path);
        free(t_ff);
}
#endif
        buff_image->w = width;
        buff_image->h = height;
        buff_image->c = colors;
    } else {
        buff_image->w = t_width;
        buff_image->h = t_height;
        buff_image->c = t_channels;
    }
    for (int h=0; h<height; h++) {
        int idx=h*width;
        for (int w=0; w<width; w++) {
            float_img[0][h][w] = ((float)stb_img[idx])/255.0; // Red
            float_img[1][h][w] = ((float)stb_img[idx+1])/255.0; // Green
            float_img[2][h][w] = ((float)stb_img[idx+2])/255.0; // Blue
            idx += colors; // 1 or 3 or 4
        }
    }

cleanup:
    if (float_img!=NULL) free(float_img);
    if (stb_img!=NULL) stbi_image_free(stb_img);
    if (status!=0) {
        free(float_img);
    } else {
        if (buff_image!=NULL) {
            buff_image->data = (float *)float_img;
        } else {
            free(float_img);
        }
    }
    return status;
}

/*
 * Revision history
 *
 * 2021.04.13: started by Ando Ki (adki@future-ds.com)
 */
