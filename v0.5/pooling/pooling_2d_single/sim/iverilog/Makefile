#------------------------------------------------------------------
SHELL		= /bin/sh
MAKEFILE	= Makefile
#--------------------------------------------------------
ILOG	= iverilog
ISIM	= vvp
#--------------------------------------------------------
TOP	      = top
DIR_RTL       = ../../rtl/verilog
DIR_MAC       = ../../../../mac/mac_integer/rtl/verilog
DIR_BENCH     = ../../bench/verilog
DATA_TYPE    ?= INTEGER
DATA_WIDTH          ?= 32
AMBA_AXI_WIDTH_ADDR ?= 32
AMBA_AXI_WIDTH_DATA ?= 32
OPTIONS      ?= +VERBOSE=1\
		+CSR_TEST=0\
		+MEM_TEST=0\
                +POOL_FEATURE_TEST=1\
                +POOL_TEST_NOPADDING=1\
                +POOL_TEST_PADDING=1\
                +POOL_TEST_PADDING_ASYMMETRY=1
ifeq ("$(DATA_TYPE)","FLOATING_POINT")
    $(error DATA_TYPE FLOATING_POINT not supported due to Xilinx library.)
endif
#--------------------------------------------------------
all: compile simulate

pre:
	/bin/cat ../../bench/verilog/defines_system_source.v\
		| /bin/sed 's|$$DATA_TYPE\$$|'"${DATA_TYPE}"'|g'\
		| /bin/sed 's|$$DATA_WIDTH\$$|'"${DATA_WIDTH}"'|g'\
		| /bin/sed 's|$$AMBA_AXI_WIDTH_ADDR\$$|'"${AMBA_AXI_WIDTH_ADDR}"'|g'\
		| /bin/sed 's|$$AMBA_AXI_WIDTH_DATA\$$|'"${AMBA_AXI_WIDTH_DATA}"'|g'\
		> ../../bench/verilog/defines_system.v

compile: pre
	($(ILOG) -g2012 -o $(TOP).vvp -s $(TOP)\
		-I$(DIR_MAC)\
		-I$(DIR_RTL)\
		-I$(DIR_BENCH)\
                ./sim_define.v\
		$(DIR_MAC)/mac_core.v\
		$(DIR_RTL)/pooling_2d.v\
		$(DIR_BENCH)/top.v\
		$(DIR_BENCH)/amba_axi_m2s2.v\
		$(DIR_BENCH)/axi_to_apb.v\
		$(DIR_BENCH)/mem_axi_beh.v\
		$(DIR_BENCH)/tester_pooling_2d.v\
		|| exit -1) 2>&1 | tee compile.log

simulate: compile
	$(ISIM) -l vvp.log $(TOP).vvp $(OPTIONS)
	@if [ -f vvp.log ]; then\
		if grep -q ERROR vvp.log; then\
			echo "\033[0;31mSimulation result ERROR.\033[0m";\
		else\
			echo "\033[0;33mOK = NO ERROR.\033[0m";\
		fi;\
	fi

#--------------------------------------------------------
clean:
	/bin/rm -f  $(TOP).vvp
	/bin/rm -f  compile.log
	/bin/rm -f  wave.vcd
	/bin/rm -f  vvp.log
	/bin/rm -f  result.bmp
	/bin/rm -f  wave.gtk.gtkw

cleanup clobber: clean

cleanupall distclean: cleanup
#--------------------------------------------------------
