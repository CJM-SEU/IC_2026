`timescale 1ns/1ps

module mac_core (
    input wire clk,
    input wire rst_n,
    input wire calc_en,      // 计算使能，只有这个为 1 时才工作 (低功耗关键)
    input wire [15:0] inA,
    input wire [15:0] inB,
    input wire mode,         // 模式选择
    output reg [23:0] sum_out,
    output reg carry,        // 进位标志
    output reg cal_done
);

    // mode=0: sum_out = 当前乘积 + 上一帧乘积
    // mode=1: sum_out = 全状态累加（accum）
    // carry 为粘滞位：一旦溢出置1，仅在复位后清零

    reg [31:0] last_prod;
    reg [23:0] accum_reg;
    reg [24:0] add_tmp;
    reg mode_d;

    wire [31:0] mult_result;
    wire mult_valid;

    // 无符号乘法语义：按 16bit 无符号数相乘得到 32bit 结果。
    // 使用1拍流水的结构化 Wallace 压缩树乘法器，避免行为级 * 推断。
    mul_wallace_u16_pipe1 u_mul_wallace_u16_pipe1 (
        .clk(clk),
        .rst_n(rst_n),
        .en(calc_en),
        .a(inA),
        .b(inB),
        .product(mult_result),
        .valid(mult_valid)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_out <= 24'd0;
            carry <= 1'b0;
            cal_done <= 1'b0;
            mode_d <= 1'b0;
            last_prod <= 32'd0;
            accum_reg <= 24'd0;
            add_tmp <= 25'd0;
        end else begin
            cal_done <= 1'b0;
            if (calc_en)
                mode_d <= mode;

            if (mult_valid) begin
                if (mode_d == 1'b0) begin
                    // 仅保留低24位参与输出与溢出检测
                    add_tmp = {1'b0, mult_result[23:0]} + {1'b0, last_prod[23:0]};
                    sum_out <= add_tmp[23:0];
                    last_prod <= mult_result;

                    if (add_tmp[24])
                        carry <= 1'b1;
                end else begin
                    // 模式1持续累加每一帧的低24位乘积
                    add_tmp = {1'b0, accum_reg} + {1'b0, mult_result[23:0]};
                    accum_reg <= add_tmp[23:0];
                    sum_out <= add_tmp[23:0];

                    if (add_tmp[24])
                        carry <= 1'b1;
                end

                cal_done <= 1'b1;
            end
        end
    end
endmodule
