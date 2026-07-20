# Batch 021：策略组件消融、胜任战斗与精英安全门

## 需求 ID

- REQ-003
- REQ-004
- REQ-005
- REQ-009

## 目标

在冻结生产数值、正式 256 matrix、真人 cohort 与 `CombatState.gd` 的前提下，把跑团策略拆成 meta/combat/elite-safety 三个可消融组件；为胜任战斗策略建立确定性 fixture；以只读三种子精英预测阻止高收益路线抵消不安全精英；最终用四 profile 的 64→128 paired gate 判断策略是否足以解锁下一次数值审计。

## 交付 Loop 控制

- 交付批次：`delivery-batch-021-strategy-component-ablation`
- Loop 模式：L3
- 需要 worktree：是
- 需要 verifier：是
- 实现技能：`trellis-implement-tdd-zh`
- 调试技能：`trellis-debug-systematic-zh`
- 评审技能：`trellis-review-twostage-zh`
- 人工门：若 64 或 128 gate 失败，必须写 `paused_no_strategy_component_passed` 并暂停；不得修改生产数值或扩大容差。
- 最大修复尝试次数：2
- 最大调试假设轮数：3
- 回滚触发：critical review、测试回归、File Manifest 外改动、current/v1 历史兼容破坏、正式矩阵或生产 JSON 被修改。

## 串行任务

1. `01-strategy-component-ablation-contract`：四 profile、组件映射、opt-in 诊断与路线理由遥测。
2. `02-competent-combat-and-elite-safety`：胜任出牌、目标选择与 v2 精英三种子硬门；依赖 021-01。
3. `03-paired-component-verification`：四 profile 3×4×64 方向门，v2 通过后才运行 128；依赖 021-02。

## 全批禁止事项

- 不修改任何生产卡牌、敌人、遭遇、角色、经济或数值树 JSON。
- 不修改 `scripts/combat/CombatState.gd`、`scripts/map/MapGenerator.gd`、`scripts/main/Main.gd` 或真人遥测 schema。
- 不改变默认 `current-greedy`，不删除/改名 `competent-player-v1`。
- 不把 64/128 诊断写入正式 256 rows，不降低目标、不扩大容差、不添加 expected exception。
- 不以单 seed、单角色或单挑战替代完整 paired gate。
