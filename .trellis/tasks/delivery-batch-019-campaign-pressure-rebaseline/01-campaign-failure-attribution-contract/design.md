# Design: 019-01 跑团失败归因契约

## 需求覆盖

| 需求 | 当前 | 设计元素 | 预期 |
| --- | --- | --- | --- |
| REQ-003/004/005/009 | PARTIAL | campaign case 章节、遭遇、角色、挑战、跨章快照与 hard-gate | 为 019-02 提供可复现证据 |

## MVP 兼容性契约

保留 `run_campaign_suite()` 的 paired seed、`current-greedy`、旧聚合字段、单战 pressure schema v2 和真人/AI 隔离；回归命令见 `prd.md`。

## 上下文清单

| 类型 | 路径 | 为什么重要 |
| --- | --- | --- |
| MVP 代码 | `scripts/tools/BalanceSimulator.gd` | 唯一 campaign 编排与聚合入口 |
| 现有测试 | `tests/test_balance_simulator.gd` | campaign fixture、旧字段与 seed 风格 |
| 矩阵契约 | `data/config/numerical_tree.json` | hard-gate、失败集中度和目标常量 |
| 领域说明 | `docs/09_NUMERICAL_TREE_AND_BALANCE.md` | 64/128/256 样本和调参顺序 |

## 编排-计算分离

| 层 | 元素 | 落点 |
| --- | --- | --- |
| 编排层 | chapter entry/exit 与 transition snapshot 的生命周期 | `BalanceSimulator.gd` 的 `_run_campaign_once()` |
| 计算层 | 章节均值、完成率、失败集中度、角色/挑战汇总 | `BalanceSimulator.gd` 的 aggregation methods |

先在同一文件中提取只搬不改行为的 failure-map increment helper，再扩展计算层；不创建平行 simulator。

## 决策表

| 决策点 | 选定方案 | 排除方案 | 原因 |
| --- | --- | --- | --- |
| 样本门 | 从 `campaign_targets.minimum_iterations_for_hard_gate` 读取 | 写死 64 或绕过样本门 | 防止小样本调参 |
| 失败集中度 | 仅失败 run 的 encounter share | 用所有 run 作分母 | 与现有 `single_failure_encounter_share_max` 定义一致 |
| 资源均值 | 以章进入/离开 snapshot 的真实 run 数为分母 | 用最终资源倒推 | 防止失败章被误认为到达章 |
| 旧 risk flag | 保留原函数输出，新增独立 attribution flags | 重排 risk flag 优先级 | 兼容旧矩阵消费者 |

## 挂载点清单

| 挂载点 | 类型 | 位置 | 接线动作 |
| --- | --- | --- | --- |
| Campaign report schema | 工具输出 | `run_campaign_suite()` | 写入 schema/summary/cases |
| Chapter snapshot lifecycle | 状态字段 | `_run_campaign_once()` | 进入章、Boss 完成和跨章恢复时记录 |
| Attribution aggregation | 计算函数 | `_aggregate_campaign_case()`/`_build_campaign_report_summary()` | 将 snapshots 与旧 failure maps 聚合 |
| Regression contract | 测试入口 | `tests/test_balance_simulator.gd` | 直接断言字段、边界和复现性 |

## 非目标

- 不改生产数值、敌人、奖励、路线、战斗算法和正式矩阵 observed 值。
- 不替代真人 cohort 证据门。
