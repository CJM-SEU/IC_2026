`timescale 1ns/1ps

module mac16 (
    input  wire mode,
    input  wire inA,
    input  wire inB,
    input  wire clk,
    input  wire rst_n,
    output wire sum_out,
    output wire carry,
    // out_ready=1 表示 sum_out 当前位有效（24bit 串行输出窗口内）
    output wire out_ready
);

    // 赛题顶层封装：对外只暴露题目定义的引脚。
    // 当前实现采用连续位流输入模型，因此 data_en 固定为 1。
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
