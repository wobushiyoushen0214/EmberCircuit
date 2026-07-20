# Implementation Plan: 021-01

## 文件计划

| 步骤 | 文件 | 操作 | 验证 |
| --- | --- | --- | --- |
| 1 | `tests/test_balance_simulator.gd` | 写 AC-021-01～06 失败断言 | 必须先看到 RED |
| 2 | `BalanceSimulator.gd` | profile/constants/components/diagnostics normalization | AC-01/02 GREEN |
| 3 | `BalanceSimulator.gd` | 路线、节点、精英计数与聚合 | AC-03/04 GREEN |
| 4 | `run_balance_simulation.gd` | CLI 参数透传 | CLI fixture GREEN |
| 5 | `docs/11...md` | 回写契约与实测 | 文档无占位符 |

## 结构健康度预检

| 文件 | 当前规模 | 阈值 | 结论 |
| --- | ---: | ---: | --- |
| `BalanceSimulator.gd` | 3009 行 | 400 | 不做跨文件重构；仅复用既有 campaign helper，技术债留后续 |
| `test_balance_simulator.gd` | 370 行 | 400 | 本任务预计越阈值；只增加按 AC 分组 fixture，不抽新测试框架 |
| `run_balance_simulation.gd` | 85 行 | 400 | 无需重构 |

## 修改边界与失败恢复

- 允许：PRD File Manifest；禁止：所有生产 JSON、CombatState、正式 matrix。
- 默认报告变化：先关闭 diagnostics 输出路径并恢复旧字段顺序，不改测试期望。
- 计数不守恒：修唯一 node/result 挂点，不从 aggregate 猜测。
