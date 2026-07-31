# SPI Top OpenSTA Timing Analysis

# Read Liberty timing library
read_liberty /usr/local/share/pdk/sky130A/libs.ref/sky130_fd_sc_hdll/lib/sky130_fd_sc_hdll__tt_025C_1v80.lib

# Read synthesized netlist
read_verilog reports/spi_top_sky130_synth.v

# Link top module
link_design spi_top

# Read timing constraints
read_sdc constraints/spi_top.sdc

puts "\n============ SETUP PATHS =============="
report_checks -path_delay max -format full_clock_expanded -fields {slew cap input_pin nets fanout} -digits 3

puts "\n============= HOLD PATHS =============="
report_checks -path_delay min -format full_clock_expanded -fields {slew cap input_pin nets fanout} -digits 3

puts "\n=========== WORST SLACK ==============="
report_worst_slack

puts "\n================ TNS =================="
report_tns

puts "\n================ wNS =================="
report_wns