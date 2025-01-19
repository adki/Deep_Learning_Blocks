if {[info exists env(FPGA_TYPE)] == 0} {
     set FPGA_TYPE z7
} else {
     set FPGA_TYPE $::env(FPGA_TYPE)
}
if {[info exists env(PART)] == 0} {
     set PART xc7z020clg484-1
} else {
     set PART $::env(PART)
}
if {[info exists env(MODULE)] == 0} {
     set MODULE  mover_2d
} else {
     set MODULE $::env(MODULE)
}
if {[info exists env(DIR_RTL)] == 0} {
     set DIR_RTL  ../../rtl/verilog
} else {
     set DIR_RTL $::env(DIR_RTL)
}
if {[info exists env(DIR_SYN)] == 0} {
     set DIR_SYN  ../../syn/vivado.$::env(FPGA_TYPE)
} else {
     set DIR_SYN $::env(DIR_SYN)
}
set TOP_FILE ${DIR_RTL}/${MODULE}_wrapper.v
set TOP_EDIF ${DIR_SYN}/${MODULE}.edn

create_project ${MODULE} . -part ${PART} -force

set EDN_LIST [ glob "${DIR_SYN}/*.edn" ]
add_files "${TOP_FILE}\
           ${EDN_LIST}"

set_property top ${MODULE} [current_fileset]
#set_property top_lib xil_defaultlib [current_fileset]
#set_property top_file ${TOP_FILE} [current_fileset]
#update_compile_order -fileset sources_1

#### packing IP
ipx::package_project -root_dir . -vendor future-ds.com\
                     -force\
                     -force_update_compile_order\
                     -library user -taxonomy /UserIP\
                     -generated_files\
                     -import_files\
                     ${TOP_FILE}

foreach f ${EDN_LIST} {
    file copy -force $f src
}

#set_property widget {textEdit} [ipgui::get_guiparamspec -name "DATA_TYPE" -component [ipx::current_core] ]
#set_property value $::env(DATA_TYPE) [ipx::get_user_parameters DATA_TYPE -of_objects [ipx::current_core]]
#set_property value $::env(DATA_TYPE) [ipx::get_hdl_parameters DATA_TYPE -of_objects [ipx::current_core]]

set_property name          ${MODULE} [ipx::current_core]
set_property display_name  ${MODULE} [ipx::current_core]
set_property description   ${MODULE} [ipx::current_core]
set_property company_url   "http://www.future-ds.com" [ipx::current_core]
set_property version       1.0 [ipx::current_core]
set_property core_revision 1   [ipx::current_core]

ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums  [ipx::current_core]
ipx::save_core         [ipx::current_core]
ipx::check_integrity -quiet [ipx::current_core]

set_property  ip_repo_paths  ./  [current_project]
update_ip_catalog -rebuild 

#---------------------------------------------------------
if {$::env(GUI) == 0} {
  exit
}

#---------------------------------------------------------
# TCL> help ipx::*
# TCL> help ipx::package_project
#
# ipx::package_project
# 
# Description: 
# Package the current project
# 
# Syntax: 
# ipx::package_project  [-root_dir <arg>] [-vendor <arg>] [-library <arg>]
#                       [-name <arg>] [-version <arg>] -taxonomy <args>
#                       [-import_files] [-set_current <arg>] [-force]
#                       [-force_update_compile_order]
#                       [-archive_source_project <arg>] [-quiet] [-verbose]
#                       [<component>]
# 
# Usage: 
#   Name                           Description
#   ------------------------------------------
#   [-root_dir]                    User specified root directory for 
#                                  component.xml
#   [-vendor]                      User specified vendor of the IP VLNV
#   [-library]                     User specified library of the IP VLNV
#   [-name]                        User specified name of the IP VLNV
#   [-version]                     User specified version of the IP VLNV
#   -taxonomy                      User specified taxonomy for the IP
#   [-import_files]                If true, import remote IP files into the IP 
#                                  structure.
#   [-set_current]                 Set the core as the current core.
#   [-force]                       Override existing packaged component.xml.
#   [-force_update_compile_order]  Force the packager to invoke the old 
#                                  behaviour of reordering and disabling files 
#                                  as necessary (This will override a manually 
#                                  set compile order).
#   [-archive_source_project]      Archives the source project to be used when 
#                                  editing the IP later.
#   [-quiet]                       Ignore command errors
#   [-verbose]                     Suspend message limits during command 
#                                  execution
#   [<component>]                  Core object
