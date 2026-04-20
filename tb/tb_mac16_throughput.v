`timescale 1ns/1ps

module tb_mac16_throughput;

    // 吞吐TB：连续输入多帧，统计 in_done/cal_done/p2s_load/out_done 关系，
    // 验证负载下结果链路是否保持有界时延与计数一致性。

    reg mode, inA, inB, clk, rst_n;
    wire sum_out, carry, out_ready;
    reg data_en;

    integer sent_frames;
    integer in_done_count;
    integer out_done_count;
    integer cal_done_count;
    integer p2s_load_count;
    integer pending_loads;
    integer head_wait_cycles;
    integer MAX_LOAD_TO_DONE_CYCLES;

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

    task send_frame_stream;
        input [15:0] data_a;
        input [15:0] data_b;
        input drop_en_after;
        integer i;
        begin
            // 可选择在该帧后拉低 data_en，用于构造帧间边界
            for (i = 15; i >= 0; i = i - 1) begin
                @(negedge clk);
                data_en = 1'b1;
                inA = data_a[i];
                inB = data_b[i];
            end

            if (drop_en_after) begin
                @(negedge clk);
                data_en = 1'b0;
                inA = 1'b0;
                inB = 1'b0;
            end
        end
    endtask

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_mac16_throughput);

        mode = 1'b0;
        rst_n = 1'b0;
        inA = 1'b0;
        inB = 1'b0;
        data_en = 1'b0;

        sent_frames = 0;
        in_done_count = 0;
        out_done_count = 0;
        cal_done_count = 0;
        p2s_load_count = 0;
        pending_loads = 0;
        head_wait_cycles = 0;
        MAX_LOAD_TO_DONE_CYCLES = 30;

        #5;
        rst_n = 1'b1;
        repeat (4) @(posedge clk);

        // 无帧间空隙连续输入4帧
        sent_frames = 4;
        send_frame_stream(16'd2, 16'd6, 1'b0);
        send_frame_stream(16'd8, 16'd30, 1'b0);
        send_frame_stream(16'd11, 16'd12, 1'b0);
        send_frame_stream(16'd14, 16'd71, 1'b1);

        // 等待所有输出收敛
        repeat (600) @(posedge clk);

        $display("THROUGHPUT_REPORT sent_frames=%0d in_done_count=%0d cal_done_count=%0d p2s_load_count=%0d out_done_count=%0d", sent_frames, in_done_count, cal_done_count, p2s_load_count, out_done_count);

        if (out_done_count > in_done_count) begin
            $display("ERROR: out_done_count cannot exceed accepted input frames");
            $fatal(1);
        end

        if (out_done_count == sent_frames)
            $display("THROUGHPUT_STATUS full-throughput-under-continuous-stream");
        else
            $display("THROUGHPUT_STATUS output-bottleneck-detected");

        $finish;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_done_count <= 0;
            out_done_count <= 0;
            pending_loads <= 0;
            head_wait_cycles <= 0;
        end else begin
            if (u_dut.in_done) begin
                in_done_count <= in_done_count + 1;
                $display("IN_DONE t=%0t count=%0d", $time, in_done_count + 1);
            end

            if (u_dut.cal_done) begin
                cal_done_count <= cal_done_count + 1;
                $display("CAL_DONE t=%0t count=%0d", $time, cal_done_count + 1);
            end

            if (u_dut.p2s_load) begin
                p2s_load_count <= p2s_load_count + 1;
                pending_loads <= pending_loads + 1;
                $display("P2S_LOAD t=%0t count=%0d", $time, p2s_load_count + 1);
            end

            if (u_dut.out_done) begin
                out_done_count <= out_done_count + 1;
                if (pending_loads == 0) begin
                    $display("ERROR: out_done happened without pending load");
                    $fatal(1);
                end
                pending_loads <= pending_loads - 1;
                head_wait_cycles <= 0;
                $display("OUT_DONE t=%0t count=%0d", $time, out_done_count + 1);
            end else if (pending_loads != 0) begin
                head_wait_cycles <= head_wait_cycles + 1;
                if ((head_wait_cycles + 1) > MAX_LOAD_TO_DONE_CYCLES) begin
                    $display("ERROR: load-to-done latency exceeded bound (%0d cycles)", MAX_LOAD_TO_DONE_CYCLES);
                    $fatal(1);
                end
            end
        end
    end

endmodule
