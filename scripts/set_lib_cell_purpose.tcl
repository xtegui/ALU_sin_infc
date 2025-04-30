####################################################################################################
# Script para definir los usos de celdas especificas
####################################################################################################

####################################################################################################
# Celdas de conexion a 0 o 1 (tie cells) y celdas de delay (arreglos de hold timing)
####################################################################################################

# Suprime la informacion de que algunos atributos especificos tendran precedencia sobre los valores de las librerias
suppress_message ATTR-11

# Excluir celdas para que no sean usadas
# set_lib_cell_purpose -exclude <purpose> [get_lib_cells <cells>]

# Configuracion de tie cells
if {$tie_cells != ""} {
    set_dont_touch [get_lib_cells $tie_cells] false
    set_lib_cell_purpose -include optimization [get_lib_cells $tie_cells]
}

# Configuracion de celdas de delay para arreglos de hold timing
if {$delay_cells != ""} {
    set_dont_touch [get_lib_cells $delay_cells] false
    set_lib_cell_purpose -exclude hold [get_lib_cells */*]
    set_lib_cell_purpose -include hold [get_lib_cells $delay_cells]
}

####################################################################################################
# Celdas para la sintesis de arboles de clock (CTS)
####################################################################################################

# Evita que cualquier celda se use para la CTS
if {$clock_cells != "" || $clock_cells_exclusivas != ""} {
    set_lib_cell_purpose -exclude cts [get_lib_cells */*]
}

# Configuracion de celdas de clock no exclusivas (tambien se pueden usar para datos)
if {$clock_cells != ""} {
    set_dont_touch [get_lib_cells $clock_cells] false ;# CTS respects dont_touch
    set_lib_cell_purpose -include cts [get_lib_cells $clock_cells]
}

# Configuracion de celdas de clock exclusivas (se usan solo para redes de clock)
if {$clock_cells_exclusivas != ""} {
    set_dont_touch [get_lib_cells $clock_cells_exclusivas] false ;# CTS respects dont_touch
    set_lib_cell_purpose -include none [get_lib_cells $clock_cells_exclusivas]
    set_lib_cell_purpose -include cts [get_lib_cells $clock_cells_exclusivas]
}
