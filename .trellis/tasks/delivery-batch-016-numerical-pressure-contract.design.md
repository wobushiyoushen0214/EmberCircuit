# Design: 数值压力契约

## 编排-计算分离

| 层 | 元素 | 落点 |
| --- | --- | --- |
| 纯计算层 | nearest-rank、单战聚合、风险排序、循环空窗、前三行动伤害、EHP 比 | `scripts/tools/NumericalPressureMetrics.gd` |
| Auditor 编排层 | 加载角色/卡牌/遗物/技能书/挑战/敌人，组织 opening 与静态压力输入 | `scripts/tools/NumericalTreeAuditor.gd` |
| Simulator 编排层 | 收集逐局结果、绑定 chapter/tier/expected turns、保留旧字段 | `scripts/tools/BalanceSimulator.gd` |
| 质量门 | 冻结 schema、错误基线、current-greedy 声明与 21 套回归 | 三个既有数值测试 + 一个新纯计算测试 |

## 数据契约

### Player opening 字段

- `opening_package_score`
- `opening_package_target_min/max`
- `opening_package_contributions[]`: `category/source_id/trigger/effect_type/raw_amount/point_weight/score`
- `opening_package_exclusions[]`
- `opening_package_severity`
- `opening_package_issues[]`

只计算确定性开局收益：起始牌组、初始势能、无条件 `combat_start`、`turn_start+first_turn_only` 和默认技能书。条件性触发只记录 exclusions。

### Single case 字段

- `chapter_id`
- `loadout_profile=starter_deck_relics`
- `strategy_profile=current-greedy`
- `pressure_contract_version`
- `pressure_gate_eligible`
- `zero_damage_win_count` / `perfect_win_rate`
- `hp_loss_p50/p90`
- `turn_sample_count` / `turns_p50/p90`
- `cards_played_per_turn`
- `expected_turns_min/max`
- `risk_flags[]` / `risk_flag`

### Monster pressure 字段

- `base_action_count`
- `base_direct_damage_action_count`
- `base_attack_action_ratio`
- `base_longest_zero_direct_damage_actions`
- `base_first_three_action_damage_total`
- `pressure_profiles[]`
- `effective_hp_challenge_level/effective_hp`
- `chapter_highest_elite_effective_hp`
- `boss_to_highest_elite_ehp_ratio`
- `pressure_severity/pressure_issues[]`

## 风险优先级

1. `timeout_check`
2. `<tier>_too_lethal`
3. `<tier>_too_easy`
4. `encounter_too_fast`
5. `encounter_too_slow`

`risk_flags` 保留全部命中项；`risk_flag` 取首项，否则为 `ok`。

## 循环行动算法

- attack ratio 只统计基础 action 中直接伤害玩家的 action 数。
- 最长零伤空窗把循环尾部和开头相连，最大不超过周期长度；多敌遭遇取单敌最大值。
- 前三行动从 action 0 开始，短循环用 modulo 重复，对全部敌人求和。
- phase 独立输出 profile，不与基础循环平均。

## 挂载点清单

- [ ] `BalanceSimulator._aggregate_case()` 接入纯计算 pressure 聚合。
- [ ] single/campaign 顶层输出 `strategy_profile=current-greedy`。
- [ ] `NumericalTreeAuditor._audit_players()` 输出 opening package 独立压力字段。
- [ ] `NumericalTreeAuditor._audit_monsters()` 输出静态压力与章节 EHP 层级。
- [ ] 冻结矩阵记录当前异常，供 Batch 017 单调消除。

## 非目标

- 不改变 CombatState、敌人行动或任何正式数值。
- 不实现高手 AI。
- 不把 pressure warning 合并进旧 budget warning。
