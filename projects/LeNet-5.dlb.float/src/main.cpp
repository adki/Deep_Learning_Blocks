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
#elif defined(TRX_AXI)||defined(BFM_AXI)
#	include "trx_axi_api.h"
#endif
#include "defines.h"
#include "etc.h"
#include "mem_test.h"
#include "get_image.hpp"
#include "softmax.hpp"
#include "lenet5_infer.hpp"

const char program[]="test";
const unsigned int version=0x20210810;

int   mem_test=0;
#if defined(RIGOR)
int   rigor = 1;
#else
int   rigor = 0;
#endif
int   verbose = 0;
int   performance = 0;

int   cid = 0;
#define MAX_IMAGES 128
int   image_num=0;
char *image_file[MAX_IMAGES];

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

//------------------------------------------------------------------------------
int main(int argc, char* argv[])
{
    extern void sig_handle( int );
    extern int  arg_parser( int, char ** );

    if ((signal(SIGINT, sig_handle)==SIG_ERR)
            #ifndef WIN32
            ||(signal(SIGQUIT, sig_handle)==SIG_ERR)
            #endif
            ) {
          myError("signal error\n");
          exit(1);
    }
    
    if (arg_parser(argc, argv)) return 1;

#if defined(COSIM_BFM)
    bfm_set_verbose(verbose); // optional
    bfm_open(cid); // mandatory
    bfm_barrier(cid); // mandatory
#elif defined(TRX_AXI)||defined(BFM_AXI)
    if ((handle=conInit(cid, CON_MODE_CMD, CONAPI_LOG_LEVEL_INFO))==NULL) {
       myError("cannot initialize CON-FMC\n");
       myError("%d %s\n", conGetErrorConapi(), conErrorMsgConapi(conGetErrorConapi()));
       return 0;
    }
#endif

    if (mem_test>0) {
        uint32_t  addr=DPU_ADDR_BASE_MEM;
        uint32_t  depth=4*32;
        test_mem( addr, depth );

        depth=4*32;
        addr=(DPU_ADDR_BASE_MEM+DPU_SIZE_MEM-depth);
        test_mem( addr, depth );
    }

    for (int idx=0; idx<image_num; idx++) {
        TYPE image_scaled_normalized[IMAGE_WIDTH][IMAGE_HEIGHT];
        myInfo("%s\n", image_file[idx]);
        if (get_image<TYPE>((TYPE * const)image_scaled_normalized
                       , image_file[idx]
                       , IMAGE_WIDTH  // see define.h
                       , IMAGE_HEIGHT // see define.h
                       , IMAGE_GREY   // see define.h
                       , rigor
                       , verbose )) {
            continue;
        }

        TYPE results[10];
        lenet5_infer<TYPE>((      TYPE * const)results
                          ,(const TYPE * const)image_scaled_normalized
                          , rigor
                          , verbose
                          , performance );

        double results_softmax[10];
        softmax<TYPE>(results, 10, results_softmax);
        TYPE tmax = results[0];
        int  tmax_ind=0;
        for (int idx=1; idx<10; idx++) {
            if (tmax<results[idx]) {
                tmax = results[idx];
                tmax_ind = idx;
            }
        }
        for (int idx=0; idx<10; idx++) {
            printf("result %01d: %7.2f %7.2f %c\n", idx,
                    (float)results[idx], results_softmax[idx],
                    (idx==tmax_ind) ? '*' : ' ');
        }
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
      myError("cannot get gpif2mst info\n");
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

    for (int idx=0; idx<MAX_IMAGES; idx++) {
        image_file[idx] = NULL;
    }

    struct option longopts[] = {
          {"cid"        , required_argument, 0, 'C'}
        , {"image"      , required_argument, 0, 'I'}
        , {"memtest"    , required_argument, 0, 'T'}
        , {"verbose"    , required_argument, 0, 'g'}
        , {"rigor"      , required_argument, 0, 'r'}
        , {"performance", no_argument      , 0, 'p'}
        , {"version"    , no_argument      , 0, 'v'}
        , {"license"    , no_argument      , 0, 'l'}
        , {"help"       , no_argument      , 0, 'h'}
        , { 0           , 0                , 0,  0 }
    };

    while ((opt=getopt_long(argc, argv, "C:I:T:g:r:pvlh?", longopts, &longidx))!=-1) {
       switch (opt) {
       case 'C': cid = atoi(optarg); break;
       case 'I': if (image_file[image_num]!=NULL) free(image_file[image_num]);
                 image_file[image_num] = (char *)calloc(strlen(optarg)+1, sizeof(char));
                 strcpy(image_file[image_num], optarg);
                 image_num++;
                 break;
       case 'T': mem_test = atoi(optarg); break;
       case 'g': verbose = atoi(optarg); break;
       case 'r': rigor = atoi(optarg); break;
       case 'p': performance = 1; break;
       case 'v': print_version(); exit(0); break;
       case 'l': print_license(); exit(0); break;
       case 'h':
       case '?': help(argc, argv); exit(0); break;
       case  0 : return -1;
                 break;
       default: 
          myError("undefined option: %c\n", optopt);
          help(argc, argv);
          exit(1);
       }
    }

    return 0;
}

//------------------------------------------------------------------------------
void help(int argc, char **argv)
{
  printf("[Usage] %s [options]\n", argv[0]);
  printf("\t-C,--cid=num       channel id (default: %d)\n", cid);
  printf("\t-I,--image=file    image file\n");
  printf("\t-T,--memtest=level test memory\n");
  printf("\t-g,--verbose=num   verbose level  (default: %d)\n", verbose);
  printf("\t-r,--rigor=num     rigorous check (default: %d)\n", rigor);
  printf("\t-p,--performance   performance check\n");
  printf("\t-v,--version       print version\n");
  printf("\t-l,--license       print license message\n");
  printf("\t-h                 print help message\n");
  printf("\n");
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
