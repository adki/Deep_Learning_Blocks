#------------------------------------------------------------------
SHELL    = /bin/sh
MAKEFILE = Makefile
#--------------------------------------------------------
ifeq ($(MAKECMDGOALS),$(findstring $(MAKECMDGOALS), "" "all" "compile" "elab" "sim"))
    ifeq (, $(shell which iverilog))
       $(error iverilog not found.)
    endif
    ifndef COSIM_HOME
       $(error COSIM_HOME environment variable not defined)
    else
        PLATFORM  = $(shell uname -s | tr '[:upper:]' '[:lower:]')
        MACHINE   = $(shell uname -m)
        export COSIM_LIB      = cosim_vpi_bfm.vpi
        export DIR_COSIM_ROOT = $(COSIM_HOME)/lib/iverilog/$(PLATFORM)_$(MACHINE)
        export DIR_VPI_BFM    = $(COSIM_HOME)/include/verilog
        export VPI_BFM        = $(DIR_VPI_BFM)/cosim_bfm_axi_vpi.v
    endif
endif
#--------------------------------------------------------
TOP	      = top
DIR_RTL       = ../../rtl/verilog
DIR_MAC       = ../../../../mac/mac_integer/rtl/verilog
DIR_BENCH     = ../../bench/verilog
DATA_TYPE           ?= INTEGER
DATA_WIDTH          ?= 32
AMBA_AXI_WIDTH_ADDR ?= 32
AMBA_AXI_WIDTH_DATA ?= 32

ifeq ("$(DATA_TYPE)","FLOATING_POINT")
    $(error DATA_TYPE FLOATING_POINT not supported due to Xilinx library.)
endif
#--------------------------------------------------------
ILOG	 = iverilog
ISIM	 = vvp
#--------------------------------------------------------
TOP	  = top
#--------------------------------------------------------
all: pre compile sim

pre:
	/bin/cat ../../bench/verilog/defines_system_source.v\
		| /bin/sed 's|$$DATA_TYPE\$$|'"${DATA_TYPE}"'|g'\
		| /bin/sed 's|$$DATA_WIDTH\$$|'"${DATA_WIDTH}"'|g'\
		| /bin/sed 's|$$AMBA_AXI_WIDTH_ADDR\$$|'"${AMBA_AXI_WIDTH_ADDR}"'|g'\
		| /bin/sed 's|$$AMBA_AXI_WIDTH_DATA\$$|'"${AMBA_AXI_WIDTH_DATA}"'|g'\
		> ../../bench/verilog/defines_system.v

compile:
	($(ILOG) -g2012 -o $(TOP).vvp -s $(TOP)\
		-DSIM -DVCD -DCOSIM_BFM\
		-I$(DIR_BENCH)\
		-I$(DIR_VPI_BFM)\
		-I$(DIR_MAC)\
		-I$(DIR_RTL)\
		./sim_define.v\
		$(DIR_MAC)/mac_core.v\
		$(DIR_RTL)/mover_2d.v\
		$(DIR_BENCH)/top.v\
		$(DIR_BENCH)/amba_axi_m2s2.v\
		$(DIR_BENCH)/axi_to_apb.v\
		$(DIR_BENCH)/mem_axi_beh.v\
		$(VPI_BFM)\
		|| exit -1) 2>&1 | tee compile.log

sim:
	$(ISIM) -l vvp.log\
		-M$(DIR_COSIM_ROOT) -mcosim_vpi_bfm\
		$(TOP).vvp

#--------------------------------------------------------
clean:
	/bin/rm -f  $(TOP).vvp
	/bin/rm -f  compile.log
	/bin/rm -f  wave.vcd wave*gtkw
	/bin/rm -f  vvp.log
	/bin/rm -f  result.bmp

cleanup clobber: clean

cleanupall distclean: cleanup
#--------------------------------------------------------
