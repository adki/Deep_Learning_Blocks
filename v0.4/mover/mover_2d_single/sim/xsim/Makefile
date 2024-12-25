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
export GUI        ?= 0
export OPTIONS    ?= -testplusarg VERBOSE=1\
                     -testplusarg CSR_TEST=0\
                     -testplusarg MEM_TEST=0\
                     -testplusarg FILL_TEST_aligned=1\
                     -testplusarg FILL_TEST_misaligned=1\
                     -testplusarg COPY_TEST_aligned=1\
                     -testplusarg COPY_TEST_misaligned_src=1\
                     -testplusarg COPY_TEST_misaligned_dst=1\
                     -testplusarg COPY_TEST_misaligned_src_dst=1\
                     -testplusarg COPY_TEST_overwrite_aligned=1\
                     -testplusarg COPY_TEST_overwrite_misaligned=1\
                     -testplusarg COPY_TEST_ACTIV_RELU_aligned=1\
                     -testplusarg COPY_TEST_ACTIV_LEAKY_RELU_aligned=1\
                     -testplusarg CONCAT0_TEST_aligned=1\
                     -testplusarg CONCAT0_TEST_asymmetric=1\
                     -testplusarg CONCAT0_TEST_misaligned=1\
                     -testplusarg CONCAT1_TEST_aligned=1\
                     -testplusarg CONCAT1_TEST_asymmetric=1\
                     -testplusarg CONCAT1_TEST_misaligned=1\
                     -testplusarg RESIDUAL_TEST_aligned=1\
                     -testplusarg RESIDUAL_TEST_misaligned=1\
                     -testplusarg TRANSPOSE_TEST_aligned=1

#-------------------------------------------------------------------------------
all: elab sim

elab:
	xelab -prj xsim.prj -debug typical top -s top

sim:
	@if [ "$(GUI)" = "0" ]; then\
		xsim top -t xsim_run.tcl $(OPTIONS);\
	else\
		xsim top -gui -t xsim_run.tcl $(OPTIONS);\
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

cleanupall distclean: cleanup
