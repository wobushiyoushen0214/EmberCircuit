# 024-02：有限角色平衡校准

## 需求 ID

- REQ-003
- REQ-004
- REQ-005
- REQ-009
- AC-024-07 至 AC-024-15

## 目标

在 024-01 的角色 selector 与 compact evidence 契约上，实现唯一、有界的 `B0 + A1-A3/E1-E3/Y1-Y3` 校准漏斗。每名角色只选择第一个通过单角色 64 原始胜局内带的候选；三名角色都有选择后，只组合一次 C1，并按组合 64、组合 128 primary/repeat 顺序晋级。任何一门失败都保存版本化证据并停机，不发明新候选、不写生产数值、不打包。

## 当前缺口

- 当前状态：PARTIAL。
- 代码证据：`tools/run_layered_pressure_ladder.gd` 只认识 P1-P5 全局候选；`scripts/tools/LayeredPressureCandidateGate.gd` 的 hard gate 只接受 128/256 完整 12 格报告。
- 测试证据：`tests/test_layered_pressure_candidate_gate.gd` 与 `tests/test_layered_pressure_rebaseline.gd` 已保护 023 raw gate、repeat 和 first-pass stop，但没有 4 格单角色内带、角色候选 exact catalog、唯一组合或版本化 compact evidence。
- 缺口：023 P4 的 Arc/Ember/Pyre 胜局高度失衡；现有 runner 不能把角色行动经济和生存候选逐角色隔离，也不能在会话重启后复核每个晋级输入。
- 风险：把单角色 64 当正式 hard gate、在角色间继承 overlay、组合多个候选、放宽角色差或丢失原始证据都会制造不可复现的假通过。

## 交付 Loop 控制

- 交付批次：`delivery-batch-024-character-parity-rebaseline`；Loop：L3；风险：高，本批唯一高风险任务。
- worktree：`/Users/lizhiwei/localProj/EmberCircuit-batch024`；verifier：必须。
- 依赖：024-01 Stage 1 与独立强模型 Stage 2 均无阻断。
- 实现/调试/评审：`trellis-implement-tdd-zh` / `trellis-debug-systematic-zh` / `trellis-review-twostage-zh`。
- Stage 2：独立强模型；最大修复 2 次；最大调试假设 3 轮。
- 人工门：用户已于 2026-07-23 确认本批；只有扩大候选/File Manifest 或出现停止条件才再次暂停询问。
- 回滚触发：candidate exact/prefix 漂移、角色间状态泄漏、compact evidence 缺失、repeat 不同、样本数超过 6,912、生产快照变化、File Manifest 越界或任何 critical。

## 复杂度与稳定上下文

- 复杂度：高；候选值、顺序、原始整数边界、停止码、样本上限和写入路径全部在本 PRD 定死。
- 必要产物：`prd.md`、`design.md`、`implement.md`、`implement.jsonl`、`check.jsonl`、`tdd-progress.md`、`review-report.md`。
- Spec 新鲜度：仓库无 `.trellis/spec/`；Round 5 audit、024-01 PRD、023 最终文档、`docs/09_NUMERICAL_TREE_AND_BALANCE.md` 为 fresh。`docs/03_CONTENT_AND_BALANCE.md` 的遗物旧值只作 024-03 待同步项，不作候选来源。

## 上下文清单

| 类型 | 路径 | 用途 |
| --- | --- | --- |
| 候选审计 | `.trellis/audits/2026-07-23-post-023-character-parity-candidate-delta-audit.md` | B0、A/E/Y、raw gate、预算和冻结项 |
| 依赖任务 | `.trellis/tasks/delivery-batch-024-character-parity-rebaseline/01-character-overlay-and-evidence-contract/prd.md` | selector/digest API 与错误契约 |
| 现有 runner | `tools/run_layered_pressure_ladder.gd` | scripted adapter、first-pass、artifact/SHA 范例 |
| 现有 gate | `scripts/tools/LayeredPressureCandidateGate.gd` | 128 hard gate 唯一来源 |
| 回归测试 | `tests/test_layered_pressure_rebaseline.gd`、`tests/test_numerical_balance_matrix.gd` | exact candidate、生产冻结与 matrix 隔离 |

## 固定候选目录

所有 fixture 都是 schema v1 完整 overlay，从 023 生产起点独立应用，不从上一候选继承未声明状态。`changes` 按 `dataset + qualified path` 字典序排序。

### B0 的六条精确 changes

1. `map_generation.chapter_one.encounter_layer_bands` 精确等于 `tests/fixtures/balance_candidates/023-P1.json` 的三段 combat band。
2. `level_tree.route_constraints.max_pressure_nodes_between_campfires=3`。
3. `level_tree.chapters.chapter_one.node_budget.campfire=[2,2]`。
4. `level_tree.chapters.chapter_two.node_budget.campfire=[2,2]`。
5. `level_tree.chapters.chapter_three.node_budget.campfire=[2,2]`。
6. `economy.campfire.heal_percent_of_max_hp=30`。

`economy.reward_generation.card_rarity_weights` 不进入任何 024 fixture，生产 `65/28/7` 必须保持；P5 的 `60/30/10` 不得复用。

### 单角色候选

| Step | B0 之外的精确 changes |
| --- | --- |
| A1 | `player.characters.arc_tinker.starting_momentum=0` |
| A2 | A1 + Arc deck=`[spark_throw,spark_throw,relay_strike,pressure_probe,pressure_probe,soot_step,soot_step,ash_guard,ash_guard,static_primer]` |
| A3 | A1 + Arc deck=`[spark_throw,spark_throw,relay_strike,pressure_probe,induction_coil,soot_step,soot_step,ash_guard,ash_guard,static_primer]` |
| E1 | Ember deck=`[ember_strike,ember_strike,ember_strike,ember_strike,pressure_probe,ash_guard,ash_guard,ash_guard,ash_guard,cooling_breath]` |
| E2 | Ember deck=`[ember_strike,ember_strike,ember_strike,pressure_probe,pressure_probe,ash_guard,ash_guard,ash_guard,ash_guard,cooling_breath]` |
| E3 | E2 + `relics.relics.ember_bottle.effects.0.amount=5` |
| Y1 | Pyre deck=`[brand_strike,brand_strike,penitent_cut,penitent_cut,scar_guard,scar_guard,scar_guard,scar_guard,kindle_pain,cooling_breath]` |
| Y2 | Pyre deck=`[brand_strike,brand_strike,penitent_cut,penitent_cut,scar_guard,scar_guard,scar_guard,scar_guard,kindle_pain,wound_offering]` |
| Y3 | Y2 + `relics.relics.ash_rosary.effects.0.amount=3` |

`CharacterParityCandidateCatalog` 必须验证 B0 exact、A/E/Y 顺序、每步完整目标数组、允许卡牌 ID、10 张长度和累计关系；不得接受 A4/E4/Y4。组合 payload 的 ID 固定为 `024-C1-{Ax}-{Ey}-{Yz}`，内容精确为 B0 加三名 selected step 的并集，排序去重后写 `/tmp/ember024-C1-overlay.json`。

## 角色与组合 Gate

### 单角色 64

`CharacterParityCandidateGate.evaluate_role(report, character_id)` 只接受 v3、paired、80 turns、attrition-v1、exact candidate identity、4 个唯一挑战 case、每格 64 runs，且角色只能是传入 ID。四格 wins 必须全部落入：C0 `18-21`、C1 `11-16`、C2 `8-13`、C3 `6-9`。按 A1→A3、E1→E3、Y1→Y3 选择第一个 PASS；耗尽时分别输出 `paused_no_arc_candidate_passed`、`paused_no_ember_candidate_passed`、`paused_no_pyre_candidate_passed` 并立即停止。

### 唯一组合 64

`evaluate_combined_64(report, selected_role_reports)` 只接受 12 个唯一格、每格 64、完整 C1 identity，并要求：

- 四挑战聚合胜局分别为 C0 `52-63/192`、C1 `33-49/192`、C2 `24-44/192`、C3 `16-28/192`。
- 每格胜局分别落在 C0 `16-23/64`、C1 `9-18/64`、C2 `6-16/64`、C3 `4-11/64`。
- 同挑战最高与最低角色相差最多 5 胜；下一挑战聚合胜局不得比上一挑战高 2 胜或更多。
- 每名角色四格的 `runs/wins/first_act_entry_runs/first_act_completed/losses/top_encounter_id/top_encounter_failures/avg_final_gold/avg_final_deck_size` 精确等于其 selected 单角色 64 report；不同即 `selected_role_case_mismatch`。

### 组合 128

组合 64 PASS 后才生成 `3×4×128` primary/repeat。两文件必须 byte-identical；然后原样调用 `LayeredPressureCandidateGate.evaluate_hard(primary,128)`，不得复制或修改 023 的目标、3% 单格容差、9% 角色差、1% 单调、50% 失败集中、金币 `100-180`、牌组 `16-19`。任一失败输出 `paused_no_character_parity_candidate_passed`。

固定新增 failure codes：`input_missing`、`identity_mismatch`、`required_iterations`、`case_matrix_mismatch`、`character_scope_mismatch`、`role_win_band_c0`、`role_win_band_c1`、`role_win_band_c2`、`role_win_band_c3`、`aggregate_win_band_failed`、`cell_win_band_failed`、`character_gap_high`、`challenge_not_monotonic`、`selected_role_case_mismatch`、`evidence_write_failed`、`repeat_mismatch`。输出顺序按此列表，不按发现顺序漂移。

## Runner、证据与样本预算

`tools/run_character_parity_ladder.gd` 固定执行：

1. exact catalog、全部 10 fixture、候选卡牌/遗物 ID、B0 的 32-seed 地图完整性预检。
2. 运行 B0 `3×4×64=768` 并写 `/tmp/ember024-B0-64.json` 与 `.trellis/evidence/batch-024/024-B0-64.json` compact digest。
3. A、E、Y 各自按顺序运行 `1×4×64`，每份 full report 写 `/tmp`，compact digest 写 `.trellis/evidence/batch-024/024-{step}-64.json`；首个 PASS 后跳过该角色后续 step。
4. 三角色都 selected 后只组合 C1 一次，写组合 64 full/digest；失败即停。
5. 组合 64 PASS 后写 128 primary/repeat full report、单份绑定 repeat SHA 的 compact digest，并调用共享 hard gate。
6. 始终写 `.trellis/evidence/batch-024/character-parity-verdict.json`，记录 exact candidate order、每步状态、报告/digest path 与 SHA、raw gate verdict、selected A/E/Y、C1 identity、总正式 runs 和最终状态。

样本上限为 B0 `768` + 九个单角色候选 `2304` + 组合 64 `768` + 组合 128 primary/repeat `3072` = `6912`。runner 在每次运行前检查预计累计值，超过即 `sample_budget_exceeded`，不得启动模拟。

## MVP 兼容性契约

- 024-01 的默认无 overlay byte identity、五数据集恢复、旧 P1-P5 overlay 和 digest error ordering 全部保持。
- 024-02 不修改 `player.json`、`relics.json`、`map_generation.json`、`level_tree.json`、`economy.json` 的生产值；仅允许 `numerical_tree.json` 增加 `campaign_rebaseline_024` 证据元数据，正式 matrix 对象必须语义不变。
- `CombatState.gd`、cards/enemies/encounters/challenges、campaign targets、AI profile/turn horizon、真人 cohort 和 alpha.8 包体保持冻结。

## 参考实现

- 候选 exact/prefix 与 32-seed：`tools/run_layered_pressure_ladder.gd:validate_candidate_payloads`、`tests/test_layered_pressure_rebaseline.gd`。
- raw gate 与 identity：`scripts/tools/LayeredPressureCandidateGate.gd`。
- full report 运行/保存/SHA：`tools/run_layered_pressure_ladder.gd`。
- compact evidence：024-01 `BalanceEvidenceDigest.gd`；runner 只调用，不复制字段提取。
- 数值树冻结：`tests/test_numerical_balance_matrix.gd:_check_strategy_diagnostic_formal_matrix_freeze`。

## 文件清单

| 操作 | 文件路径 | 精确用途 |
| --- | --- | --- |
| 新建 | `scripts/tools/CharacterParityCandidateCatalog.gd`、`.uid` | exact B0/A/E/Y catalog 校验与唯一 C1 composition |
| 新建 | `scripts/tools/CharacterParityCandidateGate.gd`、`.uid` | 单角色 64 和组合 64 原始整数 gate |
| 新建 | `tools/run_character_parity_ladder.gd`、`.uid` | 固定 runner、样本预算、报告/digest/verdict 编排 |
| 新建 | `tests/test_character_parity_candidate_gate.gd`、`.uid` | 4/12 格边界、identity、角色 scope、gap、单调和固定错误码 |
| 新建 | `tests/test_character_parity_rebaseline.gd`、`.uid` | exact fixtures、compose、first-pass/stop、evidence、预算与生产冻结 |
| 新建 | `tests/fixtures/balance_candidates/024-B0.json`、`024-A1.json` 至 `024-A3.json`、`024-E1.json` 至 `024-E3.json`、`024-Y1.json` 至 `024-Y3.json` | 十份冻结 overlay |
| 条件新建 | `.trellis/evidence/batch-024/*.json` | 实际运行生成的 compact digests 与唯一 verdict；未运行 step 不伪造文件 |
| 修改 | `data/config/numerical_tree.json` | 仅写 `campaign_rebaseline_024` 状态/provenance；正式 matrix 不变 |
| 修改 | `tests/test_numerical_balance_matrix.gd` | 024 selected/paused metadata、compact evidence、正式 matrix freeze |
| 新建 | `docs/14_CHARACTER_PARITY_REBASELINE_024.md` | 候选、raw results、SHA、停止/晋级与生产冻结 |
| 修改 | 本任务 `tdd-progress.md` | 逐 AC RED/GREEN 与真实 runs 证据 |
| 新建 | 本任务 `review-report.md` | 双阶段评审；实现者不得预填通过 |

## 挂载点

| 挂载点 | 类型 | 位置 | 接线动作 |
| --- | --- | --- | --- |
| exact catalog | 候选入口 | `CharacterParityCandidateCatalog` | runner 预检十份 fixture 并组合唯一 C1 |
| role/combined gate | 计算入口 | `CharacterParityCandidateGate` | runner 逐角色和组合 64 调用 |
| shared hard gate | 晋级入口 | `LayeredPressureCandidateGate.evaluate_hard(...,128)` | 组合 128 唯一门 |
| compact evidence | 持久证据 | `BalanceEvidenceDigest.build/write_digest` | 每份实际报告都生成版本化摘要 |
| verdict/state | 状态入口 | runner → evidence/tree/docs | 绑定 selected、SHA、raw failures 与生产冻结 |

## 实现步骤与 TDD

1. AC-024-07 RED：exact B0/A/E/Y catalog 不存在；创建 fixtures 与 catalog，错误值/顺序/额外 step fail-closed。
2. AC-024-08 RED：4 格 64 role gate 不存在；实现 exact matrix、身份和四档 raw band。
3. AC-024-09 RED：first-pass 与三种角色耗尽停止码不存在；用 scripted adapter 实现 A→E→Y 串行和提前停止。
4. AC-024-10 RED：唯一 C1 compose/12 格 64 gate 不存在；实现去重排序、aggregate/cell/gap/monotonic 与 selected-row identity。
5. AC-024-11 RED：组合 128/repeat/shared hard gate 未接；实现 byte compare、hard call 和无 256/生产写入断言。
6. AC-024-12 RED：版本化 evidence/verdict 与写失败停机不存在；接入 024-01 digest 并验证每个实际 step 均有 raw 摘要。
7. AC-024-13 RED：6,912 样本预算和 32-seed B0 graph 预检不存在；实现启动前预算与 preflight。
8. AC-024-14：运行真实 ladder；只接受 selected 或三个固定角色耗尽/组合失败状态之一，回写 tree/docs，不手改报告。
9. AC-024-15：执行 editor、024-01、023 gate/rebaseline、map/auditor/matrix/simulator、freeze SHA 与双阶段评审；最小实现收敛。

## 验收标准

- AC-024-07：十份 fixture 的 ID、B0、候选数组、顺序、累计关系精确；额外字段/step、未知卡/遗物或错误数组拒绝。
- AC-024-08：合法 4 格在全部边界 PASS；缺格/重复格/错误角色/非 64/任一档越界返回固定 code。
- AC-024-09：每名角色选择第一个 PASS；耗尽立即返回对应 paused code，后续角色、组合和 128 均未运行。
- AC-024-10：C1 只含三个 selected step；组合 64 exact aggregate/cell/5-win gap/单调/selected-row 门准确。
- AC-024-11：只有组合 64 PASS 才生成 128/repeat；byte-identical 且共享 hard gate 全过才输出 `selected_128_candidate`，失败不生成 256。
- AC-024-12：所有实际运行报告均有可解析 digest，raw rows/SHA/failures 与 full report 精确；缺失或不可写时 fail-closed。
- AC-024-13：正式 runs 计数不超过 6,912；B0 与全部 fixture 32 seeds 地图有效；禁止重新运行 023 19,968 局。
- AC-024-14：真实 verdict、tree、docs 使用同一 selected/status/SHA；无 selected 时生产和正式 matrix 保持任务起点。
- AC-024-15：全部定向/回归和冻结 SHA 通过；Stage 1/2 无阻断；实现体未 commit。

## 自检命令

```bash
HOME=/tmp/ember024_tdd_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
HOME=/tmp/ember024_tdd_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_character_parity_candidate_gate.gd
HOME=/tmp/ember024_tdd_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_character_parity_rebaseline.gd
HOME=/tmp/ember024_tdd_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tools/run_character_parity_ladder.gd
HOME=/tmp/ember024_tdd_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_character_balance_candidate_overlay.gd
HOME=/tmp/ember024_tdd_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_evidence_digest.gd
HOME=/tmp/ember024_tdd_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_candidate_runtime.gd
HOME=/tmp/ember024_tdd_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_layered_pressure_candidate_gate.gd
HOME=/tmp/ember024_tdd_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_layered_pressure_rebaseline.gd
HOME=/tmp/ember024_tdd_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_map_generator.gd
HOME=/tmp/ember024_tdd_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_tree_auditor.gd
HOME=/tmp/ember024_tdd_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_balance_matrix.gd
HOME=/tmp/ember024_tdd_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_simulator.gd
shasum -a 256 data/cards/cards.json data/enemies/enemies.json data/encounters/encounters.json data/config/challenges.json scripts/combat/CombatState.gd
git diff --check
```

每条 Godot 命令必须退出 0 且无未知 `ERROR`、`SCRIPT ERROR` 或 `Parse Error`；真实 runner 可能耗时，但不得绕过。

## 自动化测试要求

### Unit Tests

- AC-024-07：catalog 对十份 exact fixture、错误值/顺序/额外 step 和 C1 merge 给出确定结果。
- AC-024-08/10：gate 对每个 raw 下上界、缺失/重复 case、错误 identity、5/6 胜角色 gap 与单调 1/2 胜边界给出确定结果。

### Integration Tests

- AC-024-09/11/12/13：scripted runner 验证 first-pass、三种耗尽、组合 64→128、repeat/digest 写失败、预算 6912/6913 边界及不调用后续阶段。

### Regression Tests

- AC-024-14/15：024-01、023 overlay/hard/rebaseline、地图、static auditor、matrix、simulator 与冻结 SHA 全绿；正式 matrix 对象不变。

### E2E / Smoke Tests

- 真实 `run_character_parity_ladder.gd` 只运行一次有界漏斗并写 full `/tmp` + versioned compact evidence；editor import 退出 0。

### 人工验证

- 无；候选选择和停机完全由 raw gate 自动判定。

## 依赖、解锁与禁止事项

- 依赖：024-01 双阶段评审 PASS。
- 解锁：仅 `selected_128_candidate` 解锁 024-03；其他合法 paused 状态将 024-03 标记 `canceled_no_selected_128_candidate`。
- 不修改 File Manifest 外文件；不改生产 player/relic/map/level/economy、卡牌、敌人、挑战、CombatState、AI、真人 cohort、正式 matrix rows 或包体。
- 不降低/复制 hard gate，不选“最接近”，不发明 A4/E4/Y4、C2 或第 7 轮。
- 128 未全过不得运行 256；评审前不得标记完成。
