# 023-02：分层压力与成长候选重标定

## 需求 ID

- REQ-003
- REQ-004
- REQ-005
- REQ-009
- AC-023-06 ～ AC-023-12

## 目标

实现向后兼容的普通遭遇 layer-band，并用固定 P1-P5 overlay 阶梯自动运行 v3 64→128。只选择第一个同时通过方向门和硬门的候选；候选未选定前生产值冻结，全部失败则明确停机。

## 当前缺口

- 状态：PARTIAL；023-01 完成后已有候选隔离和 attrition-v1，但 MapGenerator 尚不读取 layer band。
- 第一章 L0 被强制为 combat，而 `_make_node()` 对 L0-L6 均从同一 combat pool 抽取。
- 019 奖励数量候选失败；022 v3 已排除策略路线安全误判，本任务必须直接验证路线压力与成长节奏。
- 风险：MapGenerator 是运行时和模拟器共用入口；错误 fallback 会改变所有历史章节，错误 gate 会把低样本或 rounded rate 当生产证据。

## 交付 Loop 控制

- 批次：`delivery-batch-023-layered-pressure-rebaseline`；Loop：L3；worktree/verifier：必须。
- 依赖：023-01 Stage 1/Stage 2 无阻断。
- 实现/调试/评审：`trellis-implement-tdd-zh` / `trellis-debug-systematic-zh` / `trellis-review-twostage-zh`。
- Stage 2：独立强模型；最大修复 2 次；最大调试假设 3 轮。
- 回滚：旧地图 graph 漂移、candidate 顺序/值漂移、raw-count gate 错误、生产冻结 hash 变化、无 selected 仍写生产值、File Manifest 越界。

## 复杂度与规划产物

- 复杂度：高，本批唯一高风险任务；候选值、顺序、比较和停止分支全部定死。
- 产物：完整 `prd/design/implement/implement.jsonl/check.jsonl/tdd-progress/review`。
- 稳定上下文：Round 4 audit、023-01 契约、019 失败证据、022 v3 报告和数值目标文档。

## layer-band schema

章节可选字段 `encounter_layer_bands`：

```json
{
  "combat": [
    {"layers": [0, 0], "encounter_ids": ["intro_patrol"]},
    {"layers": [1, 2], "encounter_ids": ["intro_patrol", "polluted_lab", "cinder_kennels"]},
    {"layers": [3, 6], "encounter_ids": ["polluted_lab", "iron_checkpoint", "cinder_kennels"]}
  ]
}
```

`_encounter_pool_for_layer(config,node_type,layer)` 按数组顺序找唯一覆盖 band；找到则使用 `encounter_ids`，否则回退 `encounter_by_type[node_type]`。只有 P1 为 chapter_one/combat 配置 band；elite/boss 和未配置章节行为不变。overlay 校验已禁止重叠和空池，运行时仍对 malformed/empty band fail-safe 回退旧池。

## 候选文件

在 `tests/fixtures/balance_candidates/023-P1.json` 至 `023-P5.json` 建立五份完整累积 overlay：

| Step | changes 精确集合 |
| --- | --- |
| P1 | chapter_one encounter layer bands |
| P2 | P1 + route max pressure `3` |
| P3 | P2 + chapter_one/two/three campfire `[2,2]` |
| P4 | P3 + heal `30` |
| P5 | P4 + rarity `{common:60,uncommon:30,rare:10}` |

每份 `candidate_id` 必须等于文件 step；changes 按 dataset+path 排序，前一步 changes 必须是后一步的严格前缀。P1-P5 不包含任何其他字段。

## Gate 契约

新建 `LayeredPressureCandidateGate.gd`，所有判断使用报告原始整数，不用三位小数反推。`evaluate_hard(report, expected_iterations)` 只接受 `expected_iterations` 为 128 或 256；ladder 调用 128，023-03 复用同一 gate 并传 256，禁止在最终验证任务复制第二套阈值：

### 64 direction

- 两份报告均为 v3、paired、12 cases、每格 64、80 turns，角色/挑战集合完全相同。
- baseline 每挑战 wins=`[16,8,5,3]`，第一章 completed=`[76,60,35,19]`。
- candidate 每挑战 wins 和 first-act completed 分别不得低于 baseline；C0 first-act 至少 `84/192`，C1 至少 `66/192`。
- 任一 case 的 `attribution_gate_eligible` 在 64 应为 false，不得伪装成 hard gate；报告必须有 overlay id/SHA/applied fields 和 attrition-v1。

### 128/256 hard

- v3、paired、12 cases、每格精确等于 `expected_iterations`、80 turns、全部 attribution eligible，candidate identity 与 selected candidate 一致。ladder 传 128，正式验证传 256。
- 挑战均值目标：C0 `[0.27,0.33]`、C1 `[0.17,0.26]`、C2 `[0.12,0.23]`、C3 `[0.08,0.15]`。
- 每个 cell 允许目标区间上下各 0.03；每挑战角色 gap `<=0.09`；相邻挑战均值最多逆差 0.01。
- 每 case failure top share `<=0.50`；平均最终金币和牌组分别在 `100-180`、`16-19`，均值容差 0.5。
- gate 输出 raw totals、每条 failure code 和 `eligible/pass`，禁止只信任报告已有 `target_pass`。

固定 failure codes：`input_missing`、`identity_mismatch`、`required_iterations`、`case_matrix_mismatch`、`direction_wins_regressed`、`direction_act1_regressed`、`direction_act1_gain_low`、`average_win_rate_outside_target`、`cell_win_rate_outside_tolerance`、`character_gap_high`、`challenge_not_monotonic`、`failure_concentration_high`、`final_gold_outside_target`、`final_deck_outside_target`。

## Ladder 编排

`tools/run_layered_pressure_ladder.gd` 固定读取 P1-P5，逐步执行：

1. 验证五份 overlay exact/prefix 和所有候选图的 32-seed 完整路径预算。
2. 对当前 step 生成 `3×4×64` v3 attrition 报告 `/tmp/ember023-{step}-64.json`。
3. direction FAIL：记录 SHA/failures，进入下一 step，不创建对应 128。
4. direction PASS：生成 `/tmp/ember023-{step}-128.json` 与 repeat；repeat 不同即 hard FAIL。
5. hard FAIL：记录 SHA/failures，进入下一 step。
6. hard PASS：写 `selected_step` 并停止；不得运行更高 step。
7. 输出 `/tmp/ember023-layered-ladder-verdict.json`，含 P1-P5 顺序、每步状态、原始计数、报告路径/SHA 和 selected_step。

## 生产晋级

- selected step 存在：只把该 overlay 的 changes 写入 `map_generation.json/level_tree.json/economy.json`，同步 balance/design note 和 numerical tree 的 snapshot；`campaign_rebaseline_023.status=selected_128_candidate`，记录 step、verdict path/SHA 和结果。
- 无 selected step：三份生产配置保持任务起点；`campaign_rebaseline_023.status=paused_no_layered_candidate_passed`，selected_step 为空，只记录 verdict 和结果，不写候选值。
- 两种结果都不修改 `campaign_matrix.rows/strategy_profile/iterations`；正式 matrix 仍由 023-03 独占。

## 文件清单

| 操作 | 文件 | 修改 |
| --- | --- | --- |
| 修改 | `scripts/map/MapGenerator.gd` | 新增 layer-band pool helper 与 fallback |
| 新建 | `scripts/tools/LayeredPressureCandidateGate.gd`、`.uid` | direction/hard raw-count gate 与固定 failure codes |
| 新建 | `tools/run_layered_pressure_ladder.gd`、`.uid` | 固定 P1-P5 串行 runner、报告/SHA/verdict |
| 新建 | `tests/test_layered_pressure_candidate_gate.gd`、`.uid` | exact boundary、wrong identity、64/128 混淆和 raw-count 测试 |
| 新建 | `tests/test_layered_pressure_rebaseline.gd`、`.uid` | layer band/fallback、P1-P5 prefix、32-seed path、生产晋级/回滚和冻结测试 |
| 修改 | `tests/test_map_generator.gd` | 旧 config deterministic 回归与 band 层级池测试 |
| 新建 | `tests/fixtures/balance_candidates/023-P1.json` 至 `023-P5.json` | 固定累积候选 |
| 条件修改 | `data/config/map_generation.json` | selected 时写 P1 layer band；无 selected 不改 |
| 条件修改 | `data/config/level_tree.json` | selected>=P2/P3 时写对应值；无 selected 不改 |
| 条件修改 | `data/config/economy.json` | selected>=P4/P5 时写对应值；无 selected 不改 |
| 修改 | `data/config/numerical_tree.json` | 记录 023 verdict/selected 与实际 snapshot；正式 matrix 不变 |
| 修改 | `tests/test_numerical_balance_matrix.gd` | 023 状态、正式 matrix freeze、生产值与 selected step 一致 |
| 新建 | `docs/13_LAYERED_PRESSURE_REBASELINE_023.md` | 候选表、原始结果、裁决与冻结项 |
| 修改 | 本任务 `tdd-progress.md` | 逐 AC RED/GREEN、每步命令和结果 |

## 冻结 SHA

- `player.json`: `f803ba56a07823a4ef6d15c932a666cdb0a0a762f4851e96e01e4546cb6c1d09`
- `cards.json`: `24d4c8e8b2789cd048740c1cbeabd2179bfcd6de2e52609f3e5269b80a101e76`
- `enemies.json`: `8b0c3e4ec5c9cedd69f0637f890c2727f780fba65c7a7b1e1fd8fea9098cd22a`
- `encounters.json`: `b2d8f0315ce1a865353204644626d97c189bbf42ce99966771f10ce3136c172b`
- `challenges.json`: `5779b2053818cb5f3b33ce4c1daf5951e0378f366484de2ade5b9cfde6a5d693`
- `CombatState.gd`: `89bf501cb4a723a1f866a5dda2a8c3bf1a6527ebc663d77ff39d7c3c6af4716f`

## 实现步骤与 TDD

1. AC-023-06 RED：band config 在 L0/L1/L3 仍从旧全池取值；实现 helper 和 fallback，使 band/legacy fixture GREEN。
2. AC-023-07 RED：wrong iterations/identity/边界 raw count 未被统一拒绝；实现纯 gate 和 failure codes，并证明 128/256 仅预期样本数不同、阈值逻辑完全共用。
3. AC-023-08 RED：P1-P5 fixture/prefix 与 32-seed candidate graph 尚不存在；创建 exact fixtures 和 candidate-level integration test。
4. AC-023-09 RED：ladder 当前不能按 64 fail-closed；实现 runner 的 P1-P5 direction 分支并用 fixture reports 证明 fail 不产生 128。
5. AC-023-10 RED：128/repeat/hard 边界未接；实现 hard gate、byte compare 和 first-pass stop。
6. AC-023-11 RED：selected/none 的生产晋级规则未固化；按真实 verdict 写配置或恢复起点，更新 notes/tree/docs。
7. AC-023-12：运行定向测试、21 单战、Map、Numerical Auditor、matrix、BalanceSimulator 和 freeze hash；完成双阶段评审。

## 验收标准

- AC-023-06：P1 L0 只生成 intro，L1-L2 和 L3-L6 只生成指定池；无 band/malformed/no-match 均回退旧池且旧 seed graph 不变。
- AC-023-07：gate 对全部固定错误、上下界、64/128/256 样本混淆和 rounded-rate 欺骗 fixture 给出准确 raw verdict；023-03 可直接调用 `evaluate_hard(report, 256)`，无需修改 gate。
- AC-023-08：P1-P5 schema/id/prefix/exact values 通过；每份候选 32 seeds 的路径预算、分支、篝火/压力门通过。
- AC-023-09：每个 step 有独立 64 report/SHA；direction fail 绝不产生该 step 128；runner 顺序固定。
- AC-023-10：仅 64 pass step 运行 128/repeat；首个 hard pass 被选中并停止；repeat 必须 byte-identical。
- AC-023-11：selected 时生产值精确等于 overlay；none 时生产值精确等于起点；两者均不改正式 matrix rows/profile/iterations。
- AC-023-12：所有冻结 SHA 不变，21/21 单战无 risk，静态/地图/回归无新 warning，Stage 1/2 无阻断。

## 自检命令

```bash
HOME=/tmp/ember023_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
HOME=/tmp/ember023_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_layered_pressure_candidate_gate.gd
HOME=/tmp/ember023_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_layered_pressure_rebaseline.gd
HOME=/tmp/ember023_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_map_generator.gd
HOME=/tmp/ember023_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tools/run_layered_pressure_ladder.gd
HOME=/tmp/ember023_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_act1_rebaseline.gd
HOME=/tmp/ember023_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_tree_auditor.gd
HOME=/tmp/ember023_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_balance_matrix.gd
HOME=/tmp/ember023_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_simulator.gd
shasum -a 256 data/config/player.json data/cards/cards.json data/enemies/enemies.json data/encounters/encounters.json data/config/challenges.json scripts/combat/CombatState.gd
git diff --check
```

## 依赖与解锁

- 依赖：023-01 完成并通过双阶段评审。
- 解锁：selected step 存在时解锁 023-03；无 selected 时取消 023-03 并停机。

## 禁止事项

- 不修改冻结 SHA 文件、敌人/卡牌/角色数值、challenge/campaign targets、CombatState 或 Main。
- 不手改报告、降低门槛、跳过失败 step、重排 P1-P5 或发明 P6。
- 128 未通过不得把 overlay 写入生产；正式 256 rows 由 023-03 独占。
