# TDD 进度：021-03

| AC | 可观察结果 | 测试/产物 | 状态 |
| --- | --- | --- | --- |
| AC-021-15 | 四 profile 同 paired options 的 64 报告 | tests + `/tmp` | done：四份 12-case 报告合同一致 |
| AC-021-16 | 逐挑战与 elite 自动 gate | `tests/test_balance_simulator.gd` | done：先 RED 缺 helper，再 GREEN；非法计数 fail-closed、0.02 和 elite 7/20 边界 fixture 全绿 |
| AC-021-17 | current/v1/正式 matrix 兼容 | 两个测试文件 | done：默认/显式 current 同 SHA；v1 fixture 全绿；正式树 SHA/256/profile 冻结 |
| AC-021-18 | 64 FAIL 阻止 128 | `verification-report.md` | done：显式 artifact verifier 确认 C0/C1 第一章与 elite gate FAIL，八个 128 路径均不存在 |
| AC-021-19 | 条件 128 重复 byte-identical | `/tmp` + SHA-256 | not-run-by-gate：按 AC-021-18 禁止启动 128 |
| AC-021-20 | 文档/状态唯一裁决 | docs/state/report | done：记录 `paused_no_strategy_component_passed` 与下一步边界 |

## 收尾核对

- [x] 所有适用 AC done；AC-19 标记 not-run-by-gate，未伪造 128 证据。
- [x] 自检全绿；正式 256 matrix 未变；四份 64 报告哈希齐全。
- [x] 最小实现收敛与双阶段评审完成；最终 Stage 1/2 均为 `C0/M0/m0`。

## 最小实现收敛

- 删除项：无；gate helper 仅包含配对合同、逐挑战聚合和 elite 硬门所需逻辑。
- 复用项：复用报告原始 `wins`、`runs`、`completed_runs`、elite 计数字段及 Godot `HashingContext`，未新增依赖。
- 保留项：保留四 profile/三角色/四挑战完整轴、原始计数合法域、64/128 样本白名单、80 回合、paired seed、整数形式的 0.02/0.35 固定门和正式数值树 SHA 冻结。
- `trellis-minimal:` 注释：无；没有预留扩展抽象。
