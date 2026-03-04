# IC_2026
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
