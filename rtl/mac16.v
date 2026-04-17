`timescale 1ns/1ps

module mac16 (
    input  wire mode,
    input  wire inA,
    input  wire inB,
    input  wire clk,
    input  wire rst_n,
    output wire sum_out,
    output wire carry,
    output wire out_ready
);

    // 赛题引脚未定义输入有效信号，这里默认每拍都采样输入位。
    mac16_top u_mac16_top (
        .mode(mode),
        .inA(inA),
        .inB(inB),
        .clk(clk),
        .rst_n(rst_n),
        .data_en(1'b1),
        .sum_out(sum_out),
        .carry(carry),
        .out_ready(out_ready)
    );

endmodule
