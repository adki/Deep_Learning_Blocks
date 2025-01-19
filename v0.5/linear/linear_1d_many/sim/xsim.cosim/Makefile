#------------------------------------------------------------------
SHELL           = /bin/sh
MAKEFILE        = Makefile
#-------------------------------------------------------------------------------
ifeq ($(MAKECMDGOALS),$(findstring $(MAKECMDGOALS), "" "all" "elab" "compile" "sim"))
    ifndef XILINX_VIVADO
       $(error XILINX_VIVADO environment variable not defined)
    endif
    export VIVADO         = $(XILINX_VIVADO)/bin/vivado
    export VIVADO_VERSION = $(shell vivado -version | sed -n 1p | cut -d" " -f 2 | cut -c 2-7)
    export VIVADO_VER     = vivado.$(VIVADO_VERSION)
    ifndef COSIM_HOME
       $(error COSIM_HOME environment variable not defined.)
    endif
    PLATFORM  = $(shell uname -s | tr '[:upper:]' '[:lower:]')
    MACHINE   = $(shell uname -m)
    export COSIM_LIB      = cosim_dpi_bfm.so
    export DIR_COSIM_ROOT = $(COSIM_HOME)/lib/xsim/$(PLATFORM)_$(MACHINE)
    export DIR_DPI_BFM    = $(COSIM_HOME)/include/verilog
    export DPI_BFM        = $(DIR_DPI_BFM)/cosim_bfm_axi_dpi.sv
endif

#-------------------------------------------------------------------------------
export GUI         ?= 0
export TOP          = top
export DIR_RTL      = ../../rtl/verilog
export DIR_MAC_TREE = ../../../../mac/tree_mac/rtl/verilog
export DIR_BENCH    = ../../bench/verilog
export DATA_TYPE   ?= FLOATING_POINT
                     # FLOATING_POINT may cause mis-match due to floating-point rounding
export DATA_WIDTH          ?= 32
export AMBA_AXI_WIDTH_ADDR ?= 32
export AMBA_AXI_WIDTH_DATA ?= 32
export OPTIONS_SIM    ?= -testplusarg VERBOSE=1
ifeq ("$(DATA_TYPE)","FLOATING_POINT")
    $(warning DATA_TYPE FLOATING_POINT causes mis-match since RTL testbench does not deal with floating-point.)
    export DIR_MAC       = ../../../../mac/mac_float/rtl/verilog
    export DIR_MAC_CORE  = ../../../../mac/mac_float/core/z7/$(VIVADO_VER)
    export OPTIONS_ELAB  = -include $(DIR_MAC_CORE)
    export OPTIONS_ELAB += -L secureip -L unisims_ver -L unimacro_ver
else
    export DIR_MAC       = ../../../../mac/mac_integer/rtl/verilog
    export OPTIONS_ELAB  = 
endif
    export OPTIONS_ELAB += -include $(DIR_DPI_BFM)

#-------------------------------------------------------------------------------
all: elab sim

pre:
	/bin/cat ../../bench/verilog/defines_system_source.v\
		| /bin/sed 's|$$DATA_TYPE\$$|'"${DATA_TYPE}"'|g'\
		| /bin/sed 's|$$DATA_WIDTH\$$|'"${DATA_WIDTH}"'|g'\
		| /bin/sed 's|$$AMBA_AXI_WIDTH_ADDR\$$|'"${AMBA_AXI_WIDTH_ADDR}"'|g'\
		| /bin/sed 's|$$AMBA_AXI_WIDTH_DATA\$$|'"${AMBA_AXI_WIDTH_DATA}"'|g'\
		> ../../bench/verilog/defines_system.v

elab compile: pre
ifeq ("$(DATA_TYPE)","FLOATING_POINT")
	xelab -prj xsim.prj -debug typical $(OPTIONS_ELAB)\
		-sv_root $(DIR_COSIM_ROOT) -sv_lib $(COSIM_LIB)\
		${TOP} glbl -s ${TOP}_snapshot
else
	xelab -prj xsim.prj -debug typical $(OPTIONS_ELAB)\
		-sv_root $(DIR_COSIM_ROOT) -sv_lib $(COSIM_LIB)\
		${TOP} -s ${TOP}_snapshot
endif

sim:
	if [ "$(GUI)" = "0" ]; then\
		xsim ${TOP}_snapshot -t xsim_run.tcl $(OPTIONS_SIM);\
	else\
		xsim ${TOP}_snapshot -gui -t xsim_run.tcl $(OPTIONS_SIM);\
	fi
	@if [ -f xsim.log ]; then\
		if grep -q ERROR xsim.log; then\
			echo "\033[0;31mSimulation result ERROR.\033[0m";\
		else\
			echo "\033[0;33mOK = NO ERROR.\033[0m";\
		fi;\
	fi

clean:
	/bin/rm -f  ${TOP}.wdb
	/bin/rm -f  ${TOP}_snapshot.wdb
	/bin/rm -f  ${TOP}_snapshot
	/bin/rm -f  wave.vcd
	/bin/rm -f  webtalk_*.backup.jou
	/bin/rm -f  webtalk_*.backup.log
	/bin/rm -f  webtalk.jou
	/bin/rm -f  webtalk.log
	/bin/rm -f  xelab.log
	/bin/rm -f  xelab.pb
	/bin/rm -fr .Xil/
	/bin/rm -f  xsim_*.backup.jou
	/bin/rm -f  xsim_*.backup.log
	/bin/rm -fr xsim.dir/
	/bin/rm -f  xsim.jou
	/bin/rm -f  xsim.log
	/bin/rm -f  xvlog.log
	/bin/rm -f  xvlog.pb

cleanup clobber: clean

cleanupall distclean: cleanup
