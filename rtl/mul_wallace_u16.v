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

module mul_wallace_u16 (
    input  wire [15:0] a,
    input  wire [15:0] b,
    output wire [31:0] product
);
    wire [31:0] pp [0:15];
    genvar k;

    // 16 unsigned partial-product rows.
    generate
        for (k = 0; k < 16; k = k + 1) begin : gen_pp
            assign pp[k] = b[k] ? ({16'b0, a} << k) : 32'b0;
        end
    endgenerate

    // Wallace-style reduction tree: 16 -> 11 -> 8 -> 6 -> 4 -> 3 -> 2 operands.
    wire [31:0] s10, c10, s11, c11, s12, c12, s13, c13, s14, c14;
    csa32 st1_0(.x(pp[0]),  .y(pp[1]),  .z(pp[2]),  .s(s10), .c(c10));
    csa32 st1_1(.x(pp[3]),  .y(pp[4]),  .z(pp[5]),  .s(s11), .c(c11));
    csa32 st1_2(.x(pp[6]),  .y(pp[7]),  .z(pp[8]),  .s(s12), .c(c12));
    csa32 st1_3(.x(pp[9]),  .y(pp[10]), .z(pp[11]), .s(s13), .c(c13));
    csa32 st1_4(.x(pp[12]), .y(pp[13]), .z(pp[14]), .s(s14), .c(c14));

    wire [31:0] s20, c20, s21, c21, s22, c22, s23, c23;
    csa32 st2_0(.x(s10), .y(c10), .z(s11),  .s(s20), .c(c20));
    csa32 st2_1(.x(c11), .y(s12), .z(c12),  .s(s21), .c(c21));
    csa32 st2_2(.x(s13), .y(c13), .z(s14),  .s(s22), .c(c22));
    csa32 st2_3(.x(c14), .y(pp[15]), .z(32'b0), .s(s23), .c(c23));

    wire [31:0] s30, c30, s31, c31, s32, c32;
    csa32 st3_0(.x(s20), .y(c20), .z(s21), .s(s30), .c(c30));
    csa32 st3_1(.x(c21), .y(s22), .z(c22), .s(s31), .c(c31));
    csa32 st3_2(.x(s23), .y(c23), .z(32'b0), .s(s32), .c(c32));

    wire [31:0] s40, c40, s41, c41;
    csa32 st4_0(.x(s30), .y(c30), .z(s31), .s(s40), .c(c40));
    csa32 st4_1(.x(c31), .y(s32), .z(c32), .s(s41), .c(c41));

    wire [31:0] s50, c50;
    csa32 st5_0(.x(s40), .y(c40), .z(s41), .s(s50), .c(c50));

    wire [31:0] s60, c60;
    csa32 st6_0(.x(s50), .y(c50), .z(c41), .s(s60), .c(c60));

    assign product = s60 + c60;
endmodule
