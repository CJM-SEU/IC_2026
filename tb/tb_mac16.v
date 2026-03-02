`timescale 1ns/1ps

module tb_mac16;

    // 1. 定义信号
    reg mode, inA, inB, clk, rst_n;
    wire sum_out, carry, out_ready;
    reg data_en;

    // 2. 实例化被测模块
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

    // 3. 生成时钟 (10ns 周期 = 100MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // 4. 串行发送任务 (同时驱动 inA 和 inB)
    task send_data;
        input [15:0] data_a;
        input [15:0] data_b;
        integer i;
        begin
            data_en = 1'b1;
            for (i = 15; i >= 0; i = i - 1) begin
                @(negedge clk);
                inA = data_a[i];
                inB = data_b[i];
            end
            #30;
            data_en = 1'b0;
        end
    endtask
    
    // 5. 测试流程
    // 生成波形文件 (关键！)
    initial begin
        $dumpfile("dump.vcd"); // 生成 dump.vcd 文件
        $dumpvars(0, tb_mac16); // 记录所有信号
    end
    initial begin
        // 初始化
        mode = 0; 
        rst_n = 0; 
        inA = 0; 
        inB = 0;
        data_en = 0;

        // 复位 (2 个时钟周期后置高)
        #20; 
        rst_n = 1; 
        #100;

        // 测试用例 1: Mode 0, 输入 2 和 6
        $display("=== Test Case 1: Mode 0, Data 2 & 6 ===");
        mode = 0;
        send_data(16'd2, 16'd6);
        #600; // 等待输出完成

        //测试用例 2: Mode 0, 输入 8 和 30
        $display("=== Test Case 2: Mode 0, Data 8 & 30 ===");
        send_data(16'd8, 16'd30);
        #600;

        // // 测试用例 3: Mode 1 切换测试
        // $display("=== Test Case 3: Mode Switch 0->1 ===");
        // mode = 1;
        // #20;
        // send_data(16'd14, 16'd71);
        // #600;

        // 结束
        $display("=== All Tests Finished! ===");
        $stop;
    end

    // 6. 日志监控 (在 Transcript 窗口显示输出)
    always @(posedge clk) begin
        if (out_ready) begin
            $display("Time=%0t | sum_out=%b | carry=%b", $time, sum_out, carry);
        end
    end

endmodule
