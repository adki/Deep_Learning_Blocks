#------------------------------------------------------------------
# VIVADO Batch Mode 
#------------------------------------------------------------------
# Copyright (c) 2025 by Future Design Systems
# All right reserved.
#------------------------------------------------------------------
SHELL		= /bin/sh
MAKEFILE	= Makefile
#-------------------------------------------------------------------------------
ifeq ($(MAKECMDGOALS),$(findstring $(MAKECMDGOALS), "" "all" "elab" "sim"))
    ifndef XILINX_VIVADO
       $(error XILINX_VIVADO environment variable not defined)
    endif
    export VIVADO         = $(XILINX_VIVADO)/bin/vivado
    export VIVADO_VERSION = $(shell vivado -version | sed -n 1p | cut -d" " -f 2 | cut -c 2-7)
    export VIVADO_VER     = vivado.$(VIVADO_VERSION)
endif

#------------------------------------------------------------------
export PROJECT_DIR   = project_1
export PROJECT_NAME  = project_1
export WORK          = work
export RIGOR         = 1
export SYNTH_ONLY    = 1
export GUI          ?= 1

export BOARD         = zedboard
export PART          = xc7z020-clg484-1
export FPGA_TYPE     = z7

export MODULE               = dpu
export DATA_TYPE           ?= FLOATING_POINT
#export DATA_TYPE           ?= INTEGER
export AMBA_AXI_WIDTH_ADDR ?= 32
export AMBA_AXI_WIDTH_DATA ?= 32

ifeq ("$(DATA_TYPE)","FLOATING_POINT")
    export DIR_MAC       = ../../../mac/mac_float/rtl/verilog
    export DIR_MAC_CORES = ../../../mac/mac_float/core/${FPGA_TYPE}/${VIVADO_VER}
else ifeq ("$(DATA_TYPE)","INTEGER")
    export DIR_MAC       = ../../../mac/mac_integer/rtl/verilog
else
    $(error "$(DATA_TYPE) not konwn")
endif
#------------------------------------------------------------------
export DIR_RTL      = ../../rtl/verilog
export DIR_CONV     = ../../../convolution/convolution_2d_single/rtl/verilog
export DIR_POOL     = ../../../pooling/pooling_2d_single/rtl/verilog
export DIR_LINEAR   = ../../../linear/linear_1d_many/rtl/verilog
export DIR_MOVER    = ../../../mover/mover_2d_single/rtl/verilog
export DIR_MAC_TREE = ../../../mac/tree_mac/rtl/verilog
#------------------------------------------------------------------
export SOURCE        =vivado_syn.tcl
#------------------------------------------------------------------
all: vivado

vivado: pre
	if [ "$(GUI)" = "1" ]; then\
		$(VIVADO) -mode gui -source $(SOURCE);\
	else\
		$(VIVADO) -mode batch -source $(SOURCE);\
	fi

pre:
	/bin/cat ../../bench/verilog/defines_system_source.v\
		| /bin/sed 's|$$DATA_TYPE\$$|'"${DATA_TYPE}"'|g'\
		| /bin/sed 's|$$DATA_WIDTH\$$|'"${DATA_WIDTH}"'|g'\
		| /bin/sed 's|$$AMBA_AXI_WIDTH_ADDR\$$|'"${AMBA_AXI_WIDTH_ADDR}"'|g'\
		| /bin/sed 's|$$AMBA_AXI_WIDTH_DATA\$$|'"${AMBA_AXI_WIDTH_DATA}"'|g'\
		> defines_system.v

#------------------------------------------------------------------
DIRS    = $(subst /,, $(dir $(wildcard */Makefile)))

clean:
	-/bin/rm -f  *.log
	-/bin/rm -fr .cache
	-/bin/rm -rf .Xil
	-/bin/rm -f  *.html
	-/bin/rm -f  *.xml
	-/bin/rm -f  *.jou
	-/bin/rm -f  *.backup*
	-/bin/rm -f  planAhead.*
	-/bin/rm -f  vivado.log
	-/bin/rm -f  vivado_pid*.str  vivado_pid*.debug
	-/bin/rm -f  fsm_encoding.os
	-/bin/rm -f  hw_ila_data_*btree
	-/bin/rm -rf $(WORK)
	for D in $(DIRS); do\
		if [ -f $$D/Makefile ] ; then \
			echo "make -C $$D -s $@";\
			make -C $$D -s $@;\
		fi;\
	done

cleanup clobber: clean
	for D in $(DIRS); do\
		if [ -f $$D/Makefile ] ; then \
			echo "make -C $$D -s $@";\
			make -C $$D -s $@;\
		fi;\
	done

cleanupall distclean: cleanup
	/bin/rm -f  $(MODULE).xdc
	/bin/rm -f  $(MODULE).dcp
	/bin/rm -f  $(MODULE).edn
	/bin/rm -f  $(MODULE)_stub.v  $(MODULE).vm
	/bin/rm -f  defines_system.v
	/bin/rm -rf project_*
	/bin/rm -f  fp32_accumulator_floating_point_v7_1_13.edn
	/bin/rm -f  fp32_accumulator_floating_point_v7_1_13_viv.edn
	/bin/rm -f  fp32_adder_floating_point_v7_1_13.edn
	/bin/rm -f  fp32_adder_floating_point_v7_1_13_viv.edn
	/bin/rm -f  fp32_multiplier_floating_point_v7_1_13.edn
	/bin/rm -f  fp32_multiplier_floating_point_v7_1_13_viv.edn
	for D in $(DIRS); do\
		if [ -f $$D/Makefile ] ; then \
			echo "make -C $$D -s $@";\
			make -C $$D -s $@;\
		fi;\
	done
#------------------------------------------------------------------
