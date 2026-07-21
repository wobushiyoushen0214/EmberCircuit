# 双阶段评审报告

## Review Round 1

### 被评审对象

- 任务：`02-competent-combat-and-elite-safety`
- diff 范围：`c5a4fc0..working tree`
- Stage 2 评审模型：`gpt-5.6-sol`（Codex read-only independent review）

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| AC 测试覆盖 | 通过 | - | `tests/test_balance_simulator.gd` | AC-021-07～14 均有 fixture 且自检绿 |
| 文件清单符合 | 通过 | - | task diff | 仅 simulator、测试、审计文档与任务产物 |
| 禁止事项符合 | 通过 | - | task diff | 未改生产 JSON、CombatState、MapGenerator、Main 或正式 matrix |
| 决策表符合 | 通过 | - | `BalanceSimulator.gd` | profile dispatch、3-seed、硬拒绝和 current/v1 分支均接线 |
| 挂载点接线 | 通过 | - | `BalanceSimulator.gd` | combat dispatch、predictor、cache、route gate 均已挂载 |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| exact v2 policy | 不符 | major | `BalanceSimulator.gd:1544` | 预测必须使用真实 v2 药水策略 |
| prediction horizon | 不符 | major | `BalanceSimulator.gd:1553` | 使用 campaign max_turns 并纳入 key |
| preview cache correctness | 不符 | major | `BalanceSimulator.gd:1677` | key 覆盖完整预测 state |
| thorn safety | 不符 | major | `BalanceSimulator.gd:1140` | 真实 hit 顺序计入 thorn HP 代价 |
| target ordering | 不符 | major | `BalanceSimulator.gd:1103` | threat→HP→index 必须支配小伤害差 |

### 问题汇总（按严重度）

- **Critical（阻断）**：无。
- **Major（应修）**：5，已全部按 RED→GREEN 修复并完成四项回归。
- **Minor（记录后续）**：无。

### 裁决

- [ ] 有 critical → 打回
- [x] 仅 major/minor → 本轮先修 major，再重审
- [ ] 全通过

## Review Round 2

### 被评审对象

- 任务：`02-competent-combat-and-elite-safety`
- diff 范围：`c5a4fc0..working tree`（Round 1 修复后）
- Stage 2 评审模型：`gpt-5.6-sol`（Codex read-only independent review）

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| AC 测试覆盖 | 通过 | - | `tests/test_balance_simulator.gd` | AC-021-07～14 与 Round 1 回归 fixture 全绿 |
| 文件/禁止事项 | 通过 | - | task diff | 未越过清单或修改冻结文件 |
| 决策与挂载点 | 通过 | - | `BalanceSimulator.gd` | exact profile、predictor、cache 与 hard gate 均保持接线 |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| weak-only survival | 不符 | major | `BalanceSimulator.gd:1068` | weak 单独避免致死时必须先出 |
| runtime block bonuses | 不符 | major | `BalanceSimulator.gd:1112` | 纳入技能护甲百分比与 plating 的真实顺序 |
| momentum-cost follow-up | 不符 | major | `BalanceSimulator.gd:1042` | 识别由 starter 解锁的 `lose_momentum` 后续 |
| boss phase lethal | 不符 | major | `BalanceSimulator.gd:1183` | 多段伤害逐 hit 模拟阶段入场护甲 |

### 问题汇总（按严重度）

- **Critical（阻断）**：无。
- **Major（应修）**：4，已全部按 RED→GREEN 修复并完成隔离环境四项回归。
- **Minor（记录后续）**：无。

### 裁决

- [ ] 有 critical → 打回
- [x] 仅 major/minor → 本轮修复全部 major，再进行 Round 3 复审
- [ ] 全通过

## Review Round 3

### 被评审对象

- 任务：`02-competent-combat-and-elite-safety`
- diff 范围：`c5a4fc0..working tree`（Round 2 修复后）
- Stage 2 评审模型：`gpt-5.6-sol`（Codex read-only independent review）

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| Diff/文件/禁止事项 | 通过 | - | task diff | 跟踪文件与任务产物均在清单内，冻结文件未改 |
| 挂载点/current-v1 | 通过 | - | `BalanceSimulator.gd` | current/v1 保持旧 scorer；predictor/cache/hard gate 接线存在 |
| AC 测试覆盖 | 不符 | critical | `tests/test_balance_simulator.gd` | 缺 partial-cap AOE weak 与全局 RNG 副作用 fixture |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| AOE weak partial cap | 不符 | critical | `BalanceSimulator.gd:1068` | all-enemies cap 必须覆盖每个存活目标 |
| predictor global RNG | 不符 | critical | `BalanceSimulator.gd:1611` | cache miss 不得重置/消耗调用方全局 RNG |
| runtime block base score | 不符 | major | `BalanceSimulator.gd:992` | 非致死基础防御评分也使用真实 runtime block |

### 问题汇总（按严重度）

- **Critical（阻断）**：2，已按 RED→GREEN 修复。
- **Major（应修）**：1，已按 RED→GREEN 修复。
- **Minor（记录后续）**：无。

### 裁决

- [x] 有 critical → 已打回并完成窄修复；进入 Round 4 复审
- [ ] 仅 major/minor → 放行
- [ ] 全通过

## Review Round 4

### 被评审对象

- 任务：`02-competent-combat-and-elite-safety`
- diff 范围：`c5a4fc0..working tree`（Round 3 修复后）
- Stage 2 评审模型：`gpt-5.6-sol`（Codex read-only independent review）
- 独立裁决：`C6/M0/m0`

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| Diff/文件/禁止事项 | 通过 | - | task diff | 改动仍限 simulator、fixture、审计文档与任务产物；冻结文件未改 |
| 挂载点/current-v1 | 通过 | - | `BalanceSimulator.gd` | current/v1 历史 scorer、v2 predictor/cache/hard gate 均保持接线 |
| AC 边界覆盖 | 不符 | critical | `tests/test_balance_simulator.gd` | 缺六组真实结算顺序边界 fixture |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| partial-cap AOE weak marginal value | 不符 | critical | `BalanceSimulator.gd` status starter helper | 已达 weak 的目标不得重复贡献收益，只计算仍缺状态目标的边际收益 |
| self negative starter eligibility | 不符 | critical | `BalanceSimulator.gd` status scoring | self vulnerable/self burn 不得作为敌方攻击启动器获得巨额优先级 |
| block-gained runtime modifier | 不符 | critical | `BalanceSimulator.gd` block estimator | 纳入尚未消耗的 `block_gained -> gain_block` 成长来源 |
| self vulnerable survival order | 不符 | critical | `BalanceSimulator.gd` incoming estimator | 防致死判断必须先结算同一卡施加的 self vulnerable |
| boss phase block × thorn | 不符 | critical | `BalanceSimulator.gd` thorn HP estimator | thorn HP 代价须逐 hit 模拟阶段入场护甲 |
| card-played bonus damage | 不符 | critical | `BalanceSimulator.gd` thorn/lethal estimators | `card_played -> bonus_damage` 同时进入 thorn HP 成本与 immediate lethal |

### 问题汇总（按严重度）

- **Critical（阻断）**：6，均已补失败 fixture，并按 RED→GREEN 完成窄修复。
- **Major（应修）**：无。
- **Minor（记录后续）**：无。
- 修复后隔离 HOME 下 editor import、`test_balance_simulator.gd`、`test_combat_core.gd`、`test_numerical_balance_matrix.gd` 均通过。

### 裁决

- [x] 有 critical → 已打回并完成六项窄修复；进入 Round 5 独立复审
- [ ] 仅 major/minor → 放行
- [ ] 全通过

## Review Round 5

### 被评审对象

- 任务：`02-competent-combat-and-elite-safety`
- diff 范围：`c5a4fc0..working tree`（Round 4 修复后）
- Stage 2 评审模型：`gpt-5.6-sol`（Codex read-only independent review）
- 独立裁决：`C5/M0/m0`

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| 文件/冻结边界 | 通过 | - | task diff | 仍只修改清单内文件与任务产物，冻结文件未改 |
| 挂载点/current-v1 | 通过 | - | `BalanceSimulator.gd` | profile dispatch、predictor、cache、hard gate 与历史 scorer 分流保持正确 |
| AC 边界覆盖 | 不符 | critical | `tests/test_balance_simulator.gd` | 缺五类跨 effect/触发条件/AOE 真实结算 fixture |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| AOE weak block-followup marginal value | 不符 | critical | `BalanceSimulator.gd` weak starter helper | block-followup 奖励也必须要求新增 weak 产生正边际减伤 |
| block-gained trigger conditions | 不符 | critical | `BalanceSimulator.gd` block trigger helper | 对齐 `first_turn_only`、once、momentum 与其余真实条件 |
| damage-effect status consumption | 不符 | critical | `BalanceSimulator.gd` thorn/lethal shadow | enemy vulnerable/player weak 在每个 damage effect 后按真实规则消费 |
| post-card bonus snapshot | 不符 | critical | `BalanceSimulator.gd` card-played bonus helper | 使用完整卡牌结算后的 momentum/status，并覆盖 first-turn/every-N 条件 |
| AOE secondary lethal | 不符 | critical | `BalanceSimulator.gd` immediate lethal helper | all-enemies 必须检查全部存活敌人，而非只检查 focus target |

### 问题汇总（按严重度）

- **Critical（阻断）**：5，均已补失败 fixture 并完成 RED→GREEN 修复。
- **Major（应修）**：无。
- **Minor（记录后续）**：无。
- 修复后隔离 HOME 下四项自检全绿。

### 裁决

- [x] 有 critical → 已打回并完成五项窄修复；进入 Round 6 独立复审
- [ ] 仅 major/minor → 放行
- [ ] 全通过

## Review Round 6

### 被评审对象

- 任务：`02-competent-combat-and-elite-safety`
- diff 范围：`c5a4fc0..working tree`（Round 5 修复后）
- Stage 2 评审模型：`gpt-5.6-sol`（Codex read-only independent review）
- 独立裁决：`C2/M0/m0`

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| 文件/冻结边界 | 通过 | - | task diff | 仍只修改 simulator、测试、审计文档与任务产物；冻结文件未改 |
| 挂载点/current-v1 | 通过 | - | `BalanceSimulator.gd` | v2 predictor、完整 cache key、hard gate 与历史 scorer 分流保持正确 |
| AC 边界覆盖 | 不符 | critical | `tests/test_balance_simulator.gd` | 缺多 block effect 逐效果消费与结算期间 HP-loss 遗物改变势能的 fixture |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| multi-block runtime order | 不符 | critical | `BalanceSimulator.gd` block estimator | 每个 block effect 后分别触发 `block_gained` 并消费一层 frail，维护 once 状态与触发 context |
| nested HP-loss momentum | 不符 | critical | `BalanceSimulator.gd` thorn/lethal shadow | thorn/self-damage 的 `player_hp_lost` 遗物必须立即更新后续 damage 与 card-played 所用势能 |

### 问题汇总（按严重度）

- **Critical（阻断）**：2，均已补失败 fixture 并完成 RED→GREEN 修复。
- **Major（应修）**：无。
- **Minor（记录后续）**：无。
- 修复后隔离 HOME 下 editor import 与三项脚本回归全绿。

### 裁决

- [x] 有 critical → 已打回并完成两项窄修复；进入 Round 7 独立复审
- [ ] 仅 major/minor → 放行
- [ ] 全通过

## Review Round 7

### 被评审对象

- 任务：`02-competent-combat-and-elite-safety`
- diff 范围：`c5a4fc0..working tree`（Round 6 修复后）
- Stage 2 评审模型：`gpt-5.6-sol`（Codex read-only independent review）
- 独立裁决：`C3/M0/m0`

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| 文件/冻结边界 | 通过 | - | task diff | 跟踪文件与任务产物仍在清单内，CombatState 与生产数据未改 |
| 历史行为/挂载点 | 通过 | - | `BalanceSimulator.gd` | current/v1 继续走旧 scorer；predictor/cache/hard gate 接线正确 |
| AC 边界覆盖 | 不符 | critical | `tests/test_balance_simulator.gd` | 缺 damage→consume→block、card-played block 嵌套链、create-card relic lethal 三类 fixture |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| damage before conditional block | 不符 | critical | `BalanceSimulator.gd` block shadow | damage effect 必须消费 momentum，并让 thorn HP-loss 更新后续 block 快照 |
| nested card-played effects | 不符 | critical | `BalanceSimulator.gd` card-played shadow | `gain_block` 必须执行 `block_gained` 嵌套触发，再判断后续条件 bonus |
| card-created immediate lethal | 不符 | critical | `BalanceSimulator.gd` lethal shadow | `create_card` 必须按创建次数执行 `card_created -> damage_all_enemies` 等真实遗物链 |

### 问题汇总（按严重度）

- **Critical（阻断）**：3，均已补真实 CombatState 对照 fixture 并完成 RED→GREEN 修复。
- **Major（应修）**：无。
- **Minor（记录后续）**：无。
- 修复后隔离 HOME 下 editor import 与三项脚本回归全绿。

### 裁决

- [x] 有 critical → 已打回并完成三项窄修复；进入 Round 8 独立复审
- [ ] 仅 major/minor → 放行
- [ ] 全通过

## Review Round 8

### 被评审对象

- 任务：`02-competent-combat-and-elite-safety`
- diff 范围：`c5a4fc0..working tree`（Round 7 修复后）
- Stage 2 评审模型：`gpt-5.6-sol`（Codex read-only independent review）
- 独立裁决：`C6/M0/m0`

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| 文件/冻结边界 | 通过 | - | task diff | 改动仍限 simulator、测试、审计文档与任务产物；生产数值、CombatState、地图与正式 matrix 未改 |
| 历史行为/挂载点 | 通过 | - | `BalanceSimulator.gd` | current/v1 继续走旧 scorer；v2 predictor/cache/hard gate 保持接线 |
| AC 边界覆盖 | 不符 | critical | `tests/test_balance_simulator.gd` | 缺破盾、反压、Boss 转阶段副作用、card-played 资源/护甲、顺序状态与通常中位数六类 fixture |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| shield-break relic chain | 不符 | critical | `BalanceSimulator.gd` damage shadow | 护甲从正数降为零时执行 `enemy_block_broken -> damage_broken_enemy` |
| counter-pressure random damage | 不符 | critical | `BalanceSimulator.gd` block shadow | 获得护甲后对唯一存活敌人确定性模拟反压伤害，并保留嵌套破盾链 |
| boss phase on-enter effects | 不符 | critical | `BalanceSimulator.gd` phase shadow | 阶段入口除 block 外还需执行状态与 `create_card -> card_created` 递归触发 |
| card-played resources and block | 不符 | critical | `BalanceSimulator.gd` starter/block helpers | card-played 抽牌、能量、势能与 `gain_block -> block_gained` 必须进入顺序和生存评分 |
| post-effect incoming status order | 不符 | critical | `BalanceSimulator.gd` incoming estimator | 按 effect 顺序维护 momentum、状态、伤害、创建牌、护甲与 card-played 快照 |
| elite winning-HP median | 不符 | critical | `BalanceSimulator.gd:_elite_prediction_summary` | 偶数胜局采用两个中间值的算术平均，不得取较低中位数 |

### 问题汇总（按严重度）

- **Critical（阻断）**：6，均已新增真实结算或纯边界 fixture，并完成 RED→GREEN 窄修复。
- **Major（应修）**：无。
- **Minor（记录后续）**：无。
- 修复后隔离 `HOME=/tmp/ember021_review_home` 下 editor import、`test_balance_simulator.gd`、`test_combat_core.gd`、`test_numerical_balance_matrix.gd` 全绿；`git diff --check` 通过。

### 裁决

- [x] 有 critical → 已打回并完成六项窄修复；进入 Round 9 独立复审
- [ ] 仅 major/minor → 放行
- [ ] 全通过

## Review Round 9

### 被评审对象

- 任务：`02-competent-combat-and-elite-safety`
- diff 范围：`c5a4fc0..working tree`（Round 8 修复后）
- Stage 2 评审模型：独立 Codex 强模型只读复审
- 独立裁决：`C2/M0/m0`

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| 文件/冻结边界 | 通过 | - | task diff | 文件清单合规，冻结生产数据、CombatState、地图、Main 与正式 matrix 均未改 |
| 历史行为/挂载点 | 通过 | - | `BalanceSimulator.gd` | current/v1 仍走旧 scorer；3-seed、cache、副作用隔离与 hard gate 接线正确 |
| AC 边界覆盖 | 不符 | critical | `tests/test_balance_simulator.gd` | 缺 Boss 新阶段意图和 bonus 破盾后尖刺两类真实结算 fixture |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| phase action synchronization | 不符 | critical | `BalanceSimulator.gd:_apply_shadow_phase_effects_after_hit` | 对齐 `_enter_enemy_phase`，同步 phase_data、intent_index 与新阶段首个 current_action |
| bonus thorn after shield-break kill | 不符 | critical | `BalanceSimulator.gd:_apply_shadow_bonus_damage` | 破盾遗物完成击杀后仍先结算 attack-source thorn，再返回 lethal |

### 问题汇总（按严重度）

- **Critical（阻断）**：2，均已新增真实 `CombatState` 对照 fixture 并完成 RED→GREEN。
- **Major（应修）**：无。
- **Minor（记录后续）**：无。
- 修复后隔离 `HOME=/tmp/ember021_review_home` 下 editor import、`test_balance_simulator.gd`、`test_combat_core.gd`、`test_numerical_balance_matrix.gd` 全绿；`git diff --check` 通过。

### 裁决

- [x] 有 critical → 已打回并完成两项窄修复；进入 Round 10 独立复审
- [ ] 仅 major/minor → 放行
- [ ] 全通过

## Review Round 10

### 被评审对象

- 任务：`02-competent-combat-and-elite-safety`
- diff 范围：`c5a4fc0..working tree`（Round 9 修复后）
- Stage 2 评审模型：独立 Codex 强模型只读复审
- 独立裁决：`C2/M0/m1`

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| 文件/冻结边界 | 通过 | - | task diff | 清单与冻结边界合规 |
| 历史行为/预测门 | 通过 | - | `BalanceSimulator.gd` | current/v1、3-seed、cache、副作用隔离与 hard gate 均保持正确 |
| AC 边界覆盖 | 不符 | critical | `tests/test_balance_simulator.gd` | 阶段入口 player effect 与空 actions fallback 缺真实对照 |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| phase player effects | 不符 | critical | `BalanceSimulator.gd:_apply_shadow_phase_effects_after_hit` | 对齐 `_resolve_enemy_effect` 的 player-target apply_status 与 damage 顺序 |
| phase action fallback | 不符 | critical | 同上 | 阶段 actions 为空时回退 `enemy.data.actions`，与 `_enemy_actions` 一致 |
| performance evidence | 过期 | minor | `docs/11_STRATEGY_COMPONENT_AUDIT_021.md` | 更新到最新 smoke 路径与耗时 |

### 问题汇总（按严重度）

- **Critical（阻断）**：2，均已新增真实 `CombatState` 对照 fixture 并完成 RED→GREEN。
- **Major（应修）**：无。
- **Minor（记录后续）**：1，已更新为 Round 10 smoke 证据。
- 修复后隔离 HOME 下 editor import 与三项脚本回归全绿；冻结文件无 diff，`git diff --check` 通过；v2 1-run smoke `real 0.35s`。

### 裁决

- [x] 有 critical → 已打回并完成两项窄修复；进入 Round 11 独立复审
- [ ] 仅 major/minor → 放行
- [ ] 全通过

## Review Round 11

### 被评审对象

- 任务：`02-competent-combat-and-elite-safety`
- diff 范围：`c5a4fc0..working tree`（Round 10 修复后）
- Stage 2 评审模型：独立 Codex 强模型只读复审
- 独立裁决：`C3/M0/m0`

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| 文件/冻结边界 | 通过 | - | task diff | 清单与全部冻结边界合规 |
| 历史行为/预测门 | 通过 | - | `BalanceSimulator.gd` | current/v1、3-seed、cache、副作用隔离与 hard gate 保持正确 |
| AC 边界覆盖 | 不符 | critical | `tests/test_balance_simulator.gd` | 缺后置 block、阶段 hit 玩家 thorn、递归阶段 action 三类顺序 fixture |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| resolved damage vs later block | 不符 | critical | `BalanceSimulator.gd` competent defense score | 已发生的阶段伤害不得与整张牌最终 block 聚合抵扣 |
| player thorn after phase hit | 不符 | critical | phase damage loop | 每 hit 后执行玩家 thorn，并递归检查敌人阶段/死亡 |
| recursive phase action | 不符 | critical | phase action selection | on-enter 递归转阶段后读取最新 `enemy.phase_data`，不能用外层旧 phase |

### 问题汇总（按严重度）

- **Critical（阻断）**：3，均已新增真实 `CombatState` 对照 fixture 并完成 RED→GREEN。
- **Major（应修）**：无。
- **Minor（记录后续）**：无。
- 修复后删除无消费者的 `resolved_incoming`，仅保留阶段伤害消费既有/先置护甲所需的 `block_spent`；隔离 HOME 四项自检、冻结核对与 `git diff --check` 全绿；v2 smoke `real 0.43s`。

### 裁决

- [x] 有 critical → 已打回并完成三项窄修复；进入 Round 12 独立复审
- [ ] 仅 major/minor → 放行
- [ ] 全通过

## Review Round 12

### 被评审对象

- 任务：`02-competent-combat-and-elite-safety`
- diff 范围：`c5a4fc0..working tree`（Round 11 修复后）
- Stage 2 评审模型：独立 Codex 强模型只读复审
- 独立状态：评审进程最终回传发生 `invalid_encrypted_content`，未形成完整 `C/M/m`；中断前已确认至少 1 个 critical，故严格阻断并按 `C≥1` 处理。

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| 文件/冻结边界 | 通过 | - | task diff | 清单与冻结边界合规 |
| 历史行为/预测门 | 通过 | - | `BalanceSimulator.gd` | current/v1、3-seed、cache、副作用隔离与 hard gate 保持正确 |
| AC 边界覆盖 | 不符 | critical | `tests/test_balance_simulator.gd` | 缺阶段结算后 HP/剩余护甲 survival snapshot fixture |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| post-phase survival snapshot | 不符 | critical | `BalanceSimulator.gd` competent defense score | future incoming 必须使用阶段结算后的 HP 与剩余护甲，初始护甲不能重复抵扣 |

### 问题汇总（按严重度）

- **Critical（阻断）**：至少 1；已补“阶段消耗初始 block 后不可复用”和“阶段 HP loss 后未来攻击致死/后置 block 可救”两组真实 fixture，并完成 RED→GREEN。
- **Major/Minor**：完整评审因外部回传异常未完成，不据此宣称为 0；必须重新进行完整独立复审。
- 实现新增共享 `_shadow_card_resolution` 与 `_estimated_card_survival_summary`，评分读取结算后的 HP、剩余初始/卡牌护甲与 future incoming；`_estimated_card_block_gain` 已收敛为复用同一 summary，删除重复结算循环。
- 修复后隔离 HOME 四项自检、冻结核对和 `git diff --check` 全绿；v2 smoke `real 1.01s`。

### 裁决

- [x] 评审中断且已发现 critical → 已打回修复，必须重新完整复审
- [ ] 仅 major/minor → 放行
- [ ] 全通过

## Review Round 13

### 被评审对象

- 任务：`02-competent-combat-and-elite-safety`
- diff 范围：`c5a4fc0..working tree`（Round 12 修复后）
- Stage 2 评审模型：独立 Codex 强模型只读复审
- 独立裁决：`C2/M1/m0`

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| 文件/冻结边界 | 通过 | - | task diff | 文件清单合规；生产数值、CombatState、地图、Main、正式 matrix 与真人报告均未改 |
| 历史行为/挂载点 | 通过 | - | `BalanceSimulator.gd` | current/v1 继续走旧 scorer；v2 predictor/cache/hard gate 接线保持正确 |
| 已消费卡牌护甲 | 不符 | critical | `tests/test_balance_simulator.gd` | 缺“卡牌护甲在阶段入口已消费但真实救命”的选牌与生存快照 fixture |
| 敌方 action effects 顺序 | 不符 | critical | `tests/test_balance_simulator.gd` | future incoming 未由真实 action effects 顺序验证，跨敌人 vulnerable 增伤会被 intent 汇总漏掉 |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| spent card block survival value | 不符 | critical | `BalanceSimulator.gd:_competent_card_score` | 区分已用于吸收阶段伤害的卡牌护甲与结算后剩余护甲，前者也必须计入真实防致死价值 |
| ordered future action simulation | 不符 | critical | `BalanceSimulator.gd` future turn helper | 按敌人及 effect 顺序执行伤害/状态，不能只相加 intent；保留 intent-only fixture 的显式兼容 fallback |
| duplicated card resolution | 不符 | major | fatal/lethal/survival helpers | fatal、lethal 与 survival 应共享单一卡牌 shadow 解析，避免分支漂移并控制 3×4×64 性能 |

### 问题汇总（按严重度）

- **Critical（阻断）**：2；均已补真实 `CombatState` 对照 fixture，并完成 RED→GREEN。
- **Major（应修）**：1；Green 收敛中已让 fatal、lethal、survival 共用 `_shadow_card_resolution` 与 `killed_any`。
- **Minor（记录后续）**：无。
- 修复后隔离 `HOME=/tmp/ember021_review_home` 下 editor import、`test_balance_simulator.gd`、`test_combat_core.gd`、`test_numerical_balance_matrix.gd` 全绿；冻结文件无 diff，`git diff --check` 通过；v2 1-run smoke `real 0.70s`。

### 裁决

- [x] 有 critical/major → 已完成窄修复与最小实现收敛；进入 Round 14 完整独立复审
- [ ] 仅 major/minor → 放行
- [ ] 全通过

## Review Round 14

### 被评审对象

- 任务：`02-competent-combat-and-elite-safety`
- diff 范围：`c5a4fc0..working tree`（Round 13 修复后）
- Stage 2 评审模型：独立 Codex 强模型只读复审
- 独立状态：协作流因账户并发限制中断，后备只读进程因上游 CPU 过载返回 503；未形成完整 `C/M/m`，但中断前已确认至少 1 个 critical，严格按 `C≥1` 阻断。

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| 文件/冻结边界 | 通过 | - | task diff | 主会话机械核对仍只涉及清单内 simulator、测试、审计文档与任务产物；冻结文件无 diff |
| AC 边界覆盖 | 不符 | critical | `tests/test_balance_simulator.gd` | 缺 enemy turn-start block reset / burn before action 的真实对照 fixture |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| enemy turn-start ordering | 不符 | critical | `BalanceSimulator.gd:_simulate_shadow_enemy_turn` | 对齐 `CombatState.prepare_enemy_turn`：先清敌方 block、结算 burn 与阶段切换，burn 击杀后不得执行 action |

### 问题汇总（按严重度）

- **Critical（阻断）**：至少 1；已新增 1 HP/1 burn/20 damage 的真实 `CombatState` 对照 fixture，并完成 RED→GREEN。
- **Major/Minor**：评审流中断，不能据此宣称为 0；必须重新执行完整独立复审。
- 修复后隔离 HOME 下 editor import 与三项脚本回归全绿；冻结文件无 diff，`git diff --check` 通过；v2 smoke `real 0.67s`。

### 裁决

- [x] 评审中断且已发现 critical → 已打回修复，进入 Round 15 完整独立复审
- [ ] 仅 major/minor → 放行
- [ ] 全通过

## Review Round 15

### 被评审对象

- 任务：`02-competent-combat-and-elite-safety`
- diff 范围：`c5a4fc0..working tree`（Round 14 修复后）
- Stage 2 评审模型：独立 Codex 强模型只读复审
- 独立裁决：`C2/M0/m0`

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| 文件/冻结边界 | 通过 | - | task diff | 清单合规；CombatState、生产数据、地图、正式 matrix 与真人报告未改 |
| 历史行为/精英门 | 通过 | - | `BalanceSimulator.gd` | current/v1 旧 scorer、3-seed、完整 cache、RNG/副作用隔离和 v2 hard rejection 保持正确 |
| burn phase 边界覆盖 | 不符 | critical | `tests/test_balance_simulator.gd` | 缺阶段入口嵌套杀敌跳过 action，以及入口 damage 进入 future incoming 两类 fixture |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| post-phase enemy death | 不符 | critical | `BalanceSimulator.gd:_simulate_shadow_enemy_turn` | burn 阶段入口递归结束后重新检查 enemy HP；死亡则跳过 action |
| burn-phase incoming accounting | 不符 | critical | `_simulate_shadow_enemy_turn` / `_apply_shadow_phase_effects_after_hit` | 阶段入口 damage 与随后 action damage 都必须进入 future incoming，同时不得重复 card-time 已结算伤害 |

### 问题汇总（按严重度）

- **Critical（阻断）**：2；均已新增真实 `CombatState` 对照 fixture 并分两轮完成 RED→GREEN。
- **Major（应修）**：无。
- **Minor（记录后续）**：无。
- 修复后隔离 HOME 下 editor import、`test_balance_simulator.gd`、`test_combat_core.gd`、`test_numerical_balance_matrix.gd` 全绿；冻结文件无 diff，`git diff --check` 通过；v2 smoke `real 0.58s`。

### 裁决

- [x] 有 critical → 已完成两项窄修复；进入 Round 16 完整独立复审
- [ ] 仅 major/minor → 放行
- [ ] 全通过

## Review Round 16

### 被评审对象

- 任务：`02-competent-combat-and-elite-safety`
- diff 范围：`c5a4fc0..working tree`（Round 15 修复后）
- Stage 2 评审模型：独立 Codex 强模型只读复审
- 独立裁决：`C1/M0/m0`

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| 文件/冻结边界 | 通过 | - | task diff | 文件清单、禁止项与冻结边界合规 |
| 历史行为/精英门 | 通过 | - | `BalanceSimulator.gd` | current/v1 旧 scorer、3-seed/cache/副作用隔离/hard rejection 无新增偏差 |
| 多敌 prepare/resolve 覆盖 | 不符 | critical | `tests/test_balance_simulator.gd` | 缺全体 prepare 完成后才执行首个 action 的跨敌状态 fixture |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| global enemy-turn ordering | 不符 | critical | `BalanceSimulator.gd:_simulate_shadow_enemy_turn` | 对齐生产两阶段循环：先 reset/burn/phase 全体，再 resolve action 全体 |

### 问题汇总（按严重度）

- **Critical（阻断）**：1；已新增后排 burn 阶段 vulnerable 影响前排随后 action 的真实对照，并完成 RED→GREEN。
- **Major（应修）**：无。
- **Minor（记录后续）**：无。
- 修复后隔离 HOME 下四项自检全绿；冻结文件无 diff，`git diff --check` 通过；v2 smoke `real 0.66s`。

### 裁决

- [x] 有 critical → 已完成全体 prepare/resolve 顺序修复；进入 Round 17 完整独立复审
- [ ] 仅 major/minor → 放行
- [ ] 全通过

## Review Round 17

### 被评审对象

- 任务：`02-competent-combat-and-elite-safety`
- diff 范围：`c5a4fc0..working tree`（Round 16 修复后）
- Stage 2 评审模型：独立 Codex 强模型只读复审
- 独立裁决：`C1/M0/m0`

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| 文件/冻结边界与挂载点 | 通过 | - | task diff | 清单、禁止项、current/v1、精英门与其余 AC 未见新增偏差 |
| next-player-turn burn 覆盖 | 不符 | critical | `tests/test_balance_simulator.gd` | AC-021-08 缺 enemy resolve 后 player burn 直接致死的真实 fixture |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| next player-turn survival | 不符 | critical | `BalanceSimulator.gd:_simulate_shadow_enemy_turn` | 若仍有存活敌人，对齐 `_start_player_turn_internal` 的 clear block→player burn→lost 检查后再返回 survives |

### 问题汇总（按严重度）

- **Critical（阻断）**：1；已新增 self burn 2 / HP 2 / enemy alive 的真实对照并完成 RED→GREEN。
- **Major（应修）**：无。
- **Minor（记录后续）**：无。
- 修复后隔离 HOME 四项自检全绿；冻结文件无 diff，`git diff --check` 通过；v2 smoke `real 0.35s`。

### 裁决

- [x] 有 critical → 已补 next-player-turn burn 生存边界；进入 Round 18 完整独立复审
- [ ] 仅 major/minor → 放行
- [ ] 全通过

## Review Round 18

### 被评审对象

- 任务：`02-competent-combat-and-elite-safety`
- diff 范围：`c5a4fc0..working tree`（Round 17 修复后）
- Stage 2 独立评审：两个全新只读进程均因上游 `429 Too Many Requests` 超过重试上限，未形成裁决；不视为通过。
- 本地主会话完成性审计：确认 `C1` 并完成 RED→GREEN；仍必须重新取得独立完整裁决。

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| 文件/冻结边界 | 通过 | - | task diff | 仍只修改清单内文件，冻结边界无 diff |
| next-turn burn 选牌覆盖 | 不符 | critical | `tests/test_balance_simulator.gd` | 缺高伤 self-burn 必死牌与安全低伤牌的选择对照 |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| survival result wiring | 不符 | critical | `BalanceSimulator.gd:_competent_card_score` | 无 block 卡牌也必须读取 next-player-turn burn 生存结果；只拒绝敌方行动后仍活、随后由 burn 新致死的路线 |

### 问题汇总（按严重度）

- **Critical（阻断）**：1；已新增真实选择对照并完成 RED→GREEN。
- **Major/Minor**：独立评审未完成，不能宣称为 0。
- 修复后隔离 HOME 四项自检全绿；冻结文件无 diff，`git diff --check` 通过；v2 smoke `real 0.71s`。

### 裁决

- [x] 独立评审中断且本地发现 critical → 已修复，必须重新完整独立复审
- [ ] 仅 major/minor → 放行
- [ ] 全通过

## Review Round 19

### 被评审对象

- 任务：`02-competent-combat-and-elite-safety`
- diff 范围：`c5a4fc0..working tree`（Round 18 修复后）
- Stage 2 评审模型：独立 Codex 强模型只读复审
- 独立裁决：`C1/M0/m0`

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| 文件/冻结边界 | 通过 | - | task diff | 清单、禁止项、挂载点与 current/v1 兼容均通过 |
| 多段 phase/thorn 覆盖 | 不符 | critical | `tests/test_balance_simulator.gd` | 缺首 hit thorn 触发 phase、后续 hit 状态更新的真实对照 |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| per-hit enemy damage state | 不符 | critical | `BalanceSimulator.gd:_apply_shadow_enemy_damage_effect` | 每 hit 重新读取最新 enemy/player shadow 状态；effect-start weak/vulnerable 消费仍只消费原有层数 |

### 问题汇总（按严重度）

- **Critical（阻断）**：1；已新增 thorn→phase→后续 hit 真实对照并完成 RED→GREEN。
- **Major（应修）**：无。
- **Minor（记录后续）**：无。
- 修复后隔离 HOME 下四项自检全绿；冻结文件无 diff，`git diff --check` 通过；v2 smoke `real 0.69s`。

### 裁决

- [x] 有 critical → 已完成 per-hit 状态修复；进入 Round 20 完整独立复审
- [ ] 仅 major/minor → 放行
- [ ] 全通过

## Review Round 20

### 被评审对象

- 任务：`02-competent-combat-and-elite-safety`
- diff 范围：`c5a4fc0..working tree`（Round 19 修复后）
- Stage 2 评审模型：独立 Codex 强模型只读复审
- 独立裁决：`C2/M0/m0`

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| 文件/冻结边界与挂载点 | 通过 | - | task diff | 清单、禁止项、current/v1、精英门与已有挂载点均通过 |
| partial lethal next-turn burn 覆盖 | 不符 | critical | `tests/test_balance_simulator.gd` | immediate lethal 旁路缺只击杀部分敌人且下一回合 self burn 致死的真实 fixture |
| player multi-hit phase state 覆盖 | 不符 | critical | `tests/test_balance_simulator.gd` | 缺首 hit 触发 Boss phase、后续 hit 读取新 vulnerable 的真实 fixture |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| immediate lethal survival gate | 不符 | critical | `BalanceSimulator.gd:_competent_immediate_lethal_decision` | immediate lethal 除当前 HP 成本外必须读取完整 next-turn survival summary |
| player damage hit state | 不符 | critical | `BalanceSimulator.gd:_apply_shadow_damage_effect` | 每 hit 重新读取当前玩家/敌人状态，保留 effect-start 状态消费边界 |

### 问题汇总（按严重度）

- **Critical（阻断）**：2；均新增真实 `CombatState` 对照并完成 RED→GREEN。
- **Major（应修）**：无。
- **Minor（记录后续）**：无。
- 修复后隔离 HOME 下 editor import、`test_balance_simulator.gd`、`test_combat_core.gd`、`test_numerical_balance_matrix.gd` 全绿；冻结核对与 `git diff --check` 通过；可比 v2 单格 smoke `real 0.55s`。

### 裁决

- [x] 有 critical → 已完成两项窄修复与 resolution 复用收敛；进入 Round 21 完整独立复审
- [ ] 仅 major/minor → 放行
- [ ] 全通过

## Review Round 21

### 被评审对象

- 任务：`02-competent-combat-and-elite-safety`
- diff 范围：`c5a4fc0..working tree`（Round 20 修复后）
- Stage 1/2 评审：独立强模型只读复审
- 独立裁决：`C0/M0/m0`

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| AC-021-07～14 | 通过 | - | `tests/test_balance_simulator.gd` | 每条 AC 均有确定性 fixture；独立四项自检退出码均为 0 |
| 文件清单/禁止项 | 通过 | - | `c5a4fc0..working tree` | 4 个 tracked 改动与 2 个任务产物均在清单内；冻结边界无 diff |
| 决策表/current-v1 | 通过 | - | `BalanceSimulator.gd:_choose_card` | current/v1 保留旧 scorer；competent/v2 才进入新 helper |
| 挂载点 | 通过 | - | combat/campaign flow | combat dispatch、scorer、predictor、state cache、hard rejection 五项均已接线 |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| partial lethal survival | 通过 | - | `BalanceSimulator.gd:_competent_immediate_lethal_decision` | 单一 resolution 进入完整 survival summary；部分击杀后仍结算 next-turn burn |
| player multi-hit phase state | 通过 | - | `BalanceSimulator.gd:_apply_shadow_damage_effect` | effect-start momentum/hits 固定，每 hit 重读双方状态，只消费起点状态 |
| predictor/cache/hard gate | 通过 | - | elite prediction and route helpers | 3 seed、完整 key、私有 RNG、cache hit、仅 v2 optional gate 与拒绝传播均符合契约 |
| 结构/性能 | 通过 | - | private shadow helpers | 无平行结算器或新依赖；可比单格 smoke `real 0.55s` |

### 问题汇总（按严重度）

- **Critical（阻断）**：0。
- **Major（应修）**：0。
- **Minor（记录后续）**：0。
- 残余范围仅为 021-03 明确负责的四 profile `3×4×64` paired verification，不属于本子任务 finding。

### 裁决

- [ ] 有 critical → 打回
- [ ] 仅 major/minor → 放行
- [x] 全通过：`C0/M0/m0`，允许提交 021-02
