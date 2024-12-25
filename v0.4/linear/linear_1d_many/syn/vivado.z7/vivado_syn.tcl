#-------------------------------------------------------------------------------
# VIVADO TCL Script
#-------------------------------------------------------------------------------
# Copyright (c) 2018 by Future Design Systems
# All right reserved.
#-------------------------------------------------------------------------------
# VERSION: 2018.06.01.
#-------------------------------------------------------------------------------
if {[info exists env(VIVADO_VER)] == 0} { 
     set VIVADO_VER vivado.2019.2
} else { 
     set VIVADO_VER $::env(VIVADO_VER)
}
if {[info exists env(FPGA_TYPE)] == 0} {
     set FPGA_TYPE  z7
} else {
     set FPGA_TYPE $::env(FPGA_TYPE)
}
if {[info exists env(DEVICE)] == 0} {
     set DEVICE xc7z020clg484-1
} else {
     set DEVICE $::env(DEVICE)
}
if {[info exists env(MODULE)] == 0} { 
     set MODULE linear_1d
} else { 
     set MODULE $::env(MODULE)
}
if {[info exists env(DATA_TYPE)] == 0} { 
     set DATA_TYPE INTEGER
} else { 
     set DATA_TYPE $::env(DATA_TYPE)
}
if {[info exists env(DIR_MAC)] == 0} { 
     set DIR_MAC ../../../../mac/mac_integer
} else { 
     set DIR_MAC $::env(DIR_MAC)
     if { ${DATA_TYPE} == "FLOATING_POINT" } {
         set DIR_MAC_CORE $::env(DIR_MAC_CORE)
     }
}
if {[info exists env(DIR_MAC_TREE)] == 0} { 
     set DIR_MAC_TREE ../../../../mac/tree_mac
} else { 
     set DIR_MAC_TREE $::env(DIR_MAC_TREE)
}
if {[info exists env(WORK)] == 0} { 
     set WORK work
} else { 
     set WORK $::env(WORK)
}
if {[info exists env(RIGOR)] == 0} { 
     set RIGOR 1
} else { 
     set RIGOR $::env(RIGOR)
}

#---------------------------------------------------------
set_part ${DEVICE}
set_property part ${DEVICE} [current_project]
file mkdir ${WORK}

set out_dir    ${WORK}
set part       ${DEVICE}
set module     ${MODULE}
set rigor      ${RIGOR}

#puts "******** ${DATA_TYPE}"
#puts "******** ${DIR_MAC}"
#puts "******** ${DIR_MAC_TREE}"
#puts "******** ${DIR_MAC_CORE}"
#------------------------------------------------------------------------------
# Assemble the design source files
#proc proc_read { {out_dir ${WORK}} {part ${DEVICE}} {module ${MODULE}} { rigor 0 } } {
     set DIR_RTL        ../../rtl/verilog
     set DIR_MAC        ${DIR_MAC}/rtl/verilog
     set DIR_MAC_TREE   ${DIR_MAC_TREE}/rtl/verilog

     #-------------------------------------------------------------------------
     if { ${DATA_TYPE} == "FLOATING_POINT" } {
     add_files "${DIR_MAC_CORE}/fp32_multiplier/fp32_multiplier.xci
                ${DIR_MAC_CORE}/fp32_accumulator/fp32_accumulator.xci
                ${DIR_MAC_CORE}/fp32_adder/fp32_adder.xci
                ${DIR_MAC_CORE}/fp16_multiplier/fp16_multiplier.xci
                ${DIR_MAC_CORE}/fp16_accumulator/fp16_accumulator.xci
                ${DIR_MAC_CORE}/fp16_adder/fp16_adder.xci"
     }

#puts "******** ${DIR_MAC_CORE}"
     #-------------------------------------------------------------------------
     set VERILOG_DIR_LIST " ${DIR_RTL}
                            ${DIR_MAC}
                            ${DIR_MAC_TREE}
                          "
     if { ${DATA_TYPE} == "FLOATING_POINT" } {
         append VERILOG_DIR_LIST " ${DIR_MAC_CORE} "
     }
     #puts "******** ${VERILOG_DIR_LIST}"
     set_property verilog_dir ${VERILOG_DIR_LIST} [current_fileset]

     #-------------------------------------------------------------------------
     set VLG_LIST "syn_define.v
                   ${DIR_RTL}/${MODULE}.v
                   ${DIR_MAC}/mac_core.v
                   ${DIR_MAC_TREE}/tree_mac.v
                  "
     #puts "******** ${VLG_LIST}"
     read_verilog  ${VLG_LIST}

     #-------------------------------------------------------------------------

#     return 0
#}

#---------------------------------------------------------
# Run synthesis and implementation
#proc proc_synth { out_dir {part ${DEVICE}} {module ${MODULE}} { rigor 0 } } {
     #proc_read ${out_dir} ${part} ${module} ${rigor}
     synth_design -top ${module} -part ${part}\
                  -mode out_of_context\
                  -flatten_hierarchy rebuilt\
                  -keep_equivalent_registers\
                  -directive RunTimeOptimized\
                  -verilog_define SYN=1\
                  -verilog_define VIVADO=1
    #write_verilog -force -mode synth_stub ${module_stu}
    #puts "${module_stu} has been written"
    #write_verilog -force -mode funcsim ${module_net}
    #puts "${module_net} has been written"
    #write_edif -force ${module_edn}
    #puts "${module_edn} has been written"
     write_checkpoint -force ${out_dir}/post_synth
     write_checkpoint -force ${MODULE}
     if { ${rigor} == 1} {
        report_timing_summary -file ${out_dir}/post_synth_timing_summary.rpt
        report_timing -sort_by group -max_paths 5 -path_type summary -file ${out_dir}/post_synth_timing.rpt
        report_power -file ${out_dir}/post_synth_power.rpt
        report_utilization -file ${out_dir}/post_synth_util.rpt
     }
#     return 0
#}

#---------------------------------------------------------
if {[info exists env(GUI)] == 0} {
     exit
} else {
    if { $::env(GUI) == 0} exit
}

#-------------------------------------------------------------------------------
# Revision History:
#
# 2017.01.17: 'BOARD_TYPE' added by Ando Ki.
#-------------------------------------------------------------------------------
