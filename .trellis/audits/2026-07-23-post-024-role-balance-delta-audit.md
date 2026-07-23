# 2026-07-23 Post-024 角色策略可信度 Delta Audit

## Stage State Packet

~~~yaml
stage_state:
  state: S6_CONFIRM
  loop_mode: L3
  audit_scope: delta
  current_round: 6
  max_rounds: 6
  open_gaps: 8
  tasks_created: 0
  tasks_completed: 0
  carry_over: 0
  critical_review_issues: 0
  next_legal_action: request-confirmation-for-delivery-batch-025-role-strategy-credibility
  stop_conditions:
    - none
~~~

## Trellis 工作流上下文

| 项目 | 状态 | 本轮处理 |
| --- | --- | --- |
| Trellis 元数据 | .trellis/.version、.trellis/.developer、.trellis/config.yaml、.trellis/workflow.md 均不存在 | 延续现有 prd/design/implement/JSONL/check/TDD/review 产物约定 |
| .trellis/spec/ | 不存在 | docs/03_CONTENT_AND_BALANCE.md、docs/09_NUMERICAL_TREE_AND_BALANCE.md、Batch 022-024 任务产物和版本化 evidence 构成当前稳定上下文 |
| Spec 新鲜度 | 部分过期 | docs/03 与 docs/09 仍描述 Batch 017 正式矩阵；Batch 024 的暂停裁决由 docs/14 与 numerical_tree.campaign_rebaseline_024 补充，不能把旧矩阵当作当前策略可信证据 |
| 结构健康度 | BalanceSimulator.gd 4407 行；test_balance_simulator.gd 2121 行；024 runner 377 行 | Batch 025 新计算必须进入独立 helper，新验证进入独立 test/runner；现有巨型文件只允许薄接线 |

## 路由、基线与审计范围

- 唯一路由：mvp-to-delivery-delta-audit。
- Loop：L3，进入 Round 6/6。本轮只审计 REQ-003、REQ-004、REQ-005、REQ-009；不重审 UI、美术、网格模式或商业发布。
- 审计 HEAD：d64262e7b9cfc3039fdd33b479ecab1aa9f2ecab；MVP baseline：2e3e857。
- last audited commit：6e0f5f9；本轮相关 delta 是 Batch 024 的角色候选、gate、正式 compact evidence、裁决文档和暂停状态。
- 不重跑 Batch 024 ladder，不运行 023 ladder、024 Ember/Pyre 候选、组合 64、128、256 或打包。
- docs/03 第 6.5 节明确把启发式 AI 的价值限定为稳定暴露数值断点、路线断点和决策 bug；当决策 bug 已有代码证据时，不得反向用该 AI 的结果直接修改生产角色数值。

## Batch 024 已验证结论

Batch 024 正式执行 1,536 局，verdict SHA-256 为 f70b155537c31573ef53c7e6afcfb49bc998497626fc5343760663624a10a413。

| Step | Arc C0/C1/C2/C3 原始胜局 | 结论 |
| --- | --- | --- |
| A1 | 24/13/6/6 | C0 过高、C2 过低 |
| A2 | 22/16/7/6 | C0 至少高 1 胜、C2 至少低 1 胜；仍未通过完整四档门 |
| A3 | 25/23/9/8 | C0/C1 同时抬高，方向错误 |

唯一合法裁决为 paused_no_arc_candidate_passed。没有 selected step，因此 024-03 取消，生产角色数据、正式 256 matrix、真人 cohort 和当前试玩包均未修改。A2 虽最接近，也不能被选择或作为生产起点。

## B0 全角色证据重新解释

024-B0 compact evidence 的源报告 SHA-256 为 af199c189e4208dce26776f9e95e749950655279cedd90f071ff2f7f6463ba4d；本轮读取时 /tmp/ember024-B0-64.json 的实算 SHA 与 compact evidence 绑定值一致。以下诊断已固化在本审计中，不作为 128/256 晋级证据。

| 角色 | C0/C1/C2/C3 胜局 | C0 第一章完成 | C0 平均出牌 |
| --- | --- | ---: | ---: |
| Arc | 29/24/14/7 | 54/64 | 284.094 |
| Ember | 11/2/1/0 | 47/64 | 175.531 |
| Pyre | 4/4/1/0 | 33/64 | 130.781 |

Arc 的免费行动密度仍可能是真实生产强度问题，但 Pyre 的低值已经被策略语义偏差污染，不能与 Arc/Ember 直接做生产角色差裁决。

### C0 第一章早期磨损

| 角色 | intro_patrol 死亡/访问 | intro 平均损血 | cinder_kennels 死亡/访问 | kennels 平均损血 |
| --- | ---: | ---: | ---: | ---: |
| Arc | 0/115 | 9.278 | 0/54 | 13.519 |
| Ember | 1/113 | 15.000 | 0/54 | 17.796 |
| Pyre | 8/110 | 22.400 | 10/55 | 20.582 |

Pyre 在进入第一章 Boss 前已经出现 18 次早期死亡。其起始牌组只有 kindle_pain 的每战一次 1 点自伤；如此大的差异不能仅由该固定成本解释，必须先审计出牌顺序和角色机制评分。

### C0 Pyre 卡牌遥测方向信号

| 卡牌 | offers | acquisitions | plays | 打出覆盖局 | 打出局胜/负 |
| --- | ---: | ---: | ---: | ---: | ---: |
| brand_strike | 44 | 49 | 388 | 31 | 3/28 |
| white_cinder | 44 | 29 | 252 | 22 | 3/19 |
| brand_flurry | 30 | 20 | 133 | 16 | 0/16 |
| scarlet_pact | 47 | 13 | 67 | 11 | 0/11 |
| scourge_sweep | 41 | 8 | 50 | 7 | 0/7 |
| wound_offering | 36 | 7 | 13 | 5 | 0/5 |
| blood_kindling | 47 | 0 | 0 | 0 | 0/0 |

这些 lift/胜负对照不是因果结论，但与下述机械代码偏差方向一致：v3 会高优先级连续打出带 burn 的混合攻击，却不会在安全窗口主动清理 searing_wound。

## 机械根因审计

| 根因 | 代码证据 | 当前测试边界 | 为什么会污染角色结论 |
| --- | --- | --- | --- |
| 混合 burn 攻击被误判为纯启动器 | scripts/tools/BalanceSimulator.gd::_competent_status_starter_priority 在目标 burn 少于 3 且存在可支付 damage follow-up 时无条件返回 40000；未排除自身已含 damage 的卡 | tests/test_balance_simulator.gd 只覆盖 0 费纯 burn skill 应先于伤害牌，没有“混合 burn 攻击 vs 多张必要防御”fixture | penitent_cut、brand_strike、white_cinder、brand_flurry 都会获得远高于普通伤害/护甲几十点量级的 40000 优先级，能连续抢占防御能量 |
| 自伤只防立即死亡，不防把可生存敌方回合变成死亡 | _card_player_hp_cost_is_fatal 只检查卡牌自身结算后 HP 是否为 0；_competent_card_score 只拒绝“敌方行动后仍活但下回合 burn 死亡”的分支，没有比较 no-card baseline 与 post-card enemy-turn survival | 现有 Pyre fixture 只验证 2 HP 时直接自杀牌被拒绝，未覆盖“10 HP、8 点来伤、3 点自伤后被敌方击杀” | 高伤害自伤牌仍可在非立即致死时压过安全牌，系统性放大跨战损血 |
| searing_wound 永远缺少清理价值 | _score_card 对 damage_self:2 计 -2.8，0 费只加 0.25；_choose_card 在 best_score <= 0.15 时结束，没有任何 exhaust/污染清理价值 | 无安全清理、多创口、低血和来伤边界 fixture | 人类可付 2 HP 把状态牌永久移出本场战斗；v3 几乎从不这样做，长战中会保留额外抽牌污染 |
| 苦修香炉的非致死伤害未进入普通战斗/奖励评分 | _shadow_card_resolution 能执行 card_created relic；但普通 _score_card 只给 create searing_wound 负分，只有 immediate lethal path 会消费 shadow kill；_campaign_card_reward_score 也未读取 owned relic 的 card_created damage | 现有 fixture 只证明创口触发可造成 lethal，不验证非致死分值与奖励排序 | Pyre 的起始遗物核心闭环在大多数非致死回合被低估，创口引擎的收益与污染成本不对称 |
| 角色语义没有版本隔离 | v1/v2/v3 共享 _competent_card_score；修改该函数会重写旧 evidence 的实际含义 | tests 只验证已知 profile 组件轴，不存在 role-aware 版本 | 若直接修改 v3，024 和 022/023 的历史报告将失去可解释性 |

普通伤害每点约 2.35 分、有效护甲每点约 2.8 分，而错误的 burn starter 奖励是 40000 分，量级相差三阶以上。这不是微小权重争议，而是明确的决策类别错误。

## 二选一审计裁决

裁决：选择“v3 明显低估/误用角色机制，下一批先做策略可信度与角色机制探针”，不选择“v3 已正确处理机制，直接重构生产角色基线”。

- 已证明的范围：Pyre 的 combat ordering、self-damage survival、wound cleanup 与 starter relic 评分至少存在四个可机械复核的缺口。
- 尚未证明的范围：Ember 的低胜率可能同时包含真实生产强度与策略评分不足；Arc 的高胜率也可能包含真实零费密度优势。本轮不提前替它们下生产结论。
- 决策后果：024-B0 仍是重要诊断，但不能作为全角色生产调值门。Batch 025 只修复并验证版本化策略，不修改角色、卡牌、遗物、敌人、地图、挑战或经济数值。

## 需求追踪矩阵增量

| ID | 状态 | 当前证据 | 精确缺口 | 下一步 |
| --- | --- | --- | --- | --- |
| REQ-003 | PARTIAL | 024 overlay/gate/evidence/verdict 全部可复核；A1-A3 受控失败 | 数值候选不能在角色策略语义不可信时继续晋级；缺少 role-aware 版本与配对可信度门 | 025 建立 v4 策略语义，不做生产调值 |
| REQ-004 | PARTIAL | 三角色运行时、专属卡/遗物/事件与 024 角色 gate 已接线 | Pyre 机制被 v3 系统性误用；Ember/Arc 的真实强度差仍未与策略偏差分离 | 025 先验证角色机制，再重新审计 026 数值候选 |
| REQ-005 | PARTIAL | B0 路线/恢复 overlay 与地图结构测试通过 | B0 未被 128/256 选中；当前没有证据允许写入生产 route/level/economy | 025 冻结，不新增路线候选 |
| REQ-009 | PARTIAL | 024 compact evidence、source SHA 与 verdict 已版本化 | 缺少策略版本、角色语义 reason counters、v4 primary/repeat compact evidence 与可信度裁决 | 025 新增策略 evidence/gate，仍不触碰真人 cohort |

其余需求状态不变：DONE 4、PARTIAL 7、MISSING 1、UNTESTED 0、UNCLEAR 0，共 12 条；open gaps 仍为 8。

## MVP 完成度摘要

- 已完成：4/12。
- 部分完成：7/12。
- 未实现：1/12。
- 已实现但未测试：0/12。
- 不明确：0/12。
- 当前不能进入最终验收；REQ-003/004/009 的 P0 数值与证据闭环仍未关闭。

## 选定 Batch 025（待确认）

batch_id：delivery-batch-025-role-strategy-credibility  
round：6  
priority：P0  
risk：high  
mode：L3  
audit_scope：delta

| 顺序 | 任务 | 复杂度/风险 | 交付边界 |
| --- | --- | --- | --- |
| 1 | 025-01-v4-role-semantics-contract | 中/中 | 注册 competent-player-v4；新增独立 RoleStrategySemantics helper 和 focused tests；v3 组件/行为保持冻结 |
| 2 | 025-02-v4-simulator-integration | 高/高 | 只在 v4 接入 burn 分类、自伤生存 veto、安全创口清理、苦修香炉评分和 reason counters；完整 RED→GREEN→REFACTOR |
| 3 | 025-03-paired-role-strategy-credibility | 中/中 | 固定 B0 上运行 v4 3角色×4挑战×64 primary/repeat，写 compact evidence 与唯一可信度 verdict；无论结果如何都不运行 128/256、不调生产、不打包 |

025-02 是本批唯一高风险任务。三个任务串行，均要求隔离 worktree、verifier、严格 TDD、Stage 1 与独立强模型 Stage 2。

## v4 决策契约

competent-player-v4 必须继承 v3 的 competent meta 与 predictive-v2 full-graph elite safety，只把 combat/meta 的角色语义标记为 role-aware-v1。v1/v2/v3 的 profile 注册、component map 和历史行为保持不变。

| 决策点 | v4 唯一合法行为 |
| --- | --- |
| burn starter | 40000 starter priority 只允许 cost=0、含 enemy burn、且不含 damage 的纯启动牌；现有 0 费纯 burn fixture 继续先打，混合 burn 攻击不再获得该奖励 |
| 自伤生存 | 仅对含 damage_self 或 self burn 的牌比较 no-card enemy-turn baseline；若 baseline 可活而出牌后敌方行动前/后死亡，则拒绝该牌；若 baseline 本就必死，沿用现有评分寻找改善分支 |
| searing_wound 清理 | 先执行全部正常正分决策；只有正常选择为空、手/抽/弃合计至少 2 张 searing_wound、当前来伤已被现有护甲完全覆盖、支付后 HP 仍不低于最大生命 50% 时，才打出创口；重复调用最多清到只剩 1 张或触发 HP 门 |
| 苦修香炉战斗评分 | 对 create searing_wound 的卡，按当前 owned relic、card_id、触发次数和实际存活敌人计算非致死 damage_all_enemies 的分值；必须 honour once_per_turn/once_per_combat |
| 苦修香炉奖励评分 | 仅在当前角色实际拥有匹配 card_created/searing_wound 遗物时，为创口生成量加入按 all-enemies damage multiplier 计算的保守静态收益；没有遗物时维持现有污染负分 |
| 诊断 | role-semantics-v1 opt-in 输出 hybrid_burn_priority_suppressed、self_damage_survival_vetoes、wound_cleanup_plays、searing_wound_relic_score_uses；默认报告 schema 和 v3 输出不增加字段 |

## 025 自动化门

### 决策级 fixture

1. 混合 burn 攻击与两张必要防御同手时，v4 首选防御；v3 fixture 保留历史选择，证明版本隔离。
2. 0 费纯 burn starter 仍在可支付伤害 follow-up 前打出。
3. no-card 可活、出自伤牌后会死于敌方行动时，v4 拒绝自伤牌；直接自杀、thorn、phase 和 burn 既有测试全部继续通过。
4. 两张以上 searing_wound、零未格挡来伤、支付后不少于 50% 最大生命时，正常牌耗尽后清理到一张；单创口、低血或存在未格挡来伤时不清理。
5. penitent_censer 的非致死 2 点全体伤害能改变 wound creator 的战斗/奖励排序；无 censer、已触发 once gate 或非匹配 card_id 时不加分。
6. v4 elite prediction 必须实际使用 v4 combat profile；v3 full-graph safety 结果不变。

### 64 局配对可信度门

- candidate：复用 tests/fixtures/balance_candidates/024-B0.json，但 identity 必须是 025-V4-B0，不覆盖 024 evidence。
- 样本：3×4×64 primary + 同配置 repeat，共 1,536 局。
- primary/repeat 必须 byte-identical；strategy_profile 必须为 competent-player-v4，fallback=false，role semantics 版本必须为 role-aware-v1。
- Pyre C0 的 intro_patrol + cinder_kennels 加权平均损血必须从 v3 B0 的 21.794 降至不高于 19.615，且两遭遇死亡合计必须从 18 降至不高于 14。
- Pyre C0 第一章完成不得低于 33/64；Ember 不得低于 44/64；Arc 不得低于 51/64。
- 其余角色/挑战第一章完成相对 024-B0 不得下降超过 4/64。
- 这些是策略可信度方向门，不是生产胜率目标；不得用 18-21/11-16/8-13/6-9 的角色数值内带选择 v4。
- 通过状态为 role_strategy_credibility_passed_reaudit_required；失败状态为 paused_role_strategy_credibility_failed。两种状态都禁止 128/256、生产写入和试玩打包。

## 批次限制与停止条件

- 允许修改：BalanceSimulator 的薄 profile/委托接线、新 role semantics helper、新 focused tests、新 025 runner/gate/evidence/docs/task artifacts。
- 禁止修改：scripts/combat/CombatState.gd、data/cards、data/relics、data/config/player.json、敌人/遭遇/地图/挑战/经济、numerical_tree.campaign_matrix、真人 cohort、export/version/package。
- 禁止重跑 023/024 ladder；禁止追加 A4/E4/Y4；禁止选择最接近候选；禁止降低任何现有 hard gate。
- 任一 critical、两次 verifier 失败、File Manifest 越界、v3 行为漂移、primary/repeat 不同或 Round 6 未形成可信度通过，立即暂停并重新切 scope，不自动开启 Round 7。

## Confirmation Gate

本轮只生成差距审计、状态与批次建议；未创建 Batch 025 task，未修改业务代码或生产数值，未运行新模拟或打包。

请确认这个差距审计、交付状态更新和选定批次。如果确认，我将为本批次创建或更新 Trellis tasks 和 PRD，但暂不实现功能。
