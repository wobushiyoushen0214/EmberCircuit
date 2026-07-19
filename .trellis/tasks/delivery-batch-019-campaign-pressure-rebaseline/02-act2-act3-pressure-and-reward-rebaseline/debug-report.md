# 调试报告

## Session 1

### 失败信号

- 复现命令：`HOME=/tmp/ember019-godot-home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_tree_auditor.gd`
- 原文（堆栈/断言/退出码）：

```text
Numerical tree auditor test failed with 1 issue(s).
 - legacy monster budget warning count remains unchanged
exit_code=1
```

- 是否稳定复现：是。R2-A 配置下重复运行均为 `monster_warning_count=1`。

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读栈 | 断言定位到 `tests/test_numerical_tree_auditor.gd:69`，期望 legacy monster warning count 为 0。 |
| 加一行日志 | `/tmp/ember019-r2a-static.json` 显示唯一硬问题为 `null_workshop.issues=["encounter_hp_low"]`，有效生命 86，目标下限 88。 |

### 假设记录

| 轮次 | 假设（具体到变量/分支/契约） | 验证方式 | 结论(成立/证伪) |
| --- | --- | --- | --- |
| 1 | R2-A 的 `volt_cultist.max_hp=44` 与 `null_mender.max_hp=42` 使 `null_workshop` 总生命低于 `numerical_tree.monsters.chapter_two.normal.encounter_hp[0]`。 | 查询 `encounters.json` 的 `null_workshop.enemy_ids`，运行静态审计并读取该 encounter 行。 | 成立：`42+44=86 < 88`。 |

已排除项：

- 不是测试陈旧：基线 warning count 为 0，新增 warning 来自候选确切值。
- 不是压力指标误报：`test_numerical_pressure_metrics.gd`、`test_act1_rebaseline.gd` 和 BalanceSimulator smoke 均通过。
- 不能通过修改目标预算、遭遇或行动修复：均在 019-02 禁止事项之外。

### 修复

- 根因：R2-A 冻结 HP 阶梯与既有二章双敌 encounter HP 下限不相容。
- 改动位置（一处）：无应用代码修复；候选按 PRD 回滚门拒绝。
- 重跑原失败命令结果：仍红（用于确认候选不可选，未叠加错误改动）。

### 防御性回归

- 这个 bug 能否从别处再发生：能。任何未来二章双敌 HP 调整都可能低于 encounter budget；现有 `test_numerical_tree_auditor.gd` 已覆盖该入口，已局部封闭。

### 退出状态

- [x] 已定位并按候选回滚门停止；R2-A 与继承其二章 HP 的 R2-B 不再运行。
