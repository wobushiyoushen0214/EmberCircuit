# 系统化调试报告

## Session 1: JSON 整数类型校验

- 失败命令：`Godot --headless --path . --script res://tests/test_playtest_run_integration.gd`
- 固定信号：合法奖励事务读取后没有恢复，后续精确选项、迁移写回和金币幂等断言连锁失败。
- 定位：在合法事务进入 `_combat_reward_state_matches_current_node()` 前输出字段类型；`schema_version`、`run_gold_before_reward` 和 `combat_reward_gold` 均为 `TYPE_FLOAT`。
- 单一假设：Godot JSON 将落盘整数读为浮点数，`TYPE_INT` 限制误拒绝合法事务。
- 最小修复：新增 `_is_nonnegative_json_integer()`，只接受整数或无小数部分的浮点数，并继续拒绝负数、小数和其他类型；删除临时日志。
- 原命令复跑：通过。
- 防御性回归：同一校验同时保护 schema、金币基线、金币奖励和非法事务金币回滚入口；集成测试覆盖真实 JSON 往返。
