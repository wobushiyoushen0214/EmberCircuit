# Design: 021-03 Paired Component Verification

## 需求覆盖

| 需求 | 当前 | 验证元素 | 预期 |
| --- | --- | --- | --- |
| REQ-003/004/005/009 | PARTIAL | 64 direction gate、conditional 128、hash/determinism、stop state | PARTIAL，形成下一轮可执行裁决 |

## 编排-计算分离

| 层 | 元素 | 落点 |
| --- | --- | --- |
| 编排层 | 四 profile 命令顺序、64→128 条件 | `verification-report.md` 记录的命令流程 |
| 计算层 | 按 challenge 聚合三角色均值、差分与 elite death rate | `tests/test_balance_simulator.gd` 小型纯数据 fixture |
| 冻结保护 | 正式 matrix/profile/hash 不变 | `tests/test_numerical_balance_matrix.gd` |

## 挂载点清单

| 挂载点 | 类型 | 位置 | 动作 |
| --- | --- | --- | --- |
| 64 reports | artifact | `/tmp/ember021-*-64.json` | 四 profile 同 options |
| Gate | verification | test/report | 逐 C0-C3 与 elite 门判定 |
| Conditional 128 | workflow | verification report | 仅 64 PASS 后执行 |
| Determinism | artifact | 重复 report/hash | byte-identical |
| Stop state | docs/state | report、docs、delivery-state | 写唯一裁决 |

## 非目标

- 不实现或调优策略，不更新正式数值矩阵。
