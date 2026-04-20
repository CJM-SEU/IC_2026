`timescale 1ns/1ps

module mul_wallace_u16_pipe1 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    input  wire [15:0] a,
    input  wire [15:0] b,
    output wire [31:0] product,
    output wire        valid
);
    wire [31:0] pp [0:15];
    genvar k;

    // 16路无符号部分积，保持组合生成。
    generate
        for (k = 0; k < 16; k = k + 1) begin : gen_pp
            assign pp[k] = b[k] ? ({16'b0, a} << k) : 32'b0;
        end
    endgenerate

    // stage-1: 16 -> 11 -> 8
    wire [31:0] s10, c10, s11, c11, s12, c12, s13, c13, s14, c14;
    csa32 st1_0(.x(pp[0]),  .y(pp[1]),  .z(pp[2]),  .s(s10), .c(c10));
    csa32 st1_1(.x(pp[3]),  .y(pp[4]),  .z(pp[5]),  .s(s11), .c(c11));
    csa32 st1_2(.x(pp[6]),  .y(pp[7]),  .z(pp[8]),  .s(s12), .c(c12));
    csa32 st1_3(.x(pp[9]),  .y(pp[10]), .z(pp[11]), .s(s13), .c(c13));
    csa32 st1_4(.x(pp[12]), .y(pp[13]), .z(pp[14]), .s(s14), .c(c14));

    wire [31:0] s20, c20, s21, c21, s22, c22, s23, c23;
    csa32 st2_0(.x(s10), .y(c10), .z(s11),       .s(s20), .c(c20));
    csa32 st2_1(.x(c11), .y(s12), .z(c12),       .s(s21), .c(c21));
    csa32 st2_2(.x(s13), .y(c13), .z(s14),       .s(s22), .c(c22));
    csa32 st2_3(.x(c14), .y(pp[15]), .z(32'b0),  .s(s23), .c(c23));

    // 插一拍：截断关键路径，提升频率。
    reg [31:0] r_s20, r_c20, r_s21, r_c21, r_s22, r_c22, r_s23, r_c23;
    reg en_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_s20 <= 32'd0;
            r_c20 <= 32'd0;
            r_s21 <= 32'd0;
            r_c21 <= 32'd0;
            r_s22 <= 32'd0;
            r_c22 <= 32'd0;
            r_s23 <= 32'd0;
            r_c23 <= 32'd0;
            en_d <= 1'b0;
        end else begin
            en_d <= en;
            if (en) begin
                r_s20 <= s20;
                r_c20 <= c20;
                r_s21 <= s21;
                r_c21 <= c21;
                r_s22 <= s22;
                r_c22 <= c22;
                r_s23 <= s23;
                r_c23 <= c23;
            end
        end
    end

    // stage-2: 8 -> 6 -> 4 -> 3 -> 2
    wire [31:0] s30, c30, s31, c31, s32, c32;
    csa32 st3_0(.x(r_s20), .y(r_c20), .z(r_s21), .s(s30), .c(c30));
    csa32 st3_1(.x(r_c21), .y(r_s22), .z(r_c22), .s(s31), .c(c31));
    csa32 st3_2(.x(r_s23), .y(r_c23), .z(32'b0), .s(s32), .c(c32));

    wire [31:0] s40, c40, s41, c41;
    csa32 st4_0(.x(s30), .y(c30), .z(s31), .s(s40), .c(c40));
    csa32 st4_1(.x(c31), .y(s32), .z(c32), .s(s41), .c(c41));

    wire [31:0] s50, c50;
    csa32 st5_0(.x(s40), .y(c40), .z(s41), .s(s50), .c(c50));

    wire [31:0] s60, c60;
    csa32 st6_0(.x(s50), .y(c50), .z(c41), .s(s60), .c(c60));

    assign valid = en_d;
    assign product = s60 + c60;
endmodule
