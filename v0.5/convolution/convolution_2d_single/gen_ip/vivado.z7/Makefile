#------------------------------------------------------------------
# VIVADO Batch Mode 
#------------------------------------------------------------------
# Copyright (c) 2025 by Future Design Systems
# All right reserved.
#------------------------------------------------------------------
SHELL		= /bin/sh
MAKEFILE	= Makefile
#------------------------------------------------------------------
ifeq ($(MAKECMDGOALS),$(findstring $(MAKECMDGOALS), "" "all" "vivado"))
    ifndef XILINX_VIVADO
       $(error XILINX_VIVADO environment variable not defined)
    endif
    export VIVADO         = $(XILINX_VIVADO)/bin/vivado
    export VIVADO_VERSION = $(shell vivado -version | sed -n 1p | cut -d" " -f 2 | cut -c 2-7)
    export VIVADO_VER     = vivado.$(VIVADO_VERSION)
endif
export SOURCE         = vivado_gen_ip.tcl
export WORK           = work
export PART           = xc7z020clg484-1
export FPGA_TYPE      = z7
export MODULE         = convolution_2d

export DATA_TYPE      = FLOATING_POINT
export DIR_SYN        = ../../syn/vivado.${FPGA_TYPE}
export DIR_RTL        = ../../rtl/verilog
export RIGOR          = 1
export GUI            = 1

#------------------------------------------------------------------
ifeq ($(MAKECMDGOALS),$(findstring $(MAKECMDGOALS), "" "all" "vivado"))
EDIF := ../../syn/vivado.z7/$(MODULE).edn
ifneq ("$(wildcard $(EDIF))","")
    RST := $(shell grep DATA_TYPE $(EDIF))
    ifneq ($(findstring $(DATA_TYPE), $(RST)),$(DATA_TYPE))
        $(error "$(DATA_TYPE) not match.")
    endif
else
    $(error "$(EDIF) not found.")
endif
endif

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
	-@/bin/rm -rf .Xil
	-@/bin/rm -f  *.html
	-@/bin/rm -f  *.jou
	-@/bin/rm -f  *.backup*
	-@/bin/rm -f  planAhead.*
	-@/bin/rm -f  vivado.log
	-@/bin/rm -f  vivado_pid*.str  vivado_pid*.debug
	-@/bin/rm -f  fsm_encoding.os
	-@/bin/rm -f  *.log
	-@/bin/rm -f  $(MODULE).ucf
	-@/bin/rm -f  $(MODULE).ut
	-@/bin/rm -f  $(MODULE).tcf
	-@/bin/rm -rf work
	-@/bin/rm -rf sim
	-@/bin/rm -rf $(MODULE).cache
	-@/bin/rm -rf $(MODULE).hw
	-@/bin/rm -rf $(MODULE).ip_user_files
	-@/bin/rm -rf $(MODULE).sim
	-@/bin/rm -rf $(MODULE).srcs

cleanup clobber: clean

cleanupall distclean: cleanup
	-@/bin/rm -f  component.xml
	-@/bin/rm -f  $(MODULE).xpr
	-@/bin/rm -rf src
	-@/bin/rm -rf xgui
