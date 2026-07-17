# Batch 017 第一章与开局重标定 Delta Audit

日期：2026-07-17

## Stage State Packet

```yaml
stage_state:
  state: S7_CREATE_TASKS
  loop_mode: L3
  audit_scope: delta
  current_round: 2
  max_rounds: 6
  open_gaps: 8
  tasks_created: 1
  tasks_completed: 0
  carry_over: 3
  critical_review_issues: 0
  next_legal_action: implement delivery-batch-017-act1-opening-rebaseline with strict TDD
  stop_conditions: none
```

## Delta 证据

- Batch 016 已把 opening package、单战分位数、too-easy、行动密度与 Boss/elite EHP 变成机器契约。
- 当前 opening package 为 `91.38 / 82.47 / 88.41`，三角色都高于目标区间。
- 第一章 `3×7×256` 平均单战胜率 `99.6%`，21/21 case 产生过易风险。
- 第一章 Boss 胜率为 `97.27% / 96.09% / 99.61%`，Boss/最高精英 C0 EHP 比为 `96/104=0.9231`。
- single simulator 没有注入真实默认 `steel_manual`，而 opening 审计与 campaign 已计入其开场 3 护甲，必须先统一证据口径。
- 用户已确认继续执行正式重标定，并要求后续完整 UI 重构；Batch 017 保持数值单一高风险边界，完整页面视觉重构进入 Batch 018。

## 受影响需求

| REQ | 状态 | 本批缺口 | 本批后目标 |
| --- | --- | --- | --- |
| REQ-003 | PARTIAL | 开局资源过强，第一章压力不成立 | 第一章与起始包候选进入 pressure contract |
| REQ-004 | PARTIAL | 三角色 opening package 与行动密度不可比 | 三角色落入各自 opening 区间，保留玩法差异 |
| REQ-005 | PARTIAL | 攻击空窗、Boss 层级与复合意图不足 | 7 遭遇静态压力达标，Boss/elite EHP ≥1.15 |
| REQ-009 | PARTIAL | single/campaign 默认技能书口径不一致 | 同 seed、同默认 modifier、64/256 paired evidence |
| REQ-012 | DONE | 21 套回归尚未覆盖正式重标定 | 新增第 22 套重标定契约并严格扫描 |

## 冻结候选

- Ember：`ember_strike 6/8`、`ember_bottle 3 block`、`cracked_charm` 改为首次实际损血后每战抽 1；金币 55；deck/opening `73.86/79.14`。
- Arc：`spark_throw 3/5`、`static_primer 1/1 cost`、`insulated_battery 2 block`；金币 52；deck/opening `67.03/76.83`。
- Pyre：2×`penitent_cut`+2×`ember_strike`，`penitent_cut 6/8`、`scar_guard 6/9`、`ash_rosary 3 block`；金币 50；deck/opening `72.69/77.97`。
- 篝火：40%→25%，69/70 最大生命均按现有 ceil 规则恢复 18。
- 第一章：采用 Batch 017 PRD 的逐敌 HP/行动表；Boss 116 HP，C0 EHP 112，最高精英 96，比例 1.1667。
- 意图：新增 `attack_block`、`attack_buff`、`attack_status_card`，伤害与次要效果必须同时显示。

## 批次结论

`delivery-batch-017-act1-opening-rebaseline` 是本轮唯一高风险任务。用户已确认执行，允许创建任务、提交规划、建立隔离 worktree，并自动推进到双阶段评审门。
