# Design: 021-02 胜任战斗与精英安全

## 需求覆盖

| 需求 | 当前 | 设计 | 预期 |
| --- | --- | --- | --- |
| REQ-003/004/005 | PARTIAL | profile-aware combat scorer、targeter、3-seed elite safety gate | PARTIAL，策略风险可被独立验证 |

## API / State 契约

- `_choose_card(combat, strategy_profile)` 返回现有 `{card_index,target_index}` 形状。
- competent scorer 只读取 combat/card/effect 的真实可观察状态。
- `_elite_survival_prediction(state, encounter_id, combat_profile)` 返回胜数、胜局 HP、中位数与 safe bool；预测不写回输入。
- cache key 为稳定序列化后的完整战斗输入摘要，不使用对象地址。

## 编排-计算分离

| 层 | 元素 | 落点 |
| --- | --- | --- |
| 编排层 | turn loop profile dispatch、v2 路线 gate、3 次只读战斗调用 | `BalanceSimulator.gd` 现有 combat/campaign 流程 |
| 计算层 | lethal、防御缺口、状态/资源顺序评分、target rank、cache key、median/safe 判定 | 同文件私有纯 helper |

## 挂载点清单

| 挂载点 | 类型 | 位置 | 动作 |
| --- | --- | --- | --- |
| Combat dispatch | strategy | `_run_single_combat_with_loadout`→`_choose_card` | 传入 exact combat component |
| Competent scorer | algorithm | `_choose_card` | 仅 combat/v2 分支使用 |
| Elite predictor | safety gate | route preview/node score | v2 optional elite 候选先预测 |
| Cache | state-local cache | campaign state | 完整 key；只复用判定 |
| Hard rejection | route selection | `_choose_next_campaign_node` | 安全候选存在时剔除不安全精英 |

## 非目标

- 不寻找全局最优出牌序列，不做 Monte Carlo tree search。
- 不修改卡牌实际效果、敌人意图或结算顺序。
