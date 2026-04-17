# IC_2026 逐文件审阅检查表（预填示例）

说明：本文件为 2026-04-16 基于当前工作区状态的预填版本，可在评审会直接使用并继续修订。

## 0. 审阅信息

- [x] 审阅日期已记录：2026-04-16
- [x] 审阅人已记录：Copilot 预填（待团队签字确认）
- [x] 审阅目标已记录（功能一致性/时序风险/提交完备性）：功能一致性 + 赛题对齐差异盘点

## 1. 赛题需求对齐

- [x] 已通读赛题文本：[3.22题目.md](../3.22题目.md)
- [x] 已核对当前验收说明：[docs/contest_acceptance_report.md](contest_acceptance_report.md)
- [x] 已确认本轮关注范围（仅RTL前仿 / 含后端流程）：RTL前仿为主，后端流程做完备性检查

审阅结论记录：
- RTL前仿路径可运行并可产出 Simulation Passed。
- 全流程后端项（综合/形式/APR/LVS/STA）仍未形成提交级证据闭环。

## 2. 顶层与接口

- [x] 赛题封装接口与题面一致：[rtl/mac16.v](../rtl/mac16.v)
- [x] 主实现顶层端口和内部连线清晰：[rtl/mac16_top.v](../rtl/mac16_top.v)
- [x] mode切换清空策略可解释且可验证：[rtl/mac16_top.v](../rtl/mac16_top.v)
- [ ] 输入空隙策略可解释（连续流或显式间隔语义）：[rtl/mac16.v](../rtl/mac16.v)

审阅结论记录：
- 当前顶层采用连续采样模型，缺少对外显式输入有效信号；“组间可有间隔”的赛题语义尚未严格落地。

## 3. 输入链路（串并）

- [x] bit顺序为MSB first：[rtl/serial_to_parallel.v](../rtl/serial_to_parallel.v)
- [x] 16bit拼帧计数无歧义：[rtl/serial_to_parallel.v](../rtl/serial_to_parallel.v)
- [x] in_done/data_valid时序行为明确：[rtl/serial_to_parallel.v](../rtl/serial_to_parallel.v)
- [ ] 组间间隔处理策略满足赛题口径：[rtl/serial_to_parallel.v](../rtl/serial_to_parallel.v)

审阅结论记录：
- 当前实现依赖 data_en 控制间隔；赛题对外接口无 data_en，仍存在协议口径风险。

## 4. 计算链路（MAC核心）

- [x] mode=0语义正确（当前乘积 + 上一状态乘积）：[rtl/mac_core.v](../rtl/mac_core.v)
- [x] mode=1语义正确（全状态累加）：[rtl/mac_core.v](../rtl/mac_core.v)
- [x] carry置位与清零策略符合题面：[rtl/mac_core.v](../rtl/mac_core.v) [rtl/mac16_top.v](../rtl/mac16_top.v)
- [ ] 有符号/无符号口径与赛题保持一致：[rtl/mac_core.v](../rtl/mac_core.v)

审阅结论记录：
- 当前使用有符号乘法；赛题未明确符号口径，建议与评测方确认或补双口径测试。

## 5. 输出链路（并串）

- [x] out_ready窗口与24bit输出一致：[rtl/parallel_to_serial.v](../rtl/parallel_to_serial.v)
- [x] 空闲期sum_out回0符合题面：[rtl/parallel_to_serial.v](../rtl/parallel_to_serial.v)
- [ ] 输出与输入节奏冲突时有明确行为定义：[rtl/mac16_top.v](../rtl/mac16_top.v)

审阅结论记录：
- 高吞吐/模式切换边界下存在截断窗口处置问题，行为定义与验收口径需进一步收紧。

## 6. 队列与流控边界

- [ ] 输入队列满时行为可观测（不应静默丢帧）：[rtl/mac16_top.v](../rtl/mac16_top.v)
- [ ] 结果队列满时行为可观测（不应静默丢帧）：[rtl/mac16_top.v](../rtl/mac16_top.v)
- [x] 吞吐压力下无异常截断或计数错配：[tb/tb_mac16_throughput.v](../tb/tb_mac16_throughput.v)

审阅结论记录：
- 当前队列满时缺少显式报错/握手反馈，存在静默丢帧风险。

## 7. Testbench覆盖与严谨性

- [x] 主门禁TB通过且断言有效：[tb/tb_mac16.v](../tb/tb_mac16.v)
- [x] 赛题综合TB通过：[tb/tb_mac16_contest.v](../tb/tb_mac16_contest.v)
- [x] Case1/Case2/Case3分场景TB均通过：[tb/tb_mac16_case_mode0.v](../tb/tb_mac16_case_mode0.v) [tb/tb_mac16_case_mode1.v](../tb/tb_mac16_case_mode1.v) [tb/tb_mac16_case_mode_switch.v](../tb/tb_mac16_case_mode_switch.v)
- [ ] Case3未采用“忽略截断帧”放宽口径（若有，需注明理由）：[tb/tb_mac16_case_mode_switch.v](../tb/tb_mac16_case_mode_switch.v)

审阅结论记录：
- Case3目前存在放宽判定（忽略非24bit截断帧），建议改为严格口径后复验。

## 8. 文档与约束一致性

- [x] 验证门禁文档与TB行为一致：[docs/verification_gate_spec.md](verification_gate_spec.md)
- [x] SDC说明与实际顶层一致：[docs/sdc_usage.md](sdc_usage.md) [constraints/mac16_top.sdc](../constraints/mac16_top.sdc)
- [x] 提交验收说明已更新到最新实现：[docs/contest_acceptance_report.md](contest_acceptance_report.md)

审阅结论记录：
- 文档层面的导航与验收映射已形成，适合作为当前阶段评审资料。

## 9. 后端流程完备性（提交前）

- [ ] 综合报告齐全（含功耗）：未发现报告产物
- [ ] 形式验证报告齐全：未发现报告产物
- [ ] APR与PVT timing报告齐全：未发现报告产物
- [ ] LVS与SPEF产物齐全：未发现报告产物
- [ ] STA三角报告齐全：未发现报告产物
- [ ] 面积与金属层约束达标证据齐全：未发现报告产物

审阅结论记录：
- 当前工作区检索未发现后端常见产物文件，后端评分项暂不可判定为通过。

## 10. 本轮问题清单

- [x] P0问题已登记：输入空隙语义未严格闭环；Case3口径存在放宽。
- [x] P1问题已登记：队列满行为不可观测；符号口径待确认。
- [x] P2问题已登记：文档可进一步补充提交截图索引。
- [ ] 每个问题有责任人和截止时间：待项目负责人填写。

## 11. 审阅结论

- [ ] 可进入下一阶段（是/否）：有条件进入（限RTL前仿继续）
- [x] 阻断项已明确：若目标是“严格贴合赛题提交口径”，需先闭环P0项。
- [ ] 下一次复审时间已安排：待定。

---

## 附：本次复核命令与结果摘要

- 主门禁TB复核通过：tb_mac16 PASS
- 赛题综合TB复核通过：Simulation Passed
- 后端产物检索：未检索到 .rpt/.spef/.def/.gds 等常见文件
