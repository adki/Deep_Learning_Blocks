SHELL    = /bin/sh
MAKEFILE = Makefile

ifeq ($(MAKECMDGOALS),$(findstring $(MAKECMDGOALS), "" "all" "compile" "elab" "run" "sim"))
    ifndef XILINX_VIVADO
       $(warning XILINX_VIVADO environment variable not defined)
    else
       VIVADO_VERSION = $(shell vivado -version | sed -n 1p | cut -d" " -f 2 | cut -c 2-)
       export VIVADO_VER=vivado.$(VIVADO_VERSION)
       export FPGA=z7
    endif
    ifndef COSIM_HOME
       $(error COSIM_HOME environment variable not defined.)
    else
        PLATFORM  = $(shell uname -s | tr '[:upper:]' '[:lower:]')
        MACHINE   = $(shell uname -m)
        export COSIM_LIB      = cosim_dpi_bfm.so
        export DIR_COSIM_ROOT = $(COSIM_HOME)/lib/xsim/$(PLATFORM)_$(MACHINE)
        export DIR_DPI_BFM    = $(COSIM_HOME)/include/verilog
        export DPI_BFM        = $(DIR_DPI_BFM)/cosim_bfm_axi_dpi.sv
    endif
endif

# "INTEGER", "FLOATING_POINT", "FIXED_POINT"
export DATA_TYPE  ?= INTEGER
export DATA_WIDTH ?= 32
ifeq ($(DATA_TYPE),INTEGER)
    export MAC_DIR = mac_integer
else ifeq ($(DATA_TYPE),FLOATING_POINT)
    export MAC_DIR = mac_float
else ifeq ($(DATA_TYPE),FIXED_POINT)
    export MAC_DIR = mac_fixed
else
    export MAC_DIR = mac_integer
endif
export AMBA_AXI_WIDTH_ADDR ?= 32
export AMBA_AXI_WIDTH_DATA ?= 32

export GUI        ?= 0
export OPTIONS    ?=

all:

pre:
	/bin/cat ../../bench/verilog/defines_system_source.v\
		| /bin/sed 's|$$DATA_TYPE\$$|'"${DATA_TYPE}"'|g'\
		| /bin/sed 's|$$DATA_WIDTH\$$|'"${DATA_WIDTH}"'|g'\
		| /bin/sed 's|$$AMBA_AXI_WIDTH_ADDR\$$|'"${AMBA_AXI_WIDTH_ADDR}"'|g'\
		| /bin/sed 's|$$AMBA_AXI_WIDTH_DATA\$$|'"${AMBA_AXI_WIDTH_DATA}"'|g'\
		> ../../bench/verilog/defines_system.v

elab compile: pre
	xelab -prj xsim.prj -debug typical\
		-sv_root $(DIR_COSIM_ROOT) -sv_lib $(COSIM_LIB)\
		-L secureip -L unisims_ver -L unimacro_ver\
		top glbl -s top

run sim:
	@if [ "$(GUI)" = "1" ]; then\
		xsim top -gui -t xsim_run.tcl $(OPTIONS);\
	else\
		xsim top -t xsim_run.tcl $(OPTIONS);\
	fi

clean:
	/bin/rm -f  top.wdb
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

cleanupall disclean: cleanup
