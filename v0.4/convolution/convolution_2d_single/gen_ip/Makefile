#------------------------------------------------------------------
# VIVADO Batch Mode 
#------------------------------------------------------------------
# Copyright (c) 2021 by Future Design Systems
# All right reserved.
#------------------------------------------------------------------
SHELL		= /bin/sh
MAKEFILE	= Makefile
#------------------------------------------------------------------
export VIVADO      = $(XILINX_VIVADO)/bin/vivado
export SOURCE      = vivado_gen_ip.tcl
export WORK        = work
export MODULE      = convolution_2d
export DESCRIPTION = "Convolution 2D"
export BOARD      ?= zed

export RIGOR       = 1
export GUI        ?= 0

ifeq ("${BOARD}","zed")
export FPGA_TYPE   = z7
export DEVICE      = xc7z020clg484-1
else ifeq ("${BOARD}","nexys_video")
export FPGA_TYPE   = a7
export DEVICE      = xc7a200tsbg484-1
else ifeq ("${BOARD}","ultrazed")
export FPGA_TYPE   = us7
export DEVICE      = xczu7ev-fbvb900-1-i
else ifeq ("${BOARD}","zc706")
export FPGA_TYPE   = us
export DEVICE      = xc7z045ffg900-2
else ifeq ("${BOARD}","zcu102")
export FPGA_TYPE   = us
export DEVICE      = xczu9eg-ffvb1156-2-e
endif

#------------------------------------------------------------------
all: vivado

vivado:
	if [ "$(GUI)" = "1" ]; then\
		$(VIVADO) -mode gui -source $(SOURCE);\
	else\
		$(VIVADO) -mode batch -source $(SOURCE);\
	fi

#------------------------------------------------------------------
DIRS    = $(subst /,, $(dir $(wildcard */Makefile)))

clean:
	/bin/rm -f    vivado.jou
	/bin/rm -f    vivado.log
	/bin/rm -f    vivado_*.backup.jou  vivado_*.backup.log
	/bin/rm -fr   .Xil/
	/bin/rm -f    .hdi.isWriteableTest*

cleanup: clean

cleanupall: cleanup
	/bin/rm -fr  component.xml
	/bin/rm -fr  convolution_2d.cache/
	/bin/rm -fr  convolution_2d.hw/
	/bin/rm -fr  convolution_2d.ip_user_files/
	/bin/rm -fr  convolution_2d.sim/
	/bin/rm -fr  convolution_2d.xpr
	/bin/rm -fr  src/
	/bin/rm -fr  xgui/
