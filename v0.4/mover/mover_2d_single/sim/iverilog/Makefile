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
		-I$(DIR_RTL)\
		-I$(DIR_BENCH)\
                ./sim_define.v\
		$(DIR_RTL)/mover_2d.v\
		$(DIR_MAC)/mac_core.v\
		$(DIR_BENCH)/top.v\
		$(DIR_BENCH)/amba_axi_m2s2.v\
		$(DIR_BENCH)/mem_axi_beh.v\
		$(DIR_BENCH)/tester_mover_2d.v\
		|| exit -1) 2>&1 | tee compile.log

simulate: compile
	$(ISIM) -l vvp.log $(TOP).vvp\
		+VERBOSE=1\
		+CSR_TEST=0\
		+MEM_TEST=0\
		+COPY_TEST_aligned=0\
		+COPY_TEST_misaligned_src=0\
		+COPY_TEST_misaligned_dst=0\
		+COPY_TEST_misaligned_src_dst=0\
		+FILL_TEST_aligned=0\
		+FILL_TEST_misaligned=0\
		+CONCAT0_TEST_aligned=0\
		+CONCAT0_TEST_asymmetric=0\
		+CONCAT0_TEST_misaligned=0\
		+CONCAT1_TEST_aligned=0\
		+CONCAT1_TEST_asymmetric=0\
		+CONCAT1_TEST_misaligned=0\
		+RESIDUAL_TEST_aligned=0\
		+RESIDUAL_TEST_misaligned=1

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
