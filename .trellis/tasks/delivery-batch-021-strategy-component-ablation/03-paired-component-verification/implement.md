# Implementation Plan: 021-03

## 文件计划

| 步骤 | 文件 | 操作 | 验证 |
| --- | --- | --- | --- |
| 1 | `tests/test_balance_simulator.gd` | gate 纯数据 fixture 先 RED | AC-15/16 |
| 2 | `tests/test_numerical_balance_matrix.gd` | 正式 256 冻结断言 | AC-17 |
| 3 | `/tmp/ember021-*-64.json` | 四 profile 64 报告 | 方向门 |
| 4 | `verification-report.md` | 写 64 逐门结果 | 决定是否允许 128 |
| 5 | `/tmp/ember021-*-128*.json` | 条件执行并重复 | byte-identical/hash |
| 6 | docs/state/report | 回写裁决 | AC-20 |

## 结构健康度预检

| 文件 | 规模 | 阈值 | 结论 |
| --- | ---: | ---: | --- |
| `test_balance_simulator.gd` | 预计 >400 | 400 | 只加 gate helper/fixture，不修改业务实现 |
| `test_numerical_balance_matrix.gd` | 389 行 | 400 | 仅加冻结断言，不重构既有矩阵测试 |

## 失败恢复

- 命令失败：系统化定位实现/参数 bug；不得修改 gate。
- 64 gate FAIL：停止 128，写暂停状态。
- 重复报告不同：定位随机源或字典顺序，修复后重跑该 profile，不改容差。
