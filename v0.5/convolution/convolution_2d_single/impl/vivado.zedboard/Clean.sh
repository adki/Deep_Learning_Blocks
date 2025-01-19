#!/bin/bash

DESIGN=convolution_2d

/bin/rm   -f  vivado.jou
/bin/rm   -f  vivado.log
/bin/rm   -f  vivado_*.backup.jou
/bin/rm   -f  vivado_*.backup.log
/bin/rm   -f  hs_err_*.log
/bin/rm   -f  vivado_pid*.str
/bin/rm   -f  vivado_pid*.zip
/bin/rm   -fr .Xil
/bin/rm   -fr hd_visual

/bin/rm -f  ${DESIGN}_wrapper.v

#/bin/rm -f  ${DESIGN}_wrapper.bit
#/bin/rm -f  ${DESIGN}_wrapper.ltx
/bin/rm -f  ${DESIGN}.pdf
/bin/rm -f  AddressMap.cvs AddressMapGui.csv
/bin/rm -fr project_${DESIGN}
