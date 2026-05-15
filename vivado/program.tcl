set script_dir [file dirname [file normalize [info script]]]
set bit_file [file join $script_dir top.bit]

if {![file exists $bit_file]} {
    error "Bitstream not found: $bit_file. Run build_bitstream.bat first."
}

open_hw_manager
connect_hw_server
open_hw_target

set hw_device [lindex [get_hw_devices xc7a100t*] 0]
if {$hw_device eq ""} {
    error "No xc7a100t device found. Check that the Nexys A7 100T is connected and powered."
}

current_hw_device $hw_device
refresh_hw_device -update_hw_probes false $hw_device
set_property PROGRAM.FILE $bit_file $hw_device
program_hw_devices $hw_device
refresh_hw_device $hw_device

puts "Programmed $hw_device with $bit_file"
