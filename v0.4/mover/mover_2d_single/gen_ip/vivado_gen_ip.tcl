if {[info exists env(DEVICE)] == 0} {
     set DEVICE xc7z020clg484-1
} else {
     set DEVICE $::env(DEVICE)
}
if {[info exists env(MODULE)] == 0} {
     set MODULE mover_2d
} else {
     set MODULE $::env(MODULE)
}
if {[info exists env(DESCRIPTION)] == 0} {
     set DESCRIPTION ${MODULE}
} else {
     set DESCRIPTION $::env(DESCRIPTION)
}

create_project ${MODULE} . -part ${DEVICE} -force

read_verilog  "../rtl/verilog/mover_2d.v"

ipx::package_project -root_dir . -vendor future-ds.com\
                     -library user -taxonomy /UserIP\
                     -import_files "../rtl/verilog/mover_2d.v"

set_property name         ${MODULE}      [ipx::current_core]
set_property display_name ${MODULE}      [ipx::current_core]
set_property description  ${DESCRIPTION} [ipx::current_core]
set_property company_url  "http://www.future-ds.com" [ipx::current_core]
set_property version       1.0 [ipx::current_core]
set_property core_revision 1   [ipx::current_core]

ipx::add_bus_interface S_APB [ipx::current_core]
ipx::add_port_map PENABLE [ipx::get_bus_interfaces S_APB -of_objects [ipx::current_core]]
ipx::add_port_map PWRITE  [ipx::get_bus_interfaces S_APB -of_objects [ipx::current_core]]
ipx::add_port_map PRDATA  [ipx::get_bus_interfaces S_APB -of_objects [ipx::current_core]]
ipx::add_port_map PADDR   [ipx::get_bus_interfaces S_APB -of_objects [ipx::current_core]]
ipx::add_port_map PWDATA  [ipx::get_bus_interfaces S_APB -of_objects [ipx::current_core]]
ipx::add_port_map PSEL    [ipx::get_bus_interfaces S_APB -of_objects [ipx::current_core]]
ipx::add_port_map PREADY  [ipx::get_bus_interfaces S_APB -of_objects [ipx::current_core]]
ipx::add_port_map PSLVERR [ipx::get_bus_interfaces S_APB -of_objects [ipx::current_core]]

set_property abstraction_type_vlnv xilinx.com:interface:apb_rtl:1.0 [ipx::get_bus_interfaces S_APB -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:apb:1.0 [ipx::get_bus_interfaces S_APB -of_objects [ipx::current_core]]
set_property display_name APB [ipx::get_bus_interfaces S_APB -of_objects [ipx::current_core]]
set_property description {APB BUS} [ipx::get_bus_interfaces S_APB -of_objects [ipx::current_core]]
set_property physical_name S_APB_PENABLE [ipx::get_port_maps PENABLE -of_objects [ipx::get_bus_interfaces S_APB -of_objects [ipx::current_core]]]
set_property physical_name S_APB_PWRITE  [ipx::get_port_maps PWRITE  -of_objects [ipx::get_bus_interfaces S_APB -of_objects [ipx::current_core]]]
set_property physical_name S_APB_PRDATA  [ipx::get_port_maps PRDATA  -of_objects [ipx::get_bus_interfaces S_APB -of_objects [ipx::current_core]]]
set_property physical_name S_APB_PADDR   [ipx::get_port_maps PADDR   -of_objects [ipx::get_bus_interfaces S_APB -of_objects [ipx::current_core]]]
set_property physical_name S_APB_PWDATA  [ipx::get_port_maps PWDATA  -of_objects [ipx::get_bus_interfaces S_APB -of_objects [ipx::current_core]]]
set_property physical_name S_APB_PSEL    [ipx::get_port_maps PSEL    -of_objects [ipx::get_bus_interfaces S_APB -of_objects [ipx::current_core]]]
set_property physical_name S_APB_PREADY  [ipx::get_port_maps PREADY  -of_objects [ipx::get_bus_interfaces S_APB -of_objects [ipx::current_core]]]
set_property physical_name S_APB_PSLVERR [ipx::get_port_maps PSLVERR -of_objects [ipx::get_bus_interfaces S_APB -of_objects [ipx::current_core]]]

ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums  [ipx::current_core]
ipx::save_core         [ipx::current_core]
ipx::check_integrity -quiet [ipx::current_core]

set_property  ip_repo_paths  ./  [current_project]
update_ip_catalog -rebuild 

if { $::env(GUI) == 0 } {
    exit
}
