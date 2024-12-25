SHELL    = /bin/sh
MAKEFILE = Makefile

ifeq ($(MAKECMDGOALS),$(findstring $(MAKECMDGOALS), "" "all" "elab" "sim"))
    ifndef XILINX_VIVADO
       $(error XILINX_VIVADO environment variable not defined)
    endif
    ifndef CONFMC_HOME
       $(error CONFMC_HOME environment variable not defined)
     //export CONFMC_HOME=${HOME}/work/projects/ez-usb-fx3
    endif
    VIVADO_VERSION = $(shell vivado -version | sed -n 1p | cut -d" " -f 2 | cut -c 2-)
    export FPGA_TYPE=z7
    export VIVADO=vivado.$(VIVADO_VERSION)
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

export GUI  ?= 0
export OPTIONS    ?= -testplusarg VERBOSE=1\
                     -testplusarg TEST_INFO=1\
                     -testplusarg TEST_GPIN_OUT=1\
                     -testplusarg TEST_MEM=1\
                     -testplusarg TEST_MEM_PARTIAL_RAW=1\
                     -testplusarg TEST_MEM_PARTIAL_RAW_ALL=1

all: elab sim

pre:
	/bin/cat ../../design/verilog/defines_system_source.v\
		| /bin/sed 's|$$DATA_TYPE\$$|'"${DATA_TYPE}"'|g'\
		| /bin/sed 's|$$DATA_WIDTH\$$|'"${DATA_WIDTH}"'|g'\
		| /bin/sed 's|$$AMBA_AXI_WIDTH_ADDR\$$|'"${AMBA_AXI_WIDTH_ADDR}"'|g'\
		| /bin/sed 's|$$AMBA_AXI_WIDTH_DATA\$$|'"${AMBA_AXI_WIDTH_DATA}"'|g'\
		> ../../design/verilog/defines_system.v

elab: pre
	xelab -prj xsim.prj -debug typical\
		-L secureip -L unisims_ver -L unimacro_ver\
		top glbl -s top

sim:
	if [ "$(GUI)" = "1" ]; then\
		xsim top -gui -t xsim_run.tcl $(OPTIONS);\
	else\
		xsim top -t xsim_run.tcl $(OPTIONS);\
	fi
	@if [ -f xsim.log ]; then\
		if grep -q ERROR xsim.log; then\
			echo "\033[0;31mSimulation result ERROR.\033[0m";\
		else\
			echo "\033[0;33mOK = NO ERROR.\033[0m";\
		fi;\
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
