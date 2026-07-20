# Design: 021-01 策略组件消融契约

## 需求覆盖

| 需求 | 当前 | 设计元素 | 预期 |
| --- | --- | --- | --- |
| REQ-003/009 | PARTIAL | 四 profile 映射、opt-in diagnostics、路线与精英计数 | PARTIAL，具备组件归因能力 |

## 契约

- 输入：`strategy_profile` 与可选 `strategy_diagnostics=component-v1`。
- 输出：诊断关闭时保持 020 schema；开启时在 report/case/sample 增加同名组件及计数字段。
- 错误：未知 profile fallback current 并保留 fallback marker；未知 diagnostics 关闭诊断。

## 编排-计算分离

| 层 | 元素 | 落点 |
| --- | --- | --- |
| 编排层 | options→state→node/result→aggregate 的诊断传递 | `scripts/tools/BalanceSimulator.gd` 既有 campaign 流程 |
| 计算层 | profile→components 映射、字典计数合并、reason code 选择 | 同文件私有 helper |
| CLI | diagnostics 参数透传 | `tools/run_balance_simulation.gd` |

## 挂载点清单

| 挂载点 | 类型 | 位置 | 动作 |
| --- | --- | --- | --- |
| Profile contract | API | `run_campaign_suite` | 归一化四 profile并写 components |
| Diagnostic state | state | `_run_campaign_once` | 只在 component-v1 初始化计数 |
| Route telemetry | strategy branch | `_choose_next_campaign_node` | offer/accept/reason 稳定计数 |
| Result schema | output | `_campaign_result`、aggregate/sample | 按开关输出字段 |
| CLI | option | `parse_options_for_args` | 透传 diagnostics |

## 非目标

- 不改变任何出牌、奖励、路线分值或精英准入行为。
