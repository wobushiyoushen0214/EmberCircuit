# 019-01 调试报告

## Session 1

### 失败信号

- 复现命令：`HOME=/tmp/ember019-godot-home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_simulator.gd`
- 原文：`Parse Error: Identifier "pre_hp_total" not declared in the current scope`，同类错误覆盖六个 transition total 变量，位置 `BalanceSimulator.gd:2265-2270`。
- 是否稳定复现：是。

### 定位过程

| 方法 | 结果 |
| --- | --- |
| 读栈 | `BalanceSimulator.gd:2244-2259` 的 totals 被误缩进到 `for run_value` 内，而 `result.append` 在外层读取它们 |

### 假设记录

| 轮次 | 假设 | 验证方式 | 结论 |
| --- | --- | --- | --- |
| 1 | 六个 total 变量的声明作用域比使用点窄一层 | `nl -ba` 核对缩进与 parser 行号 | 成立 |

### 修复

- 根因：transition totals 与 rows 聚合循环缩进错误。
- 改动位置：`scripts/tools/BalanceSimulator.gd` 的 `_aggregate_campaign_transition_attribution()`。
- 重跑结果：绿；`Balance simulator smoke test passed.`

### 防御性回归

- 该 bug 是当前函数局部 parser 错误，editor import 和 balance simulator test 均会防御；已局部封闭。

### 退出状态

- [x] 绿了，回到 TDD 循环。
