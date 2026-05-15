# nexysa7-peripherals-test

Test firmware for the Digilent Nexys A7-100T FPGA board, exercising the on-board peripherals from a single VHDL design. The host PC drives the board over UART: send a start byte to begin sampling, a stop byte to halt, and the board streams back temperature and accelerometer readings.

## Peripherals covered

- **ADT7420** I²C temperature sensor — 13-bit temperature readout
- **ADXL362** SPI 3-axis accelerometer — X/Y/Z acceleration
- **UART** (USB-UART bridge) — command input and data output at 115200 baud

## Repository layout

- [rtl/](rtl/) — VHDL sources
  - [top.vhd](rtl/top.vhd) — top-level, wires the peripherals together
  - [adt7420_wrapper.vhd](rtl/adt7420_wrapper.vhd) — ADT7420 control FSM
  - [adxl362_wrapper.vhd](rtl/adxl362_wrapper.vhd) — ADXL362 control FSM
  - [i2c_master.vhd](rtl/i2c_master.vhd), [spi_master.vhd](rtl/spi_master.vhd) — bus masters
  - [uart_rx.vhd](rtl/uart_rx.vhd), [uart_tx.vhd](rtl/uart_tx.vhd) — UART primitives
  - [command_read.vhd](rtl/command_read.vhd) — decodes start/stop commands from UART
  - [data_xmit.vhd](rtl/data_xmit.vhd) — formats and transmits sample data
  - [periph_pkg.vhd](rtl/periph_pkg.vhd) — shared types and helpers
- [constraint/constr.xdc](constraint/constr.xdc) — Nexys A7-100T pin assignments
- [vivado/](vivado/) — build and program scripts
  - [build.tcl](vivado/build.tcl) / [build_bitstream.bat](vivado/build_bitstream.bat) — synthesize and implement
  - [program.tcl](vivado/program.tcl) / [program.bat](vivado/program.bat) — load bitstream to the board

## Build and program

From the `vivado/` directory:

```
build_bitstream.bat
program.bat
```

Both scripts assume Vivado is on PATH and the Nexys A7 is connected via USB.

## Default parameters

Set on the top-level generic map in [top.vhd](rtl/top.vhd):

- System clock: 100 MHz
- SPI clock: 1 MHz
- I²C clock: 400 kHz
- UART baud: 115200
