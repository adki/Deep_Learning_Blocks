if {[info exists env(VIVADO_VER)] == 0} {
     set VIVADO_VER vivado.2019.2
} else {
     set VIVADO_VER $::env(VIVADO_VER)
}
if {[info exists env(PROJECR_DIR)] == 0} {
     set PROJECT_DIR project_1
} else {
     set PROJECT_DIR $::env(PROJECT_DIR)
}
if {[info exists env(PROJECR_NAME)] == 0} {
     set PROJECT_NAME project_1
} else { 
     set PROJECT_NAME $::env(PROJECT_NAME)
}
if {[info exists env(PLATFORM)] == 0} {
     set PLATFORM linux
} else { 
     set PLATFORM $::env(PLATFORM)
}

if {[info exists env(DEVICE)] == 0} { 
     set DEVICE xc7z020clg484-1
} else {
     set DEVICE $::env(DEVICE)
}
if {[info exists env(FPGA_TYPE)] == 0} {
     set FPGA_TYPE  z7
} else {
     set FPGA_TYPE $::env(FPGA_TYPE)
}
if {[info exists env(BOARD)] == 0} {
     set BOARD zed
} else {
     set BOARD $::env(BOARD)
}
if {[info exists env(BOARD_TYPE)] == 0} {
     set BOARD_TYPE BOARD_ZED
} else {
     set BOARD_TYPE $::env(BOARD_TYPE)
}
if {[info exists env(DIR_NPU)] == 0} {
     set DIR_NPU ../../../..
} else {
     set DIR_NPU $::env(DIR_NPU)
}
if {[info exists env(DIR_FIP)] == 0} {
     set DIR_FIP ../../iplib
} else {
     set DIR_FIP $::env(DIR_FIP)
}
if {[info exists env(DIR_RTL)] == 0} {
     set DIR_RTL "../../design/verilog"
} else {
     set DIR_RTL $::env(DIR_RTL)
}
if {[info exists env(DIR_XDC)] == 0} {
     set DIR_XDC "xdc"
} else {
     set DIR_XDC $::env(DIR_XDC)
}
if {[info exists env(TOP_MODULE)] == 0} { 
     set TOP_MODULE fpga
} else { 
     set TOP_MODULE $::env(TOP_MODULE)
}
if {[info exists $::env(DATA_TYPE)] == 0} { 
     set DATA_TYPE FLOATING_POINT
} else { 
     set DATA_TYPE $::env(DATA_TYPE)
}
if {[info exists env(EDIF)] == 0} {
     set EDIF fpga.edn
} else {
     set EDIF $::env(EDIF)
}
if {[info exists env(XDC_ILA)] == 0} { 
     set XDC_ILA 0
} else { 
     set XDC_ILA $::env(XDC_ILA)
}
if {[info exists env(XDC_TARGET)] == 0} { 
     set XDC_TARGET target.xdc
} else { 
     set XDC_TARGET $::env(XDC_TARGET)
}
if {[info exists env(WORK)] == 0} { 
     set WORK work
} else { 
     set WORK $::env(WORK)
}
if {[info exists env(RIGOR)] == 0} {
     set RIGOR 0
} else {
     set RIGOR $::env(RIGOR)
}
if {[info exists env(GUI)] == 0} {
     set GUI 0
} else {
     set GUI $::env(GUI)
}
if {[info exists env(SYN_ONLY)]==0} {
     set SYN_ONLY     0
} else {
     set SYN_ONLY     $::env(SYN_ONLY)
}
if {[info exists env(ILA)] == 0} {
     set ILA 0
} else {
     set ILA $::env(ILA)
}
if { ${ILA} == 1} {
   if {[info exists env(BIT)] == 0} {
        set BIT fpga_ila.bit
   } else {
        set BIT $::env(BIT)
   }
} else {
   if {[info exists env(BIT)] == 0} {
        set BIT fpga.bit
   } else {
        set BIT $::env(BIT)
   }
}

#=====================================================================
if {[file exists ${PROJECT_DIR}] == 1} {
       puts "Project sub-dirctory exists: ${PROJECT_DIR}\n"
       open_project ${PROJECT_DIR}/${PROJECT_NAME}.xpr
} else {
       puts "Project sub-dirctory create: ${PROJECT_NAME}\n"
       create_project -force -part ${DEVICE} ${PROJECT_NAME} ${PROJECT_DIR}
}

#=====================================================================
proc number_of_processor {} {
    global tcl_platform env
    switch ${tcl_platform(platform)} {
        "windows" {
            return $env(NUMBER_OF_PROCESSORS)
        }

        "unix" {
            if {![catch {open "/proc/cpuinfo"} f]} {
                set cores [regexp -all -line {^processor\s} [read $f]]
                close $f
                if {$cores > 0} {
                    return $cores
                }
            }
        }

        "Darwin" {
            if {![catch {exec {*}$sysctl -n "hw.ncpu"} cores]} {
                return $cores
            }
        }

        default {
            puts "Unknown System"
            return 1
        }
    }
}
set NPROC [expr int([number_of_processor])]
if { ${NPROC}>=8 } {
   set_param general.maxThreads [expr int(${NPROC}/2)]
} else {
   set_param general.maxThreads ${NPROC}
}
puts "num_of_processor=[number_of_processor]"
puts "num_of_thread=[get_param general.MaxThreads]"

puts ${DATA_TYPE}
#=====================================================================
set DIR_CURRENT       "."
set DIR_BENCH         "../../bench/verilog"
set DIR_BEH           "../../beh/verilog"
set DIR_BFM           "$::env(CONFMC_HOME)/hwlib/trx_axi"
#set DIR_BFM           "/home/adki/work/projects/ez-usb-fx3/hwlib/trx_axi"
set DIR_MEM           "${DIR_FIP}/mem_axi/rtl/verilog"
set DIR_MEM_BRAM      "${DIR_FIP}/mem_axi/bram_simple_dual_port/$FPGA_TYPE/$VIVADO_VER"
if { "${BOARD_TYPE}" == "BOARD_NEXYS_VIDEO" } {
set DIR_CFG_VADJ      "${DIR_FIP}/cfg_vadj/rtl/verilog"
}
set DIR_CONVOLUTION   "${DIR_NPU}/convolution/convolution_2d_single/rtl/verilog"
set DIR_POOLING       "${DIR_NPU}/pooling/pooling_2d_single/rtl/verilog"
set DIR_LINEAR        "${DIR_NPU}/linear/linear_1d_many/rtl/verilog"
set DIR_MOVER         "${DIR_NPU}/mover/mover_2d_single/rtl/verilog"
if { ${DATA_TYPE} == "FLOATING_POINT" } {
set DIR_MAC           "${DIR_NPU}/mac/mac_float/rtl/verilog"
set DIR_MAC_CORE      "${DIR_NPU}/mac/mac_float/core/$FPGA_TYPE/$VIVADO_VER"
} elseif { ${DATA_TYPE} == "FIXED_POINT" } {
set DIR_MAC           "${DIR_NPU}/mac/mac_integer/rtl/verilog"
} else {
set DIR_MAC           "${DIR_NPU}/mac/mac_fixed/rtl/verilog"
}
set DIR_MAC_TREE      "${DIR_NPU}/mac/tree_mac/rtl/verilog"

#=====================================================================
#add_files "${DIR_BFM}/syn/vivado.z7/bfm_axi.edif
add_files "$::env(DIR_BFM_EDIF)/bfm_axi.edif
           ${DIR_MEM_BRAM}/bram_simple_dual_port_32_64KB/bram_simple_dual_port_32_64KB.xci
           ${DIR_MEM_BRAM}/bram_simple_dual_port_32_32KB/bram_simple_dual_port_32_32KB.xci
           ${DIR_MEM_BRAM}/bram_simple_dual_port_32_16KB/bram_simple_dual_port_32_16KB.xci"
if { ${DATA_TYPE} == "FLOATING_POINT" } {
add_files "${DIR_MAC_CORE}/fp32_multiplier/fp32_multiplier.xci
           ${DIR_MAC_CORE}/fp32_accumulator/fp32_accumulator.xci
           ${DIR_MAC_CORE}/fp32_adder/fp32_adder.xci
           ${DIR_MAC_CORE}/fp16_multiplier/fp16_multiplier.xci
           ${DIR_MAC_CORE}/fp16_accumulator/fp16_accumulator.xci
           ${DIR_MAC_CORE}/fp16_adder/fp16_adder.xci"
}

set VERILOG_DIR_LIST "
                ${DIR_CURRENT}
                ${DIR_RTL}
                ${DIR_MEM}
                ${DIR_MEM_BRAM}
                ${DIR_CONVOLUTION}
                ${DIR_POOLING}
                ${DIR_LINEAR}
                ${DIR_MAC}
                ${DIR_MAC_CORE}
                ${DIR_MAC_TREE}
                "
if { "${BOARD_TYPE}" == "BOARD_NEXYS_VIDEO" } {
append VERILOG_DIR_LIST " ${DIR_CFG_VADJ} "
}
append VERILOG_DIR_LIST " ${DIR_BFM}/rtl/verilog"
set_property verilog_dir ${VERILOG_DIR_LIST} [current_fileset]

add_files " ${DIR_CURRENT}/syn_define.v
            ${DIR_RTL}/fpga.v
            ${DIR_MEM}/bram_axi.v
            ${DIR_CONVOLUTION}/convolution_2d.v
            ${DIR_POOLING}/pooling_2d.v
            ${DIR_LINEAR}/linear_1d.v
            ${DIR_MOVER}/mover_2d.v
            ${DIR_MAC}/mac_core.v
            ${DIR_MAC_TREE}/tree_mac.v
            "
if { "${BOARD_TYPE}" == "BOARD_NEXYS_VIDEO" } {
add_files "${DIR_CFG_VADJ}/cfg_vadj.v"
}

add_files "${DIR_BFM}/rtl/verilog/bfm_axi_stub.v"

#=====================================================================
add_files -fileset constrs_1 "${DIR_XDC}/con-fmc_lpc_${BOARD}.xdc"
add_files -fileset constrs_1 "${DIR_XDC}/fpga_${BOARD}.xdc"
if {[file exists "additional.xdc"] == 1} {
    add_files -fileset constrs_1 "additional.xdc"
}

set fid [ open ${XDC_TARGET} w+ ]
close $fid
set_property target_constrs_file ${XDC_TARGET} [current_fileset -constrset]

#=====================================================================
# macros
set VERILOG_DEFINE_LIST " SYN=1
                          VIVADO=1
                          ${FPGA_TYPE}=1
                          ${BOARD_TYPE}=1
                          AMBA_AXI4=1
                        "
set_property verilog_define ${VERILOG_DEFINE_LIST} [current_fileset]

#=====================================================================
set_property is_global_include true [get_files  ${DIR_CURRENT}/syn_define.v]
#=====================================================================
# Manual Compile Order mode
set_property source_mgmt_mode None [current_project]
set_property top_file ${DIR_RTL}/fpga.v [current_fileset]
reorder_files -fileset [current_fileset] -front ${DIR_CURRENT}/syn_define.v
reorder_files -fileset [current_fileset] -after ${DIR_CURRENT}/syn_define.v ${DIR_RTL}/fpga.v

#=====================================================================
set_property top ${TOP_MODULE} [current_fileset]
update_compile_order -fileset sources_1
#get_files -compile_order sources -used_in synthesis
#update_compile_order -fileset sim_1
#get_files -compile_order sources -used_in simulation

#=====================================================================
if { ${ILA} == 0 } {
    reset_run synth_1
    launch_runs synth_1
    wait_on_run synth_1
    if { ${SYN_ONLY} == 0 } {
        set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
        set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
        set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
        set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
        set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
        set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
        launch_runs impl_1 -to_step write_bitstream
        wait_on_run impl_1
        puts "Implementation done!"
        open_run impl_1
        write_bitstream -force ${BIT}
    }
}

if { $::env(GUI) == 0 } {
    exit
}

#=====================================================================
# https://grittyengineer.com/vivado-project-mode-tcl-script/
#########################################################################
