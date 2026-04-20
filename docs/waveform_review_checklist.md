# IC_2026 统一波形检查清单（一页版）

用途：
- 面向全量门禁回归后的波形人工复核。
- 每次评审按表打勾，未通过项在备注中记录波形时间点与信号名。

使用说明：
1. 建议先跑完全量仿真，再按本表逐项复核关键波形。
2. 状态列使用：☐ 未检查，☑ 通过，☒ 不通过，N/A 不适用。
3. 备注建议填写：波形文件、时间戳、信号组合、结论。

| 序号 | 测试平台 | 关注模块 | 检查项（可打勾） | 状态 | 备注 |
|---|---|---|---|---|---|
| 1 | tb_mac16 | mac16_top | ☐ in_done 到 out_ready 启动延迟 <= 5clk | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 2 | tb_mac16 | mac16_top | ☐ out_ready 高电平窗口严格 24 拍 | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 3 | tb_mac16 | mac_core | ☐ calc_en / mult_valid / cal_done 脉冲对齐正确 | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 4 | tb_mac16 | mac_core | ☐ mode_d 与乘法器输出拍对齐，无错拍 | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 5 | tb_mac16 | mac_core | ☐ mode0 时 sum_out = 当前乘积低24位 + 上帧乘积低24位 | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 6 | tb_mac16 | mac_core | ☐ mode1 时 sum_out 与 accum_reg 累加轨迹一致 | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 7 | tb_mac16 | mac_core | ☐ carry 满足溢出置位且粘滞（非复位不清零） | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 8 | tb_mac16 | parallel_to_serial | ☐ 空闲输出为 0，发送窗口内为 MSB first | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 9 | tb_mac16_throughput | mac16_top | ☐ 连续输入下 op_fifo_count / fifo_count 无失控堆积 | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 10 | tb_mac16_throughput | mac16_top | ☐ p2s_load 与 out_done 配对节奏稳定，无重复下发 | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 11 | tb_mac16_throughput | parallel_to_serial | ☐ out_done 到下一帧 out_ready 间隔满足吞吐预期 | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 12 | tb_mac16_throughput | 全链路 | ☐ out_done_count 始终 <= in_done_count | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 13 | tb_serial_to_parallel | serial_to_parallel | ☐ 16bit 输入后同拍拉高 data_valid 与 in_done | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 14 | tb_serial_to_parallel | serial_to_parallel | ☐ data_out 位序正确（MSB first） | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 15 | tb_serial_to_parallel | serial_to_parallel | ☐ data_en 中断时计数与移位寄存器行为正确 | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 16 | tb_parallel_to_serial | parallel_to_serial | ☐ load_en 后进入发送窗口，out_ready 连续 24 拍 | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 17 | tb_parallel_to_serial | parallel_to_serial | ☐ serial_out 位序正确，窗口外恒为 0 | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 18 | tb_parallel_to_serial | parallel_to_serial | ☐ out_done 仅在合法发送末尾出现 | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 19 | tb_csa32 | csa32 | ☐ 位级关系 s = x ^ y ^ z | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 20 | tb_csa32 | csa32 | ☐ c 为多数函数左移一位结果 | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 21 | tb_csa32 | csa32 | ☐ s + c 低32位 等价 x + y + z 低32位 | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 22 | tb_mac16_case_mode0 | mac_core | ☐ mode0 下 last_prod 逐帧更新且参与下一帧计算 | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 23 | tb_mac16_case_mode0 | mac16_top | ☐ 每组输入后均触发一帧完整24bit输出 | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 24 | tb_mac16_case_mode0 | mac_core | ☐ carry 仅在低24位溢出时置位 | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 25 | tb_mac16_case_mode1 | mac_core | ☐ accum_reg 逐帧累加 mult_result[23:0] 并与 sum_out 同步 | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 26 | tb_mac16_case_mode1 | mac_core | ☐ mode1 路径无 last_prod 串扰 | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 27 | tb_mac16_case_mode1 | mac_core | ☐ 溢出后 carry sticky 保持到复位/清空 | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 28 | tb_mac16_case_mode_switch | mac16_top | ☐ mode 翻转触发全链路清空生效 | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 29 | tb_mac16_case_mode_switch | mac_core | ☐ 切换后 mode_d 对齐正确，无旧模式错拍 | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 30 | tb_mac16_case_mode_switch | mac_core | ☐ 切换后 carry 先清零再按新模式置位 | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 31 | tb_mac16_case_mode_switch | 输出链路 | ☐ 边界截断帧被识别为无效帧，不参与有效帧比较 | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 32 | tb_mac16_contest | 全链路 | ☐ Case1/Case2/Case3 切换边界行为连续且可解释 | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 33 | tb_mac16_contest | mac16_top | ☐ 长流程 calc_start / p2s_load 无丢脉冲或重复脉冲 | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 34 | tb_mac16_contest | mac_core | ☐ 长流程 cal_done 与有效乘法一一对应 | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |
| 35 | tb_mac16_contest | 输出端 | ☐ sum_out 串行帧与 expected_q 对齐，仅完整24bit帧计入 | ☑ | 见 docs/acceptance_logs/2026-04-20/run-waveform-check/ 对应日志 |

结论区：
- 总体结论：☑ 通过  ☐ 不通过
- 关键风险项：
  1. 本次结论基于 testbench 断言与日志通过；若需签收“逐信号可视化复核”，建议按关键条目抽样打开 dump.vcd 二次确认。
  2. 长流程与边界切换已通过 `tb_mac16_contest`，后续改动应保持该项必跑。
  3. 若后续引入时序优化，建议优先复核 `calc_en/mult_valid/cal_done` 与 `out_ready` 窗口一致性。
- 复核人：Copilot（自动回归填表）
- 日期：2026-04-20

本次回归证据：
- 命令清单：`docs/acceptance_logs/2026-04-20/run-waveform-check/commands.txt`
- 汇总结果：`docs/acceptance_logs/2026-04-20/run-waveform-check/summary.txt`
- 单项日志：`docs/acceptance_logs/2026-04-20/run-waveform-check/*.log`
