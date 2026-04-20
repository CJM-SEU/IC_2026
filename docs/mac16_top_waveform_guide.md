# mac16_top 波形对照指南（基于 tb_mac16）

本文用于把 [rtl/mac16_top.v](../rtl/mac16_top.v) 的内部逻辑与波形现象一一对应，帮助你在看 `dump.vcd` 时快速定位关键行为。

## 1. 推荐观测信号清单

### 1.1 顶层输入输出
- `clk`
- `rst_n`
- `mode`
- `inA`
- `inB`
- `sum_out`
- `out_ready`
- `carry`

### 1.2 输入拼帧相关（mac16_top 内部）
- `u_dut.u_inA.cnt`
- `u_dut.u_inB.cnt`
- `u_dut.inA_done`
- `u_dut.inB_done`
- `u_dut.in_done`
- `u_dut.inA_par`
- `u_dut.inB_par`

### 1.3 调度/队列相关（mac16_top 内部）
- `u_dut.op_push`
- `u_dut.op_pop`
- `u_dut.op_fifo_count`
- `u_dut.schedule_active`
- `u_dut.sched_cnt`
- `u_dut.calc_start`
- `u_dut.cal_done`
- `u_dut.fifo_count`
- `u_dut.p2s_load`
- `u_dut.p2s_in_ready`
- `u_dut.p2s_issue_hold`

### 1.4 计算与输出子模块内部（建议）
- `u_dut.u_mac.mult_result`
- `u_dut.u_mac.last_prod`
- `u_dut.u_mac.accum_reg`
- `u_dut.u_out.busy`
- `u_dut.u_out.bits_left`
- `u_dut.u_out.shift_reg`

## 2. 场景划分（对应 tb_mac16）

参考测试平台：[tb/tb_mac16.v](../tb/tb_mac16.v)

### 阶段A：复位阶段
期望波形：
- `rst_n=0` 时，内部计数器/FIFO/状态清零。
- `out_ready=0`，`sum_out=0`，`carry=0`。

快速核对：
- `u_dut.schedule_active==0`
- `u_dut.op_fifo_count==0`
- `u_dut.fifo_count==0`

### 阶段B：Case1 mode=0 输入与输出
期望波形：
- 连续16拍输入后，`inA_done` 与 `inB_done` 同拍拉高，`in_done` 拉高1拍。
- 随后出现 `op_push`，在调度空闲时出现 `op_pop`。
- `schedule_active` 拉高，`sched_cnt` 从0递增。
- `sched_cnt==0` 的下一拍看到 `calc_start=1`。
- `cal_done` 后若并串空闲，`p2s_load=1`，`out_ready` 开始持续24拍。

快速核对：
- `out_ready` 高电平窗口长度应为 24 拍。
- `sum_out` 在 `out_ready=1` 时为有效串行位。

### 阶段C：Case2（在 tb_mac16 中继续 mode=0）
说明：
- 当前 `tb_mac16` 第二段仍是 mode=0，用于再验证一次 mode=0 行为链路。

期望波形：
- 与阶段B同构，重复“收帧 -> 调度 -> 计算 -> 24拍输出”。

### 阶段D：Case3 mode 0->1 切换
期望波形：
- `mode` 翻转时，`mode_chg` 触发，`global_rst_n` 出现低脉冲。
- 内部状态被清空：`schedule_active/op_fifo_count/fifo_count` 回零。
- 切换后 `carry` 应回到0。
- 后续输入按 mode=1 累加语义运行。

快速核对：
- 切换后首个有效窗口中，`u_dut.u_mac.accum_reg` 从0开始重新累加。

### 阶段E：sticky carry 验证
期望波形：
- 当 mode=1 且某次加法溢出，`carry` 拉高。
- 后续即使未溢出，`carry` 仍保持1，直到复位或mode切换清空。

快速核对：
- `carry` 置1后不应自行回0。

## 3. 关键对照关系（信号到行为）

- `in_done` 上升沿：一帧16bit输入被成功拼帧。
- `op_push=1`：该帧写入输入FIFO。
- `op_pop=1`：该帧被调度器取走进入计算窗口。
- `calc_start=1`：`mac_core` 本拍开始处理当前操作数。
- `cal_done=1`：`mac_result` 本拍有效。
- `p2s_load=1`：并串模块装载24bit结果。
- `out_ready=1`：`sum_out` 当前位有效。
- `out_ready` 下降沿：一帧24bit输出结束。

## 3.1 结果调度判定流程（对应 p2s 逻辑）

本节对应 [rtl/mac16_top.v](../rtl/mac16_top.v) 中结果下发分支：
- `p2s_issue_hold`
- `cal_done`
- `p2s_in_ready`
- `fifo_count`

执行优先级（每个时钟拍）
1. 先判 `p2s_issue_hold`
2. 再判 `cal_done`
3. 最后在“无新结果”分支判是否可从结果FIFO补发

### 条件-动作表

| 优先级 | 条件 | 动作 | 结果含义 |
|---|---|---|---|
| 1 | `p2s_issue_hold==1` | `p2s_issue_hold<=0` | 本拍不发新 load，打一拍隔离 |
| 2 | `p2s_issue_hold==0 && cal_done==1 && p2s_in_ready==1 && fifo_count==0` | `mac_result_shadow<=mac_result`，`p2s_load<=1`，`p2s_issue_hold<=1` | 新结果旁路直发，最低延迟 |
| 3 | `p2s_issue_hold==0 && cal_done==1 && !(p2s_in_ready==1 && fifo_count==0) && fifo_count<4` | `result_fifo[fifo_wr_ptr]<=mac_result`，`fifo_wr_ptr++`，`fifo_count++` | 新结果入队等待发送 |
| 4 | `p2s_issue_hold==0 && cal_done==0 && p2s_in_ready==1 && fifo_count!=0` | `mac_result_shadow<=result_fifo[fifo_rd_ptr]`，`p2s_load<=1`，`p2s_issue_hold<=1`，`fifo_rd_ptr++`，`fifo_count--` | 无新结果时补发队列最旧结果 |
| 5 | 其余情况 | 无状态推进（除默认脉冲清零） | 等待下一拍 |

### 读波形时应看到的直接现象

1. 当 `p2s_load` 拉高后，下一拍常见 `p2s_issue_hold` 仍为1，然后被清0。
2. 当 `cal_done` 连续到达且 `p2s_in_ready` 不连续时，`fifo_count` 应先升后降。
3. 当 `fifo_count!=0` 且 `p2s_in_ready==1` 且当拍无 `cal_done`，会看到“队列补发”脉冲。

### 边界风险提示（审阅重点）

1. 当 `fifo_count==4` 且再次 `cal_done==1` 时，当前实现没有显式报错路径，存在结果丢弃风险。
2. 当前策略在有积压时不让新结果插队直发，优先保持FIFO顺序一致性。

## 4. 常见异常与定位思路

### 异常1：`out_ready` 没有在预期窗口拉高
优先检查：
- 是否有 `in_done`
- `op_fifo_count` 是否卡住
- `schedule_active/sched_cnt/calc_start` 是否按拍推进
- `cal_done` 是否产生

### 异常2：`out_ready` 窗口不是24拍
优先检查：
- `u_dut.u_out.bits_left` 的起始值是否为24
- `u_dut.u_out.busy` 是否在 `bits_left==1` 时释放

### 异常3：mode切换后行为异常
优先检查：
- `mode_chg` 是否产生
- `global_rst_n` 是否出现清空脉冲
- 切换后 `accum_reg/last_prod` 是否确实清零

## 5. 建议的审阅顺序（看波形时）

1. 先看外部：`rst_n/mode/inA/inB/out_ready/sum_out/carry`
2. 再看输入拼帧：`inA_done/inB_done/in_done`
3. 再看调度：`op_push/op_pop/schedule_active/sched_cnt/calc_start`
4. 再看输出发射：`cal_done/p2s_load/p2s_in_ready/busy/bits_left`
5. 最后看内部数值：`inA_par/inB_par/mac_result/accum_reg`

## 6. 与文字时序文档联动

建议搭配阅读：
- [docs/mac16_top_timing_walkthrough.md](mac16_top_timing_walkthrough.md)

该文档解释“为什么这样变”，本文解释“在波形上看到什么”。
