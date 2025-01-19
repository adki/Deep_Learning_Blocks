@ECHO OFF

SET MODULES=fp32_multiplier fp32_accumulator fp32_adder fp32_gt^
            fp16_multiplier fp16_accumulator fp16_adder fp16_gt

DEL   /Q   *.html
DEL   /Q   *.xml
DEL   /Q   vivado*.jou
DEL   /Q   vivado*.log
DEL   /Q   vivado_*.str
DEL   /Q   *.backup.*
DEL   /Q   planAhead.*
DEL   /Q   m_encoding.os
RMDIR /S/Q ip_user_files
RMDIR /S/Q managed_ip_project
RMDIR /S/Q .Xil
RMDIR /S/Q work

@FOR /D %%I in ( %MODULES% ) DO @(
	RMDIR /S/Q %%I
)
