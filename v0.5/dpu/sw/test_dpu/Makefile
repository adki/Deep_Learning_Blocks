#-------------------------------------------------------------------------------
# Copyright (c) 2025 by Ando Ki.
# All rights are reserved by Ando Ki.
#-------------------------------------------------------------------------------
SHELL    = /bin/sh
MAKEFILE = Makefile
#-------------------------------------------------------------------------------
# COSIM_BFM  TRX_AXI BFM_AXI
RUN_TYPE   ?= COSIM_BFM
#RUN_TYPE   ?= TRX_AXI
#-------------------------------------------------------------------------------
ifeq ($(MAKECMDGOALS),$(findstring $(MAKECMDGOALS), pre all hw sw cosim run_dpi dpi_run))
    ifndef DLB_HOME
       $(error "DLB_HOME" environment variable not defined.)
    endif
    export DIR_DLB_INC  := $(DLB_HOME)/include
    export DIR_DLB_LIB  := $(DLB_HOME)/lib
    export DIR_DPU_HW   := $(DLB_HOME)/dpu
    ifndef DLR_HOME
       $(error "DLR_HOME" environment variable not defined.)
    endif
    export DIR_DLR_INC  := $(DLR_HOME)/include
    export DIR_DLR_LIB  := $(DLR_HOME)/lib
    ifeq ("$(wildcard $(DIR_DLR_INC))", "")
             $(error $(DIR_DLR_INC) not found.)
    endif
    ifeq ("$(wildcard $(DIR_DLR_LIB))", "")
             $(error $(DIR_DLR_LIB) not found.)
    endif
    ifeq ($(RUN_TYPE),COSIM_BFM)
        ifndef COSIM_HOME
           $(error "COSIM_HOME" environment variable not defined.)
        endif
        PLATFORM  := $(shell uname -s | tr '[:upper:]' '[:lower:]')
        MACHINE   := $(shell uname -m)
        export DIR_COSIM_INC  := $(COSIM_HOME)/include
        export SIMULATOR      ?= xsim
        export DIR_COSIM_LIB  := $(COSIM_HOME)/lib/$(SIMULATOR)/$(PLATFORM)_$(MACHINE)
        ifeq ("$(wildcard $(DIR_COSIM_INC))", "")
             $(error $(DIR_COSIM_INC) not found.)
        endif
        ifeq ("$(wildcard $(DIR_COSIM_LIB))", "")
             $(error $(DIR_COSIM_LIB) not found.)
        endif
        ifeq ($(SIMULATOR),xsim)
            ifndef XILINX_VIVADO
               $(error "XILINX_VIVADO" environment variable not defined.)
            endif
        endif
        export DIR_SIM_HW := ../../sim/$(SIMULATOR).cosim
    else ifeq ($(RUN_TYPE),TRX_AXI)
        ifndef CONFMC_HOME
           $(error "CONFMC_HOME" environment variable not defined.)
        endif
        PLATFORM  := $(shell uname -s | tr '[:upper:]' '[:lower:]')
        MACHINE   := $(shell uname -m)
        export DIR_CONFMC_INC  := $(CONFMC_HOME)/include
        export DIR_CONFMC_LIB  := $(CONFMC_HOME)/lib/$(PLATFORM)_$(MACHINE)
        export DIR_CONFMC_BFM  := $(CONFMC_HOME)/hwlib/trx_axi/api/c
    endif
    export DIR_DPU_CONFIG := $(DLB_HOME)/dpu/api/c
    export DIR_CONV_2D    := $(DLB_HOME)/convolution/convolution_2d_single/api/c
    export DIR_POOLING_2D := $(DLB_HOME)/pooling/pooling_2d_single/api/c
    export DIR_LINEAR_1D  := $(DLB_HOME)/linear/linear_1d_many/api/c
endif
#-------------------------------------------------------------------------------
DATA_TYPE  ?= float
#DATA_TYPE  ?= int32_t
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

export AMBA_AXI_WIDTH_ADDR_VERILOG ?= 32
export AMBA_AXI_WIDTH_DATA_VERILOG ?= 32

#-------------------------------------------------------------------------------
TEST_LEVEL   ?= 0
TEST_OPTIONS ?= --test_level=$(TEST_LEVEL)\
                --test_mem=1\
                --test_dconfig=1\
                --test_conv=1\
                --test_pool=1\
                --test_linear=1
#-------------------------------------------------------------------------------
LIB_BFM       = cosim_bfm
LIB_DLR       = dlr
LIB_CONFMC    = conapi
#-------------------------------------------------------------------------------
TARGET   = test
CPP_SRCS = main.cpp mem_test.cpp\
           test_dpu_config.cpp test_convolution.cpp test_pooling.cpp test_linear.cpp
C_SRCS   = dpu_config.c\
           convolution_2d_one_core.c\
           pooling_2d_one_core.c\
           linear_1d_one_core.c
OBJS     = $(CPP_SRCS:.cpp=.o) $(C_SRCS:.c=.o)
#-------------------------------------------------------------------------------
vpath %.h    src:$(DIR_COSIM_INC):$(DIR_DPU_CONFIG):$(DIR_CONV_2D):$(DIR_POOLING_2D):$(DIR_LINEAR_1D):$(DIR_DLR_INC):$(DIR_CONFMC_BFM)
vpath %.c    src:$(DIR_COSIM_INC):$(DIR_DPU_CONFIG):$(DIR_CONV_2D):$(DIR_POOLING_2D):$(DIR_LINEAR_1D):$(DIR_DLR_INC):$(DIR_CONFMC_BFM)
vpath %.hpp  src:$(DIR_COSIM_INC):$(DIR_DPU_CONFIG):$(DIR_CONV_2D):$(DIR_POOLING_2D):$(DIR_LINEAR_1D):$(DIR_DLR_INC)
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
                       -I$(DIR_DPU_CONFIG)\
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
all:

.PHONY: sw
sw: pre $(TARGET)

$(TARGET): $(addprefix $(OBJECTDIR)/,$(OBJS))
	echo $(addprefix $(OBJECTDIR)/,$(OBJS))
	/bin/rm -f compile.log
	$(CPP) -o $(TARGET) $(LDFLAGS) $(addprefix $(OBJECTDIR)/,$(OBJS))\
		$(LDLIBS) 2>&1 | tee compile.log

pre: $(DIR_DPU_HW)/bench/verilog/defines_system.v
	@if [ -f compile.log ]; then /bin/rm -f compile.log; fi
	@if [ -f $(DIR_DPU_HW)/bench/verilog/defines_system_source.v ]; then\
		echo "#ifdef __cplusplus" >  src/defines_dpu.h;\
		echo "extern \"C\" {"     >> src/defines_dpu.h;\
		echo "#endif"             >> src/defines_dpu.h;\
		sed -e 's/`define/#define/'\
			-e 's/`if/#if/'\
			-e 's/`endif/#endif/'\
			-e 's/\x27h/0x/g'\
			-e 's/`//g'\
			$(DIR_DPU_HW)/bench/verilog/defines_system.v >>\
				src/defines_dpu.h;\
		echo "#ifdef __cplusplus" >> src/defines_dpu.h;\
		echo "}"                  >> src/defines_dpu.h;\
		echo "#endif"             >> src/defines_dpu.h;\
	else\
		echo "$(DIR_DPU_HW)/bench/verilog/defines_system_source.v not found.";\
		exit 1;\
	fi

.PHONY: $(DIR_DPU_HW)/bench/verilog/defines_system.v
$(DIR_DPU_HW)/bench/verilog/defines_system.v: $(DIR_DPU_HW)/bench/verilog/defines_system_source.v
ifeq ("$(wildcard $(DIR_SIM_HW))", "")
	/bin/cat $(DIR_DPU_HW)/bench/verilog/defines_system_source.v\
		| /bin/sed 's|$$DATA_TYPE\$$|'"${DATA_TYPE}"'|g'\
		| /bin/sed 's|$$DATA_WIDTH\$$|'"${DATA_WIDTH}"'|g'\
		| /bin/sed 's|$$AMBA_AXI_WIDTH_ADDR\$$|'"${AMBA_AXI_WIDTH_ADDR}"'|g'\
		| /bin/sed 's|$$AMBA_AXI_WIDTH_DATA\$$|'"${AMBA_AXI_WIDTH_DATA}"'|g'\
		> $(DIR_DPU_HW)/bench/verilog/defines_system.v
else
	@echo "Rebuild $(DIR_DPU_HW)/bench/verilog/defines_system.v"
	@echo "cd ${DIR_SIM_HW}; make pre"
	make -C ${DIR_SIM_HW} pre\
		DATA_TYPE=\"${DATA_TYPE_VERILOG}\" DATA_WIDTH=${DATA_WIDTH_VERILOG}\
		AMBA_AXI_WIDTH_ADDR=${AMBA_AXI_WIDTH_ADDR_VERILOG}\
		AMBA_AXI_WIDTH_DATA=${AMBA_AXI_WIDTH_DATA_VERILOG}
endif

# to run with CON-FMC
.PHONY: sw
run:
	/bin/rm -f run.log
	./$(TARGET) --cid=0 --verbose=1 $(TEST_OPTIONS) 2>&1 | tee run.log

# to build HW for HW-SW cosimulation
.PHONY: hw
hw:
	make -C ${DIR_SIM_HW} compile\
		DATA_TYPE=${DATA_TYPE_VERILOG} DATA_WIDTH=${DATA_WIDTH_VERILOG}\
		AMBA_AXI_WIDTH_ADDR=${AMBA_AXI_WIDTH_ADDR_VERILOG}\
		AMBA_AXI_WIDTH_DATA=${AMBA_AXI_WIDTH_DATA_VERILOG}

# to run HW for HW-SW cosimulation
.PHONY: cosim
cosim run_dpi dpi_run:
	@if [ ! -z "`(ipcs -q | grep "^0x" | cut -d' ' -f 2) 2>/dev/null`" ]; then\
		echo "IPC message queue is still working. Use \"$$ ipcs -q\" and \"$$ ipcrm -q mid.\"";\
	fi
	@if [ -z "`which xelab 2>/dev/null`" ]; then\
		echo "xelab not found."; exit 1;\
	fi
	if [ ! -f $(TARGET) ]; then make; fi
	gnome-terminal --window -- bash -c "cd ${DIR_SIM_HW};\
			make sim DATA_TYPE=\"${DATA_TYPE_VERILOG}\"; bash"
	@if [ -f run.log ]; then /bin/rm -f run.log; fi
	make TEST_OPTIONS="$(TEST_OPTIONS)" run 2>&1 | tee run.log
	@if [ -f run.log ]; then\
		if grep -q ERROR run.log; then\
			echo "\033[0;31mResult ERROR.\033[0m";\
		else\
			echo "\033[0;33mOK = NO ERROR.\033[0m";\
		fi;\
	fi
ifeq ($(DATA_TYPE),float)
	$(info "Rounding error can be found due to floating-point rounding.")
endif

#-------------------------------------------------------------------------------
main.o: cosim_bfm_api.h\
        convolution_2d_one.hpp\
        convolution_2d.hpp\
        pooling_2d_one.hpp\
        pooling_2d_max.hpp\
        linear_1d_one.hpp\
        linear_1d.hpp\
        mover_2d_one.hpp
convolution_2d_one_core.o: convolution_2d_one_core.c convolution_2d_one_core.h
pooling_2d_one_core.o: pooling_2d_one_core.c pooling_2d_one_core.h
linear_1d_one_core.o: linear_1d_one_core.c linear_1d_one_core.h
mover_2d_one_core.o: mover_2d_one_core.c mover_2d_one_core.h
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

.PHONY: cleanupall distclean
cleanupall distclean: cleanup

#----------------------------------------------------------------------------
# Revision history
#
# 2025.01.10: Started by Ando Ki (andoki@gmail.com)
#----------------------------------------------------------------------------
