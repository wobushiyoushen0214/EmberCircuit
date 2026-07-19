# 2026-07-19 Batch 020 策略重基线差距审计

## Stage State Packet

```yaml
stage_state:
  state: S5_PICK_BATCH
  loop_mode: L3
  audit_scope: delta
  current_round: 1
  max_rounds: 6
  open_gaps: 8
  tasks_created: 2
  tasks_completed: 0
  carry_over: 0
  critical_review_issues: 0
  next_legal_action: implement 020-01 in isolated worktree
  stop_conditions:
    - none
```

## 路由与基线

- 路由：`mvp-to-delivery-delta-audit`，因为 019 合并后相关代码、测试和 delivery state 已变化，源需求未变化。
- 交付循环：用户已确认继续进行受控 rebaseline；本轮仍为 L3，先只建立可复现策略差分，不改生产数值。
- 当前基线：`585cc34d0819aa9e88df6570112ac7ce6faca9ec`。
- 旧候选证据：`/tmp/ember019-step-R1-128.json`、`/tmp/ember019-step-R2-128.json`、`/tmp/ember019-r2a-static.json`；019-02 已按停止门回滚。
- 正式矩阵：`data/config/numerical_tree.json.campaign_matrix` 仍为 `current-greedy` 的冻结 256 rows，不能写入 020 的 128 诊断。

## 需求追踪矩阵增量

| ID | 状态 | 019 后证据 | 本轮差距 | 020 处理 |
| --- | --- | --- | --- | --- |
| REQ-003 | PARTIAL | `data/config/numerical_tree.json`、`scripts/tools/NumericalTreeAuditor.gd`、`scripts/tools/BalanceSimulator.gd`、`tests/test_numerical_balance_matrix.gd` | 生产数值与静态压力契约已冻结，但 current-greedy 不能代表熟练玩家，无法据此决定后章敌人/奖励 | 先建立 competent-player-v1 差分策略；不改生产数据 |
| REQ-004 | PARTIAL | `scripts/tools/BalanceSimulator.gd`、`data/config/player.json`、`tests/test_balance_simulator.gd` | 报告显示大量局只拿牌、不升级、奖励评分不读角色与牌组状态，策略归因不足 | 增加策略版本和决策遥测，修正可证实的模拟器策略缺陷 |
| REQ-005 | PARTIAL | `data/enemies/enemies.json`、`data/encounters/encounters.json`、`tests/test_act2_act3_rebaseline.gd` | 019 R1/R2 全部方向门失败；继续改 HP 会把模拟器弱点误当生产压力 | 020 禁止改敌人数值，先复核路线和战斗策略 |
| REQ-009 | PARTIAL | `scripts/core/PlaytestTelemetry.gd`、`scripts/tools/BalanceSimulator.gd`、`tests/test_playtest_evidence_gate.gd` | AI 归因 schema 已完成，真人 cohort 仍隔离；策略 profile 尚未可切换和配对比较 | 输出 strategy profile/schema、paired differential report 与停机结果 |

其余 REQ 保持上一轮状态，未发现本轮相关变化。

## 根因证据

1. 128 报告的 C0 章完成率仍极低，但单战压力门 21/21 通过；失败更像累计路线策略而非单个敌人硬越界。
2. `scripts/tools/BalanceSimulator.gd:1718-1752` 的 `_card_reward_score(card, _character_id)` 明确未使用角色参数；它不能区分角色构筑或牌组已有重复。
3. `scripts/tools/BalanceSimulator.gd:1325-1339` 的 `_campaign_node_score()` 对普通战固定给 6 分，对 Boss 固定给 100 分；没有读取遭遇峰值、牌组成熟度或下一节点的战斗压力。
4. `scripts/tools/BalanceSimulator.gd:666-683` 的篝火策略只按 72% HP 阈值二选一；`_best_upgrade_index()` 在 `scripts/tools/BalanceSimulator.gd:1925-1943` 以空角色上下文评分，且直接用带 `+` 的 ID 查卡，升级决策缺少稳定的角色/升级语义。
5. `scripts/tools/BalanceSimulator.gd:1140-1167` 的药水策略只在 38% HP、即将受击或 Boss 压力等局部条件使用，未输出“为何未使用”的诊断；报告因此无法区分资源不足和策略囤积。
6. `/tmp/ember019-attribution-128.json` 的 12 个 case 平均升级数约 `0.023-0.594`，多局在第一章 Boss 前只有低质量牌组；这与“只靠生产敌人 HP 就能修复”的假设不相容。

## 选定 Batch 020

`delivery-batch-020-competent-campaign-strategy`，只处理 AI 策略可观测性和一个可选的熟练玩家策略 profile。

| 子任务 | 复杂度 | 作用 | 允许改动 |
| --- | --- | --- | --- |
| `020-01-strategy-contract-diagnostics` | 中 | profile 入口、版本化字段、逐局决策遥测；默认 current-greedy 行为兼容 | `BalanceSimulator.gd`、`test_balance_simulator.gd`、任务产物 |
| `020-02-competent-player-differential-verification` | 高 | competent-player-v1 的路线/奖励/篝火/升级/药水决策和 128 paired differential report | `BalanceSimulator.gd`、`tools/run_balance_simulation.gd`、数值测试、任务产物 |

## 候选与停机门

- `current-greedy` 永远保留，作为历史相对回归 profile；省略 profile 的旧调用必须得到同一行为。
- `competent-player-v1` 仅为诊断 profile，不进入正式 256 matrix，不改变 `campaign_targets`，不恢复免费开局资源。
- 只有在同一 `character_ids/challenge_levels/iterations/max_turns` 下，competent profile 报告可复现，且其 C0/C1/C2/C3 平均通关率不低于 current profile、第一章完成率不下降超过 2 个百分点时，才可建议下一轮数值候选。
- 任一 profile 结果低于上述差分门、出现非单调挑战、静态预算 warning、非确定性或回归失败，都记录 `paused_no_strategy_passed`，不继续改生产 JSON。
- 不把 128 结果写进 `campaign_matrix.rows`；不混入真人报告。

## 自我评审结论

- A 需求追踪：通过；每条受影响 REQ 都有具体代码、测试和报告证据。
- B 完成度：通过；REQ-003/004/005/009 继续 `PARTIAL`，没有把弱策略诊断标为 DONE。
- C 拆分：通过；契约/遥测与高复杂度策略/验证分离，串行依赖明确。
- D/E PRD：计划按无占位符、精确 File Manifest、TDD AC 和停止门生成。
- H 风险：通过；高风险仅为模拟器策略，不触碰生产数值、正式矩阵、真人 cohort。

## 下一步

在用户确认的继续执行授权下，已进入 `delivery-batch-planning`，先创建 020-01/020-02 任务产物；完成后在隔离 worktree 中按 `trellis-implement-tdd-zh` 实现。
