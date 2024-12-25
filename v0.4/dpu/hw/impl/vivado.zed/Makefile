
export PROJECT        ?= 1
export SYN_ONLY       ?= 0
export ILA            ?= 0
export GUI            ?= 1
export SOURCE          = ../vivado.scripts/vivado_prj.tcl
export DIR_XDC         = ../vivado.scripts/xdc

export BOARD      ?= zed
export BOARD_PART ?= em.avnet.com:zed:part0:1.4
export PART       ?= xc7z020clg484-1
export FPGA_TYPE  ?= z7

export DATA_TYPE  ?= FLOATING_POINT
export DATA_WIDTH ?= 32
export AMBA_AXI_WIDTH_ADDR ?= 32
export AMBA_AXI_WIDTH_DATA ?= 32

ifdef CONFMC_HOME
export BFM       ?= $(CONFMC_HOME)/hwlib/trx_axi/gen_ip/vivado.$(FPGA_TYPE)
else
export BFM       ?= ../../../iplib/bfm_axi/gen_ip/zed
endif

all: pre
	make -f ../vivado.scripts/Makefile\
		ILA=$(ILA)\
		SYN_ONLY=$(SYN_ONLY)\
		PROJECT=$(PROJECT)\
		GUI=$(GUI)\
		DIR_XDC=$(DIR_XDC)\
		DATA_TYPE=$(DATA_TYPE)\
		SOURCE=$(SOURCE)

        ifeq ($(ILA),1)
	if [ -f project_1/project_1.runs/impl_1/fpga.bit ]; then\
		cp project_1/project_1.runs/impl_1/fpga.bit fpga_ila.bit;\
	fi
	if [ -f project_1/project_1.runs/impl_1/fpga.ltx ]; then\
		cp project_1/project_1.runs/impl_1/fpga.ltx fpga_ila.ltx;\
	fi
        endif

pre:
	/bin/cat ../../design/verilog/defines_system_source.v\
		| /bin/sed 's|$$DATA_TYPE\$$|'"${DATA_TYPE}"'|g'\
		| /bin/sed 's|$$DATA_WIDTH\$$|'"${DATA_WIDTH}"'|g'\
		| /bin/sed 's|$$AMBA_AXI_WIDTH_ADDR\$$|'"${AMBA_AXI_WIDTH_ADDR}"'|g'\
		| /bin/sed 's|$$AMBA_AXI_WIDTH_DATA\$$|'"${AMBA_AXI_WIDTH_DATA}"'|g'\
		> ../../design/verilog/defines_system.v

clean cleanup clobber distclean cleanupall:
	make -f ../vivado.scripts/Makefile $@

