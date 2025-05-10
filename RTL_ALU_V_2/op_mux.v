module op_mux #(
    parameter N_BITS = 32
) (
    input wire [1:0] sel,                      						 // Selector para elegir operación
    input wire [N_BITS-1:0] xor_res, sum_res, and_res, or_res,  	// Entradas de las operaciones
    output reg [N_BITS-1:0] result              					// Salida con el resultado
);
    always @(*) begin
        case (sel)
            2'b00: result = xor_res;   // Selecciona XOR
            2'b01: result = sum_res;   // Selecciona Suma
            2'b10: result = and_res;   // Selecciona AND
            2'b11: result = or_res;    // Selecciona OR
            default: result = {N_BITS{1'b0}};  // Valor por defecto (todos 0)
        endcase
    end
endmodule
