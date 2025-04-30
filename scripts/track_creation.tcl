####################################################################################################
# Script para crear los tracks de las capas de ruteo
####################################################################################################

### PSOSA: TODO chequear los tracks

#create_track_pattern -layer M1   -direction horizontal -offsets { 0.0 } -spacing 0.074 -mask_pattern { mask_one mask_two }
#create_track_pattern -layer M2   -direction horizontal -offsets { 0.0 } -spacing 0.060 -mask_pattern { mask_one mask_two }
#create_track_pattern -layer M3   -direction vertical   -offsets { 0.0 } -spacing 0.074
#create_track_pattern -layer M4   -direction horizontal -offsets { 0.0 } -spacing 0.074
#create_track_pattern -layer M5   -direction vertical   -offsets { 0.0 } -spacing 0.120
#create_track_pattern -layer M6   -direction horizontal -offsets { 0.0 } -spacing 0.120
#create_track_pattern -layer M7   -direction vertical   -offsets { 0.0 } -spacing 0.120
#create_track_pattern -layer M8   -direction horizontal -offsets { 0.0 } -spacing 0.120
#create_track_pattern -layer M9   -direction vertical   -offsets { 0.0 } -spacing 0.120
#create_track_pattern -layer MRDL -direction horizontal -offsets { 0.0 } -spacing 0.600

remove_tracks -all -force

create_track -layer M1   -dir x -relative_to core_area -offset 0.037 -space 0.074 -mask_pattern { mask_one mask_two }
create_track -layer M2   -dir y -relative_to core_area -offset 0.0 -space 0.060 -mask_pattern { mask_one mask_two }
create_track -layer M3   -dir x -relative_to core_area -offset 0.0 -space 0.074
create_track -layer M4   -dir y -relative_to core_area -offset 0.0 -space 0.120
create_track -layer M5   -dir x -relative_to core_area -offset 0.0 -space 0.120
create_track -layer M6   -dir y -relative_to core_area -offset 0.0 -space 0.120
create_track -layer M7   -dir x -relative_to core_area -offset 0.0 -space 0.120
create_track -layer M8   -dir y -relative_to core_area -offset 0.0 -space 0.120
create_track -layer M9   -dir x -relative_to core_area -offset 0.0 -space 0.120
create_track -layer MRDL -dir y -relative_to core_area -offset 0.0 -space 4
