`default_nettype none

`define BITS 16
`define NUM_MULS 50
`define MAX_NUM 100

module my_multiply (
    input  logic [`BITS-1:0] a,
    input  logic [`BITS-1:0] b,
    output logic [2*`BITS-1:0] prod
);
    assign prod = a * b;
endmodule

module muls (
    input logic [2*`BITS*`MAX_NUM-1:0] _prod_in,
    output logic [2*`BITS*`MAX_NUM-1:0] _prod_out
);

    logic [`BITS-1:0] a[`MAX_NUM];
    logic [`BITS-1:0] b[`MAX_NUM];
    logic [2*`BITS-1:0] prod[`MAX_NUM];

    genvar i;
    generate
        for (i = 0; i < `NUM_MULS; i++) begin : gen_muls
            my_multiply mul_inst (
                .a(a[i][7:0]),
                .b(b[i][7:0]),
                .prod(prod[i])
            );
        end
        for (i = `NUM_MULS; i < `MAX_NUM; i++) begin : gen_empty
            assign prod[i] = '0;
        end
    endgenerate

    always_comb begin
        for (int x = 0; x < `MAX_NUM; x++) begin
            a[x] = _prod_in[x*`BITS +: `BITS];
            b[x] = _prod_in[`BITS*`MAX_NUM+x*`BITS +: `BITS];
            _prod_out[x*(2*`BITS) +: (2*`BITS)] = prod[x];
        end
    end

endmodule
