`timescale 1ns/1ps

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
    wire inA_done, inB_done;
    wire [15:0] inA_par, inB_par;
    wire cal_done;
    wire [23:0] mac_result;
    wire mac_carry;
    wire out_done;
    wire p2s_in_ready;
    wire in_done;
    reg calc_start;
    reg p2s_load;
    reg [2:0] sched_cnt;
    reg schedule_active;
    reg [15:0] opA_reg, opB_reg;
    reg [15:0] opA_fifo [0:3];
    reg [15:0] opB_fifo [0:3];
    reg [1:0] op_fifo_wr_ptr;
    reg [1:0] op_fifo_rd_ptr;
    reg [2:0] op_fifo_count;
    reg [23:0] mac_result_shadow;
    reg [23:0] result_fifo [0:3];
    reg [1:0] fifo_wr_ptr;
    reg [1:0] fifo_rd_ptr;
    reg [2:0] fifo_count;
    reg p2s_issue_hold;

    wire op_push;
    wire op_pop;

    assign op_push = in_done && (op_fifo_count < 3'd4);
    assign op_pop = (!schedule_active) && (op_fifo_count != 3'd0);
    
    // 模式切换复位逻辑 (题目要求 mode 切换时清空)
    reg mode_reg;
    reg mode_reg_d1;
    wire mode_chg;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            mode_reg <= 1'b0;
            mode_reg_d1 <= 1'b0;
        end else begin
            mode_reg <= mode;
            mode_reg_d1 <= mode_reg;
        end
    end
    assign mode_chg = (mode_reg ^ mode_reg_d1);
    wire global_rst_n = rst_n && (!mode_chg); // 模式切换时相当于复位
    assign in_done = inA_done & inB_done;

    // 1. 实例化输入模块 (需要两个，一个收 inA，一个收 inB)
    // 注意：题目是 inA 和 inB 同时串行输入，所以使能信号一样
    serial_to_parallel u_inA (
        .clk(clk), .rst_n(global_rst_n), .data_en(data_en), 
        .data_in(inA), .data_out(inA_par), .data_valid(inA_valid), .in_done(inA_done)
    );

    serial_to_parallel u_inB (
        .clk(clk), .rst_n(global_rst_n), .data_en(data_en), 
        .data_in(inB), .data_out(inB_par), .data_valid(inB_valid), .in_done(inB_done)
    );

    // Global controller: 固化 T+0~T+5 的调度窗口
    always @(posedge clk or negedge global_rst_n) begin
        if (!global_rst_n) begin
            calc_start <= 1'b0;
            p2s_load <= 1'b0;
            sched_cnt <= 3'd0;
            schedule_active <= 1'b0;
            opA_reg <= 16'd0;
            opB_reg <= 16'd0;
            opA_fifo[0] <= 16'd0;
            opA_fifo[1] <= 16'd0;
            opA_fifo[2] <= 16'd0;
            opA_fifo[3] <= 16'd0;
            opB_fifo[0] <= 16'd0;
            opB_fifo[1] <= 16'd0;
            opB_fifo[2] <= 16'd0;
            opB_fifo[3] <= 16'd0;
            op_fifo_wr_ptr <= 2'd0;
            op_fifo_rd_ptr <= 2'd0;
            op_fifo_count <= 3'd0;
            mac_result_shadow <= 24'd0;
            result_fifo[0] <= 24'd0;
            result_fifo[1] <= 24'd0;
            result_fifo[2] <= 24'd0;
            result_fifo[3] <= 24'd0;
            fifo_wr_ptr <= 2'd0;
            fifo_rd_ptr <= 2'd0;
            fifo_count <= 3'd0;
            p2s_issue_hold <= 1'b0;
        end else begin
            calc_start <= 1'b0;
            p2s_load <= 1'b0;

            if (p2s_issue_hold) begin
                p2s_issue_hold <= 1'b0;
            end else begin
                // 计算结果到达时，若输出空闲且队列空则直接发；否则进入2级队列
                if (cal_done) begin
                    if (p2s_in_ready && (fifo_count == 3'd0)) begin
                        mac_result_shadow <= mac_result;
                        p2s_load <= 1'b1;
                        p2s_issue_hold <= 1'b1;
                    end else if (fifo_count < 3'd4) begin
                        result_fifo[fifo_wr_ptr] <= mac_result;
                        fifo_wr_ptr <= fifo_wr_ptr + 1'b1;
                        fifo_count <= fifo_count + 1'b1;
                    end
                end else if (p2s_in_ready && (fifo_count != 3'd0)) begin
                    mac_result_shadow <= result_fifo[fifo_rd_ptr];
                    p2s_load <= 1'b1;
                    p2s_issue_hold <= 1'b1;
                    fifo_rd_ptr <= fifo_rd_ptr + 1'b1;
                    fifo_count <= fifo_count - 1'b1;
                end
            end

            // 输入拼帧完成后入队，避免schedule_active期间丢失in_done
            if (op_push) begin
                opA_fifo[op_fifo_wr_ptr] <= inA_par;
                opB_fifo[op_fifo_wr_ptr] <= inB_par;
                op_fifo_wr_ptr <= op_fifo_wr_ptr + 1'b1;
            end

            // 调度器空闲时，从输入队列取一帧启动一次计算窗口
            if (op_pop) begin
                opA_reg <= opA_fifo[op_fifo_rd_ptr];
                opB_reg <= opB_fifo[op_fifo_rd_ptr];
                op_fifo_rd_ptr <= op_fifo_rd_ptr + 1'b1;
                schedule_active <= 1'b1;
                sched_cnt <= 3'd0;
            end

            case ({op_push, op_pop})
                2'b10: op_fifo_count <= op_fifo_count + 1'b1;
                2'b01: op_fifo_count <= op_fifo_count - 1'b1;
                default: op_fifo_count <= op_fifo_count;
            endcase

            if (schedule_active) begin
                sched_cnt <= sched_cnt + 1'b1;

                if (sched_cnt == 3'd0)
                    calc_start <= 1'b1; // T+1 启动计算

                if (sched_cnt == 3'd4)
                    schedule_active <= 1'b0;
            end
        end
    end

    // 2. 实例化计算核心
    // 当 inA 和 inB 都收齐时，触发计算
    mac_core u_mac (
        .clk(clk), .rst_n(global_rst_n), 
        .calc_en(calc_start), 
        .inA(opA_reg), .inB(opB_reg), 
        .mode(mode), .sum_out(mac_result), .carry(mac_carry), .cal_done(cal_done)
    );

    // 3. 实例化输出模块
    parallel_to_serial u_out (
        .clk(clk), .rst_n(global_rst_n), 
        .load_en(p2s_load),
        .data_in(mac_result_shadow), 
        .serial_out(sum_out), .out_ready(out_ready), .out_done(out_done), .in_ready(p2s_in_ready)
    );

    assign carry = mac_carry;

endmodule
