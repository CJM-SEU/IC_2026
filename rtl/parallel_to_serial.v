module parallel_to_serial (
    input wire clk,
    input wire rst_n,
    input wire load_en,
    input wire [23:0] data_in,
    output reg serial_out,      // reg 类型，在 always 里赋值
    output reg out_ready        // reg 类型，在 always 里赋值
);

    reg [4:0] cnt;
    reg [23:0] shift_reg;
    reg busy;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 5'd23;
            shift_reg <= 24'd0;
            busy <= 1'b0;
        end
    end
    always @(negedge clk or negedge rst_n) begin
        if (load_en) begin
            shift_reg <= data_in;
            cnt <= 5'd23;
            busy <= 1'b1;
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if (busy )  begin
            if (cnt == 5'd23 && !load_en) begin
                cnt <= 5'd0;
            end
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if (busy) begin
                cnt <= cnt + 1'b1;
            end
    end
    always @(negedge clk or negedge rst_n) begin
        if (busy) begin
                shift_reg <= {shift_reg[22:0], 1'b0};
            end
    end

    // serial_out 和 out_ready 在 always 块里赋值，所以必须是 reg
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            serial_out <= 1'b0;
            out_ready <= 1'b0;
        end
        else begin
            serial_out <= shift_reg[23];  // MSB 先出
            //out_ready <= busy;
        end
    end
    always @(negedge clk or negedge rst_n) begin
        if (busy == 1&& cnt == 5'd23 && !load_en) begin
            busy <= 1'b0;
        end
    end
    always @(negedge clk or negedge rst_n)begin
        if (!rst_n)begin
            out_ready <= 1'b0;
        end
        else if (cnt == 5'd23 && !out_ready)begin
            out_ready <= 1'b1;
        end
    end
    always @(negedge clk or negedge rst_n)begin
        if (cnt == 5'd0 && out_ready)begin
            out_ready <= 1'b0;
        end
    end

endmodule
