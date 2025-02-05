#-----------------------------------------------------------
if {[info exists env(DEVICE)] == 0} { 
     set DEVICE xc7z020clg484-1
} else {
     set DEVICE $::env(DEVICE)
}
if {[info exists env(WIDTH)] == 0} { 
     set WIDTH 32
} else { 
     set WIDTH $::env(WIDTH)
}
if {[info exists env(SIZEK)] == 0} { 
     set SIZEK 1024
} else { 
     set SIZEK $::env(SIZEK)
}
if {[info exists env(MODULE)] == 0} { 
     set MODULE bram_simple_dual_port_${WIDHT}_${SIZEK}KB
} else { 
     set MODULE $::env(MODULE)
}
if {[info exists env(GUI)] == 0} {
     set GUI 0
} else {
     set GUI $::env(GUI)
}

set_part ${DEVICE}
#-----------------------------------------------------------
create_project managed_ip_project managed_ip_project -part ${DEVICE} -ip -force
set_property simulator_language Verilog [current_project]
set_property target_simulator Questa [current_project]
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4\
          -module_name ${MODULE}\
          -dir [pwd] -force
set_property -dict [list CONFIG.Memory_Type {Simple_Dual_Port_RAM}\
                         CONFIG.Use_Byte_Write_Enable {true}\
                         CONFIG.Byte_Size {8}\
                         CONFIG.Assume_Synchronous_Clk {true}\
                         CONFIG.Write_Width_A ${WIDTH}\
                         CONFIG.Write_Depth_A [expr ${SIZEK}*1024/(${WIDTH}/8)]\
                         CONFIG.Read_Width_A ${WIDTH}\
                         CONFIG.Operating_Mode_A {WRITE_FIRST}\
                         CONFIG.Write_Width_B ${WIDTH}\
                         CONFIG.Read_Width_B ${WIDTH}\
                         CONFIG.Operating_Mode_B {READ_FIRST}\
                         CONFIG.Enable_B {Use_ENB_Pin}\
                         CONFIG.Register_PortA_Output_of_Memory_Primitives {false}\
                         CONFIG.Register_PortB_Output_of_Memory_Primitives {false}\
                         CONFIG.Port_B_Clock {100}\
                         CONFIG.Port_B_Write_Rate {0}\
                         CONFIG.Port_B_Enable_Rate {100}\
                   ] [get_ips ${MODULE}]
generate_target {instantiation_template} [get_files ${MODULE}.xci]
generate_target all [get_files  ${MODULE}.xci]
export_ip_user_files -of_objects [get_files ${MODULE}.xci] -no_script -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] ${MODULE}.xci]
launch_run -jobs 4 ${MODULE}_synth_1
wait_on_run ${MODULE}_synth_1
export_simulation -of_objects [get_files ${MODULE}/${MODULE}.xci]\
                  -directory ip_user_files/sim_scripts -force -quiet
if {${GUI} == 0} {
  exit
}
