# TDD 进度：021-01

| AC | 可观察结果 | 测试文件 | 状态 |
| --- | --- | --- | --- |
| AC-021-01 | 四 profile/CLI/API 归一化 | `tests/test_balance_simulator.gd` | done |
| AC-021-02 | component-v1 opt-in schema | 同上 | done |
| AC-021-03 | 节点/精英计数守恒 | 同上 | done |
| AC-021-04 | 稳定 reason code/tie-break | 同上 | done |
| AC-021-05 | current/v1 历史兼容 | 同上 | done |
| AC-021-06 | 完整 JSON 确定性与回归 | 同上 | done |

## 收尾核对

- [x] 所有 AC done；无 red/green 遗留。
- [x] 自检命令全绿；挂载点全部接线。
- [x] 最小实现收敛完成；无新依赖、无无用抽象。
- [x] 未提交实现；双阶段评审 `C0/M0/m0`，交回主编排会话提交。

## 最小实现收敛

- 删除项：修正并删除“任意早期 tie 污染最终 reason”的错误状态传播。
- 复用项：复用现有 `_increment_count`、campaign state/result/aggregate/sample 流程和 CLI parser。
- 保留项：opt-in schema 隔离、current/v1 回归、计数守恒、稳定 tie-break 与完整报告确定性；新增 v1 diagnostics-off 的 report/case/sample 八字段全量泄漏检查。
- `trellis-minimal:` 注释：无；未新增依赖或平行 simulator。

## Review Round 3 补测

- RED：对 `competent-player-v1` diagnostics-off 临时注入顶层 `strategy_components` 泄漏，新回归测试稳定失败；随后撤销故障注入。
- GREEN：真实实现无需生产代码修复，新测试验证 report、全部 case 与全部 sample 均不含八个 021 字段。
- 回归：editor、balance simulator、card telemetry、numerical matrix 全绿。

## Review Round 4 补测

- RED 1：向 diagnostics-off 顶层临时注入 `elite_visits`，默认 current、未知 diagnostics、v1 三类完整 schema 检查均失败；随后撤销注入。
- RED 2：临时破坏 run result 的 `elite_deaths` 采集，sample 路径对账与精英守恒测试失败；随后撤销注入。
- GREEN：默认 current、未知 diagnostics、v1 均对 report/case/sample 做八字段全量禁止；diagnostics-on 的 v1 稳定 fixture 验证七个计数字段存在、节点计数等于实际 path、精英胜负等于实际 elite path 结果、单局 case 与 sample 聚合相等。
- 兼容性：真实精英采集使用历史 `competent-player-v1` fixture，不依赖 021-02 将新增的 v2 精英安全门。
- 回归：editor、balance simulator、card telemetry、numerical matrix 全绿。

## Review Round 5 补测

- RED 1：临时禁用 optional elite accept 增量，成熟 v1 的 optional elite 1 offer / 1 accept 断言失败；随后撤销注入。
- RED 2：临时把 sample 的 optional elite offer 恒置零，非零 fixture 与单局 case/sample 对账同时失败；随后撤销注入。
- GREEN：拒绝 optional elite 明确为 1/0，接受 optional elite 明确为 1/1；历史 v1 单局报告的 optional offer 非零，case 与 sample 的 offer/accept 完全相等。
- 回归：editor、balance simulator、card telemetry、numerical matrix 全绿。
