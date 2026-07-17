# EmberCircuit Delivery State

stage_state:
  state: S8_RUN_LOG
  loop_mode: L3
  audit_scope: delta
  current_round: 3
  max_rounds: 6
  open_gaps: 8
  tasks_created: 3
  tasks_completed: 2
  carry_over: 3
  critical_review_issues: 0
  next_legal_action: pause after merging Batch 018A; resume with delivery-batch-018b-run-pages when requested
  stop_conditions: none
---

loop_mode: L3
current_round: 3
next_loop_recommendation: await-user-resume
carry_over: 3

## 基线

- source_requirements: `docs/00_MASTER_PLAN.md`（由 `docs/01-08` 细化）
- mvp_baseline_commit: `2e3e857`
- last_audited_commit: `4032b8d`
- loop_mode: `L3`
- current_round: `3`
- max_rounds: `6`
- current_batch_id: `delivery-batch-018a-ui-shell-menu-pages`

## 需求状态

| REQ ID | 状态 | 实现证据 | 测试证据 | 补缺任务 | 最近变化轮次 | Carry-over 次数 |
| --- | --- | --- | --- | --- | --- | --- |
| REQ-001 | DONE | `scripts/combat/CombatState.gd` | `tests/test_combat_core.gd` | none | 3 | 0 |
| REQ-002 | DONE | `scripts/main/Main.gd`, `scripts/map/MapGenerator.gd`, `data/config/level_tree.json` | `tests/test_run_flow.gd`, `tests/test_map_generator.gd`, `tests/test_map_view.gd` | none | 3 | 0 |
| REQ-003 | PARTIAL | `data/cards/cards.json`, `data/enemies/enemies.json`, `data/config/monster_scaling.json`, `scripts/tools/NumericalTreeAuditor.gd`, `scripts/tools/NumericalPressureMetrics.gd`, `data/config/numerical_tree.json` | `tests/test_act1_rebaseline.gd`, `tests/test_numerical_pressure_metrics.gd`, `tests/test_numerical_tree_auditor.gd`, `tests/test_balance_simulator.gd`, `tests/test_numerical_balance_matrix.gd` | Batch 017 第一章与开局重标定已通过 22/22 和双阶段评审；二三章仍为后续数值缺口 | L3-new-2 | 0 |
| REQ-004 | PARTIAL | `data/config/player.json`, `data/config/progression_systems.json`, `data/cards/cards.json`, `scripts/main/Main.gd` | `tests/test_act1_rebaseline.gd`, `tests/test_progression_systems.gd`, `tests/test_combat_core.gd`, `tests/test_run_flow.gd`, `tests/test_balance_card_telemetry.gd` | Batch 017 三角色 opening package、金币和 Arc 行动密度已交付；更深角色构筑继续保留后续扩展 | L3-new-2 | 1 |
| REQ-005 | PARTIAL | `data/enemies/enemies.json`, `data/encounters/encounters.json`, `data/config/monster_scaling.json`, `scripts/combat/CombatState.gd`, `scripts/tools/NumericalTreeAuditor.gd`, `scripts/main/Main.gd` | `tests/test_act1_rebaseline.gd`, `tests/test_combat_core.gd`, `tests/test_balance_simulator.gd`, `tests/test_numerical_tree_auditor.gd`, `tests/test_run_flow.gd` | Batch 017 第一章七遭遇、复合意图与 Boss/elite 层级已交付；二三章仍待配对重标定 | L3-new-2 | 1 |
| REQ-006 | PARTIAL | `data/cards/cards.json`, `data/relics/relics.json`, `data/events/events.json`, `data/config/art_assets.json`, `assets/art/generated/` | `tests/test_data_integrity.gd`, `tests/test_art_asset_auditor.gd` | batch-014 delivered 8 relic PNGs; next: replace remaining legacy event/enemy art | L3-5 | 0 |
| REQ-007 | DONE | `scripts/core/SaveManager.gd`, `scripts/main/Main.gd`, `data/config/achievements.json` | v5 奖励事务、原子恢复、错节点/坏 ID/金币回滚和旧战斗 HP 隔离测试 | none | L3-post | 0 |
| REQ-008 | PARTIAL | `scripts/ui/AppShell.gd`, `scripts/ui/ForgeTheme.gd`, `scripts/ui/ForgeMotion.gd`, `scripts/ui/components/`, `scripts/ui/pages/WelcomePage.gd`, `scripts/ui/pages/CharacterSelectPage.gd`, `scripts/main/Main.gd`, `assets/art/generated/`, `assets/fonts/NotoSansSC-Variable.ttf` | `tests/test_forge_ui_foundation.gd`, `tests/test_welcome_character_pages.gd`, `tests/test_visual_bounds.gd`, `tests/test_run_flow.gd`, `tools/render_pc_gallery.gd` | Batch 018A 已交付 Shell/Token/欢迎/角色页；地图/事件/商店/篝火/奖励与结算/设置/图鉴仍由 018B/018C 补齐 | L3-3 | 0 |
| REQ-009 | PARTIAL | `scripts/core/PlaytestTelemetry.gd`, `scripts/core/PlaytestEvidenceGate.gd`, `tools/merge_playtest_reports.gd`, `scripts/tools/BalanceSimulator.gd`, `data/config/numerical_tree.json` | `tests/test_act1_rebaseline.gd`, `tests/test_playtest_evidence_gate.gd`, `tests/test_balance_simulator.gd`, `tests/test_numerical_balance_matrix.gd` | Batch 017 single 默认技能书已对齐，64/256 paired evidence 已交付；真人难度仍等待合格样本 | L3-new-2 | 0 |
| REQ-010 | MISSING | none | none | proposed: build-grid-tactics-mode | 1 | 2 |
| REQ-011 | PARTIAL | `export_presets.cfg`, `project.godot`, `packaging/PLAYTEST_README_ZH.txt` | alpha.8 Windows PE32+ x86_64 embedded-PCK、精确 PCK 启动、版本和压缩完整性通过 | next: native Windows matrix, commercial signing, installer and Steam integration | L3-post | 0 |
| REQ-012 | PARTIAL | `tests/`, `tools/render_pc_gallery.gd`, `scripts/tools/ArtAssetAuditor.gd`, `data/config/ui_motion_profiles.json`, `data/config/ui_theme_tokens.json` | 24-suite strict-log regression、foundation/page API、1280×720/1600×900 欢迎与角色页、motion clamp/reduced-motion/disabled focus 契约通过；其余页面 golden 仍待 018B/018C | 018B/018C | L3-3 | 0 |

## 当前批次

- batch_id: `delivery-batch-018-ui-ember-forge-cohesion`
- scope: `完整 PC UI shell 与欢迎、角色、地图、事件、商店、篝火、奖励、结算、设置、图鉴页面质量重构`
- selected_reqs:
  - `REQ-008`
  - `REQ-012`
- excluded_this_round:
  - `REQ-003/004/005/009`: 数值/玩法已冻结，UI 迁移不得触碰
  - `REQ-006`: legacy 内容资产替换不纳入本批，只复用或新增原创 UI 装饰
  - `REQ-010/011`: 网格战术模式、商业签名/Steam/安装器继续后续批次
  - `二三章`: 后章压力必须使用完成第一章后的真实牌组快照，留后续批次
  - `REQ-010`: 空间网格战术模式继续作为后续差异化扩展

## 阻塞项

| 条目 | 原因 | 需要人工提供什么 | 起始轮次 |
| --- | --- | --- | --- |
| none | 当前无阻塞项 | none | 2 |

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

## 预算快照

- max_batches_per_day: `1`
- max_gap_tasks_per_run: `3`
- max_high_risk_tasks_per_run: `1`
- max_carry_over_rounds_per_req: `2`
- max_verifier_failures_per_task: `2`

## 下一轮建议

- action: `await-user-resume`
- reason: `Batch 018A 已以严格 TDD、24/24 回归、双阶段评审 C0/M0/m0 和 PC 实图验收交付；按用户要求合并后暂停。`
- next_batch: `delivery-batch-018b-run-pages`，继续迁移地图、事件、商店、篝火与奖励页；恢复前不自动进入下一批。
- next_audit_scope: `delta`
