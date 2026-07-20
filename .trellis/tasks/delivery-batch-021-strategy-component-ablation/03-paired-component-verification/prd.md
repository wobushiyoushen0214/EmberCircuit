# 021-03：四组件 profile 配对验证与停机裁决

## 需求 ID

- REQ-003
- REQ-004
- REQ-005
- REQ-009
- AC-021-15 ～ AC-021-20

## 依赖与目标

- 依赖：021-01、021-02 全绿且双阶段评审无 critical。
- 目标：先以四 profile 的 3角色×4挑战×64 paired 报告做方向门；仅当 v2 全部门通过才运行 128；输出可复现报告、哈希与明确停机状态。

## 交付 Loop 控制

- 复杂度/风险：中；worktree/verifier 必须。
- 失败不是待修 bug：硬门未达即记录 `paused_no_strategy_component_passed`，不得调低门或改生产数值。
- 最大调试仅用于命令/实现缺陷；策略结果不通过不得“调试”成通过。

## 决策表

| 决策 | 固定方案 |
| --- | --- |
| profiles | current、v1、competent-combat-v1、v2 全部运行同一 paired options |
| 64 gate | C0-C3 各档三角色平均 win rate≥current；chapter-one completion 下降≤0.02；v2 elite visits>0 且 deaths/visits≤0.35；兼容门全绿 |
| 128 | 仅 64 全过后运行；同一硬门，不扩大容差 |
| determinism | 同 profile 相同命令重复报告 byte-identical，并记录 SHA-256 |
| 结果 | 通过=`strategy_component_gate_passed`，只解锁下一轮数值审计；失败=`paused_no_strategy_component_passed` |

## 文件清单

| 操作 | 文件 | 修改 |
| --- | --- | --- |
| 修改 | `tests/test_balance_simulator.gd` | 增加小 fixture 的 gate 计算、兼容和报告字段断言。 |
| 修改 | `tests/test_numerical_balance_matrix.gd` | 断言 64/128 诊断不能覆盖正式 256 rows/profile/hash。 |
| 修改 | `docs/11_STRATEGY_COMPONENT_AUDIT_021.md` | 记录四 profile 64/128 表、哈希、gate 与裁决。 |
| 新建 | `verification-report.md` | 保存命令、报告路径、逐门结果与 stop state。 |
| 新建 | 本目录规划/进度/评审产物 | 保存证据。 |

## 验收标准

- [ ] AC-021-15：四 profile 以完全相同角色、挑战、iterations、max_turns 与 paired seed model 生成 64 报告。
- [ ] AC-021-16：自动化 gate 逐挑战比较三角色平均胜率和第一章完成率，并验证 v2 精英访问/死亡率门；无手工舍入改变结果。
- [ ] AC-021-17：默认/显式 current byte-equivalent；v1 与 020 固定 fixture 兼容；正式 256 matrix/profile/hash 未变。
- [ ] AC-021-18：64 未全过时不生成 128 报告并写暂停状态；64 全过才运行四 profile 128。
- [ ] AC-021-19：若运行 128，同 profile 重复报告 byte-identical，记录八次输出的 SHA-256；128 使用同一硬门。
- [ ] AC-021-20：验证报告与审计文档给出逐门 PASS/FAIL、最终状态和下一步；通过也只解锁数值候选审计，不直接调生产数值。

## 自检与正式诊断命令

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_simulator.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_balance_matrix.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_pressure_metrics.gd
# 对四个 profile 分别运行 --iterations=64 --max-turns=80 --challenges=0,1,2,3 --strategy-diagnostics=component-v1
# 只有 verification-report 的 64 gate 全 PASS 后，才把 iterations 改为 128 并各重复一次
```

## 范围外与禁止事项

- 不修改 `BalanceSimulator.gd` 业务策略；若验证发现实现 bug，退回 021-01/02，不在本任务暗改。
- 不写正式 256 rows，不改生产 JSON，不扩大容差，不选择性排除角色/挑战/seed。
