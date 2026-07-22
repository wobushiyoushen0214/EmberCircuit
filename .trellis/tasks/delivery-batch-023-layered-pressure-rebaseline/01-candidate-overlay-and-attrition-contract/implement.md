# Implementation Plan: 023-01

## 文件计划

| 步骤 | 文件 | 操作 | 验证 |
| --- | --- | --- | --- |
| 0 | `/tmp/ember023-default-before.json` | 用任务起点生成 1×1×3 v3 报告 | 文件存在并记录 SHA |
| 1 | `BalanceCandidateOverlay.gd` + fixtures + new test | 写 RED 后实现 schema/allowlist/value/SHA/apply | AC-023-01/02 GREEN |
| 2 | `BalanceSimulator.gd` | 接生命周期适配、恢复与 metadata | AC-023-03 GREEN；默认 cmp 相等 |
| 3 | `run_balance_simulation.gd` | 接 CLI 参数和拒绝退出 | AC-023-04 GREEN |
| 4 | `BalanceSimulator.gd` + new test | 接 opt-in node snapshot 与聚合 | AC-023-05 GREEN |
| 5 | task docs | 记录 RED/GREEN、hash、回归和评审 | 所有清单完成 |

## 修改边界

- 只允许 PRD File Manifest。
- 禁止所有生产 JSON、MapGenerator、CombatState、Main、matrix 与真人报告。
- 新文件生成 `.uid` 后必须纳入提交；不新增插件或依赖。

## 失败恢复

- 默认 cmp 失败：先检查 report/path 是否在 diagnostics 关闭时新增字段，再检查数据恢复是否在所有 return 分支执行。
- 同实例污染：检查赋值是否使用 `duplicate(true)`，不得改成每次重载生产文件掩盖问题。
- 非法 overlay 退出 0：检查 CLI 是否在 save_report 前判断 rejected metadata。
