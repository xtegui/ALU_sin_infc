####################################################################################################
# Script de configuracion de multi VT (Voltage Threshold)
####################################################################################################

foreach lib $celdas_hvt {set_attribute [get_lib_cells -quiet $lib] threshold_voltage_group hvt -quiet}
foreach lib $celdas_svt {set_attribute [get_lib_cells -quiet $lib] threshold_voltage_group rvt -quiet}
foreach lib $celdas_lvt {set_attribute [get_lib_cells -quiet $lib] threshold_voltage_group lvt -quiet}
foreach lib $celdas_slvt {set_attribute [get_lib_cells -quiet $lib] threshold_voltage_group slvt -quiet}

if {[sizeof [get_lib_cells -filter "threshold_voltage_group == hvt"]]} {
    set_threshold_voltage_group_type -type high_vt {hvt}
}

if {[sizeof [get_lib_cells -filter "threshold_voltage_group == rvt"]]} {
    set_threshold_voltage_group_type -type normal_vt {rvt}
}

if {[sizeof [get_lib_cells -filter "threshold_voltage_group == lvt"]]} {
    set_threshold_voltage_group_type -type low_vt {lvt}
}

# Aplica las restricciones de multi VT
if {$limitar_celdas_lvt} {
   if {$metrica_estrategia_qor != "timing"} {
      puts "\nINFO: Ejecutando \"set_multi_vth_constraint -cost cell_count -low_vt_percentage ${porcentaje_celdas_lvt}\"\n"
      set_multi_vth_constraint -cost cell_count -low_vt_percentage ${porcentaje_celdas_lvt}
   }
}
