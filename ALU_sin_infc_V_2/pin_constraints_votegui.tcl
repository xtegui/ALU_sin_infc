####################################################################################################
# Script para ubicacion de puertos
####################################################################################################
#output  [(N_BITS-1):0]        o_data,
#output                          o_clock,
#output                          o_valid,
////Entradas
#input   [1:0]                   i_operation,
#input   [1:0]                   i_sel_clock,
#input                           i_enable,
#input                           i_clock,
#input   [N_BITS-1:0]            i_data_a,
#input   [N_BITS-1:0]            i_data_b,
#input                           i_valid,
#input                           i_reset
for {set i 0} {$i < 32} {incr i} {
    set_individual_pin_constraints -ports [get_ports i_data_a[$i]] -allowed_layers [get_layers M6] -pin_spacing 0 -sides 1 -offset [expr 9.960 + ($i * 0.240)] -width 0.060 -length 0.600
}

for {set i 31} {$i >= 0} {incr i -1} {
    set_individual_pin_constraints -ports [get_ports i_data_b[$i]] -allowed_layers [get_layers M6] -pin_spacing 0 -sides 1 -offset [expr -9.960 - ((7 - $i) * 0.240)] -width 0.060 -length 0.600
}

for {set i 0} {$i < 2} {incr i} {
    set_individual_pin_constraints -ports [get_ports i_operation[$i]] -allowed_layers [get_layers M6] -pin_spacing 0 -sides 1 -offset [expr 20 + ($i * 0.240)] -width 0.060 -length 0.600
}
for {set i 0} {$i < 2} {incr i} {
    set_individual_pin_constraints -ports [get_ports i_operation[$i]] -allowed_layers [get_layers M6] -pin_spacing 0 -sides 1 -offset [expr 20 + ($i * 0.240)] -width 0.060 -length 0.600

for {set i 15} {$i >= 0} {incr i -1} {
    set_individual_pin_constraints -ports [get_ports o_resultado[$i]] -allowed_layers [get_layers M6] -pin_spacing 0 -sides 3 -offset [expr -20.640 - ((15 - $i) * 0.240)] -width 0.060 -length 0.600
}

set_individual_pin_constraints -ports [get_ports i_reset] -allowed_layers [get_layers M5] -pin_spacing 0 -sides 2 -offset 13.560 -width 0.060 -length 0.600

set_individual_pin_constraints -ports [get_ports clock] -allowed_layers [get_layers M5] -pin_spacing 0 -sides 4 -offset 13.56 -width 0.120 -length 0.600
