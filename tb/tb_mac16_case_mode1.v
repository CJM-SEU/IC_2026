`timescale 1ns/1ps

module tb_mac16_case_mode1;

    // 分场景TB-Case2：mode=1，检查全状态累加输出序列。

    reg mode, inA, inB, clk, rst_n;
    wire sum_out, carry, out_ready;

    reg [23:0] expected_q [0:5];
    integer q_wr;
    integer q_rd;

    reg [23:0] recv_word;
    integer recv_bits;
    reg out_ready_d;

    reg [23:0] accum_tb;
    reg test_failed;

    reg [24:0] tmp25;
    reg [23:0] exp_word;
    reg [15:0] vec_a [0:5];
    reg [15:0] vec_b [0:5];
    integer i;

    mac16 u_dut (
        .mode(mode),
        .inA(inA),
        .inB(inB),
        .clk(clk),
        .rst_n(rst_n),
        .sum_out(sum_out),
        .carry(carry),
        .out_ready(out_ready)
    );

    initial clk = 1'b0;
    always #0.5 clk = ~clk; // 1GHz

    task enqueue_expect_mode1;
        input [15:0] a;
        input [15:0] b;
        reg signed [31:0] prod;
        begin
            prod = $signed(a) * $signed(b);
            tmp25 = {1'b0, accum_tb} + {1'b0, prod[23:0]};
            exp_word = tmp25[23:0];
            accum_tb = tmp25[23:0];

            expected_q[q_wr] = exp_word;
            q_wr = q_wr + 1;
        end
    endtask

    task send_frame;
        input [15:0] data_a;
        input [15:0] data_b;
        integer k;
        begin
            for (k = 15; k >= 0; k = k - 1) begin
                @(negedge clk);
                inA = data_a[k];
                inB = data_b[k];
            end
        end
    endtask

    task fail_once;
        begin
            if (!test_failed) begin
                test_failed = 1'b1;
                $display("Simulation Failed");
            end
        end
    endtask

    task wait_frame_count;
        input integer target;
        integer guard;
        begin
            guard = 0;
            while ((q_rd < target) && (guard < 2000)) begin
                @(posedge clk);
                guard = guard + 1;
            end
            if (q_rd < target) begin
                $display("FAIL_REASON: timeout target=%0d got=%0d t=%0t", target, q_rd, $time);
                fail_once();
            end
        end
    endtask

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_mac16_case_mode1);

        vec_a[0] = 16'd2;
        vec_a[1] = 16'd8;
        vec_a[2] = 16'd14;
        vec_a[3] = 16'd116;
        vec_a[4] = 16'd1546;
        vec_a[5] = 16'd20698;

        vec_b[0] = 16'd6;
        vec_b[1] = 16'd30;
        vec_b[2] = 16'd71;
        vec_b[3] = 16'd828;
        vec_b[4] = 16'd1152;
        vec_b[5] = 16'd728;

        mode = 1'b0;
        rst_n = 1'b0;
        inA = 1'b0;
        inB = 1'b0;

        q_wr = 0;
        q_rd = 0;
        recv_word = 24'd0;
        recv_bits = 0;
        out_ready_d = 1'b0;
        accum_tb = 24'd0;
        test_failed = 1'b0;

        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        // 先在mode=0稳定两个周期，再切到mode=1，避免上电切换瞬态干扰
        repeat (2) @(posedge clk);
        mode = 1'b1;
        repeat (2) @(posedge clk);

        for (i = 0; i < 6; i = i + 1) begin
            enqueue_expect_mode1(vec_a[i], vec_b[i]);
            send_frame(vec_a[i], vec_b[i]);
        end

        wait_frame_count(6);

        if (q_rd != q_wr)
            fail_once();

        if (!test_failed)
            $display("Simulation Passed");

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

            if (out_ready)
                recv_word <= {recv_word[22:0], sum_out};

            if (out_ready && !out_ready_d)
                recv_bits <= 1;
            else if (out_ready)
                recv_bits <= recv_bits + 1;

            if (!out_ready && out_ready_d) begin
                if (recv_bits == 24) begin
                    if (recv_word !== expected_q[q_rd]) begin
                        $display("FAIL_REASON: mismatch q=%0d got=0x%06h exp=0x%06h t=%0t", q_rd, recv_word, expected_q[q_rd], $time);
                        fail_once();
                    end
                    q_rd <= q_rd + 1;
                end
                recv_bits <= 0;
            end
        end
    end

endmodule
