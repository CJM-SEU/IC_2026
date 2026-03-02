module serial_to_parallel (
    input wire clk,
    input wire rst_n,
    input wire data_en,
    input wire serial_in,
    output reg [15:0] data_out,
    output wire data_valid
);

    reg [3:0] cnt;
    reg [15:0] shift_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 4'd15;
        else if (data_en) begin
            if (cnt == 4'd15)
                cnt <= 4'd0;
            else
                cnt <= cnt + 1'b1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shift_reg <= 16'd0;
        else if (data_en)
            shift_reg <= {shift_reg[14:0], serial_in};
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 16'd0;
        else if (data_en && (cnt == 4'd15))
            data_out <= shift_reg;
    end

    // 关键：data_valid 是 wire，用 assign 赋值
    assign data_valid = (cnt == 4'd15) && data_en;

endmodule
