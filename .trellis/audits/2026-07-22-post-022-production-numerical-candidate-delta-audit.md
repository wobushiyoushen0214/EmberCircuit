# 2026-07-22 Post-022 生产数值候选 Delta Audit

## Stage State Packet

```yaml
stage_state:
  state: S6_CONFIRM
  loop_mode: L3
  audit_scope: delta
  current_round: 4
  max_rounds: 6
  open_gaps: 8
  tasks_created: 0
  tasks_completed: 0
  carry_over: 0
  critical_review_issues: 0
  next_legal_action: request-confirmation-for-delivery-batch-023-layered-pressure-rebaseline
  stop_conditions:
    - none
```

## Trellis 工作流上下文

| 项目 | 状态 | 处理 |
| --- | --- | --- |
| Trellis 元数据 | `.trellis/.version`、`.trellis/.developer`、`.trellis/config.yaml`、`.trellis/workflow.md` 均不存在 | 沿用 019-022 已交付任务的 `prd/design/implement/JSONL/check/TDD/review` 产物约定 |
| `.trellis/spec/` | 不存在 | 019-022 的任务产物和 `docs/09-12` 足以解释当前数值、策略与验证门；023 确认后必须生成同规格规划产物 |
| 实现规模 | `BalanceSimulator.gd=4192` 行、对应测试 `2121` 行 | 禁止继续把候选解析逻辑直接堆入模拟器；候选 overlay 使用独立纯数据 helper |

## 路由与基线

- 唯一路由：`mvp-to-delivery-delta-audit`。源需求未变，022 交付和状态证据自 `last_audited_commit=efb4e11` 后发生变化。
- Loop：L3，Round 4；本轮只审计并选择一个候选批次，创建任务前停在确认门。
- 审计 HEAD：`09f52ac`；022 业务基线：`efb4e11`。
- 022 的 `competent-player-v3` 已通过完整图到 Boss 的路线安全和 64→128 paired gate，可作为本轮候选评估器；这不代表生产数值已通过。
- 正式 `data/config/numerical_tree.json` 仍为 `current-greedy/256/12 rows`，SHA-256 `1f0cc2cbf45739c8b82abb92380c91138673a716d0031be0b57c5c0eacd5845e`。

## 新证据

### 022 v3 128 完整跑团

来源：`/tmp/ember022-competent-player-v3-128.json`，`3角色×4挑战×128`，paired seed，报告 SHA-256 `bb8bb6ab34e18216500f2f867d6ad3eb761122457bb265032ca3544416bbb738`。

| 指标 | 实际 | 目标/判断 |
| --- | ---: | --- |
| C0/C1/C2/C3 平均胜率 | `8.9% / 5.5% / 3.1% / 2.9%` | 均低于 `27-33% / 17-26% / 12-23% / 8-15%` |
| C0/C1 角色差 | `16.5% / 10.9%` | 超过 AI `9%` 门 |
| 总平均胜率/章节 | `5.1% / 0.436` | 12/12 case flagged |
| 角色平均胜率 | Arc `10.8%`、Ember `3.5%`、Pyre `1.0%` | 全局候选还必须避免扩大角色差 |
| C0 第一章完成 | Ember `53/128`、Arc `52/128`、Pyre `42/128` | 第一章仍是主要进入门 |

升级均值极低：C0 为 Ember `0.273`、Arc `0.445`、Pyre `0.055`，高挑战进一步接近 0。019 的 R1/R2 仅提高选牌、药水和金币供给，四档胜率仍只有 `5.0/3.4/0.5/0.8%` 与 `5.5/3.1/0.5/0.5%`，因此不能重复同一奖励数量方向。

### 第一章单战与累计磨损

本轮只读生成 `/tmp/ember023-act1-single-64.json`，覆盖 `3角色×7遭遇×64`，SHA-256 `65ccdab9b5be96e32150153ec307e2990fc58271e9dd0045c9309980c947d860`；21/21 无 pressure risk，平均胜率 `85.6%`。

| 遭遇 | 三角色平均胜率 | HP 损失 p50 均值 | HP 损失 p90 均值 |
| --- | ---: | ---: | ---: |
| `intro_patrol` | `100%` | `11.0` | `19.0` |
| `polluted_lab` | `100%` | `27.7` | `41.7` |
| `iron_checkpoint` | `99.5%` | `36.0` | `50.3` |
| `cinder_kennels` | `100%` | `18.7` | `22.7` |
| `executor_elite` | `89.6%` | `50.3` | `57.0` |
| `furnace_colossus_elite` | `75.5%` | `57.3` | `64.3` |
| `chapter_one_boss` | `34.4%` | `69.7` | `69.7` |

单场满血时普通战几乎必胜，但部分普通战会消耗半条生命。`MapGenerator._make_node()` 当前从整个 `encounter_by_type.combat` 池均匀抽取，`map_generation.json` 又把 `intro_patrol/polluted_lab/iron_checkpoint/cinder_kennels` 放在同一第一章池中，所以 `iron_checkpoint` 可以出现在强制开场层。问题是遭遇强度未按层级排布，而不是每个普通战单独越过 lethal 门。

## 需求追踪矩阵增量

| ID | 状态 | 022 后证据 | 精确缺口 | 023 建议 |
| --- | --- | --- | --- | --- |
| REQ-003 | PARTIAL | v3 128 可复现；正式目标与 256 matrix 冻结 | 12/12 case 仍低胜率；当前没有不修改生产 JSON 即可比较候选的机制 | 候选 overlay、固定阶梯、128/256 门 |
| REQ-004 | PARTIAL | 三角色起始包和基础数值已在 017 重标定 | Arc/Ember/Pyre 平均胜率 `10.8/3.5/1.0%`；不能通过恢复免费开局资源修复 | 起始包继续冻结；候选必须同时检查每挑战角色差 |
| REQ-005 | PARTIAL | 21/21 第一章单战无 risk；v3 路线安全通过 | 第一章普通遭遇池不分层，满血单战高胜但累计 HP 损失极大 | 增加兼容的 layer band schema，并用生产候选验证完整路线 |
| REQ-009 | PARTIAL | v3 64/128 paired、repeat byte-identical；真人 cohort 隔离 | 候选输入尚无 schema、allowlist、hash 和报告回放身份 | 每份候选报告嵌入 overlay id/schema/SHA/applied fields；真人数据继续隔离 |

其余 REQ 无本轮相关变化。REQ-006/008 的资产和 UI、REQ-010 网格模式、REQ-011 商业发布均不混入高风险数值批次。

## 选定 Batch 023

`delivery-batch-023-layered-pressure-rebaseline`，P0，高风险，三个串行任务，唯一高风险任务为 023-02。

| 顺序 | 任务 | 复杂度/风险 | 交付边界 |
| --- | --- | --- | --- |
| 1 | `023-01-candidate-overlay-and-attrition-contract` | 中/中 | 独立 `BalanceCandidateOverlay.gd`、CLI overlay、allowlist/hash、逐层/逐遭遇损耗归因；默认无 overlay 必须 byte-identical |
| 2 | `023-02-layered-pressure-and-growth-rebaseline` | 高/高 | 在 overlay 中按固定 P1-P5 阶梯运行 v3 64→128；只把第一个通过全部 128 门的候选写入生产配置 |
| 3 | `023-03-production-matrix-verification` | 中/中 | 仅在 023-02 有 selected candidate 时运行 v3 256、静态/地图/全量回归和双阶段评审；失败则回滚并禁止打包 |

### 固定候选阶梯

每一步从任务起点重新应用，不累乘未声明值；P1-P5 是有序累积阶梯，禁止临时发明 P6。

| Step | 精确变化 |
| --- | --- |
| P1 | 第一章普通遭遇分层：L0=`[intro_patrol]`；L1-L2=`[intro_patrol,polluted_lab,cinder_kennels]`；L3-L6=`[polluted_lab,iron_checkpoint,cinder_kennels]`；elite/boss 不变 |
| P2 | P1 + `max_pressure_nodes_between_campfires: 4→3` |
| P3 | P2 + 三章 `node_budget.campfire: [1,2]→[2,2]`，普通战、精英和 Boss 路径预算不变 |
| P4 | P3 + 篝火恢复 `25%→30%` |
| P5 | P4 + 战斗卡稀有度 `65/28/7→60/30/10`；接受阈值、牌组跳过阈值、药水和金币保持 019 起点 |

P1 需要向 `MapGenerator` 增加向后兼容的 layer-band 读取；未配置 band 的章节继续使用既有 `encounter_by_type`。overlay 只允许修改上述 map/level/economy 字段，明确禁止角色、起始牌组、卡牌效果、敌人 HP/行动、挑战倍率、目标区间和真人报告。

### 晋级与停止门

- 64 只做方向门：12 cases、v3、paired；每挑战胜局和第一章完成数不得低于 022 v3 64 基线。C0 第一章完成须从 `76/192` 提高到至少 `84/192`，C1 从 `60/192` 提高到至少 `66/192`；21/21 单战与完整路径预算保持无新 warning/risk。
- 首个通过 64 的 step 才运行 128；128 必须满足四档聚合目标、单格 3% 容差、角色差 `<=9%`、挑战单调、失败集中度 `<=50%`、经济/牌组范围和静态门。
- 只选择第一个通过全部 128 门的 step。任何 step 失败都保存独立报告和 SHA；P1-P5 全失败则恢复生产起点并记录 `paused_no_layered_candidate_passed`。
- 023-03 只接受 023-02 的 selected step；256 失败即回滚生产候选，不更新正式 rows、不打包真人试玩版。
- 正式 256 通过后才允许把 matrix evaluator 从 `current-greedy` 迁移为 `competent-player-v3`；历史 current 报告保留，AI 结果不得写入真人 cohort。

## 批次限制

- `max_gap_tasks=3`，`max_high_risk_tasks=1`，worktree/verifier/Stage 1/独立强模型 Stage 2 全部必需。
- 023-01 必须先把候选解析移出 4192 行的模拟器；禁止借机重构战斗结算或 UI。
- 023-02 不能更改 `CombatState.gd`、玩家初始数值、敌人 action/phase、challenge targets 或 `campaign_targets`。
- 023-03 不能手改 observed rows；必须由通过的 256 报告同步。
- 任一 critical、两次 verifier 失败、File Manifest 越界或候选阶梯耗尽即停机。

## Confirmation Gate

本轮未创建 023 task、未修改生产数值、未修改正式 matrix，也未打包。需要用户确认本审计和 `delivery-batch-023-layered-pressure-rebaseline` 后，才能创建 PRD/worktree；创建任务后才进入严格 TDD。
