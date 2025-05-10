#Definicion de clock(s)
##Autora: Victoria Otegui Alexenicer
##Version: 0.5
##Fecha 3/3/2025
##INFO: aplicando mapeado de celdas de fusion para definir los puertos de los clocks generados
#
set CLK_NAME    "CLOCK_MAIN"
set CLK_PORT    "i_clock"
set CLK_PERIOD  "10"; #ns
#Defino los clocks segun SDC (synopsis design constraints)
puts "INFO: Definiendo clocks"
create_clock [get_ports $CLK_PORT] -name $CLK_NAME -period $CLK_PERIOD -waveform "0 [expr 0.5*$CLK_PERIOD]"
puts "INFO: Definiendo clocks virtuales para la definicion de input y output delays"
create_clock -name vir_${CLK_NAME} -period $CLK_PERIOD
puts "INFO: Definiendo clocks generados"
# Clock dividido por 2 (q_div_2)
create_generated_clock -name gen_clk_div2 -divide_by 2 -source [get_flat_pins  {q_div_2_reg/clocked_on}] -master_clock CLOCK_MAIN [get_pins {q_div_2_reg/Q}] -add
# Clock dividido por 4 (q_div_4)
create_generated_clock -name gen_clk_div4 -divide_by 2 -source [get_flat_pins  {q_div_4_reg/clocked_on}] -master_clock gen_clk_div2 [get_pins {q_div_4_reg/Q}] -add
# Clock dividido por 8 (q_div_8)
create_generated_clock -name gen_clk_div8 -divide_by 2 -source [get_flat_pins  {q_div_8_reg/clocked_on}] -master_clock gen_clk_div4 [get_pins {q_div_8_reg/Q}] -add
# Clock seleccionado en la salida del multiplexor de reloj (o_clock_w)
#create_generated_clock -name o_clock_w -source [get_ports i_clock] [get_flat_pins u_clock_mux/C23/Z\[0\]]
# Clocks generados para el MUX 
create_generated_clock -name gen_clk_CLOCK_MAIN_MUX -divide_by 1 -source [get_pins {u_clock_mux/C23/DATA1\[0\]}] -master_clock CLOCK_MAIN [get_pins {u_clock_mux/C23/Z\[0\]}] -add
create_generated_clock -name gen_clk_DIV2_CLK_MUX -divide_by 1 -source [get_pins {u_clock_mux/C23/DATA2\[0\]}] -master_clock gen_clk_div2 [get_pins {u_clock_mux/C23/Z\[0\]}] -add
create_generated_clock -name gen_clk_DIV4_CLK_MUX -divide_by 1 -source [get_pins {u_clock_mux/C23/DATA3\[0\]}] -master_clock gen_clk_div4 [get_pins {u_clock_mux/C23/Z\[0\]}] -add
create_generated_clock -name gen_clk_DIV8_CLK_MUX -divide_by 1 -source [get_pins {u_clock_mux/C23/DATA4\[0\]}] -master_clock gen_clk_div8 [get_pins {u_clock_mux/C23/Z\[0\]}] -add

# Configuración de los márgenes (uncertainties)
set_clock_uncertainty -setup 0.2 [get_clocks CLOCK_MAIN]
set_clock_uncertainty -hold 0.1 [get_clocks CLOCK_MAIN]

#Grupos logicamente exclusivos
set_clock_groups -group {CLOCK_MAIN} -group {gen_clk_div2} -group {gen_clk_div4} -group {gen_clk_div8} -logically_exclusive
set_clock_groups -group {gen_clk_CLOCK_MAIN_MUX} -group {gen_clk_DIV2_CLK_MUX} -group {gen_clk_DIV4_CLK_MUX} -group {gen_clk_DIV8_CLK_MUX} -physically_exclusive
## Previous version ---------------------------------
##set_clock_transition 0.2 [get_clocks $CLK_NAME]
##Defini los clks virtuales
## puts "INFO: Creando clocks virtuales"
## create_clock -name vir_$CLK_NAME -period $CLK_PERIOD ; #buscar definicion de clock virtuales
#
## #FALTA: definir clks virtuales de divisores  
## #Generated clocks para divisiones de frecuencia: un clock que es generado por logiica del chip de otro clock se llama generated clock
## #Clocks generados para DIV 2
## create_generated_clock -name gen_clk_FF_DIV_2 -divide_by 2 -source [get_flat_pins {q_reg/clocked_on}] -master_clock $CLK_NAME [get_flat_pins {q_reg/Q}] -add
## #Clocks generados para DIV 4
## create_generated_clock -name gen_clk_FF_DIV_4 -divide_by 4 -source [get_flat_pins {q_2_reg/clocked_on}] -master_clock $CLK_NAME [get_flat_pins {q_2_reg/Q}] -add
## #Clocks generados para DIV 8
## create_generated_clock -name gen_clk_FF_DIV_8 -divide_by 8 -source [get_flat_pins {q_3_reg/clocked_on}] -master_clock $CLK_NAME [get_flat_pins {q_3_reg/Q}] -add
#
## #Clocks generados a la salida del MUX 1
## create_generated_clock -name gen_clk_MUX_DIV_1 -divide_by 1 -source [get_flat_pins -of [get_flat_net clock_in_net  -filter direction==in]] -master_clock $CLK_NAME [get_flat_pins -of [get_flat_net output_mux= -filter direction==out]] -add
## create_generated_clock -name gen_clk_MUX_DIV_2 -divide_by 2 -source [get_flat_pins -of [get_flat_net q_next  -filter direction==in]] -master_clock $CLK_NAME [get_flat_pins -of [get_flat_net output_mux= -filter direction==out]] -add
## create_generated_clock -name gen_clk_MUX_DIV_4 -divide_by 4 -source [get_flat_pins -of [get_flat_net q_next_2  -filter direction==in]] -master_clock $CLK_NAME  [get_flat_pins -of [get_flat_net output_mux= -filter direction==out]] -add
## create_generated_clock -name gen_clk_MUX_DIV_8 -divide_by 8 -source [get_flat_pins -of [get_flat_net q_next_3  -filter direction==in]] -master_clock $CLK_NAME [get_flat_pins -of [get_flat_net output_mux= -filter direction==out]] -add
## #Grupos Logically exclusive
## set_clock_groups -group {CLK} -group {gen_clk_FF_DIV_2} -group {gen_clk_FF_DIV_4} -group {gen_clk_FF_DIV_8} -logically_exclusive
## #Grupos physically exclusive
## set_clock_groups -group {gen_clk_MUX_DIV_1} -group {gen_clk_MUX_DIV_2} -group {gen_clk_MUX_DIV_4} -group {gen_clk_MUX_DIV_8} -physically_exclusive
## --------------------------------------------
