# 023-01：候选 Overlay 与累计磨损归因契约

## 需求 ID

- REQ-003
- REQ-005
- REQ-009
- AC-023-01 ～ AC-023-05

## 目标

建立只作用于 `BalanceSimulator` 实例的候选 overlay 和 opt-in `attrition-v1` 报告。候选必须有 schema、allowlist、文件 SHA 和应用字段身份；无候选的历史报告保持不变，任何非法候选 fail-closed 且不得污染同一模拟器的后续运行。

## 当前缺口

- 状态：PARTIAL。
- `BalanceSimulator.load_default_data()` 直接加载生产 JSON，CLI 只有 mode/profile/iterations 等选项，没有候选隔离。
- campaign path 只记录节点结算后的 HP，case 未聚合逐层/逐遭遇进入 HP、离开 HP 和损耗。
- 风险：继续直接改生产 JSON 会重复 019 的候选回滚流程；把解析继续堆入 4192 行模拟器会扩大结构债务。

## 交付 Loop 控制

- 批次：`delivery-batch-023-layered-pressure-rebaseline`；Loop：L3；worktree/verifier：必须。
- 实现/调试/评审：`trellis-implement-tdd-zh` / `trellis-debug-systematic-zh` / `trellis-review-twostage-zh`。
- Stage 2：独立强模型；最大修复 2 次；最大调试假设 3 轮。
- 回滚：默认报告不一致、同实例数据污染、非法 path 被应用、File Manifest 越界、生产 JSON/hash 变化。

## 复杂度与规划产物

- 复杂度：中；执行模型按固定 schema 和错误码机械实现。
- 产物：`prd.md`、`design.md`、`implement.md`、`implement.jsonl`、`check.jsonl`、`tdd-progress.md`。
- `.trellis/spec/` 不存在；稳定上下文为 Round 4 audit、019 候选失败、022 v3 契约和现有 CLI/tests。

## 决策表

| 决策点 | 固定方案 | 禁止方案 |
| --- | --- | --- |
| 实现落点 | 新建纯数据 `BalanceCandidateOverlay.gd`，模拟器只接适配器 | 把校验/深合并散落进 `BalanceSimulator.gd` |
| overlay schema | `schema_version=1`、非空 `candidate_id`、非空且 path 唯一的 `changes[]` | 任意递归 merge、未知字段静默忽略 |
| change 结构 | `dataset`、`path` 字符串数组、`value` | JSON Pointer 字符串或脚本表达式 |
| 允许 dataset | `map_generation`、`level_tree`、`economy` | player/cards/enemies/challenges/numerical_tree |
| 应用方式 | 三份数据深复制后逐 path 替换；报告完成后恢复实例原引用 | 原地修改生产加载字典 |
| 报告身份 | overlay 存在时输出 schema/id/SHA/applied_fields；默认不新增字段 | 用输出文件名冒充候选身份 |
| 磨损归因 | 仅 `candidate_diagnostics=attrition-v1` 时输出 | 默认报告无条件升级 schema |
| 非法输入 | 返回固定错误码、0 cases；CLI 退出 1 且不保存成功报告 | fallback 到生产基线并退出 0 |

## Overlay 字段与校验

允许的完整 path：

- `map_generation.chapter_one.encounter_layer_bands`
- `level_tree.route_constraints.max_pressure_nodes_between_campfires`
- `level_tree.chapters.chapter_one.node_budget.campfire`
- `level_tree.chapters.chapter_two.node_budget.campfire`
- `level_tree.chapters.chapter_three.node_budget.campfire`
- `economy.campfire.heal_percent_of_max_hp`
- `economy.reward_generation.card_rarity_weights`

固定错误码：`overlay_file_missing`、`overlay_json_invalid`、`schema_version_unsupported`、`candidate_id_invalid`、`changes_empty`、`dataset_forbidden`、`path_forbidden`、`path_duplicate`、`value_invalid`。

`encounter_layer_bands` 必须是只含 `combat` key 的字典，`combat` 为非空数组；每项必须是 `{layers:[start,end], encounter_ids:[non-empty strings]}`，start/end 为非负整数、start<=end、区间不得重叠。该结构与 023-02 冻结的 MapGenerator runtime schema 一致。pressure 为 `1-4` 整数；campfire budget 是两个非负整数且 min<=max；heal 是 `1-100` 整数；rarity 必须只含 common/uncommon/rare 非负整数且合计 100。

## attrition-v1 字段

每个 campaign case 增加两个按 key 排序的数组：

- `attrition_by_layer`：`chapter_id/layer/visits/combat_visits/combat_wins/combat_deaths/hp_lost_total/avg_hp_lost/avg_hp_before/avg_hp_after`。
- `attrition_by_encounter`：`encounter_id/visits/wins/deaths/hp_lost_total/avg_hp_lost/avg_hp_before/avg_hp_after`。

只统计 combat/elite/boss。`hp_lost=max(0,hp_before-hp_after)`；死亡也使用真实结算后 HP。诊断 sample path 可增加 `layer/hp_before/hp_after/hp_lost`，无 diagnostics 时旧 path 字段集合不变。

## 文件清单

| 操作 | 文件 | 修改 |
| --- | --- | --- |
| 新建 | `scripts/tools/BalanceCandidateOverlay.gd`、`.uid` | schema/load/validate/deep-copy/apply/SHA 和固定错误码 |
| 修改 | `scripts/tools/BalanceSimulator.gd` | run 前应用隔离副本、run 后恢复；opt-in 收集并聚合 attrition-v1；默认分支不变 |
| 修改 | `tools/run_balance_simulation.gd` | 解析 `--candidate-overlay`、`--candidate-diagnostics`；rejected 时退出 1 |
| 新建 | `tests/test_balance_candidate_overlay.gd`、`.uid` | schema、allowlist、污染、CLI、默认 identity、attrition 聚合测试 |
| 新建 | `tests/fixtures/balance_candidates/valid-minimal.json` | 只把 heal 覆盖为 30 的合法 fixture |
| 新建 | `tests/fixtures/balance_candidates/invalid-forbidden.json` | 尝试修改 player 的非法 fixture |
| 修改 | 本任务 `tdd-progress.md` | 逐 AC RED→GREEN 证据 |

## 挂载点

- `run_campaign_suite(options)`：应用/恢复候选上下文并登记报告身份。
- `_run_campaign_once()`：仅 attrition-v1 捕获节点前 HP 和 layer。
- `_aggregate_campaign_case()`：仅 attrition-v1 输出两组聚合。
- `run_balance_simulation.parse_options_for_args()`：CLI 参数接入。
- CLI `_run()`：overlay rejected 时退出 1。

## MVP 兼容性契约

- 实现前生成同一 `1×1×3` v3 报告；实现后无 overlay 命令必须 `cmp` 相等。
- 默认/显式无 diagnostics 的 case/path 字段集合不变。
- overlay run 后同一 simulator 再跑默认 options，结果等于全新 simulator。
- 生产 `numerical_tree.json` SHA 保持 `1f0cc2cbf45739c8b82abb92380c91138673a716d0031be0b57c5c0eacd5845e`。

## 实现步骤与 TDD

1. AC-023-01 RED：合法 fixture 当前无法解析；写 schema/metadata 断言，再创建 helper 使其 GREEN。
2. AC-023-02 RED：非法 dataset/path/duplicate/value 当前未 fail-closed；实现固定错误码和 0-case rejection。
3. AC-023-03 RED：同实例 overlay 后默认数据被污染；实现三数据集深副本、引用恢复和 applied_fields 排序。
4. AC-023-04 RED：CLI 不识别两个参数且错误退出码不正确；接入 parser 和 rejected 分支。
5. AC-023-05 RED：attrition-v1 字段缺失；以手工三节点 run fixture 断言原始整数、平均值和排序，再接入 opt-in 聚合。
6. 运行默认 before/after `cmp`、定向测试、BalanceSimulator、map、matrix 和 editor import；最后最小收敛和双阶段评审。

## 验收标准

- AC-023-01：合法 overlay 输出 `schema_version=1`、candidate id、64 位小写 SHA 和排序 applied fields，且只作用于副本。
- AC-023-02：九类非法输入分别返回固定错误码；CLI 退出 1、case_count=0，不 fallback 成生产报告。
- AC-023-03：同实例候选→默认与全新默认报告一致；输入数据字典和生产文件字节不变。
- AC-023-04：CLI/API 参数一致；省略参数的历史调用、未知 strategy fallback 和单战模式保持原行为。
- AC-023-05：attrition-v1 按层/遭遇输出正确原始计数和三位小数均值；关闭 diagnostics 时不存在新增字段。

## 自检命令

```bash
HOME=/tmp/ember023_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
HOME=/tmp/ember023_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_candidate_overlay.gd
HOME=/tmp/ember023_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_simulator.gd
HOME=/tmp/ember023_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_map_generator.gd
HOME=/tmp/ember023_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_balance_matrix.gd
cmp /tmp/ember023-default-before.json /tmp/ember023-default-after.json
shasum -a 256 data/config/numerical_tree.json
git diff --check
```

## 依赖与解锁

- 依赖：Batch 022 已完成，v3 128/repeat 可复现。
- 解锁：`023-02-layered-pressure-and-growth-rebaseline`。

## 禁止事项

- 不修改任何生产 JSON、MapGenerator、CombatState、Main、正式 matrix 或真人报告。
- 不加入通配 allowlist、递归 merge、环境变量后门或外部依赖。
- 不把 023-02 的 P1-P5 候选值硬编码到 helper。
