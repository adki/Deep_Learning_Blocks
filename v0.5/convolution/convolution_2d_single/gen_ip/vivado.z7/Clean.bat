@ECHO OFF

SET MODULE=convolution_2d
DEL /Q  *.html
DEL /Q  *.jou
DEL /Q  *.backup*
DEL /Q  planAhead.*
DEL /Q  vivado.log
DEL /Q  vivado_pid*.str  vivado_pid*.debug
DEL /Q  fsm_encoding.os
DEL /Q  ./*.log
DEL /Q  %MODULE%.ucf
DEL /Q  %MODULE%.ut
DEL /Q  %MODULE%.tcf
RMDIR /S/Q .Xil
RMDIR /S/Q work
RMDIR /S/Q sim
RMDIR /S/Q %MODULE%.cache
RMDIR /S/Q %MODULE%.hw
RMDIR /S/Q %MODULE%.ip_user_files
RMDIR /S/Q %MODULE%.sim
RMDIR /S/Q %MODULE%.srcs
REM RMDIR /S/Q src
REM RMDIR /S/Q xgui
REM DEL   /Q   component.xml
REM DEL   /Q   %MODULE%.xpr
