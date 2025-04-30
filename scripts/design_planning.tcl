####################################################################################################
# Descripcion: Script para design planning (diseno de floorplan)
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

# Manejo de mensajes de la herramienta
suppress_message ATTR-11 ; # Surpime la informacion que hay valores de atributos que prevalecen sobre los valores en las librerias
# set_message_info -id ATTR-11 -limit 1 ; # Limita el mensaje a 1 ocurrencia
set_message_info -id PVT-012 -limit 1
set_message_info -id PVT-013 -limit 1

# Informacion de la ejecucion en el log
puts "INFO: Informacion de la ejecucion"
puts " - Maquina: [sh hostname]"
puts " - Fecha: [date]"
puts " - ID proceso: [pid]"
puts " - Directorio: [pwd]"

set etapa_anterior ""
set etapa_actual "design_planning"

puts "\nINFO: Etapa actual: ${etapa_actual}\n"

file mkdir ${dir_reportes}/${etapa_actual}

# Directorios para categoria de reportes
set dir_estado "estado"
file mkdir ${dir_reportes}/${etapa_actual}/${dir_estado}
set dir_ems "base_datos_ems"
file mkdir ${dir_reportes}/${etapa_actual}/${dir_ems}

# Informacion de comienzo
set tiempo_comienzo [clock seconds]
puts "\nINFO: Comienzo: [clock format $tiempo_comienzo -format {%H:%M:%S - %d %b %Y}]\n"

####################################################################################################
# Creacion de la libreria del diseno
####################################################################################################

if {[file exists $nombre_design]} {
    file delete -force $nombre_design
}

puts "\nINFO: create_lib $nombre_design -tech $techfile -ref_libs ${librerias_referencia}\n"
create_lib $nombre_design -tech $techfile -ref_libs $librerias_referencia
redirect -file ${dir_reportes}/${etapa_actual}/${dir_estado}/ref_libs.rpt {report_ref_libs}

####################################################################################################
# Configuraciones de lectura del RTL
####################################################################################################

set_app_options -as_user_default -name design.bus_delimiters -value {[]} ; # Especifica los delimitadores de buses de datos. Ejemplo: i_datos[4]
set_app_var bus_extraction_style {%s[%d:%d]} ; # Especifica el estilo de buses como nombre[num:num]. Ejemplo: i_datos[0:7]
set synthetic_design_naming_style {%s_%d} ; #
set_app_var change_names_update_inst_tree true ; #
set_app_options -as_user_default -name hdlin.elaborate.preserve_sequential -value all ; # Todos los secuenciales sin carga son preservados
set_app_options -as_user_default -name hdlin.report.check_no_latch -value true ; # Imprime un mensaje de advertencia cuando se infiere in latch en el diseno
set_app_var enable_analysis_info false ; # 
set_app_options -as_user_default -name time.disable_case_analysis -value false ; # Evita que se deshabiliten los constraints de case_analysis
set_app_options -as_user_default -name hdlin.elaborate.ff_infer_sync_set_reset -value true ; # Permite usar flip-flops con set/reset sincronos
set hdlin_force_template_style true ; #
set_app_options -as_user_default -name hdlin.naming.template_naming_style -value "%s" ; # Cambio de %s_%p a %s (remueve parámetros de los nombres)
set_app_options -as_user_default -name hdlin.report.sequential_pruning -value true ; # Emite un mensaje cuando un registro es removido
set_app_options -as_user_default -name link.bit_blast_naming_style -value "%s\[%d\] %s(%d) %s_%d" ; # Permite interpretar disenos con diferentes estilos de nombres de buses. Ejemplo: i_datos\[4\] , i_datos(4) o i_datos_4
set_app_var hdlin_enable_hier_map true ; #

####################################################################################################
# Lectura del diseno RTL
####################################################################################################

set_svf ${dir_salidas}/${etapa_actual}.svf

# Lectura de lista de directorios include
if {[file exist ${dir_lista_rtl}/include_dir_list.lst]} {
    puts "\nINFO: Leyendo lista de directorios include desde '${dir_lista_rtl}/include_dir_list.lst' ...\n"
    set f [open "${dir_lista_rtl}/include_dir_list.lst"]
    set search_path "$search_path [subst [join [split [read $f] \n]]]"
    close $f
} else {
    puts "\nINFO: El archivo '${dir_lista_rtl}/include_dir_list.lst' no existe. No se usara ningun directorio de includes.\n"
}

# Lectura de lista de archivos RTL
if {[file exist ${dir_lista_rtl}/verilog_list.lst]} {
    puts "\nINFO: Leyendo lista de archivos RTL desde '${dir_lista_rtl}/verilog_list.lst' ...\n"
    set f [open "${dir_lista_rtl}/verilog_list.lst"]
    set archivos_rtl [subst [join [split [read $f] \n]]]
    close $f
} else {
    puts "\nINFO: El archivo '${dir_lista_rtl}/verilog_list.lst' no existe. Por favor chequear.\n"
}

# Analisis y elaboracion del diseno
analyze -format sverilog ${archivos_rtl}
elaborate ${nombre_design}

set_top_module ${nombre_design}

# Guarda el diseno elaborado
save_block -as ${nombre_design}/${etapa_actual}_elaborated

# Nombres de modulos unicos
set_app_option -name design.uniquify_naming_style -value ${nombre_design}_%s_%d
puts "\nINFO: Haciendo modulos unicos: uniquify -force\n"
uniquify -force

# Cambio de nombres de senales para usar solo caracteres permitidos
define_name_rules verilog -allowed "A-Z a-z 0-9 _" -replacement_char "_"
change_names -rules verilog -hierarchy

# Reportes de chequeo del diseno
redirect -file ${dir_reportes}/${etapa_actual}/${dir_estado}/chequeo_diseno_incompatibilidades.rpt {check_design -ems_database ${dir_reportes}/${etapa_actual}/${dir_ems}/chequeo_diseno_incompatibilidades.ems -log_file ${dir_reportes}/${etapa_actual}/${dir_ems}/chequeo_diseno_incompatibilidades.log -checks design_mismatch}
redirect -file ${dir_reportes}/${etapa_actual}/${dir_estado}/incompatibiliades_diseno.rpt {report_design_mismatch -verbose}
redirect -file ${dir_reportes}/${etapa_actual}/${dir_estado}/unbound.rpt {report_unbound}

####################################################################################################
# Configuracion de la tecnologia
####################################################################################################

if {$nodo != ""} {
    set_technology -node $nodo
}

# Configuracion de routing_direction y track_offset
if {$layer_direccion_offset != ""} {
    foreach par_direccion_offset $layer_direccion_offset {
        set layer [lindex $par_direccion_offset 0]
        set direccion [lindex $par_direccion_offset 1]
        set offset [lindex $par_direccion_offset 2]
        set_attribute [get_layers $layer] routing_direction $direccion
        if {$offset != ""} {
            set_attribute [get_layers $layer] track_offset $offset
        }
    }
} else {
    puts "\nADVERTENCIA: layer_direccion_offset no fue especificado. Debes configurar manualmente routing_directions y track_offsets\n"
}

# Configuracion de site_default
if {$site_default != ""} {
    set_attribute [get_site_defs] is_default false
    set_attribute [get_site_defs $site_default] is_default true
}

# Configuracion de site_symmetry
if {$site_simetria != ""} {
    foreach par_site_simetria $site_simetria {
        set nombre_site [lindex $par_site_simetria 0]
        set simetria [lindex $par_site_simetria 1]
        set_attribute [get_site_defs $nombre_site] symmetry $simetria
    }
}

# Configuracion de capas multi-mascaras
foreach capa_mm $capas_multi_mascara {
    puts "\nINFO: Configurando capa [lindex $capa_mm 0] con numero de mascaras [lindex $capa_mm 1].\n"
    set_attribute [get_layers [lindex $capa_mm 0]] number_of_masks [lindex $capa_mm 1]
}

####################################################################################################
# Creacion de redes de power/ground
####################################################################################################

create_net -power $nombre_power
create_net -ground $nombre_ground

####################################################################################################
# Diseno de floorplan: initialize_floorplan
####################################################################################################

# Inicializacion del floorplan
initialize_floorplan -flip_first_row false -control_type die -side_length [list $ancho_floorplan $alto_floorplan] -core_offset $core_offset

# Creacion de tracks
# source "track_creation.tcl" ; # PSOSA: TODO chequear tracks

####################################################################################################
# Ubicacion de puertos
####################################################################################################

# Script con configuracion de puertos
source $ubicacion_puertos

# Check Design: Pre-Pin Placement
redirect -file ${dir_reportes}/${etapa_actual}/${dir_estado}/chequeo_diseno_pre_ubicacion_puertos.rpt {check_design -ems_database ${dir_reportes}/${etapa_actual}/${dir_ems}/chequeo_diseno_pre_ubicacion_puertos.ems -log_file ${dir_reportes}/${etapa_actual}/${dir_ems}/chequeo_diseno_pre_ubicacion_puertos.log -checks dp_pre_pin_placement}

# Ubicacion de puertos
place_pins -self

# Configuracion de los puertos como fijos para que no puedan ser movidos
set lista_puertos [get_ports -quiet -filter "port_type!=power && port_type!=ground && physical_status==placed"]
if {[sizeof_collection $lista_puertos] > 0} {
  set_attribute $lista_puertos physical_status "fixed"
}

# Chequeo y reporte de puertos sin ubicacion
set puertos_no_ubicados [get_ports -quiet -filter "port_type!=power && port_type!=ground && physical_status==unplaced"]
foreach_in_collection puerto $puertos_no_ubicados {
  set nombre_puerto [get_object_name $puerto]
  puts "\nADVERTENCIA: El puerto \"$nombre_puerto\" no tiene ubicacion.\n"
  #exit
}

# Escritura de puertos basada en la ubicacion actual
write_pin_constraints -self \
  -file_name $dir_salidas/preferred_port_locations.tcl \
  -physical_pin_constraint {side | offset | layer} \
  -from_existing_pins

# Verificacion de reglas de ubicacion de puertos
redirect -file ${dir_reportes}/${etapa_actual}/${dir_estado}/chequeo_ubicacion_puertos.rpt {check_pin_placement -self -pre_route true -pin_spacing true -sides true -layers true -stacking true}

# Guarda el bloque para la etapa actual
save_block -as ${nombre_design}/${etapa_actual}_place_pins

####################################################################################################
# Insercion de boundary cells
####################################################################################################

source "create_boundary_cells.tcl"

####################################################################################################
# Insercion de tap cells
####################################################################################################

source "create_tap_cells.tcl"

# Guarda el bloque para la etapa actual
save_block -as ${nombre_design}/${etapa_actual}_boundary_taps

####################################################################################################
# Insercion de grilla de power/ground (PG)
####################################################################################################

# Conecta las tap y boundary cells antes de compilar la PG
connect_pg_net -automatic

# Script para insertar la grilla de PG
source "compile_pg.tcl"

# Guarda el bloque para la etapa actual
save_block -as ${nombre_design}/${etapa_actual}_pg

# Continuar la ejecucion ante la falta del archivo scandef (sin DFT)
set_app_options -name place.coarse.continue_on_missing_scandef -value true

# Chequea la conectividad fisica de la grilla PG
redirect -file ${dir_reportes}/${etapa_actual}/${dir_estado}/chequeo_conectividad_pg.rpt {check_pg_connectivity}

# Create DRC error report for PG
redirect -file ${dir_reportes}/${etapa_actual}/${dir_estado}/chequeo_drc_pg.rpt {check_pg_drc}

# Guarda el bloque para la etapa actual
save_block -as ${nombre_design}/${etapa_actual}

####################################################################################################
# Escritura de salida del floorplan
####################################################################################################

puts "\nINFO: Ejecutando write_floorplan...\n"
write_floorplan \
  -format icc2 \
  -def_version 5.8 \
  -force \
  -read_def_options {-add_def_only_objects {all} -skip_pg_net_connections} \
  -exclude {scan_chains fills pg_metal_fills routing_rules} \
  -net_types {power ground} \
  -include_physical_status {fixed locked} -output ${dir_salidas}/${etapa_actual}_write_floorplan

puts "\nINFO: Ejecutando write_def...\n"
write_def -compress gzip -version 5.8 -include_tech_via_definitions ${dir_salidas}/${nombre_design}_${etapa_actual}.def

####################################################################################################
# Finalizacion de la ejecucion
####################################################################################################

# Informacion de la ejecucion
set tiempo_final [clock seconds]
set runtime [expr $tiempo_final - $tiempo_comienzo]
set runtime [expr $runtime/60]
set memKB [get_mem]
set memGB [expr ($memKB * 1.0)/(1024*1024)]

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
