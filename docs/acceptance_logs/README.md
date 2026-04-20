# 验收日志归档说明

本目录用于保存每次全量门禁回归的原始证据，配合上层总览文档使用：
- 上层总览：`docs/contest_acceptance_report.md`
- 本目录：按日期与批次归档命令和日志

## 目录规范
推荐结构：

- `docs/acceptance_logs/YYYY-MM-DD/run-01/`
- `docs/acceptance_logs/YYYY-MM-DD/run-02/`

## 每次回归最小归档内容
1. `commands.txt`
- 记录完整执行命令，便于复现。

2. `tb_*.log`
- 每个 testbench 一份原始日志，例如：
  - `tb_mac16.log`
  - `tb_mac16_throughput.log`
  - `tb_mac16_contest.log`
  - `tb_csa32.log`

3. `summary.md`
- 记录本次结论：通过/失败、失败点、后续处理。

## 建议约束
- 不覆盖历史 run 目录。
- 日志保留原始输出，不做二次改写。
- 若失败，summary.md 需注明触发的 TB 与关键报错行。
