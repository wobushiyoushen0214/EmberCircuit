# 021-01：策略组件消融契约与遥测

## 需求 ID

- REQ-003
- REQ-009
- AC-021-01 ～ AC-021-06

## 当前缺口

- 状态：PARTIAL。
- 证据：`BalanceSimulator.gd` 只识别 `current-greedy` 与 `competent-player-v1`；020 schema 没有 meta/combat/elite-safety 组件映射、节点访问、精英 offer/accept 或路线 reason code。
- 风险：无法区分“路线更激进”“战斗更聪明”“精英硬门”各自贡献，继续调数值会混淆归因。

## 交付 Loop 控制

- 批次：`delivery-batch-021-strategy-component-ablation`
- Loop：L3；worktree：是；verifier：是。
- 技能：`trellis-implement-tdd-zh` → `trellis-debug-systematic-zh` → `trellis-review-twostage-zh`。
- 最大修复 2 次；最大调试假设 3 轮。
- 回滚：current/v1 默认报告变化、诊断关闭仍增加字段、非清单文件改动或正式矩阵变化。

## 复杂度与上下文

- 复杂度：中。
- 产物：`prd.md`、`design.md`、`implement.md`、`implement.jsonl`、`check.jsonl`、`tdd-progress.md`。
- `.trellis/spec/` 不存在；以 `docs/11_STRATEGY_COMPONENT_AUDIT_021.md`、020 任务和既有测试为稳定契约。

## 决策表

| 决策 | 固定方案 | 禁止方案 |
| --- | --- | --- |
| profile | `current-greedy`、`competent-player-v1`、`competent-combat-v1`、`competent-player-v2` | 自由 profile 或改默认 |
| 组件映射 | current=`current/current/off`；v1=`competent/current/off`；combat=`current/competent/off`；v2=`competent/competent/predictive-v1` | 从 profile 名临时猜分支 |
| 诊断开关 | opt-in `strategy_diagnostics=component-v1`；未知值视为 off | 默认增加 schema 字段 |
| reason code | 固定枚举：`highest_score`、`stable_node_id_tiebreak`、`elite_safety_rejected`；计数字典键稳定排序 | 自由文本 |
| 计数 | 每局整数；case 汇总为总数，node/reason 字典逐键求和 | 从 sample 反推 |

## 文件清单

| 操作 | 文件 | 修改 |
| --- | --- | --- |
| 修改 | `tests/test_balance_simulator.gd` | 先写四 profile、组件映射、opt-in schema、默认兼容、节点/精英/reason 计数与确定性失败测试。 |
| 修改 | `scripts/tools/BalanceSimulator.gd` | 扩展 profile normalization；初始化组件与诊断 state；在路线选择、节点解析、精英结果处计数；聚合/样本按开关输出。 |
| 修改 | `tools/run_balance_simulation.gd` | 解析 `--strategy-diagnostics=`。 |
| 修改 | `docs/11_STRATEGY_COMPONENT_AUDIT_021.md` | 追加 021-01 契约、测试证据和兼容裁决。 |
| 新建 | 本目录的规划、进度与评审产物 | 保存 TDD/评审证据。 |

## MVP 兼容性契约

- 未传 `strategy_profile` 与显式 `current-greedy` 的完整 `cases` byte-equivalent。
- 未传诊断或传未知诊断时，current/v1 报告不出现 021 新字段。
- `competent-player-v1` 继续表示 competent meta + current combat，行为与 020 历史 fixture 一致。
- paired seed、019 attribution、020 decision telemetry 与正式 matrix 冻结测试保持全绿。

## 验收标准

- [ ] AC-021-01：四个 profile 均被接受，未知 profile 明确 fallback current；CLI 与 API 归一化一致。
- [ ] AC-021-02：开启 component-v1 时顶层、case、sample 输出确切 `strategy_components` 映射；关闭时不出现任何 021 新字段。
- [ ] AC-021-03：开启诊断时输出 `node_visit_counts`、`elite_visits/wins/deaths`、`optional_elite_offer_count`、`optional_elite_accept_count`、`route_choice_reason_counts`，均为非负确定值且 `elite_visits=elite_wins+elite_deaths`。
- [ ] AC-021-04：路线同分按 node id 选择并计 `stable_node_id_tiebreak`；非同分计 `highest_score`，不写自由文本。
- [ ] AC-021-05：默认/显式 current 完整 cases 相等；020 v1 既有 fixture 保持全绿，诊断关闭 schema 无漂移。
- [ ] AC-021-06：相同 profile、诊断、seed 和 options 重复运行完整 JSON 相等；相关四个测试命令全绿。

## 自检命令

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_simulator.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_card_telemetry.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_balance_matrix.gd
```

## 依赖与解锁

- 依赖：Batch 020 和 021 前置审计。
- 解锁：`02-competent-combat-and-elite-safety`。

## 范围外与禁止事项

- 不实现胜任战斗 scorer 或精英预测；只建立契约、映射和遥测挂点。
- 不改生产 JSON、CombatState、MapGenerator、Main、正式 256 rows 或真人报告。
- 不新增平行 simulator 或第三方依赖。
