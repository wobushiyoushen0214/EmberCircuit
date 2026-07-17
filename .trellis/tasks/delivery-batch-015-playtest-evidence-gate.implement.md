# Implementation Plan: 真人试玩证据门

## 结构健康度预检

| 文件 | 当前行数 | 结论 |
| --- | ---: | --- |
| `PlaytestTelemetry.gd` | 841 | 已超 400 行，不再堆入留存/合并算法；新纯计算放 `PlaytestEvidenceGate.gd` |
| `Main.gd` | 15455 | 只改既有导出函数和增加短小 context helper，不做无关重构 |
| `test_playtest_telemetry.gd` | 254 | 只补迁移/兼容断言；大规模新场景放新测试文件 |

## 有序步骤

1. RED AC-001：新建 `test_playtest_evidence_gate.gd`，固定 v1 隔离和 12×35+200 留存失败信号。
2. GREEN AC-001：新建纯计算 gate，升级遥测 schema，接入迁移和留存。
3. RED AC-002：增加双 cohort、12/30 状态、跨报告去重与冲突测试。
4. GREEN AC-002：实现 cohort report 与 `merge_reports()`；保持单 cohort 顶层兼容字段。
5. RED AC-003：集成测试要求游戏导出摘要含方向/硬门/缺口。
6. GREEN AC-003：Main 传期望 3×4 context，加入摘要；实现离线 CLI 与文档。
7. 运行三套目标测试、20 套严格回归、双阶段评审。

## 修改边界

- 只允许 PRD File Manifest。
- 禁止正式数值 JSON、CombatState、SaveManager schema、构建版本与美术资源变更。
- 禁止新依赖。

## 失败恢复

- 测试失败进入 `trellis-debug-systematic-zh`，一次只修一个稳定失败。
- verifier/review 两次失败即停止本批。
