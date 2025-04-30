
# CTS arbol H
# Configuracion de arboles de clock
set estilo_cts "arbol_h" ; # El estilo puede ser "regular" o "arbol_h"
if {$estilo_cts == "arbol_h"} {
    source cts_arbol_h.tcl
    set_app_options -name compile.flow.enable_multisource_clock_trees -value true
    save_block -as ${nombre_design}/${etapa_actual}_arbol_h
}

####################################################################################################
# Ubicacion final de las celdas
####################################################################################################

puts "\nINFO: Ejecutando la ubicacion final de las celdas\n"
compile_fusion -from final_place -to final_place

report_qor -summary
save_block -as ${nombre_design}/${etapa_actual}_final_place

puts "\nINFO: Ejecutando la optimizacion final de la ubicacion de las celdas\n"
compile_fusion -from final_opto -to final_opto

report_qor -summary
save_block -as ${nombre_design}/${etapa_actual}_final_opto

# Agrega celdas de repuesto
set celdas_repuesto ""
foreach celda_repuesto $lista_celdas_repuesto {
    set lib_cell [get_lib_cells [lindex $celda_repuesto 0]]
    set cantidad [expr round([sizeof_collection [get_flat_cells]] * [lindex $celda_repuesto 1] * 0.01)]
    lappend celdas_repuesto $lib_cell $cantidad
}
add_spare_cells -cell_name repuesto -num_cells $celdas_repuesto -density_aware_ratio 100 -input_pin_connect_type tie_low
place_eco_cells -legalize_only -cells [get_flat_cells -filter is_spare_cell]

####################################################################################################
# Conexion de power y ground
####################################################################################################

connect_pg_net

# Cambia el nombre de los elementos del circuito de acuerdo con las reglas de Verilog
change_names -rules verilog -hierarchy -skip_physical_only_cells

# Escribe los archivos de salida
write_ascii_files -force -output ${dir_salidas}/${etapa_actual}.ascii_files

# Escribe el archivo de map para los SAIF
saif_map -type ptpx -essential -write_map ${dir_salidas}/${etapa_actual}.saif.ptpx.map
saif_map -write_map ${dir_salidas}/${etapa_actual}.saif.fc.map

# Guarda el bloque
save_block
set_svf -off

####################################################################################################
# Reportes de QoR
####################################################################################################

set reportar_etapa synthesis
set reportar_escenarios_activos $escenarios_activos_compile_placement
source "report_qor.tcl"

####################################################################################################
# Finalizacion de la ejecucion
####################################################################################################

# Informacion de la ejecucion
set tiempo_final [clock seconds]
set runtime [expr $tiempo_final - $tiempo_comienzo]
set runtime [expr $runtime/60]
set memKB [get_mem]
set memGB [expr ($memKB * 1.0)/(1024*1024)]

puts "INFO: Informacion de la ejecucion:"
puts " - Comienzo: [clock format $tiempo_comienzo -format {%H:%M:%S - %d %b %Y}]"
puts " - Final: [clock format $tiempo_final -format {%H:%M:%S - %d %b %Y}]"
puts " - Runtime: $runtime min"
puts " - Memoria usada: [format "%.3f" $memGB] GB"

# Reportes de QoR
write_qor_data -report_list "performance host_machine report_app_options" -label $etapa_actual -output $dir_qor

if {[file exists ${etapa_actual}.log]} {
    exec gzip ${etapa_actual}.log
    file rename -force ${etapa_actual}.log.gz $dir_logs
}

#exit
