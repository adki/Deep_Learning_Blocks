#!/bin/bash

source /tools/Xilinx/Vivado/2021.2/settings64.sh

if [ -z "$1" ]; then
    BIT_PATH="../../impl/vivado.zedboard/design_dpu_wrapper.bit"
else
    BIT_PATH="$1"
fi

JTAG_SERIAL="*RA"
#TARGET_DEV=$1
TARGET_DEV=0

if [ "${TARGET_DEV}" == "0" ]; then
        JTAG_SERIAL="*WA"
fi

xsdb -interactive << EOF
connect
targets -set -filter {jtag_cable_serial =~ "${JTAG_SERIAL}" && level == 0}
puts stderr "INFO: Configuring the FPGA..."
puts stderr "INFO: Downloading bitstream: ${BIT_PATH} to the target."
fpga ${BIT_PATH}
after 2000
exit
EOF
