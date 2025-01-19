@ECHO OFF

SET DESIGN=convolution_2d

DEL /Q  vivado.jou
DEL /Q  vivado.log
DEL /Q  vivado_*.backup.jou
DEL /Q  vivado_*.backup.log
DEL /Q  hs_err_*.log
DEL /Q  vivado_pid*.str
DEL /Q  vivado_pid*.zip
RMDIR /Q/S .Xil
RMDIR /Q/S hd_visual

DEL /Q  %DESIGN%_wrapper.v
REM DEL /Q  %DESIGN%_wrapper.bit
REM DEL /Q  %DESIGN%_wrapper.ltx
DEL /Q  %DESIGN%.pdf
DEL /Q  AddressMap.cvs AddressMapGui.csv
DEL /Q/S project_%DESIGN%
