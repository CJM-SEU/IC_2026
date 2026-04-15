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
                    shift_reg <= data_in;
                    bits_left <= 6'd24;
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
