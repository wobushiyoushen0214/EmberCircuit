# TDD 记录

## RED

- 结束回合原先经 `start_player_turn()` 和自身尾部发送两次 `changed`。
- 主场景原先先调用 `combat.play_card()`，再请求飞行动画。
- 主场景原先先完整执行敌方回合和下一回合抽牌，再播放敌方动作。

## GREEN

- 新增状态层 changed 次数断言。
- 新增 `test_combat_presentation.gd`，覆盖两条顺序、单次刷新和输入拒绝。
- `test_run_flow.gd` 保留真实拖拽出牌单次刷新契约，并断言卡牌演出检查点。

## 回归

- 19/19 Godot 测试通过。
- 严格扫描未发现 `SCRIPT ERROR` 或 `ERROR:`。
