set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clk }]; #IO_L12P_T1_MRCC_35 Sch=clk100mhz
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {clk}];

set_property -dict { PACKAGE_PIN C12   IOSTANDARD LVCMOS33 } [get_ports { rstn }]; #IO_L3P_T0_DQS_AD1P_15 Sch=cpu_resetn

set_property -dict { PACKAGE_PIN E15   IOSTANDARD LVCMOS33 } [get_ports { miso_i }]; #IO_L11P_T1_SRCC_15 Sch=acl_miso
set_property -dict { PACKAGE_PIN F14   IOSTANDARD LVCMOS33 } [get_ports { mosi_o }]; #IO_L5N_T0_AD9N_15 Sch=acl_mosi
set_property -dict { PACKAGE_PIN F15   IOSTANDARD LVCMOS33 } [get_ports { sclk_o }]; #IO_L14P_T2_SRCC_15 Sch=acl_sclk
set_property -dict { PACKAGE_PIN D15   IOSTANDARD LVCMOS33 } [get_ports { cs_o }]; #IO_L12P_T1_MRCC_15 Sch=acl_csn

set_property -dict { PACKAGE_PIN C4    IOSTANDARD LVCMOS33 } [get_ports { uart_rx_i }]; #IO_L7P_T1_AD6P_35 Sch=uart_txd_in
set_property -dict { PACKAGE_PIN D4    IOSTANDARD LVCMOS33 } [get_ports { uart_tx_o}]; #IO_L11N_T1_SRCC_35 Sch=uart_rxd_out

set_property -dict { PACKAGE_PIN C14   IOSTANDARD LVCMOS33 } [get_ports { scl_io }]; #IO_L1N_T0_AD0N_15 Sch=tmp_scl
set_property -dict { PACKAGE_PIN C15   IOSTANDARD LVCMOS33 } [get_ports { sda_io }]; #IO_L12N_T1_MRCC_15 Sch=tmp_sda