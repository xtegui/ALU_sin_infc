####################################################################################################
## Script para crear la grilla de power/ground (PG)
####################################################################################################

# Creacion de la grilla de PG
create_pg_mesh_pattern mesh_pattern -layers { {{vertical_layer: M9} {width: 0.6} {pitch: 6} {spacing: interleaving}} }
set_pg_strategy mesh_strategy -core -pattern {{pattern: mesh_pattern} {nets: {$nombre_power $nombre_ground}}} -extension { {{stop: design_boundary_and_generate_pin}} }

# Creacion de los rieles de PG para celdas estandard
create_pg_std_cell_conn_pattern rail -layers M1 -rail_width 0.094
set_pg_strategy rail_strategy -core -pattern {{name: rail} {nets: {$nombre_power $nombre_ground}}}

# Compilacion de la red PG
compile_pg -ignore_via_drc

# Configurar los puertos de alimentacion (PG) como fijos para evitar que sean movidos
set_attribute [get_ports "$nombre_power $nombre_ground"] physical_status "fixed"
