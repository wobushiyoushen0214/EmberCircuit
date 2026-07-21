# Design: 022-01 完整图精英安全

## 编排-计算分离

| 层 | 元素 | 落点 |
| --- | --- | --- |
| 编排 | v3 dispatch、候选集合过滤 | `BalanceSimulator.gd:_choose_next_campaign_node` |
| 计算 | 节点安全可达性、preview-state cache、cycle guard | `BalanceSimulator.gd` 相邻私有 helper |
| 既有安全 | 精英三 seed 预测 | `_campaign_elite_is_safe`，不复制 predictor |

## API 契约

- `_campaign_has_safe_boss_route(state, graph, node_id, cache, active)` 返回 bool；cache key 使用 node+preview state，active path 只使用 node id，从而让状态变化的回边也能终止；不修改 `state` 的业务字段。
- v3 通过 `_campaign_strategy_components()` 暴露 `predictive-v2`；v2 继续 `predictive-v1`。
- v3 的 predictor combat execution 使用 v2 的 competent policy，仅 safety component 名称与路线过滤不同。

## 路由流程

1. 当前候选进入 `_campaign_has_safe_boss_route`。
2. 当前节点是不安全 elite 时返回 false。
3. 当前节点是 boss 时返回 true。
4. 其他节点调用 `_campaign_preview_state_after_node`，对 successors 做 OR 搜索。
5. `_choose_next_campaign_node` 只有在 safe candidate 集合非空时过滤不安全分支；全 false 时走既有评分。

## 挂载点

| 挂载点 | 类型 | 位置 | 接线动作 |
| --- | --- | --- | --- |
| v3 profile | strategy config | `_campaign_strategy_config` | 添加明确白名单项 |
| component mapping | telemetry contract | `_campaign_strategy_components` | 返回 `predictive-v2` |
| full graph check | route safety | `_choose_next_campaign_node` | v3 且 graph 非空时建立 safe candidate ids |
| predictor reuse | safety | `_campaign_elite_is_safe` | 不改现有预测实现与 cache key |

## 结构健康度预检

`BalanceSimulator.gd` 约 3800 行，超过 400 行阈值；本任务不拆平行 simulator，不做行为重构，只在 route helper 相邻区域加入一个纯递归 helper并复用已有 preview/predictor。
