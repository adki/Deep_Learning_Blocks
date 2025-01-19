#------------------------------------------------------------------
SHELL		= /bin/sh
MAKEFILE	= Makefile
#--------------------------------------------------------
ILOG	= iverilog
ISIM	= vvp
#--------------------------------------------------------
TOP	      = top
DIR_RTL       = ../../rtl/verilog
DIR_MAC       = ../../../mac/mac_integer/rtl/verilog
DIR_BENCH     = ../../bench/verilog
DATA_TYPE    ?= INTEGER
ifeq ("$(DATA_TYPE)","FLOATING_POINT")
    $(error DATA_TYPE FLOATING_POINT not supported due to Xilinx library.)
endif
DATA_WIDTH          ?= 32
AMBA_AXI_WIDTH_ADDR ?= 32
AMBA_AXI_WIDTH_DATA ?= 32
OPTIONS      ?= +VERBOSE=1\
                +CSR_TEST=1\
                +MEM_TEST=1\
                +KERNEL_TEST=1\
                +FEATURE_TEST=1\
                +MAC_TEST_NOPADDING=1\
                +MAC_TEST_PADDING=1\
                +MAC_TEST_PADDING_ASYMMETRY=1\
                +MAC_TEST_SINGLE_KERNEL=1
export DIR_BENCH    = ../../bench/verilog
export DIR_RTL      = ../../rtl/verilog
export DIR_CONV     = ../../../convolution/convolution_2d_single/rtl/verilog
export DIR_POOL     = ../../../pooling/pooling_2d_single/rtl/verilog
export DIR_LINEAR   = ../../../linear/linear_1d_many/rtl/verilog
export DIR_MOVER    = ../../../mover/mover_2d_single/rtl/verilog
export DIR_MAC_TREE = ../../../mac/tree_mac/rtl/verilog
#--------------------------------------------------------
all: compile simulate

pre:
	/bin/cat ../../bench/verilog/defines_system_source.v\
		| /bin/sed 's|$$DATA_TYPE\$$|'"${DATA_TYPE}"'|g'\
		| /bin/sed 's|$$DATA_WIDTH\$$|'"${DATA_WIDTH}"'|g'\
		| /bin/sed 's|$$AMBA_AXI_WIDTH_ADDR\$$|'"${AMBA_AXI_WIDTH_ADDR}"'|g'\
		| /bin/sed 's|$$AMBA_AXI_WIDTH_DATA\$$|'"${AMBA_AXI_WIDTH_DATA}"'|g'\
		> ../../bench/verilog/defines_system.v

elab compile: pre
	($(ILOG) -g2012 -o $(TOP).vvp -s $(TOP)\
		-DSIM -DVCD\
		-I$(DIR_BENCH)\
		-I$(DIR_RTL)\
		-I$(DIR_CONV)\
		-I$(DIR_POOL)\
		-I$(DIR_LINEAR)\
		-I$(DIR_MOVER)\
		-I$(DIR_MAC)\
		-I$(DIR_MAC_TREE)\
                ./sim_define.v\
		$(DIR_BENCH)/defines_system.v\
		$(DIR_BENCH)/top.sv\
		$(DIR_RTL)/dpu.v\
		$(DIR_RTL)/axi_to_apb_s5.v\
		$(DIR_RTL)/dpu_configuration.v\
		$(DIR_CONV)/convolution_2d.v\
		$(DIR_POOL)/pooling_2d.v\
		$(DIR_LINEAR)/linear_1d.v\
		$(DIR_MOVER)/mover_2d.v\
		$(DIR_MAC)/mac_core.v\
		$(DIR_MAC_TREE)/tree_mac.v\
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
