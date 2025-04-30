####################################################################################################
# Configuraciones del diseno y sus propiedades
####################################################################################################

# Nombre del diseno y archivos RTL
set nombre_design "ALU_votegui" ; # Nombre del diseno. Debe ser el nombre del modulo RTL de mayor jerarquia.
set dir_lista_rtl "/home/votegui/proyecto_final/place_and_route/ALU_sin_infc/RTL_sin_infc" ; # Directorio donde se encuentran los archivos verilog_list.lst e include_dir_list.lst

# Variables para inicializar el floorplan desde design_planning
set ancho_floorplan  50.024 ; # Multiplo de 0.074
set alto_floorplan 49.8  ; # Multiplo impar de 0.600
set core_offset "1.184 1.200" ; # X multiplo de 0.074, Y multiplo de 0.600 (Segun el manual: multiplo de 0.045)
set ubicacion_puertos "pin_constraints.tcl" ; # Archivo que contiene la ubicacion de los puertos

# Para cargar un floorplan en formato Tcl, usualmente es la salida de design_planning
set floorplan_tcl "./${dir_salidas}/design_planning_write_floorplan/floorplan.tcl"
#votegui debug
#set floorplan_tcl "${dir_salidas}/design_planning_write_floorplan/floorplan.tcl"
set floorplan_tcl ""

# Para cargar un floorplan desde un archivo DEF (Opcional)
set floorplan_def "" ; # Archivos DEF
set pg_en_floorplan_def "true" ; # true: cuando la PG esta incluida en el floorplan DEF

# Nombres de las nets de power y ground
set nombre_power "VDD"
set nombre_ground "VSS"

# Constraints de corners. Replicar cuantas veces sea necesario
set corner1 "setup_ss0p72v125c"
set proceso($corner1) 1
set label_proceso($corner1) "SS"
set voltaje($corner1) 0.72
set temperatura($corner1) 125
set corner_constraints($corner1) $parasitos1 ; # TLU+ parasitic max en technology_setup.tcl

set corner2 "hold_ff0p88v125c"
set proceso($corner2) 1
set label_proceso($corner2) "FF"
set voltaje($corner2) 0.88
set temperatura($corner2) 125
set corner_constraints($corner2) $parasitos2 ; # TLU+ parasitic min en technology_setup.tcl

# Constraints de modos. Replicar cuantas veces sea necesario
set modo1 "func"
#set modo_constraints($modo1) "/home/psosa/Work/legacy_flow_trial_14nm/dcnxt/override/clocks.tcl /home/psosa/Work/legacy_flow_trial_14nm/dcnxt/override/iodelay.tcl /home/psosa/Work/legacy_flow_trial_14nm/dcnxt/override/timing.tcl"
set modo_constraints($modo1) "/home/votegui/proyecto_final/override/constraints/clocks.tcl /home/votegui/proyecto_final/override/constraints/iodelay.tcl /home/votegui/proyecto_final/override/constraints/timing.tcl"

# Constraints de escenarios. "::" es usado como separador siguiendo el valor por defecto de "time.scenario_auto_name_separator"
# Replicar cuantas veces sea necesario. Terminar la configuracion de set_scenario_status en scripts/mcmm_setup.tcl
set escenario1 "${modo1}::${corner1}"
set escenario_constraints($escenario1) ""

set escenario2 "${modo1}::${corner2}"
set escenario_constraints($escenario2) ""

# Escenarios activos en cada etapa
set escenarios_activos_init_design "func::setup_ss0p72v125c"
set escenarios_activos_compile_placement "func::setup_ss0p72v125c"
set escenarios_activos_clock_opt_cts "func::setup_ss0p72v125c func::hold_ff0p88v125c"
set escenarios_activos_clock_opt_opto "func::setup_ss0p72v125c func::hold_ff0p88v125c"
set escenarios_activos_route_auto "func::setup_ss0p72v125c func::hold_ff0p88v125c"
set escenarios_activos_route_opt "func::setup_ss0p72v125c func::hold_ff0p88v125c"
set escenarios_activos_chip_finish "func::setup_ss0p72v125c func::hold_ff0p88v125c"

# Interfaces
set fuerza_reg_interfaz 1
set buffer_interfaz_senal "SAEDRVT14_BUF_S_4"
set buffer_interfaz_clock "SAEDSLVT14_BUF_S_8"
# Lista de registros para arbol de clock de la interfaz. Formato "{regsA regsB ...} {regsC ...} ..."
set regs_clock_interfaz ""
set inversor_ancla "SAEDSLVT14_INV_S_8"
# Lista de puertos para crear bloqueo de placement en las interfaces. Formato: "{puerto1* puert2} {puerto3} ..."
set puertos_regiones_interfaces ""

# Configuracion de arboles de clock
set estilo_cts "arbol_h" ; # El estilo puede ser "regular" o "arbol_h"

# Variables para controlar la implementacion de arboles H de clock
set arbol_h_clock "" ; # Nombre del clock para construir el arbol H
set arbol_h_net "" ; # Opcional: Especificar una net distinta a la net raiz del clock en caso que se quiera construir desde alli
set arbol_h_prefijo "arbol_h_${arbol_h_clock}" ; # Prefijo para las celdas del arbol H
set arbol_h_ndr "" ; # Nombre de la regla NDR para el arbol H. Ejemplo: ndr_2w2s
set arbol_h_minima_capa_routeo "" ;# Minima capa de routeo para el arbol H
set arbol_h_maxima_capa_routeo "" ;# Maxima capa de routeo para el arbol H
set arbol_h_cells_tronco $arbol_h_cells_tronco_por_defecto ; # Celdas que construiran el tronco del arbol. Definidas en config_tecnologia.tcl
set arbol_h_cells_puntas $arbol_h_cells_puntas_por_defecto ; # Celdas que construiran las puntas del arbol. Definidas en config_tecnologia.tcl
set arbol_h_area_personalizada "" ; # Opcional: Definir area personalizada en lugar de usar toda el area del bloque. Formato: {ll_x ll_y} {ur_x ur_y}

