#!/bin/csh -f

set MODULES  = fp32_multiplier fp32_accumulator fp32_adder fp32_gt\
               fp16_multiplier fp16_accumulator fp16_adder fp16_gt

/bin/rm -rf ./.Xil
/bin/rm -rf work
/bin/rm -f  ./*.html
/bin/rm -f  ./*.xml
/bin/rm -f  ./vivado*.jou
/bin/rm -f  ./vivado*.log
/bin/rm -f  ./vivado_*.str
/bin/rm -f  ./*.backup.*
/bin/rm -f  ./planAhead.*
/bin/rm -f  fsm_encoding.os
/bin/rm -rf ip_user_files
/bin/rm -rf managed_ip_project

foreach F ( $MODULES )
    /bin/rm -rf $F
end
