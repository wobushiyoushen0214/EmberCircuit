# 024-03：正式 256、生产晋级与 alpha.9 试玩包

## 需求 ID

- REQ-003
- REQ-004
- REQ-005
- REQ-009
- REQ-011
- REQ-012
- AC-024-16 至 AC-024-22

## 目标

只消费 024-02 的唯一 `selected_128_candidate`，运行绑定同一 C1 identity 的 `3×4×256` primary/repeat。两份报告 byte-identical、共享 256 hard gate、report-driven matrix sync、生产快照、静态数值树、地图与全量回归全部通过后，才原子写入生产并在评审/提交后构建 `0.1.0-alpha.9` Windows PC 试玩包。任一门失败都保留证据、精确恢复 Batch 024 起点并锁住包体。

## 当前缺口

- 当前状态：PARTIAL；本任务前置是 024-02 的 selected 128 与双阶段评审。
- 代码证据：`data/config/numerical_tree.json.campaign_matrix` 仍是 current-greedy 256 baseline；023-03 的 matrix sync 仅有 PRD，因无 selected 候选而从未实现。
- 测试证据：`tests/test_numerical_balance_matrix.gd` 保护正式矩阵冻结；没有角色生产 promotion、selected-bound 256 pair、静态角色 target rebaseline、alpha.9 一致性或新包门。
- 风险：手改 matrix、只更新 `characters` 不更新默认 `player` 镜像、遗物数值与文案不一致、在失败候选上打包、或从未评审提交构建都会污染真人 cohort。

## 交付 Loop 控制

- 批次：`delivery-batch-024-character-parity-rebaseline`；Loop：L3；风险：中。
- worktree/verifier：必须；依赖 024-02 `selected_128_candidate` 且 Stage 1/独立强模型 Stage 2 无阻断。
- 若前置不满足：状态固定 `canceled_no_selected_128_candidate`，不得创建 256 artifact、修改生产、升级版本或构建。
- 实现/调试/评审：`trellis-implement-tdd-zh` / `trellis-debug-systematic-zh` / `trellis-review-twostage-zh`。
- 人工门：用户已授权数值迭代完成后构建试玩版；只有范围扩大、停止条件或商业发布动作才需重新确认。
- 最大修复 2 次；最大调试 3 轮；critical、两次 verifier 失败、File Manifest 越界立即暂停。

## 上下文清单

| 类型 | 路径 | 用途 |
| --- | --- | --- |
| selected 前置 | `.trellis/evidence/batch-024/character-parity-verdict.json` | 唯一 C1、A/E/Y、128 SHA 和 gate；不存在即取消 |
| 候选契约 | `.trellis/tasks/delivery-batch-024-character-parity-rebaseline/02-bounded-character-parity-calibration/prd.md` | 生产值、样本和冻结边界 |
| 正式 tree | `data/config/numerical_tree.json` | matrix schema、静态 targets、023/024 provenance |
| 静态审计 | `scripts/tools/NumericalTreeAuditor.gd`、`tests/test_numerical_tree_auditor.gd` | selected deck/opening score 来源与 warning 门 |
| 发布基线 | `project.godot`、`export_presets.cfg`、`scripts/main/Main.gd`、`packaging/PLAYTEST_README_ZH.txt` | alpha.8→alpha.9 四入口与 Windows 包格式 |

## 256 证据门

固定命令语义为 `competent-player-v3`、paired、80 turns、selected C1 overlay、attrition-v1、三角色、挑战 0-3、每格 256。primary `/tmp/ember024-production-256.json` 与 repeat `/tmp/ember024-production-256-repeat.json` 共 6,144 局，必须 byte-identical。

随后按顺序：

1. 024-01 `BalanceEvidenceDigest` 写 `.trellis/evidence/batch-024/024-C1-256.json`，其中绑定 primary/repeat path、SHA、12 行 raw counts、selected identity 和 failure codes。
2. 原样调用 `LayeredPressureCandidateGate.evaluate_hard(primary,256)`；目标、3%/9%/1%/50%、金币和牌组门不得改。
3. 任一 report/save/digest/repeat/hard 失败，`campaign_rebaseline_024.status=rolled_back_256_gate_failed`，保存固定 failure codes，进入回滚分支。

## 生产 Promotion 契约

新建纯 helper `CharacterParityProductionPromotion.build(...)`，输入五份生产 dictionary 与 selected C1 overlay，返回 deep-copied `{player,relics,map_generation,level_tree,economy,provenance}`；失败返回空 datasets 与固定 errors，输入不得变化。

- map：写入 B0 第一章三段 layer band。
- level tree：pressure=3；三章 campfire 都为 `[2,2]`。
- economy：heal=30；card rarity 必须仍为 `65/28/7`。
- player：只写 selected Arc momentum/deck、Ember deck、Pyre deck；若默认角色 `ember_exile` 被写，`player.player` 的 `starting_momentum/starter_deck_ids` 与 `characters[ember_exile]` 同步，其余旧镜像字段不变。
- relics：只按 selected E3/Y3 写 `ember_bottle` 5 或 `ash_rosary` 3；未 selected 的 amount 保持任务起点。数值变化时同步该遗物 `description` 与 `balance_note`，不得改 trigger/type/id。
- selected identity、applied fields 和 fixture SHA 必须等于 024-02 verdict；未知/重复角色或遗物、缺镜像、额外 path 都 fail-closed。

## 静态目标同步

角色 effect-point 描述 envelope 只能在 256 全门通过后按 selected step 使用以下冻结映射；这是生产 snapshot 同步，不参与也不替代 campaign hard gate：

| Step | deck score max | attack/skill/zero exact | opening target max |
| --- | ---: | --- | ---: |
| A1 | 73 | 5/5/4 | 78 |
| A2 | 75 | 5/5/3 | 82 |
| A3 | 75 | 4/6/3 | 82 |
| E1 | 80 | 5/5/1 | 82 |
| E2 | 80 | 5/5/1 | 82 |
| E3 | 80 | 5/5/1 | 83 |
| Y1 | 83 | 4/6/2 | 86 |
| Y2 | 90 | 4/6/1 | 93 |
| Y3 | 90 | 4/6/1 | 95 |

保持各角色现有 deck/opening lower bound，只把 `players.character_targets` 的 max/count exact 和 `pressure_contract.opening_package_targets` 的 max 更新为对应 selected 行。`NumericalTreeAuditor` 的实际 deck/opening score、结构和 relic contribution 必须与生产数据一致且 player/opening warning 均为 0。

## Matrix Sync 契约

实现 `CampaignMatrixSync.build_synced_tree(tree, static_report, primary, repeat, selected_verdict, hard_verdict)`：

- exact 12-case 256、v3/paired/80、identity/repeat/hard PASS、全部 case `risk_flag=ok` 才成功。
- 按 `character_id:challenge_level` 映射；每行 `observed_win_rate/avg_final_gold/avg_final_deck_size/risk_flag` 来自 primary case。
- `starter_deck_score` 来自 `static_report.players[id]`；其他静态行字段 deep-preserve。
- matrix 固定 schema 2、`competent-player-v3`、256、paired、80、原角色/挑战轴；三组 expected issue/cell 数组只在 hard PASS 后清空。
- 写 `campaign_rebaseline_024` 的 selected A/E/Y/C1、primary/repeat/digest path+SHA、hard raw verdict、production/matrix/package flags。
- 固定 errors：`selected_candidate_missing`、`report_missing`、`report_json_invalid`、`report_repeat_mismatch`、`strategy_profile_mismatch`、`candidate_identity_mismatch`、`required_iterations`、`case_matrix_mismatch`、`hard_gate_failed`、`risk_flags_present`、`static_report_invalid`、`matrix_source_row_missing`、`output_validation_failed`。
- CLI `tools/sync_campaign_matrix.gd` 默认 dry-run；只有显式 `--apply` 才以临时文件重解析后原子替换 tree。失败退出 1 且 tree byte-identical。

## 失败回滚

任何 256、promotion、sync、静态、地图、回归或评审门失败时，五份生产数据与正式 matrix 在语义对象级恢复任务起点：无 layer band、pressure 4、三章 `[1,2]`、heal 25、rarity `65/28/7`、原三角色开局和 relic amounts 3/1、current-greedy 256 matrix 与原 expected arrays。只允许 `campaign_rebaseline_024`、docs/14 和 compact evidence记录失败；`production_applied=false`、`matrix_updated=false`、`playtest_package_eligible=false`，版本仍 alpha.8，build 目录不新增 alpha.9。

## alpha.9 发布门

只有 production/matrix/static/map/full regression/Stage 1/独立 Stage 2 全过，外层控制器提交并合并该 source 后才允许：

- `project.godot config/version="0.1.0.9"`。
- `scripts/main/Main.gd PLAYTEST_BUILD_LABEL="0.1.0-alpha.9"`。
- `export_presets.cfg` 的 macOS build number 9（即使本轮只分发 Windows，也保持版本入口一致）。
- `packaging/PLAYTEST_README_ZH.txt` 标题/重点体验/已知限制同步 alpha.9 与本次数值变化。
- Windows release export 为 embedded-PCK x86_64；输出目录名 `EmberCircuit-0.1.0-alpha.9-Windows-x86_64-${SOURCE_SHA7}`，内含 `EmberCircuit.exe`、README、`SHA256SUMS.txt`，最终 zip 同名。
- `unzip -t`、zip 内 SHA、`file` 的 PE32+ x86-64、`Godot --main-pack ${EXE_PATH} --headless --quit-after 2`、资源排除、四处版本一致和 archive SHA 全过。
- 构建文件只写 `build/`，不进入 Git；保留 alpha.8，除非用户另行要求删除。

## 参考实现

- Pure matrix/CLI 边界：`.trellis/tasks/delivery-batch-023-layered-pressure-rebaseline/03-production-matrix-verification/prd.md`；该任务未执行，只复用已评审的接口边界并替换成 024 前置。
- Atomic JSON 写入与 SHA：`tools/run_layered_pressure_ladder.gd:_write_json/_sha256_file`。
- 默认角色镜像一致性：`scripts/tools/NumericalTreeAuditor.gd:_legacy_player_matches_character`。
- keyed matrix 与冻结断言风格：`tests/test_numerical_balance_matrix.gd`。
- alpha.8 包内容与版本入口：提交 `61a13ae` 和 `build/EmberCircuit-0.1.0-alpha.8-Windows-x86_64-61a13ae.zip`。

## MVP 兼容性契约

- cards/enemies/encounters/challenges/CombatState/AI 规则/真人 cohort/UI/美术音频不变。
- AI 256 artifact 不进入真人 12/30 cohort；alpha.9 因配置指纹和 game version 形成新 cohort。
- matrix rows 不得手改；dry-run/拒绝分支不改 tree；生产 helper 不改输入。
- 保存/奖励/三章流程和 PC 1280×720/1600×900 继续由全量 `tests/test_*.gd` 保护。

## 文件清单

| 操作 | 文件路径 | 精确用途 |
| --- | --- | --- |
| 新建 | `scripts/tools/CharacterParityProductionPromotion.gd`、`.uid` | selected-bound 五数据集 pure promotion/rollback validation |
| 新建 | `scripts/tools/CampaignMatrixSync.gd`、`.uid` | 256/static report-driven matrix deep copy |
| 新建 | `tools/sync_campaign_matrix.gd`、`.uid` | dry-run/apply、临时校验与原子 tree 写入 |
| 新建 | `tests/test_character_parity_production_promotion.gd`、`.uid` | selected path、legacy mirror、relic文案、非法输入与不修改参数 |
| 新建 | `tests/test_campaign_matrix_verification.gd`、`.uid` | 128拒绝、repeat/identity/hard/static/row mapping、dry-run/apply |
| 条件新建 | `.trellis/evidence/batch-024/024-C1-256.json`、`production-verdict.json` | 真实 256 compact evidence 与最终分支 |
| 条件修改 | `data/config/map_generation.json`、`level_tree.json`、`economy.json` | PASS 写 B0；FAIL 精确起点 |
| 条件修改 | `data/config/player.json`、`data/relics/relics.json` | PASS 写 selected 角色/遗物和 legacy mirror；FAIL 起点 |
| 修改 | `data/config/numerical_tree.json` | PASS 静态目标、正式 matrix、024 provenance；FAIL 只记失败证据 |
| 修改 | `tests/test_numerical_tree_auditor.gd`、`tests/test_numerical_balance_matrix.gd` | selected 静态 score/target 与 PASS/rollback matrix |
| 修改 | `tests/test_map_generator.gd`、`tests/test_playtest_evidence_gate.gd` | 生产 B0 地图和 AI/真人 cohort 隔离 |
| 修改 | `docs/03_CONTENT_AND_BALANCE.md`、`docs/09_NUMERICAL_TREE_AND_BALANCE.md`、`docs/14_CHARACTER_PARITY_REBASELINE_024.md` | 实际生产 snapshot、256 raw evidence 与结论 |
| 修改 | `docs/06_IMPLEMENTATION_LOG.md`、`docs/07_CURRENT_STATE_AND_NEXT_STEPS.md` | 交付/回滚、包体 SHA 与 next action |
| 条件修改 | `project.godot`、`export_presets.cfg`、`scripts/main/Main.gd`、`packaging/PLAYTEST_README_ZH.txt` | 仅 PASS/评审后升级 alpha.9 |
| 修改 | `.trellis/delivery-state.md`、`.trellis/delivery-run-log.jsonl` | 最终批次状态和 artifact provenance |
| 修改 | 本任务 `tdd-progress.md` | RED/GREEN、256 SHA、回归、评审和包体验证 |
| 新建 | 本任务 `review-report.md` | 双阶段评审；实现者不得预填通过 |
| 条件生成 | `build/EmberCircuit-0.1.0-alpha.9-Windows-x86_64-${SOURCE_SHA7}.zip` | 忽略的试玩包，不进 Git |

## 挂载点

1. 024-02 verdict/evidence 控制唯一 selected C1 与 256 前置。
2. `LayeredPressureCandidateGate.evaluate_hard(...,256)` 控制唯一正式数值门。
3. `CharacterParityProductionPromotion` 控制五数据集 production snapshot。
4. `CampaignMatrixSync` + CLI `--apply` 控制唯一正式 matrix 写入。
5. version/README/export 四入口与 build archive 控制新真人 cohort 和可分发包。

## 实现步骤与 TDD

1. AC-024-16 RED：selected/identity/256 前置未固化；写 missing/wrong/128 与合法 256 fixture，再实现 fail-closed validation。
2. AC-024-17 RED：promotion 不存在；实现 five-dataset deep copy、legacy mirror、relic文案和非法 path/duplicate ID 拒绝。
3. AC-024-18 RED：repeat/shared hard/digest 未接；验证 byte identity、256 hard 全边界与 compact evidence。
4. AC-024-19 RED：report-driven sync 不存在；实现 static score + keyed matrix mapping、dry-run/no-write/apply。
5. AC-024-20 RED：PASS/FAIL 生产分支未固化；实现 selected static target mapping、完整 promotion 或精确 rollback。
6. AC-024-21：运行真实 256 pair，按唯一真实分支写 production/tree/docs/evidence，跑静态、地图、数值和全量严格回归。
7. AC-024-22：Stage 1 与独立强模型 Stage 2 无阻断后，由外层提交/合并；仅 PASS 构建并验证 alpha.9，回写 artifact SHA 后提交推送。

## 验收标准

- AC-024-16：无 selected 时任务取消且零写入；有 selected 时只生成绑定同一 C1 的两份 12×256 artifact。
- AC-024-17：pure promotion 精确应用 B0/A/E/Y，默认 Ember mirror 一致，relic数值/文案一致；非法输入不改参数。
- AC-024-18：primary/repeat byte-identical；compact digest 绑定两 SHA；共享 256 hard 全部门 PASS。
- AC-024-19：sync 每个固定非法输入 fail-closed；合法时四个 observed 字段来自 report、starter score 来自 static report、其他字段保持。
- AC-024-20：PASS 五数据集/tree/matrix/docs 同一 snapshot且 static 0 player/opening warnings；FAIL 精确起点、matrix 不变、package=false。
- AC-024-21：地图 32 seeds、NumericalTreeAuditor、matrix、全部 `tests/test_*.gd` 严格日志、AI/真人隔离和冻结文件通过。
- AC-024-22：Stage 1/2 无阻断；只有 PASS 产生 alpha.9 zip，版本/架构/embedded PCK/启动/排除/压缩/SHA 全过，build 不入 Git。

## 自检命令

```bash
HOME=/tmp/ember024_release_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
HOME=/tmp/ember024_release_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_character_parity_production_promotion.gd
HOME=/tmp/ember024_release_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_campaign_matrix_verification.gd
cmp /tmp/ember024-production-256.json /tmp/ember024-production-256-repeat.json
HOME=/tmp/ember024_release_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tools/sync_campaign_matrix.gd -- --report=/tmp/ember024-production-256.json --repeat-report=/tmp/ember024-production-256-repeat.json --tree=res://data/config/numerical_tree.json --dry-run
HOME=/tmp/ember024_release_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_tree_auditor.gd
HOME=/tmp/ember024_release_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_balance_matrix.gd -- --require-024-production-artifacts
HOME=/tmp/ember024_release_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_map_generator.gd
HOME=/tmp/ember024_release_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_playtest_evidence_gate.gd
for test in tests/test_*.gd; do HOME=/tmp/ember024_all_tests /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://$test || exit 1; done
shasum -a 256 data/cards/cards.json data/enemies/enemies.json data/encounters/encounters.json data/config/challenges.json scripts/combat/CombatState.gd
git diff --check
```

PASS 且评审/源码提交后，构建命令由外层执行：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --export-release "Windows PC" /tmp/ember024-alpha9/EmberCircuit.exe
file /tmp/ember024-alpha9/EmberCircuit.exe
HOME=/tmp/ember024_package_home /Applications/Godot.app/Contents/MacOS/Godot --headless --main-pack /tmp/ember024-alpha9/EmberCircuit.exe --quit-after 2
unzip -t build/EmberCircuit-0.1.0-alpha.9-Windows-x86_64-${SOURCE_SHA7}.zip
shasum -a 256 build/EmberCircuit-0.1.0-alpha.9-Windows-x86_64-${SOURCE_SHA7}.zip
```

`SOURCE_SHA7` 是发布阶段用 `git rev-parse --short=7 HEAD` 从已评审源码提交机械取得的变量，不是执行模型自由选择；源码 PRD 不预填未知 commit。

## 自动化测试要求

### Unit Tests

- AC-024-16/17：promotion 对 missing/wrong selection、额外 path、重复 ID、每个 A/E/Y 分支、legacy mirror 和输入 immutability 给出精确结果。
- AC-024-18/19：sync 对 128、repeat mismatch、wrong identity、hard fail、static missing、duplicate/missing row、risk flag 与合法 256 mapping 给出固定 error 或 deep-copied tree。

### Integration Tests

- AC-024-19/20：CLI dry-run 绝不写 tree；`--apply` 只接受合法 256 pair，并验证临时 tree 可重解析、production/static/matrix snapshot 一致。

### Regression Tests

- AC-024-20/21：NumericalTreeAuditor、matrix、地图 32 seeds、真人 evidence gate、全部 `tests/test_*.gd` 和五个冻结文件保护 PASS/rollback 两分支。

### E2E / Smoke Tests

- AC-024-21：真实 selected 256 primary/repeat、digest、hard、唯一 apply/rollback。
- AC-024-22：Windows release export、PE32+ x86-64、embedded PCK 隔离启动、资源排除、zip integrity、inner/archive SHA 与四处版本一致。

### 人工验证

- 不以人工目测替代数值门；试玩包交付后由真人另行评测，反馈进入新 cohort，不影响本任务自动验收。

## 依赖、范围外与禁止事项

- 依赖：024-02 selected 128 + 双阶段评审。
- 解锁：PASS 后交付 alpha.9 真人试玩；FAIL 后只解锁新 delta audit。
- 不改候选、targets/hard tolerances、CombatState、卡牌、敌人、挑战、AI、真人数据、UI/资产；不创建第二套 hard gate。
- 不手改 report/matrix observed/SHA/expected arrays；不在评审前提交或打包；不删除 alpha.8。
