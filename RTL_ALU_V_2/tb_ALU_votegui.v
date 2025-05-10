module tb_ALU_votegui();
localparam      TB_NB=32; //Numero de bits
//inputs
wire            [TB_NB-1:0]     tb_i_data_a;
wire            [TB_NB-1:0]     tb_i_data_b;
wire                            tb_i_reset;
wire                            tb_i_enable;
wire                            tb_i_valid;
wire            [1:0]           tb_i_operation;
wire            [1:0]           tb_i_freq_clock;
//outputs
wire        [(TB_NB-1):0]    tb_o_data; 
wire                            tb_o_valid;
wire                            tb_o_clock;
//regs
reg                             tb_i_clock;
//integers
integer                         tb_output_counter_a;
integer                         tb_output_counter_b;

initial
        begin
        tb_i_clock              =       0;
        tb_output_counter_b     =       32'd31; //Se asigna un offset de valor inicial asi no se trabaja con vectores de muestra iguales
        tb_output_counter_a     =       0;
//        #5; //delay para asegurarse la inicializacion correcta
 //       forever #5 tb_i_clock = ~ tb_i_clock; 


        end
always
        #(2.5) tb_i_clock= ~tb_i_clock; //se hace coincidir el ciclo de trabajo y frecuencia del clock con los contraints
//Defino contador auxiliar
always @(posedge tb_i_clock)
        begin
        tb_output_counter_a<=tb_output_counter_a+1'b1;
        tb_output_counter_b<=tb_output_counter_b+1'b1;
        end
assign tb_i_data_a[TB_NB-1:0]=tb_output_counter_a[TB_NB-1:0];
assign tb_i_data_b[TB_NB-1:0]=tb_output_counter_b[TB_NB-1:0];
//Generacion de reset, enable, valid, y selector de operacion y frecuencia del
//clock
assign tb_i_reset       =       (tb_output_counter_a>4  &&      tb_output_counter_a<6);
//assign tb_i_reset       =      0; 
assign tb_i_enable      =       (tb_output_counter_a>1);
//assign tb_i_enable      =      1; 
assign tb_i_valid       =       (tb_output_counter_a>2);
//assign tb_i_valid       =       1;
//assign tb_i_operation   =       2'b00;
assign tb_i_operation   =       tb_output_counter_a[4:3];
//assign tb_i_freq_clock  =       2'b00;
assign tb_i_freq_clock  =       tb_output_counter_b[9:8];
ALU_votegui
#(
        .N_BITS (TB_NB)
)
u_ALU_v
(
        .o_data(tb_o_data),
        .o_clock(tb_o_clock),
        .o_valid(tb_o_valid),
        .i_operation(tb_i_operation),
        .i_freq_clock(tb_i_freq_clock),
        .i_enable(tb_i_enable),
        .i_clock(tb_i_clock),
        .i_data_a(tb_i_data_a),
        .i_data_b(tb_i_data_b),
        .i_valid(tb_i_valid),
        .i_reset(tb_i_reset)
);
endmodule
