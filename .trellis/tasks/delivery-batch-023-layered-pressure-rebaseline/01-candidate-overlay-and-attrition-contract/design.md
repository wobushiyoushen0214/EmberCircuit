# Design: 023-01 候选 Overlay 与累计磨损归因

## 编排-计算分离

| 层 | 元素 | 落点 |
| --- | --- | --- |
| 编排 | options、临时数据引用、report metadata、CLI exit | `BalanceSimulator.gd`、`run_balance_simulation.gd` |
| 计算 | JSON 校验、allowlist、value validator、深副本和 path apply | `BalanceCandidateOverlay.gd` |
| 聚合 | attrition 原始计数转排序 rows | `BalanceSimulator.gd` 相邻 campaign aggregation helper |

## API 契约

`BalanceCandidateOverlay.load_and_apply(path, datasets)` 返回 `{ok, metadata, datasets, errors}`。成功时 datasets 只含三份深副本；失败时 datasets 为空、errors 为稳定去重错误码。`metadata` 只含 `schema_version/candidate_id/sha256/applied_fields`。

## 数据契约

| 字段 | 类型 | 默认 | 规则 |
| --- | --- | --- | --- |
| schema_version | int | 无 | 必须为 1 |
| candidate_id | String | 无 | 非空，只允许 ASCII 字母数字、点、下划线、短横线 |
| changes | Array | 无 | 非空，dataset+path 唯一 |
| dataset | String | 无 | 三项白名单之一 |
| path | Array[String] | 无 | 必须等于七条允许路径之一 |
| value | Variant | 无 | 按 path 执行固定类型/范围校验 |

## 挂载点

| 挂载点 | 类型 | 接线动作 |
| --- | --- | --- |
| campaign options | API | 接受 `candidate_overlay_path/candidate_diagnostics` |
| simulator lifecycle | 编排 | run 前替换副本、return 前恢复原引用 |
| campaign node loop | telemetry | opt-in 捕获 layer 与 HP before/after |
| case aggregation | schema | 输出排序 attrition-v1 rows |
| CLI | 参数/退出码 | 映射两个参数，拒绝态退出 1 |

## 结构健康度

- `BalanceSimulator.gd` 4192 行：超过 400 行。禁止把 overlay 校验放入该文件；只允许生命周期适配与相邻 attrition 聚合，不搬动现有战斗/路线行为。
- `tests/test_balance_simulator.gd` 2121 行：不继续扩展；新增独立测试文件。
- 新 helper 和新 test 预计各低于 400 行，无目录阈值问题。

## 非目标

- 不实现 layer-band 运行时选择，不运行 P1-P5，不修改生产配置。
- 不为 single encounter 模式应用候选。
