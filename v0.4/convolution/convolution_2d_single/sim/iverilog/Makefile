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

compile:
	($(ILOG) -o $(TOP).vvp -s $(TOP)\
		-I$(DIR_MAC)\
		-I$(DIR_RTL)\
		-I$(DIR_BENCH)\
                ./sim_define.v\
		$(DIR_MAC)/mac_core.v\
		$(DIR_RTL)/convolution_2d.v\
		$(DIR_BENCH)/top.v\
		$(DIR_BENCH)/amba_axi_m4s2.v\
		$(DIR_BENCH)/mem_axi_beh.v\
		$(DIR_BENCH)/tester_convolution_2d.v\
		|| exit -1) 2>&1 | tee compile.log

simulate: compile
	$(ISIM) -l vvp.log $(TOP).vvp\
		+VERBOSE=1\
		+CSR_TEST=1\
		+MEM_TEST=1\
		+KERNEL_TEST=1\
		+FEATURE_TEST=1\
		+MAC_TEST_NOPADDING=1\
		+MAC_TEST_PADDING=1\
		+MAC_TEST_PADDING_ASYMMETRY=1\
		+MAC_TEST_SINGLE_KERNEL=1

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
