`timescale 1ns/1ps

module tb_serial_to_parallel;

    // 1. 定义信号
    reg data_en, serial_in, clk, rst_n;
    wire [15:0] data_out;
    wire data_valid;

    // 2. 实例化被测模块
    serial_to_parallel serial_to_parallel_dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_en(data_en),
        .serial_in(serial_in),
        .data_out(data_out),
        .data_valid(data_valid)
    );

    // 3. 生成时钟 (10ns 周期 = 100MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // 4. 串行发送任务 (同时驱动 inA 和 inB)
    task send_data;
        input [15:0] data_a;
        integer i;
        begin
            data_en = 1'b1;
            for (i = 15; i >= 0; i = i - 1) begin
                @(negedge clk);
                serial_in = data_a[i];
            end
            #30;
            data_en = 1'b0;
        end
    endtask
    
    // 5. 测试流程
    // 生成波形文件 (关键！)
    initial begin
        $dumpfile("dump.vcd"); // 生成 dump.vcd 文件
        $dumpvars(0, tb_serial_to_parallel); // 记录所有信号
    end
    initial begin
        // 初始化 
        rst_n = 0; 
        serial_in = 0; 
        data_en = 0;

        // 复位 (2 个时钟周期后置高)
        #20; 
        rst_n = 1; 
        #100;

        // 测试用例 1: Mode 0, 输入 2 和 6
        $display("=== Test Case 1: Mode 0, Send Data 2 ");
        send_data(16'd2);

        // 结束
        $display("=== All Tests Finished! ===");
        $finish;
    end

    // 6. 日志监控 (在 Transcript 窗口显示输出)
    always @(posedge clk) begin
        $display("Time=%0t | Received: data_out=%d (0x%h), data_valid=%b", 
                     $time, data_out, data_out, data_valid);
    end

endmodule
