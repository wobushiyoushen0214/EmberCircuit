# EmberCircuit 数值树重基线 Full Audit

日期：2026-07-17

## Stage State Packet

```yaml
stage_state:
  state: S3_GAP_AUDIT
  loop_mode: L3
  audit_scope: full
  current_round: 1
  max_rounds: 6
  open_gaps: 8
  tasks_created: 0
  tasks_completed: 0
  carry_over: 3
  critical_review_issues: 0
  next_legal_action: confirm delivery-batch-016-numerical-pressure-contract
  stop_conditions:
    - do not tune gameplay values before the pressure contract is executable
```

## Trellis 工作流上下文

| 项目 | 值 | 备注 |
| --- | --- | --- |
| Trellis 版本/来源 | unknown | `.trellis/.version` 不存在 |
| 工作流契约 | not present | 延续现有任务的 `prd/design/implement/*.jsonl/review/tdd-progress` 产物 |
| 配置 | not present | `.trellis/config.yaml` 不存在 |
| Developer identity | not initialized | 不阻塞只读审计 |
| Spec 新鲜度 | missing | `.trellis/spec/` 不存在；以 `docs/09`、数值 JSON、模拟器和现有测试为权威契约 |

## 交付 Loop 元数据

| 项目 | 值 | 备注 |
| --- | --- | --- |
| Loop 模式 | L3 | 用户要求持续完成游戏，并明确要求重做数值树 |
| 审计范围 | full | 上一 L3 已到 6/6，资深玩家反馈重新打开 REQ-003，需要重设数值证据基线 |
| MVP baseline commit | `c7505c4` | batch-015 状态登记提交 |
| Last audited commit | `2c3e894` | 上一批业务交付提交 |
| 当前轮次 | 新 loop Round 1 | 先建立压力测量契约 |
| 是否可 early-exit | no | 新的人类体验证据与本地模拟均推翻“开局压力健康”假设 |

## 触发证据

- 资深 Slay the Spire 类型玩家反馈：开局数值偏高、普通难度简单、整体有些无聊。
- 3 角色 × 7 个第一章遭遇 × 256 个种子的 starter-only 单战共 5376 场，平均胜率 `99.6%`。
- 第一章四个普通遭遇三角色全部 `100%` 胜。
- `intro_patrol` 平均损血：流亡者 `3.324`、工匠 `4.367`、苦修者 `5.195`；三者起始生命为 69–70。
- 仅用满血起始牌组挑战第一章 Boss，胜率仍为 `97.27% / 96.09% / 99.61%`。
- 完整 `3×4×256` 跑团矩阵的普通难度胜率仍为 `27.5%`，但 C0 失败的 `35.3%–47.6%` 集中在最终 Boss；它反映弱策略长期累积，不反映开局压力。

复现命令：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tools/run_balance_simulation.gd -- --iterations=256 --max-turns=30 --characters=ember_exile,arc_tinker,pyre_ascetic --challenges=0 --encounters=intro_patrol,polluted_lab,iron_checkpoint,cinder_kennels,executor_elite,furnace_colossus_elite,chapter_one_boss --output=/tmp/embercircuit-opening-baseline.json
```

## 根因矩阵

| 根因 | 当前证据 | 为什么导致无聊 | 现有门禁缺口 |
| --- | --- | --- | --- |
| 起始牌效率过高 | 牌组效果点 `78.86 / 70.03 / 79.61`；补入起始势能和遗物后约 `88.74 / 79.83 / 85.77`；默认钢铁手册再提供 3 开场甲 | 基础牌本身已接近普通牌上沿，升级/奖励带来的相对提升变小 | Auditor 目标区间围绕现值，未计算完整 opening package |
| 免费前置资源叠加 | 每角色 2 件起始遗物；开场免费甲 5/6/7；钢铁手册再给 3 甲；流亡者首回合多抽 1；工匠开场总势能 2 | 第一回合几乎不存在进攻与防守取舍 | 只检查遗物数量，不审计叠加后的开局效果点 |
| 低威胁密度与固定循环 | 第一章普通敌人仅 50% 行动为攻击；Boss 基础循环仅 40%；所有意图固定从 action 0 循环 | 玩家可背板，空窗多；提高 HP 只会变成木桩战 | Auditor 只查理论峰值，不查同回合压力、空窗或攻击密度 |
| Boss 与精英层级倒挂 | 普通模式第一章 Boss 有效 HP `100×0.96=96`，低于最高精英 `104` | 章节终点没有检验构筑成长 | 没有 Boss/elite EHP 比例门 |
| 恢复和成长过密 | 篝火恢复 40%=约 28 HP；第一章 1–2 个篝火；首战后恢复远高于首战平均损耗；初始金币 92–99 | 首战后几乎无条件升级，路线与恢复决策缺少代价 | Economy audit 不检查恢复覆盖率或休息/升级分布 |
| 挑战只制造海绵 | C0–C3 敌伤倍率均为 1.0，主要是敌血 +5/10/13% 与开局扣血 | 战术没有变化，只延长战斗或压低总生命 | 没有行动压力与决策张力指标 |
| 完整模拟策略过弱 | 逐张即时贪心、几乎不做卡序/跨回合规划；牌组<15时强制拿牌；路线极少主动打精英 | 高手会主动滚雪球，AI 的低通关率不能代表真人难度 | 单一弱策略被当作完整数值硬门 |

## 需求追踪矩阵

| ID | 需求 | 当前状态 | 相关代码 | 现有测试 | 缺口 | 建议任务 |
| --- | --- | --- | --- | --- | --- | --- |
| REQ-001 | 战斗核心 | DONE | `scripts/combat/CombatState.gd` | `tests/test_combat_core.gd` | 无 | none |
| REQ-002 | 三章路线流程 | DONE | `scripts/map/MapGenerator.gd`, `scripts/main/Main.gd` | `tests/test_map_generator.gd`, `tests/test_run_flow.gd` | 无 | none |
| REQ-003 | 严谨且可玩的数值树 | PARTIAL | `data/config/numerical_tree.json`, `data/cards/cards.json`, `data/enemies/enemies.json`, `scripts/tools/NumericalTreeAuditor.gd` | `tests/test_numerical_tree_auditor.gd`, `tests/test_numerical_balance_matrix.gd` | 现有契约只证明自洽，无法识别开局过强、低压力和木桩战 | numerical-pressure-contract → act1-rebaseline |
| REQ-004 | 三角色构筑差异 | PARTIAL | `data/config/player.json`, `data/cards/cards.json`, `data/config/progression_systems.json` | `tests/test_progression_systems.gd`, `tests/test_balance_card_telemetry.gd` | 三套 opening package 强度不可比，工匠行动密度过高 | act1-rebaseline |
| REQ-005 | 敌人与 Boss 压力曲线 | PARTIAL | `data/enemies/enemies.json`, `data/encounters/encounters.json`, `data/config/monster_scaling.json` | `tests/test_numerical_tree_auditor.gd`, `tests/test_balance_simulator.gd` | 不检查攻击密度、空窗、实际回合或 Boss/elite 层级 | numerical-pressure-contract → act1-rebaseline |
| REQ-006 | 内容与资源规模 | PARTIAL | 卡牌/遗物/事件/美术数据 | 数据与资源审计 | 非本轮瓶颈 | later |
| REQ-007 | 存档与成就 | DONE | `scripts/core/SaveManager.gd` | `tests/test_save_manager.gd` | 无 | none |
| REQ-008 | 产品级 UI/视听 | PARTIAL | `scripts/main/Main.gd`, assets | 视觉/音频测试 | 非本轮瓶颈 | later |
| REQ-009 | 平衡模拟与真人证据 | PARTIAL | `scripts/tools/BalanceSimulator.gd`, `scripts/core/PlaytestEvidenceGate.gd` | `tests/test_balance_simulator.gd`, `tests/test_playtest_evidence_gate.gd` | 缺早期分层指标、too-easy 风险和 baseline/candidate 配对证据 | numerical-pressure-contract |
| REQ-010 | 九宫格战术模式 | MISSING | none | none | 非本轮 | later |
| REQ-011 | 正式发行 | PARTIAL | `export_presets.cfg`, packaging | 构建验证 | 非本轮 | later |
| REQ-012 | 自动化质量门 | DONE | `tests/`, tools | 20 套严格回归 | 数值质量门需要扩充，但测试基础已存在 | numerical-pressure-contract |

## MVP 完成度摘要

- DONE：4/12（33.3%）
- PARTIAL：7/12（58.3%）
- MISSING：1/12（8.3%）
- UNTESTED：0
- UNCLEAR：0

本轮只重新打开数值相关状态，不否定已验证的战斗、路线、存档和自动化基础。

## 新证据契约（Batch 016）

Batch 016 不修改正式玩法数值，先让错误基线能够被机器识别。

### Opening package

- Auditor 新增 `opening_package_score`，至少包含：起始牌组、角色初始势能、无条件 combat-start 遗物、默认技能书、首回合固定额外抽牌。
- 输出每项贡献明细，禁止只给总分。
- 当前三角色 opening package 必须被标为超出“待重标定”目标，而不是继续 `ok`。

### Single-combat pressure

- 每个 case 输出：`perfect_win_rate`、HP 损失 p50/p90、回合 p50/p90、每回合出牌、零伤胜局数。
- 风险标记新增 `normal_too_easy`、`elite_too_easy`、`boss_too_easy`、`encounter_too_fast`、`encounter_too_slow`。
- 当前 `intro_patrol` 与 starter-only `chapter_one_boss` 必须产生过易风险，不允许继续 `ok`。

### Encounter structure

- 静态报告输出攻击行动占比、最长连续零直接伤害行动、前 3 行动基础伤害和、Boss 有效 HP / 本章最高精英 HP 比。
- `expected_turns_min/max` 必须由模拟结果进入验收，不再只是注释字段。

### Evidence discipline

- 完整跑团旧 27.5% 矩阵保留为 current-greedy 相对回归证据，不再单独证明真人难度。
- 后续 candidate 与 baseline 必须使用同一角色、挑战、iteration、节点和遭遇种子。
- Act 1 正式调值前先冻结 Batch 016 的指标 schema 与基线报告。

## 任务计划

| 顺序 | 任务 Slug | 标题 | 需求 ID | 依赖 | 验收标准 | 自动化测试要求 | 优先级 | 复杂度 | 规划产物 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | numerical-pressure-contract | 开局强度与单战压力契约 | REQ-003/005/009/012 | none | opening package 分解、分位数、too-easy、攻击密度、EHP 层级全部可机器判定 | auditor + simulator RED/GREEN、固定种子重算、20/20 | P0 | 高 | prd/design/implement/jsonl/tdd/review |
| 2 | act1-opening-rebaseline | 第一章与起始包重标定 | REQ-003/004/005 | task 1 | 不靠全局加血，把开局无伤率、损血、回合、恢复和 Boss 层级拉入新门 | 配对 256 种子、数据完整性、战斗核心、全回归 | P0 | 高 | 下一批单独规划 |
| 3 | later-chapter-pressure | 二三章入口快照重标定 | REQ-003/005/009 | task 2 + qualified Act 1 feedback | 用章节入口真实牌组反推 EHP/压力 | chapter snapshot + paired campaign | P1 | 高 | 后续批次 |

## 交付批次建议

| Batch ID | 范围 | 纳入 REQ | 排除 REQ | 风险 | 下一步动作 |
| --- | --- | --- | --- | --- | --- |
| `delivery-batch-016-numerical-pressure-contract` | 只建立压力测量、too-easy 和 opening package 契约，不调正式数值 | REQ-003/005/009/012 | REQ-004 与实际卡牌/角色/敌人数值留到 Batch 017；REQ-006/008/010/011 非本轮 | high | 用户确认后创建任务与隔离 worktree |

## 批次边界

- 每轮仅一个高风险批次；Batch 016 不与实际数值修改混合。
- 不用全局敌人 HP/伤害倍率掩盖低攻击密度和固定空窗。
- 不把 current-greedy 的完整通关率当作真人难度替代品。
- 不改变卡牌、角色、遗物、敌人、经济、挑战或路线正式数值。
- Batch 016 完成并评审后，Batch 017 才允许改第一章与起始包。

## 确认请求

请确认这个重基线审计和 `delivery-batch-016-numerical-pressure-contract`。确认后创建 Trellis 任务和隔离 worktree，并按严格 TDD 实现；Batch 016 本身不改正式玩法数值。
