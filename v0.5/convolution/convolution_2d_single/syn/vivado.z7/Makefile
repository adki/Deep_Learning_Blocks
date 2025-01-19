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

export MODULE        = convolution_2d
export DATA_TYPE    ?= FLOATING_POINT
#export DATA_TYPE    ?= INTEGER

export DIR_RTL       = ../../rtl/verilog
ifeq ("$(DATA_TYPE)","FLOATING_POINT")
    export DIR_MAC       = ../../../../mac/mac_float/rtl/verilog
    export DIR_MAC_CORES = ../../../../mac/mac_float/core/${FPGA_TYPE}/${VIVADO_VER}
else ifeq ("$(DATA_TYPE)","INTEGER")
    export DIR_MAC       = ../../../../mac/mac_integer/rtl/verilog
else
    $(error "$(DATA_TYPE) not konwn")
endif
#------------------------------------------------------------------
export SOURCE        =vivado_syn.tcl
#------------------------------------------------------------------
all: vivado

vivado:
	if [ "$(GUI)" = "1" ]; then\
		$(VIVADO) -mode gui -source $(SOURCE);\
	else\
		$(VIVADO) -mode batch -source $(SOURCE);\
	fi

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
	/bin/rm -rf $(MODULE).dcp
	/bin/rm -rf $(MODULE).edn
	/bin/rm -rf project_*
	/bin/rm -f  convolution_2d_stub.v
	/bin/rm -f  convolution_2d.vm
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
