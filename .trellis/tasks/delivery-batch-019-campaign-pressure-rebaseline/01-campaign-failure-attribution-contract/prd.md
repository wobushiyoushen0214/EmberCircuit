# 019-01：跑团失败归因契约

## 需求 ID

- REQ-003
- REQ-004
- REQ-005
- REQ-009
- AC-019-01 ～ AC-019-05

## 目标

扩展现有 `BalanceSimulator.run_campaign_suite()` 的结果聚合，使每个 campaign case 能复现地解释失败发生在哪一章、哪一种遭遇、哪个角色/挑战组合以及跨章时拥有多少续航资源。此任务不修改任何生产数值，不新增平行模拟器。

## 当前缺口与证据

- 代码：`scripts/tools/BalanceSimulator.gd` 已有 `_run_campaign_once()`、`_aggregate_campaign_case()`、`_build_campaign_report_summary()`、`failure_points` 和 `failure_encounters`，但没有章节资源快照和 hard-gate 归因字段。
- 测试：`tests/test_balance_simulator.gd` 覆盖 campaign 基础输出；`tests/test_numerical_balance_matrix.gd` 覆盖正式矩阵，但不能验证归因契约。
- 诊断：`/tmp/ember019-campaign-audit-64.json` 只用于方向诊断，失败集中于 `chapter_one_boss`、`iron_checkpoint`、`cinder_kennels`；每格 64 runs 必须继续标为 `campaign_insufficient_samples`。

## 交付控制

- 批次：`delivery-batch-019-campaign-pressure-rebaseline`；Loop：L3。
- 需要隔离 worktree 和 verifier；实现/调试/评审技能分别为 `trellis-implement-tdd-zh` / `trellis-debug-systematic-zh` / `trellis-review-twostage-zh`。
- 依赖：无；解锁：`02-act2-act3-pressure-and-reward-rebaseline`。
- 回滚触发：改变现有 risk flag 语义、seed 配对、旧 campaign 字段、单战 pressure 输出、File Manifest 越界或任何生产数据改动。

## 复杂度与产物

- 复杂度：高。`BalanceSimulator.gd` 当前约 2489 行，超过 400 行阈值；先做同文件内只搬不改行为的 failure-map 累加微重构，再加入归因字段，禁止另起模拟器。
- 必要产物：本目录 `prd.md`、`design.md`、`implement.md`、`implement.jsonl`、`check.jsonl`、`tdd-progress.md`，后续 `debug-report.md` 和 `review-report.md`。
- 仓库没有 `.trellis/spec/`；以本 PRD、018D 审计、`docs/09_NUMERICAL_TREE_AND_BALANCE.md` 和现有测试为契约。

## 决策表

| 决策点 | 选定方案 | 原因 | 影响文件 |
| --- | --- | --- | --- |
| 归因 schema | 在 campaign report 和每个 case 增加 `campaign_attribution_schema_version=1`，保留 `version=1` 与所有旧字段 | 遥测/旧消费者兼容，归因可独立演进 | `BalanceSimulator.gd`、`test_balance_simulator.gd` |
| hard-gate 样本门 | `runs >= numerical_tree.campaign_targets.minimum_iterations_for_hard_gate`（当前 128）；不足时 `attribution_gate_eligible=false` 且仅输出诊断 | 64-seed 不能触发调参结论 | 同上 |
| 章节快照 | 在每章进入时记录 HP、最大 HP、金币、牌组/遗物数量；击败 Boss 前记录章末值；失败章记录最后可观测值 | 不改变战斗，只增加可复现观测 | `BalanceSimulator.gd` |
| 失败集中度 | 仅统计失败 run；输出 top encounter、count、share、阈值和独立 `attribution_flags`，不覆盖旧 `risk_flag` | 低胜率与集中失败需同时可见 | 同上 |
| 角色/挑战聚合 | case 保留 `character_id`/`challenge_level`；summary 新增 `character_attribution` 和 `challenge_attribution` 行 | 让矩阵消费者无需解析 sample runs | 同上 |

## 文件清单

| 操作 | 文件 | 精确修改 |
| --- | --- | --- |
| 修改 | `scripts/tools/BalanceSimulator.gd` | chapter entry/exit 快照、跨章快照、归因聚合、schema/eligibility 字段；保留旧字段和旧 risk flag |
| 修改 | `tests/test_balance_simulator.gd` | AC-019-01～05 的 RED/GREEN 断言、64/128 样本边界、角色/挑战聚合和失败集中度 fixture |
| 修改 | `.trellis/tasks/delivery-batch-019-campaign-pressure-rebaseline/01-campaign-failure-attribution-contract/tdd-progress.md` | 记录每条 AC 红→绿与自检 |

## 契约字段

每个 campaign case 必须包含：

- `campaign_attribution_schema_version`（整数 1）。
- `attribution_gate_eligible`（布尔；`runs >= 128`）。
- `chapter_attribution`：按 `map_generation.chapter_sequence` 排序的数组；每行包含 `chapter_id`、`entry_runs`、`completed_runs`、`failed_runs`、`entry_rate`、`completion_rate`、`conditional_completion_rate`、`avg_entry_hp`、`avg_entry_hp_ratio`、`avg_exit_hp`、`avg_exit_hp_ratio`、`avg_entry_gold`、`avg_exit_gold`、`avg_entry_deck_size`、`avg_exit_deck_size`、`avg_entry_relic_count`、`avg_exit_relic_count`。
- `chapter_transition_attribution`：每个相邻章节一行；包含 `from_chapter_id`、`to_chapter_id`、`transition_runs`、`avg_pre_transition_hp`、`avg_post_transition_hp`、`avg_post_transition_hp_ratio`、`avg_gold`、`avg_deck_size`、`avg_relic_count`。
- `failure_concentration`：包含 `losses`、`top_encounter_id`、`top_encounter_failures`、`top_encounter_share`、`share_threshold`、`gate_eligible`、`attribution_flags`。
- summary 必须包含 `character_attribution` 和 `challenge_attribution`；每行至少包含 case 数、平均胜率、平均完成章节、归因 hard-gate 是否可用。

## MVP 兼容性契约

| 已有行为 | 证据 | 必须保留 | 回归检查 |
| --- | --- | --- | --- |
| `run_campaign_suite()` 使用 paired-by-iteration seed 和 `current-greedy` | `BalanceSimulator.gd`、`test_numerical_balance_matrix.gd` | 是 | campaign schema test |
| `failure_reasons`/`failure_points`/`failure_node_types`/`failure_encounters` 字段 | `_aggregate_campaign_case()` | 是 | 旧字段 exact presence test |
| 单战 pressure schema v2 和 risk flags | `test_balance_simulator.gd`、`test_numerical_pressure_metrics.gd` | 是 | full regression |
| 64 runs 不进入正式硬门 | `numerical_tree.campaign_targets` | 是 | 64-sample boundary test |

## 实现步骤

1. RED：在 `test_balance_simulator.gd` 增加 019-01-01～05 断言，分别覆盖 schema、章节快照、跨章资源、失败集中度、角色/挑战 summary；先看到 feature-specific failure。
2. GREEN（AC-019-01）：在 `_run_campaign_once()` 记录 chapter entry/exit 和 transition snapshot，输出到 `_campaign_result()`；不改变 node resolution。
3. GREEN（AC-019-02）：在 `_aggregate_campaign_case()` 聚合章节完成率、资源均值和失败章，保留旧计数。
4. GREEN（AC-019-03）：加入 `failure_concentration` 与 `attribution_flags`，仅在 hard-gate eligible 时评估阈值。
5. GREEN（AC-019-04）：在 `_build_campaign_report_summary()` 加入角色和挑战归因行，保持既有 `challenge_targets` 输出。
6. GREEN（AC-019-05）：运行 64 与 128 的最小 campaign fixture，证明样本门和 paired seed 可复现；运行全任务自检。
7. 最小实现收敛：删除重复计数字典逻辑，保留所有旧字段、边界检查和诊断字段；更新进度表并暂存，不 commit。

## 验收标准

- [ ] AC-019-01：同一 character/challenge/iterations 输入重复运行时，`campaign_attribution_schema_version`、章节行顺序、entry/exit 快照和 transition rows 完全一致；旧 `version=1`、`seed_model`、`strategy_profile` 不变。
- [ ] AC-019-02：每个 case 的 `chapter_attribution` 三行可由 run 的 `chapters_completed` 和 snapshots 复算，`entry_rate`/`completion_rate` 在 `[0,1]`，失败章不会伪造完成快照。
- [ ] AC-019-03：64 runs 的 `attribution_gate_eligible=false` 且 flags 为空；128 runs 才允许 `top_encounter_share` 与 `single_failure_encounter_share_max` 比较；旧 `risk_flag` 语义不变。
- [ ] AC-019-04：summary 输出角色和挑战归因，并能识别 `chapter_one_boss`、`iron_checkpoint`、`cinder_kennels` 等真实失败 encounter；不混入真人报告。
- [ ] AC-019-05：现有 `test_balance_simulator.gd`、`test_numerical_pressure_metrics.gd`、`test_numerical_balance_matrix.gd` 不回归；编辑前后不得修改任何生产 JSON。

## 自检命令

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_simulator.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_pressure_metrics.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_balance_matrix.gd
```

## 自动化测试要求

- Unit：聚合 helper 的章节/失败/样本门计算。
- Integration：`run_campaign_suite()` 64/128 paired seed report schema。
- Regression：旧 campaign、single pressure、numerical matrix contract。
- 人工验证：无；本任务输出必须完全由自动报告生成。

## 范围外与禁止事项

- 不改 `data/config/economy.json`、`data/enemies/enemies.json`、`data/encounters/encounters.json`、`data/config/numerical_tree.json` 或任何 UI/CombatState/SaveManager 文件。
- 不改变战斗胜负、路线选择、奖励选择或 challenge multiplier；不删除/弱化现有断言；不把 64 runs 写成正式 observed matrix。
- 不新增第二套 campaign simulator，不引入依赖，不修改 telemetry schema 或真人 cohort 文件。
