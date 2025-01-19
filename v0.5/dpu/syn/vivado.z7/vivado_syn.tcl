#-------------------------------------------------------------------------------
# VIVADO TCL Script
#-------------------------------------------------------------------------------
# Copyright (c) 2024 by Future Design Systems
# All right reserved.
#-------------------------------------------------------------------------------
# VERSION: 2024.02.01.
#---------------------------------------------------------
if {[info exists env(VIVADO_VER)] == 0} { 
     set VIVADO_VER vivado.2021.1
} else { 
     set VIVADO_VER $::env(VIVADO_VER)
}
if {[info exists env(FPGA_TYPE)] == 0} { 
     set FPGA_TYPE  z7
} else {
     set FPGA_TYPE  $::env(FPGA_TYPE)
}
if {[info exists env(PART)] == 0} { 
     set PART     xc7z020-clg484-1
} else { 
     set PART  $::env(PART)
}
if {[info exists env(MODULE)] == 0} { 
     set MODULE convolution_2d
} else { 
     set MODULE $::env(MODULE)
}
if {[info exists env(DATA_TYPE)] == 0} { 
     set DATA_TYPE "FLOATING_POINT"
} else { 
     set DATA_TYPE $::env(DATA_TYPE)
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

set DIR_MAC          $::env(DIR_MAC)
if { ${DATA_TYPE} == "FLOATING_POINT" } {
    set DIR_MAC_CORES    $::env(DIR_MAC_CORES)
}
set DIR_RTL      $::env(DIR_RTL)
set DIR_CONV     $::env(DIR_CONV)
set DIR_POOL     $::env(DIR_POOL)
set DIR_LINEAR   $::env(DIR_LINEAR)
set DIR_MOVER    $::env(DIR_MOVER)
set DIR_MAC_TREE $::env(DIR_MAC_TREE)

#---------------------------------------------------------
set_part ${PART}
set_property part ${PART} [current_project]
file mkdir ${WORK}

set out_dir    ${WORK}
set part       ${PART}
set module     ${MODULE}
set module_edn ${MODULE}.edn
set module_net ${MODULE}.vm
set module_stu ${MODULE}_stub.v
set rigor      ${RIGOR}

#------------------------------------------------------------------------------
# Assemble the design source files
    if { ${DATA_TYPE} == "FLOATING_POINT" } {
        set_property verilog_dir "${DIR_RTL}       
                                  ${DIR_CONV}
                                  ${DIR_POOL}
                                  ${DIR_LINEAR}
                                  ${DIR_MOVER}
                                  ${DIR_MAC_TREE}
                                  ${DIR_MAC}
                                  ${DIR_MAC_CORES}" [current_fileset]
        set_property verilog_dir " ${DIR_MAC_CORES} " [current_fileset]
        read_ip "${DIR_MAC_CORES}/fp32_multiplier/fp32_multiplier.xci
                 ${DIR_MAC_CORES}/fp32_accumulator/fp32_accumulator.xci
                 ${DIR_MAC_CORES}/fp32_adder/fp32_adder.xci
                 ${DIR_MAC_CORES}/fp32_gt/fp32_gt.xci
                 ${DIR_MAC_CORES}/fp16_multiplier/fp16_multiplier.xci
                 ${DIR_MAC_CORES}/fp16_accumulator/fp16_accumulator.xci
                 ${DIR_MAC_CORES}/fp16_adder/fp16_adder.xci
                 ${DIR_MAC_CORES}/fp16_gt/fp16_gt.xci"
    } elseif { ${DATA_TYPE} == "INTEGER" } {
        set_property verilog_dir "${DIR_RTL}       
                                  ${DIR_CONV}
                                  ${DIR_POOL}
                                  ${DIR_LINEAR}
                                  ${DIR_MOVER}
                                  ${DIR_MAC_TREE}
                                  ${DIR_MAC} " [current_fileset]
    } else {
        puts "ERROR: undefined data type ${DTAT_TYPE}"
        exit
    }
    puts [get_property verilog_dir [current_fileset]]

    #-------------------------------------------------------------------------
    set VLG_LIST "syn_define.v
                  defines_system.v
                  ${DIR_RTL}/${MODULE}.v
                  ${DIR_RTL}/axi_to_apb_s5.v
                  ${DIR_RTL}/dpu_configuration.v
                  ${DIR_CONV}/convolution_2d.v
                  ${DIR_POOL}/pooling_2d.v
                  ${DIR_LINEAR}/linear_1d.v
                  ${DIR_MOVER}/mover_2d.v
                  ${DIR_MAC}/mac_core.v
                  ${DIR_MAC_TREE}/tree_mac.v"
    puts ${VLG_LIST}
    read_verilog  ${VLG_LIST}

#---------------------------------------------------------
# Manual Compile Order mode
set_property source_mgmt_mode None [current_project]
set_property top_file ${DIR_RTL}/${MODULE}.v [current_fileset]
reorder_files -fileset [current_fileset] -front syn_define.v
reorder_files -fileset [current_fileset] -front defines_system.v
set_property top ${MODULE} [current_fileset]
update_compile_order -fileset sources_1

#---------------------------------------------------------
# Run synthesis and implementation
     synth_design -top ${module} -part ${part}\
                  -mode out_of_context\
                  -flatten_hierarchy rebuilt\
                  -keep_equivalent_registers\
                  -directive RunTimeOptimized\
                  -verilog_define SYN=1\
                  -verilog_define VIVADO=1\
                  -verilog_define ${FPGA_TYPE}=1\
                  -verilog_define AMBA_AXI4=1\
                  -verilog_define AMBA_APB3=1\
                  -verilog_define DATA_TYPE="${DATA_TYPE}"\
                  -generic DATA_TYPE="${DATA_TYPE}"
     write_verilog -force -mode synth_stub ${module_stu}
     puts "${module_stu} has been written"
     write_verilog -force -mode funcsim ${module_net}
     puts "${module_net} has been written"
     write_edif -force ${module_edn}
     puts "${module_edn} has been written"
     write_checkpoint -force ${out_dir}/post_synth
     write_checkpoint -force ${MODULE}
     if { ${rigor} == 1} {
        report_timing_summary -file ${out_dir}/post_synth_timing_summary.rpt
        report_timing -sort_by group -max_paths 5 -path_type summary -file ${out_dir}/post_synth_timing.rpt
        report_power -file ${out_dir}/post_synth_power.rpt
        report_utilization -file ${out_dir}/post_synth_util.rpt
     }

#---------------------------------------------------------
if {$::env(GUI) == 0} {
  exit
}
#-------------------------------------------------------------------------------
# Revision History:
#
# 2025.01.07 started by Ando Ki.
#-------------------------------------------------------------------------------
