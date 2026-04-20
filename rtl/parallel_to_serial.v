`timescale 1ns/1ps

module parallel_to_serial (
    input wire clk,
    input wire rst_n,
    input wire load_en,
    input wire [23:0] data_in,
    output reg serial_out,
    output reg out_ready,
    output reg out_done,
    output wire in_ready
);

    // load_en 装载24bit并启动发送；busy期间每拍送出1bit（MSB first）。
    // out_ready=1 表示 serial_out 有效；空闲时 serial_out 固定为0。

    reg [5:0] bits_left;
    reg [23:0] shift_reg;
    reg busy;

    assign in_ready = ~busy;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bits_left <= 6'd0;
            shift_reg <= 24'd0;
            busy <= 1'b0;
            serial_out <= 1'b0;
            out_ready <= 1'b0;
            out_done <= 1'b0;
        end else begin
            out_done <= 1'b0;

            if (!busy) begin
                serial_out <= 1'b0;
                out_ready <= 1'b0;

                if (load_en) begin
                    // 仅在空闲状态接受新帧，并在本拍直接输出MSB以缩短启动延迟。
                    out_ready <= 1'b1;
                    serial_out <= data_in[23];
                    shift_reg <= {data_in[22:0], 1'b0};
                    bits_left <= 6'd23;
                    busy <= 1'b1;
                end
            end else begin
                out_ready <= 1'b1;
                serial_out <= shift_reg[23];
                shift_reg <= {shift_reg[22:0], 1'b0};
                bits_left <= bits_left - 1'b1;

                if (bits_left == 6'd1) begin
                    busy <= 1'b0;
                    out_done <= 1'b1;
                end
            end
        end
    end

endmodule
