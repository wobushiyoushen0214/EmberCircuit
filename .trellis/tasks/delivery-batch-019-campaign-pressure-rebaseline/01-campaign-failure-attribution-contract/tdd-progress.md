# 019-01 TDD 进度

| AC ID | 期望可观察结果 | 测试文件 | 测试命令 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- |
| AC-019-01 | campaign case 输出 schema、章节快照和跨章行且可复现 | `tests/test_balance_simulator.gd` | `Godot --headless --path . --script res://tests/test_balance_simulator.gd` | pending | |
| AC-019-02 | 章节 entry/completion/resource 聚合可由 runs 复算 | `tests/test_balance_simulator.gd` | 同上 | pending | |
| AC-019-03 | 64 不 eligible，128 才评估失败集中度 | `tests/test_balance_simulator.gd` | 同上 | pending | |
| AC-019-04 | summary 按角色与挑战输出归因且保留旧字段 | `tests/test_balance_simulator.gd` | 同上 | pending | |
| AC-019-05 | 旧 campaign/single/matrix 回归全绿且无生产 JSON 变化 | `tests/test_balance_simulator.gd` | 任务自检全集 | pending | |

## 收尾核对

- [ ] 所有 AC 为 done。
- [ ] 已执行最小实现收敛并记录删除/复用/保留项。
- [ ] 未 commit，已暂存，等待双阶段评审。

## 最小实现收敛

- 删除项：pending。
- 复用项：现有 campaign 聚合、DataLoader、numerical_tree targets。
- 保留项：旧字段、样本门、seed 配对和回归断言。
