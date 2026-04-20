# IC_2026 逐文件审阅检查表

使用方式：每完成一项就勾选，右侧写结论或问题编号。

## 0. 审阅信息

- [ ] 审阅日期已记录：
- [ ] 审阅人已记录：
- [ ] 审阅目标已记录（功能一致性/时序风险/提交完备性）：

## 1. 赛题需求对齐

- [ ] 已通读赛题文本：[3.22题目.md](../3.22题目.md)
- [ ] 已核对当前验收说明：[docs/contest_acceptance_report.md](contest_acceptance_report.md)
- [ ] 已确认本轮关注范围（仅RTL前仿 / 含后端流程）

审阅结论记录：

## 2. 顶层与接口

- [ ] 赛题封装接口与题面一致：[rtl/mac16.v](../rtl/mac16.v)
- [ ] 主实现顶层端口和内部连线清晰：[rtl/mac16_top.v](../rtl/mac16_top.v)
- [ ] mode切换清空策略可解释且可验证：[rtl/mac16_top.v](../rtl/mac16_top.v)
- [ ] 输入空隙策略可解释（连续流或显式间隔语义）：[rtl/mac16.v](../rtl/mac16.v)

审阅结论记录：

## 3. 输入链路（串并）

- [ ] bit顺序为MSB first：[rtl/serial_to_parallel.v](../rtl/serial_to_parallel.v)
- [ ] 16bit拼帧计数无歧义：[rtl/serial_to_parallel.v](../rtl/serial_to_parallel.v)
- [ ] in_done/data_valid时序行为明确：[rtl/serial_to_parallel.v](../rtl/serial_to_parallel.v)
- [ ] 组间间隔处理策略满足赛题口径：[rtl/serial_to_parallel.v](../rtl/serial_to_parallel.v)

审阅结论记录：

## 4. 计算链路（MAC核心）

- [ ] mode=0语义正确（当前乘积 + 上一状态乘积）：[rtl/mac_core.v](../rtl/mac_core.v)
- [ ] mode=1语义正确（全状态累加）：[rtl/mac_core.v](../rtl/mac_core.v)
- [ ] carry置位与清零策略符合题面：[rtl/mac_core.v](../rtl/mac_core.v)
- [ ] 有符号/无符号口径与赛题保持一致：[rtl/mac_core.v](../rtl/mac_core.v)

审阅结论记录：

## 5. 输出链路（并串）

- [ ] out_ready窗口与24bit输出一致：[rtl/parallel_to_serial.v](../rtl/parallel_to_serial.v)
- [ ] 空闲期sum_out回0符合题面：[rtl/parallel_to_serial.v](../rtl/parallel_to_serial.v)
- [ ] 输出与输入节奏冲突时有明确行为定义：[rtl/mac16_top.v](../rtl/mac16_top.v)

审阅结论记录：

## 6. 队列与流控边界

- [ ] 输入队列满时行为可观测（不应静默丢帧）：[rtl/mac16_top.v](../rtl/mac16_top.v)
- [ ] 结果队列满时行为可观测（不应静默丢帧）：[rtl/mac16_top.v](../rtl/mac16_top.v)
- [ ] 吞吐压力下无异常截断或计数错配：[tb/tb_mac16_throughput.v](../tb/tb_mac16_throughput.v)

审阅结论记录：

## 7. Testbench覆盖与严谨性

- [ ] 主门禁TB通过且断言有效：[tb/tb_mac16.v](../tb/tb_mac16.v)
- [ ] 赛题综合TB通过：[tb/tb_mac16_contest.v](../tb/tb_mac16_contest.v)
- [ ] Case1/Case2/Case3分场景TB均通过：[tb/tb_mac16_case_mode0.v](../tb/tb_mac16_case_mode0.v) [tb/tb_mac16_case_mode1.v](../tb/tb_mac16_case_mode1.v) [tb/tb_mac16_case_mode_switch.v](../tb/tb_mac16_case_mode_switch.v)
- [ ] Case3未采用“忽略截断帧”放宽口径（若有，需注明理由）：[tb/tb_mac16_case_mode_switch.v](../tb/tb_mac16_case_mode_switch.v)

审阅结论记录：

## 8. 文档与约束一致性

- [ ] 验证门禁文档与TB行为一致：[docs/verification_gate_spec.md](verification_gate_spec.md)
- [ ] SDC说明与实际顶层一致：[docs/sdc_usage.md](sdc_usage.md) [constraints/mac16.sdc](../constraints/mac16.sdc)
- [ ] 提交验收说明已更新到最新实现：[docs/contest_acceptance_report.md](contest_acceptance_report.md)

审阅结论记录：

## 9. 后端流程完备性（提交前）

- [ ] 综合报告齐全（含功耗）：
- [ ] 形式验证报告齐全：
- [ ] APR与PVT timing报告齐全：
- [ ] LVS与SPEF产物齐全：
- [ ] STA三角报告齐全：
- [ ] 面积与金属层约束达标证据齐全：

审阅结论记录：

## 10. 本轮问题清单

- [ ] P0问题已登记：
- [ ] P1问题已登记：
- [ ] P2问题已登记：
- [ ] 每个问题有责任人和截止时间：

## 11. 审阅结论

- [ ] 可进入下一阶段（是/否）：
- [ ] 阻断项已明确：
- [ ] 下一次复审时间已安排：
