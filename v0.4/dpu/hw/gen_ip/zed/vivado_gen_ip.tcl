create_project bfm_axi_if . -part xc7z020clg484-1 -force

read_edif  "
        ../../rtl/zed/bfm_axi.edif
     "

read_verilog  "
        ../../rtl/zed/bfm_axi_if.v
        ../../rtl/zed/bfm_axi.v
     "

#### packing IP
ipx::package_project -root_dir . -vendor future-ds.com -library user -taxonomy /UserIP\
                     -import_files "../../rtl/zed/bfm_axi_if.v ../../rtl/zed/bfm_axi.v ../../rtl/zed/bfm_axi.edif"
set_property name bfm_axi_if [ipx::current_core]
set_property display_name bfm_axi_if [ipx::current_core]
set_property name bfm_axi_if [ipx::current_core]
set_property core_revision 2 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
set_property  ip_repo_paths  ./  [current_project]
update_ip_catalog -rebuild 

ipx::check_integrity -quiet [ipx::current_core]


