#------------------------------------------------------------------
SHELL		= /bin/sh
MAKEFILE	= Makefile
#--------------------------------------------------------
ILOG	= iverilog
ISIM	= vvp
#--------------------------------------------------------
TOP	  = top
DIR_RTL   = ../../rtl/verilog
DIR_MAC   = ../../../../mac/mac_integer/rtl/verilog
DIR_BENCH = ../../bench/verilog
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
	($(ILOG) -o $(TOP).vvp -s $(TOP)\
		-I$(DIR_BENCH)\
		-I$(DIR_RTL)\
		-I$(DIR_MAC)\
                ../xsim/sim_define.v\
		$(DIR_BENCH)/top.v\
		$(DIR_BENCH)/amba_axi_m2s2.v\
		$(DIR_BENCH)/axi_to_apb.v\
		$(DIR_BENCH)/mem_axi_beh.v\
		$(DIR_BENCH)/tester_pooling_2d.v\
		$(DIR_RTL)/pooling_2d.v\
		$(DIR_MAC)/mac_core.v\
		|| exit -1) 2>&1 | tee compile.log

simulate: compile
	$(ISIM) -l vvp.log $(TOP).vvp\
		+CSR_TEST=0\
		+MEM_TEST=0\
                +POOL_FEATURE_TEST=1\
                +POOL_TEST_NOPADDING=1\
                +POOL_TEST_PADDING=1\
                +POOL_TEST_PADDING_ASYMMETRY=1

#--------------------------------------------------------
clean:
	/bin/rm -f  $(TOP).vvp
	/bin/rm -f  compile.log
	/bin/rm -f  wave.vcd
	/bin/rm -f  vvp.log
	/bin/rm -f  result.bmp

cleanup clobber: clean

cleanupall distclean: cleanup
#--------------------------------------------------------
