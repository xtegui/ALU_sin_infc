####################################################################################################
# Script para reportar resultados (QoR)
####################################################################################################

if {[info exists reportar_etapa]} {
    puts "\nINFO: Etapa a reportar ${reportar_etapa}\n"
} else {
    puts "\nERROR: La variable reportar_etapa (etapa a reportar) no esta definida.\n"
}

# Escenarios activos
if {[info exists reportar_escenarios_activos] && $reportar_escenarios_activos != ""} {
    set_scenario_status -active false [get_scenarios -filter active]
    set_scenario_status -active true $reportar_escenarios_activos
}

####################################################################################################
# Timing y QoR
####################################################################################################

puts "\nINFO: Reportando timing y QoR ...\n"

# Se muestran path groups especiales (**async_default** y **clock_gating_default**) en el reporte de timing
# Nota: Los path groups definidos por el usuario tienen mayor precedencia que estos.
# set_app_options -name time.use_special_default_path_groups -value true ; # Por defecto: false

if {![regexp init_design $reportar_etapa]} {
    # Reporte de QoR
    redirect -file ${dir_reportes}/${etapa_actual}/${dir_estado}/qor.rpt {report_qor -scenarios [get_scenarios -filter active] -pba_mode [get_app_option_value -name time.pba_optimization_mode] -nosplit}
    redirect -tee -append -file ${dir_reportes}/${etapa_actual}/${dir_estado}/qor.rpt {report_qor -summary -pba_mode [get_app_option_value -name time.pba_optimization_mode] -nosplit}
    #redirect -file ${dir_reportes}/${etapa_actual}/proc_qor {proc_qor -pba_mode [get_app_option_value -name time.pba_optimization_mode]} ; ### PSOSA: TODO chequear proc proc_qor (proc gigante, sacar?)

    # Reporte de timing global
    redirect -tee -file ${dir_reportes}/${etapa_actual}/${dir_timing}/timing_global.rpt {report_global_timing -pba_mode [get_app_option_value -name time.pba_optimization_mode] -nosplit}

    # Reporte de timing max (setup)
    redirect -file ${dir_reportes}/${etapa_actual}/${dir_timing}/timing_setup.rpt {report_timing -delay max -scenarios [get_scenarios -filter active] \
        -input_pins -nets -transition_time -capacitance -attributes -physical -derate -crosstalk -report_by group -pba_mode [get_app_option_value -name time.pba_optimization_mode] -nosplit}

    foreach_in_collection scenario [get_scenarios -filter {active && setup}] {
        set nombre_escenario [get_object_name $scenario]
        redirect -file ${dir_reportes}/${etapa_actual}/${dir_timing}/timing_setup_final_${nombre_escenario}.rpt {report_timing -delay max -path end -nosplit -max_paths 5000 -scenarios ${nombre_escenario}}
        if {$report_timing_verbose} {
            redirect -file ${dir_reportes}/${etapa_actual}/${dir_timing}/timing_setup_${nombre_escenario}.rpt {report_timing -delay max -scenarios ${nombre_escenario} -path_type full_clock_expanded \
                -input_pins -nets -transition_time -capacitance -attributes -physical -derate -crosstalk -report_by group -pba_mode [get_app_option_value -name time.pba_optimization_mode] -nosplit -max_paths 300 -slack_lesser_than 0.0}
        }
    }

    # Reporte de timing min (hold) para etapas post-CTS
    if {![regexp init_design|mapped|synthesis|placement $reportar_etapa]} {
        redirect -file ${dir_reportes}/${etapa_actual}/${dir_timing}/timing_hold.rpt {report_timing -delay min -scenarios [get_scenarios -filter active] \
            -input_pins -nets -transition_time -capacitance -attributes -physical -derate -crosstalk -report_by group -pba_mode [get_app_option_value -name time.pba_optimization_mode] -nosplit}

        foreach_in_collection scenario [get_scenarios -filter {active && hold}] {
            set nombre_escenario [get_object_name $scenario]
            redirect -file ${dir_reportes}/${etapa_actual}/${dir_timing}/timing_hold_final_${nombre_escenario}.rpt {report_timing -delay min -path end -nosplit -max_paths 5000 -scenarios ${nombre_escenario}}
            if {$report_timing_verbose} {
                redirect -file ${dir_reportes}/${etapa_actual}/${dir_timing}/timing_hold_${nombre_escenario}.rpt {report_timing -delay min -scenarios ${nombre_escenario} -path_type full_clock_expanded \
                    -input_pins -nets -transition_time -capacitance -attributes -physical -derate -crosstalk -report_by group -pba_mode [get_app_option_value -name time.pba_optimization_mode] -nosplit -max_paths 300 -slack_lesser_than 0.0}
            }
        }
    }

    # Reporte de violaciones de transicion y capacidad (DRV: Design Rule Violations)
    redirect -file ${dir_reportes}/${etapa_actual}/${dir_timing}/drv.rpt {report_constraint -all_violators -max_transition -max_capacitance -scenarios [get_scenarios -filter active] -nosplit}
}

# Debug
puts "\nINFO: Analizando violaciones del diseno ...\n"

# El comando agregara automaticamente el tipo de analisis (setup o hold) como parte del nombre del reporte
# Por ejemplo, el nombre del reporte para setup seria ${dir_reportes}/${etapa_actual}/analyze_design_violations.setup

# analyze_design_violations para setup
if {[regexp synthesis|placement|post_cts_opt $reportar_etapa]} {
    analyze_design_violations -type setup -stage preroute -output ${dir_reportes}/${etapa_actual}/${dir_timing}/analisis_violaciones
} elseif {[regexp post_route $reportar_etapa]} {
    analyze_design_violations -type setup -stage postroute -output ${dir_reportes}/${etapa_actual}/${dir_timing}/analisis_violaciones
}

# analyze_design_violations para hold
if {[regexp post_cts_opt $reportar_etapa]} {
    analyze_design_violations -type hold -stage preroute -output ${dir_reportes}/${etapa_actual}/${dir_timing}/analisis_violaciones
} elseif {[regexp post_route $reportar_etapa]} {
    analyze_design_violations -type hold -stage postroute -output ${dir_reportes}/${etapa_actual}/${dir_timing}/analisis_violaciones
}

# Reportes varios
if {[regexp synthesis|mapped $reportar_etapa]} {
    redirect -file ${dir_reportes}/${etapa_actual}/${dir_estado}/registros_transformados.rpt {report_transformed_registers -nosplit}
    redirect -file ${dir_reportes}/${etapa_actual}/${dir_estado}/clock_gating.rpt {report_clock_gating -nosplit}
    redirect -file ${dir_reportes}/${etapa_actual}/${dir_estado}/recursos.rpt {report_resources -nosplit}
    redirect -file ${dir_reportes}/${etapa_actual}/${dir_estado}/niveles_logicos.rpt {report_logic_levels -nosplit}
    #redirect -file ${dir_reportes}/${etapa_actual}/${dir_estado}/dft.rpt {report_dft -nosplit}
    redirect -file ${dir_reportes}/${etapa_actual}/${dir_potencia}/actividad_rtl.rpt {report_activity -rtl}
    redirect -file ${dir_reportes}/${etapa_actual}/${dir_potencia}/actividad_driver_final.rpt {report_activity -driver}
}
if {![regexp init_design|synthesis|mapped $reportar_etapa]} {
    redirect -file ${dir_reportes}/${etapa_actual}/${dir_potencia}/actividad.rpt {report_activity -verbose}
}

####################################################################################################
# QoR de arboles de clock
####################################################################################################

if {![regexp init_design|mapped|synthesis|placement $reportar_etapa]} {
    puts "\nINFO: Reportando informacion de las redes de clock y QoR ...\n"
    redirect -tee -file ${dir_reportes}/${etapa_actual}/${dir_clocks}/resumen_clock_qor.rpt {report_clock_qor -nosplit}
    parallel_execute {
        {report_clock_qor -type latency -show_paths -nosplit} ${dir_reportes}/${etapa_actual}/${dir_clocks}/latencia_clocks.rpt
        {report_clock_qor -type area -nosplit} ${dir_reportes}/${etapa_actual}/${dir_clocks}/area_celdas_clock.rpt
        {report_clock_qor -type structure -nosplit} ${dir_reportes}/${etapa_actual}/${dir_clocks}/estructura_clocks.rpt
        {report_clock_qor -type drc_violators -all -nosplit} ${dir_reportes}/${etapa_actual}/${dir_clocks}/drc_clocks.rpt
        {report_clock_timing -type summary -clock_synthesis_view -scenarios [get_scenarios -filter active] -nosplit} ${dir_reportes}/${etapa_actual}/${dir_clocks}/resumen_timing_clocks.rpt
        {report_clock_timing -type skew -clock_synthesis_view -scenarios [get_scenarios -filter active] -nosplit} ${dir_reportes}/${etapa_actual}/${dir_clocks}/skew_clocks.rpt
        {report_clock_timing -type latency -clock_synthesis_view -scenarios [get_scenarios -filter active] -nosplit} ${dir_reportes}/${etapa_actual}/${dir_clocks}/latencia_timing_clocks.rpt
    }
    if {[get_app_option_value -name cts.compile.enable_local_skew] || [get_app_option_value -name cts.optimize.enable_local_skew] || [get_app_option_value -name clock_opt.flow.enable_ccd]} {\
        redirect -file ${dir_reportes}/${etapa_actual}/${dir_clocks}/skew_local_clocks.rpt {report_clock_qor -type local_skew -nosplit}
    }
}

if {$reportar_potencia_clock && [regexp cts|post_route $reportar_etapa]} {
    if {[sizeof_collection [get_scenarios -filter "active && (dynamic_power || leakage_power)"]] > 0} {
        puts "\nINFO: Ejecutando report_clock_qor -type power ...\n"
        redirect -file ${dir_reportes}/${etapa_actual}/${dir_clocks}/potencia_clocks.rpt {report_clock_qor -type power -nosplit}
    }
}

####################################################################################################
# Analisis de potencia
####################################################################################################

if {![regexp init_design $reportar_etapa]} {
    redirect -file ${dir_reportes}/${etapa_actual}/${dir_estado}/grupos_vt.rpt {report_threshold_voltage_group -nosplit}
}

if {$reportar_power && ![regexp init_design $reportar_etapa]} {
    puts "\nINFO: Ejecutando report_power ...\n"
    redirect -file ${dir_reportes}/${etapa_actual}/${dir_potencia}/potencia.rpt {report_power -verbose -scenarios [get_scenarios -filter active] -nosplit}

    set escenarios_potencia [get_scenarios -filter "leakage_power==true||dynamic_power==true"]
    if { [sizeof_collection $escenarios_potencia] > 0 } {
        puts "\nINFO: Ejecutando report_power ...\n"

        # Activar escenarios de potencia inactivos
        if { [sizeof_collection [filter_collection $escenarios_potencia "active==false"]] > 0 } {
            set escenarios_potencia_inactivos [filter_collection $escenarios_potencia "active==false"]
            set_scenario_status $escenarios_potencia_inactivos -active true
        } else {
            set escenarios_potencia_inactivos {}
        }

        # Recuperar todos los escenarios de potencia
        set escenarios_potencia [get_scenarios -filter "leakage_power==true||dynamic_power==true"]

        # Reporte de potencia
        redirect -tee -file ${dir_reportes}/${etapa_actual}/${dir_potencia}/potencia.rpt {report_power -verbose -scenarios $escenarios_potencia -nosplit}

        # Volver a desactivar los escenarios de potencia
        if { [sizeof_collection $escenarios_potencia_inactivos] > 0 } {
            set_scenario_status $escenarios_potencia_inactivos -active false
        }

    } else {
        puts "\nINFO: No se encontraron escenarios de analisis de potencia. Omitiendo report_power.\n"
    }
}

####################################################################################################
# Reportes de configuracion de escenarios
####################################################################################################

puts "\nINFO: Ejecutando timing constraints ...\n"
parallel_execute {
    {report_modes -nosplit} ${dir_reportes}/${etapa_actual}/${dir_escenarios}/modos.rpt
    {report_pvt -nosplit} ${dir_reportes}/${etapa_actual}/${dir_escenarios}/pvt.rpt
    {report_corners [all_corners]} ${dir_reportes}/${etapa_actual}/${dir_escenarios}/corners.rpt
}
redirect -file ${dir_reportes}/${etapa_actual}/${dir_escenarios}/escenarios.rpt {report_scenarios -nosplit}
redirect -file ${dir_reportes}/${etapa_actual}/${dir_clocks}/clocks.rpt {report_clocks -mode [all_modes] -nosplit}

####################################################################################################
# Reportes de informacion del diseno
####################################################################################################

puts "\nINFO: Reportando informacion del diseno ...\n"
if {[regexp init_design $reportar_etapa]} {
    redirect -file ${dir_reportes}/${etapa_actual}/${dir_estado}/reporte_diseno.rpt {report_design -library -floorplan -nosplit}
} elseif {[regexp cts|post_cts_opt|route|post_route $reportar_etapa]} {
    redirect -file ${dir_reportes}/${etapa_actual}/${dir_estado}/reporte_diseno.rpt {report_design -library -netlist -floorplan -routing -nosplit}
} else {
    redirect -file ${dir_reportes}/${etapa_actual}/${dir_estado}/reporte_diseno.rpt {report_design -library -netlist -floorplan -nosplit}
    redirect -file ${dir_reportes}/${etapa_actual}/${dir_estado}/tracks.rpt {report_tracks -nosplit}
}

set rm_lib_type [get_attribute -quiet [current_design] rm_lib_type]
if {$rm_lib_type != ""} {puts "\nINFO: rm_lib_type = ${rm_lib_type}\n"}
if {![regexp init_design|mapped $reportar_etapa]} {
    if { [regexp {h$} $rm_lib_type] } {
        create_utilization_configuration no_physical -capacity site_row -exclude {hard_macros macro_keepouts soft_macros io_cells hard_blockages physical_only_cells}
        redirect -tee -file ${dir_reportes}/${etapa_actual}/${dir_estado}/utilizacion.rpt {report_utilization -hybrid -config no_physical}
    } else {
        redirect -tee -file ${dir_reportes}/${etapa_actual}/${dir_estado}/utilizacion.rpt {report_utilization}
    }
}

if {![regexp init_design $reportar_etapa]} {
    redirect -file ${dir_reportes}/${etapa_actual}/${dir_estado}/referencias_celdas.rpt {report_reference -hierarchical -nosplit}
}
# redirect -file ${dir_reportes}/${etapa_actual}/report_ignored_layers {report_ignored_layers}
# redirect -file ${dir_reportes}/${etapa_actual}/report_extraction_options {report_extraction_options -corners [all_corners]}

####################################################################################################
# check_design, check_netlist y check_legality
####################################################################################################

puts "\nINFO: Chequeando problemas del diseno ...\n"

# Corre el mega chequeo predefinido pre_placement_stage que incluye chequeos como mv_design, design_mismatch, rp_constraints, timing, y cadenas de scan
if {[regexp init_design $reportar_etapa]} {
    redirect -file ${dir_reportes}/${etapa_actual}/${dir_estado}/chequeo_diseno_pre_placement.rpt {check_design -ems_database ${dir_reportes}/${etapa_actual}/${dir_ems}/chequeo_diseno_pre_placement.ems -log_file ${dir_reportes}/${etapa_actual}/${dir_ems}/chequeo_diseno_pre_placement.log -checks pre_placement_stage}
    redirect -file ${dir_reportes}/${etapa_actual}/${dir_estado}/chequeo_netlist.rpt {check_netlist -summary}
}

# Corre el mega chequeo predefinido pre_clock_tree_stage que incluye chequeos como mv_design, design_mismatch, timing, cadenas de scan, legalidad, design_extraction, y redes de clock
if {[regexp synthesis|placement $reportar_etapa]} {
    redirect -file ${dir_reportes}/${etapa_actual}/${dir_estado}/chequeo_diseno_pre_arbol_clock.rpt {check_design -ems_database ${dir_reportes}/${etapa_actual}/${dir_ems}/chequeo_diseno_pre_arbol_clock.ems -log_file ${dir_reportes}/${etapa_actual}/${dir_ems}/chequeo_diseno_pre_arbol_clock.log -checks pre_clock_tree_stage}
}

# Corre check_legality
if {![regexp init_design $reportar_etapa]} {
    redirect -file ${dir_reportes}/${etapa_actual}/${dir_estado}/chequeo_legalizacion.rpt {check_legality -verbose}
}

####################################################################################################
# Miscelaneos
####################################################################################################

puts "\nINFO: Reportando unidades ...\n"
if {[regexp init_design $reportar_etapa]} {
    redirect -file ${dir_reportes}/${etapa_actual}/${dir_configuraciones}/unidades.rpt {report_units -nosplit}
    redirect -file ${dir_reportes}/${etapa_actual}/${dir_configuraciones}/unidades_usuario.rpt {report_user_units -nosplit}
}

puts "\nINFO: Reportando configuraciones que no estan por defecto ...\n"
redirect -file ${dir_reportes}/${etapa_actual}/${dir_configuraciones}/app_options_final.rpt {report_app_options -non_default *}
puts "\nINFO: Reportando informacion de redes ideales ...\n"
redirect -file ${dir_reportes}/${etapa_actual}/${dir_estado}/redes_ideales.rpt {report_ideal_network -scenarios [get_scenarios -filter active]}

####################################################################################################
# report_drc_error despues de route_auto
####################################################################################################

if {[regexp route|post_route $reportar_etapa]} {
    if {[get_drc_error_data -quiet zroute.err] == ""} {open_drc_error_data zroute.err}
    redirect -tee -file ${dir_reportes}/${etapa_actual}/${dir_estado}/drc.rpt {report_drc_error -error_data zroute.err}
}

####################################################################################################
# report_congestion y mapa de congestion de global route
####################################################################################################

if {$reportar_congestion && [regexp synthesis|placement|cts|post_cts_opt $reportar_etapa]} {
    set_app_options -name route.global.timing_driven -value true
    if {![regexp post_cts_opt $reportar_etapa]} {
        redirect -tee -file ${dir_reportes}/${etapa_actual}/${dir_estado}/congestion.rpt {report_congestion -layers [get_layers -filter "layer_type==interconnect"] -rerun_global_router -nosplit}
    } else {
        redirect -tee -file ${dir_reportes}/${etapa_actual}/${dir_estado}/congestion.rpt {report_congestion -layers [get_layers -filter "layer_type==interconnect"] -nosplit}
    }
    if {[info exists env(DISPLAY)] && ![catch {gui_start}]} {
        #gui_execute_menu_item -menu "View->Layout View"
        gui_execute_menu_item -menu "View->Map->Global Route Congestion"
        gui_write_window_image -format png -file ${dir_reportes}/${etapa_actual}/${dir_estado}/congestion.png
        gui_stop
    } else {
        puts "\nINFO: env(DISPLAY) no esta definido. Se omitio la captura del mapa de congestion de global_route\n"
    }
}

####################################################################################################
# write_qor_data
####################################################################################################

if {$escribir_qor} {
    set etiqueta_qor $etapa_actual
    if {[regexp init_design $reportar_etapa]} {
        ## No op
    } elseif {[regexp synthesis|placement $reportar_etapa]} {
        write_qor_data -report_group placed -label $etiqueta_qor -output $dir_qor -exclude_list "performance host_machine report_app_options"
    } elseif {[regexp init_design|mapped $reportar_etapa]} {
        write_qor_data -report_group mapped -label $etiqueta_qor -output $dir_qor -exclude_list "performance host_machine report_app_options"
    } elseif {[regexp cts|post_cts_opt $reportar_etapa]} {
        write_qor_data -report_group cts -label $etiqueta_qor -output $dir_qor -exclude_list "performance host_machine report_app_options"
    } else {
        write_qor_data -report_group routed -label $etiqueta_qor -output $dir_qor -exclude_list "performance host_machine report_app_options"
    }

    if {![regexp init_design $reportar_etapa]} {
        compare_qor_data -run_locations $dir_qor -force -output $dir_comparacion_qor
    }

    # Corre el mega chequeo predefinido pre_route_stage que incluye chequeos como mv_design, design_mismatch, timing, cadenas de scan, design_extraction, y ruteabilidad
    if {[regexp post_cts_opt $reportar_etapa]} {
        redirect -file ${dir_reportes}/${etapa_actual}/${dir_estado}/cheque_diseno_pre_ruteo.rpt {check_design -ems_database ${dir_reportes}/${etapa_actual}/${dir_ems}/chequeo_diseno_pre_ruteo.ems -log_file ${dir_reportes}/${etapa_actual}/${dir_ems}/chequeo_diseno_pre_ruteo.log -checks pre_route_stage}
    }
}

####################################################################################################
# Otros reportes
####################################################################################################

# report_ccd_timing : Reports CCD timing information of a design
# - To Print D slacks and Q slacks of the top 5 critical endpoints
#   (D slack : worst slack of the paths captured by a flop)
#   (Q slack : worst slack of the paths lauched by a flop)
# report_ccd_timing
# - To report slacks of timing paths that precede or succeed a critical end point with a specified stage number up/down the chain
# report_ccd_timing -type stage -pin <pin> -max_stages <integer>
# - To report top 5 timing paths in the fanin(fanout) cone of a critical end point
# report_ccd_timing -type fanin -pin <pin>

