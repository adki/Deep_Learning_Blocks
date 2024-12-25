#--------------------------------------------------------
# CLOCK
set_property PACKAGE_PIN Y9       [get_ports BOARD_CLK_IN] ;# 100Mhz
set_property IOSTANDARD  LVCMOS33 [get_ports BOARD_CLK_IN]

#--------------------------------------------------------
# BOARD RESET
set_property PACKAGE_PIN P16      [get_ports BOARD_RST_SW] ;#BTNC
set_property IOSTANDARD  LVCMOS25 [get_ports BOARD_RST_SW]

#--------------------------------------------------------
set_false_path -reset_path       -from         [get_ports BOARD_RST_SW]
create_clock   -name BOARD_CLK_IN -period 10.0 [get_ports BOARD_CLK_IN]

#--------------------------------------------------------
#set_property PACKAGE_PIN T22 [get_ports "LED[0]"];  # "LD0"
#set_property PACKAGE_PIN T21 [get_ports "LED[1]"];  # "LD1"
#set_property PACKAGE_PIN U22 [get_ports "LED[2]"];  # "LD2"
#set_property PACKAGE_PIN U21 [get_ports "LED[3]"];  # "LD3"
#set_property PACKAGE_PIN V22 [get_ports "LED[4]"];  # "LD4"
#set_property PACKAGE_PIN W22 [get_ports "LED[5]"];  # "LD5"
#set_property PACKAGE_PIN U19 [get_ports "LED[6]"];  # "LD6"
#set_property PACKAGE_PIN U14 [get_ports "LED[7]"];  # "LD7"

#--------------------------------------------------------
#set_property PACKAGE_PIN F22 [get_ports "SW[0]"];  # "SW0"
#set_property PACKAGE_PIN G22 [get_ports "SW[1]"];  # "SW1"
#set_property PACKAGE_PIN H22 [get_ports "SW[2]"];  # "SW2"
#set_property PACKAGE_PIN F21 [get_ports "SW[3]"];  # "SW3"
#set_property PACKAGE_PIN H19 [get_ports "SW[4]"];  # "SW4"
#set_property PACKAGE_PIN H18 [get_ports "SW[5]"];  # "SW5"
#set_property PACKAGE_PIN H17 [get_ports "SW[6]"];  # "SW6"
#set_property PACKAGE_PIN M15 [get_ports "SW[7]"];  # "SW7"
