module clock_mux (
    input wire [1:0] sel,        // Selector de 2 bits
    input wire clk0,             // Frecuencia 1
    input wire clk1,             // Frecuencia 2
    input wire clk2,             // Frecuencia 3
    input wire clk3,             // Frecuencia 4
    output reg clk_out           // Salida de frecuencia seleccionada
);

    always @(*) begin
        case (sel)
            2'b00: clk_out = clk0;  // Selecciona clk0
            2'b01: clk_out = clk1;  // Selecciona clk1
            2'b10: clk_out = clk2;  // Selecciona clk2
            2'b11: clk_out = clk3;  // Selecciona clk3
            default: clk_out = clk0; // Valor por defecto
        endcase
    end

endmodule