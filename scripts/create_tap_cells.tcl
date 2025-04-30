########################################################################
## Script para crear y ubicar las celdas tap (tap cells)
########################################################################

# Creacion de tap cells
create_tap_cells \
    -lib_cell [get_lib_cells $tap_cell] \
    -mirrored_row_lib_cell [get_lib_cells $tap_cell_espejada] \
    -distance $distancia_tap_cells \
    -pattern stagger \
    -skip_fixed_cells \
    -separator "_"
