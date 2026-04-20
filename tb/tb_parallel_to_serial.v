`timescale 1ns/1ps

module tb_parallel_to_serial;

    // 并串单元TB：检查空闲输出、电平窗口长度(24拍)和逐帧数据一致性。

    reg clk, rst_n, load_en;
    reg [23:0] data_in;
    wire serial_out, out_ready, out_done;

    reg [23:0] expected_q [0:15];
    integer q_wr, q_rd;

    reg [23:0] recv_word;
    integer recv_bits;
    reg out_ready_d;

    parallel_to_serial dut (
        .clk(clk),
        .rst_n(rst_n),
        .load_en(load_en),
        .data_in(data_in),
        .serial_out(serial_out),
        .out_ready(out_ready),
        .out_done(out_done)
    );

    initial clk = 0;
    always #0.5 clk = ~clk; // 1GHz

    task load_data;
        input [23:0] data_to_load;
        begin
            // 在空闲窗口打一拍 load_en 装载一帧24bit数据
            @(negedge clk);
            load_en = 1'b1;
            data_in = data_to_load;
            @(negedge clk);
            load_en = 1'b0;
            data_in = 24'd0;
        end
    endtask

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_parallel_to_serial);

        rst_n = 1'b0;
        load_en = 1'b0;
        data_in = 24'd0;
        q_wr = 0;
        q_rd = 0;
        recv_word = 24'd0;
        recv_bits = 0;
        out_ready_d = 1'b0;

        #5;
        rst_n = 1'b1;
        repeat (4) @(posedge clk);

        expected_q[q_wr] = 24'hC00003; q_wr = q_wr + 1;
        load_data(24'hC00003);
        repeat (30) @(posedge clk);

        expected_q[q_wr] = 24'h00ABCD; q_wr = q_wr + 1;
        load_data(24'h00ABCD);
        repeat (30) @(posedge clk);

        expected_q[q_wr] = 24'hF0F0F0; q_wr = q_wr + 1;
        load_data(24'hF0F0F0);
        repeat (30) @(posedge clk);

        if (q_rd != q_wr) begin
            $display("ERROR: Not all expected frames observed. q_rd=%0d q_wr=%0d", q_rd, q_wr);
            $fatal(1);
        end

        $display("=== tb_parallel_to_serial PASS ===");
        $finish;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_ready_d <= 1'b0;
            recv_word <= 24'd0;
            recv_bits <= 0;
            q_rd <= 0;
        end else begin
            out_ready_d <= out_ready;

            if (!out_ready && serial_out !== 1'b0) begin
                $display("ERROR: serial_out must be 0 when out_ready=0");
                $fatal(1);
            end

            if (out_done && !out_ready) begin
                $display("ERROR: out_done asserted while out_ready=0");
                $fatal(1);
            end

            if (out_ready)
                recv_word <= {recv_word[22:0], serial_out};

            if (out_ready && !out_ready_d)
                recv_bits <= 1;
            else if (out_ready)
                recv_bits <= recv_bits + 1;

            if (!out_ready && out_ready_d) begin
                if (recv_bits != 24) begin
                    $display("ERROR: out_ready window mismatch. got=%0d exp=24", recv_bits);
                    $fatal(1);
                end

                if (recv_word !== expected_q[q_rd]) begin
                    $display("ERROR: frame%0d mismatch. got=0x%06h exp=0x%06h", q_rd, recv_word, expected_q[q_rd]);
                    $fatal(1);
                end

                recv_bits <= 0;
                q_rd <= q_rd + 1;
            end
        end
    end

endmodule
