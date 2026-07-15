# EmberCircuit Delivery State

stage_state:
  state: S8_RUN_LOG
  loop_mode: L3
  audit_scope: delta
  current_round: 1
  max_rounds: 4
  open_gaps: 7
  tasks_created: 0
  tasks_completed: 0
  carry_over: 4
  critical_review_issues: 0
  next_legal_action: distribute 0.1.0-alpha.4 and collect fingerprinted human playtest reports
  stop_conditions: hard numerical tuning still requires human samples
---

loop_mode: L3
current_round: 1
next_loop_recommendation: pause-human-needed
carry_over: 4

## 基线

- source_requirements: `docs/00_MASTER_PLAN.md`（由 `docs/01-08` 细化）
- mvp_baseline_commit: `7b3f050`
- last_audited_commit: `7313e1dfe9b1f58c29947f2ea87cc67a61333f6f`
- loop_mode: `L3`
- current_round: `1`
- max_rounds: `4`
- current_batch_id: `l3-round-1-pc-campfire-ui-art`

## 需求状态

| REQ ID | 状态 | 实现证据 | 测试证据 | 补缺任务 | 最近变化轮次 | Carry-over 次数 |
| --- | --- | --- | --- | --- | --- | --- |
| REQ-001 | DONE | `scripts/combat/CombatState.gd` | `tests/test_combat_core.gd` | none | 3 | 0 |
| REQ-002 | DONE | `scripts/main/Main.gd`, `scripts/map/MapGenerator.gd`, `data/config/level_tree.json` | `tests/test_run_flow.gd`, `tests/test_map_generator.gd`, `tests/test_map_view.gd` | none | 3 | 0 |
| REQ-003 | DONE | `data/cards/cards.json`, `data/enemies/enemies.json`, `data/config/monster_scaling.json`, `scripts/tools/NumericalTreeAuditor.gd` | `tests/test_data_integrity.gd`, `tests/test_numerical_tree_auditor.gd` | none | 3 | 0 |
| REQ-004 | PARTIAL | `data/config/player.json`, `data/config/progression_systems.json`, `data/cards/cards.json`, `scripts/main/Main.gd` | `tests/test_progression_systems.gd`, `tests/test_combat_core.gd`, `tests/test_run_flow.gd`, `tests/test_balance_card_telemetry.gd` | next: expand character-exclusive card pools using human telemetry | 3 | 1 |
| REQ-005 | PARTIAL | `data/enemies/enemies.json`, `data/encounters/encounters.json`, `data/config/monster_scaling.json`, `scripts/combat/CombatState.gd` | `tests/test_combat_core.gd`, `tests/test_balance_simulator.gd`, `tests/test_numerical_tree_auditor.gd` | next: expand chapter encounters and phase presentation | 3 | 1 |
| REQ-006 | PARTIAL | `data/cards/cards.json`, `data/relics/relics.json`, `data/events/events.json`, `data/config/art_assets.json`, `assets/art/generated/` | `tests/test_data_integrity.gd`, `tests/test_art_asset_auditor.gd` | next: replace remaining legacy relic/event/enemy art | L3-1 | 0 |
| REQ-007 | DONE | `scripts/core/SaveManager.gd`, `data/config/achievements.json` | `tests/test_save_manager.gd`, `tests/test_run_flow.gd` | none | 1 | 0 |
| REQ-008 | PARTIAL | `assets/art/generated/`, `assets/fonts/NotoSansSC-Variable.ttf`, `data/config/art_assets.json`, `scripts/main/Main.gd`, `scripts/map/MapView.gd`, `assets/audio/` | `tests/test_visual_bounds.gd`, `tests/test_art_asset_auditor.gd`, `tests/test_pc_combat_hotkeys.gd`, `tests/test_audio_manager.gd` | next: unify remaining legacy overlays, effects and content art | L3-1 | 0 |
| REQ-009 | PARTIAL | `scripts/core/PlaytestTelemetry.gd`, `scripts/core/SaveManager.gd`, `scripts/main/Main.gd`, `scripts/tools/BalanceSimulator.gd`, `data/config/numerical_tree.json` | `tests/test_playtest_telemetry.gd`, `tests/test_playtest_run_integration.gd`, `tests/test_balance_card_telemetry.gd`, `tests/test_numerical_balance_matrix.gd` | next: collect 12/30 finished human runs per character/challenge cell and analyze by configuration fingerprint | 5 | 0 |
| REQ-010 | MISSING | none | none | proposed: build-grid-tactics-mode | 1 | 2 |
| REQ-011 | PARTIAL | `export_presets.cfg`, `project.godot`, `packaging/PLAYTEST_README_ZH.txt` | alpha.4 Windows embedded-PCK smoke; macOS universal native startup, build 4 and ad-hoc signature verification | next: native Windows matrix, commercial signing, installer and Steam integration | L3-1 | 0 |
| REQ-012 | DONE | `tests/`, `tools/render_pc_gallery.gd`, `scripts/tools/ArtAssetAuditor.gd` | 18-suite strict-log regression, 153-slot art audit, two 720p campfire crops, archive integrity and exported-package smoke passed | none | L3-1 | 0 |

## 当前批次

- batch_id: `l3-round-1-pc-campfire-ui-art`
- scope: `L3 Round 1 delta：PC 篝火双阶段重构、完整牌组锻造、正式房间插画与 0.1.0-alpha.4 试玩包`
- selected_reqs:
  - `REQ-006`
  - `REQ-008`
  - `REQ-011`
  - `REQ-012`
- excluded_this_round:
  - `REQ-004/005/009`: 冻结角色、怪物、卡牌和挑战数值，真人每格未达到 12/30 完成局前不做硬调参
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

## 预算快照

- max_batches_per_day: `1`
- max_gap_tasks_per_run: `3`
- max_high_risk_tasks_per_run: `1`
- max_carry_over_rounds_per_req: `2`
- max_verifier_failures_per_task: `2`

## 下一轮建议

- action: `pause-human-needed`
- reason: `L3 Round 1 与 alpha.4 已交付；先让试玩者验证完整流程、篝火双阶段和长牌组锻造，并按配置指纹收集每格 12 局方向样本，达到 30 局前不做数值硬调参。`
- next_audit_scope: `delta`
