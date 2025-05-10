#Definicion de restricciones de tiempo - timing.tcl
#Autora: Victoria Otegui Alexenicer
#Version: 0.1
#Fecha 9/12/2024

puts "INFO: Configurando false paths para senales estaticas o reset asincrono"
set_false_path -through [get_ports i_reset]
set_false_path -through  [get_ports i_operation]
set_false_path -through [get_ports i_sel_clock]
set_false_path -through [get_ports i_enable]
