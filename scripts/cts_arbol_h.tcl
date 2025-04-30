####################################################################################################
# Script para la creacion de arboles H de clock
####################################################################################################

# Antes de comenzar elimna los atributos dont_touch a la red de clock para permitir hacer los cambios
set_dont_touch_network -clear [get_attribute [get_clocks $arbol_h_clock] sources]
mark_clock_trees -clear -dont_touch

# Asegurarse que el current_scenario es de setup y este activo
set escenarios_activos_setup [get_object_name [get_scenarios -filter "setup&&active"]]
set primer_esc_activo_setup [lindex $escenarios_activos_setup 0]
current_scenario $primer_esc_activo_setup
 
# Incluye las celdas de construccion del arbol como "cts" y les remueve las restricciones de dont_touch en caso de tenerlas
set_lib_cell_purpose -include cts [get_lib_cell $arbol_h_cells_tronco]
set_lib_cell_purpose -include cts [get_lib_cell $arbol_h_cells_puntas]
set_dont_touch [get_lib_cell $arbol_h_cells_tronco] false
set_dont_touch [get_lib_cell $arbol_h_cells_puntas] false

# Controla la ubicacion de las celdas insertadas de modo que sean accesibles desde las capas de routeo seleccionadas. Esto asegura una buena topologia del arbol H
set_app_options -name cts.multisource.enable_pin_accessibility_for_global_clock_trees -value true

####################################################################################################
# Definicion de opciones para realizar la sintesis del arbol H
####################################################################################################

# Cantidad de filas y columnas de las puntas del arbol H
set arbol_h_filas 4
set arbol_h_columnas 4

# Configuracion de opciones del arbol H
puts "\nINFO: Configurando la estructura de \"Arbol H\" para el clock $arbol_h_clock\n"

set comando_opciones_arbol_h " \
set_regular_multisource_clock_tree_options \
 -clock $arbol_h_clock \
 -topology htree_only \
 -prefix $arbol_h_prefijo \
 -tap_boxes \[list $arbol_h_filas $arbol_h_columnas\] \
 -htree_layers \[list $arbol_h_minima_capa_routeo $arbol_h_maxima_capa_routeo\] \
 -htree_routing_rule $arbol_h_ndr \
 -tap_lib_cells \[get_lib_cells $arbol_h_cells_puntas\] \
 -htree_lib_cells \[get_lib_cells $arbol_h_cells_tronco\]"

if {$arbol_h_net != ""} {
    set comando_opciones_arbol_h "$comando_opciones_arbol_h -net $arbol_h_net"
}
if {$arbol_h_area_personalizada != ""} {
    set comando_opciones_arbol_h "$comando_opciones_arbol_h -tap_boundary \$arbol_h_area_personalizada"
}

# Evalua el comando de opciones desde la variable
eval $comando_opciones_arbol_h

# Reporte de opciones para la construccion del arbol H
report_regular_multisource_clock_tree_options

# Sintesis del arbol H
puts "\nINFO: Construyendo la estructura de \"Arbol H\" para el clock $arbol_h_clock\n"
synthesize_regular_multisource_clock_trees

####################################################################################################
# Definicion de configuraciones para asignaciones de celdas a cada punta del arbol
####################################################################################################

# Actualizacion de timing
update_timing

# Configuracion opciones de puntas del arbol H
set pines_puntas_arbol_h [get_pins -of_objects  [get_cells -physical_context *${arbol_h_prefijo}_r*c*] -filter "direction==out && related_clock==$arbol_h_clock"]
set_multisource_clock_tap_options -clock $arbol_h_clock -num_taps [sizeof_collection $pines_puntas_arbol_h] -driver_objects $pines_puntas_arbol_h
