//------------------------------------------------------------------------------
// Copyright (c) 2021 by Ando Ki.
// All rights are reserved by Ando Ki.
//------------------------------------------------------------------------------
// main.cpp
//------------------------------------------------------------------------------
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include <getopt.h>
#include <signal.h>
#include <math.h>
#include <iostream>
#if defined(COSIM_BFM)
#	include "cosim_bfm_api.h"
#endif
#include "defines_dpu.h"

const char program[]="test";
const unsigned int version=0x20210810;

int verbose = 0;
int cid = 0;
int test_level=0;
int test_mem=1;
int test_conv=0;
int test_pool=0;
int test_linear=0;
int test_mover_fill=0;
int test_mover_copy=0;
int test_mover_residual=0;
int test_mover_concat0=0;
int test_mover_concat1=0;

// It should reflect 'DATA_TYPE/DATA_WIDTH/DATA_WIDTH_Q' macros
// in 'defines_system.v' file in HW.
#ifdef DATA_TYPE
#define TYPE DATA_TYPE
#else
#define TYPE int32_t
#endif

#define QuoteIdent(ident) #ident
#define QuoteMacro(macro) QuoteIdent(macro)
#define PRINTF(format, ...) printf("%s(): " format, __func__, ##__VA_ARGS__)

//------------------------------------------------------------------------------
int main(int argc, char* argv[])
{
    extern void sig_handle( int );
    extern int  arg_parser( int, char ** );
    extern int  test_memory( uint32_t addr, uint32_t depth );
    extern int  test_convolution_2d( uint32_t base, int test_level, int verbose );

    if ((signal(SIGINT, sig_handle)==SIG_ERR)
            #ifndef WIN32
            ||(signal(SIGQUIT, sig_handle)==SIG_ERR)
            #endif
            ) {
          fprintf(stderr, "Error: signal error\n");
          exit(1);
    }
    
    if (arg_parser(argc, argv)) return 1;

#if defined(COSIM_BFM)
    bfm_set_verbose(verbose); // optional
    bfm_open(cid); // mandatory
    bfm_barrier(cid); // mandatory
#endif

    if (test_mem>0) {
        uint32_t  addr=DPU_ADDR_BASE_MEM;
        uint32_t  depth=4*32;
        test_memory( addr, depth );
    }
    if (test_conv>0) {
        test_convolution_2d( DPU_ADDR_BASE_CONV, test_level, verbose );
    }

#if defined(COSIM_BFM)
    bfm_close(cid); // mandatory
#endif

    return 0;
}

//------------------------------------------------------------------------------
int arg_parser(int argc, char **argv)
{
    int opt;
    int longidx=0;
    extern void help(int, char **);
    extern void print_license(void);
    extern void print_version(void);

    struct option longopts[] = {
          {"test_level"         , required_argument, 0, 'T'}
        , {"test_mem"           , required_argument, 0, 'A'}
        , {"test_conv"          , required_argument, 0, 'B'}
        , {"cid"                , required_argument, 0, 'c'}
        , {"verbose"            , required_argument, 0, 'g'}
        , {"version"            , no_argument      , 0, 'v'}
        , {"license"            , no_argument      , 0, 'l'}
        , {"help"               , no_argument      , 0, 'h'}
        , { 0                   , 0                , 0,  0 }
    };

    while ((opt=getopt_long(argc, argv, "T:A:B:C:D:E:c:g:vlh?", longopts, &longidx))!=-1) {
       switch (opt) {
       case 'c': cid = atoi(optarg); break;
       case 'T': test_level = atoi(optarg); break;
       case 'A': test_mem = atoi(optarg); break;
       case 'B': test_conv = atoi(optarg); break;
       case 'g': verbose = atoi(optarg); break;
       case 'v': print_version(); exit(0); break;
       case 'l': print_license(); exit(0); break;
       case 'h':
       case '?': help(argc, argv); exit(0); break;
       case  0 : return -1;
                 break;
       default: 
          fprintf(stderr, "undefined option: %c\n", optopt);
          help(argc, argv);
          exit(1);
       }
    }
    return 0;
}

//------------------------------------------------------------------------------
void help(int argc, char **argv)
{
  fprintf(stderr, "[Usage] %s [options]\n", argv[0]);
  fprintf(stderr, "\t-T,--test_level=num           test level (default: %d)\n", test_level);
  fprintf(stderr, "\t-A,--test_mem=1|0             memory test when 1 (default: %d)\n", test_mem);
  fprintf(stderr, "\t-B,--test_conv=1|0            convolution test when 1 (default: %d)\n", test_conv);
  fprintf(stderr, "\t-c,--cid=num                  channel id (default: %d)\n", cid);
  fprintf(stderr, "\t-g,--verbose=num              verbose level  (default: %d)\n", verbose);
  fprintf(stderr, "\t-v,--version                  print version\n");
  fprintf(stderr, "\t-l,--license                  print license message\n");
  fprintf(stderr, "\t-h                            print help message\n");
  fprintf(stderr, "\n");
}

//------------------------------------------------------------------------------
const char license[] =
"Copyright (c) 2021 by Ando Ki (andoki@gmail.com).\n\n\
This contents and its associated materials are licensed with the 2-clause BSD license to make the program and library useful in open and closed source products independent of their licensing scheme. Each contributor holds copyright over their respective contribution.\n\
All contents are provided as it is WITHOUT ANY WARRANTY and NO TECHNICAL SUPPORT will be provided for problems that might arise.\n";
void print_license(void)
{
     printf("%s %X\n\n", program, version);
     printf("%s", license);
}

//------------------------------------------------------------------------------
void print_version(void)
{
     printf("%X\n", version);
}

//------------------------------------------------------------------------------
void sig_handle(int sig)
{
   extern void cleanup();
   switch (sig) {
   case SIGINT:
   #ifndef WIN32
   case SIGQUIT:
   #endif
   case SIGSEGV:
        exit(0);
        break;
   }
}

//------------------------------------------------------------------------------
// Revision history
//
// 2021.08.01: Started by Ando Ki.
//------------------------------------------------------------------------------
