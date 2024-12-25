#------------------------------------------------------------------
SHELL    = /bin/sh
MAKEFILE = Makefile
#--------------------------------------------------------
ifeq ($(MAKECMDGOALS),$(findstring $(MAKECMDGOALS), "" "all" "elab" "sim"))
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
#--------------------------------------------------------
ILOG	 = iverilog
ISIM	 = vvp
#--------------------------------------------------------
TOP	  = top
#--------------------------------------------------------
all: pre compile simulate

pre:
	/bin/cat ../../bench/verilog/defines_system_source.v\
		| /bin/sed 's|$$DATA_TYPE\$$|'"${DATA_TYPE}"'|g'\
		| /bin/sed 's|$$DATA_WIDTH\$$|'"${DATA_WIDTH}"'|g'\
		| /bin/sed 's|$$AMBA_AXI_WIDTH_ADDR\$$|'"${AMBA_AXI_WIDTH_ADDR}"'|g'\
		| /bin/sed 's|$$AMBA_AXI_WIDTH_DATA\$$|'"${AMBA_AXI_WIDTH_DATA}"'|g'\
		> ../../bench/verilog/defines_system.v

compile: pre
	($(ILOG) -o $(TOP).vvp -s $(TOP)\
		-DSIM -DVCD -DCOSIM_BFM\
		-I../../bench/verilog\
		-I$(DIR_VPI_BFM)\
		-I../../../../mac/mac_integer/rtl/verilog\
		-I../../rtl/verilog\
		../xsim.cosim/sim_define.v\
		../../bench/verilog/top.v\
		../../bench/verilog/amba_axi_m2s2.v\
		../../bench/verilog/axi_to_apb.v\
		../../bench/verilog/mem_axi_beh.v\
		$(VPI_BFM)\
		../../rtl/verilog/pooling_2d.v\
		../../../../mac/mac_integer/rtl/verilog/mac_core.v\
		|| exit -1) 2>&1 | tee compile.log

simulate: compile
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
