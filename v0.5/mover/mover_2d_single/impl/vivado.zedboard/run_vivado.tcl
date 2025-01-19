set DESIGN       $::env(DESIGN)
set DESIGN_NAME  $::env(DESIGN_NAME)
set PROJECT_NAME $::env(PROJECT_NAME)
set PROJECT_DIR  $::env(PROJECT_DIR)
set BOARD        $::env(BOARD)
set FPGA_TYPE    $::env(FPGA_TYPE)
set PART         $::env(PART)
set BOARD_PART   $::env(BOARD_PART)
set BFM_AXI      $::env(BFM_AXI)
set XDC_DIR      $::env(XDC_DIR)
set DATA_TYPE    $::env(DATA_TYPE)

set DIR_MOVER    $::env(DIR_MOVER)
set DIR_MOVER    $::env(DIR_MOVER)
set DIR_MAC      $::env(DIR_MAC)
if { "${DATA_TYPE}" == "FLOATING_POINT" } {
set DIR_MAC_CORES $::env(DIR_MAC_CORES)
}

#set_param board.repoPaths $::env(XILINX_VIVADO)/data/boards/board_files/zed

source ${DESIGN_NAME}.tcl

add_files -fileset constrs_1 ${XDC_DIR}/con-fmc_lpc_zed.xdc
add_files -fileset constrs_1 ${XDC_DIR}/fpga_etc.xdc
add_files -fileset constrs_1 ${XDC_DIR}/fpga_zed.xdc

make_wrapper -force -top -files [get_files ${PROJECT_DIR}/${PROJECT_NAME}.srcs/sources_1/bd/${DESIGN_NAME}/${DESIGN_NAME}.bd]
file copy -force ${PROJECT_DIR}/${PROJECT_NAME}.gen/sources_1/bd/${DESIGN_NAME}/hdl/${DESIGN_NAME}_wrapper.v ${DESIGN_NAME}_wrapper.v 
add_files -norecurse ${PROJECT_DIR}/${PROJECT_NAME}.gen/sources_1/bd/${DESIGN_NAME}/hdl/${DESIGN_NAME}_wrapper.v
add_files -norecurse ${DESIGN_NAME}_wrapper.v
set_property top ${DESIGN_NAME}_wrapper [current_fileset]

proc syn_impl { } {
    global PROJECT_DIR PROJECT_NAME DESIGN_NAME

    # run synth 
    launch_runs synth_1 -jobs 8
    wait_on_run synth_1

    # run imple 
    launch_runs impl_1 -to_step write_bitstream -jobs 8
    wait_on_run impl_1

    if {[file exists "${PROJECT_DIR}/${PROJECT_NAME}.runs/impl_1/${DESIGN_NAME}_wrapper.bit"]} {
         file copy -force ${PROJECT_DIR}/${PROJECT_NAME}.runs/impl_1/${DESIGN_NAME}_wrapper.bit ${DESIGN_NAME}_wrapper.bit
    } else {
         puts "ERROR not found ${PROJECT_DIR}/${PROJECT_NAME}.runs/impl_1/${DESIGN_NAME}_wrapper.bit"
    }
    if {[file exists "${PROJECT_DIR}/${PROJECT_NAME}.runs/impl_1/${DESIGN_NAME}_wrapper.ltx"]} {
         file copy -force ${PROJECT_DIR}/${PROJECT_NAME}.runs/impl_1/${DESIGN_NAME}_wrapper.ltx ${DESIGN_NAME}_wrapper.ltx
    }

    regenerate_bd_layout
    write_bd_layout -force -format pdf -orientation portrait ${DESIGN_NAME}.pdf
    write_hw_platform -fixed -include_bit -force -file ./xsa/${DESIGN_NAME}.xsa

    assign_bd_address -force -export_to_file AddressMap.cvs
    assign_bd_address -force -export_gui_to_file AddressMapGui.csv
}

if {[info exists env(GUI)] == 0} {
    set GUI 0
} else {
    set GUI $::env(GUI)
}

if { ${GUI} == 0 } {
    syn_impl
}
