####################################################################################################
# Descripcion: Script para sintetizar las redes de clock
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
puts 
puts "INFO: Informacion de la ejecucion"
puts " - Maquina: [sh hostname]"
puts " - Fecha: [date]"
puts " - ID proceso: [pid]"
puts " - Directorio: [pwd]"
puts 

set etapa_anterior "compile_placement"
set etapa_actual "clock_opt_cts"

puts "\nINFO: Etapa actual: ${etapa_actual}\n"

file mkdir ${dir_reportes}/${etapa_actual}

# Directorios para categoria de reportes
set dir_estado "estado"
file mkdir ${dir_reportes}/${etapa_actual}/${dir_estado}
set dir_escenarios "escenarios"
file mkdir ${dir_reportes}/${etapa_actual}/${dir_escenarios}
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

open_lib $nombre_design
copy_block -from ${nombre_design}/${etapa_anterior} -to ${nombre_design}/${etapa_actual}
current_block ${nombre_design}/${etapa_actual}
link_block

####################################################################################################
# Escenarios y tipos de celdas
####################################################################################################

# Activa los escenarios elegidos para esta etapa
if {$escenarios_activos_clock_opt_cts != ""} {
    set_scenario_status -active false [get_scenarios -filter active]
    set_scenario_status -active true $escenarios_activos_clock_opt_cts
}

if {[sizeof_collection [get_scenarios -filter "hold && active"]] == 0} {
    puts "\nADVERTENCIA: No se encontro ningun escenario de hold activo. Activar los escenarios de hold para la CTS si estan disponibles.\n"
}

# Restricciones de uso de celdas estandar (set_lib_cell_purpose: Dont use, tie cells, arreglos de hold y CTS)
source "set_lib_cell_purpose.tcl"

# Carga archivo con restricciones de uso de VT
source "multi_vt_constraints.tcl"

####################################################################################################
## Configuraciones de clock_opt_cts
####################################################################################################

# set_qor_strategy: Comando que combina varias configuraciones (placement, optimizaciones, timing, CTS, ruteo, etc.)
puts "\nINFO: Ejecutando \"set_qor_strategy -stage pnr -metric ${metrica_estrategia_qor} -mode ${modo_estrategia_qor}\"\n"
set_qor_strategy -stage pnr -metric ${metrica_estrategia_qor} -mode ${modo_estrategia_qor}

# set_stage: Comando para aplicar configuraciones por etapa
# Configuraciones de "set_stage -step cts"
set_app_options -name time.remove_clock_reconvergence_pessimism -value true
set_app_options -name ccd.timing_effort -value high
set_app_options -name ccd.fmax_optimization_effort -value high

# Prefijos
set_app_options -name cts.common.user_instance_name_prefix -value clock_opt_cts_
set_app_options -name opt.common.user_instance_name_prefix -value clock_opt_cts_opt_

# Para "set_qor_strategy -metric timing", deshabilita el analisis de dynamic power y leakage power en los escenarios activos para optimizacion
# Los escenarios de analisis de potencia se restableceran despues de las optimizaciones para reportar
if {$metrica_estrategia_qor == "timing"} {
    set escenarios_leakage [get_object_name [get_scenarios -filter active==true&&leakage_power==true]]
    set escenarios_dinamica [get_object_name [get_scenarios -filter active==true&&dynamic_power==true]]

    if {[llength $escenarios_leakage] > 0 || [llength $escenarios_dinamica] > 0} {
        puts "\nINFO: Deshabilitando el analisis de potencia leakage para $escenarios_leakage y potencia dinamica para $escenarios_dinamica\n"
        set_scenario_status -leakage_power false -dynamic_power false [get_scenarios "$escenarios_leakage $escenarios_dinamica"]
    }
}

# Los arreglos de violaciones de antena estan encendidos por defecto: route.detail.antenna = true
source "antenna_rules.tcl"

####################################################################################################
# Chequeos y reportes intermedios
####################################################################################################

redirect -tee -file ${dir_reportes}/${etapa_actual}/${dir_configuraciones}/app_options_inicio.rpt {report_app_options -non_default *}

# Reporta configuraciones de CTS
redirect -file ${dir_reportes}/${etapa_actual}/${dir_configuraciones}/pre_cts_configuraciones_clock.rpt {report_clock_settings}
# Chequea problemas que pueden perjudicar los resultados de CTS
redirect -file ${dir_reportes}/${etapa_actual}/${dir_estado}/pre_cts_chequeo_arbol_clock.rpt {check_clock_tree}

# Reportes de QoR y timing
if {$reportar_qor_intermedio} {
   redirect -file ${dir_reportes}/${etapa_actual}/${dir_estado}/reporte_qor_inicio.rpt {report_qor -scenarios [all_scenarios] -pba_mode [get_app_option_value -name time.pba_optimization_mode] -nosplit}
   redirect -append -file ${dir_reportes}/${etapa_actual}/${dir_estado}/reporte_qor_inicio.rpt {report_qor -summary -pba_mode [get_app_option_value -name time.pba_optimization_mode] -nosplit}
   redirect -tee -file ${dir_reportes}/${etapa_actual}/${dir_timing}/timing_global_inicio.rpt {report_global_timing -pba_mode [get_app_option_value -name time.pba_optimization_mode] -nosplit}
}

# Chequeo de configuraciones de la etapa CTS
redirect -file ${dir_reportes}/${etapa_actual}/${dir_configuraciones}/chequeo_configuraciones.rpt {check_stage_settings -stage pnr -metric ${metrica_estrategia_qor} -step cts}

####################################################################################################
# Flujo de CTS clock_opt
####################################################################################################

# Recordatorio: Incluir flip-flops como parte de la lista de CTS lib_cell_purpose asi se podran reemplazar para mejorar timing.

# Sintesis de los arboles de clock
puts "\nINFO: Ejecutando \"clock_opt -from build_clock -to build_clock\"\n"
clock_opt -from build_clock -to build_clock
#save_block -as ${nombre_design}/clock_opt_build_clock

# Ruteo de los arboles de clock
puts "\nINFO: Ejecutando \"clock_opt -from route_clock -to route_clock\"\n"
clock_opt -from route_clock -to route_clock

####################################################################################################
# Insercion de vias redundantes y blindaje para las redes de clock
####################################################################################################

# Insercion de vias redundantes
if {$habilitar_insercion_vias_redundantes} {
    add_redundant_vias
}

# Blindaje para las redes de clock
if {$habilitar_creacion_blindaje_clock} {
    create_shields 
}

####################################################################################################
# Conexion de power y ground
####################################################################################################

connect_pg_net

# Rehablitacion de escenarios de potencia si fueron deshabilitados por "set_qor_strategy -metric timing"
if {[info exists escenarios_leakage] && [llength $escenarios_leakage] > 0} {
   puts "\nINFO: Habilitando el analisis de potencia leakage para ${escenarios_leakage}\n"
   set_scenario_status -leakage_power true [get_scenarios $escenarios_leakage]
}
if {[info exists escenarios_dinamica] && [llength $escenarios_dinamica] > 0} {
   puts "\nINFO: Habilitando el analisis de potencia dinamica para ${escenarios_dinamica}\n"
   set_scenario_status -dynamic_power true [get_scenarios $escenarios_dinamica]
}

# Corre check_routes para guardar DRCs de ruteo actualizadas al bloque
redirect -tee -file ${dir_reportes}/${etapa_actual}/${dir_estado}/chequeo_ruteos.rpt {check_routes -open_net false}

# Guarda el bloque
save_block

####################################################################################################
# Reportes de QoR
####################################################################################################

set reportar_etapa cts
set reportar_escenarios_activos $escenarios_activos_clock_opt_cts
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

puts 
puts "INFO: Informacion de la ejecucion:"
puts " - Comienzo: [clock format $tiempo_comienzo -format {%H:%M:%S - %d %b %Y}]"
puts " - Final: [clock format $tiempo_final -format {%H:%M:%S - %d %b %Y}]"
puts " - Runtime: $runtime min"
puts " - Memoria usada: [format "%.3f" $memGB] GB"
puts 

# Reportes de QoR
write_qor_data -report_list "performance host_machine report_app_options" -label $etapa_actual -output $dir_qor

if {[file exists ${etapa_actual}.log]} {
    exec gzip ${etapa_actual}.log
    file rename -force ${etapa_actual}.log.gz $dir_logs
}

exit
