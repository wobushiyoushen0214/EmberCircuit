# Design: 019-03 完整跑团矩阵与交付验证

## 需求覆盖

| 需求 | 当前 | 设计元素 | 预期 |
| --- | --- | --- | --- |
| REQ-003/004/005/009/012 | PARTIAL | 128/256 工具报告、矩阵同步、回归和 cohort 隔离 | 交付证据完整且可审计 |

## MVP 兼容性契约

保留现有 256 matrix schema v2、单战 pressure schema v2、真人 cohort schema、28+ Godot suites、UI/performance smoke；只更新真实 observed 和文档证据。

## 上下文清单

| 类型 | 路径 | 用途 |
| --- | --- | --- |
| 方向报告 | `/tmp/ember019-selected-128.json` | 验证 selected step 进入正式矩阵前已通过 |
| 正式报告 | `/tmp/ember019-campaign-matrix-256.json` | 唯一 observed 来源 |
| 矩阵契约 | `tests/test_numerical_balance_matrix.gd` | target/axis/risk/经济断言 |
| 真人门 | `tests/test_playtest_evidence_gate.gd` | cohort 与分母隔离 |
| 交付状态 | `.trellis/delivery-state.md` | batch/REQ 状态与 next action |

## 编排-计算分离

| 层 | 元素 | 落点 |
| --- | --- | --- |
| 编排层 | 命令顺序、报告来源校验、结构化矩阵同步、文档/状态回写 | `tools/sync_campaign_matrix.gd`、`tests/test_campaign_matrix_verification.gd`、交付文档 |
| 计算层 | 已有 `BalanceSimulator` 与 `NumericalTreeAuditor` 输出 | 只消费，不复制聚合逻辑 |

## 挂载点清单

| 挂载点 | 类型 | 位置 | 接线动作 |
| --- | --- | --- | --- |
| 128 direction report | 工具输出 | `/tmp/ember019-direction-128.json` | schema/selected step 校验 |
| 256 matrix report | 工具输出 | `/tmp/ember019-campaign-matrix-256.json` | observed rows 同步/核对 |
| Matrix sync | 工具入口 | `tools/sync_campaign_matrix.gd` | 校验 256 report 完整性并原子生成 tree |
| Matrix contract | 测试 | `tests/test_campaign_matrix_verification.gd` | 直接读取 report 与 tree 对比 |
| Delivery state | 状态 | `.trellis/delivery-state.md` | 记录 batch completed 与 REQ evidence |

## 非目标

- 不重新设计 simulator，不改数值，不用真人不足样本推断难度。
