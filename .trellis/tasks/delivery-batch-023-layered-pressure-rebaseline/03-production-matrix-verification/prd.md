# 023-03：正式 256 矩阵与生产候选验证

## 需求 ID

- REQ-003
- REQ-004
- REQ-005
- REQ-009
- AC-023-13 ～ AC-023-17

## 目标

仅当 023-02 选出 128 candidate 后，运行 `competent-player-v3` 3×4×256 和同命令 repeat。复用同一 raw hard gate，由工具报告同步正式 matrix，并把报告 SHA 绑定到生产裁决。256 失败时恢复 Batch 023 起点的全部候选生产值、保持正式 matrix 不变，并继续锁定试玩包。

## 前置条件

- 023-01 与 023-02 的 Stage 1/Stage 2 无阻断。
- `campaign_rebaseline_023.status=selected_128_candidate`，且 `selected_step` 精确属于 P1-P5。
- selected 128 report/repeat byte-identical，candidate ID/SHA 与对应 overlay 文件一致，023-02 hard verdict 为 PASS。
- 运行 256 前，生产 `map_generation.json/level_tree.json/economy.json` 精确等于 selected overlay changes。
- 任一前置不成立时，将本任务标记为 `canceled_no_selected_128_candidate`；不得创建 256 artifact、不得修改正式 matrix、不得打包。

## 当前缺口

- 状态：PARTIAL；正式 `campaign_matrix` 仍是 Batch 017 的 `current-greedy` 256 基线，带 12 个预期失败格。
- 代码/测试证据：`data/config/numerical_tree.json` 的 `campaign_matrix`、`tests/test_numerical_balance_matrix.gd` 的 current-greedy/hash freeze、`docs/09_NUMERICAL_TREE_AND_BALANCE.md` 的正式矩阵说明。
- 019 的 report-driven matrix sync 任务因无 selected candidate 被取消，仓库目前没有防止手改 observed rows 的同步工具。
- 风险：只信任 report summary、把 128 报告同步成正式矩阵，或 256 失败后保留生产候选，都会形成伪正式基线。

## 交付 Loop 控制

- 批次：`delivery-batch-023-layered-pressure-rebaseline`；Loop：L3；worktree/verifier：必须。
- 依赖：023-02 selected 128 candidate 且双阶段评审 PASS。
- 实现/调试/评审：`trellis-implement-tdd-zh` / `trellis-debug-systematic-zh` / `trellis-review-twostage-zh`。
- Stage 2：独立强模型；最大修复 2 次；最大调试假设 3 轮。
- 回滚：报告不一致、任一 256 gate 失败、正式 exception 非空、手改 observed、AI/真人混写、File Manifest 越界、回归失败或 review critical。

## 复杂度与规划产物

- 复杂度：中；报告生成耗时，但校验和变换必须是纯数据、有界实现。
- 产物：`prd.md`、`design.md`、`implement.md`、`implement.jsonl`、`check.jsonl`、`tdd-progress.md`；执行期补 verification/review reports。
- 稳定上下文：023-02 selected verdict、019-03 已取消的 sync 设计、正式 matrix 契约和 AI/真人证据隔离规则。
- `.trellis/spec/` 不存在；以上任务产物、正式 JSON 契约和现有 tests 是本任务稳定 spec。

## 参考实现

- 仅读取 `.trellis/tasks/delivery-batch-019-campaign-pressure-rebaseline/03-campaign-matrix-verification/prd.md` 与 `design.md` 的 report-driven 边界；该任务已取消，仓库没有可照抄的 sync 代码。
- 纯 helper 的 schema/errors/deep-copy 风格照 023-01 交付后的 `scripts/tools/BalanceCandidateOverlay.gd`，只替换为 matrix axis 和 row mapping；不得复用其 overlay allowlist。
- CLI 参数解析照 `tools/run_balance_simulation.gd.parse_options_for_args()`，新增参数只属于 `sync_campaign_matrix.gd`，不得修改 simulation CLI 的历史语义。
- Matrix 断言照 `tests/test_numerical_balance_matrix.gd`，把过时 current-only freeze 改成明确 PASS/rollback 双分支，其他 target/static inventory 检查保持不变。

## 决策表

| 决策点 | 固定方案 | 禁止方案 |
| --- | --- | --- |
| 正式 profile | `competent-player-v3` | 通过后仍保留 `current-greedy` 或重命名 profile |
| 样本模型 | 3 角色×C0-C3×精确 256、80 turns、`paired_by_iteration` | 64/128、缺格、非 paired 或混合 options |
| 候选身份 | 从 `campaign_rebaseline_023.selected_step` 读取并解析 `023-{step}.json`，report ID/SHA 必须一致 | 操作者另传未绑定 overlay |
| Repeat | 同 options、同 candidate，两个 report 文件 byte-identical | 只比较语义 JSON 或忽略字段顺序 |
| Hard gate | 复用 `LayeredPressureCandidateGate.evaluate_hard(report, 256)` | 复制阈值或只信 `summary.target_pass` |
| Matrix 来源 | 纯 `CampaignMatrixSync` 从通过的 256 report 变换 | 手改 observed/economy/risk |
| 通过结果 | 同步 v3 正式 matrix，三个 expected issue/cell 数组清空 | 保留过时 expected exceptions |
| 失败结果 | 恢复精确 023 起点生产值，正式 matrix 保持任务起点 | 失败候选留在生产或同步部分 rows |
| 真人证据 | AI report 与 real-human cohort 严格隔离 | 把 256 AI runs 当真人试玩证据 |

## 256 Artifact 契约

执行命令机械读取 selected step，不允许操作员自由选择 P1-P5：

```bash
SELECTED_STEP="$(jq -r '.campaign_rebaseline_023.selected_step' data/config/numerical_tree.json)"
OVERLAY_PATH="res://tests/fixtures/balance_candidates/023-${SELECTED_STEP}.json"
HOME=/tmp/ember023_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tools/run_balance_simulation.gd -- --mode=campaign --strategy-profile=competent-player-v3 --candidate-overlay="$OVERLAY_PATH" --candidate-diagnostics=attrition-v1 --iterations=256 --max-turns=80 --characters=ember_exile,arc_tinker,pyre_ascetic --challenges=0,1,2,3 --output=/tmp/ember023-production-256.json
HOME=/tmp/ember023_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tools/run_balance_simulation.gd -- --mode=campaign --strategy-profile=competent-player-v3 --candidate-overlay="$OVERLAY_PATH" --candidate-diagnostics=attrition-v1 --iterations=256 --max-turns=80 --characters=ember_exile,arc_tinker,pyre_ascetic --challenges=0,1,2,3 --output=/tmp/ember023-production-256-repeat.json
```

两份 artifact 必须包含 12 个唯一角色/挑战 case、每格 256 runs、精确 selected candidate metadata、完整 attrition-v1、全部 attribution eligible，并且文件字节和 SHA-256 相同。

## Matrix Sync 契约

新建纯 helper `CampaignMatrixSync.gd` 与薄 CLI `sync_campaign_matrix.gd`：

- helper 输入当前 numerical tree、primary/repeat report、selected verdict 和 256 hard-gate verdict。
- 拒绝缺格/重复格、非 256、错误 strategy/seed/turn horizon、identity 不同、repeat 不同、hard gate 失败或任一 case `risk_flag != ok`。
- 按 `character_id:challenge_level` key 保留每行全部静态字段，只替换 `observed_win_rate`、`avg_final_gold`、`avg_final_deck_size`、`risk_flag`。
- 设置 `campaign_matrix.strategy_profile=competent-player-v3`，保持 schema 2、256 iterations、80 turns、paired seed 和现有轴顺序的 12 rows。
- 仅在独立 256 hard gate 全过后，把 `expected_target_issues`、`expected_out_of_tolerance_cells`、`expected_flagged_cells` 设为空数组。
- 在 `campaign_rebaseline_023` 记录 primary/repeat path/SHA、candidate ID/SHA、`production_applied`、`matrix_updated`、`playtest_package_eligible`；不得写入 `human_playtest_targets` 或真人报告。
- CLI 先写临时 tree、重新解析并验证，只有显式 `--apply` 才原子替换 `data/config/numerical_tree.json`；失败退出 1 且 tree byte-identical。

固定 sync errors：`selected_candidate_missing`、`report_missing`、`report_json_invalid`、`report_repeat_mismatch`、`strategy_profile_mismatch`、`candidate_identity_mismatch`、`required_iterations`、`case_matrix_mismatch`、`hard_gate_failed`、`risk_flags_present`、`matrix_source_row_missing`、`output_validation_failed`。

## 失败回滚契约

任一 256 生成、byte compare、hard gate、sync validation 或回归失败时：

- 从 `map_generation.json` 删除 `chapter_one.encounter_layer_bands`。
- 恢复 `max_pressure_nodes_between_campfires=4`，三章 campfire budget 全部 `[1,2]`。
- 恢复篝火 heal=25，卡牌稀有度 `common/uncommon/rare=65/28/7`。
- 正式 `campaign_matrix` 在语义对象级精确保持任务起点：current-greedy、256、paired、12 rows 和原 expected exceptions。
- 设置 `campaign_rebaseline_023.status=rolled_back_256_gate_failed`，保留 selected step 与报告证据，并设置 `production_applied=false`、`matrix_updated=false`、`playtest_package_eligible=false`。
- 文档记录精确 failure codes；该分支不得构建试玩包。

## 文件清单

| 操作 | 文件 | 精确修改 |
| --- | --- | --- |
| 新建 | `scripts/tools/CampaignMatrixSync.gd`、`.uid` | 纯 report 校验、keyed row 变换、固定错误和输出验证 |
| 新建 | `tools/sync_campaign_matrix.gd`、`.uid` | CLI、SHA/byte repeat、dry-run/apply、临时写入和原子替换 |
| 新建 | `tests/test_campaign_matrix_verification.gd`、`.uid` | 128 拒绝、轴/身份/repeat/gate 边界、精确 row mapping、失败不写入和回滚断言 |
| 修改 | `data/config/numerical_tree.json` | PASS 同步 v3 正式 matrix；FAIL 只写 023 回滚证据且正式 matrix 不变 |
| 256 失败时条件修改 | `data/config/map_generation.json` | 删除 candidate layer band |
| 256 失败时条件修改 | `data/config/level_tree.json` | 恢复 pressure 4 和三章 `[1,2]` 篝火预算 |
| 256 失败时条件修改 | `data/config/economy.json` | 恢复 heal 25 与 rarity 65/28/7 |
| 修改 | `tests/test_numerical_balance_matrix.gd` | 把旧 freeze 断言改为 PASS/rollback 分支契约与 report provenance |
| 修改 | `docs/13_LAYERED_PRESSURE_REBASELINE_023.md` | 写 256 命令、SHA、gate、matrix/rollback 状态与 package eligibility |
| 修改 | `docs/09_NUMERICAL_TREE_AND_BALANCE.md` | 仅 PASS 更新正式 strategy/matrix，否则记录保留旧基线 |
| 修改 | `docs/07_CURRENT_STATE_AND_NEXT_STEPS.md` | 写 delivered 或 rolled-back 数值状态与 next legal action |
| 修改 | `.trellis/delivery-state.md`、`.trellis/delivery-run-log.jsonl` | 批次结果、REQ 证据与 next action |
| 修改 | 本任务 `tdd-progress.md` | 真实 RED→GREEN、artifact SHA、回归和评审证据 |

## 挂载点

- `run_balance_simulation.gd`：以相同 options 生成两份 selected-candidate 256 report。
- `LayeredPressureCandidateGate.evaluate_hard(report, 256)`：唯一 256 阈值计算。
- `CampaignMatrixSync.build_synced_tree(...)`：唯一 observed/economy/risk row 变换。
- `sync_campaign_matrix.gd --apply`：唯一正式 matrix 写入入口。
- `test_numerical_balance_matrix.gd`：绑定生产配置、selected verdict、report provenance 和正式 matrix。

## MVP 兼容性契约

- sync dry-run 与全部拒绝分支保持 `numerical_tree.json` byte-identical。
- Matrix 静态字段、target ranges、角色/挑战轴、campaign/pressure targets、challenge、玩家/卡牌/敌人/遭遇数据和 `CombatState.gd` 不变。
- 256 失败精确恢复上述 Batch 023 起点生产值。
- AI artifact 不修改真人 cohort，也不能满足真人试玩样本门。

## 实现步骤与 TDD

1. AC-023-13 RED：precondition/selected identity 尚无校验；添加 missing selection、wrong SHA、128 input 和合法 selected 256 纯 fixture，再实现 fail-closed validation。
2. AC-023-14 RED：repeat mismatch 与精确 256 hard gate 未接；复用 023-02 gate，证明全部既有 hard threshold/failure code 仍生效。
3. AC-023-15 RED：report-driven sync 不存在；实现 keyed transformation 和 CLI dry-run/apply，证明静态字段保持且四个 observed 字段来自 report case。
4. AC-023-16 RED：PASS/FAIL 生产分支未固化；实现 PASS metadata/空 exception 和精确失败回滚，含失败不改 matrix。
5. AC-023-17：生成真实 primary/repeat，记录 SHA，执行 sync 或 rollback 唯一分支，跑完整数值/静态/campaign/真人隔离回归，再做 Stage 1 与独立 Stage 2。

## 验收标准

- AC-023-13：无 selected 128 时任务取消且无 256 文件；有 selected 时精确生成两份 bound 3×4×256 v3 artifact。
- AC-023-14：primary/repeat byte-identical；`evaluate_hard(...,256)` 用 raw counts 通过目标、3% 单格、9% 角色差、1% 单调、50% 失败集中、金币 100-180、牌组 16-19 全部门。
- AC-023-15：sync 对每个固定非法输入 fail-closed 且不写文件；通过时从 report 精确映射 12 rows，不手改 observed。
- AC-023-16：PASS 得到 v3/256/paired matrix、三个 expected 数组为空、rows risk 全为 `ok`、package eligible=true；FAIL 精确恢复起点生产值、旧 matrix 不变、package eligible=false。
- AC-023-17：冻结 SHA 不变；editor、完整数值/静态/map/campaign、AI/真人隔离、文档、Stage 1 和独立 Stage 2 无阻断。

## 自动化测试要求

### Unit Tests

- `CampaignMatrixSync.build_synced_tree()`：合法 12-case 256 输入精确替换四字段并保持静态字段；每个固定 error 输入返回对应 code 且不修改参数。
- `LayeredPressureCandidateGate.evaluate_hard(report, 256)`：目标上下界、3%/9%/1%/50%、金币/牌组边界各有一条 PASS 与一条 FAIL 断言。

### Integration Tests

- `sync_campaign_matrix.gd --dry-run` 对合法 artifact 退出 0 且不写 tree；128、repeat mismatch、缺格、wrong identity、risk 非 ok 分别退出 1 且 tree SHA 不变。
- `--apply` 只接受已通过 hard verdict 的 256 pair，输出可重新解析且 12 rows 与 report case key 一一对应。

### Regression Tests

- `test_numerical_balance_matrix.gd` 覆盖 PASS/rollback 两种生产状态、静态 row 字段、campaign targets、expected arrays 与 report provenance。
- Map、BalanceSimulator、NumericalTreeAuditor 和六个 frozen SHA 保持本批兼容性契约。

### E2E / Smoke

- 真实 selected candidate 生成 256/repeat、byte compare、dry-run、唯一 apply/rollback 分支和完整回归；AI report 不改变 `test_playtest_evidence_gate.gd` 的真人样本状态。

## 自检命令

```bash
HOME=/tmp/ember023_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
HOME=/tmp/ember023_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_campaign_matrix_verification.gd
cmp /tmp/ember023-production-256.json /tmp/ember023-production-256-repeat.json
HOME=/tmp/ember023_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tools/sync_campaign_matrix.gd -- --report=/tmp/ember023-production-256.json --repeat-report=/tmp/ember023-production-256-repeat.json --tree=res://data/config/numerical_tree.json --dry-run
HOME=/tmp/ember023_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_balance_matrix.gd -- --require-023-production-artifacts
HOME=/tmp/ember023_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_tree_auditor.gd
HOME=/tmp/ember023_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_map_generator.gd
HOME=/tmp/ember023_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_simulator.gd
HOME=/tmp/ember023_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_playtest_evidence_gate.gd
shasum -a 256 data/config/player.json data/cards/cards.json data/enemies/enemies.json data/encounters/encounters.json data/config/challenges.json scripts/combat/CombatState.gd
git diff --check
```

## 依赖与解锁

- 依赖：023-02 selected 128 candidate 且双阶段评审 PASS。
- 解锁：256 PASS 时解锁 Batch 023 完成和独立的最新试玩版打包步骤；FAIL 时只解锁 delta audit。

## 范围外与禁止事项

- 不调 P1-P5、不加 P6、不改 targets/tolerances，也不改 combat/AI 行为。
- 不手改 report、SHA、observed/economy/risk rows 或 expected exception arrays。
- 不修改冻结玩家/卡牌/敌人/遭遇/challenge/CombatState、真人报告、UI、资产、音频、发布配置或包体。
- AC-023-16 未明确 PASS 并设置 `playtest_package_eligible=true` 前不得打包。
- verifier 与双阶段评审前不得标记完成。
