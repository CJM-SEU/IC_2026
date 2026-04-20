`timescale 1ns/1ps

module csa32 (
    input  wire [31:0] x,
    input  wire [31:0] y,
    input  wire [31:0] z,
    output wire [31:0] s,
    output wire [31:0] c
);
    wire [31:0] carry_raw;
    genvar i;

    // 3:2 compressor on each bit: sum stays in current bit, carry goes to next bit.
    generate
        for (i = 0; i < 32; i = i + 1) begin : gen_csa_fa
            fulladder u_fa (
                .in1(x[i]),
                .in2(y[i]),
                .in3(z[i]),
                .carry(carry_raw[i]),
                .sum(s[i])
            );
        end
    endgenerate

    assign c = {carry_raw[30:0], 1'b0};
endmodule
