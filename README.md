# IC_2026

语言标准说明：
- 本工程源码按 Verilog 语法编写，不使用 SystemVerilog 关键字与语法扩展。
- 工程验收编译口径采用 `iverilog -g2001`。
- 由于 Icarus Verilog 不提供独立 `-g2000` 开关（仅支持 `-g1995/-g2001/...`），
	本工程将 `-g2001` 作为 Verilog-2000 工程化验收口径。

审阅入口：
- [工程审阅导航](docs/review_guide.md)
- [赛题要求文本](3.22题目.md)
- [赛题提交验收说明](docs/contest_acceptance_report.md)

serial_to_parallel模块：

clk---------->|---------|
rst_n-------->|         |-->data_out(parallel)
data_in------>|         |-->data_valid
data_valid--->|---------|

parallel_to_serial模块：

clk-------->|---------|
rst_n------>|         |-->data_out(serial)
data_in---->|         |-->data_valid
data_valid->|---------|
