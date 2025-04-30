# Suprime mensaje molesto
suppress_message {MP-001 MP-002}

# Uniformiza los registros de entrada
puts "\nINFO: Uniformizando los registros de entrada\n"
foreach_in_collection puerto [all_inputs -exclude_clock_ports] {
    set reg [all_fanout -from $puerto -flat -endpoints_only -only_cells]
    if {[sizeof_collection $reg] == 1} {
        set nueva_celda "[regsub {_[^_]+$} [get_attribute $reg ref_name] {}]_$fuerza_reg_interfaz"
        if {[get_lib_cells -quiet $nueva_celda] != ""} {
            size_cell [get_object_name $reg] $nueva_celda
            set_dont_touch $reg
        }
    }
}

# Uniformiza los registros de salida
puts "\nINFO: Uniformizando los registros de salida\n"
foreach_in_collection puerto [all_outputs] {
    set reg [all_fanin -to $puerto -flat -startpoints_only -only_cells]
    if {[sizeof_collection $reg] == 1} {
        set nueva_celda "[regsub {_[^_]+$} [get_attribute $reg ref_name] {}]_$fuerza_reg_interfaz"
        if {[get_lib_cells -quiet $nueva_celda] != ""} {
            size_cell [get_object_name $reg] $nueva_celda
            set_dont_touch $reg
        }
    }
}

edit_block {
    # Inserta buffers de interfaz a puertos de entrada de senal
    puts "\nINFO: Insertando buffers de interfaz a puertos de entrada de senal\n"
    foreach_in_collection puerto [all_inputs -exclude_clock_ports] {
        set nuevo_buffer [create_cell "buf_int_[regsub -all {[^[:alnum:]]} [get_object_name $puerto] {_}]" [get_lib_cell $buffer_interfaz_senal]]
        set nueva_net [create_net "[regsub -all {[^[:alnum:]]} [get_object_name $puerto] {_}]_net"]
        set orig_net [get_flat_net -of $puerto]
        connect_net $nueva_net [get_flat_pins -of $nuevo_buffer -filter "direction==in"]
        disconnect_net $orig_net $puerto
        connect_net $orig_net [get_flat_pins -of $nuevo_buffer -filter "direction==out"]
        connect_net $nueva_net $puerto
        set_attribute $nuevo_buffer dont_touch true
        set_attribute $nueva_net dont_touch true
    }

    # Inserta buffers de interfaz a puertos de entrada de clock
    puts "\nINFO: Insertando buffers de interfaz a puertos de entrada de clock\n"
    foreach_in_collection puerto [remove_from_collection [all_inputs] [all_inputs -exclude_clock_ports]] {
        set nuevo_buffer [create_cell "buf_int_[regsub -all {[^[:alnum:]]} [get_object_name $puerto] {_}]" [get_lib_cell $buffer_interfaz_clock]]
        set nueva_net [create_net "[regsub -all {[^[:alnum:]]} [get_object_name $puerto] {_}]_net"]
        set orig_net [get_flat_net -of $puerto]
        connect_net $nueva_net [get_flat_pins -of $nuevo_buffer -filter "direction==in"]
        disconnect_net $orig_net $puerto
        connect_net $orig_net [get_flat_pins -of $nuevo_buffer -filter "direction==out"]
        connect_net $nueva_net $puerto
        set_attribute $nuevo_buffer dont_touch true
        set_attribute $nueva_net dont_touch true
    }

    # Inserta buffers de interfaz a puertos de salida de senal
    puts "\nINFO: Insertando buffers de interfaz a puertos de salida de senal\n"
    foreach_in_collection puerto [all_outputs] {
        set nuevo_buffer [create_cell "buf_int_[regsub -all {[^[:alnum:]]} [get_object_name $puerto] {_}]" [get_lib_cell $buffer_interfaz_senal]]
        set nueva_net [create_net "[regsub -all {[^[:alnum:]]} [get_object_name $puerto] {_}]_net"]
        set orig_net [get_flat_net -of $puerto]
        connect_net $nueva_net [get_flat_pins -of $nuevo_buffer -filter "direction==out"]
        disconnect_net $orig_net $puerto
        connect_net $orig_net [get_flat_pins -of $nuevo_buffer -filter "direction==in"]
        connect_net $nueva_net $puerto
        set_attribute $nuevo_buffer dont_touch true
        set_attribute $nueva_net dont_touch true
    }
}

define_user_attribute -type boolean -classes cell -name is_interface_placed

set ubicar_celdas ""

# Colecciona celdas de interfaz de entrada para ubicarlas
puts "\nINFO: Coleccionando celdas de interfaz de entrada para ubicarlas\n"
foreach_in_collection puerto [all_inputs -exclude_clock_ports] {
    set buf [get_flat_cells -of [get_flat_nets -of $puerto]]
    if {[sizeof_collection $buf] == 1} {
        if {[get_attribute [get_lib_cells -of $buf] is_buffer]} {
            append_to_collection ubicar_celdas $buf
            set reg [remove_from_collection [get_flat_cells -of [get_flat_nets -of [get_flat_pins -of $buf -filter "direction==out"]]] $buf]
            if {[sizeof_collection $reg] == 1} {
                if {![get_attribute [get_lib_cells -of $reg] is_sequential]} {continue}
                if {[get_attribute [get_lib_cells -of $reg] is_a_flip_flop] || [get_attribute [get_lib_cells -of $reg] is_a_flip_flop_bank]} {
                    append_to_collection ubicar_celdas $reg
                    set_attribute [get_flat_nets -of [get_flat_pins -of $buf -filter "direction==out"]] dont_touch true
                }
            }
        }
    }
}

# Colecciona celdas de interfaz de clock para ubicarlas
puts "\nINFO: Coleccionando celdas de interfaz de clock para ubicarlas\n"
foreach_in_collection puerto [remove_from_collection [all_inputs] [all_inputs -exclude_clock_ports]] {
    set buf [get_flat_cells -of [get_flat_nets -of $puerto]]
    if {[sizeof_collection $buf] == 1} {
        if {[get_attribute [get_lib_cells -of $buf] is_buffer]} {
            append_to_collection ubicar_celdas $buf
        }
    }
}

# Colecciona celdas de interfaz de salida para ubicarlas
puts "\nINFO: Coleccionando celdas de interfaz de salida para ubicarlas\n"
foreach_in_collection puerto [all_outputs] {
    set buf [get_flat_cells -of [get_flat_nets -of $puerto]]
    if {[sizeof_collection $buf] == 1} {
        if {[get_attribute [get_lib_cells -of $buf] is_buffer]} {
            append_to_collection ubicar_celdas $buf
            set reg [remove_from_collection [get_flat_cells -of [get_flat_nets -of [get_flat_pins -of $buf -filter "direction==in"]]] $buf]
            if {[sizeof_collection $reg] == 1} {
                if {![get_attribute [get_lib_cells -of $reg] is_sequential]} {continue}
                if {[get_attribute [get_lib_cells -of $reg] is_a_flip_flop] || [get_attribute [get_lib_cells -of $reg] is_a_flip_flop_bank]} {
                    append_to_collection ubicar_celdas $reg
                    set_attribute [get_flat_nets -of [get_flat_pins -of $buf -filter "direction==in"]] dont_touch true
                }
            }
        }
    }
}

set valor [get_app_option_value -name place.legalize.advanced_ignore_vertical_keepout_margin]
set_app_option -name place.legalize.advanced_ignore_vertical_keepout_margin -value false

# Crea margenes keepout a las celdas de interfaz
puts "\nINFO: Creando margenes keepout a las celdas de interfaz\n"
create_keepout_margin -type hard -outer \
    [list \
        [expr 12 * [get_attribute [get_site_defs unit] width]] \
        [get_attribute [get_site_defs unit] height] \
        {} \
        {} \
    ] \
    $ubicar_celdas

# Atrae las celdas de interfaz a los puertos
puts "\nINFO: Atraeyendo las celdas de interfaz a los puertos\n"
magnet_placement -mark_legalize_only -cells $ubicar_celdas [add_to_collection [all_inputs] [all_outputs]]

set_app_option -name place.legalize.advanced_ignore_vertical_keepout_margin -value $valor

# Legaliza las celdas ubicadas en el floorplan
puts "\nINFO: Legalizando las celdas ubicadas en el floorplan\n"
legalize_placement -cells [get_flat_cells -filter physical_status==legalize_only]
set_attribute [get_flat_cells -filter physical_status==legalize_only] physical_status fixed

set_attribute [filter_collection $ubicar_celdas physical_status==fixed] is_interface_placed true

unsuppress_message {MP-001 MP-002}
