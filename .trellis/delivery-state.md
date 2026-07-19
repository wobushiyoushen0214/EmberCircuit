# EmberCircuit Delivery State

stage_state:
  state: S8_RUN_LOG
  loop_mode: L3
  audit_scope: delta
  current_round: 1
  max_rounds: 6
  open_gaps: 8
  tasks_created: 2
  tasks_completed: 2
  carry_over: 0
  critical_review_issues: 0
  next_legal_action: pause until a new strategy-diagnostic batch is explicitly confirmed
  stop_conditions:
    - Batch 020 differential gate failed: C2/C3 win-rate regression and C0/C1 chapter-one regression
---

loop_mode: L3
current_round: 1
next_loop_recommendation: pause-human-needed
carry_over: 0

## 基线

- source_requirements: `docs/00_MASTER_PLAN.md`（由 `docs/01-08` 细化）
- mvp_baseline_commit: `2e3e857`
- last_audited_commit: `d550003`（020 胜任玩家策略差分、确定性证据与停机裁决合并后）
- loop_mode: `L3`
- current_round: `1`
- max_rounds: `6`
- current_batch_id: `delivery-batch-020-competent-campaign-strategy`（策略重基线；生产数值冻结）

## 需求状态

| REQ ID | 状态 | 实现证据 | 测试证据 | 补缺任务 | 最近变化轮次 | Carry-over 次数 |
| --- | --- | --- | --- | --- | --- | --- |
| REQ-001 | DONE | `scripts/combat/CombatState.gd` | `tests/test_combat_core.gd` | none | 3 | 0 |
| REQ-002 | DONE | `scripts/main/Main.gd`, `scripts/map/MapGenerator.gd`, `data/config/level_tree.json` | `tests/test_run_flow.gd`, `tests/test_map_generator.gd`, `tests/test_map_view.gd` | none | 3 | 0 |
| REQ-003 | PARTIAL | `data/cards/cards.json`, `data/enemies/enemies.json`, `data/config/monster_scaling.json`, `scripts/tools/NumericalTreeAuditor.gd`, `scripts/tools/NumericalPressureMetrics.gd`, `scripts/tools/BalanceSimulator.gd`, `data/config/numerical_tree.json`, `docs/10_STRATEGY_DIFFERENTIAL_020.md` | `tests/test_act1_rebaseline.gd`, `tests/test_numerical_pressure_metrics.gd`, `tests/test_numerical_tree_auditor.gd`, `tests/test_balance_simulator.gd`, `tests/test_numerical_balance_matrix.gd`, `tests/test_act2_act3_rebaseline.gd` | 020 已完成 competent 差分；C2/C3 胜率回退且 C0/C1 第一章回退，状态 `paused_no_strategy_passed`，生产数值和正式矩阵继续冻结 | 1 | 0 |
| REQ-004 | PARTIAL | `data/config/player.json`, `data/config/progression_systems.json`, `data/cards/cards.json`, `scripts/main/Main.gd`, `scripts/tools/BalanceSimulator.gd`, `docs/10_STRATEGY_DIFFERENTIAL_020.md` | `tests/test_act1_rebaseline.gd`, `tests/test_progression_systems.gd`, `tests/test_combat_core.gd`, `tests/test_run_flow.gd`, `tests/test_balance_card_telemetry.gd`, `tests/test_balance_simulator.gd` | 020 已交付策略版本、决策遥测和角色/牌组感知 profile，但差分门失败；角色基础数值仍冻结 | 1 | 0 |
| REQ-005 | PARTIAL | `data/enemies/enemies.json`, `data/encounters/encounters.json`, `data/config/monster_scaling.json`, `scripts/combat/CombatState.gd`, `scripts/tools/NumericalTreeAuditor.gd`, `scripts/tools/BalanceSimulator.gd`, `scripts/main/Main.gd`, `docs/10_STRATEGY_DIFFERENTIAL_020.md` | `tests/test_act1_rebaseline.gd`, `tests/test_combat_core.gd`, `tests/test_balance_simulator.gd`, `tests/test_numerical_tree_auditor.gd`, `tests/test_run_flow.gd`, `tests/test_act2_act3_rebaseline.gd` | 020 未证明策略能跨难度稳定提升；不允许据此修改敌人，需新策略诊断批次后再讨论数值候选 | 1 | 0 |
| REQ-006 | PARTIAL | `data/cards/cards.json`, `data/relics/relics.json`, `data/events/events.json`, `data/config/art_assets.json`, `assets/art/generated/` | `tests/test_data_integrity.gd`, `tests/test_art_asset_auditor.gd` | batch-014 delivered 8 relic PNGs; next: replace remaining legacy event/enemy art | L3-5 | 0 |
| REQ-007 | DONE | `scripts/core/SaveManager.gd`, `scripts/main/Main.gd`, `data/config/achievements.json` | v5 奖励事务、原子恢复、错节点/坏 ID/金币回滚和旧战斗 HP 隔离测试 | none | L3-post | 0 |
| REQ-008 | PARTIAL | `scripts/ui/AppShell.gd`, `scripts/ui/ForgeTheme.gd`, `scripts/ui/ForgeMotion.gd`, `scripts/ui/components/`, `scripts/ui/pages/`, `scripts/main/Main.gd`, `assets/art/generated/`, `assets/fonts/NotoSansSC-Variable.ttf` | `tests/test_forge_ui_foundation.gd`, `tests/test_welcome_character_pages.gd`, `tests/test_ember_forge_route_rooms.gd`, `tests/test_ui_outcome_settings_compendium.gd`, `tests/test_visual_bounds.gd`, `tools/render_pc_gallery.gd`, `/tmp/ember018d-visual.json`, `/tmp/ember018d-performance.json` | 018D 已将 Map/Event/Shop/Campfire/Reward 真实挂入 Main→AppShell，并删除五页旧 PC 视觉树；仍保留生产内容美术与更深玩法扩展缺口 | L3-5 | 0 |
| REQ-009 | PARTIAL | `scripts/core/PlaytestTelemetry.gd`, `scripts/core/PlaytestEvidenceGate.gd`, `tools/merge_playtest_reports.gd`, `scripts/tools/BalanceSimulator.gd`, `data/config/numerical_tree.json`, `docs/10_STRATEGY_DIFFERENTIAL_020.md` | `tests/test_act1_rebaseline.gd`, `tests/test_playtest_evidence_gate.gd`, `tests/test_balance_simulator.gd`, `tests/test_numerical_balance_matrix.gd` | 020 已生成 deterministic 128 strategy differential report；结果只作 AI 诊断，正式 256 rows 与真人 cohort 继续隔离 | 1 | 0 |
| REQ-010 | MISSING | none | none | proposed: build-grid-tactics-mode | 1 | 2 |
| REQ-011 | PARTIAL | `export_presets.cfg`, `project.godot`, `packaging/PLAYTEST_README_ZH.txt` | alpha.8 Windows PE32+ x86_64 embedded-PCK、精确 PCK 启动、版本和压缩完整性通过 | next: native Windows matrix, commercial signing, installer and Steam integration | L3-post | 0 |
| REQ-012 | DONE | `tests/`, `tools/render_pc_gallery.gd`, `tools/verify_ui_visual_regression.gd`, `tools/profile_ui_performance.gd`, `tests/fixtures/ui_visual_contracts.json`, `tests/golden/ui_720p/` | 28/28 strict-log regression；11/11 1280x720 区域金标；真实 Main 600 帧 profiler；focus/motion/44px/节点增量门 | none；Windows release 目标机采样归入 REQ-011 发布门 | L3-5 | 0 |

## 当前批次

- batch_id: `delivery-batch-020-competent-campaign-strategy`（已确认；策略重基线，不改生产数值）
- scope: `建立可切换的 competent-player-v1 跑团策略、决策遥测和 128 paired differential report`
- selected_reqs:
  - `REQ-003`
  - `REQ-004`
  - `REQ-005`
  - `REQ-009`
- tasks:
  - `020-01-strategy-contract-diagnostics`（完成；C0/M0/m1）
  - `020-02-competent-player-differential-verification`（完成；C0/M0/m2；停机分支）
- result: `paused_no_strategy_passed`
- delivery_commit: `d550003`
- excluded_this_round:
  - `REQ-006/008`: 内容资产、正式音频和演出不与高风险数值批次混合
  - `REQ-012`: 仅回归，不重新设计测试基础设施
  - `REQ-010/011`: 网格战术模式、商业签名/Steam/安装器继续后续批次

## 阻塞项

| 条目 | 原因 | 需要人工提供什么 | 起始轮次 |
| --- | --- | --- | --- |
| Batch 020 strategy differential | `competent-player-v1` 在 C2/C3 胜率回退，且 C0/C1 第一章完成率下降超过 0.02；不能解锁生产数值候选 | 确认新的、独立策略诊断批次；不可直接修改生产数值 | 1 |

## 人工决策

- 2026-07-13: 用户要求安装并使用 Trellis skills 继续游戏开发。
- 2026-07-13: 用户确认 `delivery-batch-001`，并授权任务写好后直接进入开发。
- 2026-07-15: 用户授权多代理并行；本批按美术、数值、UI、测试四条工作流完成并通过主线程复核。
- 2026-07-15: 用户要求数值树合理严谨后进入 PC UI 与生图美术重构；Round 3 先固化数值和路线契约，下一批转入资产门与界面架构。
- 2026-07-15: 用户限定当前只做 PC 端体验，要求本阶段提交后生成可供他人试玩的版本，提交信息继续使用中文。
- 2026-07-15: `0.1.0-alpha.1` 作为未商业签名的内部试玩版交付；Windows 为首要测试包，macOS 通用包作为附加验证平台。
- 2026-07-15: `0.1.0-alpha.2` 加入本地匿名逐局报告；用户授权本阶段提交后打包给他人试玩，报告只手动分享、不自动上传。
- 2026-07-15: Round 6 优先修复事件页在 PC 720p 下的拥挤和廉价感，四个高频事件使用生图位图；完成后构建 `0.1.0-alpha.3` 供真人试玩。
- 2026-07-15: 用户要求继续独立 UI/美术开发并在本阶段提交后打包试玩；旧 L2 已到 6/6，按既有授权开启 L3 新 loop，首批只重构 PC 篝火与完整牌组锻造，不触碰冻结数值。
- 2026-07-15: 用户要求完成当前阶段、提交并打包给他人试玩；L3 Round 2 聚焦战败复盘和终局存档保护，版本递增到 `0.1.0-alpha.5`。
- 2026-07-16: 用户要求完成当前阶段、提交并打包给他人试玩；L3 Round 3 聚焦三章 Boss 阶段可读性和局部战场顿帧，版本递增到 `0.1.0-alpha.6`。
- 2026-07-16: 用户要求继续完成当前阶段并打包试玩；L3 Round 4 修复卡牌和敌方行动的结算顺序、重复刷新与演出期间输入，版本递增到 `0.1.0-alpha.7`。
- 2026-07-16: 用户要求完成阶段后提交并打包，同时删除旧构建节省磁盘；试玩加固批次加入奖励页事务存档，只保留 `0.1.0-alpha.8` Windows x86_64 分发包。
- 2026-07-16: 用户要求读取并接续旧会话的未完成项目；恢复 batch-014 后继续自动验证、中文提交和推送，并允许完成迁移后删除旧 session。
- 2026-07-17: 用户确认扩展 batch-015 File Manifest，同步真人报告 schema 元数据并纳入 Godot UID sidecar；证据门通过 20/20 严格回归和双阶段评审后提交推送。
- 2026-07-17: 资深 Slay the Spire 玩家反馈当前开局数值偏高、难度简单、体验无聊；用户要求重新精确计算并迭代严谨、高可玩性的数值树。该反馈重新打开 REQ-003，下一 loop 以数值重标定为唯一高风险批次。
- 2026-07-17: 用户在重基线 full audit 提交后明确回复“确认执行”，确认 `delivery-batch-016-numerical-pressure-contract`；允许创建任务、隔离 worktree，并按严格 TDD 自动推进到评审门。
- 2026-07-17: Batch 016 以严格 TDD、21/21 回归和双阶段评审交付；最终 Stage 1 PASS，Stage 2 C0/M0/m2。256-seed opening 21/21 cases 均命中过易风险，正式调值转入 Batch 017。
- 2026-07-17: 用户再次确认执行正式数值重标定；Batch 017 delta audit 冻结起始包、经济、第一章敌人和 single 默认技能书一致性。因候选含复合行动，最小扩展 intent schema 并要求完整预告，完整页面 UI 仍留 Batch 018。
- 2026-07-18: 用户明确本作为 PC 游戏，正式视觉金标限定为 1280×720 与 1600×900；更小窗口只保留外层有界和关键动作可达的兼容烟测。
- 2026-07-18: 用户授权浏览器/MCP/截图/只读审计和测试自动执行，不需要逐次确认；Batch 018A 完成提交、回写文档并合并后暂停。
- 2026-07-18: Batch 018C 已以 28/28 回归、11 页区域金标和真实 Main profiler 交付并合并；用户通过持续目标恢复 L3，要求继续严格 TDD 推进完整游戏。
- 2026-07-18: 用户明确回复“确认执行 018D”；批次拆为契约补齐、运行时挂载、视觉验证三个任务，允许创建隔离 worktree 并按严格 TDD 推进到评审门。
- 2026-07-19: 018D-03 通过双阶段评审（无 critical；Main 偏胖列为 minor），28/28 测试、11/11 区域视觉、真实 600 帧性能和五页 20 轮路由均通过；已提交并合并 master。
- 2026-07-19: 018D 后 delta audit 发现 current-greedy 三章矩阵仍 12 格低胜率，64-seed 失败集中于第一章 Boss、iron_checkpoint、cinder_kennels；修正 07 文档漂移，等待确认 019 数值批次。
- 2026-07-19: 用户明确回复“确认执行”，确认 `delivery-batch-019-campaign-pressure-rebaseline`；允许创建任务、隔离 worktree，并按严格 TDD 串行推进归因契约、二三章冻结候选重标定和 128/256 正式验证。
- 2026-07-19: Batch 019-01 归因契约完成；019-02 穷尽冻结候选并触发 stop condition，所有未通过数值已回滚；019-03 因无 selected step 取消，正式 256 rows 保持不变。用户此前要求本阶段提交合并后暂停。
- 2026-07-19: 用户确认继续执行策略重基线 Batch 020；新 loop 从第 1 轮开始，先实现 `competent-player-v1` 与决策遥测，默认 `current-greedy`、生产 JSON、正式 256 rows 和真人 cohort 均冻结。
- 2026-07-19: Batch 020 两任务以严格 TDD 和双阶段评审完成；current/competent 各 3×4×128 重复报告 byte-identical，但 competent 在 C2/C3 胜率与 C0/C1 第一章门回退，记录 `paused_no_strategy_passed`，不修改生产 JSON 或正式 256 rows。

## 预算快照

- max_batches_per_day: `1`
- max_gap_tasks_per_run: `3`
- max_high_risk_tasks_per_run: `1`
- max_carry_over_rounds_per_req: `2`
- max_verifier_failures_per_task: `2`

## 下一轮建议

- action: `pause-human-needed`
- reason: `020 的 competent-player-v1 未通过跨难度非回退门；生产数值候选继续锁定，等待确认新的策略诊断批次。`
- next_batch: `none`。
- next_audit_scope: `delta`
