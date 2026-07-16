# 设计说明

## 状态层

`CombatState` 使用 `_start_player_turn_internal()` 完成无信号的回合初始化。公开 `start_player_turn()`、`setup()` 与 `end_player_turn()` 各自在完整事务结束时最多发送一次 `changed`。

## 表现层

`Main` 维护单一演出锁和递增票据。出牌和敌方回合各自记录可观测检查点；正式显示后端用短计时器把结算放在动作顶点，headless 测试保持同步确定性。

卡牌顺序：`lock -> windup -> impact -> resolved -> unlock`。

敌方顺序：`lock -> windup -> impact -> resolved -> unlock`。

## 取消与恢复

新演出会生成新票据，过期协程不能继续结算或解锁；场景退出会使票据失效并清除忙碌状态。
