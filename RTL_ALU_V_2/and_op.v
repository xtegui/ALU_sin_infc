module and_op #(
    parameter N_BITS = 32
) (
    input wire [N_BITS-1:0] a, b,
    output wire [N_BITS-1:0] result
);
    assign result = a & b;
endmodule