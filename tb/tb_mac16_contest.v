`timescale 1ns/1ps

module tb_mac16_contest;

    // 赛题验收TB：串行输入6组数据，依次执行
    // Case1(mode=0)、Case2(mode=1)、Case3(mode 0->1 切换)并自动判定通过/失败。

    reg mode, inA, inB, clk, rst_n;
    wire sum_out, carry, out_ready;

    localparam integer TOTAL_FRAMES = 18;

    reg [23:0] expected_q [0:TOTAL_FRAMES-1];
    integer q_wr;
    integer q_rd;

    reg [23:0] recv_word;
    integer recv_bits;
    reg out_ready_d;

    reg signed [31:0] prev_prod_tb;
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

    task reset_scoreboard;
        begin
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
                exp_word = tmp25[23:0];
                accum_tb = tmp25[23:0];
            end

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

    task flag_fail;
        begin
            if (!test_failed) begin
                test_failed = 1'b1;
                $display("Simulation Failed");
            end
        end
    endtask

    task wait_until_received;
        input integer target_count;
        integer guard;
        begin
            // 防止无限等待：若目标帧长期未收到则判失败
            guard = 0;
            while ((q_rd < target_count) && (guard < 3000)) begin
                @(posedge clk);
                guard = guard + 1;
            end

            if (q_rd < target_count) begin
                $display("FAIL_REASON: wait timeout target=%0d got=%0d t=%0t", target_count, q_rd, $time);
                flag_fail();
            end
        end
    endtask

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_mac16_contest);

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
        test_failed = 1'b0;

        reset_scoreboard();

        // rst_n 在2个clk周期后拉高
        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        // Case1: mode=0, 6组输入
        mode = 1'b0;
        reset_scoreboard();
        for (i = 0; i < 6; i = i + 1) begin
            enqueue_expect(1'b0, vec_a[i], vec_b[i]);
            send_frame(vec_a[i], vec_b[i]);
        end

        // 等待Case1全部6帧输出完成，再进入Case2
        wait_until_received(6);

        // Case2: mode=1, 6组输入
        mode = 1'b1;
        repeat (2) @(posedge clk);
        if (carry !== 1'b0) begin
            $display("FAIL_REASON: carry not cleared before Case2, t=%0t", $time);
            flag_fail();
        end

        reset_scoreboard();
        for (i = 0; i < 6; i = i + 1) begin
            enqueue_expect(1'b1, vec_a[i], vec_b[i]);
            send_frame(vec_a[i], vec_b[i]);
        end

        // 等待Case2全部6帧输出完成，再进入Case3
        wait_until_received(12);

        // Case3: mode 0->1, 在14&71输入完成后切换
        mode = 1'b0;
        repeat (2) @(posedge clk);
        if (carry !== 1'b0) begin
            $display("FAIL_REASON: carry not cleared before Case3, t=%0t", $time);
            flag_fail();
        end

        reset_scoreboard();
        for (i = 0; i < 3; i = i + 1) begin
            enqueue_expect(1'b0, vec_a[i], vec_b[i]);
            send_frame(vec_a[i], vec_b[i]);
        end

        // 在切mode前先等待前三组mode0结果稳定输出，避免输出队列被切换清空
        wait_until_received(15);

        mode = 1'b1;
        repeat (2) @(posedge clk);
        if (carry !== 1'b0) begin
            $display("FAIL_REASON: carry not cleared after 0->1 in Case3, t=%0t", $time);
            flag_fail();
        end

        reset_scoreboard();
        for (i = 3; i < 6; i = i + 1) begin
            enqueue_expect(1'b1, vec_a[i], vec_b[i]);
            send_frame(vec_a[i], vec_b[i]);
        end

        // 等待全部18帧输出完成
        wait_until_received(18);

        if (q_rd != q_wr)
            flag_fail();

        if (!test_failed)
            $display("Simulation Passed");

        $finish;
    end

    // 串行接收并按帧比对（仅24bit完整帧计入比较）
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
                        flag_fail();
                    end

                    q_rd <= q_rd + 1;
                end else begin
                    // mode切换引起的截断输出帧直接丢弃，不参与验收计数
                end
                recv_bits <= 0;
            end
        end
    end

endmodule
