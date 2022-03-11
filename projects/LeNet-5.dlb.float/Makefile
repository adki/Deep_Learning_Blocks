#-------------------------------------------------------------------------------
# Copyright (c) 2021 by Ando Ki.
# All rights are reserved by Ando Ki.
#-------------------------------------------------------------------------------
SHELL    = /bin/sh
MAKEFILE = Makefile
#-------------------------------------------------------------------------------
# COSIM_BFM  TRX_AXI BFM_AXI
RUN_TYPE   ?= COSIM_BFM
#RUN_TYPE   ?= TRX_AXI
#-------------------------------------------------------------------------------
ifeq ($(MAKECMDGOALS),$(findstring $(MAKECMDGOALS), all run run_all run_dpi dpi_run))
    ifndef DLR_HOME
       $(error "DLR_HOME" environment variable not defined.)
    else
        export DIR_DLR_ROOT := $(DLR_HOME)
        export DIR_DLR_INC  := $(DIR_DLR_ROOT)/include
        export DIR_DLR_LIB  := $(DIR_DLR_ROOT)/lib
        ifeq ("$(wildcard $(DIR_DLR_INC))", "")
             $(error $(DIR_DLR_INC) not found.)
        endif
        ifeq ("$(wildcard $(DIR_DLR_LIB))", "")
             $(error $(DIR_DLR_LIB) not found.)
        endif
    endif
    ifeq ($(RUN_TYPE),COSIM_BFM)
        ifndef COSIM_HOME
           $(error "COSIM_HOME" environment variable not defined.)
        else
            PLATFORM  := $(shell uname -s | tr '[:upper:]' '[:lower:]')
            MACHINE   := $(shell uname -m)
            export DIR_COSIM_ROOT := $(COSIM_HOME)
            export DIR_COSIM_INC  := $(DIR_COSIM_ROOT)/include
            export SIMULATOR      ?= xsim
            export DIR_COSIM_LIB  := $(DIR_COSIM_ROOT)/lib/$(SIMULATOR)/$(PLATFORM)_$(MACHINE)
            ifeq ("$(wildcard $(DIR_COSIM_INC))", "")
                 $(error $(DIR_COSIM_INC) not found.)
            endif
            ifeq ("$(wildcard $(DIR_COSIM_LIB))", "")
                 $(error $(DIR_COSIM_LIB) not found.)
            endif
            endif
        ifndef XILINX_VIVADO
           $(error "XILINX_VIVADO" environment variable not defined.)
        endif
    else ifeq ($(RUN_TYPE),TRX_AXI)
        ifndef CONFMC_HOME
           $(error "CONFMC_HOME" environment variable not defined.)
        else
            PLATFORM  := $(shell uname -s | tr '[:upper:]' '[:lower:]')
            MACHINE   := $(shell uname -m)
            export DIR_CONFMC_ROOT := $(CONFMC_HOME)
            export DIR_CONFMC_INC  := $(DIR_CONFMC_ROOT)/include
            export DIR_CONFMC_LIB  := $(DIR_CONFMC_ROOT)/lib/$(PLATFORM)_$(MACHINE)
            export DIR_CONFMC_BFM  := $(DIR_CONFMC_ROOT)/hwlib/trx_axi/api/c
        endif
    endif
    ifndef DLB_HOME
        $(warning "DLB_HOME" environment variable not defined.)
        export DLB_HOME       := ../..
        export DIR_DLB_ROOT   := $(DLB_HOME)
    endif
    export DIR_DLB_ROOT   := $(DLB_HOME)
    export DIR_CONV_2D    := $(DLB_HOME)/convolution/convolution_2d_single/api/c
    export DIR_POOLING_2D := $(DLB_HOME)/pooling/pooling_2d_single/api/c
    export DIR_LINEAR_1D  := $(DLB_HOME)/linear/linear_1d_many/api/c
    export DIR_DPU_HW     := $(DLB_HOME)/dpu/hw
    export DIR_LENET5     := ../LeNet-5.pytorch
endif
#-------------------------------------------------------------------------------
# "INTEGER", "FLOATING_POINT", "FIXED_POINT"
DATA_TYPE  ?= float
ifeq ($(DATA_TYPE),int32_t)
    DATA_TYPE_VERILOG = INTEGER
    DATA_WIDTH_VERILOG = 32
else ifeq ($(DATA_TYPE),int16_t)
    DATA_TYPE_VERILOG = INTEGER
    DATA_WIDTH_VERILOG = 16
else ifeq ($(DATA_TYPE),int8_t)
    DATA_TYPE_VERILOG = INTEGER
    DATA_WIDTH_VERILOG = 8
else ifeq ($(DATA_TYPE),float)
    DATA_TYPE_VERILOG = FLOATING_POINT
    DATA_WIDTH_VERILOG = 32
else ifeq ($(DATA_TYPE),half)
    DATA_TYPE_VERILOG = FLOATING_POINT
    DATA_WIDTH_VERILOG = 16
else
    DATA_TYPE_VERILOG = INTEGER
    DATA_WIDTH_VERILOG = 32
endif

#-------------------------------------------------------------------------------
LIB_BFM     = cosim_bfm
LIB_DLR     = dlr
LIB_CONFMC  = conapi
#-------------------------------------------------------------------------------
TARGET   = test
CPP_SRCS = main.cpp
C_SRCS   = etc.c mem_test.c preprocess.c\
           convolution_2d_one_core.c\
           pooling_2d_one_core.c\
           linear_1d_one_core.c
OBJS     = $(CPP_SRCS:.cpp=.o) $(C_SRCS:.c=.o)
#-------------------------------------------------------------------------------
vpath %.h    src:$(DIR_COSIM_INC):$(DIR_CONV_2D):$(DIR_POOLING_2D):$(DIR_LINEAR_1D):$(DIR_DLR_INC):$(DIR_CONFMC_BFM)
vpath %.c    src:$(DIR_COSIM_INC):$(DIR_CONV_2D):$(DIR_POOLING_2D):$(DIR_LINEAR_1D):$(DIR_DLR_INC):$(DIR_CONFMC_BFM)
vpath %.hpp  src:$(DIR_COSIM_INC):$(DIR_CONV_2D):$(DIR_POOLING_2D):$(DIR_LINEAR_1D):$(DIR_DLR_INC)
vpath %.cpp  src
#-------------------------------------------------------------------------------
CPP        = g++
CC         = gcc
CC_VERSION = $(shell gcc -dumpversion)
#-------------------------------------------------------------------------------
PLATFORM  = $(shell uname -s | tr '[:upper:]' '[:lower:]')
MACH      = $(shell uname -m)
C_USER_DEFS   = -DDATA_TYPE=${DATA_TYPE} -D$(RUN_TYPE)
C_USER_DEFS  += -DRIGOR #-DDEBUG
C_USER_FLAGS  =
ifeq ($(PLATFORM),cygwin)
	C_USER_DEFS  += -DWIN32 -mno-cygwin
	C_USER_FLAGS +=
else ifeq ($(PLATFORM),mingw)
	C_USER_DEFS  += -DWIN32
	C_USER_FLAGS +=
else ifeq ($(PLATFORM),linux)
	C_USER_DEFS  +=
        ifeq ($(MACH),x86_64)
	    C_USER_FLAGS += -m64 -fPIC
        else
	    C_USER_FLAGS += -m32 -fPIC
        endif
else
	C_USER_DEFS  +=
	C_USER_FLAGS +=
endif
C_CFLAGS = -g -O0 -Werror -std=c++11 $(C_USER_DEFS) $(C_USER_FLAGS)
C_LFLAGS = -O0 $(C_USER_DEFS) $(C_USER_FLAGS)

CFLAGS   = $(C_CFLAGS) -Isrc\
                       -I$(DIR_CONV_2D)\
                       -I$(DIR_POOLING_2D)\
                       -I$(DIR_LINEAR_1D)\
                       -I$(DIR_DLR_INC)
LDFLAGS  = $(C_LFLAGS)
LDLIBS   = -Wl,-Bstatic -L$(DIR_DLR_LIB) -l$(LIB_DLR)\
                        -L$(DIR_COSIM_LIB) -l$(LIB_BFM) -Wl,-Bdynamic

ifeq ($(RUN_TYPE),COSIM_BFM)
CFLAGS   += -I$(DIR_COSIM_INC)
LDLIBS   += -Wl,-Bstatic -L$(DIR_COSIM_LIB) -l$(LIB_BFM) -Wl,-Bdynamic
else ifeq ($(RUN_TYPE),TRX_AXI)
C_SRCS   += trx_axi_api.c
CFLAGS   += -I$(DIR_CONFMC_INC) -I$(DIR_CONFMC_BFM)
LDLIBS   += -L$(DIR_CONFMC_LIB) -l$(LIB_CONFMC) -lusb-1.0
endif

#------------------------------------------------------------------------
OBJECTDIR := obj
DUMMY     := $(shell [ -d $(OBJECTDIR) ] || mkdir $(OBJECTDIR) )
$(OBJECTDIR)/%.o: %.c
	$(CPP) -c $(CFLAGS) $< -o $@ 2>&1 | tee -a compile.log
$(OBJECTDIR)/%.o: %.cpp
	$(CPP) -c $(CFLAGS) $< -o $@ 2>&1 | tee -a compile.log
#------------------------------------------------------------------------
.PHONY: all
all: pre $(TARGET)

$(TARGET): $(addprefix $(OBJECTDIR)/,$(OBJS))
	$(CPP) -o $(TARGET) $(LDFLAGS) $(addprefix $(OBJECTDIR)/,$(OBJS))\
		$(LDLIBS)

pre:
	@if [ -f $(DIR_DPU_HW)/design/verilog/defines_system.v ]; then\
		echo "// derived from $(DIR_DPU_HW)/design/verilog/defines_system.v" > src/defines_dpu.h;\
		echo "#ifdef __cplusplus" >> src/defines_dpu.h;\
		echo "extern \"C\" {"     >> src/defines_dpu.h;\
		echo "#endif"             >> src/defines_dpu.h;\
		sed -e 's/`define/#define/'\
			-e 's/`if/#if/'\
			-e 's/`endif/#endif/'\
			-e 's/\x27h/0x/g'\
			-e 's/`//g'\
			$(DIR_DPU_HW)/design/verilog/defines_system.v >>\
				src/defines_dpu.h;\
		echo "#ifdef __cplusplus" >> src/defines_dpu.h;\
		echo "}"                  >> src/defines_dpu.h;\
		echo "#endif"             >> src/defines_dpu.h;\
	else\
		echo "$(DIR_DPU_HW)/design/verilog/defines_system.v not found.";\
		exit 1;\
	fi
	@if [ -f $(DIR_LENET5)/lenet5_params.h ]; then\
		cp $(DIR_LENET5)/lenet5_params.h src;\
		sed -i '1 i // copied from $(DIR_LENET5)/lenet5_params.h' src/lenet5_params.h;\
	else\
		echo "$(DIR_LENET5)/lenet5_params.h not found.";\
		exit 1;\
	fi
	@if [ -f compile.log ]; then /bin/rm -f compile.log; fi


#-------------------------------------------------------------------------------
# $(DIR_LENET5)/samples/2.png
# $(DIR_LENET5)/samples/3.png
# $(DIR_LENET5)/samples/4.png
# $(DIR_LENET5)/samples/5.png
# $(DIR_LENET5)/samples/7.png
# $(DIR_LENET5)/samples/9.png
# $(DIR_LENET5)/samples/t_00_c4.png
# $(DIR_LENET5)/samples/t_01_c7.png
# $(DIR_LENET5)/samples/t_02_c0.png
# $(DIR_LENET5)/samples/t_03_c2.png
# $(DIR_LENET5)/samples/t_04_c3.png
# $(DIR_LENET5)/samples/t_06_c5.png
# $(DIR_LENET5)/samples/t_07_c6.png
IMAGE_FILE ?= $(DIR_LENET5)/samples/2.png
run:
ifeq ($(RUN_TYPE),COSIM_BFM)
	./$(TARGET) --cid=0 --verbose=0 --image=$(IMAGE_FILE)
else ifeq ($(RUN_TYPE),TRX_AXI)
	./$(TARGET) --cid=0 --performance --rigor=1 --verbose=0 --image=$(IMAGE_FILE)
endif

run_all:
	./$(TARGET) --cid=0 --rigor=0 --verbose=0\
			--image=$(DIR_LENET5)/samples/2.png\
			--image=$(DIR_LENET5)/samples/3.png\
			--image=$(DIR_LENET5)/samples/4.png\
			--image=$(DIR_LENET5)/samples/5.png\
			--image=$(DIR_LENET5)/samples/7.png\
			--image=$(DIR_LENET5)/samples/9.png\
			--image=$(DIR_LENET5)/samples/t_00_c4.png\
			--image=$(DIR_LENET5)/samples/t_01_c7.png\
			--image=$(DIR_LENET5)/samples/t_02_c0.png\
			--image=$(DIR_LENET5)/samples/t_03_c2.png\
			--image=$(DIR_LENET5)/samples/t_04_c3.png\
			--image=$(DIR_LENET5)/samples/t_06_c5.png\
			--image=$(DIR_LENET5)/samples/t_07_c6.png\
			2>&1 | tee run.log

run_dpi dpi_run:
	@if [ ! -z "`(ipcs -q | grep "^0x" | cut -d' ' -f 2) 2>/dev/null`" ]; then\
		echo "IPC message queue is still working. Use \"$$ ipcs -q\" and \"$$ ipcrm -q mid.\"";\
	fi
	@if [ -z "`which xelab 2>/dev/null`" ]; then\
		echo "xelab not found."; exit 1;\
	fi
	if [ ! -f $(TARGET) ]; then make; fi
	gnome-terminal --window -- bash -c "cd $(DIR_DPU_HW)/sim/xsim.cosim;\
			make DATA_TYPE=${DATA_TYPE_VERILOG} DATA_WIDTH=${DATA_WIDTH_VERILOG}; bash"
	make IMAGE_FILE=$(IMAGE_FILE) run 2>&1 | tee run.log | sed '/ERROR/q'
#make IMAGE_FILE=$(IMAGE_FILE) run 2>&1 | tee run.log | tail +1f | sed '/ERROR/q'
#make IMAGE_FILE=$(IMAGE_FILE) run 2>&1 | tee run.log

#-------------------------------------------------------------------------------
main.o: cosim_bfm_api.h\
        convolution_2d_one.hpp\
        convolution_2d.hpp\
        pooling_2d_one.hpp\
        pooling_2d_max.hpp\
        linear_1d_one.hpp\
        linear_1d.hpp
convolution_2d_one_core.o: convolution_2d_one_core.c convolution_2d_one_core.h
pooling_2d_one_core.o: pooling_2d_one_core.c pooling_2d_one_core.h
linear_1d_one_core.o: linear_1d_one_core.c linear_1d_one_core.h
#------------------------------------------------------------------------
.PHONY: clean
clean:
	rm -rf $(OBJECTDIR)
	rm -f  *.log
	rm -f  *.o
	rm -f *stackdump
	rm -f *.exe.core
	rm -f compile.log
	rm -f lock_file*.txt

.PHONY: cleanup clobber
cleanup clobber: clean
	rm -f $(TARGET) $(TARGET).exe
	rm -f src/defines_dpu.h
	rm -f src/lenet5_params.h

.PHONY: cleanupall distclean
cleanupall distclean: cleanup

#----------------------------------------------------------------------------
# Revision history
#
# 2021.07.01: Started by Ando Ki (andoki@gmail.com)
#----------------------------------------------------------------------------
