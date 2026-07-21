# 双阶段评审报告：021-01

## Review Round 1

### 被评审对象

- 任务：`01-strategy-component-ablation-contract`
- diff：`463efed..工作区`
- Stage 2：独立 `gpt-5.6-sol` 只读 reviewer

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 说明 |
| --- | --- | --- | --- |
| AC 测试覆盖 | 不符 | critical | diagnostics 同分只覆盖 v1，未覆盖 current/combat/v2 |
| 文件清单 | 通过 | - | 仅修改 PRD 允许文件及任务证据 |
| 禁止事项 | 通过 | - | 未改生产 JSON/CombatState/正式矩阵 |
| 决策表 | 不符 | critical | current/combat diagnostics-on 未稳定 node-id tie-break |
| 挂载点 | 通过 | - | API/state/route/result/CLI 均接线 |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 说明 |
| --- | --- | --- | --- |
| 正确性 | 不符 | critical | diagnostics-on 的 current/combat tie reason 错误 |
| 组件语义 | 不符 | major | v2 meta 的路线/升级旧分支仍只识别 v1 |
| 遥测语义 | 不符 | major | 强制精英被误计为 optional offer/accept |
| 结构/复用 | 通过 | - | 复用既有 state/result/aggregate helper，无新依赖 |

### 裁决

- Critical：1；Major：2；Minor：0。
- 打回 TDD：分别新增失败测试并修复 C1/M1/M2，完成后重新评审。

## Review Round 2

### 修复证据

- C1：diagnostics-on 四 profile 全部稳定 node-id tie-break；新增 diagnostics-off current 保留首候选历史行为断言。
- M1：新增 `_strategy_uses_competent_meta`，统一 v2 的路线、奖励、篝火、升级与药水 meta 分派；五类回归均有 fixture。
- M2：只有存在非 elite 候选时才累计 optional elite offer/accept；强制精英 fixture 为 0/0。
- 回归：editor、balance simulator、card telemetry、numerical matrix 全绿。

### 最终裁决

- 第三轮独立只读复审：`C0/M1/m0`。
- Major：缺少 `competent-player-v1` diagnostics-off 的完整 report/case/sample schema 回归，无法阻止任一 021 字段泄漏。
- 裁决：打回 TDD，补齐完整八字段泄漏检查后重新复审。

## Review Round 3

### 修复证据

- 新增 `competent-player-v1` diagnostics-off 报告 fixture。
- 在 report、每个 case、每个 sample 上逐层禁止八个 021 字段：组件映射、节点访问、精英访问/胜/死、optional elite offer/accept、路线 reason。
- 通过临时故障注入看到明确 RED；撤销故障后真实实现 GREEN，未为测试改动生产逻辑。
- 回归：editor、balance simulator、card telemetry、numerical matrix 全绿。

### 最终裁决

- 第四轮独立只读复审：`C0/M2/m0`。
- Major 1：默认 current 与未知 diagnostics 未对八个 021 字段做 report/case/sample 全量禁止。
- Major 2：diagnostics-on 未锁定 sample 七个计数字段和真实节点/精英采集，删除字段或恒置零仍可能测试全绿。
- 裁决：打回 TDD，补齐关闭模式全覆盖和真实 path 对账后重新复审。

## Review Round 4

### 修复证据

- 默认 current、未知 diagnostics、v1 统一调用八字段全层级泄漏检查。
- diagnostics-on 使用历史 `competent-player-v1` 单局 fixture，逐项验证 case/sample 七个计数字段。
- `node_visit_counts` 总和必须等于实际 path 长度且非零；elite visits/wins/deaths 必须等于实际 elite path 结果；单局 case 必须等于 sample 聚合。
- 两项故障注入均看到明确 RED；撤销故障后真实实现 GREEN，生产逻辑未为测试改动。
- 回归：editor、balance simulator、card telemetry、numerical matrix 全绿。

### 最终裁决

- 第五轮独立只读复审：`C0/M1/m0`。
- Major：七个计数字段中，optional elite offer/accept 尚未逐字段锁定真实采集和单局 case/sample 传播。
- 裁决：打回 TDD，补齐 optional elite 的拒绝、接受和聚合传播断言后重新复审。

## Review Round 5

### 修复证据

- 直接路线 fixture：拒绝 optional elite 计 1/0；成熟 v1 接受 optional elite 计 1/1。
- 历史 v1 单局报告：sample optional offer 必须非零，case/sample 的 offer/accept 必须完全相等。
- 两项故障注入均看到明确 RED；撤销后真实实现 GREEN，未修改生产行为。
- 回归：editor、balance simulator、card telemetry、numerical matrix 全绿。

### 最终裁决

- 独立 `gpt-5.6-sol` 最终复审：`C0/M0/m0`。
- Stage 1：AC、File Manifest、禁止事项、决策表、挂载点全部通过。
- Stage 2：关闭模式八字段全层级隔离、node/path、elite path、七字段存在与聚合传播、optional elite 1/0 与 1/1 均通过。
- 裁决：全通过，交回主编排会话推进 021-01 完成并进入 021-02。
