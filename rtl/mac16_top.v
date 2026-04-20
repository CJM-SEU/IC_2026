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

    // ------------------------------------------------------------------------
    // mac16_top 顶层说明（控制面 + 数据面）
    // ------------------------------------------------------------------------
    // 数据面：
    //   串行 inA/inB(16bit, MSB first)
    //      -> serial_to_parallel 拼帧
    //      -> 输入FIFO(opA/opB)
    //      -> mac_core 计算(24bit结果 + carry)
    //      -> 结果FIFO(result_fifo)
    //      -> parallel_to_serial 串行输出(sum_out)
    //
    // 控制面：
    //   1) mode 切换触发全链路清空（global_rst_n 脉冲）
    //   2) schedule_active + sched_cnt 驱动一次计算窗口
    //   3) p2s_in_ready / p2s_load 协调结果下发并串模块
    // ------------------------------------------------------------------------

    // 顶层调度职责：
    // 1) 收集 inA/inB 16bit 串行帧
    // 2) 将操作数入队并触发 mac_core 计算
    // 3) 将 24bit 结果送入并串模块进行输出

    // ------------------------------
    // 内部连线与状态寄存器
    // ------------------------------

    // 输入拼帧相关
    wire inA_valid, inB_valid;
    wire inA_done, inB_done;
    wire [15:0] inA_par, inB_par;

    // 计算与输出握手相关
    wire cal_done;
    wire [23:0] mac_result;
    wire mac_carry;
    wire out_done;
    wire p2s_in_ready;
    wire in_done;

    // 调度控制信号
    reg calc_start;
    reg p2s_load;
    reg [2:0] sched_cnt;
    reg schedule_active;

    // 输入操作数FIFO（深度4）
    reg [15:0] opA_reg, opB_reg;
    reg [15:0] opA_fifo [0:3];
    reg [15:0] opB_fifo [0:3];
    reg [1:0] op_fifo_wr_ptr;
    reg [1:0] op_fifo_rd_ptr;
    reg [2:0] op_fifo_count;

    // 结果FIFO（深度4）
    reg [23:0] mac_result_shadow;
    reg [23:0] result_fifo [0:3];
    reg [1:0] fifo_wr_ptr;
    reg [1:0] fifo_rd_ptr;
    reg [2:0] fifo_count;

    // 防重复下发保护位：
    // 某些时刻 cal_done 与 p2s_in_ready 条件切换同拍，会导致重复 load_en 风险。
    // 该标志用于“打一拍隔离”。
    reg p2s_issue_hold;

    wire op_push;
    wire op_pop;

    // 输入FIFO控制：in_done 表示 inA/inB 同时完成一帧16bit输入。
    // - op_push: 收到完整输入帧且FIFO未满 -> 入队
    // - op_pop : 调度器空闲且FIFO非空 -> 出队给 mac_core
    assign op_push = in_done && (op_fifo_count < 3'd4);
    assign op_pop = (!schedule_active) && (op_fifo_count != 3'd0);
    
    // ------------------------------------------------------------------------
    // mode切换清空逻辑
    // ------------------------------------------------------------------------
    // mode_reg/mode_reg_d1 用于检测 mode 的边沿变化：
    //   mode_chg = 1 时将 global_rst_n 拉低1拍，达到“模式切换清空”目的。
    // 注意：该策略会清空内部FIFO和输出状态，切换边界帧可能被丢弃。
    // ------------------------------------------------------------------------
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
    // ^是抑或运算
    assign mode_chg = (mode_reg ^ mode_reg_d1);
    // 一旦检测到 mode 翻转，对内部模块打一个复位脉冲
    wire global_rst_n = rst_n && (!mode_chg);

    // 仅当两路输入都完成16bit拼帧，才视为一组有效输入
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

    // ------------------------------------------------------------------------
    // Global controller（核心时序）
    // ------------------------------------------------------------------------
    // 以一次 op_pop 出队作为时间基准：
    //   T+0: 把 opA/opB 从输入FIFO装入 opA_reg/opB_reg，schedule_active=1
    //   T+1: sched_cnt==0 时拉高 calc_start，触发 mac_core 计算
    //   T+2~T+4: 保持窗口，等待结果进入结果队列或直接下发
    //   T+5: sched_cnt==4，schedule_active 清零，允许下一帧出队
    //
    // 结果发送策略：
    //   - 并串空闲且结果FIFO为空：当前结果直接下发
    //   - 否则写入结果FIFO，等待并串空闲后再发
    // ------------------------------------------------------------------------
    always @(posedge clk or negedge global_rst_n) begin
        if (!global_rst_n) begin
            // mode切换或rst时，所有状态清零
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
            // 默认脉冲信号每拍拉低，命中条件时再拉高1拍
            calc_start <= 1'b0;
            p2s_load <= 1'b0;

            // p2s_issue_hold 用于避免同拍重复下发 load_en
            if (p2s_issue_hold) begin
                p2s_issue_hold <= 1'b0;
            end else begin
                // 计算结果到达时：
                // - 若并串空闲且结果FIFO空，直接发出
                // - 否则先写入结果FIFO排队
                if (cal_done) begin
                    if (p2s_in_ready && (fifo_count == 3'd0)) begin
                        // 旁路直发：减少结果等待延迟
                        mac_result_shadow <= mac_result;
                        p2s_load <= 1'b1;
                        p2s_issue_hold <= 1'b1;
                    end else if (fifo_count < 3'd4) begin
                        // 写入结果FIFO排队
                        result_fifo[fifo_wr_ptr] <= mac_result;
                        fifo_wr_ptr <= fifo_wr_ptr + 1'b1;
                        fifo_count <= fifo_count + 1'b1;
                    end
                end else if (p2s_in_ready && (fifo_count != 3'd0)) begin
                    // 并串空闲时，从结果FIFO取最旧结果发送
                    mac_result_shadow <= result_fifo[fifo_rd_ptr];
                    p2s_load <= 1'b1;
                    p2s_issue_hold <= 1'b1;
                    fifo_rd_ptr <= fifo_rd_ptr + 1'b1;
                    fifo_count <= fifo_count - 1'b1;
                end
            end

            // 输入拼帧完成后入队，避免 schedule_active 忙碌期间丢帧
            if (op_push) begin
                opA_fifo[op_fifo_wr_ptr] <= inA_par;
                opB_fifo[op_fifo_wr_ptr] <= inB_par;
                op_fifo_wr_ptr <= op_fifo_wr_ptr + 1'b1;
            end

            // 调度器空闲时，从输入FIFO取一帧作为本次计算输入
            if (op_pop) begin
                opA_reg <= opA_fifo[op_fifo_rd_ptr];
                opB_reg <= opB_fifo[op_fifo_rd_ptr];
                op_fifo_rd_ptr <= op_fifo_rd_ptr + 1'b1;
                schedule_active <= 1'b1;
                sched_cnt <= 3'd0;
            end

            // 入队出队计数统一在同一个 case 中处理，避免重复改写计数
            case ({op_push, op_pop})
                2'b10: op_fifo_count <= op_fifo_count + 1'b1;
                2'b01: op_fifo_count <= op_fifo_count - 1'b1;
                default: op_fifo_count <= op_fifo_count;
            endcase

            if (schedule_active) begin
                sched_cnt <= sched_cnt + 1'b1;

                if (sched_cnt == 3'd0)
                    calc_start <= 1'b1; // T+1 拉高 calc_en，触发 mac_core

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
