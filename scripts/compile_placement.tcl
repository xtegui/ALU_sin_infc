####################################################################################################
# Descripcion: Script para compilar el diseno y ubicar las compuertas
# Autores: Pablo Sosa - David Sosa
####################################################################################################

####################################################################################################
# Inicializacion de la ejecucion
####################################################################################################

# Configuracion del directorio de busqueda de scripts
set search_path ". scripts"

# Variables y procs que son utilizados en todo el flujo
source "config_tecnologia.tcl"
source "config_herramienta.tcl"
source "config_design.tcl"
source "procs.tcl"

# Separador de mensajes
set sep [string repeat = 100]

# Numero de procesadores, digitos significativos y unidades
set_host_options -max_cores $num_procesadores
set_app_options -name shell.common.report_default_significant_digits -value 3 ; # Por defecto 2
set_user_units -type power -value 1mW
set_user_units -type capacitance -value 1pF

# Directorios para archivos de salida
if !{[file exists $dir_reportes]} {file mkdir $dir_reportes}
if !{[file exists $dir_salidas]} {file mkdir $dir_salidas}
if !{[file exists $dir_logs]} {file mkdir $dir_logs}

# Informacion de la ejecucion en el log

puts "INFO: Informacion de la ejecucion"
puts " - Maquina: [sh hostname]"
puts " - Fecha: [date]"
puts " - ID proceso: [pid]"
puts " - Directorio: [pwd]"
 

set etapa_anterior "init_design"
set etapa_actual "compile_placement"

puts "\nINFO: Etapa actual: ${etapa_actual}\n"

file mkdir ${dir_reportes}/${etapa_actual}

# Directorios para categoria de reportes
set dir_estado "estado"
file mkdir ${dir_reportes}/${etapa_actual}/${dir_estado}
set dir_escenarios "escenarios"
file mkdir ${dir_reportes}/${etapa_actual}/${dir_escenarios}
set dir_ems "base_datos_ems"
file mkdir ${dir_reportes}/${etapa_actual}/${dir_ems}
set dir_clocks "clocks"
file mkdir ${dir_reportes}/${etapa_actual}/${dir_clocks}
set dir_configuraciones "configuraciones"
file mkdir ${dir_reportes}/${etapa_actual}/${dir_configuraciones}
set dir_timing "timing"
file mkdir ${dir_reportes}/${etapa_actual}/${dir_timing}
set dir_potencia "potencia"
file mkdir ${dir_reportes}/${etapa_actual}/${dir_potencia}

# Informacion de comienzo
set tiempo_comienzo [clock seconds]
puts "\nINFO: Comienzo: [clock format $tiempo_comienzo -format {%H:%M:%S - %d %b %Y}]\n"

####################################################################################################
# Apertura de la libreria del diseno
####################################################################################################

set_svf ${dir_salidas}/${etapa_actual}.svf
puts "INFo votegui: Omitiendo open_lib"
#open_lib $nombre_design
copy_block -from ${nombre_design}/${etapa_anterior} -to ${nombre_design}/${etapa_actual}
current_block ${nombre_design}/${etapa_actual}
link_block

####################################################################################################
# Escenarios y tipos de celdas
####################################################################################################

# Activa los escenarios elegidos para esta etapa
if {$escenarios_activos_compile_placement != ""} {
    set_scenario_status -active false [get_scenarios -filter active]
    set_scenario_status -active true $escenarios_activos_compile_placement
}

# Restricciones de uso de celdas estandar (set_lib_cell_purpose: Dont use, tie cells, arreglos de hold y CTS)
source "set_lib_cell_purpose.tcl"

# Carga archivo con restricciones de uso de VT
source "multi_vt_constraints.tcl"

# Configuracion de capas de ruteo max/min
if {$maxima_capa_routeo != ""} {set_ignored_layers -max_routing_layer $maxima_capa_routeo}
if {$minima_capa_routeo != ""} {set_ignored_layers -min_routing_layer $minima_capa_routeo}

# Seteo de la estrategia para optimizar la calidad de los resultados (QoR)
set set_qor_strategy_cmd "set_qor_strategy -stage synthesis -metric \"${metrica_estrategia_qor}\" -mode \"${modo_estrategia_qor}\""
if {$habilitar_high_effort_timing} {
   lappend set_qor_strategy_cmd -high_effort_timing
}
puts "\nINFO: Ejecutando \"${set_qor_strategy_cmd}\"\n"
eval ${set_qor_strategy_cmd}

# Habilita o deshabilita el uso de registros mutibit
set_app_options -name compile.flow.enable_multibit -value $habilitar_multibit
set_app_options -name place_opt.flow.enable_multibit -value $habilitar_multibit
set_app_options -name place_opt.flow.enable_multibit_debanking -value $habilitar_multibit
set_app_options -name compile.seqmap.enable_register_merging_across_bus -value false
set_app_options -name multibit.common.ignore_cell_with_sdc -value true
set_app_options -name multibit.common.ignore_sizeonly_cells -value true

# Prefijo
set_app_options -name opt.common.user_instance_name_prefix -value compile_
set_app_options -name cts.common.user_instance_name_prefix -value compile_cts_

####################################################################################################
# Configuraciones de pre-compilacion
####################################################################################################

# Para evitar que la herramienta haga grandes cambios en los registros
set_app_options -name compile.seqmap.enable_register_merging -value false
set_app_options -name compile.seqmap.identify_shift_registers -value false

# Optimizacion de clock gates
set_app_options -name time.case_analysis_propagate_through_icg -value true
set_app_options -name compile.clockgate.physically_aware -value true

# Evita que se desagrupen las jerarquias del diseno
set_app_options -name compile.flow.autoungroup -value false

# Configuraciones de analisis de potencia
set_app_options -name power.default_toggle_rate -value 0.1 ; # Cantidad de cambios logicos por unidad de tiempo
set_app_options -name power.default_static_probability -value 0.5 ; # Probabilidad de que las se??ales tengan un 1 logico
set_app_options -name power.enable_activity_persistency -value on
set_app_options -name power.power_annotation_persistency -value true
set_app_options -name power.propagation_effort -value medium
set_app_options -name power.report_user_power_groups -value inclusive

puts "\nINFO: Haciendo ideal los clocks\n"
set modo_actual [current_mode]
foreach_in_collection modo [all_modes] {
    current_mode $modo
    set clock_tree [remove_from_collection [all_fanout -flat -clock_tree] [all_registers -clock_pins]]
    if { [sizeof_collection $clock_tree] > 0 } {
        set_ideal_network $clock_tree
    }
}
current_mode $modo_actual

set_svf ${dir_salidas}/${etapa_actual}_pre_map.svf

####################################################################################################
# Chequeos y reportes intermedios
####################################################################################################
redirect -tee -file ${dir_reportes}/${etapa_actual}/${dir_configuraciones}/app_options_inicio.rpt {report_app_options -non_default *}

puts "\nINFO: Ejecutando el chequeo de la compilacion\n"
redirect -file ${dir_reportes}/${etapa_actual}/${dir_estado}/compile_fusion_solo_chequeo.rpt {compile_fusion -check_only}

####################################################################################################
# Compilacion inicial
####################################################################################################
puts "\nINFO: Ejecutando la compilacion inicial\n"
compile_fusion -to initial_map

save_block -as ${nombre_design}/${etapa_actual}_initial_map

# Ubica las celdas de interfaz cerca de los puertos, crea las redes de clock de las interfaces y bloqueos de placement
source celdas_interfaces.tcl
source clock_interfaces.tcl
source regiones_interfaces.tcl

save_block -as ${nombre_design}/${etapa_actual}_interfaces

####################################################################################################
# Optimizacion logica de la compilacion
####################################################################################################

set_svf ${dir_salidas}/${etapa_actual}_logic_opto.svf

puts "\nINFO: Ejecutando la optimizacion logica de la compilacion\n"
compile_fusion -from logic_opto -to logic_opto

save_block -as ${nombre_design}/${etapa_actual}_logic_opto
report_qor -summary

set_svf ${dir_salidas}/${etapa_actual}.svf

####################################################################################################
# Modelado de las NDR de clock en la compilacion
####################################################################################################
puts "\nINFO: Modelando el impacto de las NDR de clock en la compilacion\n"
mark_clock_trees -routing_rules

####################################################################################################
# Ubicacion inicial de las celdas
####################################################################################################

puts "\nINFO: Ejecutando la ubicacion inicial de las celdas\n"
compile_fusion -from initial_place -to initial_place
save_block -as ${nombre_design}/${etapa_actual}_initial_place

puts "\nINFO: Ejecutando el chequeo inicial de reglas de diseno\n"
compile_fusion -from initial_drc -to initial_drc

report_qor -summary
save_block -as ${nombre_design}/${etapa_actual}_initial_drc

puts "\nINFO: Ejecutando optimizacion inicial de la ubicacion de celdas\n"
compile_fusion -from initial_opto -to initial_opto

report_qor -summary
save_block -as ${nombre_design}/${etapa_actual}_initial_opto

# CTS arbol H
# Configuracion de arboles de clock
set estilo_cts "regular" ; # El estilo puede ser "regular" o "arbol_h"
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