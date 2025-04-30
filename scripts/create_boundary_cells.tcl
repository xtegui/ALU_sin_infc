####################################################################################################
## Script para crear y ubicar las celdas de frontera (boundary cells)
####################################################################################################

# Reglas de celdas de frontera (boundary cells)
set_boundary_cell_rules \
    -left_boundary_cell [get_lib_cells $borde_izquierdo] \
    -right_boundary_cell [get_lib_cells $borde_derecho]\
    -bottom_boundary_cells [get_lib_cells $borde_inferior] \
    -top_boundary_cells [get_lib_cells $borde_superior] \
    -bottom_left_outside_corner_cell [get_lib_cells $esquina_inferior_izquierda] \
    -bottom_right_outside_corner_cell [get_lib_cells $esquina_inferior_derecha] \
    -top_left_outside_corner_cell [get_lib_cells $esquina_superior_izquierda] \
    -top_right_outside_corner_cell [get_lib_cells $esquina_superior_derecha] \
    -top_tap_cell [get_lib_cells $tap_cell_superior] \
    -bottom_tap_cell [get_lib_cells $tap_cell_inferior] \
    -tap_distance $distancia_tap_cells_borde \
    -separator "_"

# Compilacion y ubicacion de las boundary cells
compile_targeted_boundary_cells -target_objects [get_core_area]
