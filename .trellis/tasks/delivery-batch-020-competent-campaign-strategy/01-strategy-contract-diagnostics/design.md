# Design: 020-01 策略契约与决策遥测

## 需求覆盖

| 需求 | 当前 | 设计 | 预期 |
| --- | --- | --- | --- |
| REQ-004/009 | PARTIAL | profile normalization、campaign strategy schema、decision telemetry | PARTIAL，具备可比较的 AI 证据 |

## 编排-计算分离

| 层 | 元素 | 落点 |
| --- | --- | --- |
| 编排层 | `run_campaign_suite` 将 profile 写入每局 state 并传入聚合 | `scripts/tools/BalanceSimulator.gd` campaign methods |
| 计算层 | 决策计数初始化、结果复制、case 平均值 | `BalanceSimulator.gd` result/aggregate helpers |

## 挂载点

| 挂载点 | 类型 | 位置 | 接线动作 |
| --- | --- | --- | --- |
| Strategy profile input | API option | `run_campaign_suite(options)` | 读取并归一化 profile |
| Per-run state | state | `_run_campaign_once` | 初始化并累计计数 |
| Report schema | output | `_campaign_result`/`_aggregate_campaign_case` | 输出 case/sample 字段 |
| Regression gate | test | `tests/test_balance_simulator.gd` | 断言默认兼容和确定性 |

## 非目标

- 不改变任何节点选择、出牌、奖励评分或药水阈值。
- 不添加生产数值候选。
