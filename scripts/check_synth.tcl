set script_dir [file dirname [file normalize [info script]]]
set project_root [file dirname $script_dir]
set report_dir [file join $project_root ".synth"]
file mkdir $report_dir

create_project -in_memory -part xc7a35tcpg236-1
set_property target_language Verilog [current_project]

read_verilog -sv [list \
    [file join $project_root "rv32i_cpu.sv"] \
    [file join $project_root "rv32i_datapath.sv"] \
    [file join $project_root "instruction_mem.sv"] \
    [file join $project_root "data_mem.sv"] \
    [file join $project_root "rv32i_top.sv"]]

# First verify that the complete production hierarchy elaborates together.
synth_design -rtl -top rv32i_top -part xc7a35tcpg236-1
puts "PASS: production top RTL elaboration"
close_design

# Then implement the CPU alone so internal core timing is not optimized away.
synth_design -top rv32i_cpu -part xc7a35tcpg236-1 -mode out_of_context
create_clock -name cpu_clk -period 10.000 [get_ports clk]
set_false_path -from [get_ports rst]

opt_design
place_design
route_design

report_utilization -file [file join $report_dir "utilization.rpt"]
report_timing_summary -delay_type max -max_paths 10 -report_unconstrained \
    -file [file join $report_dir "timing_summary.rpt"]

set summary_file [open [file join $report_dir "summary.txt"] "w"]
set worst_path [get_timing_paths -delay_type max -max_paths 1 -nworst 1]
if {[llength $worst_path] > 0} {
    set worst_slack [get_property SLACK $worst_path]
    puts $summary_file "WNS_NS=$worst_slack"
    puts $summary_file "DATAPATH_DELAY_NS=[get_property DATAPATH_DELAY $worst_path]"
    puts $summary_file "STARTPOINT=[get_property STARTPOINT_PIN $worst_path]"
    puts $summary_file "ENDPOINT=[get_property ENDPOINT_PIN $worst_path]"
} else {
    close $summary_file
    error "No constrained setup timing path was found"
}
close $summary_file

if {$worst_slack < 0.0} {
    error "100 MHz timing constraint failed with WNS $worst_slack ns"
}

puts "PASS: core routed timing check"
