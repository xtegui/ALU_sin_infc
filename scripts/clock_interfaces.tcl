proc clock_interfaz {regs inversor_ancla} {
    global sep
    # Saca el nombre del clock y de los registros
    set regs [get_flat_cells $regs]
    set clock_net [get_object_name [get_flat_nets -of [get_flat_pins -of $regs -filter is_clock_pin]]]
    set nombre_regs [join [lmap x [lsort -unique [regsub -all {_\d+_} [get_object_name $regs] {}]] {regsub {_reg$} $x {}}] "_"]

    # Si los regs no tienen un unico clock, sale
    if {[llength $clock_net] != 1} {
        puts "\nERROR: No se puede crear arbol de clock de interfaz en los registros \"$nombre_regs\" porque no tienen un unico clock. Clocks: \"$clock_net\"\n"
        return
    }

    # Bordes minimos y maximos ocupado por los registros
    set x1 [expr min([join [lmap x [get_attribute $regs boundary_bbox] {lindex $x 0 0}] ,])]
    set y1 [expr min([join [lmap x [get_attribute $regs boundary_bbox] {lindex $x 0 1}] ,])]
    set x2 [expr max([join [lmap x [get_attribute $regs boundary_bbox] {lindex $x 1 0}] ,])]
    set y2 [expr max([join [lmap x [get_attribute $regs boundary_bbox] {lindex $x 1 1}] ,])]

    # Detector de lado
    set lados [list "izquierda [expr abs($x1 - 0.0)]" "abajo [expr abs($y1 - 0.0)]" "derecha [expr abs([get_attribute [get_designs] width] - $x2)]" "arriba [expr abs([get_attribute [get_designs] height] - $y2)]"]
    set lado [lindex [lsort -real -index 1 $lados] 0 0]

    # Cantidad de inversores dependiendo de la cantidad de registros
    if {[sizeof_collection $regs] <= 16} {
        set etapa1 1
        set etapa2 1
        set etapa3 0
        set etapa4 0
    } elseif {16 < [sizeof_collection $regs] && [sizeof_collection $regs] <= 64} {
        set etapa1 4
        set etapa2 1
        set etapa3 0
        set etapa4 0
    } elseif {64 < [sizeof_collection $regs] && [sizeof_collection $regs] <= 256} {
        set etapa1 16
        set etapa2 4
        set etapa3 1
        set etapa4 1
    } else {
        set etapa1 64
        set etapa2 16
        set etapa3 4
        set etapa4 1
    }

    # Configuraciones por lado
    switch $lado {
        "izquierda" {
            set ref $x2
            set signo "+"
            set coord "y"
        }
        "abajo" {
            set ref $y2
            set signo "+"
            set coord "x"
        }
        "derecha" {
            set ref $x1
            set signo "-"
            set coord "y"
        }
        "arriba" {
            set ref $y1
            set signo "-"
            set coord "x"
        }
    }

    # Distancia desde los registros a la primera etapa y distancia entre etapas
    set dist_inicial 10
    set dist_etapas 5.0

    # Insercion de los inversores de clock de la interfaz
    puts "\nINFO: Insertando de los inversores de clock de la interfaz: \"$nombre_regs\"\n"
    edit_block {
        for {set i 1} {$i <= 4} {incr i} {
            set separacion [expr ([set ${coord}2] - [set ${coord}1])/([set etapa${i}] + 1.0)]
            if {$i == 1} {set busqueda [expr aracion * 2.0]}
            for {set j 0} {$j < [set etapa${i}]} {incr j} {
                set nuevo_inversor [create_cell "${nombre_regs}_${clock_net}_${i}_${j}" [get_lib_cells $inversor_ancla]]
                set nueva_net [create_net "${nombre_regs}_${clock_net}_${i}_${j}_net"]
                set inversor_raiz $nuevo_inversor
                connect_net $nueva_net [get_flat_pins -of $nuevo_inversor -filter "direction==out"]
                if {$coord == "y"} {
                    set_cell_location $nuevo_inversor -coordinates [list [expr $ref $signo $dist_inicial $signo ($dist_etapas * ($i - 1))] [expr [set ${coord}1] + (aracion * ($j + 1))]]
                } else {
                    set_cell_location $nuevo_inversor -coordinates [list [expr [set ${coord}1] + (aracion * ($j + 1))] [expr $ref $signo $dist_inicial $signo ($dist_etapas * ($i - 1))]]
                }
                set_attribute $nueva_net dont_touch true
                set_attribute $nuevo_inversor dont_touch true
                set_attribute $nuevo_inversor physical_status legalize_only
            }
        }

        # Conexiones de los inversores
        puts "\nINFO: Conectando los inversores de clock de interfaz: \"$nombre_regs\"\n"
        disconnect_net $clock_net [get_flat_pins -of $regs -filter is_clock_pin]
        connect_net $clock_net [get_flat_pins -of $inversor_raiz -filter "direction==in"]
        for {set i 1} {$i <= 4} {incr i} {
            for {set j 0} {$j < [set etapa${i}]} {incr j} {
                if {[get_flat_nets -quiet ${nombre_regs}_${clock_net}_[expr ${i} + 1]_[expr ${j} / 4]_net] != ""} {
                    connect_net [get_flat_nets -quiet ${nombre_regs}_${clock_net}_[expr ${i} + 1]_[expr ${j} / 4]_net] [get_flat_pins -of [get_flat_cells ${nombre_regs}_${clock_net}_${i}_${j}] -filter "direction==in"]
                }
            }
        }

        # Conexiones de los registros
        puts "\nINFO: Conectando los registros de interfaz\n"
        foreach_in_collection sink [get_flat_pins -of $regs -filter is_clock_pin] {
            set modulo_menor "999999999999"
            set conectar_tap ""
            lassign [lindex [get_attribute $sink bbox] 0] x1 y1
            if {$coord == "y"} {
                set tx1 0
                set ty1 [expr $y1 - $busqueda]
                set tx2 [get_attribute [get_designs] width]
                set ty2 [expr $y1 + $busqueda]
            } else {
                set tx1 [expr $x1 - $busqueda]
                set ty1 0
                set tx2 [expr $x1 + $busqueda]
                set ty2 [get_attribute [get_designs] height]
            }
            foreach_in_collection tap [get_flat_pins -of [get_objects_by_location -quiet -filter "name=~${nombre_regs}_${clock_net}_1_*" -classes cell -within [list "$tx1 $ty1" "$tx2 $ty2"]] -filter "direction==out"] {
                lassign [lindex [get_attribute $tap bbox] 0] x2 y2
                set modulo [expr sqrt(pow(($x1 - $x2),2)+pow(($y1 - $y2),2))]
                if {$modulo < $modulo_menor} {
                    set modulo_menor $modulo
                    set conectar_tap $tap
                }
            }
            connect_net [get_flat_nets -of $conectar_tap] $sink
        }
    }
}

if {$regs_clock_interfaz != ""} {
    foreach regs_interfaz $regs_clock_interfaz {
        clock_interfaz $regs_interfaz $inversor_ancla
    }

    # Legalizacion de las celdas insertadas
    puts "\nINFO: Legalizando las celdas insertadas\n"
    legalize_placement -cells [get_flat_cells -filter physical_status==legalize_only]
    set_attribute [get_flat_cells -filter physical_status==legalize_only] physical_status fixed
}
