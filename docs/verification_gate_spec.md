# IC_2026 验证门禁规范（固定版）

## 1. 目的与适用范围
- 目的：为后续版本提供统一、可执行、可判定的 RTL 验证门禁标准。
- 适用范围：
  - rtl 下 MAC 主链路相关模块
  - tb 下四个核心测试平台
- 门禁触发建议：
  - 每次提交涉及 rtl 或 tb 变更
  - 合并到主分支前
  - 版本打标前

## 2. 门禁测试清单（必须全通过）
1. tb_mac16
- 文件：tb/tb_mac16.v
- 覆盖：主功能、模式切换、时序窗口、结果比对、sticky carry。

2. tb_mac16_throughput
- 文件：tb/tb_mac16_throughput.v
- 覆盖：连续流吞吐、装载到完成有界时延、计数一致性。

3. tb_serial_to_parallel
- 文件：tb/tb_serial_to_parallel.v
- 覆盖：16bit 串并转换、in_done/data_valid 协同、数据正确性。

4. tb_parallel_to_serial
- 文件：tb/tb_parallel_to_serial.v
- 覆盖：24bit 并串发送窗口、空闲输出约束、逐帧比对。

## 3. 断言列表

### 3.1 tb_mac16 断言
1. 输入完成到输出开始延迟
- 规则：in_done 后，out_ready 必须在 5 拍内拉高。
- 失败信息：ERROR: output start latency > 5 cycles

2. 输出窗口长度
- 规则：每帧 out_ready 高电平窗口必须严格等于 24 拍。
- 失败信息：ERROR: out_ready window != 24 cycles

3. 帧数据一致性
- 规则：串行拼接得到的 24bit 结果必须与 scoreboard 期望值一致。
- 失败信息：ERROR: frameN data mismatch

4. mode 切换清空 carry
- 规则：mode 变化后，carry 必须被清零。
- 失败信息：ERROR: carry must clear right after mode switch

5. sticky carry 语义
- 规则：Mode1 下发生溢出后，carry 必须保持为 1，后续非溢出帧不允许清零。
- 失败信息：
  - ERROR: sticky carry must be 1 after overflow sequence
  - ERROR: sticky carry must remain 1 after non-overflow frame

6. 期望帧消费完整性
- 规则：仿真结束前，q_rd 必须等于 q_wr。
- 失败信息：ERROR: Not all expected frames consumed

### 3.2 tb_mac16_throughput 断言
1. 计数上界一致性
- 规则：out_done_count 不得大于 in_done_count。
- 失败信息：ERROR: out_done_count cannot exceed accepted input frames

2. 装载-完成配对一致性
- 规则：出现 out_done 时必须存在 pending load。
- 失败信息：ERROR: out_done happened without pending load

3. 装载到完成有界时延
- 规则：存在 pending load 时，若连续等待超过 MAX_LOAD_TO_DONE_CYCLES（当前 30）仍无 out_done，则失败。
- 失败信息：ERROR: load-to-done latency exceeded bound

4. 连续流吞吐目标
- 规则：sent_frames=4 场景下，out_done_count 必须等于 sent_frames。
- 通过标志：THROUGHPUT_STATUS full-throughput-under-continuous-stream

### 3.3 tb_serial_to_parallel 断言
1. data_valid 与 in_done 一致性
- 规则：data_valid 拉高时，in_done 必须同时为高。
- 失败信息：ERROR: data_valid asserted without in_done

2. 并行数据正确性
- 规则：data_out 必须与期望序列逐项一致。
- 失败信息：ERROR: sampleN mismatch

3. 样本消费完整性
- 规则：仿真结束前，q_rd 必须等于 q_wr。
- 失败信息：ERROR: Not all expected samples observed

### 3.4 tb_parallel_to_serial 断言
1. 空闲输出约束
- 规则：out_ready=0 时，serial_out 必须为 0。
- 失败信息：ERROR: serial_out must be 0 when out_ready=0

2. out_done 时序合法性
- 规则：out_done 仅允许在 out_ready=1 的发送窗口内出现。
- 失败信息：ERROR: out_done asserted while out_ready=0

3. 发送窗口长度
- 规则：每帧 out_ready 高电平窗口必须为 24 拍。
- 失败信息：ERROR: out_ready window mismatch

4. 帧数据一致性
- 规则：接收拼接数据必须与期望帧一致。
- 失败信息：ERROR: frameN mismatch

5. 帧消费完整性
- 规则：仿真结束前，q_rd 必须等于 q_wr。
- 失败信息：ERROR: Not all expected frames observed

## 4. 执行命令（建议固定脚本化）
在工程根目录执行：

```bash
iverilog -g2012 -o sim_tb_mac16.vvp -s tb_mac16 rtl/*.v tb/tb_mac16.v && vvp sim_tb_mac16.vvp
iverilog -g2012 -o sim_tb_mac16_throughput.vvp -s tb_mac16_throughput rtl/*.v tb/tb_mac16_throughput.v && vvp sim_tb_mac16_throughput.vvp
iverilog -g2012 -o sim_tb_serial_to_parallel.vvp -s tb_serial_to_parallel rtl/*.v tb/tb_serial_to_parallel.v && vvp sim_tb_serial_to_parallel.vvp
iverilog -g2012 -o sim_tb_parallel_to_serial.vvp -s tb_parallel_to_serial rtl/*.v tb/tb_parallel_to_serial.v && vvp sim_tb_parallel_to_serial.vvp
```

## 5. 门禁通过准则
必须同时满足：
1. 四个 testbench 均返回退出码 0。
2. 日志中不出现 ERROR: 或 Fatal 类终止信息。
3. tb_mac16 输出包含：=== tb_mac16 PASS ===。
4. tb_serial_to_parallel 输出包含：=== tb_serial_to_parallel PASS ===。
5. tb_parallel_to_serial 输出包含：=== tb_parallel_to_serial PASS ===。
6. tb_mac16_throughput 输出包含：THROUGHPUT_STATUS full-throughput-under-continuous-stream。

任一条件不满足即判定门禁失败。

## 6. 失败分级与处理建议
- P0（阻断发布）
  - 功能结果错误
  - 延迟超过 5 拍
  - 吞吐目标不达标
  - 断言触发导致仿真中止

- P1（需修复后合并）
  - 计数一致性异常
  - 握手边界异常（如无 load 却 out_done）

- P2（可跟踪优化）
  - 非功能性信息告警，不影响断言通过

## 7. 维护规则
1. 新增或修改断言时，必须同步更新本规范文档与对应 testbench。
2. 变更说明写入 docs/change_logs，规范主文档只维护“稳定门禁条款”，不记录过程性细节。
3. 若未来引入 CI，要求将第 4 节命令固化为流水线步骤，并严格使用第 5 节作为唯一判定口径。
