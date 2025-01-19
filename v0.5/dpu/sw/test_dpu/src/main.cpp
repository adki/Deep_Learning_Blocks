//------------------------------------------------------------------------------
// Copyright (c) 2025 by Ando Ki.
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
#elif defined(TRX_AXI)||defined(BFM_AXI)
#	include "trx_axi_api.h"
#endif
#include "defines_dpu.h"

const char program[]="test";
const unsigned int version=0x20250110;

int verbose = 0;
int cid = 0;
int test_level=0;
int test_mem=1;
int test_dconfig=0;
int test_conv=1;
int test_pool=1;
int test_linear=1;

#if defined(TRX_AXI)||defined(BFM_AXI)
    con_Handle_t handle=NULL;
    int  get_confmc( con_Handle_t handle );
#endif

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
    extern int  test_dpu_config( uint32_t base, int test_level, int verbose );
    extern int  test_memory( uint32_t addr, uint32_t depth );
    extern int  test_convolution_2d( uint32_t base, int test_level, int verbose );
    extern int  test_pooling_2d( uint32_t base, int test_level, int verbose );
    extern int  test_linear_1d( uint32_t base, int test_level, int verbose );

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
#elif defined(TRX_AXI)||defined(BFM_AXI)
    if ((handle=conInit(cid, CON_MODE_CMD, CONAPI_LOG_LEVEL_INFO))==NULL) {
       printf("cannot initialize CON-FMC\n");
       printf("%d %s\n", conGetErrorConapi(), conErrorMsgConapi(conGetErrorConapi()));
       return 0;
    }
#endif

    if (test_mem>0) {
        uint32_t  addr=DPU_ADDR_BASE_MEM;
        uint32_t  depth=4*32;
        test_memory( addr, depth );
    }
    if (test_dconfig>0) {
        test_dpu_config( DPU_ADDR_BASE_CONV, test_level, verbose );
    }
    if (test_conv>0) {
        test_convolution_2d( DPU_ADDR_BASE_CONV, test_level, verbose );
    }
    if (test_pool>0) {
        test_pooling_2d( DPU_ADDR_BASE_POOL, test_level, verbose );
    }
    if (test_linear>0) {
        test_linear_1d( DPU_ADDR_BASE_LINEAR, test_level, verbose );
    }

#if defined(COSIM_BFM)
    bfm_close(cid); // mandatory
#elif defined(TRX_AXI)||defined(BFM_AXI)
    if (handle!=NULL) conRelease(handle);
#endif

    return 0;
}

//------------------------------------------------------------------------------
#if defined(TRX_AXI)||defined(BFM_AXI)
int get_confmc( con_Handle_t handle )
{
  struct _usb usb;
  conGetUsbInfo( handle, &usb);
  printf("USB information\n");
  printf("    DevSpeed         =%d%cbps\n", (usb.speed>10000) ? usb.speed/10000
                                                              : usb.speed/10
                                          , (usb.speed>10000) ? 'G' : 'M');
  printf("    BulkMaxPktSizeOut=%d\n", usb.bulk_max_pkt_size_out);
  printf("    BulkMaxPktSizeIn =%d\n", usb.bulk_max_pkt_size_in );
  printf("    IsoMaxPktSizeOut =%d\n", usb.iso_max_pkt_size_out );
  printf("    IsoMaxPktSizeIn  =%d\n", usb.iso_max_pkt_size_in  );
  fflush(stdout);

  con_MasterInfo_t gpif2mst_info;
  if (conGetMasterInfo(handle, &gpif2mst_info)) {
      printf("cannot get gpif2mst info\n");
      return 1;
  }
  printf("gpif2mst information\n");
  printf("         version 0x%08X\n", gpif2mst_info.version);
  printf("         pclk_freq %d-Mhz (%s)\n", gpif2mst_info.clk_mhz
                                             , (gpif2mst_info.clk_inv)
                                             ? "inverted"
                                             : "not-inverted");
  printf("         DepthCu2f=%d, DepthDu2f=%d, DepthDf2u=%d\n"
                               , gpif2mst_info.depth_cmd
                               , gpif2mst_info.depth_u2f
                               , gpif2mst_info.depth_f2u);
  fflush(stdout);

  return 0;
}
#endif

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
        , {"test_pool"          , required_argument, 0, 'C'}
        , {"test_linear"        , required_argument, 0, 'D'}
        , {"test_dconfig"    , required_argument, 0, 'E'}
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
       case 'C': test_pool = atoi(optarg); break;
       case 'D': test_linear = atoi(optarg); break;
       case 'E': test_dconfig = atoi(optarg); break;
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
  fprintf(stderr, "\t-C,--test_pool=1|0            pooling test when 1 (default: %d)\n", test_pool);
  fprintf(stderr, "\t-D,--test_linear=1|0          linear test when 1 (default: %d)\n", test_linear);
  fprintf(stderr, "\t-E,--test_dconfig=1|0      dpu config test when 1 (default: %d)\n", test_dconfig);
  fprintf(stderr, "\t-c,--cid=num                  channel id (default: %d)\n", cid);
  fprintf(stderr, "\t-g,--verbose=num              verbose level  (default: %d)\n", verbose);
  fprintf(stderr, "\t-v,--version                  print version\n");
  fprintf(stderr, "\t-l,--license                  print license message\n");
  fprintf(stderr, "\t-h                            print help message\n");
  fprintf(stderr, "\n");
}

//------------------------------------------------------------------------------
const char license[] =
"Copyright (c) 2021-2025 by Ando Ki (andoki@gmail.com).\n\n\
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
// 2025.01.10: Rewritten
// 2021.08.01: Started by Ando Ki.
//------------------------------------------------------------------------------
