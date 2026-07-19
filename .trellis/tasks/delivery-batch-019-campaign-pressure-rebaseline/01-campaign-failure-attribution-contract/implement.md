# Implementation Plan: 019-01

## 文件计划

| 步骤 | 文件 | 操作 | 精确位置 | 验证方式 |
| --- | --- | --- | --- | --- |
| 0 | `scripts/tools/BalanceSimulator.gd` | 只搬不改行为 | failure map 累加段提取为本文件私有 helper | 旧 balance simulator test |
| 1 | `tests/test_balance_simulator.gd` | 新增 RED 断言 | campaign test 主流程之后 | 看到字段缺失/边界失败 |
| 2 | `scripts/tools/BalanceSimulator.gd` | 修改 | `_run_campaign_once()` 与 `_campaign_result()` | AC-019-01 |
| 3 | `scripts/tools/BalanceSimulator.gd` | 修改 | `_aggregate_campaign_case()` | AC-019-02/03 |
| 4 | `scripts/tools/BalanceSimulator.gd` | 修改 | `_build_campaign_report_summary()` | AC-019-04 |
| 5 | `tests/test_balance_simulator.gd` | 修改 | 64/128 deterministic fixture | AC-019-05 |

## 结构健康度预检

| 目标 | 当前规模 | 阈值 | 结论 |
| --- | --- | --- | --- |
| `BalanceSimulator.gd` | 2489 行 | 400 行 | 必须先做同文件 failure-map 私有 helper 微重构；只搬不改行为 |
| `test_balance_simulator.gd` | 223 行 | 400 行 | 不需重构 |

## 修改边界

- 允许：`scripts/tools/BalanceSimulator.gd`、`tests/test_balance_simulator.gd`、本任务产物。
- 禁止：所有生产 JSON、`CombatState`、`SaveManager`、`Main.gd`、真人 cohort 文件和矩阵 observed 字段。

## 失败恢复

- schema 字段缺失：检查 `_campaign_result()` 和 aggregate 输入，不弱化断言。
- 64 runs 被判 eligible：检查 config 读取和 `runs` 分母，重跑边界 fixture。
- 旧字段变化：优先恢复兼容字段，再回到当前 AC；连续三轮仍失败升级强模型。
