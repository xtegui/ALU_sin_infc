####################################################################################################
# Script para crear las reglas de ruteo de los arboles de clock (NDR)
####################################################################################################

if {$nombre_ndr_root == "" && $nombre_ndr_internal == "" && $nombre_ndr_leaf == ""} {
    puts "\nINFO: [info script] es omitido. Ni nombre_ndr_root, ni nombre_ndr_internal, ni nombre_ndr_leaf se especificaron.\n"
} else {

####################################################################################################
# Reglas de routeo para las root nets (nombre_ndr_root)
####################################################################################################

# Creacion de la regla para root nets
if {$nombre_ndr_root != ""} {
    redirect -var x {report_routing_rules $nombre_ndr_root}
    if {[regexp "Error" $x]} {
        # Si la regla no existe, la crea
        if {$nombre_ndr_root == "ndr_2w2s"} {
            create_routing_rule $nombre_ndr_root -default_reference_rule -multiplier_width 2 -multiplier_spacing 2
        } else {
            puts "\nERROR: $nombre_ndr_root no es el nombre de una regla soportada. La regla no fue creada. Por favor chequear.\n"
        }
    } else {
        puts "\nINFO: nombre_ndr_root($nombre_ndr_root) ya existe. Se omitio la creacion de la regla.\n"
    }
}

# Asociacion de la regla para root nets (set_clock_routing_rules)
if {$nombre_ndr_root != ""} {
    # Chequea si la regla esta correctamente creada
    redirect -var x {report_routing_rules $nombre_ndr_root}
    if {![regexp "Error" $x]} {
        puts "\nINFO: set_clock_routing_rules -net_type root -rule $nombre_ndr_root -min_routing_layer $minima_capa_routeo_ndr_root -max_routing_layer ${maxima_capa_routeo_ndr_root}\n"
        set_clock_routing_rules -net_type root -rule $nombre_ndr_root -min_routing_layer $minima_capa_routeo_ndr_root -max_routing_layer $maxima_capa_routeo_ndr_root
    } else {
        puts "\nERROR: nombre_ndr_root($nombre_ndr_root) no fue creada. No se puede asociarla con las root nets.\n"
    }
}

####################################################################################################
# Reglas de routeo para las internal nets (nombre_ndr_internal)
####################################################################################################

# Creacion de la regla para internal nets
if {$nombre_ndr_internal != ""} {
    redirect -var x {report_routing_rules $nombre_ndr_internal}
    if {[regexp "Error" $x]} {
        # Si la regla no existe, la crea
        if {$nombre_ndr_internal == "ndr_2w2s"} {
            create_routing_rule $nombre_ndr_internal -default_reference_rule -multiplier_width 2 -multiplier_spacing 2
        } else {
            puts "\nERROR: $nombre_ndr_internal no es el nombre de una regla soportada. La regla no fue creada. Por favor chequear.\n"
        }
    } else {
        puts "\nINFO: nombre_ndr_internal($nombre_ndr_internal) ya existe. Se omitio la creacion de la regla.\n"
    }
}

# Asociacion de la regla para internal nets (set_clock_routing_rules)
if {$nombre_ndr_internal != ""} {
    # Chequea si la regla esta correctamente creada
    redirect -var x {report_routing_rules $nombre_ndr_internal}
    if {![regexp "Error" $x]} {
        puts "\nINFO: set_clock_routing_rules -net_type internal -rule $nombre_ndr_internal -min_routing_layer $minima_capa_routeo_ndr_internal -max_routing_layer ${maxima_capa_routeo_ndr_internal}\n"
        set_clock_routing_rules -net_type internal -rule $nombre_ndr_internal -min_routing_layer $minima_capa_routeo_ndr_internal -max_routing_layer $maxima_capa_routeo_ndr_internal
    } else {
        puts "\nERROR: nombre_ndr_internal($nombre_ndr_internal) no fue creada. No se puede asociarla con las internal nets.\n"
    }
}

####################################################################################################
# Reglas de routeo para las leaf nets (nombre_ndr_leaf)
####################################################################################################

# Creacion de la regla para leaf nets
if {$nombre_ndr_leaf != ""} {
    redirect -var x {report_routing_rules $nombre_ndr_leaf}
    if {[regexp "Error" $x]} {
        # Si la regla no existe, la crea
        if {$nombre_ndr_leaf == "ndr_leaf"} {
            create_routing_rule $nombre_ndr_leaf -default_reference_rule
        } else {
            puts "\nERROR: $nombre_ndr_leaf no es el nombre de una regla soportada. La regla no fue creada. Por favor chequear.\n"
        }
    } else {
        puts "\nINFO: nombre_ndr_leaf($nombre_ndr_leaf) ya existe. Se omitio la creacion de la regla.\n"
    }
}

# Asociacion de la regla para leaf nets (set_clock_routing_rules)
if {$nombre_ndr_leaf != ""} {
    # Chequea si la regla esta correctamente creada
    redirect -var x {report_routing_rules $nombre_ndr_leaf}
    if {![regexp "Error" $x]} {
        puts "\nINFO: set_clock_routing_rules -net_type sink -rule $nombre_ndr_leaf -min_routing_layer $minima_capa_routeo_ndr_leaf -max_routing_layer ${maxima_capa_routeo_ndr_leaf}\n"
        set_clock_routing_rules -net_type sink -rule $nombre_ndr_leaf -min_routing_layer $minima_capa_routeo_ndr_leaf -max_routing_layer $maxima_capa_routeo_ndr_leaf
    } else {
        puts "\nERROR: nombre_ndr_leaf($nombre_ndr_leaf) no fue creada. No se puede asociarla con las leaf nets.\n"
    }
}

}

