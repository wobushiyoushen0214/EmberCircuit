# 022-02：完整图路线安全配对验证

## 需求 ID

- REQ-003
- REQ-004
- REQ-005
- REQ-009

## 目标

验证 v3 完整图安全策略是否值得进入下一轮数值审计。使用 current、competent-combat-v1、competent-player-v2、competent-player-v3 四 profile 的同一 3×4×64 paired options；v3 通过所有挑战胜率、第一章完成率和精英死亡率硬门后才允许 128。失败只记录停机，不修改正式数值。

## 交付 Loop 控制

- 批次：`delivery-batch-022-full-graph-elite-safety`；Loop L3
- worktree/verifier/Stage 1/Stage 2：必须；Stage 2 使用强模型
- 最大修复 2 次；验证脚本问题最多调试 3 轮
- 64 gate FAIL、重复报告不一致、正式矩阵变化均立即停止

## 当前缺口

- 状态：PARTIAL。
- 证据：021-03 的 `_evaluate_strategy_component_gate()` 固定 candidate 为 v2，且只读取 `/tmp/ember021-*-64.json`。
- 缺口：没有 v3 profile 的 artifact、哈希、逐挑战门和 v2→v3 的精英路线效果证据。

## 决策表

| 决策 | 固定方案 |
| --- | --- |
| profiles | `current-greedy`、`competent-combat-v1`、`competent-player-v2`、`competent-player-v3` |
| paired options | 3 characters、C0-C3、64 iterations、80 max turns、`paired_by_iteration`、`component-v1` |
| candidate | v3；current 是唯一硬基线，v2 只做诊断对照 |
| gate | 每个 challenge 三角色平均 win rate 不低于 current；第一章完成率下降不超过 0.02；v3 elite visits>0 且 deaths/visits≤0.35 |
| 128 | 仅四 profile 64 gate 全 PASS 后运行，并重复一次每 profile |
| failure | 写 `paused_no_route_safety_component_passed`，不生成 128 |

## 文件清单

| 操作 | 文件 | 说明 |
| --- | --- | --- |
| 修改 | `tests/test_balance_simulator.gd` | 更新 profile 列表、候选选择、artifact 路径与 v3 gate fixture |
| 修改 | `tests/test_numerical_balance_matrix.gd` | 断言 v3 诊断报告不能覆盖正式 current 256 rows/profile/hash |
| 修改 | `docs/12_STRATEGY_ROUTE_SAFETY_AUDIT_022.md` | 回写四 profile 64/128 结果、哈希和停机状态 |
| 新建 | `verification-report.md` | 命令、逐门结果、报告哈希、下一步 |

## 验收标准

- AC-022-07：四 profile 使用完全相同 paired options，报告 case axis 和 seed model 一致。
- AC-022-08：gate 使用整数计数和精确边界，不通过手工四舍五入；candidate 固定为 v3。
- AC-022-09：v3 64 gate 失败时不存在 `/tmp/ember022-*-128*.json`，报告写唯一停机状态。
- AC-022-10：64 全 PASS 才允许运行四 profile 128，并验证同 profile 重复 JSON byte-identical。
- AC-022-11：current/v2 历史报告、正式 256 rows、生产 numerical tree hash 保持不变。

## 自检命令

```bash
HOME=/tmp/ember022_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
HOME=/tmp/ember022_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_simulator.gd -- --require-route-safety-gate-artifacts
HOME=/tmp/ember022_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_balance_matrix.gd
HOME=/tmp/ember022_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_pressure_metrics.gd
git diff --check
```

