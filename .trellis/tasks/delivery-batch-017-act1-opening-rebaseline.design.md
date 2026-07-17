# Design: 第一章与开局重标定

## 编排-计算分离

| 层 | 元素 | 落点 |
| --- | --- | --- |
| 数据层 | 卡牌、角色、遗物、敌人、经济、数值树、scaling | `data/**.json` |
| 战斗编排 | single 默认 modifier source | `BalanceSimulator._run_single_combat()` |
| 报告编排 | loadout/skill book/profile 与 paired evidence | `BalanceSimulator._aggregate_case()` 和 CLI |
| 显示编排 | 三种复合意图的文字、图标、颜色、投射 | `Main.gd` intent helpers |
| 质量门 | 精确数据、静态压力、single/campaign 与运行时行为 | 7 个既有测试 + `test_act1_rebaseline.gd` |

## MVP 兼容性契约

- 战斗效果仍完全由 action `effects[]` 结算；intent 只做准确预告。
- campaign 继续使用默认 `steel_manual`，single 只补齐此前缺失的同源 modifier。
- 旧 `risk_flag/risk_flags`、pressure schema 1、current-greedy 与确定性 seed 保留。
- 商店/奖励/删牌价格、挑战倍率、地图、后章敌人与存档不变。

## 复合意图契约

- `attack_block`: `amount/hits` 为伤害，`block` 为自我护甲。
- `attack_buff`: `amount/hits` 为伤害，`status/status_amount` 为自我强化。
- `attack_status_card`: `amount/hits` 为伤害，`card_id/card_amount` 为加入玩家牌堆的状态牌。
- 三者都投射到玩家、使用攻击主色与攻击图标；详细文本必须包含两部分，compact badge 不能把次要效果完全省略。

## 挂载点清单

- [ ] legacy/default Ember 与正式角色配置同步。
- [ ] single combat 接入默认技能书 modifier sources。
- [ ] Simulator 投影伤害识别三种复合攻击。
- [ ] Main intent helpers 完整识别三种复合攻击。
- [ ] numerical tree inventory、矩阵、文档和 22 套回归同步。

## 非目标

- 不重构 1.5 万行 Main；仅做复合意图最小接线，完整拆分留 Batch 018。
- 不升级模拟 AI，不重做二三章，不改变商店购买算法。
