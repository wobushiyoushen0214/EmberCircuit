# Post-018D 游戏性与数值树 Delta Audit

日期：2026-07-19

## Stage State Packet

```yaml
stage_state:
  state: S6_CONFIRM
  loop_mode: L3
  audit_scope: delta
  current_round: 6
  max_rounds: 6
  open_gaps: 8
  tasks_created: 0
  tasks_completed: 3
  carry_over: 3
  critical_review_issues: 0
  next_legal_action: request confirmation for delivery-batch-019-campaign-pressure-rebaseline
  stop_conditions:
    - none
```

## 审计范围与基线

- 源需求未变化，使用 delta audit；基线为 018D 交付后的 `df098ef`。
- 018D 已合并 `master`；合并后 visual bounds、UI performance budget、数值矩阵、数值树审计和 BalanceSimulator smoke 均通过。
- `docs/07_CURRENT_STATE_AND_NEXT_STEPS.md` 的旧 27.5% 快照已在 `df098ef` 修正为权威 `data/config/numerical_tree.json` 的 current-greedy 结果。

## Delta Requirements Matrix

| ID | 当前状态 | 证据 | 精确缺口 | 建议 |
| --- | --- | --- | --- | --- |
| REQ-003 | PARTIAL | `data/config/numerical_tree.json`、`docs/09_NUMERICAL_TREE_AND_BALANCE.md`、`tests/test_numerical_balance_matrix.gd` | 3×4×256 矩阵 12 格均为 `campaign_win_rate_low`；C0/C1/C2/C3 三角色均值 `6.5%/3.8%/2.0%/1.2%`，目标为 `27-33%/17-26%/12-23%/8-15%`；current-greedy 无法形成后章成熟构筑 | 先建立失败归因与跨章压力契约，再按冻结阶梯调整章节敌人、奖励和经济；禁止凭单卡 lift 或恢复免费开局资源。 |
| REQ-004 | PARTIAL | `data/config/player.json`、`data/cards/cards.json`、`tests/test_act1_rebaseline.gd`、`tests/test_progression_systems.gd` | 三角色开局已重标定，但 C0 角色最大差 `10.5%` 超过 AI 9% 门槛，且 Pyre/Ember 在第一章节点大量失败；需要区分开局包、角色卡池与后章供给的因果边界 | 在证据任务中按角色/章节/节点拆分失败，不直接改角色基础数值。 |
| REQ-005 | PARTIAL | `data/enemies/enemies.json`、`data/encounters/encounters.json`、`tests/test_act1_rebaseline.gd`、`/tmp/ember019-campaign-audit-64.json` | 64-seed 失败集中于 `chapter_one_boss`、`iron_checkpoint`、`cinder_kennels`；单战 21/21 pressure case 仍无禁止风险，说明需要跨章/路线归因而非放宽全局压力门 | 建立章节门槛、失败遭遇集中度和跨章续航的回归门。 |
| REQ-009 | PARTIAL | `scripts/core/PlaytestTelemetry.gd`、`tests/test_playtest_evidence_gate.gd`、`docs/09_NUMERICAL_TREE_AND_BALANCE.md` | 真人每格仍未达到 12/30 完成局；64-seed 只够方向诊断，不能触发硬调参 | 保持 AI 与真人 cohort 隔离；新增 evidence contract，不把 64-seed 当真人难度结论。 |
| REQ-008/012 | PARTIAL/DONE | 018D 评审报告、`/tmp/ember018d-visual.json`、`/tmp/ember018d-performance.json` | UI 挂载与自动验证已完成；生产内容美术、正式音频和更深演出仍是独立后续缺口 | 不与本轮高风险数值批次混合。 |

## 64-seed 方向证据

来源：`/tmp/ember019-campaign-audit-64.json`，真实 `BalanceSimulator`、paired seed、12 cases、每格 64 runs。

- 总平均胜率 `2.0%`，平均完成章节 `0.38`；所有 challenge target 因样本低于 128 标记 `insufficient_samples`，不能写入正式 observed matrix。
- C0 平均胜率 `4.7%`、角色差 `12.5%`；C1 `2.1%`、差 `4.7%`；C2/C3 均 `0.5%`、差 `1.6%`。
- 失败点主要出现在第一章 Boss、`iron_checkpoint`、`cinder_kennels`；不同角色集中点不同，不能用一个全局倍率修复。
- 单战 pressure 契约仍为 21/21 无 `too_easy`、`too_lethal`、`encounter_too_fast`、`encounter_too_slow`；开局过易与完整跑团过难必须分层处理。

## 建议批次（待确认）

`delivery-batch-019-campaign-pressure-rebaseline`，高风险、严格 TDD、最多三个串行任务：

1. `01-campaign-failure-attribution-contract`：为章节、遭遇、角色、挑战和跨章续航建立可复现归因字段与失败集中度门；不改生产数值。
2. `02-act2-act3-pressure-and-reward-rebaseline`：在证据门通过后，按冻结阶梯逐值调整二三章敌人/奖励/经济，并同步 `balance_note`、矩阵和真实模拟；禁止调 pressure threshold、全局倍率或免费开局资源。
3. `03-campaign-matrix-verification`：运行 128/256 paired matrix、全量 Godot regression、真人 cohort schema 检查和双阶段评审；不手改 observed 字段。

排除：REQ-006 内容资产、REQ-008 正式音频/演出、REQ-010 网格模式、REQ-011 商业发布管线；它们另开批次。

## Confirmation Gate

本轮只完成 delta audit 和证据修正，未创建 019 任务、未修改游戏数值。根据 Trellis S6 门，需要用户确认上述批次范围后才能创建 PRD/worktree 并进入 TDD。

