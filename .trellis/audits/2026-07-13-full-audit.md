# EmberCircuit MVP 到完整交付差距审计

## Stage State Packet

```yaml
stage_state:
  state: S5_PICK_BATCH
  loop_mode: L1
  audit_scope: full
  current_round: 1
  max_rounds: 6
  open_gaps: 7
  tasks_created: 0
  tasks_completed: 0
  carry_over: 0
  critical_review_issues: 0
  next_legal_action: confirm delivery-batch-001
  stop_conditions:
    - first full audit requires user confirmation before task creation
```

## Trellis 工作流上下文

| 项目 | 值 | 备注 |
| --- | --- | --- |
| Trellis 版本/来源 | `coldwateryi/trellis-skills` | 项目此前没有 `.trellis/`，本轮初始化交付状态 |
| 工作流契约 | not present | 后续创建任务时采用当前 Trellis skill 默认契约 |
| 配置 | not present | 未发现 `.trellis/config.yaml` |
| Developer identity | not initialized | 不阻塞 L1 审计；创建任务前再初始化 |
| Spec 新鲜度 | missing | 当前以 `docs/00-08`、代码和测试作为权威证据 |

## 交付 Loop 元数据

| 项目 | 值 | 备注 |
| --- | --- | --- |
| Loop 模式 | L1 | 首次 MVP 后完整审计 |
| 审计范围 | full | `.trellis/delivery-state.md` 原本不存在 |
| MVP baseline commit | `7b3f050` | 当前本地 `master` |
| Last audited commit | none | 首次审计 |
| 当前轮次 | 1 | 初始轮次 |
| 是否可 early-exit | no | 首次审计必须建立完整基线 |

## 执行模型画像

| 项目 | 值 |
| --- | --- |
| 预期执行模型 | Codex 强模型规划 + Trellis TDD 实现技能 |
| 规划深度 | high-risk |
| 回归风险等级 | high（共享 `Main.gd`、跨章节数据和美术清单） |

## 需求追踪矩阵

| ID | 需求 | 当前状态 | 相关代码 | 现有测试 | 缺口 | 建议任务 |
| --- | --- | --- | --- | --- | --- | --- |
| REQ-001 | 回合制卡牌战斗：抽牌、能量、攻击/技能/能力、敌人意图、状态、胜负 | DONE | `scripts/combat/CombatState.gd`, `data/cards/cards.json`, `data/statuses/statuses.json` | `tests/test_combat_core.gd`, `tests/test_run_flow.gd` | 无阻塞缺口 | none |
| REQ-002 | 三章节完整跑团：分叉地图、普通/精英/Boss、事件、商店、篝火、宝箱、奖励和结算 | DONE | `scripts/main/Main.gd`, `scripts/map/MapGenerator.gd`, `data/config/map_generation.json`, `data/encounters/encounters.json` | `tests/test_run_flow.gd`, `tests/test_map_generator.gd`, `tests/test_map_view.gd` | 无阻塞缺口 | none |
| REQ-003 | 数据驱动内容、数值预算、设计/平衡/升级注释和完整性校验 | DONE | `data/cards/cards.json`, `data/enemies/enemies.json`, `data/config/monster_scaling.json`, `data/config/level_tree.json` | `tests/test_data_integrity.gd`, `tests/test_balance_simulator.gd` | 无阻塞缺口 | none |
| REQ-004 | 3 个角色及完整专属构筑、局外升级树、技能书、卡组专精 | PARTIAL | `data/config/player.json`, `data/config/progression_systems.json`, `data/cards/cards.json`, `scripts/main/Main.gd` | `tests/test_progression_systems.gd`, `tests/test_run_flow.gd` | 三角色和成长规则已完成，但总卡池约 49 张，未达到每角色 75-100 张专属卡牌的完整版目标 | expand-character-card-pools |
| REQ-005 | 每章 12-18 种敌人、2-3 个 Boss，并具备章节化战术和演出 | PARTIAL | `data/enemies/enemies.json`, `data/encounters/encounters.json`, `scripts/main/Main.gd` | `tests/test_data_integrity.gd`, `tests/test_combat_core.gd`, `tests/test_balance_simulator.gd` | 三章和 Boss 均可玩，但敌人/多 Boss 内容量不足，部分后章敌人仍使用首版 SVG 表现 | expand-chapter-encounters |
| REQ-006 | 150-250 张卡牌、120-200 遗物、40-60 事件的商业内容量 | PARTIAL | `data/cards/cards.json`, `data/relics/relics.json`, `data/events/events.json` | `tests/test_data_integrity.gd`, `tests/test_run_flow.gd` | 当前内容足以完成三章流程，但远未达到完整版数量和流派覆盖目标 | expand-content-library |
| REQ-007 | 存档、设置、图鉴、成就、挑战等级和局外档案 | DONE | `scripts/core/SaveManager.gd`, `data/config/achievements.json`, `data/config/challenges.json`, `scripts/main/Main.gd` | `tests/test_save_manager.gd`, `tests/test_run_flow.gd` | Steam 成就映射属于 REQ-011，不影响本地系统完成状态 | none |
| REQ-008 | PC 商用品质 UI、美术、动画、音频和打击感 | PARTIAL | `scripts/main/Main.gd`, `assets/art/generated/`, `assets/audio/`, `data/config/art_assets.json`, `data/config/vfx_profiles.json` | `tests/test_visual_bounds.gd`, `tests/test_audio_manager.gd`, `tests/test_run_flow.gd`, `tools/render_pc_gallery.gd` | 战斗/角色/牌组已显著重构，但大量卡牌、事件、后章敌人仍为首版 SVG；缺少正式 Boss 动画、结局动画和一致的场景级包装 | complete-production-art |
| REQ-009 | 全角色/全挑战的完整跑团平衡模拟与稳定数值目标 | PARTIAL | `scripts/tools/BalanceSimulator.gd`, `tools/run_balance_simulation.gd`, `data/config/monster_scaling.json` | `tests/test_balance_simulator.gd`, `tests/test_progression_systems.gd` | 普通模式 192 次样本已稳定；挑战 1-3 的扩大样本和更强策略模型仍不足 | deepen-balance-campaigns |
| REQ-010 | 九宫格空间战术模式/移动壁垒核心扩展 | MISSING | none | none | 尚未建立网格数据模型、空间卡牌词条、敌人范围预告或模式入口 | build-grid-tactics-mode |
| REQ-011 | 多语言、Steam 页面/发布素材、Steam 成就和发布管线 | MISSING | none | none | 当前只有中文本地 UI 和本地成就；没有本地化表、Steam 素材或发布检查 | prepare-steam-release |
| REQ-012 | 自动化验证、视觉防回归和可重复运行 | DONE | `tests/`, `tools/render_pc_gallery.gd`, `tools/render_visual_snapshot.gd` | 10 套 Godot smoke/regression tests | 仍可继续增加性能基准，但现有核心流程具备稳定验证证据 | none |

## MVP 完成度摘要

- 已完成：4 项（REQ-001、002、003、007、012 中实际为 5 项；总计 5/12，41.7%）。
- 部分完成：5 项（REQ-004、005、006、008、009，41.7%）。
- 未实现：2 项（REQ-010、011，16.7%）。
- 已实现但未测试：0 项。
- 不明确：0 项。
- 说明：该百分比以《完整开发主计划》的商业完整版范围为分母，不代表当前三章原型不可玩；当前 MVP 和三章纵向流程已有充分运行证据。

## 阻塞性问题

- 没有阻塞 L1 审计的问题。
- 首次 full audit 安全门要求：用户确认差距矩阵和第一批范围前，不创建 Trellis task，也不继续业务实现。
- GitHub HTTPS push 当前间歇性返回 403；不影响本地开发和测试，但影响自动同步远端。

## 按依赖排序的任务计划

| 顺序 | 任务 Slug | 标题 | 需求 ID | 依赖 | 验收标准 | 自动化测试要求 | 优先级 | 复杂度 | 规划产物 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | audit-art-manifest | 建立正式美术缺口清单和替换优先级 | REQ-008 | none | 所有运行时美术槽位被分类为 production/first-pass/missing，且无未登记资源 | 数据完整性测试验证资源路径和分类字段 | P1 | 低 | `prd.md` |
| 2 | replace-card-art-batch-01 | 替换第一批高频卡牌占位/首版 SVG | REQ-008 | audit-art-manifest | 三角色起始牌组、常见奖励和能力牌全部使用统一位图插画；卡面 720p 可读 | `test_data_integrity.gd` + `test_run_flow.gd` + 截图库 | P1 | 中 | `prd.md`, `design.md`, `implement.md` |
| 3 | polish-boss-presentation | 完善三章 Boss 舞台、阶段动画和专属音频包装 | REQ-008 | audit-art-manifest | 三章 Boss 都有独立舞台视觉、阶段反馈和非占位音频；不改变战斗数值 | `test_run_flow.gd` + `test_visual_bounds.gd` + Boss 截图 | P1 | 高 | `prd.md`, `design.md`, `implement.md` |
| 4 | expand-character-card-pools | 扩展三角色专属卡池与流派交叉验证 | REQ-004, REQ-006 | REQ-008 第一批完成后可并行 | 每角色至少新增一个完整 10-15 张主题批次，全部含注释与升级 | 数据完整性、战斗核心、完整跑团模拟 | P1 | 高 | `prd.md`, `design.md`, `implement.md` |
| 5 | deepen-balance-campaigns | 扩大挑战模式样本和策略模型 | REQ-009 | 内容批次稳定 | 三角色挑战 1-3 有独立报告和风险阈值 | `test_balance_simulator.gd` + JSON 报告 | P1 | 中 | `prd.md`, `implement.md` |
| 6 | build-grid-tactics-mode | 建立九宫格模式最小垂直切片 | REQ-010 | 主模式稳定 | 独立模式入口、纯数据网格、空间卡牌和一场可完成战斗 | 新增网格 unit/integration tests | P2 | 高 | `prd.md`, `design.md`, `implement.md` |
| 7 | prepare-steam-release | 多语言与 Steam 发布管线 | REQ-011 | 核心内容冻结 | 本地化表、发布素材清单、Steam 成就映射和导出检查 | 导出 smoke test + 本地化完整性测试 | P2 | 高 | `prd.md`, `design.md`, `implement.md` |

## 交付批次建议

| Batch ID | 范围 | 纳入 REQ | 排除 REQ | 风险 | 下一步动作 |
| --- | --- | --- | --- | --- | --- |
| delivery-batch-001 | P1 正式美术资产完整性 | REQ-008 | REQ-004/005/006：内容扩充应在视觉资产契约稳定后进入；REQ-009：等待内容批次；REQ-010/011：P2 | medium（含 1 个高风险 Boss 演出任务） | 用户确认后创建 3 个 tasks，暂不实现 |

## 自我评审结论

- A 需求追踪矩阵：通过。每条完整版能力域均有状态、实现和测试证据，PARTIAL/MISSING 缺口具体。
- B 完成度：通过。机械统计为 DONE 5、PARTIAL 5、MISSING 2，总数 12。
- H 风险：通过。共享 `Main.gd`、内容平衡、Boss 演出和发布范围均已标记。
- C/D/E：本轮仅推荐批次，尚未创建 PRD；任务创建质量门在用户确认后执行。
- 整体结论：L1 full audit 达标，可进入 S6 用户确认安全门。

## 确认请求

请确认这个差距审计、交付状态更新和 `delivery-batch-001`。确认后将创建或更新本批次 Trellis tasks 和 PRD，但按 Trellis 安全门暂不直接实现功能。
