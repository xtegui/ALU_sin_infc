#Definicion de restricciones de tiempo - iodelay.tcl
#Autora: Victoria Otegui Alexenicer
#Version: 0.2
#Fecha 3/03/2025
# --Input delays--

set_input_delay -add_delay 2.5 -clock [get_clocks CLOCK_MAIN] i_data_a
set_input_delay -add_delay 2.5 -clock [get_clocks CLOCK_MAIN] i_data_b
set_input_delay -add_delay 2.5 -clock [get_clocks CLOCK_MAIN] i_operation
set_input_delay -add_delay 2.5 -clock [get_clocks CLOCK_MAIN] i_sel_clock
set_input_delay -add_delay 2.5 -clock [get_clocks CLOCK_MAIN] i_enable
set_input_delay -add_delay 2.5 -clock [get_clocks CLOCK_MAIN] i_valid
set_input_delay -add_delay 2.5 -clock [get_clocks CLOCK_MAIN] i_reset


# -- Output delays --
set_output_delay -add_delay 2.5 -clock [get_clocks CLOCK_MAIN] o_data
set_output_delay -add_delay 2.5 -clock [get_clocks CLOCK_MAIN] o_clock 
set_output_delay -add_delay 2.5 -clock [get_clocks CLOCK_MAIN] o_valid
 
  
