# All right reserved.
#------------------------------------------------------------------
# How to ILA.
# 1. $ make SYN_ONLY=1
# 2. $ cd ila
# 3. $ make
# 4. $ cd ..
# 5. $ make ILA=1 GUI=1
#------------------------------------------------------------------
SHELL		= /bin/sh
MAKEFILE	= Makefile
#-------------------------------------------------------------------------------
ifeq ($(MAKECMDGOALS),$(findstring $(MAKECMDGOALS), "" "all" "elab" "sim"))
    ifndef XILINX_VIVADO
           $(error XILINX_VIVADO environment variable not defined)
    endif
    export VIVADO         = $(XILINX_VIVADO)/bin/vivado
    export VIVADO_VERSION = $(shell vivado -version | sed -n 1p | cut -d" " -f 2 | cut -c 2-7)
    export VIVADO_VER     = vivado.$(VIVADO_VERSION)
    ifndef CONFMC_HOME
       $(error CONFMC_HOME environment variable not defined)
       #export CONFMC_HOME=${HOME}/work/projects/ez-usb-fx3
    endif
    export BFM_AXI=${CONFMC_HOME}/hwlib/trx_axi
    ifeq ("$(wildcard ${BFM_AXI}/syn/vivado.${FPGA_TYPE}/bfm_axi.edif)","")
        $(warning "${BFM_AXI}/syn/vivado.${FPGA_TYPE}/bfm_axi.edif not found.")
        ifeq ("$(wildcard ${BFM_AXI}/syn/vivado/bfm_axi.edif)","")
             $(warning "${BFM_AXI}/syn/vivado/bfm_axi.edif not found.")
        else
             export DIR_BFM_EDIF=${BFM_AXI}/syn/vivado
        endif
    else
        export DIR_BFM_EDIF=${BFM_AXI}/syn/vivado.${FPGA_TYPE}
    endif
endif
#------------------------------------------------------------------
#export BOARD         ?= nexys_video
export BOARD          ?= zed
ifeq ("${BOARD}","zed")
# Zynq-7000
export BOARD_PART      = em.avnet.com:zed:part0:1.4
export FPGA_TYPE       = z7
export DEVICE          = xc7z020clg484-1
export BOARD_TYPE      = BOARD_ZED
else ifeq ("${BOARD}","nexys_video")
# Artix-7
export BOARD_PART      = digilentinc.com:nexys_video:part0:1.1
export FPGA_TYPE       = a7
export DEVICE          = xc7a200tsbg484-1
export BOARD_TYPE      = BOARD_NEXYS_VIDEO
else ifeq ("${BOARD}","vcu108")
# Artix-7
export BOARD_PART ?= xilinx.com:vcu108:part0:1.7
export FPGA_TYPE       = vus
export DEVICE          = xcvu095-ffva2104-2-e
export BOARD_TYPE      = BOARD_VCU108
else
$(error "unknown board ${BOARD})
endif
#------------------------------------------------------------------
export PROJECT_DIR     = project_1
export PROJECT_NAME    = project_1
export WORK            = work
export PLATFORM       ?= linux
export MODULE          = fpga
export RIGOR           = 1
export DIR_FIP         = ../../iplib
export DIR_XDC         = ./xdc
export ILA            ?= 0
export SYN_ONLY       ?= 0
export PROJECT        ?= 1
ifeq (${ILA},1)
export GUI            ?= 1
else
export GUI            ?= 1
endif
ifeq (${PROJECT},1)
export SOURCE         = vivado_prj.tcl
else
export SOURCE         = vivado_run.tcl
endif
export SOURCE_HW_MANAGER=vivado_hw.tcl
export BITS           = $(MODULE).bit

export DATA_TYPE     ?= FLOATING_POINT
FLOG	= $(MODULE)
#------------------------------------------------------------------
all:
	if [ "$(GUI)" = "1" ]; then\
		$(VIVADO) -mode gui -source $(SOURCE);\
	else\
		$(VIVADO) -mode batch -source $(SOURCE);\
	fi
	if [ -f project_1/project_1.runs/impl_1/$(BITS) ]; then\
		cp project_1/project_1.runs/impl_1/$(BITS) $(BITS);\
	fi

hw:
	$(VIVADO) -mode gui -source $(SOURCE_HW_MANAGER);

#------------------------------------------------------------------
DIRS    = $(subst /,, $(dir $(wildcard */Makefile)))

clean:
	-@/bin/rm -rf $(WORK)
	-@/bin/rm -rf .Xil
	-@/bin/rm -rf work .cache
	-@/bin/rm -f  *.html
	-@/bin/rm -f  *.xml
	-@/bin/rm -f  *.jou
	-@/bin/rm -f  *.backup*
	-@/bin/rm -f  planAhead.*
	-@/bin/rm -f  vivado.log
	-@/bin/rm -f  vivado_pid*.str  vivado_pid*.debug
	-@/bin/rm -f  fsm_encoding.os
	-@/bin/rm -f  impact_impact.xwbt  impact.xsl webtalk.log
	-@/bin/rm -f  vivado_pid*.zip
	-@/bin/rm -rf work
	-@/bin/rm -fr project_1.cache
	-@/bin/rm -fr project_1.hw
	-@/bin/rm -fr project_1.ip_user_files
	-@/bin/rm -f  project_1.xpr
	for D in $(DIRS); do\
		if [ -f $$D/Makefile ] ; then \
			echo "make -C $$D -s $@";\
			make -C $$D -s $@;\
		fi;\
	done
	/bin/rm -f target.xdc

cleanup clobber: clean
	-@/bin/rm -f  ./*.log
	-@/bin/rm -f  $(MODULE).ucf
	-@/bin/rm -f  $(MODULE).ut
	-@/bin/rm -f  $(MODULE).tcf
	-@/bin/rm -f  $(MODULE).edn
	-@/bin/rm -f  $(MODULE).edif
	-@/bin/rm -f  target.xdc
	-@/bin/rm -f  all.xdc
	-@/bin/rm -fr checkpoint
	-@/bin/rm -fr hd_visual
	-@/bin/rm -f  tight_setup_hold_pins.txt
	for D in $(DIRS); do\
		if [ -f $$D/Makefile ] ; then \
			echo "make -C $$D -s $@";\
			make -C $$D -s $@;\
		fi;\
	done

cleanupall distclean: cleanup
	-@/bin/rm -f  $(MODULE).bit $(MODULE)_ila.bit
	-@/bin/rm -f  $(MODULE).ltx $(MODULE)_ila.ltx
	-@/bin/rm -fr $(PROJECT_DIR)
	-@/bin/rm -fr project_1
	for D in $(DIRS); do\
		if [ -f $$D/Makefile ] ; then \
			echo "make -C $$D -s $@";\
			make -C $$D -s $@;\
		fi;\
	done
