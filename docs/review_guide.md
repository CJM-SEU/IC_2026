# IC_2026 工程审阅导航

## 1. 一眼看全局

### 1.1 主线设计文件（优先看）
- 顶层赛题封装: [rtl/mac16.v](../rtl/mac16.v)
- 主实现顶层: [rtl/mac16_top.v](../rtl/mac16_top.v)
- MAC核心逻辑: [rtl/mac_core.v](../rtl/mac_core.v)
- 串并转换: [rtl/serial_to_parallel.v](../rtl/serial_to_parallel.v)
- 并串转换: [rtl/parallel_to_serial.v](../rtl/parallel_to_serial.v)

### 1.2 主线验证文件（优先看）
- 主功能门禁TB: [tb/tb_mac16.v](../tb/tb_mac16.v)
- 赛题三场景综合TB: [tb/tb_mac16_contest.v](../tb/tb_mac16_contest.v)
- 赛题Case1: [tb/tb_mac16_case_mode0.v](../tb/tb_mac16_case_mode0.v)
- 赛题Case2: [tb/tb_mac16_case_mode1.v](../tb/tb_mac16_case_mode1.v)
- 赛题Case3: [tb/tb_mac16_case_mode_switch.v](../tb/tb_mac16_case_mode_switch.v)
- 吞吐TB: [tb/tb_mac16_throughput.v](../tb/tb_mac16_throughput.v)

### 1.3 文档与约束（审阅时同步参考）
- 赛题文本: [3.22题目.md](../3.22题目.md)
- 提交验收对照: [docs/contest_acceptance_report.md](contest_acceptance_report.md)
- 验证门禁规范: [docs/verification_gate_spec.md](verification_gate_spec.md)
- SDC说明: [docs/sdc_usage.md](sdc_usage.md)
- 约束文件: [constraints/mac16_top.sdc](../constraints/mac16_top.sdc)

## 2. 推荐审阅顺序

### 2.1 快速审阅（20-30分钟）
1. 看赛题要求与当前验收结论
- [3.22题目.md](../3.22题目.md)
- [docs/contest_acceptance_report.md](contest_acceptance_report.md)

2. 看设计主链路
- [rtl/mac16.v](../rtl/mac16.v)
- [rtl/mac16_top.v](../rtl/mac16_top.v)
- [rtl/mac_core.v](../rtl/mac_core.v)

3. 看一个综合TB确认验证方式
- [tb/tb_mac16_contest.v](../tb/tb_mac16_contest.v)

### 2.2 深度审阅（1.5-2小时）
1. 输入输出时序细节
- [rtl/serial_to_parallel.v](../rtl/serial_to_parallel.v)
- [rtl/parallel_to_serial.v](../rtl/parallel_to_serial.v)

2. 模式切换与边界行为
- [rtl/mac16_top.v](../rtl/mac16_top.v)
- [tb/tb_mac16_case_mode_switch.v](../tb/tb_mac16_case_mode_switch.v)

3. 门禁与覆盖完整性
- [tb/tb_mac16.v](../tb/tb_mac16.v)
- [tb/tb_mac16_throughput.v](../tb/tb_mac16_throughput.v)
- [docs/verification_gate_spec.md](verification_gate_spec.md)

## 3. 目录分层解读

### 3.1 你当前最该关注
- [rtl](../rtl)
- [tb](../tb)
- [docs](.)
- [constraints](../constraints)

### 3.2 参考实现与历史资料
- [reference/gitcode](../reference/gitcode)
- [reference/bobei](../reference/bobei)
- [docs/change_logs](change_logs)

这些目录主要用于对照与追溯，不是当前提交主线。

### 3.3 可暂时忽略的仿真产物
- 顶层目录下 sim_*.vvp
- 顶层目录下 contest_case*.log
- 顶层目录下 dump.vcd
- [simulation](../simulation) 下工具缓存和数据库

## 4. 当前工程状态摘要

### 4.1 已有基础
- 已形成可运行RTL主链路与多份TB。
- 赛题场景已可输出 Simulation Passed。
- 已有验收对照文档可直接扩展为提交报告。

### 4.2 仍需重点核查
- 输入空隙语义是否与赛题评测口径一致。
- mode切换时输出窗口是否存在边界截断风险。
- 后端流程资料尚需补齐（综合、形式、APR、LVS、STA）。

## 5. 审阅时的实操建议

1. 每次只盯一条链路
- 输入链路: serial_to_parallel -> mac16_top入队
- 计算链路: mac_core
- 输出链路: mac16_top出队 -> parallel_to_serial

2. 先看断言和失败条件
- 从TB中查找 Simulation Failed 的触发条件，再回看RTL。

3. 先收敛主线，再看参考目录
- 先把 rtl + tb + docs 主线看透，再回看 reference 做差异比对。

## 6. 建议你保留的“审阅入口”

如果只想保留一个入口文档，建议从这里开始：
- [docs/review_guide.md](review_guide.md)
- [逐文件审阅检查表](review_checklist.md)
- [逐文件审阅检查表（预填示例）](review_checklist_filled_2026-04-16.md)
