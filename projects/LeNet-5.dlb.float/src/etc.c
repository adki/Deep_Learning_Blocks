/*
 * Copyright (c) 2021 by Ando Ki.
 * All rights are reserved by Ando Ki.
 *
 * @file etc.c
 * @brief This file contains functions for print out.
 * @author Ando Ki
 * @date 2021.03.13.
 */

#include <stdio.h>
#include <stdarg.h>
#include <sys/time.h>
#include <libgen.h>
#include "etc.h"

// return current time in micro-second unit
long long timestamp()
{
    struct timeval time;
    if (gettimeofday(&time,NULL)){
        return 0;
    }
    return (long long)(time.tv_sec*1000000 + time.tv_usec);
}

#define stream_error  stderr
#define stream_warn   stdout
#define stream_info   stdout
#define stream_print  stdout

/* @brief myError()
 *
 * @param[in]    file: file name
 * @param[in]    line: line number
 * @param[in]    fmt : format
 *
 * @return print location of error and terminate the program.
 */
int myErrorCore( const char *file
               , const int   line
               , const char *func
               , const char *fmt, ...)
{
    va_list     ap;
    int         ret;
    int vfprintf(FILE* stream, const char *fmt, va_list ap);
    fprintf(stream_error, "ERROR: %s %d %s(): ", basename((char*)file), line, func);
    va_start(ap, fmt);
    ret = vfprintf(stream_error, fmt, ap);
    va_end(ap);
    fflush(stream_error);
    return(ret);
}

/* @brief myWarn()
 *
 * @param[in]    file: file name
 * @param[in]    line: line number
 * @param[in]    fmt : format
 *
 * @return print location of error and terminate the program.
 */
int myWarnCore( const char *file
              , const int   line
              , const char *func
              , const char *fmt, ...)
{
    va_list     ap;
    int         ret;
    int vfprintf(FILE* stream, const char *fmt, va_list ap);
    fprintf(stream_warn, "WARNING: %s %d %s(): ", basename((char*)file), line, func);
    va_start(ap, fmt);
    ret = vfprintf(stream_warn, fmt, ap);
    va_end(ap);
    fflush(stream_warn);
    return(ret);
}

/* @brief myInfo()
 *
 * @param[in]    file: file name
 * @param[in]    line: line number
 * @param[in]    fmt : format
 *
 * @return print location of error and terminate the program.
 */
int myInfoCore( const char *file
              , const int   line
              , const char *func
              , const char *fmt, ...)
{
    va_list     ap;
    int         ret;
    int vfprintf(FILE* stream, const char *fmt, va_list ap);
    fprintf(stream_info, "INFO: %s %d %s(): ", basename((char*)file), line, func);
    va_start(ap, fmt);
    ret = vfprintf(stream_warn, fmt, ap);
    va_end(ap);
    fflush(stream_warn);
    return(ret);
}

/* @brief myPrint() assert
 *
 * @param[in]    file: file name
 * @param[in]    line: line number
 * @param[in]    fmt : format
 *
 * @return print message
 */
int myPrint(const char *fmt, ...)
{
    va_list     ap;
    int         ret;
    int vfprintf(FILE* stream, const char *fmt, va_list ap);
    va_start(ap, fmt);
    ret = vfprintf(stream_print, fmt, ap);
    va_end(ap);
    fflush(stream_print);
    return(ret);
}

#undef stream_error
#undef stream_warn
#undef stream_info
#undef stream_print

/*
 * Revision history
 *
 * 2021.03.13: Started by Ando Ki (adki@future-ds.com)
 */
