`timescale 100ps/1ps

module tb_parallel_to_serial;

    // 1. 定义信号
    reg clk, rst_n, load_en;
    reg [23:0] data_in;
    wire serial_out, out_ready;

    // 2. 实例化被测模块
    parallel_to_serial parallel_to_serial_dut (
        .clk(clk),
        .rst_n(rst_n),
        .load_en(load_en),
        .data_in(data_in),
        .serial_out(serial_out),
        .out_ready(out_ready)
    );

    // 3. 生成时钟 (1ns 周期 = 1GHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // 4. 并行加载任务
    task load_data;
        input [23:0] data_to_load;
        begin
            @(posedge clk);
            load_en = 1'b1;
            data_in = data_to_load;
            @(posedge clk);
            
            load_en = 1'b0;
            data_in = 24'd0;
        end
    endtask
    
    // 5. 测试流程
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_parallel_to_serial);
    end
    
    integer i;
    initial begin
        // 初始化 
        rst_n = 0; 
        load_en = 0;
        data_in = 24'd0;

        // 复位 (2 个时钟周期后置高)
        #20; 
        rst_n = 1; 
        #20;

        // 测试用例 1: 输入 2
        $display("=== Test Case 1: Send Data 24'd2 ===");
        load_data(24'b110000000000000000000011);
        
        // 等待串行输出完成 (24 个时钟周期 + 余量)
        for (i = 0; i < 30; i = i + 1) begin
            @(posedge clk);
        end
        
        $display("Test Case 1 Finished!");
        
        // 测试用例 2: 输入 24'd8
        $display("=== Test Case 2: Send Data 24'd8 ===");
        load_data(24'b110000000000000000000011);
        
        for (i = 0; i < 30; i = i + 1) begin
            @(posedge clk);
        end
        
        $display("Test Case 2 Finished!");
        
        // 测试用例 3: 输入 24'd14
        $display("=== Test Case 3: Send Data 24'd14 ===");
        load_data(24'b110000000000000000000011);
        
        for (i = 0; i < 30; i = i + 1) begin
            @(posedge clk);
        end
        
        $display("Test Case 3 Finished!");
        
        // 测试用例 4: 输入 24'd116 (全 0)
        $display("=== Test Case 4: Send Data 24'd116 ===");
        load_data(24'b110000000000000000000011);
        
        for (i = 0; i < 30; i = i + 1) begin
            @(posedge clk);
        end
        
        $display("Test Case 4 Finished!");
        
        // 结束
        $display("=== All Tests Finished! ===");
        $finish;
    end

    // 6. 日志监控 (在 Transcript 窗口显示输出)
    always @(posedge clk) begin
        $display("Time=%0t | Output: serial_out=%b, out_ready=%b", 
                     $time, serial_out, out_ready);
    end

endmodule