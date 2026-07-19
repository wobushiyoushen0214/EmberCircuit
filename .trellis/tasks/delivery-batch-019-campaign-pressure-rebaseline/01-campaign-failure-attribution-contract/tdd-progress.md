# 019-01 TDD 进度

| AC ID | 期望可观察结果 | 测试文件 | 测试命令 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- |
| AC-019-01 | campaign case 输出 schema、章节快照和跨章行且可复现 | `tests/test_balance_simulator.gd` | `Godot --headless --path . --script res://tests/test_balance_simulator.gd` | done | RED 后加入 report/case schema 与 deterministic raw chapter/transition snapshots；旧 smoke 全绿 |
| AC-019-02 | 章节 entry/completion/resource 聚合可由 runs 复算 | `tests/test_balance_simulator.gd` | 同上 | done | RED 后加入按实际 entry/transition 样本聚合；局部缩进调试 1 轮后原命令全绿 |
| AC-019-03 | 64 不 eligible，128 才评估失败集中度 | `tests/test_balance_simulator.gd` | 同上 | done | 64/128 边界与 normalized top encounter share 全绿 |
| AC-019-04 | summary 按角色与挑战输出归因且保留旧字段 | `tests/test_balance_simulator.gd` | 同上 | done | summary 新增稳定排序的角色/挑战行，旧 challenge_targets 保留并全绿 |
| AC-019-05 | 旧 campaign/single/matrix 回归全绿且无生产 JSON 变化 | `tests/test_balance_simulator.gd` | 任务自检全集 | done | sample_runs 保留 raw snapshots；128×12 report 两次 SHA-256 均为 `329d716d39f71162392bde406f2484ce81456691a67c825f10be43732a6cdd2e`；editor/pressure/matrix 全绿 |

## 收尾核对

- [x] 所有 AC 为 done。
- [x] 已执行最小实现收敛并记录删除/复用/保留项。
- [x] 未 commit，已暂存，等待双阶段评审。

## 最小实现收敛

- 删除项：case 级第 0 个 run raw snapshot 字段，避免把代表性样本误标为 aggregate；raw 仅保留在 sample_runs。
- 复用项：现有 campaign 聚合、DataLoader、numerical_tree targets。
- 保留项：旧字段、样本门、seed 配对和回归断言。
