# 调试报告

## Session 1

### 失败信号

- 复现命令：独立 Stage 2 评审；既有定向测试仍为退出 0。
- 原文（评审发现）：

```text
critical: 未知顶层/change 字段被 BalanceCandidateOverlay 静默忽略。
critical: attrition 将 completed=false 且正 HP 的 timeout 计为 death。
major: _is_integer_number 使用 is_equal_approx 接受接近整数的小数。
```

- 是否稳定复现：是（由代码路径和边界输入确定）。

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读栈 / 读评审行号 | `BalanceCandidateOverlay.gd:67-103` 未检查未知字段；`BalanceSimulator.gd:379-392,3721-3741` 用 completed 直接计 death；`BalanceCandidateOverlay.gd:201-206` 近似整数判断 |

### 假设记录

| 轮次 | 假设（具体到变量/分支/契约） | 验证方式 | 结论(成立/证伪) |
| --- | --- | --- | --- |
| 1 | 三处边界缺陷来自实现缺少对应 fail-closed 分支，现有测试没有覆盖它们。 | Stage 2 指定行号并构造对应边界输入 | 成立 |

已排除项：

- 默认报告污染不是根因；默认 `cmp` 已通过。

### 修复

- 根因：边界契约没有进入测试和实现分支。
- 改动位置（一处）：分别在 `BalanceCandidateOverlay._validate_payload/_is_integer_number` 与 `BalanceSimulator._aggregate_campaign_attrition` 做单项最小修复。
- 重跑原失败命令结果：三项均绿；随后 overlay/simulator/map/matrix/editor/cmp/hash/diff 全绿。

### 防御性回归

- 这个 bug 能否从别处再发生：能；已补充 overlay schema、整数值和 timeout attrition 回归测试。
- 已在 `check.jsonl` 追加回归点：`tests/test_balance_candidate_overlay.gd`。

### 退出状态

- [x] 绿了，回到 TDD 循环失败的那一步
- [ ] 已回滚，升级（附已排除项）
- [ ] 超 3 轮，升级强模型/人工

独立 Stage 2 re-review：`0 critical / 0 major`；未知字段、精确整数和正 HP timeout 三项均放行。
