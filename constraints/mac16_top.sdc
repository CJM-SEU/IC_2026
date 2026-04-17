# SDC constraints for mac16_top
# Target clock: 1GHz (period = 1.000ns)
# Tune the budget values below according to your process/library and board timing.

set DESIGN_TOP mac16_top
set CLK_PORT clk
set RST_PORT rst_n

# Clock and timing budget
set CLK_PERIOD_NS        1.000
set CLK_UNCERTAINTY_NS   0.050
set CLK_TRANSITION_NS    0.050
set IN_MAX_DELAY_NS      0.250
set IN_MIN_DELAY_NS      0.050
set OUT_MAX_DELAY_NS     0.250
set OUT_MIN_DELAY_NS     0.050
set OUT_LOAD_PF          0.020

current_design $DESIGN_TOP

# Primary clock
create_clock -name core_clk -period $CLK_PERIOD_NS [get_ports $CLK_PORT]
set_clock_uncertainty $CLK_UNCERTAINTY_NS [get_clocks core_clk]
set_clock_transition $CLK_TRANSITION_NS [get_clocks core_clk]

# Input constraints
set_input_delay -clock core_clk -max $IN_MAX_DELAY_NS [get_ports {mode inA inB data_en}]
set_input_delay -clock core_clk -min $IN_MIN_DELAY_NS [get_ports {mode inA inB data_en}]
set_input_transition $CLK_TRANSITION_NS [get_ports {mode inA inB data_en}]

# Output constraints
set_output_delay -clock core_clk -max $OUT_MAX_DELAY_NS [get_ports {sum_out carry out_ready}]
set_output_delay -clock core_clk -min $OUT_MIN_DELAY_NS [get_ports {sum_out carry out_ready}]
set_load $OUT_LOAD_PF [get_ports {sum_out carry out_ready}]

# Async reset path should not be timed as a data path
set_false_path -from [get_ports $RST_PORT]

# Optional checks
set_max_fanout 16 [current_design]
