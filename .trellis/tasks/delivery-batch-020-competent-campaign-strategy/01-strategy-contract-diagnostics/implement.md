# Implementation Plan: 020-01

## 文件计划

| 步骤 | 文件 | 操作 | 位置 | 验证 |
| --- | --- | --- | --- | --- |
| 1 | `tests/test_balance_simulator.gd` | modify | campaign fixture前后 | RED：profile/schema/telemetry 缺失 |
| 2 | `scripts/tools/BalanceSimulator.gd` | modify | strategy normalize/state 初始化 | AC-020-01/02 |
| 3 | `scripts/tools/BalanceSimulator.gd` | modify | node/reward/shop/campfire/potion 计数挂点 | AC-020-03/04 |
| 4 | `scripts/tools/BalanceSimulator.gd` | modify | result/sample/aggregate 输出 | AC-020-04 |
| 5 | `tests/test_balance_simulator.gd` | modify | explicit/default deterministic comparison | AC-020-05 |

## 结构健康度预检

| 文件 | 当前规模 | 阈值 | 微重构 |
| --- | ---: | ---: | --- |
| `scripts/tools/BalanceSimulator.gd` | 2776 行 | 400 行 | 不在本任务抽离；只增加既有 helper，后续独立重构任务处理 |
| `tests/test_balance_simulator.gd` | 278 行 | 400 行 | 否 |

## 失败恢复

- profile JSON 不相等：先检查默认归一化和 seed，不改测试期望。
- 计数缺失：检查唯一挂点是否同时覆盖成功与失败节点。
- 019 字段回归：恢复旧字段，再继续新增字段。
