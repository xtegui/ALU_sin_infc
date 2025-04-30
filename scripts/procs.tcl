####################################################################################################
# Script para cargar los procs que se usan en todo el flujo
####################################################################################################

####################################################################################################
# flow_check_design: Chequeos basicos de floorplan
####################################################################################################
proc flow_check_design { args } {

    parse_proc_arguments -args $args opciones

    if {[info exists opciones(-step)]} { set step $opciones(-step) }

    if {[current_design] != ""} {
        if { [string equal ${step} init_design] } {
            set error_detectado 0 ; # Alerta de errors

            # Chequeo de existencia de rows
            if {[sizeof_collection [get_site_rows -quiet]] == 0 && [sizeof_collection [get_site_arrays -quiet]] == 0} {
                set error_detectado 1
                puts "\nERROR: El diseno no tiene site rows o site arrays. Por favor arreglarlo antes de continuar.\n"
            }
            # Chequeo de existencia de puertos
            if {[sizeof_collection [get_terminals -filter "port.port_type==signal" -quiet]] == 0} {
                set error_detectado 1
                puts "\nERROR: El diseno no tiene terminales de senal. Por favor arreglarlo antes de continuar.\n"
            }
            # Chequeo de existencia de tracks
            if {[sizeof_collection [get_tracks -quiet]] == 0} {
                set error_detectado 1
                puts "\nERROR: El diseno no tiene tracks. Por favor arreglarlo antes de continuar.\n"
            }
            # Chequeo de existencia de PG
            if {[sizeof_collection [get_shapes -filter "net_type==power"]] == 0 || [sizeof_collection [get_shapes -filter "net_type==ground"]] == 0} {
                set error_detectado 1
                puts "\nADVERTENCIA: El diseno no contiene ningun objeto de PG (power/ground). No existe una estructura de PG apropiada. Si esto es inesperado, por favor arreglarlo antes de continuar.\n"
            }
            # Chequeo de celdas macro no ubicadas
            if {[sizeof_collection [get_cells -hier -filter "is_hard_macro&&!is_placed"]]} {
                set error_detectado 1
                puts "\nERROR: El diseno tiene macros no ubicadas. Por favor arreglarlo antes de continuar.\n"
            }
            # Chequeo de existencia de boundary y tap cells
            if {[sizeof_collection [get_cells -hier -filter "is_physical_only&&(design_type=~*cap||design_type=~*tap)"]] == 0} {
                puts "\nADVERTENCIA: El diseno no tiene boundary o tap cells. Si esto es inesperado, por favor arreglarlo antes de continuar.\n"
            }
            # Chequeo de boundary y tap cells no ubicadas o no fijas
            if {[sizeof_collection [get_cells -hier -filter "is_physical_only&&(design_type=~*cap||design_type=~*tap)&&(!is_placed||!is_fixed)"]]} {
                set error_detectado 1
                puts "\nERROR: El diseno tiene boundary o tap cells no ubicadas. Por favor arreglarlo antes de continuar.\n"
            }
            return $error_detectado ;
        }
    } else {
        puts "\nERROR: No existe el current_design\n"
    }
}

define_proc_attributes flow_check_design \
        -info "flow_check_design # Comando para chequear diferentes etapas del diseno" \
    -define_args {
    {-step "Valores - init_design|compile|place_opt|cts|post_cts_opto|route|post_route" "#flow step" string required }
    }
