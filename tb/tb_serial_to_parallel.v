`timescale 1ns/1ps

module tb_serial_to_parallel;

    // 串并单元TB：按MSB-first输入16bit帧，检查 data_valid/in_done 和 data_out。

    reg data_en, data_in, clk, rst_n;
    wire [15:0] data_out;
    wire data_valid;
    wire in_done;

    reg [15:0] expected_q [0:15];
    integer q_wr, q_rd;

    serial_to_parallel dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_en(data_en),
        .data_in(data_in),
        .data_out(data_out),
        .data_valid(data_valid),
        .in_done(in_done)
    );

    initial clk = 0;
    always #0.5 clk = ~clk; // 1GHz

    task send_data;
        input [15:0] serial_in;
        integer i;
        begin
            // 逐bit发送一帧16bit数据
            data_en = 1'b0;
            for (i = 15; i >= 0; i = i - 1) begin
                @(negedge clk);
                data_en = 1'b1;
                data_in = serial_in[i];
            end
            @(negedge clk);
            data_en = 1'b0;
            data_in = 1'b0;
        end
    endtask

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_serial_to_parallel);

        rst_n = 1'b0;
        data_en = 1'b0;
        data_in = 1'b0;
        q_wr = 0;
        q_rd = 0;

        #5;
        rst_n = 1'b1;
        repeat (4) @(posedge clk);

        expected_q[q_wr] = 16'd2;   q_wr = q_wr + 1;
        send_data(16'd2);

        expected_q[q_wr] = 16'd8;   q_wr = q_wr + 1;
        send_data(16'd8);

        expected_q[q_wr] = 16'd14;  q_wr = q_wr + 1;
        send_data(16'd14);

        expected_q[q_wr] = 16'd116; q_wr = q_wr + 1;
        send_data(16'd116);

        repeat (16) @(posedge clk);

        if (q_rd != q_wr) begin
            $display("ERROR: Not all expected samples observed. q_rd=%0d q_wr=%0d", q_rd, q_wr);
            $fatal(1);
        end

        $display("=== tb_serial_to_parallel PASS ===");
        $finish;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_rd <= 0;
        end else begin
            if (data_valid) begin
                if (!in_done) begin
                    $display("ERROR: data_valid asserted without in_done");
                    $fatal(1);
                end

                if (data_out !== expected_q[q_rd]) begin
                    $display("ERROR: sample%0d mismatch. got=0x%04h exp=0x%04h", q_rd, data_out, expected_q[q_rd]);
                    $fatal(1);
                end

                q_rd <= q_rd + 1;
            end
        end
    end

endmodule
