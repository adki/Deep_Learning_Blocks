#------------------------------------------------------------------
# VIVADO Batch Mode 
#------------------------------------------------------------------
# Copyright (c) 2018 by Future Design Systems
# All right reserved.
#------------------------------------------------------------------
SHELL		= /bin/sh
MAKEFILE	= Makefile
#-------------------------------------------------------------------------------
ifeq ($(MAKECMDGOALS),$(findstring $(MAKECMDGOALS), "" "all" "elab" "sim"))
    ifndef XILINX_VIVADO
       $(error XILINX_VIVADO environment variable not defined)
    else
        export VIVADO         = $(XILINX_VIVADO)/bin/vivado
        export VIVADO_VERSION = $(shell vivado -version | sed -n 1p | cut -d" " -f 2 | cut -c 2-7)
        export VIVADO_VER     = vivado.$(VIVADO_VERSION)
    endif
endif

#------------------------------------------------------------------
export PROJECT_DIR   = project_1
export PROJECT_NAME  = project_1
export WORK          = work
export FPGA_TYPE     = z7
export DEVICE        = xc7z020clg484-1
export MODULE        = linear_1d
export RIGOR         = 1
export SYNTH_ONLY    = 1
export GUI          ?= 1
#------------------------------------------------------------------
export DATA_TYPE  ?= INTEGER
#export DATA_TYPE  ?= FLOATING_POINT
ifeq ($(DATA_TYPE),$(findstring $(DATA_TYPE), "INTEGER"))
export DIR_MAC      = ../../../../mac/mac_integer
else ifeq ($(DATA_TYPE),$(findstring $(DATA_TYPE), "FLOATING_POINT"))
export DIR_MAC      = ../../../../mac/mac_float
export DIR_MAC_CORE = ../../../../mac/mac_float/core/$(FPGA_TYPE)/$(VIVADO_VER)
endif
export DIR_MAC_TREE = ../../../../mac/tree_mac
#------------------------------------------------------------------
export SOURCE        =vivado_syn.tcl
#------------------------------------------------------------------
all: replace vivado

replace:
	/bin/cat syn_define_save.v | /bin/sed 's|TYPE_DATA|'"\"${DATA_TYPE}\""'|g' > syn_define.v


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
	/bin/rm -f syn_define.v
	for D in $(DIRS); do\
		if [ -f $$D/Makefile ] ; then \
			echo "make -C $$D -s $@";\
			make -C $$D -s $@;\
		fi;\
	done

cleanupall: cleanup
	-@/bin/rm -f  $(MODULE).xdc
	-@/bin/rm -rf $(MODULE).dcp
	-@/bin/rm -rf $(MODULE).edn
	-@/bin/rm -rf project_*
	for D in $(DIRS); do\
		if [ -f $$D/Makefile ] ; then \
			echo "make -C $$D -s $@";\
			make -C $$D -s $@;\
		fi;\
	done
#------------------------------------------------------------------
