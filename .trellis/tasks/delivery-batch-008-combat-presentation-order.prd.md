# Delivery Batch 008: 战斗演出顺序与输入锁

## 目标

让卡牌与敌方行动遵循“起手演出 -> 命中结算 -> 单次刷新 -> 收尾解锁”，避免数值先跳、动画后补，以及敌方动画期间新手牌已经可操作的问题。

## 验收标准

- AC-001：成功出牌只触发一次 `changed` / UI 刷新，状态结算发生在卡牌起手之后。
- AC-002：结束回合只触发一次 `changed` / UI 刷新，敌方起手发生在伤害和下一回合抽牌之前。
- AC-003：演出期间卡牌点击/拖拽、药水、结束回合和战斗快捷键不可用。
- AC-004：离开场景会废弃未完成的演出票据，不留下永久输入锁。
- AC-005：不修改卡牌、角色、怪物、成长、挑战和经济数值。

## 文件范围

- `scripts/combat/CombatState.gd`
- `scripts/main/Main.gd`
- `tests/test_combat_core.gd`
- `tests/test_combat_presentation.gd`
- `tests/test_run_flow.gd`
- `tools/render_pc_gallery.gd`
- 本批次 Trellis 文档与发布状态文档
