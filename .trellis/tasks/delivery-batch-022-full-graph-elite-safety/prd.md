# Batch 022：完整地图精英安全可达性

## 需求 ID

- REQ-003
- REQ-004
- REQ-005
- REQ-009

## 目标

修复 021 暴露的未来强制精英漏斗：新增历史兼容的 `competent-player-v3`，在 `BalanceSimulator.gd` 中对 v3 进行完整 graph 到 Boss 的安全可达性检查。只要当前候选中存在一条能到 Boss 且所有精英均通过现有 3-seed predictor 的路线，就拒绝把策略带入所有后续路径都依赖不安全精英的候选；若不存在安全路径，保留旧的确定性选择以避免无解图死循环。

## 交付 Loop 控制

- 交付批次：`delivery-batch-022-full-graph-elite-safety`
- Loop：L3；worktree：是；verifier：是
- 实现：`trellis-implement-tdd-zh`
- 调试：`trellis-debug-systematic-zh`
- 评审：`trellis-review-twostage-zh`
- 人工门：Stage 2 需要强模型；64 gate 失败时暂停，不进入 128
- 最大修复尝试：2；最大调试假设轮数：3
- 回滚触发：current/v1/v2 报告变化、改动 File Manifest 外文件、生产 JSON/正式矩阵变化、递归搜索不确定或测试回归

## 当前缺口

- 状态：PARTIAL。
- 代码：`scripts/tools/BalanceSimulator.gd:2317-2412` 只检查当前 optional elite，前瞻深度固定 3。
- 测试：`tests/test_balance_simulator.gd:1491-1501` 只覆盖两层 future unsafe fixture，没有覆盖深度超过 3 的漏斗、分支安全可达和无安全路径 fallback。
- 风险：v2 的 `elite_visits=256`、`elite_deaths=159` 表明父节点选择已把后续决策锁入不安全精英；继续改生产数值会混淆路线策略与战斗策略。

## 复杂度与规划产物

- 复杂度：高，执行模型按 fixture 机械实现，不得自行改 gate 或数值。
- 必要产物：`prd.md`、`design.md`、`implement.md`、`implement.jsonl`、`check.jsonl`、`tdd-progress.md`、`review-report.md`。
- Spec：`.trellis/spec/` 不存在；稳定依据为 `docs/11_STRATEGY_COMPONENT_AUDIT_021.md`、`tests/test_balance_simulator.gd` 与 `scripts/tools/BalanceSimulator.gd`。

## 决策表

| 决策点 | 固定方案 | 禁止方案 |
| --- | --- | --- |
| 新 profile | `competent-player-v3` | 静默改写 v2 或复用旧报告身份 |
| v3 组件 | `meta=competent`、`combat=competent`、`elite_safety=predictive-v2` | 新增自由组件名或改生产 profile |
| 安全终点 | graph 中 `type=boss` 的节点 | 把任意无 successor 节点当成功 |
| 路线判断 | 从候选节点递归搜索完整 successors；精英调用现有 `_campaign_elite_is_safe` | 只增加 lookahead depth、静态成熟度或单 seed |
| 候选过滤 | 至少一个 safe-to-boss candidate 时过滤其余候选；全部不安全时保留旧评分 | 大负分相加抵消、无替代时返回空节点 |
| 环检测 | 用 `node_id + preview state key` active set 终止当前分支并判 false | 无界递归 |
| predictor policy | v3 predictor 使用与 v2 相同的 competent combat/potion policy，cache key 仍含请求 profile | 消耗真实 state/potion 或复制另一套结算器 |

## MVP 兼容性契约

| 行为 | 必须保留 | 回归 |
| --- | --- | --- |
| 未知 profile fallback current | 是 | `tests/test_balance_simulator.gd` profile tests |
| current/v1 旧 scorer 与 route tie 行为 | 是 | `tests/test_balance_simulator.gd` existing fixture |
| v2 使用 predictive-v1 | 是 | v2 component mapping and v2 cached elite fixtures |
| 无 graph/无 Boss fixture | 是 | existing `lookahead_graph` tests |
| 生产 JSON、正式 matrix | 是 | `tests/test_numerical_balance_matrix.gd` |

## 文件清单

| 操作 | 文件 | 说明 |
| --- | --- | --- |
| 修改 | `scripts/tools/BalanceSimulator.gd` | 注册 v3；新增 full-graph safe-to-boss helper；仅 v3 启用全图过滤；v2/current/v1 分支不变 |
| 修改 | `tests/test_balance_simulator.gd` | 先写 v3 映射与深层漏斗 RED，再写 safe branch、forced fallback、cycle/legacy 回归 |
| 修改 | `docs/12_STRATEGY_ROUTE_SAFETY_AUDIT_022.md` | 回写实现证据与性能结果 |
| 新建 | `.trellis/tasks/delivery-batch-022-full-graph-elite-safety/01-full-graph-elite-safety/*` | TDD、设计、上下文、评审产物 |

## 实现步骤

1. 在测试中增加 `competent-player-v3` CLI/API 映射断言，并建立五层以上的 unsafe elite funnel fixture；当前代码必须看到 RED。
2. 在 `BalanceSimulator.gd` 中新增常量、profile normalization、component mapping，并让 v3 复用 competent meta/combat 与现有 predictor。
3. 增加纯递归 `_campaign_has_safe_boss_route(state, graph, node_id, cache, active)`：先检查当前 elite，boss 返回 true，非 boss 只沿 successor 继续；`_campaign_preview_state_after_node` 作为下一节点状态，cache key 包含 node 和完整 preview state。
4. 在 `_choose_next_campaign_node` 中仅对 v3 且 graph 非空计算 safe candidate 集合；集合非空时跳过不在集合中的候选，集合为空时保持现有评分和 forced elite 行为。
5. 逐条运行 route fixture、四项项目回归、editor import，最后做最小实现收敛和 diff/freeze 核对。

## 行为约束

- v3 的深层 unsafe elite funnel 在存在安全 Boss 路线时必须返回安全候选。
- v3 的 safe elite branch 必须仍可被选择。
- v3 的 graph 若所有到 Boss 的路线均不安全，必须返回旧评分选择，不返回空字符串。
- current/v1/v2 不调用 full-graph helper；v2 仍只使用 predictive-v1 的当前/三层行为。
- 递归只读 graph 与 preview state；不得修改真实 campaign state，预测 cache 只能写入 campaign-local copy。

## 验收标准

- AC-022-01：CLI/API 接受 v3，未知值仍 fallback current；v3 组件映射准确。
- AC-022-02：五层以上 future unsafe elite funnel 在有 safe-to-boss sibling 时被 v3 拒绝；原三层 fixture 与 current/v1/v2 回归保持通过。
- AC-022-03：存在 safe elite 的路线可达性为 true，v3 不因“包含 elite”而全部拒绝。
- AC-022-04：所有路径都无安全 Boss 路线时，v3 保留确定性旧评分选择且不产生空节点。
- AC-022-05：递归 cache 可区分相同节点的不同 preview state，并对循环图终止；重复相同输入选择确定。
- AC-022-06：editor import、`test_balance_simulator.gd`、`test_combat_core.gd`、`test_numerical_balance_matrix.gd` 全绿；生产 JSON 与正式 256 hash 不变。

## 自检命令

```bash
HOME=/tmp/ember022_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
HOME=/tmp/ember022_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_simulator.gd
HOME=/tmp/ember022_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_combat_core.gd
HOME=/tmp/ember022_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_balance_matrix.gd
git diff --check
```

