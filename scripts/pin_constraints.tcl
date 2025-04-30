####################################################################################################
# Script para ubicacion de puertos
####################################################################################################

#input   [1:0]                   i_operation,
#input   [1:0]                   i_sel_clock,
#input                           i_enable,
#input                           i_clock,
#input   [N_BITS-1:0]            i_data_a,
#input   [N_BITS-1:0]            i_data_b,
#input                           i_valid,
#input                           i_reset
#//Salidas
#///output        [N_BITS-1:0]    o_data,
#output  [(N_BITS-1):0]        o_data,
#output                          o_clock,
#output                          o_valid,
#-offset offset_distance
#Specifies the distance in microns between the starting or ending point of a specified edge and the pin's center location. The
#starting point is the location where the edge begins as you proceed clockwise around the shape. The ending point is the location
#where the edge end as you proceed clockwise around the shape. The starting point of edge 1 is the lowest point of the edge, the
#ending point of edge 1 is the highest point of the edge the starting point of edge 2 is the leftmost point of the edge, and so on.
#Positive value means offset distance calculates from starting point of a specified edge and the pin's center location, vice versa for
#negative value.
#INPUTS
puts "INFO: Colocando puertos de entrada"
for {set i 0} {$i < 32} {incr i} {
    set_individual_pin_constraints -ports [get_ports i_data_a[$i]] -allowed_layers [get_layers M6] -pin_spacing 0 -sides 1 -offset [expr 9.960 + ($i * 0.240)] -width 0.060 -length 0.600
}
#for {set i 0} {$i < 32} {incr i} {
#   set_individual_pin_constraints -ports [get_ports i_data_b[$b]] -allowed_layers [get_layers M6] -pin_spacing 0 -sides 1 -offset [expr 17.88 + ($i * 0.240)] -width 0.060 -length 0.600
#}

for {set i 31} {$i >= 0} {incr i -1} {
    set_individual_pin_constraints -ports [get_ports i_data_b[$i]] -allowed_layers [get_layers M6] -pin_spacing 0 -sides 1 -offset [expr -9.960 - ((7 - $i) * 0.240)] -width 0.060 -length 0.600
}

for {set i 0} {$i < 2} {incr i} {
    set_individual_pin_constraints -ports [get_ports i_operation[$i]] -allowed_layers [get_layers M6] -pin_spacing 0 -sides 1 -offset [expr 18 + ($i * 0.240)] -width 0.060 -length 0.600
}
for {set i 0} {$i < 2} {incr i} {
    set_individual_pin_constraints -ports [get_ports i_sel_clock[$i]] -allowed_layers [get_layers M6] -pin_spacing 0 -sides 1 -offset [expr -18 - ($i - 0.240)] -width 0.060 -length 0.600
}
set_individual_pin_constraints -ports [get_ports i_reset] -allowed_layers [get_layers M5] -pin_spacing 0 -sides 2 -offset 13.560 -width 0.060 -length 0.600
set_individual_pin_constraints -ports [get_ports i_valid] -allowed_layers [get_layers M5] -pin_spacing 0 -sides 2 -offset 14.04 -width 0.060 -length 0.600
set_individual_pin_constraints -ports [get_ports i_enable] -allowed_layers [get_layers M5] -pin_spacing 0 -sides 2 -offset 14.52 -width 0.060 -length 0.600
#double witdth for clock ports
set_individual_pin_constraints -ports [get_ports i_clock] -allowed_layers [get_layers M5] -pin_spacing 0 -sides 4 -offset 13.56 -width 0.120 -length 0.600
#OUTPUTS
puts "INFO: Colocando puertos de salida"
for {set i 31} {$i >= 0} {incr i -1} {
    set_individual_pin_constraints -ports [get_ports o_data[$i]] -allowed_layers [get_layers M6] -pin_spacing 0 -sides 3 -offset [expr -11.640 - ((15 - $i) * 0.240)] -width 0.060 -length 0.600
}
set_individual_pin_constraints -ports [get_ports i_clock] -allowed_layers [get_layers M5] -pin_spacing 0 -sides 4 -offset 20 -width 0.120 -length 0.600
set_individual_pin_constraints -ports [get_ports o_valid] -allowed_layers [get_layers M5] -pin_spacing 0 -sides 4 -offset 14.04 -width 0.060 -length 0.600





