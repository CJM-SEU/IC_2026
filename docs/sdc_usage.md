# SDC usage for IC_2026

This project provides a baseline synthesis constraint file:
- constraints/mac16_top.sdc

## Scope
The SDC targets top module mac16_top and applies:
- 1GHz core clock on port clk
- Input/output delay budget for top-level IO
- Basic output load
- Async reset false path on rst_n

## Parameters to tune first
Open constraints/mac16_top.sdc and adjust these variables for your flow:
- CLK_PERIOD_NS
- CLK_UNCERTAINTY_NS
- IN_MAX_DELAY_NS / IN_MIN_DELAY_NS
- OUT_MAX_DELAY_NS / OUT_MIN_DELAY_NS
- OUT_LOAD_PF

## Recommended integration
Use the SDC in your synthesis script after reading RTL and before compile/optimize.

Typical flow (tool-agnostic):
1. read_verilog rtl/*.v
2. current_design mac16_top
3. read_sdc constraints/mac16_top.sdc
4. compile/optimize
5. report_timing / report_qor

## Notes
- If your environment has strict external interface timing, replace the generic IO budgets with board/system timing values.
- If later you intentionally add multi-cycle behavior between sequential endpoints, add set_multicycle_path only with clear design proof.
- Keep reset handling asynchronous in RTL, but do not time reset as a data path.
