# Design: 020-02 competent-player-v1

## 需求覆盖

| 需求 | 当前 | 设计元素 | 预期 |
| --- | --- | --- | --- |
| REQ-003/004/005/009 | PARTIAL | profile-specific route/reward/campfire/upgrade/potion decisions and paired report | PARTIAL with falsifiable strategy evidence |

## 编排-计算分离

| 层 | 元素 | 落点 |
| --- | --- | --- |
| 编排层 | profile dispatch in campaign node/reward/combat flow | `scripts/tools/BalanceSimulator.gd` existing campaign methods |
| 计算层 | role/deck reward score, route pressure estimate, profile normalization, action gates | `BalanceSimulator.gd` private helpers |
| Verification | CLI option and report comparison | `tools/run_balance_simulation.gd`, `docs/10_STRATEGY_DIFFERENTIAL_020.md` |

## 挂载点

| 挂载点 | 类型 | 位置 | 接线动作 |
| --- | --- | --- | --- |
| Profile dispatch | API/state | `run_campaign_suite` -> `_run_campaign_once` | carry exact profile into state |
| Route choice | strategy branch | `_campaign_node_score`/`_campaign_route_preview_score` | use competent helper only for competent profile |
| Reward/upgrade | strategy branch | `_offer_card_reward`/`_simulate_campaign_shop`/`_best_upgrade_index` | preserve old branch and use deck state |
| Combat resources | strategy branch | `_simulate_campaign_campfire`/`_try_use_potion` | record chosen action and consume only valid potion |
| Differential evidence | CLI/docs | `run_balance_simulation.gd` and docs | save two reports and gate result |

## 非目标

- 不重写 CombatState 或建立第二套战斗规则。
- 不以单个 seed、单卡 lift 或 128 报告直接修改生产数值。
