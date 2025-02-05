#-------------------------------------------------------------------------------
if {[info exists env(PART)] == 0} {
     set PART xc7z020clg484-1
} else {
     set PART $::env(PART)
}
if {[info exists env(MODULE)] == 0} {
     set MODULE fp32_accmulator
} else {
     set MODULE $::env(MODULE)
}
if {[info exists env(GUI)] == 0} {
     set GUI 0
} else {
     set GUI $::env(GUI)
}

set_part ${PART}
#-------------------------------------------------------------------------------
create_project managed_ip_project managed_ip_project -part ${PART} -ip -force
set_property target_simulator XSim [current_project]
set_property simulator_language Verilog [current_project]
create_ip -name floating_point -vendor xilinx.com -library ip -version 7.1\
          -module_name ${MODULE} -dir [pwd] -force
set_property -dict [list CONFIG.Operation_Type {Accumulator}\
                         CONFIG.Add_Sub_Value {Add}\
                         CONFIG.Maximum_Latency {false}\
                         CONFIG.Has_ARESETn {true}\
                         CONFIG.C_Has_ACCUM_OVERFLOW {true}\
                         CONFIG.C_Has_ACCUM_INPUT_OVERFLOW {true}\
                         CONFIG.A_Precision_Type {Single}\
                         CONFIG.C_A_Exponent_Width {8}\
                         CONFIG.C_A_Fraction_Width {24}\
                         CONFIG.Result_Precision_Type {Single}\
                         CONFIG.C_Result_Exponent_Width {8}\
                         CONFIG.C_Result_Fraction_Width {24}\
                         CONFIG.C_Mult_Usage {Full_Usage}\
                         CONFIG.C_Optimization {Low_Latency}\
                         CONFIG.C_Accum_Msb {32}\
                         CONFIG.C_Accum_Lsb {-24}\
                         CONFIG.C_Accum_Input_Msb {32}\
                         CONFIG.C_Latency {3}\
                         CONFIG.C_Rate {1}\
                         CONFIG.Has_A_TLAST {true}\
                         CONFIG.RESULT_TLAST_Behv {Pass_A_TLAST}\
                         CONFIG.Has_A_TUSER {true}\
                         CONFIG.A_TUSER_Width {4}\
                   ] [get_ips ${MODULE}]
generate_target {instantiation_template} [get_files ${MODULE}.xci]
generate_target all [get_files  ${MODULE}.xci]
export_ip_user_files -of_objects [get_files ${MODULE}.xci] -no_script -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] ${MODULE}.xci]
launch_run -jobs 4 ${MODULE}_synth_1
wait_on_run ${MODULE}_synth_1
export_simulation -of_objects [get_files ${MODULE}/${MODULE}.xci]\
                  -directory ip_user_files/sim_scripts -force -quiet
#-------------------------------------------------------------------------------
if {${GUI} == 0} {
  exit
}
#-------------------------------------------------------------------------------
