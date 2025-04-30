####################################################################################################
# Script para crear los corners, los modos y los escenarios
####################################################################################################

####################################################################################################
# Creacion de corners, modos y escenarios
####################################################################################################

# Remueve todos los modos, corners y scenarios existentes
remove_corners -all; remove_modes -all; remove_scenarios -all

# Creacion de los corners
foreach c [array name corner_constraints] {
    puts "\nINFO: create_corner ${c}\n"
    create_corner $c
}

# Creacion de los modos
foreach m [array name modo_constraints] {
    puts "\nINFO: create_mode ${m}\n"
    create_mode $m
}

# Creacion de los scenarios
foreach s [array name escenario_constraints] {
    set m [lindex [split $s ::] 0]
    set c [lindex [split $s ::] end]
    puts "\nINFO: create_scenario ${s}\n"
    create_scenario -name $s -mode $m -corner $c
}

####################################################################################################
# Lectura de constraints
####################################################################################################

# Lectura de constraints de corners
foreach c [array name corner_constraints] {
    current_corner $c
    current_scenario [index_collection [get_scenarios -corner $c] 0]
    puts "\nINFO: set_parasitics_parameters -early_spec $corner_constraints($c) -late_spec $corner_constraints($c) -corners ${c}\n"
    set_parasitics_parameters -early_spec $corner_constraints($c) -late_spec $corner_constraints($c) -corners $c
    ### PSOSA: TODO chequear
    # for example, set_parasitic_parameters -late_spec $parasitics1 -early_spec $parasitics2
    # Configuracion de proceso, voltaje y temperarura (PVT). Se recomienda hacerlo por separado en lugar de "set_operating_conditions"
    set_process_number $proceso($c)
    set_process_label $label_proceso($c)
    set_voltage $voltaje($c)
    set_temperature $temperatura($c)
}

# Lectura de constraints de modo
foreach m [array name modo_constraints] {
    current_mode $m
    current_scenario [index_collection [get_scenarios -mode $m] 0]
    # ensures a current_scenario exists in case provided mode constraints are actually scenario specific
    puts "\nINFO: current_mode ${m}\n"
    foreach cnstr $modo_constraints($m) {
        source $cnstr
    }
}

# Lectura de constraints de escenarios
#foreach s [array name escenario_constraints] {
#    current_scenario $s
#    puts "\nINFO: current_scenario ${s}\n"
#    source $escenario_constraints($s)
#}

####################################################################################################
# Configuracion del tipo de analisis para los escenarios
####################################################################################################

# Tipos de analisis: $escenario1 setup y $escenario2 hold
set_scenario_status $escenario1 -none -setup true -hold false -leakage_power true -dynamic_power true -max_transition true -max_capacitance true -min_capacitance false -active true
set_scenario_status $escenario2 -none -setup false -hold true -leakage_power true -dynamic_power false -max_transition true -max_capacitance false -min_capacitance true -active true
