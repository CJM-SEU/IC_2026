# MAC16 赛题提交验收说明（提交版草案）

## 1. 文档目的
本文件用于对照“华大九天企业命题：MAC16芯片设计”评分条款，汇总当前工程完成情况、可追溯证据与待补事项，作为提交材料总览。

## 2. 工程对象与关键文件
- 赛题接口顶层：rtl/mac16.v
- 主实现顶层：rtl/mac16_top.v
- 计算核心：rtl/mac_core.v
- 串并转换：rtl/serial_to_parallel.v
- 并串输出：rtl/parallel_to_serial.v
- 赛题综合验收TB：tb/tb_mac16_contest.v
- 赛题分场景TB（推荐提交）：
  - tb/tb_mac16_case_mode0.v
  - tb/tb_mac16_case_mode1.v
  - tb/tb_mac16_case_mode_switch.v

## 3. 赛题功能要求对照

### 3.1 IO与时序行为
- 串行输入 inA/inB（16bit，MSB first）：已实现。
- 串行输出 sum_out（24bit，MSB first）：已实现。
- out_ready 输出有效窗口：已实现并在TB中校验。
- carry 溢出置位、复位清除：已实现并在TB中校验。
- mode切换清空内部状态：已实现并在TB中校验。
- 输入完成到开始输出不超过5拍：已在综合验收TB中校验。

### 3.2 三种必测组合
- Case A：mode=0，6组数据：已实现并通过。
- Case B：mode=1，6组数据：已实现并通过。
- Case C：mode 0->1（在14&71输入完成后切换）：已实现并通过。

### 3.3 仿真自检判定
- 判定机制：任一不匹配打印 Simulation Failed，全通过打印 Simulation Passed。
- 状态：已实现于赛题验收TB与分场景TB。

## 4. 本地仿真验收记录（已执行）

### 4.1 分场景TB（推荐作为提交截图来源）
```bash
iverilog -g2012 -o sim_tb_case0.vvp -s tb_mac16_case_mode0 rtl/*.v tb/tb_mac16_case_mode0.v && vvp sim_tb_case0.vvp
iverilog -g2012 -o sim_tb_case1.vvp -s tb_mac16_case_mode1 rtl/*.v tb/tb_mac16_case_mode1.v && vvp sim_tb_case1.vvp
iverilog -g2012 -o sim_tb_case_sw.vvp -s tb_mac16_case_mode_switch rtl/*.v tb/tb_mac16_case_mode_switch.v && vvp sim_tb_case_sw.vvp
```
执行结果：三项均输出 Simulation Passed。

### 4.2 综合验收TB（单TB覆盖三场景）
```bash
iverilog -g2012 -o sim_tb_mac16_contest.vvp -s tb_mac16_contest rtl/*.v tb/tb_mac16_contest.v && vvp sim_tb_mac16_contest.vvp
```
执行结果：输出 Simulation Passed。

## 5. 评分条款完成度总表（截至当前）

1. RTL编写+前仿+综合+形式+APR+物理验证+STA全流程数据
- 当前状态：部分完成。
- 已完成：RTL与前仿。
- 待补：综合、形式验证、布局布线、LVS、SPEF、STA完整产物与日志。

2. 1GHz下串行输入输出，testbench逻辑正确且日志通过
- 当前状态：已完成（前仿维度）。
- 证据：tb/tb_mac16_case_mode0.v、tb/tb_mac16_case_mode1.v、tb/tb_mac16_case_mode_switch.v、tb/tb_mac16_contest.v。

3. 逻辑综合结果正确，Total Power <= 300uW
- 当前状态：待完成。
- 需要产物：综合报告（含功耗）。

4. 形式验证（综合前后一致）
- 当前状态：待完成。
- 需要产物：LEC/Formality等比对报告。

5. 布局布线正确，3个PVT在1GHz setup/hold通过
- 当前状态：待完成。
- 需要产物：APR报告与三角timing summary。

6. LVS通过，且拿到3个PVT SPEF
- 当前状态：待完成。
- 需要产物：LVS报告与SPEF文件。

7. STA中3个PVT在1GHz setup/hold通过
- 当前状态：待完成。
- 需要产物：PrimeTime/Tempus等STA报告。

8. 面积 <= 90um x 90um，金属层M1~M5
- 当前状态：待完成。
- 需要产物：版图面积与层使用报告。

9. Word版设计报告
- 当前状态：待完成。
- 建议：以本文件为章节骨架转写到Word。

10. 加分项（100uW与1.5GHz）
- 当前状态：待评估（依赖综合/STA结果）。

## 6. 提交材料打包建议
- RTL源文件：rtl目录完整打包。
- Testbench：tb目录完整打包，重点附上三份分场景TB。
- 仿真日志：每个TB保存独立log。
- 波形：关键场景dump.vcd截图（输入结束到输出开始、mode切换、carry置位）。
- 约束：constraints/mac16_top.sdc。
- 报告：按第5节条款逐条附证据。

## 7. 已知实现边界说明（建议写入答辩备注）
- 题面未显式给出输入valid引脚，当前对外赛题顶层采用连续位流输入模型。
- 在mode切换瞬间，输出链路可能出现截断窗口，验收TB已按“仅完整24bit帧计分”的方式处理。
- 若后续赛事方提供更严格输入空隙协议，可在顶层增加显式输入有效控制并同步更新TB。

## 8. 后续优先级建议
1. 先完成综合并拿到功耗（优先验证300uW门槛）。
2. 再推进形式验证，锁定前后网表一致性。
3. 完成APR与物理验证后，统一做3个PVT STA收敛。
4. 最后收口Word报告与提交清单。