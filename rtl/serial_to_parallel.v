`timescale 1ns/1ps

module serial_to_parallel (
    input wire clk,
    input wire rst_n,
    input wire data_en,
    input wire data_in,
    output reg [15:0] data_out,
    output reg data_valid,
    output reg in_done
);

    // 当 data_en 连续有效时，每16拍拼出一帧并拉高 data_valid/in_done。
    // 若 data_en 拉低，当前半帧会被丢弃并清空计数。

    reg [4:0] cnt;
    reg [15:0] shift_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 5'd0;
            shift_reg <= 16'd0;
            data_out <= 16'd0;
            data_valid <= 1'b0;
            in_done <= 1'b0;
        end else begin
            data_valid <= 1'b0;
            in_done <= 1'b0;

            if (data_en) begin
                if (cnt == 5'd15) begin
                    // 最后一位到达，输出完整16bit并重新开始下一帧
                    data_out <= {shift_reg[14:0], data_in};
                    data_valid <= 1'b1;
                    in_done <= 1'b1;
                    cnt <= 5'd0;
                    shift_reg <= 16'd0;
                end else begin
                    shift_reg <= {shift_reg[14:0], data_in};
                    cnt <= cnt + 1'b1;
                end
            end else begin
                cnt <= 5'd0;
                shift_reg <= 16'd0;
            end
        end
    end

endmodule
