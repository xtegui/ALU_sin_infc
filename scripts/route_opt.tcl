####################################################################################################
# Descripcion: Script para rutear las senales de un diseno
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

set etapa_anterior "route_auto"
set etapa_actual "route_opt"

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
#ya esta abierta la lireria
#open_lib $nombre_design
copy_block -from ${nombre_design}/${etapa_anterior} -to ${nombre_design}/${etapa_actual}
current_block ${nombre_design}/${etapa_actual}
link_block

####################################################################################################
# Escenarios y tipos de celdas
####################################################################################################

# Activa los escenarios elegidos para esta etapa
if {$escenarios_activos_route_opt != ""} {
    set_scenario_status -active false [get_scenarios -filter active]
    set_scenario_status -active true $escenarios_activos_route_opt
}

# Restricciones de uso de celdas estandar (set_lib_cell_purpose: Dont use, tie cells, arreglos de hold y CTS)
source "set_lib_cell_purpose.tcl"

# Carga archivo con restricciones de uso de VT
source "multi_vt_constraints.tcl"

####################################################################################################
# Configuraciones de route_opt
####################################################################################################

# set_stage: Comando para aplicar configuraciones por etapa
# Configuraciones de set_stage -step post_route
set_app_options -name time.remove_clock_reconvergence_pessimism -value true
set_app_options -name time.enable_ccs_rcv_cap -value true
set_app_options -name time.delay_calc_waveform_analysis_mode -value full_design
set_app_options -name route.detail.eco_route_use_soft_spacing_for_timing_optimization -value false
set_app_options -name route_opt.flow.enable_ccd -value true

set_app_options -name route_opt.flow.enable_clock_power_recovery -value none
set_app_options -name route_opt.flow.enable_power -value true
set_app_options -name ccd.timing_effort -value high
set_app_options -name ccd.fmax_optimization_effort -value high

if {$habilitar_creacion_blindaje} {
    # El ruteador vuelve a agregar blindaje a las nets modificadas
    set_app_options -name route.common.reshield_modified_nets -value reshield
}

# Prefijos
set_app_options -name opt.common.user_instance_name_prefix -value route_opt_
set_app_options -name cts.common.user_instance_name_prefix -value route_opt_cts_

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

# Chequeo de configuraciones de la etapa route_opt
redirect -file ${dir_reportes}/${etapa_actual}/${dir_configuraciones}/chequeo_configuraciones.rpt {check_stage_settings -stage pnr -metric ${metrica_estrategia_qor} -step post_route}

####################################################################################################
# Flujo route_opt
####################################################################################################

# Guarda la cantidad de DRCs antes de la optimizacion de ruteo
if {[get_drc_error_data -quiet zroute.err] == ""} {open_drc_error_data zroute.err}
set drc_antes_route_opt [sizeof_collection [get_drc_errors -quiet -error_data zroute.err]]

compute_clock_latency

# Ejecutamos hyper_route_opt en vez de route_opt para optimizaciones post-ruteo, porque es mas eficiente porque internamente hace varias pasadas
puts "\nINFO: Ejecutando hyper_route_opt.\n"
hyper_route_opt

# Insercion de vias redundantes
if {$habilitar_insercion_vias_redundantes} {
    add_redundant_vias
}

# Creacion de blindaje
if {$habilitar_creacion_blindaje} {
    create_shields -shielding_mode reshield
    set_extraction_options -virtual_shield_extraction false
}

# Guarda la cantidad de DRCs despues de la optimizacion de ruteo
if {[get_drc_error_data -quiet zroute.err] == ""} {open_drc_error_data zroute.err}
set drc_despues_route_opt [sizeof_collection [get_drc_errors -quiet -error_data zroute.err]]

####################################################################################################
# Ruteo incremental para arreglar DRCs restantes
####################################################################################################

# Comando de ruteo incremental
set comando_ruteo_incremental "route_detail -incremental true -initial_drc_from_input true"
if {$iteraciones_ruteo_incremental != ""} {lappend comando_ruteo_incremental -max_number_iterations $iteraciones_ruteo_incremental}

switch $modo_ruteo_incremental {
    "off" {puts "\nINFO: El ruteo incremental esta apagado, no se ejecutara\n"}
    "on" {puts "\nINFO: Ejecutando ruteo incremental\n"; eval $comando_ruteo_incremental}
    "auto" {
        if {\
            ($drc_antes_route_opt < $tope_drc_rute_incemental) && \
            ($drc_despues_route_opt > $drc_min_ruteo_incremental) && \
            (($drc_despues_route_opt - $drc_antes_route_opt) > ($drc_antes_route_opt * $porcent_incr_drc_ruteo_incremental))\
        } {
            puts "\nINFO: Ejecutando ruteo incremental automatico\n"; eval $comando_ruteo_incremental
        }
    }
}

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