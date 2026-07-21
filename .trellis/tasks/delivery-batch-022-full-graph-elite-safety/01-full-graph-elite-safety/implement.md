# Implementation Plan: 022-01

## 文件计划

| 步骤 | 文件 | 操作 | 验证 |
| --- | --- | --- | --- |
| 1 | `tests/test_balance_simulator.gd` | 增加 v3 profile 与五层 unsafe funnel RED fixture | 目标测试退出码 1，失败指向旧选择结果 |
| 2 | `scripts/tools/BalanceSimulator.gd` | 添加 v3 白名单/组件并复用 competent meta/combat | v3 mapping fixture GREEN |
| 3 | `scripts/tools/BalanceSimulator.gd` | 添加完整 graph safe-to-boss recursion 与 cycle/cache guard | 深层 funnel、safe branch、forced fallback GREEN |
| 4 | `tests/test_balance_simulator.gd` | 补 v2/current/v1 compatibility and duplicate selection tests | 四项自检 GREEN |
| 5 | `docs/12_STRATEGY_ROUTE_SAFETY_AUDIT_022.md` | 写实现和验证证据 | 文档与 diff 一致 |

## 修改边界

- 允许修改：`scripts/tools/BalanceSimulator.gd`、`tests/test_balance_simulator.gd`、本任务产物、`docs/12_STRATEGY_ROUTE_SAFETY_AUDIT_022.md`。
- 禁止修改：所有生产 JSON、`CombatState.gd`、`MapGenerator.gd`、`Main.gd`、正式 matrix、真人报告。
- 不新增依赖，不新增公共 API，不改变 v2 predictor。

## 失败恢复

- 若旧 fixture 改变，先检查 v3 条件是否错误地作用到 current/v1/v2；恢复 dispatch 分支后重跑。
- 若递归超时，检查 active key 是否在进入 successor 前写入并在返回前删除；不得降低搜索范围回到固定深度。
- 若没有安全 candidate，确认 fallback 使用原 `_campaign_route_preview_score` / `_campaign_node_score`，不得返回空节点。

