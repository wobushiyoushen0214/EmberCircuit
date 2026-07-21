# Batch 022：完整地图精英安全可达性审计

## Stage State Packet

```yaml
stage_state:
  state: S7_CREATE_TASKS
  loop_mode: L3
  audit_scope: delta
  current_round: 3
  max_rounds: 6
  open_gaps: 8
  tasks_created: 2
  tasks_completed: 0
  carry_over: 0
  critical_review_issues: 0
  next_legal_action: implement-022-01-full-graph-elite-safety
  stop_conditions:
    - none
```

## Delta Evidence

021 的四 profile 64 paired gate 已 fail-closed。`competent-player-v2` 的精英访问为 256，死亡为 159，死亡率 `159/256=0.62109`；C0/C1 第一章完成率比 current 分别下降 `22/192=0.11458` 与 `10/192=0.05208`。证据见 `docs/11_STRATEGY_COMPONENT_AUDIT_021.md`、`.trellis/tasks/delivery-batch-021-strategy-component-ablation/03-paired-component-verification/verification-report.md` 和 `/tmp/ember021-*-64.json`。

代码证据显示 `_choose_next_campaign_node()` 只对当前 candidates 中有非精英替代时拒绝不安全精英，`_campaign_route_preview_score()` 的深度固定为 3。`256-60=196` 次精英访问不是当前 optional offer，说明未来强制精英漏斗已经绕过当前层安全门。

## 需求差距矩阵（受影响项）

| REQ | 状态 | 现有实现/测试 | 本轮缺口 | 建议任务 |
| --- | --- | --- | --- | --- |
| REQ-003 | PARTIAL | `scripts/tools/BalanceSimulator.gd`、`tests/test_balance_simulator.gd`、`docs/11_STRATEGY_COMPONENT_AUDIT_021.md` | 组件消融已具备，但 v2 路线安全只覆盖 3 层，无法证明完整图到 Boss 的安全可达性 | 022-01、022-02 |
| REQ-004 | PARTIAL | `BalanceSimulator.gd` competent combat/meta dispatch、020/021 fixture | v2 组合会提前进入未来强制精英，战斗策略虽通过局部 fixture 仍被路线漏斗放大 | 022-01、022-02 |
| REQ-005 | PARTIAL | 精英 3-seed predictor、hard reject、route preview | 未来不安全精英分支未从父节点传播；真正无替代路径与可安全路径未区分 | 022-01、022-02 |
| REQ-009 | PARTIAL | component-v1 diagnostics、021 64 gate | 缺少 v3 历史兼容 profile 与完整图路线安全的可复现实证 | 022-01、022-02 |

其余 REQ 状态与 021 相同；本轮不扩大到 UI、资产、网格战术模式或商业发布。

## Batch 022 计划

| 顺序 | 任务 | 风险 | 验收结果 |
| --- | --- | --- | --- |
| 1 | `022-01-full-graph-elite-safety` | 高 | 新增 `competent-player-v3/predictive-v2`；完整图搜索到 Boss，存在安全路径时拒绝未来不安全漏斗，无安全路径时保留确定性 fallback；current/v1/v2 历史行为不变 |
| 2 | `022-02-paired-route-safety-verification` | 中 | current、competent-combat-v1、competent-player-v2、competent-player-v3 使用相同 3×4×64 paired options；v3 全部门通过才允许 128；正式 256 与生产数据冻结 |

### 批次限制

- 每轮最多 3 个任务，唯一高风险任务为 022-01。
- 必须使用隔离 worktree、verifier 和双阶段评审。
- 不修改生产卡牌、敌人、遭遇、角色、经济、数值树 JSON、`CombatState.gd`、`MapGenerator.gd`、`Main.gd`、正式 256 rows 或真人报告。
- 不修改 `competent-player-v2` 的既有 `predictive-v1` 语义；v3 是新 profile。
- 64 gate 失败时不创建 128 报告，不降低容差，不把失败写入正式矩阵。

## 自我评审

- 状态证据均来自 021 报告、代码行和可复现 JSON，未把策略缺口误记为数值通过。
- 任务边界按高风险业务行为与验证拆分，未把生产调值混入。
- v3 保持 v2 历史身份，避免静默改写已审计报告。
- 完整图搜索以 graph 的 Boss 终点为安全目标；无 Boss 或无可达安全路径时走旧确定性评分，不改变旧 fixture。

