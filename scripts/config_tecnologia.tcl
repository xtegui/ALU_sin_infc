####################################################################################################
# Configuraciones de la tecnologia
####################################################################################################

# Configuraciones de la tecnologia
set nodo "s14"
set techfile "/home/digitalProjects/tech/saed14nm/tf/saed14nm_1p9m_mw.tf"
set librerias_referencia [list \
/home/digitalProjects/tech/saed14nm/ndm/saed14rvt.ndm \
/home/digitalProjects/tech/saed14nm/ndm/saed14hvt.ndm \
/home/digitalProjects/tech/saed14nm/ndm/saed14lvt.ndm \
/home/digitalProjects/tech/saed14nm/ndm/saed14slvt.ndm \
/home/digitalProjects/tech/saed14nm/ndm/saed14rvt_dlvl.ndm \
/home/digitalProjects/tech/saed14nm/ndm/saed14hvt_dlvl.ndm \
/home/digitalProjects/tech/saed14nm/ndm/saed14lvt_dlvl.ndm \
/home/digitalProjects/tech/saed14nm/ndm/saed14slvt_dlvl.ndm \
/home/digitalProjects/tech/saed14nm/ndm/saed14rvt_ulvl.ndm \
/home/digitalProjects/tech/saed14nm/ndm/saed14hvt_ulvl.ndm \
/home/digitalProjects/tech/saed14nm/ndm/saed14lvt_ulvl.ndm \
/home/digitalProjects/tech/saed14nm/ndm/saed14slvt_ulvl.ndm \
/home/digitalProjects/tech/saed14nm/ndm/saed14rvt_pg.ndm \
/home/digitalProjects/tech/saed14nm/ndm/saed14hvt_pg.ndm \
/home/digitalProjects/tech/saed14nm/ndm/saed14lvt_pg.ndm \
/home/digitalProjects/tech/saed14nm/ndm/saed14slvt_pg.ndm \
]
set site_default "unit"
set site_simetria {{unit Y}}
set capas_multi_mascara "{M1 2} {M2 2}" ; # Formato: {capa num_mascaras}

# Grupos de celdas por VT (Voltage Threshold)
set celdas_hvt "*/SAEDHVT*" ; # Define el grupo de VT hvt
set celdas_svt "*/SAEDRVT*" ; # Define el grupo de VT rvt
set celdas_lvt "*/SAEDLVT*" ; # Define el grupo de VT lvt
set celdas_slvt "*/SAEDSLVT*"; # Define el grupo de VT slvt
set prioridad_leakage "HVT RVT LVT"

# Archivos de parasitos para read_parasitic_tech. Replicar cuantas veces sea necesario
set parasitos1 "Cmax" ; # Nombre del modelo 1
set tluplus($parasitos1) "/home/tools/synopsys/tech_kits/SAED14nm_EDK/tech/star_rc/max/saed14nm_1p9m_Cmax.tluplus" ; # Archivo TLU+ para parasitos1
set itf_tlu_map($parasitos1) "/home/tools/synopsys/tech_kits/SAED14nm_EDK/tech/star_rc/saed14nm_tf_itf_tluplus.map" ; # Mapeo de capas entre ITF y TLU+ para parasitos1

set parasitos2 "Cmin" ; # Nombre del modelo 2
set tluplus($parasitos2) "/home/tools/synopsys/tech_kits/SAED14nm_EDK/tech/star_rc/min/saed14nm_1p9m_Cmin.tluplus" ; # Archivo TLU+ para parasitos2
set itf_tlu_map($parasitos2) "/home/tools/synopsys/tech_kits/SAED14nm_EDK/tech/star_rc/saed14nm_tf_itf_tluplus.map" ; # Mapeo de capas entre ITF y TLU+ para parasitos2

# Configuraciones de power grid
set capa_tiras_pg "vertical_layer: M9"
set ancho_tiras_pg 0.6
set distancia_entre_tiras_pg 6
set capa_rieles_pg "M1"
set ancho_rieles_pg 0.094

# Celdas de frontera (boundary cells)
set borde_izquierdo "saed14rvt/SAEDRVT14_CAPSPACER1"
set borde_derecho "saed14rvt/SAEDRVT14_CAPSPACER1"
set borde_inferior "saed14rvt/SAEDRVT14_CAPB2 saed14rvt/SAEDRVT14_CAPB3"
set borde_superior "saed14rvt/SAEDRVT14_CAPT2 saed14rvt/SAEDRVT14_CAPT3"
set esquina_inferior_izquierda "saed14rvt/SAEDRVT14_CAPBIN13"
set esquina_inferior_derecha "saed14rvt/SAEDRVT14_CAPBIN13"
set esquina_superior_izquierda "saed14rvt/SAEDRVT14_CAPTIN13"
set esquina_superior_derecha "saed14rvt/SAEDRVT14_CAPTIN13"
set tap_cell_superior "saed14rvt/SAEDRVT14_CAPTTAP6"
set tap_cell_inferior "saed14rvt/SAEDRVT14_CAPBTAP6"
set distancia_tap_cells_borde 7.4

# Tap cells
set tap_cell "saed14rvt/SAEDRVT14_TAPPN"
set tap_cell_espejada "saed14rvt/SAEDRVT14_TAPDS"
set distancia_tap_cells 80

# Celdas de relleno
set dcap_cells "*DCAP*"
set fill_cells "*FILL*"

# Variables para controlar las reglas de ruteo de clock (NDR)
# Redes de clock de raiz (root nets)
set nombre_ndr_root "ndr_2w2s" ; # Nombre de la regla de ruteo para las root nets. ndr_2w2s: Doble ancho y doble espaciado
set minima_capa_routeo_ndr_root "M5" ; # Minima capa de ruteo para las root nets
set maxima_capa_routeo_ndr_root "M8" ; # Maxima capa de ruteo para las root nets
# Redes de clock internas (internal nets), (por defecto iguales a las root nets)
set nombre_ndr_internal $nombre_ndr_root ; # Nombre de la regla de ruteo para las internal nets
set minima_capa_routeo_ndr_internal $minima_capa_routeo_ndr_root ; # Minima capa de ruteo para las internal nets
set maxima_capa_routeo_ndr_internal $maxima_capa_routeo_ndr_root ; # Maxima capa de ruteo para las internal nets
# Redes de clock de hojas (leaf nets)
set nombre_ndr_leaf "ndr_leaf" ; # Nombre de la regla de ruteo para las leaf nets
set minima_capa_routeo_ndr_leaf $minima_capa_routeo_ndr_root ; # Minima capa de ruteo para las leaf nets
set maxima_capa_routeo_ndr_leaf $maxima_capa_routeo_ndr_root ; # Maxima capa de ruteo para las leaf nets

# Configuraciones de ruteo
set layer_direccion_offset "{PO vertical 0} {M1 vertical 0.037} {M2 horizontal 0} {M3 vertical 0} {M4 horizontal 0} {M5 vertical 0} {M6 horizontal 0} {M7 vertical 0} {M8 horizontal 0} {M9 vertical 0} {MRDL horizontal 0}"
set minima_capa_routeo "M2"
set maxima_capa_routeo "M8"

# Celdas para propositos especificos
set tie_cells "saed14rvt/SAEDRVT14_TIE1* saed14rvt/SAEDRVT14_TIE0*"
set delay_cells "saed14rvt/SAEDRVT14_DEL_*"
set clock_cells "saed14slvt/SAEDSLVT14_INV_S_* saed14slvt/SAEDSLVT14_AN2_MM_* saed14slvt/SAEDSLVT14_OR2_MM_* saed14slvt/SAEDSLVT14_MUX2_MM_* saed14slvt/SAEDSLVT14_CKGTP* saed14slvt/SAEDSLVT14_FDP* saed14slvt/SAEDSLVT14_FSD*"
set clock_cells_exclusivas ""
set driving_cell "SAEDRVT14_BUF_S_8"
set arbol_h_cells_tronco_por_defecto "SAEDSLVT14_INV_S_12"
set arbol_h_cells_puntas_por_defecto "SAEDSLVT14_INV_S_8"

# Celdas de repuesto. Formato: "celda porcentaje(%)"
set lista_celdas_repuesto [list \
[list saed14rvt/SAEDRVT14_FDPQ_V2ECO_1  0.5] \
[list saed14rvt/SAEDRVT14_BUF_ECO_8     0.5] \
[list saed14rvt/SAEDRVT14_INV_ECO_8     0.5] \
[list saed14rvt/SAEDRVT14_AOI21_ECO_1   0.2] \
[list saed14rvt/SAEDRVT14_DCAP_PV1ECO_6 0.2] \
[list saed14rvt/SAEDRVT14_MUX2_ECO_2    0.2] \
[list saed14rvt/SAEDRVT14_NR2_ECO_2     0.2] \
[list saed14rvt/SAEDRVT14_OAI21_2       0.2] \
[list saed14rvt/SAEDRVT14_OR2_ECO_2     0.2] \
[list saed14rvt/SAEDRVT14_ND2_ECO_2     0.2] \
[list saed14rvt/SAEDRVT14_AN2_ECO_2     0.2] \
]

# Patron de celdas multibit
set mb_patron_banking "*/MB*"
set mb_patron_debanking ""
