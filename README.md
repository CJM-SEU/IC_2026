# IC_2026

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
