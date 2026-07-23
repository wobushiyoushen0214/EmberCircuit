# 024-01：角色候选 Overlay 与版本化证据契约

## 需求 ID

- REQ-003
- REQ-004
- REQ-009
- AC-024-01 至 AC-024-06

## 目标

扩展既有 fail-closed candidate overlay，使其只通过 id selector 修改三名角色的受控开局字段和两件指定起始遗物效果；模拟器必须隔离并恢复五份数据集。同时提供 compact evidence builder，把后续 64/128/256 gate 所需的原始行、候选身份、报告 SHA、repeat 身份和 failure codes 写成可版本化 JSON。

## 当前缺口

- 当前状态：PARTIAL。
- 代码证据：`scripts/tools/BalanceCandidateOverlay.gd` 只允许 `map_generation/level_tree/economy`，`scripts/tools/BalanceSimulator.gd:_apply_candidate_overlay()` 也只传入并恢复这三份数据。
- 测试证据：`tests/test_balance_candidate_overlay.gd` 已覆盖 023 schema、实例隔离、CLI 和 attrition，但没有角色数组 id selector、遗物数组 selector或版本化 evidence。
- 缺口：`player.characters` 与 `relics.relics` 都是数组，现有 dictionary path writer 无法安全按 id 命中；023 完整报告只在 `/tmp`，重启后原始 12 行不可复核。
- 风险：数组 selector 命中错误会静默改到其他角色；只恢复三份数据会污染后续 case；只保存 SHA 而不保存 gate 输入仍无法审计晋级结论。

## 交付 Loop 控制

- 交付批次：`delivery-batch-024-character-parity-rebaseline`。
- Loop 模式：L3。
- 需要 worktree：是，固定 `/Users/lizhiwei/localProj/EmberCircuit-batch024`。
- 需要 verifier：是。
- 实现技能：`trellis-implement-tdd-zh`。
- 调试技能：`trellis-debug-systematic-zh`。
- 评审技能：`trellis-review-twostage-zh`。
- Stage 2：独立强模型；实现者不得自评完成。
- 最大修复尝试次数：2；最大调试假设轮数：3。
- 回滚触发：默认报告漂移、非目标角色/遗物被改、任一数据集未恢复、compact evidence 缺少 hard gate 输入、改动 File Manifest 外文件、评审 critical。

## 复杂度与规划产物

- 复杂度：中。
- 执行模型假设：能力有限模型也必须能按 AC 逐条机械执行。
- 必要产物：`prd.md`、`design.md`、`implement.md`、`implement.jsonl`、`check.jsonl`、`tdd-progress.md`、`review-report.md`。
- Spec 新鲜度：仓库无 `.trellis/spec/`；使用 Round 5 audit、023 overlay PRD/review、`docs/09` 与 `docs/13` 作为稳定契约。`docs/03` 的苦修香炉描述已过期，不作为 selector 数值来源。

## 上下文清单

| 类型 | 路径 | 用途 |
| --- | --- | --- |
| 现有 overlay | `scripts/tools/BalanceCandidateOverlay.gd` | 保留 schema v1、error ordering、deep copy、metadata/SHA 和 map/level/economy 行为 |
| 模拟器接线 | `scripts/tools/BalanceSimulator.gd:135` | 扩展 `_apply_candidate_overlay/_restore_candidate_overlay`，不改 campaign 结算 |
| overlay 测试 | `tests/test_balance_candidate_overlay.gd` | 复用临时 fixture、byte identity 和同实例恢复测试模式 |
| hard gate | `scripts/tools/LayeredPressureCandidateGate.gd` | compact evidence 必须保留其全部输入字段和 failure codes |
| 角色/遗物数据 | `data/config/player.json`、`data/relics/relics.json` | selector collection、id、字段类型和当前生产值来源 |
| 审计契约 | `.trellis/audits/2026-07-23-post-023-character-parity-candidate-delta-audit.md` | 固定 allowlist、候选边界与证据保存要求 |

## 决策表

| 决策点 | 选定方案 | 排除方案 | 原因 | 影响文件 |
| --- | --- | --- | --- | --- |
| Overlay schema | 继续 `schema_version=1`，用 path 的 collection/id 语义 | schema v2、任意 JSON Pointer | 保持 023 fixture 兼容，新增范围可精确 allowlist | `BalanceCandidateOverlay.gd`、`BalanceCandidateSelector.gd` |
| 角色 path | `player.characters.{character_id}.{field}` | 数组下标、整份 characters 替换 | id 稳定且不会因排序改变命中对象 | `BalanceCandidateOverlay.gd`、`BalanceCandidateSelector.gd` |
| 遗物 path | `relics.relics.{relic_id}.effects.0.amount` | 任意 effect selector、整份 relic 替换 | 024 只允许两件单效果起始遗物 | `BalanceCandidateOverlay.gd`、`BalanceCandidateSelector.gd` |
| Selector 失败 | 0 个命中=`selector_not_found`；多个命中=`selector_ambiguous` | 自动取第一条 | 重复 id 必须 fail-closed | `BalanceCandidateSelector.gd` |
| Evidence | 独立 `BalanceEvidenceDigest.gd` 输出 schema v1 compact JSON | 继续只保存 `/tmp` SHA、把逻辑塞进 runner | 允许单测并跨会话复核 | `BalanceEvidenceDigest.gd` |
| Simulator 结构 | 只在 4399 行文件增加五数据集委托/恢复 | 在模拟器内实现 selector/digest、全文件重构 | 避免继续扩大超大文件职责 | `BalanceSimulator.gd` |

## 允许路径与值契约

| Qualified path | 值类型与边界 |
| --- | --- |
| `player.characters.arc_tinker.starting_momentum` | 整数 0-5 |
| `player.characters.arc_tinker.starter_deck_ids` | 精确 10 个非空 String；允许重复卡牌 id |
| `player.characters.ember_exile.starter_deck_ids` | 精确 10 个非空 String；允许重复卡牌 id |
| `player.characters.pyre_ascetic.starter_deck_ids` | 精确 10 个非空 String；允许重复卡牌 id |
| `relics.relics.ember_bottle.effects.0.amount` | 整数 1-10 |
| `relics.relics.ash_rosary.effects.0.amount` | 整数 1-10 |

其余 player/relic path 返回 `path_forbidden`。旧七条 map/level/economy allowlist 和校验器保持不变。`applied_fields` 使用上述 qualified path 字符串并按字典序排序。

## Compact Evidence schema v1

`BalanceEvidenceDigest.build(report, gate_verdict, report_path, repeat_path="")` 返回：

- 成功：`{ok:true,digest:Dictionary,errors:[]}`。
- 失败：`{ok:false,digest:{},errors:[稳定错误码]}`。
- digest 顶层固定字段：`schema_version=1`、`source_report_path`、`source_report_sha256`、`repeat_report_path`、`repeat_report_sha256`、`repeat_identical`、`candidate_identity`、`strategy_profile`、`iterations_per_case`、`case_count`、`case_rows`、`gate_verdict`。
- `case_rows` 按 `character_id`、`challenge_level` 排序；每行固定保留 `character_id/challenge_level/runs/wins/first_act_entry_runs/first_act_completed/losses/top_encounter_id/top_encounter_failures/avg_final_gold/avg_final_deck_size`。
- `gate_verdict` 固定保留严格 boolean `eligible/pass` 和 String 数组 `failure_codes`。
- 合法 case_count 只允许 4 或 12；iterations 只允许 64、128、256；case key 必须唯一且每格 runs 等于 iterations。
- report 必须包含合法且相同的 `candidate_overlay` 与 `selected_candidate`；strategy 必须为 `competent-player-v3`、paired、80 turns、attrition-v1。
- repeat_path 非空时必须存在且与 report_path byte-identical；否则 `repeat_mismatch`。
- 稳定错误顺序：`input_missing`、`identity_mismatch`、`case_matrix_mismatch`、`gate_invalid`、`report_file_missing`、`repeat_mismatch`、`output_write_failed`。

## MVP 兼容性契约

| 已有行为 | 证据 | 必须保留 | 回归检查 |
| --- | --- | --- | --- |
| 023 五候选仍可加载 | `tests/test_balance_candidate_overlay.gd` | 是 | 原测试全绿 |
| 无 overlay 报告不含 metadata 且 byte-identical | `test_balance_candidate_overlay.gd` 同实例测试 | 是 | 新 runtime test 比较两次默认报告 |
| overlay 拒绝返回结构化错误且不污染实例 | `BalanceSimulator._campaign_overlay_rejection_report` | 是 | bad selector 后再次跑默认报告 |
| map/level/economy 仍按 deep copy 应用与恢复 | 023 overlay/rebaseline tests | 是 | 原测试与 023 gate/rebaseline tests 全绿 |

## 参考实现

- Overlay 范例：`scripts/tools/BalanceCandidateOverlay.gd:_validate_payload/_apply_path`。
- 数组 id 查找范例：`scripts/tools/BalanceSimulator.gd:_character_config`，只复用按 `id` 精确匹配语义，不复制 fallback。
- SHA 与 JSON 写入范例：`tools/run_layered_pressure_ladder.gd:_sha256_file/_write_json`。
- 测试范例：`tests/test_balance_candidate_overlay.gd` 的临时 JSON、source immutability、same-instance restore。
- 替换说明：把 generic dictionary path 的 array 段委托给新 selector；把 runner 内 SHA/摘要逻辑下沉到 evidence builder。

## 文件清单

| 操作 | 文件路径 | 说明 |
| --- | --- | --- |
| 修改 | `scripts/tools/BalanceCandidateOverlay.gd` | 扩展 dataset/allowlist/value validator，委托 id selector，保留旧行为 |
| 新建 | `scripts/tools/BalanceCandidateSelector.gd`、`.uid` | 按 collection/id 和固定尾路径安全命中/写值 |
| 新建 | `scripts/tools/BalanceEvidenceDigest.gd`、`.uid` | 校验报告/gate/repeat 并构建、写入 compact evidence |
| 修改 | `scripts/tools/BalanceSimulator.gd` | overlay 输入、赋值和恢复加入 player/relics；不改 campaign 逻辑 |
| 新建 | `tests/test_character_balance_candidate_overlay.gd`、`.uid` | AC-024-01/02 selector allowlist、命中、错误与 source immutability |
| 新建 | `tests/test_balance_evidence_digest.gd`、`.uid` | AC-024-04/05 evidence 字段、排序、malformed/repeat/I/O 边界 |
| 新建 | `tests/test_balance_candidate_runtime.gd`、`.uid` | AC-024-03/06 simulator 五数据集恢复、默认 identity 和拒绝后恢复 |
| 新建 | 本任务 `tdd-progress.md` | 逐 AC 红绿、自检与最小实现收敛记录 |
| 新建 | 本任务 `review-report.md` | 双阶段评审结论；实现阶段不得预填通过 |

## 挂载点

| 挂载点 | 类型 | 位置 | 接线动作 |
| --- | --- | --- | --- |
| player/relic datasets | candidate 输入 | `BalanceSimulator._apply_candidate_overlay` | 与旧三份数据一起传给 overlay |
| applied dataset assignment | 状态挂载 | `BalanceSimulator._apply_candidate_overlay` | 成功后替换五份实例数据 |
| dataset restoration | 生命周期 | `BalanceSimulator._restore_candidate_overlay` | 报告完成后恢复五份原始数据 |
| id selector | 计算委托 | `BalanceCandidateOverlay.load_and_apply` | player/relic path 交给 selector，错误原样 fail-closed |
| evidence writer | 验证 API | `BalanceEvidenceDigest.build/write_digest` | 024 runner 只调用此 API，不复制摘要逻辑 |

## 实现步骤与 TDD

1. AC-024-01 RED：角色/遗物合法 path 当前返回 `dataset_forbidden`；实现 dataset 和精确 allowlist/value validator，非法 path/type 仍 fail-closed。
2. AC-024-02 RED：合法 path 当前不能按 id 命中数组；实现 selector 的唯一命中、not-found/ambiguous、deep-copy 和 other-entity 不变。
3. AC-024-03 RED：模拟器不传/不恢复 player/relics；扩展薄接线，证明成功、拒绝和连续运行都不污染实例。
4. AC-024-04 RED：不存在 compact builder；实现合法 4/12 case 的原始行、排序、身份、SHA 和 gate 摘要。
5. AC-024-05 RED：malformed case/gate/repeat/I/O 未拒绝；实现稳定错误顺序和 `write_digest` 失败传播。
6. AC-024-06：运行默认 byte identity、023 overlay、layered gate/rebaseline、balance simulator 与 editor parse 回归，执行最小实现收敛。

## 验收标准

- AC-024-01：六条新 qualified path 的合法值 PASS；未知 dataset/path、错误类型、非 10 张 deck、空 card id 均返回固定错误且不产生 datasets。
- AC-024-02：selector 对 Arc/Ember/Pyre 和两件遗物各只命中一个 id；0 命中/重复 id 分别返回 `selector_not_found/selector_ambiguous`；source 和其他实体深比较不变。
- AC-024-03：合法 overlay 报告 metadata 含排序 applied_fields；同一 simulator 下一次默认报告与新实例默认报告 byte-identical；拒绝 overlay 后默认报告也相同。
- AC-024-04：4/12 case digest 字段、顺序、raw counts、first-act、failure concentration、gold/deck、candidate identity、source SHA 与 gate failures 精确等于输入。
- AC-024-05：非法 identity、重复/缺失 case、runs 不等、非法 gate、缺报告、repeat mismatch、不可写输出均返回对应稳定错误且不留下成功 digest。
- AC-024-06：原 023 overlay/gate/rebaseline 和 simulator tests 全绿；`BalanceSimulator.gd` 除五数据集薄接线外无行为修改；无新依赖。

## 自检命令

```bash
HOME=/tmp/ember024_tdd_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
HOME=/tmp/ember024_tdd_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_character_balance_candidate_overlay.gd
HOME=/tmp/ember024_tdd_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_evidence_digest.gd
HOME=/tmp/ember024_tdd_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_candidate_runtime.gd
HOME=/tmp/ember024_tdd_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_candidate_overlay.gd
HOME=/tmp/ember024_tdd_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_layered_pressure_candidate_gate.gd
HOME=/tmp/ember024_tdd_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_layered_pressure_rebaseline.gd
HOME=/tmp/ember024_tdd_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_simulator.gd
git diff --check
```

每条 Godot 命令期望退出码 0，且输出不含 `SCRIPT ERROR`、`Parse Error` 或未知 `ERROR`；`git diff --check` 无输出。

## 自动化测试要求

### Unit Tests

- `BalanceCandidateSelector`：唯一/缺失/重复 id，完整 deck、数字 index、其他实体不变。
- `BalanceEvidenceDigest`：4/12 case 合法矩阵、排序、身份、SHA、gate、repeat 和全部错误码。

### Integration Tests

- `BalanceCandidateOverlay.load_and_apply` 对五 dataset deep copy、applied_fields 和新旧 allowlist。
- 同一 `BalanceSimulator` 的 overlay→default、reject→default 序列无状态泄漏。

### Regression Tests

- 023 overlay、layered candidate gate/rebaseline 和 balance simulator 原测试全绿。
- 默认无 overlay 报告 byte-identical，不出现 candidate metadata。

### E2E / Smoke Tests

- headless editor import/parse 退出 0。

### 人工验证

- 无；本任务全部可自动化。

## 依赖

- 依赖于：Batch 024 Round 5 audit 和用户确认；无代码任务依赖。
- 原因：selector/evidence 是后续候选 runner 的基础契约。

## 解锁项

- `024-02-bounded-character-parity-calibration`。

## 范围外

- 不创建 A/E/Y fixture，不运行正式角色候选。
- 不修改生产 player/relic/map/level/economy、numerical tree、matrix、包体或文档数值。
- 不为 cards/enemies/challenges 增加 selector。
- 不重构 4399 行 simulator 的战斗、路线或奖励逻辑。

## 禁止事项

- 不改 File Manifest 外文件，不引入依赖，不改 schema version，不放宽旧 allowlist。
- 不以数组 index 代替角色/遗物 id；重复 id 不能静默取第一条。
- 不只保存 rounded rate；compact evidence 必须保存 hard gate 使用的原始整数。
- 不修改或删除 023 测试来制造绿灯。
- 未通过双阶段评审前不得标记完成或进入 024-02。

## 技术备注

- Godot 4 / GDScript；使用 `Dictionary.duplicate(true)`、`FileAccess`、`HashingContext` 和现有 JSON API。
- 新 selector 与 digest 单文件目标均低于 400 行。
- `BalanceSimulator.gd` 已超过 400 行阈值；本任务不做高风险搬迁，只允许在现有 apply/restore 区域增加薄接线，原因和边界由 design/implement 记录。
