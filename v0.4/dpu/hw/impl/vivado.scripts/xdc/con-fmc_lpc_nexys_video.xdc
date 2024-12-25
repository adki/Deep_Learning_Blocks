########################################################
## USB Host Interface Signal
## nexys video FMC
########################################################

set_property PACKAGE_PIN K18 [get_ports "SL_DT[0]"];  
set_property PACKAGE_PIN K19 [get_ports "SL_DT[1]"];  
set_property PACKAGE_PIN J20 [get_ports "SL_DT[2]"];  
set_property PACKAGE_PIN J21 [get_ports "SL_DT[3]"];  
set_property PACKAGE_PIN M18 [get_ports "SL_DT[4]"];  
set_property PACKAGE_PIN L18 [get_ports "SL_DT[5]"];  
set_property PACKAGE_PIN N18 [get_ports "SL_DT[6]"];  
set_property PACKAGE_PIN N19 [get_ports "SL_DT[7]"];  
set_property PACKAGE_PIN N20 [get_ports "SL_DT[8]"];  
set_property PACKAGE_PIN M20 [get_ports "SL_DT[9]"];  
set_property PACKAGE_PIN M21 [get_ports "SL_DT[10]"]; 
set_property PACKAGE_PIN L21 [get_ports "SL_DT[11]"]; 
set_property PACKAGE_PIN N22 [get_ports "SL_DT[12]"]; 
set_property PACKAGE_PIN M22 [get_ports "SL_DT[13]"]; 
set_property PACKAGE_PIN M13 [get_ports "SL_DT[14]"]; 
set_property PACKAGE_PIN L13 [get_ports "SL_DT[15]"]; 
set_property PACKAGE_PIN L16 [get_ports "SL_DT[16]"]; 
set_property PACKAGE_PIN K16 [get_ports "SL_DT[17]"]; 
set_property PACKAGE_PIN G17 [get_ports "SL_DT[18]"]; 
set_property PACKAGE_PIN G18 [get_ports "SL_DT[19]"]; 
set_property PACKAGE_PIN B17 [get_ports "SL_DT[20]"]; 
set_property PACKAGE_PIN B18 [get_ports "SL_DT[21]"]; 
set_property PACKAGE_PIN D17 [get_ports "SL_DT[22]"]; 
set_property PACKAGE_PIN C17 [get_ports "SL_DT[23]"]; 
set_property PACKAGE_PIN A18 [get_ports "SL_DT[24]"]; 
set_property PACKAGE_PIN A19 [get_ports "SL_DT[25]"]; 
set_property PACKAGE_PIN F19 [get_ports "SL_DT[26]"]; 
set_property PACKAGE_PIN F20 [get_ports "SL_DT[27]"]; 
set_property PACKAGE_PIN D19 [get_ports "SL_DT[28]"]; 
set_property PACKAGE_PIN E21 [get_ports "SL_DT[29]"]; 
set_property PACKAGE_PIN D21 [get_ports "SL_DT[30]"]; 
set_property PACKAGE_PIN B21 [get_ports "SL_DT[31]"]; 

set_property PACKAGE_PIN H22 [get_ports "SL_AD[0]"];   
set_property PACKAGE_PIN J22 [get_ports "SL_AD[1]"];   

set_property PACKAGE_PIN M15 [get_ports "SL_PCLK"];  
set_property PACKAGE_PIN M16 [get_ports "SL_CS_N"];  
set_property PACKAGE_PIN H20 [get_ports "SL_WR_N"];  
set_property PACKAGE_PIN G20 [get_ports "SL_OE_N"];  
set_property PACKAGE_PIN K21 [get_ports "SL_RD_N"];  
set_property PACKAGE_PIN K22 [get_ports "SL_FLAGA"];   
set_property PACKAGE_PIN L14 [get_ports "SL_FLAGB"];   
set_property PACKAGE_PIN L15 [get_ports "SL_FLAGC"];   
set_property PACKAGE_PIN L20 [get_ports "SL_FLAGD"];  

set_property PACKAGE_PIN L19 [get_ports "SL_PKTEND_N"]; 
set_property PACKAGE_PIN K17 [get_ports "SL_RST_N"];  

set_property PACKAGE_PIN J17 [get_ports "SL_MODE[0]"]; 
set_property PACKAGE_PIN E19 [get_ports "SL_MODE[1]"]; 

set_property IOSTANDARD LVCMOS18    [get_ports {SL_*}]
set_property SLEW       FAST        [get_ports {SL_*}]

set_property IOB TRUE  [get_cells {u_dut/*/u_gpif2mst/SL_DT_O*}]
set_property IOB TRUE  [get_cells {u_dut/*/u_gpif2mst/SL_RD_N}]
set_property IOB TRUE  [get_cells {u_dut/*/u_gpif2mst/SL_WR_N}]
set_property IOB TRUE  [get_cells {u_dut/*/u_gpif2mst/SL_OE_N}]
set_property IOB TRUE  [get_cells {u_dut/*/u_gpif2mst/SL_PKTEND_N}]
set_property IOB TRUE  [get_cells {u_dut/*/u_gpif2mst/SL_AD*}]

set_property IOB TRUE [get_port SL_DT*]
