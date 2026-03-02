module mac16_top (
    input wire mode,
    input wire inA,
    input wire inB,
    input wire clk,
    input wire rst_n,
    input wire data_en,
    output wire sum_out,
    output wire carry,
    output wire out_ready

);

    // 内部连线
    wire inA_valid, inB_valid;
    wire [15:0] inA_par, inB_par;
    wire calc_done;
    wire [23:0] mac_result;
    wire mac_carry;
    
    // 模式切换复位逻辑 (题目要求 mode 切换时清空)
    reg mode_dly;
    wire mode_chg;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) mode_dly <= 0;
        else mode_dly <= mode;
    end
    assign mode_chg = (mode != mode_dly);
    wire global_rst_n = rst_n && (!mode_chg); // 模式切换时相当于复位

    // 1. 实例化输入模块 (需要两个，一个收 inA，一个收 inB)
    // 注意：题目是 inA 和 inB 同时串行输入，所以使能信号一样
    serial_to_parallel u_inA (
        .clk(clk), .rst_n(global_rst_n), .data_en(data_en), 
        .serial_in(inA), .data_out(inA_par), .data_valid(inA_valid)
    );

    serial_to_parallel u_inB (
        .clk(clk), .rst_n(global_rst_n), .data_en(data_en), 
        .serial_in(inB), .data_out(inB_par), .data_valid(inB_valid)
    );

    // 2. 实例化计算核心
    // 当 inA 和 inB 都收齐时，触发计算
    mac_core u_mac (
        .clk(clk), .rst_n(global_rst_n), 
        .calc_en(inA_valid && inB_valid), 
        .inA(inA_par), .inB(inB_par), 
        .mode(mode), .sum_out(mac_result), .carry(mac_carry)
    );

    // 3. 实例化输出模块
    // 当计算完成后 (这里简化为计算使能后的下一个周期，实际可能需要流水线延迟)
    parallel_to_serial u_out (
        .clk(clk), .rst_n(global_rst_n), 
        .load_en(inA_valid && inB_valid), // 简化逻辑：收齐即计算并准备输出
        .data_in(mac_result), 
        .serial_out(sum_out), .out_ready(out_ready)
    );

    assign carry = mac_carry;

endmodule
