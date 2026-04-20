# mac16_top 时序与数据流说明（文字版）

本文是 [rtl/mac16_top.v](../rtl/mac16_top.v) 的阅读辅助，目标是让你在不看波形的情况下快速理解拍级行为。

## 1. 总体路径

输入路径：
- `inA/inB` 串行位流 -> [rtl/serial_to_parallel.v](../rtl/serial_to_parallel.v) -> 16bit 并行帧
- 两路同时完成后形成一次 `in_done`
- 输入帧写入 `opA_fifo/opB_fifo`

计算路径：
- 调度器空闲时 `op_pop=1`，从输入FIFO取一帧到 `opA_reg/opB_reg`
- 下一拍拉高 `calc_start`，触发 [rtl/mac_core.v](../rtl/mac_core.v)
- `mac_core` 输出 `mac_result`，并给 `cal_done` 脉冲

输出路径：
- 若并串空闲且结果FIFO为空：结果直接旁路给并串
- 否则写入结果FIFO排队
- [rtl/parallel_to_serial.v](../rtl/parallel_to_serial.v) 在 `out_ready=1` 期间逐拍输出 24bit

## 2. 关键控制信号语义

- `op_push`：输入完整帧入队条件
- `op_pop`：调度器可取帧条件
- `schedule_active`：一次计算窗口是否正在进行
- `sched_cnt`：窗口内拍计数
- `calc_start`：给 `mac_core` 的单拍启动脉冲
- `p2s_load`：给并串模块的单拍装载脉冲
- `p2s_in_ready`：并串模块空闲可接收新帧
- `p2s_issue_hold`：避免边界条件下同拍重复下发 `p2s_load`

## 3. 调度窗口（T+0 到 T+5）

以“某次 `op_pop` 成功”为起点：

- `T+0`
- 从输入FIFO取一帧：`opA_reg/opB_reg` 更新
- `schedule_active` 置 1，`sched_cnt` 置 0

- `T+1`
- 命中 `sched_cnt==0`，拉高 `calc_start` 1 拍
- `mac_core` 开始处理本帧数据

- `T+2 ~ T+4`
- 等待 `cal_done` / 结果入队或旁路发送
- 并串空闲则尽快发，忙则排队

- `T+5`
- 命中 `sched_cnt==4`，`schedule_active` 清 0
- 调度器可切换到下一帧

## 4. 结果发送两条路径

### 4.1 旁路直发（低延迟路径）
触发条件：
- `cal_done=1`
- `p2s_in_ready=1`
- `fifo_count==0`

动作：
- `mac_result_shadow <= mac_result`
- `p2s_load <= 1`（单拍）

### 4.2 FIFO排队（拥塞路径）
触发条件：
- `cal_done=1`
- 并串忙，或已有结果排队

动作：
- 写 `result_fifo[fifo_wr_ptr]`
- `fifo_wr_ptr++`, `fifo_count++`

并串空闲后：
- 从 `result_fifo[fifo_rd_ptr]` 取出
- 打 `p2s_load` 下发

## 5. mode 切换清空机制

`mode` 变化时：
- 通过 `mode_reg ^ mode_reg_d1` 产生 `mode_chg`
- `global_rst_n = rst_n && !mode_chg`
- 等效于给内部模块一个清空脉冲

效果：
- 输入FIFO、结果FIFO、调度状态都被清零
- `carry` 等状态随下游复位行为清空

注意：
- mode 切换边界附近，尚未完整输出的帧可能被清空，这也是Case3验证需要特别处理的原因。

## 6. 阅读源码建议（最快路径）

1. 先看 `mode` 清空逻辑
- [rtl/mac16_top.v](../rtl/mac16_top.v)

2. 再看调度 always 块
- 找 `schedule_active/sched_cnt/calc_start`

3. 再看结果分发分支
- 找 `cal_done`、`p2s_in_ready`、`fifo_count`

4. 最后对照 TB
- [tb/tb_mac16.v](../tb/tb_mac16.v)
- [tb/tb_mac16_contest.v](../tb/tb_mac16_contest.v)

## 7. Pipe1 接入后的拍间关系（最新实现）

当前实现已经将 `mac_core` 的乘法路径切到 `mul_wallace_u16_pipe1`（1拍流水）。

对应文件：
- [rtl/mac_core.v](../rtl/mac_core.v)
- [rtl/mul_wallace_u16_pipe1.v](../rtl/mul_wallace_u16_pipe1.v)
- [rtl/parallel_to_serial.v](../rtl/parallel_to_serial.v)

### 7.1 拍间链路：`calc_en -> cal_done -> p2s_load -> out_ready`

以 `calc_en` 有效拍记为 `N`：

- `N` 拍
- `mul_wallace_u16_pipe1` 采样 `a/b` 与 `en`
- 同时 `mac_core` 记录 `mode_d <= mode`（保证模式与数据对齐）

- `N+1` 拍
- 乘法器输出 `mult_valid=1` 与对应 `mult_result`
- `mac_core` 在该拍执行 mode0/mode1 累加逻辑
- `mac_core` 产生 `cal_done=1`（单拍）

- `N+2` 拍（典型旁路路径）
- 顶层控制在检测到 `cal_done` 后拉高 `p2s_load`（单拍）
- 并串模块若空闲，会在 `load_en` 当拍直接把首 bit 打到 `serial_out`，并置 `out_ready=1`

结论：从 `calc_en` 到串行输出首 bit，典型是 2 拍（满足主 TB 的启动延迟约束）。

### 7.2 为什么并串模块要“当拍出首 bit”

如果并串模块按旧行为在 `load_en` 下一拍才开始 `out_ready`，
在 `pipe1` 接入后，端到端首包延迟会多 1 拍，触发 `tb_mac16` 的延迟检查。

因此当前 [rtl/parallel_to_serial.v](../rtl/parallel_to_serial.v) 在 `!busy && load_en` 分支下：
- 当拍输出 `data_in[23]`
- `out_ready` 当拍拉高
- 内部 `bits_left` 置 23，后续 busy 阶段继续输出剩余 23 bit

这样总输出窗口仍是 24bit，不改变帧长度协议。

### 7.3 两类可见时序（旁路与排队）

- 旁路直发：
`cal_done=1` 且并串空闲且结果FIFO空，下一拍直接 `p2s_load=1`，再下一拍/当拍即可见 `out_ready` 有效窗口起点。

- FIFO排队：
并串忙或结果FIFO非空时，本帧结果先进结果FIFO；后续待并串空闲再发。
该路径增加排队等待拍数，但不影响单帧 24bit 协议与 `cal_done` 语义。

### 7.4 审阅时重点观察信号

建议在波形中同时观察：
- `u_dut.calc_start`（=`mac_core.calc_en`）
- `u_dut.cal_done`
- `u_dut.p2s_load`
- `out_ready`
- `sum_out`

其中 `calc_start` 到 `cal_done` 应稳定 1 拍；`p2s_load` 与 `out_ready` 的相对关系取决于并串是否空闲。
