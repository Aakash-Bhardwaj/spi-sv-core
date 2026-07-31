# SPI Top Timing Constraints

# 50 MHz clock
create_clock -name clk -period 20 [get_ports clk]

# Input delays (exclude clock)
set_input_delay 0 -clock clk \
    [remove_from_collection [all_inputs] [get_ports clk]]

# Output delays
set_output_delay 0 -clock clk [all_outputs]