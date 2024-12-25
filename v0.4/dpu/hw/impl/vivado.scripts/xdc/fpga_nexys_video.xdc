set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

# CLOCK
set_property PACKAGE_PIN R4 [get_ports BOARD_CLK_IN] ;# 100Mhz
set_property IOSTANDARD LVCMOS33 [get_ports BOARD_CLK_IN]

#--------------------------------------------------------
# BOARD RESET
# It should be Vadj.
set_property PACKAGE_PIN B22      [get_ports BOARD_RST_SW] ;#BTNC
#set_property PACKAGE_PIN D22      [get_ports BOARD_RST_SW] ;#BTND
set_property IOSTANDARD  LVCMOS18 [get_ports BOARD_RST_SW]

#--------------------------------------------------------
set_false_path -reset_path       -from         [get_ports BOARD_RST_SW]
create_clock   -name BOARD_CLK_IN -period  10.00 [get_ports BOARD_CLK_IN]

#--------------------------------------------------------
# make sure 'cfg_vadj' set Vadj 1.8V.
set_property -dict { PACKAGE_PIN AA13  IOSTANDARD LVCMOS18 } [get_ports { SET_VADJ[0] }]; #IO_L3P_T0_DQS_13 Sch=set_vadj[0]
set_property -dict { PACKAGE_PIN AB17  IOSTANDARD LVCMOS18 } [get_ports { SET_VADJ[1] }]; #IO_L2N_T0_13 Sch=set_vadj[1]
set_property -dict { PACKAGE_PIN V14   IOSTANDARD LVCMOS18 } [get_ports { VADJ_EN }]; #IO_L13N_T2_MRCC_13 Sch=vadj_en

#set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS18 } [get_ports { LED0 }]; #IO_L15P_T2_DQS_13 Sch=led[0]

###--------------------------------------------------------
### CLOCK
##set_property PACKAGE_PIN R4 [get_ports USER_CLK100MHZ_IN] ;# 100Mhz
##set_property IOSTANDARD LVCMOS33 [get_ports USER_CLK100MHZ_IN]
##
###--------------------------------------------------------
### BOARD RESET
### USER_RST0_N U25
### USER_RST1_N T25
##set_property PACKAGE_PIN B22      [get_ports USER_RST_SW_N]
##set_property IOSTANDARD  LVCMOS12 [get_ports USER_RST_SW_N]
##
###--------------------------------------------------------
##set_false_path -reset_path       -from         [get_ports USER_RST_SW_N]
##create_clock   -name USER_CLK100MHZ_IN -period  10.00 [get_ports USER_CLK100MHZ_IN]
##
