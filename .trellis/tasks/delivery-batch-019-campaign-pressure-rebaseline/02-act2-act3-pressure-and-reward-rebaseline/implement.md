# Implementation Plan: 019-02

## 结构健康度预检

| 目标 | 当前规模 | 阈值 | 微重构 |
| --- | --- | --- | --- |
| `economy.json` | 88 行 | 400 | 否 |
| `enemies.json` | 482 行 | 400 | 否；结构化数据表，不拆 schema |
| `numerical_tree.json` | 319 行 | 400 | 否 |
| `test_numerical_balance_matrix.gd` | 324 行 | 400 | 否 |

## 有序步骤

0. 校验 019-01 的 128 report schema/eligibility；失败立即停止。
1. 新建 RED test，冻结起点和 candidate-to-values mapping。
2. 按 R1、R2、R2-A、R2-B 顺序一次只应用一级；每级运行 128 report 并记录 SHA-256。
3. 每次敌人 HP 变化后先跑 data integrity、numerical auditor 和 21 single pressure，再跑 campaign。
4. 选择第一个通过全部方向门的 step；更新 docs/snapshot/进度，确认 256 rows 未改。

## 修改边界

- 允许：PRD File Manifest 和本任务产物。
- 禁止：所有其他代码/配置，尤其 `BalanceSimulator.gd`、`Main.gd`、`CombatState.gd`、`SaveManager.gd`。

## 失败恢复

- static budget 失败：恢复该 step 的敌人变更，不改 budget 边界。
- campaign 不通过：按固定下一 step 推进，不并行改多档。
- 所有 step 不通过：记录四份报告并暂停，不新增候选。
