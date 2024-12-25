#------------------------------------------------------------------
SHELL           = /bin/sh
MAKEFILE        = Makefile
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

#-------------------------------------------------------------------------------
export WID        ?= 32
export FPGA       ?= z7
export GUI        ?= 0
export OPTIONS    ?= -testplusarg VERBOSE=1

#-------------------------------------------------------------------------------
all: replace elab sim

replace:
	/bin/cat sim_define_save.v | /bin/sed 's|DATA_WIDTH|'"${WID}"'|g' > sim_define.v
elab:
	xelab -prj xsim.prj -debug typical\
		-L secureip -L unisims_ver -L unimacro_ver\
		top glbl -s top

sim:
	if [ "$(GUI)" = "0" ]; then\
		xsim top -t xsim_run.tcl $(OPTIONS);\
	else\
		xsim top -gui -t xsim_run.tcl $(OPTIONS);\
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

cleanupall distclean: cleanup
