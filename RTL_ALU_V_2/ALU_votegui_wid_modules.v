//Esta ALU posee paralelismo de N_BITS. Posee un modulo para realizar las
//operaciones y ademas un divisor de frecuencia de clock.
//Tanto entradas como salidas seran registradas.
//
module ALU_votegui
#(
        parameter N_BITS = 32
)
(
//Salidas
///output        [N_BITS-1:0]    o_data,
output  [(N_BITS-1):0]        o_data,
output                          o_clock,
output                          o_valid,
////Entradas
input   [1:0]                   i_operation,
input   [1:0]                   i_sel_clock,
input                           i_enable,
input                           i_clock,
input   [N_BITS-1:0]            i_data_a,
input   [N_BITS-1:0]            i_data_b,
input                           i_valid,
input                           i_reset
);
////Definicion de variables tipo reg (Las salidas y entradas estan
//registradas)
reg     [N_BITS-1:0]            data_a;
reg     [N_BITS-1:0]            data_b;
////reg   [N_BITS-1:0]    data_out;
reg     [(N_BITS-1):0]        data_out;
reg                             q_2;
reg                             q_3;
reg                             q;
reg     [1:0]                   count;
reg                             o_valid_reg;
//Definicion de variables tipo wire

//wire  [N_BITS-1:0]    result;
wire    [(N_BITS-1):0]        	result;
wire            		clock_in_net;
wire                            q_next;
wire                            q_next_2;
wire                            q_next_3;
wire                            output_mux;
wire                            o_clock_w;
wire    [N_BITS-1:0]            data_a_wire;
wire    [N_BITS-1:0]            data_b_wire;
wire    [N_BITS:0]              sum_w;
wire    [N_BITS-1:0]            xor_w;
wire    [N_BITS-1:0]            or_w;
wire    [N_BITS-1:0]            and_w;
wire    [N_BITS-1:0]           	result_1;
wire    [N_BITS-1:0]		result_2;
//Senales intermedias para los resultados de cada operacion 
wire [N_BITS-1:0] xor_result, sum_result, and_result, or_result;

//Divisores de frecuencia
//Divisores de frecuencia
//assign i_operation_w = i_operation;
assign clock_in_net=i_clock;
always @ (posedge i_clock, posedge i_reset)
	begin
	if (i_reset)
	q<=1'b0;
	else
	q<=~q;
	end
assign q_next=q;
always @ (posedge q_next, posedge i_reset)
	begin
	if (i_reset)
		q_2<=1'b0;
	else
		q_2<=~q_2;
	end
assign q_next_2=q_2;
always @ (posedge q_next_2, posedge i_reset)
	begin
	if (i_reset)
		q_3<=1'b0;
	else
		q_3<=~q_3;
	end
assign q_next_3=q_3;
// Selector de frecuencia TOP
clock_mux u_clock_mux (
	.sel(i_sel_clock), //Conectar el selector de frecuencia del modulo al top-level
	.clk0(i_clock), //Frecuencia 0: original
	.clk1(q_next), //Frecuencia 1: DIV 2
	.clk2(q_next_2), //Frecuencia 2: DIV 4
	.clk3(q_next_3), //Frecuencia 3: DIV 8
	.clk_out(o_clock_w) //Salida seleccionada a top level
);
/* //Selector de frecuencia flat
assign output_mux= 	(i_sel_clock==2'b00) ? i_clock : 
			(i_sel_clock==2'b01) ? q_next : 
			(i_sel_clock==2'b10) ? q_next_2 : q_next_3;
assign o_clock_w = output_mux; */
//Registro las entradas y salidas en un registro de interfaz u_infc_*
always @ (posedge o_clock_w)
	begin: u_infc_in_a
	data_a [N_BITS-1:0] <= i_data_a[N_BITS-1:0];
	end
always @ (posedge o_clock_w)
	begin: u_infc_in_b
	data_b[N_BITS-1:0] <= i_data_b[N_BITS-1:0];
	end
always @ (posedge o_clock_w)
	begin: u_infc_out
//data_out[N_BITS-1:0] <= result; 
	data_out[(N_BITS-1):0] <= result;
	end
assign data_a_wire = data_a;
assign data_b_wire = data_b;
/* assign o_data = data_out;
assign xor_w = data_a_wire ^ data_b_wire;
assign sum_w =   data_a_wire + data_b_wire;
assign and_w =   data_a_wire & data_b_wire;
assign or_w =   data_a_wire | data_b_wire;
assign result_1 = (i_operation[0])? and_w : xor_w; 
assign result_2 = (i_operation[0])? sum_w : or_w;
assign result = (i_operation[1])? result_2 : result_1; */
 xor_op #(.N_BITS(N_BITS)) u_xor (
        .a(data_a_wire),
        .b(data_b_wire),
        .result(xor_result)
    );
sum_op #(.N_BITS(N_BITS)) u_sum (
        .a(data_a_wire),
        .b(data_b_wire),
        .result(sum_result)
    );
 and_op #(.N_BITS(N_BITS)) u_and (
        .a(data_a_wire),
        .b(data_b_wire),
        .result(and_result)
	);
or_op #(.N_BITS(N_BITS)) u_or (
        .a(data_a_wire),
        .b(data_b_wire),
        .result(or_result)
    );
op_mux #(.N_BITS(N_BITS)) u_mux (
        .sel(i_operation),
        .xor_res(xor_result),
        .sum_res(sum_result),
        .and_res(and_result),
        .or_res(or_result),
        .result(result)
    );
////el o_valid es una copia del i_valid con un delay de un ciclo de clock
//
always @ (posedge o_clock_w)
	begin : u_valid
	o_valid_reg<=i_valid;
	end
assign o_valid = o_valid_reg;
//habiltiacion del clock de salida
assign o_clock = i_enable ? o_clock_w : 1'b0;
endmodule

