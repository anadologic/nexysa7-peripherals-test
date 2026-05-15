set script_dir [file dirname [file normalize [info script]]]
set repo_dir [file normalize [file join $script_dir ..]]
set build_dir [file join $script_dir build]
set project_name periph_nexys_a7_100t
set top_name top
set part_name xc7a100tcsg324-1

file mkdir $build_dir
create_project -force $project_name $build_dir -part $part_name

set_property target_language VHDL [current_project]
catch { set_property board_part digilentinc.com:nexys-a7-100t:part0:1.1 [current_project] }

add_files -norecurse [list \
    [file join $repo_dir rtl periph_pkg.vhd] \
    [file join $repo_dir rtl uart_rx.vhd] \
    [file join $repo_dir rtl uart_tx.vhd] \
    [file join $repo_dir rtl spi_master.vhd] \
    [file join $repo_dir rtl i2c_master.vhd] \
    [file join $repo_dir rtl moving_avg.vhd] \
    [file join $repo_dir rtl command_read.vhd] \
    [file join $repo_dir rtl data_xmit.vhd] \
    [file join $repo_dir rtl adxl362_wrapper.vhd] \
    [file join $repo_dir rtl adt7420_wrapper.vhd] \
    [file join $repo_dir rtl top.vhd] \
]

add_files -fileset constrs_1 -norecurse [file join $repo_dir constraint constr.xdc]
set_property top $top_name [current_fileset]
update_compile_order -fileset sources_1

launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    error "Synthesis did not complete"
}

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    error "Implementation or bitstream generation did not complete"
}

set bit_file [file join $build_dir $project_name.runs impl_1 ${top_name}.bit]
file copy -force $bit_file [file join $script_dir ${top_name}.bit]
puts "Bitstream written to [file join $script_dir ${top_name}.bit]"
