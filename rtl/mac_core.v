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

    reg [31:0] last_prod;
    reg [23:0] accum_reg;
    reg [24:0] add_tmp;

    wire signed [31:0] mult_result;
    assign mult_result = $signed(inA) * $signed(inB);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_out <= 24'd0;
            carry <= 1'b0;
            cal_done <= 1'b0;
            last_prod <= 32'd0;
            accum_reg <= 24'd0;
            add_tmp <= 25'd0;
        end else begin
            cal_done <= 1'b0;

            if (calc_en) begin
                if (mode == 1'b0) begin
                    add_tmp = {1'b0, mult_result[23:0]} + {1'b0, last_prod[23:0]};
                    sum_out <= add_tmp[23:0];
                    last_prod <= mult_result;

                    if (add_tmp[24])
                        carry <= 1'b1;
                end else begin
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
