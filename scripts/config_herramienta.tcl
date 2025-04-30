####################################################################################################
# Configuraciones de la herramienta Fusion Compiler
####################################################################################################

# Numero de procesadores (CPU) para usar en la ejecucion
set num_procesadores 8

# Nombres de directorios para escritura de archivos
set dir_reportes "./reportes"
set dir_salidas "./salidas"
set dir_logs "./logs"
set dir_qor "./datos_qor"
set dir_comparacion_qor "./comparacion_qor" ; # Directorio donde se escrcriben comparaciones de QoR

# Estrategias de QoR
set modo_estrategia_qor "balanced"
set metrica_estrategia_qor "timing" ; # Valores: timing | total_power

# Parametros para controlar la implementacion
set habilitar_high_effort_timing "false"
set limitar_celdas_lvt "false"  ; # Habilita limitaciones de celdas low_vt en el diseno
set porcentaje_celdas_lvt ""    ; # Porcentaje de celdsas LVT en el diseno (requiere habilitar la variable limitar_celdas_lvt)

# Configuracion de multibit
set habilitar_multibit "true"
set mb_umbral_slack_banking -0.010
set mb_umbral_slack_debanking 0.100

# Parametros de clock
set clock_porcentaje_skew 0.1
set clock_skew_global "" ; # Skew fijo. La variable clock_porcentaje_skew debe estar vacía
set habilitar_clock_ccd "true"
set clock_ccd_posponer_max 0.100
set clock_ccd_preponer_max 0.100
set espaciado_celdas_clock "3*site 0"
set habilitar_creacion_blindaje_clock "false"

# Parametros de ruteo
set habilitar_insercion_vias_redundantes "true"
set habilitar_creacion_blindaje "true"

# Variables para controlar reportes
set report_timing_verbose "false" ; # true|false; Hace un reporte de timing adicional con "-max_paths 300 -slack_lesser_than 0"
set reportar_potencia_clock "false" ; # true|false; Hace un "report_clock_qor -type power" despues de clock_opt_cts y route_opt stages
set reportar_power "true"; # true|false
set reportar_congestion "true" ; # true|false
set escribir_qor "true" ; # true|false; Escribe el QoR y ejecuta compare_qor_data para generar un archivo HTML de QoR
set reportar_qor_intermedio "true" ; # true|false; Habilita el report_qor intermedio durante la implementacion

# Control de reglas de diseño (DRV)
set transicion_max 0.300
set fanout_max 40
set capacidad_max "" ; # Sin restricciones por defecto
set largo_net_max "" ; # Sin restricciones por defecto
set clock_transicion_max 0.080
set clock_sinks_transicion_max 0.060
set clock_fanout_max 64
set clock_capacidad_max 0.050
set clock_largo_net_max "" ; # Sin restricciones por defecto
set tie_fanout_max 50

# Transiciones de entrada y cargas de salida
set transicion_entrada_subida_max 0.200
set transicion_entrada_bajada_max 0.200
set transicion_entrada_subida_min 0.010
set transicion_entrada_bajada_min 0.010
set carga_max 0.030
set carga_min 0.010

# Parámetros de actividad
set tasa_cambio_clock 2
set tasa_cambio_puertos 0.16
set tasa_cambio_icgs 1.0
set tasa_cambio_registross 0.1
set probablidad_clock 0.5
set probablidad_puertos 0.5
set probablidad_icgs 0.5
set probablidad_registros 0.5

# Ruteo incremental
set modo_ruteo_incremental "auto" ; # Los valores son: on | off | auto
set iteraciones_ruteo_incremental 10 ; # Cantidad de iteraciones maximas del ruteo incremental
set tope_drc_rute_incemental 10000 ; # Tope maximo de DRCs para activar el ruteo incremental automatico
set drc_min_ruteo_incremental 50 ; # Cantidad minima de DRCs para activar el ruteo incremental automatico
set porcent_incr_drc_ruteo_incremental 0.1 ; # Porcentaje de incremento de DRCs despues de route_auto para activar el ruteo incremental. Default 0.1 = 10%
