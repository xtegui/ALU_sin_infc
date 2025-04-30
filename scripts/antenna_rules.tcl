####################################################################################################
## Script de ejemplo de reglas de insercion de diodos de antena
####################################################################################################

# set lib [current_lib]
# set metal_superior 17
# # Regla con modo 2 y modo de diodo 16
# define_antenna_rule $lib -mode 2 -diode_mode 16 -metal_ratio 0 -cut_ratio 0
# for { set i 0 } { $i < $metal_superior } { incr i } {
#   define_antenna_layer_rule $lib -mode 2 -layer "M$i" -ratio 5000 -diode_ratio { 0 0 0 5000 0 0.030 0.500 7.600 }
# }
