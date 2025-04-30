set n 0
foreach puertos_para_region $puertos_regiones_interfaces {
    set puertos_entradas [get_ports $puertos_para_region -filter direction==in]
    set puertos_salidas [get_ports $puertos_para_region -filter direction==out]

    set boundary_bbox ""
    lappend boundary_bbox {*}[get_attribute [filter_collection [all_fanout -flat -only_cells -quiet -from $puertos_entradas] is_interface_placed] boundary_bbox]
    lappend boundary_bbox {*}[get_attribute [filter_collection [all_fanin -flat -only_cells -quiet -to $puertos_salidas] is_interface_placed] boundary_bbox]

    # Bordes minimos y maximos ocupado por las celdas de interfaz
    set x1 [expr min([join [lmap x $boundary_bbox {lindex $x 0 0}] ,])]
    set y1 [expr min([join [lmap x $boundary_bbox {lindex $x 0 1}] ,])]
    set x2 [expr max([join [lmap x $boundary_bbox {lindex $x 1 0}] ,])]
    set y2 [expr max([join [lmap x $boundary_bbox {lindex $x 1 1}] ,])]

    # Crea bloqueos de placement en las interfaces para que no ingresen otras celdas
    create_placement_blockage -name "region_interfaz_${n}" -type partial -blocked_percentage 100 -boundary [list "$x1 $y1" "$x2 $y2"]
    incr n
}
