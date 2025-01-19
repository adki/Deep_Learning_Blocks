#!/bin/bash

MODULE=convolution_2d

/bin/rm -rf .Xil
/bin/rm -f  *.html
/bin/rm -f  *.jou
/bin/rm -f  *.backup*
/bin/rm -f  planAhead.*
/bin/rm -f  vivado.log
/bin/rm -f  vivado_pid*.str  vivado_pid*.debug
/bin/rm -f  fsm_encoding.os
/bin/rm -f  *.log
/bin/rm -f  ${MODULE}.ucf
/bin/rm -f  ${MODULE}.ut
/bin/rm -f  ${MODULE}.tcf
/bin/rm -rf work
/bin/rm -rf sim
/bin/rm -rf ${MODULE}.cache
/bin/rm -rf ${MODULE}.hw
/bin/rm -rf ${MODULE}.ip_user_files
/bin/rm -rf ${MODULE}.sim
/bin/rm -rf ${MODULE}.srcs
#/bin/rm -rf src
#/bin/rm -rf xgui
#/bin/rm -f  component.xml
#/bin/rm -f  ${MODULE}.xpr
