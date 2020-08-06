#XDC for kintex hpc
# part XC7K420T

#####   clocks          #####

set_property PACKAGE_PIN U24 [get_ports clk_100] ;#the sch say that is clk_p
set_property IOSTANDARD LVCMOS25 [get_ports clk_100]

set_property PACKAGE_PIN T25 [get_ports clk_133] ;#the sch says clk_p0
set_property IOSTANDARD LVCMOS25 [get_ports clk_133]

##### gtx-sfp clocks    #####

#### 156.25 clk         #####

set_property PACKAGE_PIN G8 [get_ports sfp_mgt_refclk_p] ;#MGTRECLK1_P_117
set_property PACKAGE_PIN G7 [get_ports sfp_mgt_refclk_n] ;#MGTRECLK1_N_117

#not sure if the pcs/pma block needs this 
# 156.25 MHz MGT reference clock
#create_clock -period 6.4 -name sfp_mgt_refclk [get_ports sfp_mgt_refclk_p]


#### Buttons            #####

set_property PACKAGE_PIN A16 [get_ports btn1]
set_property IOSTANDARD LVCMOS25 [get_ports btn1]
set_false_path -from [get_ports btn1]


#### LEDS               ####
#### there are more of this ones
set_property PACKAGE_PIN H24 [get_ports {leds[0]}]
set_property PACKAGE_PIN H25 [get_ports {leds[1]}]
set_property PACKAGE_PIN H26 [get_ports {leds[2]}]
set_property PACKAGE_PIN G27 [get_ports {leds[3]}]
set_property IOSTANDARD LVCMOS15

#### I2C                ####
#### I dont think that we need to enable then via i2c
set_property PACKAGE_PIN C16 [get_ports I2C_SCL]
set_property PACKAGE_PIN C17 [get_ports I2C_SDA]

#### SFP+               ####

#### BANK 117           ####
set_property PACKAGE_PIN D10 [get_ports sfp_a_rx_p] ;#MGTXRXP1
set_property PACKAGE_PIN D9  [get_ports sfp_a_rx_n] ;#MGTXRXN1
set_property PACKAGE_PIN A8  [get_ports sfp_a_tx_p] ;#MGTXTXP1
set_property PACKAGE_PIN A7  [get_ports sfp_a_tx_n] ;#MGTXTXN1

set_property PACKAGE_PIN F10 [get_ports sfp_b_rx_p] ;#MGTXRXP0
set_property PACKAGE_PIN F9  [get_ports sfp_b_rx_n] ;#MGTXRXN0
set_property PACKAGE_PIN C8  [get_ports sfp_b_tx_p] ;#MGTXTXP0
set_property PACKAGE_PIN C7  [get_ports sfp_b_tx_n] ;#MGTXTXN0

#### BANK 118           ####   
set_property PACKAGE_PIN A17 [get_ports sfp_a_tx_disable]   ;#1 or open: disable
set_property IOSTANDARD LVCMOS25 [get_ports sfp_a_tx_disable]
set_property PACKAGE_PIN D14 [get_ports sfp_b_tx_disable]
set_property IOSTANDARD LVCMOS25 [get_ports sfp_b_tx_disable]


set_property PACKAGE_PIN B15 [get_ports sfp_a_rate]         ;# 0 or open:reduce bw; 1:complete bw         
set_property IOSTANDARD LVCMOS25 [get_ports sfp_a_rate]
set_property PACKAGE_PIN A14 [get_ports sfp_b_rate]         
set_property IOSTANDARD LVCMOS25 [get_ports sfp_b_rate]  

### the next ones are pull up ??
### the example with the kintex only uses
### the sfp rate and sfp disable
 
set_property PACKAGE_PIN C15 [get_ports sfp_a_sda]
set_property PACKAGE_PIN A15 [get_ports sfp_a_sck]
set_property PACKAGE_PIN C14 [get_ports sfp_b_sda]
set_property PACKAGE_PIN B14 [get_ports sfp_b_sck]


#### the example defines the clock group
#set_clock_groups -name async_clock -asynchronous -group [get_clocks [get_clocks -of_objects [get_pins clk_wiz_0/inst/mmcm_adv_inst/CLKOUT0]]] -group [get_clocks gtrefclk0_p]
### where gtx_clkp is sfp_clk_p