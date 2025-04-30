####################################################################################################
# Descripcion: Script para ejecutar las tareas finales del chip
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


set etapa_anterior "route_opt"
set etapa_actual "chip_finish"

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
#ya esta abierta la lib del design
#open_lib $nombre_design
copy_block -from ${nombre_design}/${etapa_anterior} -to ${nombre_design}/${etapa_actual}
current_block ${nombre_design}/${etapa_actual}
link_block

####################################################################################################
# Escenarios y tipos de celdas
####################################################################################################

# Activa los escenarios elegidos para esta etapa
if {$escenarios_activos_chip_finish != ""} {
    set_scenario_status -active false [get_scenarios -filter active]
    set_scenario_status -active true $escenarios_activos_chip_finish
}

# Restricciones de uso de celdas estandar (set_lib_cell_purpose: Dont use, tie cells, arreglos de hold y CTS)
source "set_lib_cell_purpose.tcl"

# Carga archivo con restricciones de uso de VT
source "multi_vt_constraints.tcl"

####################################################################################################
# Configuraciones de chip_finish
####################################################################################################

# Deshabilita las optimizaciones de timing basadas en reglas soft durante el ECO routing
# Esto es para evitar un impacto en la convergencia
set_app_options -name route.detail.eco_route_use_soft_spacing_for_timing_optimization -value false

# Habilita el legalizador avanzado
set_app_option -name place.legalize.enable_advanced_legalizer -value true

####################################################################################################
# Chequeos y reportes intermedios
####################################################################################################

redirect -tee -file ${dir_reportes}/${etapa_actual}/${dir_configuraciones}/app_options_inicio.rpt {report_app_options -non_default *}

# Reportes de QoR y timing
if {$reportar_qor_intermedio} {
   redirect -file ${dir_reportes}/${etapa_actual}/${dir_estado}/reporte_qor_inicio.rpt {report_qor -scenarios [all_scenarios] -pba_mode [get_app_option_value -name time.pba_optimization_mode] -nosplit}
   redirect -append -file ${dir_reportes}/${etapa_actual}/${dir_estado}/reporte_qor_inicio.rpt {report_qor -summary -pba_mode [get_app_option_value -name time.pba_optimization_mode] -nosplit}
   redirect -tee -file ${dir_reportes}/${etapa_actual}/${dir_timing}/timing_global_inicio.rpt {report_global_timing -pba_mode [get_app_option_value -name time.pba_optimization_mode] -nosplit}
}

####################################################################################################
# Insercion de celdas de relleno
####################################################################################################

# Remueve los keepout margins de las celdas
remove_keepout_margins [get_keepout_margins -quiet]

# Celdas de relleno de metal (celdas decap)
if {$dcap_cells != ""} {
    puts "\nINFO: Insertando celdas de relleno de metal\n"
    # Se recomienda armar la lista de celdas mas grandes a mas pequenas
    create_stdcell_filler -lib_cell [sort_collection -descending [get_lib_cells $dcap_cells] area]
    connect_pg_net

    remove_stdcell_fillers_with_violation
}

# Celdas de relleno (no metal)
if {$fill_cells != ""} {
    puts "\nINFO: Insertando celdas de relleno (no metal)\n"
    # Se recomienda armar la lista de celdas mas grandes a mas pequenas
    create_stdcell_filler -lib_cell [sort_collection -descending [get_lib_cells $fill_cells] area]
    connect_pg_net
}

####################################################################################################
# Ruteo incremental para arreglar DRCs restantes
####################################################################################################

# Deshabilita que el ruteo tenga en cuenta el timing
set_app_options -name route.global.timing_driven -value false
set_app_options -name route.detail.timing_driven -value false
set_app_options -name route.track.timing_driven -value false
set_app_options -name route.global.crosstalk_driven -value false
set_app_options -name route.track.crosstalk_driven -value false

# Comando de ruteo incremental
set comando_ruteo_incremental "route_eco -reuse_existing_global_route true"
if {$iteraciones_ruteo_incremental != ""} {lappend comando_ruteo_incremental -max_detail_route_iterations $iteraciones_ruteo_incremental}

puts "\nINFO: Ejecutando ruteo incremental\n"
eval $comando_ruteo_incremental

####################################################################################################
# Conexion de power y ground
####################################################################################################

connect_pg_net

# Ejecutar check_routes para guardar las violaciones de DRC en la DB
redirect -tee -file ${dir_reportes}/${etapa_actual}/${dir_estado}/chequeo_ruteos.rpt {check_routes}

# Guarda el bloque
save_block

####################################################################################################
# Reportes de QoR
####################################################################################################

set reportar_etapa post_route
set reportar_escenarios_activos $escenarios_activos_route_opt
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

exit