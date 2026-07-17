# EmberCircuit Delivery State

stage_state:
  state: S8_RUN_LOG
  loop_mode: L3
  audit_scope: delta
  current_round: 6
  max_rounds: 6
  open_gaps: 8
  tasks_created: 1
  tasks_completed: 1
  carry_over: 4
  critical_review_issues: 0
  next_legal_action: rebaseline around expert playtest difficulty feedback before the next high-risk numerical batch
  stop_conditions: L3 Round 6 reached; start a new loop baseline before numerical recalibration
---

loop_mode: L3
current_round: 6
next_loop_recommendation: rebaseline-required
carry_over: 4

## 基线

- source_requirements: `docs/00_MASTER_PLAN.md`（由 `docs/01-08` 细化）
- mvp_baseline_commit: `7b3f050`
- last_audited_commit: `2c3e89411c14096aac87dbad9ae9eba6df442e3b`
- loop_mode: `L3`
- current_round: `6`
- max_rounds: `6`
- current_batch_id: `delivery-batch-015-playtest-evidence-gate`

## 需求状态

| REQ ID | 状态 | 实现证据 | 测试证据 | 补缺任务 | 最近变化轮次 | Carry-over 次数 |
| --- | --- | --- | --- | --- | --- | --- |
| REQ-001 | DONE | `scripts/combat/CombatState.gd` | `tests/test_combat_core.gd` | none | 3 | 0 |
| REQ-002 | DONE | `scripts/main/Main.gd`, `scripts/map/MapGenerator.gd`, `data/config/level_tree.json` | `tests/test_run_flow.gd`, `tests/test_map_generator.gd`, `tests/test_map_view.gd` | none | 3 | 0 |
| REQ-003 | PARTIAL | `data/cards/cards.json`, `data/enemies/enemies.json`, `data/config/monster_scaling.json`, `scripts/tools/NumericalTreeAuditor.gd`, `data/config/numerical_tree.json` | `tests/test_data_integrity.gd`, `tests/test_numerical_tree_auditor.gd`, `tests/test_numerical_balance_matrix.gd` | next: rebaseline opening power and chapter difficulty from expert feedback, paired simulation and TDD | L3-6 | 0 |
| REQ-004 | PARTIAL | `data/config/player.json`, `data/config/progression_systems.json`, `data/cards/cards.json`, `scripts/main/Main.gd` | `tests/test_progression_systems.gd`, `tests/test_combat_core.gd`, `tests/test_run_flow.gd`, `tests/test_balance_card_telemetry.gd` | next: expand character-exclusive card pools using human telemetry | 3 | 1 |
| REQ-005 | PARTIAL | `data/enemies/enemies.json`, `data/encounters/encounters.json`, `data/config/monster_scaling.json`, `scripts/combat/CombatState.gd`, `scripts/main/Main.gd` | `tests/test_combat_core.gd`, `tests/test_balance_simulator.gd`, `tests/test_numerical_tree_auditor.gd`, `tests/test_run_flow.gd` | next: expand chapter encounters and dedicated phase assets/audio | L3-3 | 1 |
| REQ-006 | PARTIAL | `data/cards/cards.json`, `data/relics/relics.json`, `data/events/events.json`, `data/config/art_assets.json`, `assets/art/generated/` | `tests/test_data_integrity.gd`, `tests/test_art_asset_auditor.gd` | batch-014 delivered 8 relic PNGs; next: replace remaining legacy event/enemy art | L3-5 | 0 |
| REQ-007 | DONE | `scripts/core/SaveManager.gd`, `scripts/main/Main.gd`, `data/config/achievements.json` | v5 奖励事务、原子恢复、错节点/坏 ID/金币回滚和旧战斗 HP 隔离测试 | none | L3-post | 0 |
| REQ-008 | PARTIAL | `assets/art/generated/`, `assets/fonts/NotoSansSC-Variable.ttf`, `data/config/art_assets.json`, `scripts/main/Main.gd`, `scripts/map/MapView.gd`, `assets/audio/` | `tests/test_visual_bounds.gd`, `tests/test_run_flow.gd`, `tests/test_art_asset_auditor.gd`, `tests/test_pc_combat_hotkeys.gd`, `tests/test_audio_manager.gd`, `tools/render_pc_gallery.gd` | batch-014 added six-relic HUD and full relic compendium evidence; next: remaining legacy effects/content art/Boss audio | L3-5 | 0 |
| REQ-009 | PARTIAL | `scripts/core/PlaytestTelemetry.gd`, `scripts/core/PlaytestEvidenceGate.gd`, `tools/merge_playtest_reports.gd`, `scripts/core/SaveManager.gd`, `scripts/main/Main.gd`, `scripts/tools/BalanceSimulator.gd`, `data/config/numerical_tree.json` | `tests/test_playtest_evidence_gate.gd`, `tests/test_playtest_telemetry.gd`, `tests/test_playtest_run_integration.gd`, `tests/test_numerical_balance_matrix.gd` | evidence gate DONE; next: collect qualified cohorts and compare the numerical rebaseline against expert feedback | L3-6 | 0 |
| REQ-010 | MISSING | none | none | proposed: build-grid-tactics-mode | 1 | 2 |
| REQ-011 | PARTIAL | `export_presets.cfg`, `project.godot`, `packaging/PLAYTEST_README_ZH.txt` | alpha.8 Windows PE32+ x86_64 embedded-PCK、精确 PCK 启动、版本和压缩完整性通过 | next: native Windows matrix, commercial signing, installer and Steam integration | L3-post | 0 |
| REQ-012 | DONE | `tests/`, `tools/render_pc_gallery.gd`, `scripts/tools/ArtAssetAuditor.gd` | 20-suite strict-log regression、153-slot art audit、720p 奖励页、资源排除与导出包启动验证通过 | none | L3-6 | 0 |

## 当前批次

- batch_id: `delivery-batch-015-playtest-evidence-gate`
- scope: `L3 Round 6：真人遥测 schema v2、cohort 隔离、per-cell 留存、多报告合并、12/30 覆盖矩阵与游戏内导出摘要`
- selected_reqs:
  - `REQ-009`
  - `REQ-012`
- excluded_this_round:
  - `REQ-003/004/005`: 本批只建立可信证据门，不调整角色、卡牌、怪物或挑战数值
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

## 预算快照

- max_batches_per_day: `1`
- max_gap_tasks_per_run: `3`
- max_high_risk_tasks_per_run: `1`
- max_carry_over_rounds_per_req: `2`
- max_verifier_failures_per_task: `2`

## 下一轮建议

- action: `rebaseline-required`
- reason: `batch-015 已建立可信真人证据门并通过 20/20；L3 已到 6/6，且资深玩家反馈直接否定当前开局强度与难度曲线的体验质量。下一步需开启新 loop，审计角色起始资源、起始牌组、第一章遭遇压力、挑战修正和奖励成长斜率，再以配对种子模拟与 TDD 重标定。`
- next_audit_scope: `full`
