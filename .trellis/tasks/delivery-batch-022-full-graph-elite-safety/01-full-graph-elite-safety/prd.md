# 022-01：完整地图精英安全可达性

## 需求 ID

- REQ-003
- REQ-004
- REQ-005
- REQ-009
- AC-022-01 ～ AC-022-06

## 当前缺口

- 状态：PARTIAL。
- 代码证据：`scripts/tools/BalanceSimulator.gd:2317-2412` 仅拒绝当前层 optional unsafe elite，路线前瞻深度固定为 3。
- 测试证据：`tests/test_balance_simulator.gd:1491-1501` 只覆盖两层 future unsafe fixture。
- 业务证据：021 v2 的 `elite_visits=256`、`elite_deaths=159`，其中 `256-60=196` 次访问不是当前 optional accept。
- 风险：路线先进入深层强制精英漏斗，后续安全门已无替代候选；直接调生产数值会混淆路线与战斗难度。

## 交付 Loop 控制

- 批次：`delivery-batch-022-full-graph-elite-safety`；Loop：L3。
- worktree/verifier：必须；Stage 2：独立强模型。
- 实现：`trellis-implement-tdd-zh`；调试：`trellis-debug-systematic-zh`；评审：`trellis-review-twostage-zh`。
- 最大修复 2 次；最大调试假设 3 轮。
- 回滚：current/v1/v2 兼容回归、File Manifest 外改动、递归不确定/超时、生产 JSON 或正式 matrix 变化。

## 决策表

| 决策 | 固定方案 | 禁止方案 |
| --- | --- | --- |
| profile | 新增 `competent-player-v3`，v2 保持历史 `predictive-v1` | 静默修改 v2 |
| v3 components | `competent/competent/predictive-v2` | 自由组件名 |
| 安全终点 | graph 中 `type=boss` | 任意 dead end |
| 搜索 | 从候选递归完整 successors；elite 复用现有 3-seed predictor | 增大固定 depth、静态成熟度、单 seed |
| 过滤 | safe candidate 集合非空才过滤；全 false 走旧评分 | 返回空节点或无解死循环 |
| 环保护 | cache 使用 `node_id + preview state key`；当前递归路径 active set 只使用 node id，环分支返回 false | 无界递归或让状态变化绕过回边检测 |
| combat policy | v3 predictor 复用 v2 competent combat/potion policy | 新结算器或真实 state 副作用 |

## 文件清单

| 操作 | 文件 | 修改 |
| --- | --- | --- |
| 修改 | `tests/test_balance_simulator.gd` | 先写 v3 profile、五层 funnel、safe elite、all-unsafe fallback、cycle/cache 和 compatibility RED fixture |
| 修改 | `scripts/tools/BalanceSimulator.gd` | v3 normalization/components/meta/combat dispatch；full graph safe-to-Boss helper；仅 v3 候选过滤 |
| 修改 | `docs/12_STRATEGY_ROUTE_SAFETY_AUDIT_022.md` | 回写 TDD、回归与性能证据 |
| 新建/修改 | 本任务目录下的 `tdd-progress.md`、`review-report.md` 与规划产物 | 记录证据 |

## 编排与挂载点

- `_campaign_strategy_config`：显式接受 v3。
- `_campaign_strategy_components`：v3 映射为 `predictive-v2`。
- `_strategy_uses_competent_meta/_strategy_uses_competent_combat`：v3 复用 competent 分支。
- `_choose_next_campaign_node`：仅 v3 且 graph 非空时计算 safe candidate ids。
- `_campaign_has_safe_boss_route`：复用 `_campaign_elite_is_safe`、`_campaign_preview_state_after_node`、`_successor_nodes`。

## MVP 兼容性契约

- 未知 profile 仍显式 fallback `current-greedy`。
- current/v1 的旧 scorer、route tie 和 diagnostics-off 行为不变。
- v2 保持 `predictive-v1`、现有 cached unsafe/safe/forced elite fixture 不变。
- graph 无 Boss 或 safe candidate 集合为空时，旧 `lookahead_graph` 与 forced elite fixture 不变。
- 所有生产 JSON、`CombatState.gd`、`MapGenerator.gd`、`Main.gd`、正式 256 rows 和真人报告冻结。

## 验收标准

- AC-022-01：CLI/API 接受 v3，未知值仍 fallback current；v3 component mapping 准确。
- AC-022-02：五层以上 future unsafe elite funnel 在有 safe-to-Boss sibling 时被 v3 拒绝；current/v1/v2 仍走旧行为。
- AC-022-03：预测安全的 elite 路线可达性为 true，v3 不会回避所有 elite。
- AC-022-04：所有到 Boss 路线都不安全时，v3 仍返回确定性的旧评分选择，不返回空字符串。
- AC-022-05：相同 node 的不同 preview state 使用不同 cache key；循环 graph 稳定终止；重复选择相等。
- AC-022-06：editor import、BalanceSimulator、CombatState、numerical matrix 自检全绿；生产数值树 SHA-256 仍为 `1f0cc2cbf45739c8b82abb92380c91138673a716d0031be0b57c5c0eacd5845e`。

## 自检命令

```bash
HOME=/tmp/ember022_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
HOME=/tmp/ember022_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_simulator.gd
HOME=/tmp/ember022_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_combat_core.gd
HOME=/tmp/ember022_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_balance_matrix.gd
git diff --check
```

## 禁止事项

- 不修改生产卡牌、敌人、遭遇、角色、经济、数值树、地图或真人遥测。
- 不复制 CombatState 结算器，不新增依赖，不改变 021 的 gate 容差。
- 不在 022-01 运行 64/128 正式诊断；该步骤属于 022-02。
