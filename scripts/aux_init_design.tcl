####################################################################################################
# Descripcion: Script para inicializar el diseno
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
set etapa_actual "init_design"

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

# Comienza mapeo de SAIF
saif_map -start

####################################################################################################
# Configuracion de la tecnologia
####################################################################################################

if {$nodo != ""} {
    set_technology -node $nodo
}

####################################################################################################
# Lectura de floorplan desde floorplan_tcl (desde write_floorplan) o floorplan_def (soporta multiples DEFs)
####################################################################################################

if {$floorplan_tcl != ""} {
    # Lee el floorplan en formato Tcl
    source $floorplan_tcl
} elseif {$floorplan_def != ""} {
    # Primero se chequea si todos los DEFs son validos, si no, read_def se omite
    set floorplan_def_incorrecto false
    foreach def $floorplan_def {
        if {![file exists [which $def]]} {
            puts "\nERROR: El archivo DEF de floorplan ($def) no es valido\n"
            set floorplan_def_incorrecto true
        }
    }
    if {!$floorplan_def_incorrecto} {
        puts "\nINFO: Creando floorplan desde el DEF...\n"
        # Lee el floorplan en formato DEF
        read_def -add_def_only_objects all [list $floorplan_def]

        if {$pg_en_floorplan_def} {
            # En caso que resolve_pg_nets devuelva un warning que cause la salida del bucle
            redirect -var x {catch {resolve_pg_nets}}
            puts $x
            if {[regexp ".*NDMUI-096.*" $x]} {
                puts "\nERROR: El archivo UPF podria tener un problema. Por favor revisarlo y corregirlo.\n"
            }
        }
    } else {
        puts "\nERROR: Al menos uno de los archivos floorplan_def especificados no es valido. Por favor corregirlo.\n"
    }
}

####################################################################################################
# Configuracion de la tecnologia
####################################################################################################

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
# Conexion de la red de PG
####################################################################################################

connect_pg_net

####################################################################################################
# Chequeo basico de floorplan
####################################################################################################

if {[flow_check_design -step init_design]} {
    puts "ERROR: El floorplan tiene problemas constructivos. Arreglalos antes de continuar. Saliendo de la herramienta..."
    exit
}

####################################################################################################
# Timing y constraints del diseno
####################################################################################################

# Lectura de los archivos de parasitos
# Estos modelos seran referenciados en los constraints de corners
foreach p [array name tluplus] {
    puts "\nINFO: \"read_parasitic_tech -tlup $tluplus($p) -layermap $itf_tlu_map($p) -name ${p}\"\n"
    read_parasitic_tech -tlup $tluplus($p) -layermap $itf_tlu_map($p) -name $p
}

# Escenarios multi-corner y multi-modo
source "mcmm_setup.tcl"

# Driving cell de entrada y carga maxima de salida
set puertos_clock [filter_collection [get_attribute [get_clocks] sources] object_class==port]
set puertos_datos_entrada [remove_from_collection [all_inputs] $puertos_clock]
puts "\nINFO: Estableciendo driving cell de entrada $driving_cell con transicion de subida $transicion_entrada_subida_max y transicion de bajada $transicion_entrada_bajada_max para todos los puertos de datos de entrada.\n"
set_driving_cell -lib_cell $driving_cell -from_pin A -pin X -input_transition_rise $transicion_entrada_subida_max -input_transition_fall $transicion_entrada_bajada_max [get_ports $puertos_datos_entrada]
puts "\nINFO: Estableciendo carga maxima $carga_max a todas las salidas.\n"
set_load $carga_max [all_outputs]

# False path de hold en los IOs
set escenarios_activos [get_scenarios -filter active]
set_scenario_status -active true [get_scenarios -filter hold]
puts "\nINFO: Deshabilitando el analisis de timing de hold para todas las entradas y salidas.\n"
foreach escenario [get_object_name [get_scenarios -filter hold]] {
    current_scenario $escenario
    set_false_path -hold -from [all_inputs]
    set_false_path -hold -to [all_outputs]
}
set_scenario_status -active false [get_scenarios -filter active]
set_scenario_status -active true $escenarios_activos

# Creacion de grupos de clock
set modo_actual [current_mode]
puts "\nINFO: Creando grupos de clock \"reg2out in2reg in2out\".\n"
foreach modo [get_object_name [all_modes]] {
    current_mode $modo
    group_path -name reg2out -to [all_outputs] ; # -weight 0.1
    group_path -name in2reg -from [remove_from_collection [all_inputs] [get_ports [get_attribute -quiet [all_clocks -mode $modo] sources]]] ; # -weight 0.1
    group_path -name in2out -from [remove_from_collection [all_inputs] [get_ports [get_attribute -quiet [all_clocks -mode $modo] sources]]] -to [all_outputs] ; # -weight 0.1
}
current_mode $modo_actual

####################################################################################################
# Transicion, capacidad, fanout y largo de net maximos del diseno
####################################################################################################

set escenario_actual [current_scenario]

# Transicion maxima
puts "\nINFO: Configurando transicion maxima del diseno ${transicion_max}.\n"
set_max_transition $transicion_max [current_design]
foreach $modo [get_object_name [all_modes]] {
    current_mode $modo
    set_max_transition $transicion_max [current_design] -mode $modo
    set_max_transition -data_path $transicion_max -mode $modo *
    set_max_transition -data_path $transicion_max [get_clocks *] -mode $modo
    set_max_transition -clock_path $clock_transicion_max [get_clocks *] -mode $modo
}

# Capacidad maxima
if {$capacidad_max != ""} {
    puts "\nINFO: Configurando capacidad maxima del diseno ${capacidad_max}.\n"
    set_max_capacitance $capacidad_max [current_design]
    foreach $modo [get_object_name [all_modes]] {
        current_mode $modo
        set_max_capacitance $capacidad_max [current_design] -moce $modo
        set_max_capacitance -data_path $capacidad_max [get_clocks *] -mode $modo
    }
}

# Fanout maximo
if {$fanout_max != ""} {
    puts "\nINFO: Cofigurando fanout maximo del diseno ${fanout_max}.\n"
    set_app_options -name opt.common.max_fanout -value $fanout_max
}

# Fanout maximo de tie cells
if {$tie_fanout_max != ""} {
    puts "\nINFO: Configurando fanout maximo de tie cells del diseno ${tie_fanout_max}.\n"
    set_app_options -name opt.tie_cell.max_fanout -value $tie_fanout_max
}

# Largo maximo de nets
if {$largo_net_max != ""} {
    puts "\nINFO: Configurando largo maximo de nets del diseno ${largo_net_max}.\n"
    set_app_options -name opt.common.max_net_length -value $largo_net_max
}

current_scenario $escenario_actual

####################################################################################################
# Configuraciones adicionales
####################################################################################################

# Configuracion de capas de ruteo max/min
if {$maxima_capa_routeo != ""} {set_ignored_layers -max_routing_layer $maxima_capa_routeo}
if {$minima_capa_routeo != ""} {set_ignored_layers -min_routing_layer $minima_capa_routeo}

# Reglas de ruteo de clock (NDRs)
source "cts_ndr.tcl"

# Restricciones de uso de celdas estandar (set_lib_cell_purpose: Dont use, tie cells, arreglos de hold y CTS)
source "set_lib_cell_purpose.tcl"

# Chequea y remueve shapes duplicadas en el diseno
set shapes_duplicadas [check_duplicates -return_as_collection]
if {[sizeof_collection $shapes_duplicadas] > 0} {
   remove_shapes -force $shapes_duplicadas
}

# Guarda el bloque para la etapa actual
save_block -as ${nombre_design}/${etapa_actual}

####################################################################################################
# Chequeos y reportes de QoR
####################################################################################################

set reportar_etapa init_design
set reportar_escenarios_activos $escenarios_activos_init_design
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
