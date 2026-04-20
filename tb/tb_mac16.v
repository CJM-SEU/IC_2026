`timescale 1ns/1ps

module tb_mac16;

    // 主门禁TB：覆盖基础功能、mode切换、5拍输出启动约束、sticky carry语义。

    reg mode, inA, inB, clk, rst_n;
    wire sum_out, carry, out_ready;
    reg data_en;

    reg signed [31:0] prev_prod_tb;
    reg [23:0] accum_tb;

    reg [23:0] expected_q [0:15];
    integer q_wr, q_rd;

    reg [23:0] recv_word;
    integer recv_bits;
    reg out_ready_d;

    reg pending_latency;
    integer latency_cnt;

    reg [24:0] tmp25;
    reg [23:0] exp_word;

    mac16_top u_dut (
        .mode(mode),
        .inA(inA),
        .inB(inB),
        .clk(clk),
        .rst_n(rst_n),
        .data_en(data_en),
        .sum_out(sum_out),
        .carry(carry),
        .out_ready(out_ready)
    );

    initial clk = 0;
    always #0.5 clk = ~clk; // 1GHz

    task reset_scoreboard;
        begin
            // 与DUT模式语义一致的参考模型状态
            prev_prod_tb = 32'sd0;
            accum_tb = 24'd0;
        end
    endtask

    task enqueue_expect;
        input test_mode;
        input [15:0] a;
        input [15:0] b;
        reg signed [31:0] prod;
        begin
            prod = $signed(a) * $signed(b);

            if (test_mode == 1'b0) begin
                tmp25 = {1'b0, prod[23:0]} + {1'b0, prev_prod_tb[23:0]};
                exp_word = tmp25[23:0];
                prev_prod_tb = prod;
            end else begin
                tmp25 = {1'b0, accum_tb} + {1'b0, prod[23:0]};
                accum_tb = tmp25[23:0];
                exp_word = tmp25[23:0];
            end

            expected_q[q_wr] = exp_word;
            q_wr = q_wr + 1;
        end
    endtask

    task send_data;
        input [15:0] data_a;
        input [15:0] data_b;
        integer i;
        begin
            // 以 MSB-first 方式连续送入16bit一帧
            data_en = 1'b0;
            for (i = 15; i >= 0; i = i - 1) begin
                @(negedge clk);
                data_en = 1'b1;
                inA = data_a[i];
                inB = data_b[i];
            end
            @(negedge clk);
            data_en = 1'b0;
        end
    endtask

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_mac16);

        mode = 1'b0;
        rst_n = 1'b0;
        inA = 1'b0;
        inB = 1'b0;
        data_en = 1'b0;

        q_wr = 0;
        q_rd = 0;
        recv_word = 24'd0;
        recv_bits = 0;
        out_ready_d = 1'b0;
        pending_latency = 1'b0;
        latency_cnt = 0;

        reset_scoreboard();

        #5;
        rst_n = 1'b1;
        repeat (4) @(posedge clk);

        $display("=== Case1 Mode0: 2 x 6 ===");
        mode = 1'b0;
        enqueue_expect(1'b0, 16'd2, 16'd6);
        send_data(16'd2, 16'd6);

        repeat (80) @(posedge clk);

        $display("=== Case2 Mode0: 8 x 30 ===");
        enqueue_expect(1'b0, 16'd8, 16'd30);
        send_data(16'd8, 16'd30);

        repeat (80) @(posedge clk);

        $display("=== Case3 ModeSwitch 0->1 then 14 x 71 ===");
        mode = 1'b1;
        repeat (2) @(posedge clk);

        if (carry !== 1'b0) begin
            $display("ERROR: carry must clear right after mode switch");
            $fatal(1);
        end

        // mode切换后内部应清空，scoreboard也同步清零
        reset_scoreboard();

        enqueue_expect(1'b1, 16'd14, 16'd71);
        send_data(16'd14, 16'd71);
        repeat (12) @(posedge clk);

        // 触发Mode1粘滞carry: 第二帧溢出后，后续帧应保持carry=1
        enqueue_expect(1'b1, 16'h7FFF, 16'h7FFF);
        send_data(16'h7FFF, 16'h7FFF);
        repeat (12) @(posedge clk);

        enqueue_expect(1'b1, 16'h7FFF, 16'h7FFF);
        send_data(16'h7FFF, 16'h7FFF);
        repeat (12) @(posedge clk);

        if (carry !== 1'b1) begin
            $display("ERROR: sticky carry must be 1 after overflow sequence");
            $fatal(1);
        end

        enqueue_expect(1'b1, 16'd1, 16'd1);
        send_data(16'd1, 16'd1);
        repeat (12) @(posedge clk);

        if (carry !== 1'b1) begin
            $display("ERROR: sticky carry must remain 1 after non-overflow frame");
            $fatal(1);
        end

        repeat (120) @(posedge clk);

        if (q_rd != q_wr) begin
            $display("ERROR: Not all expected frames consumed. q_rd=%0d q_wr=%0d", q_rd, q_wr);
            $fatal(1);
        end

        $display("=== tb_mac16 PASS ===");
        $finish;
    end

    // 输入完成后，5拍内必须开始输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending_latency <= 1'b0;
            latency_cnt <= 0;
        end else begin
            if (u_dut.in_done) begin
                pending_latency <= 1'b1;
                latency_cnt <= 0;
            end else if (pending_latency && !out_ready) begin
                latency_cnt <= latency_cnt + 1;
                if (latency_cnt > 5) begin
                    $display("ERROR: output start latency > 5 cycles");
                    $fatal(1);
                end
            end

            if (pending_latency && out_ready)
                pending_latency <= 1'b0;
        end
    end

    // 接收串行输出并做逐帧比对
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_ready_d <= 1'b0;
            recv_word <= 24'd0;
            recv_bits <= 0;
        end else begin
            out_ready_d <= out_ready;

            if (out_ready)
                recv_word <= {recv_word[22:0], sum_out};

            if (out_ready && !out_ready_d)
                recv_bits <= 1;
            else if (out_ready)
                recv_bits <= recv_bits + 1;

            if (!out_ready && out_ready_d) begin
                if (recv_bits != 24) begin
                    $display("ERROR: out_ready window != 24 cycles, got %0d", recv_bits);
                    $fatal(1);
                end

                if (recv_word !== expected_q[q_rd]) begin
                    $display("ERROR: frame%0d data mismatch. got=0x%06h exp=0x%06h", q_rd, recv_word, expected_q[q_rd]);
                    $fatal(1);
                end

                q_rd <= q_rd + 1;
                recv_bits <= 0;
            end
        end
    end

endmodule
