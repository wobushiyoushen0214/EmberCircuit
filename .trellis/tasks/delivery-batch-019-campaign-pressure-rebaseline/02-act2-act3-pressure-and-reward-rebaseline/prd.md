# 019-02：二三章压力、奖励与经济重标定

## 需求 ID

- REQ-003
- REQ-004
- REQ-005
- AC-019-06 ～ AC-019-10

## 目标

只在 019-01 的 128-seed 归因报告通过 schema/eligibility 门后，按固定候选阶梯逐值调整奖励供给、二三章敌人和章节经济，使 current-greedy 完整跑团接近既有 challenge 目标，同时保持第一章单战 21/21 pressure 无禁止风险、挑战难度单调且不恢复免费开局资源。

## 前置证据门

执行前必须存在 `/tmp/ember019-attribution-128.json`，并同时满足：

- 12 cases、每格 128 runs、`strategy_profile=current-greedy`、`seed_model=paired_by_iteration`。
- 每个 case `campaign_attribution_schema_version=1`、`attribution_gate_eligible=true`。
- summary 含 3 个角色行、4 个挑战行和按章 attribution；报告可由同命令复现。
- 如果缺任一字段，停止并返回 019-01，不允许修改数值。

## 当前缺口

- 权威 256 矩阵 12/12 `campaign_win_rate_low`；最终金币 `65.879-81.094`、牌组 `11.879-15.406`，后章构筑成熟度不足。
- 单战 21/21 pressure case 已在允许范围，说明不能放宽全局 threshold 或 challenge multiplier。
- 生产奖励配置已完全数据驱动：`combat_card_accept_score=8.2`、`skip_reward_when_deck_at_least=15`、药水掉落 45%、二/三章金币加成 3/6。

## 交付控制

- 批次：`delivery-batch-019-campaign-pressure-rebaseline`；Loop：L3；worktree/verifier：是/是。
- 复杂度/风险：高，且是本批唯一高风险实现任务。
- 依赖：`01-campaign-failure-attribution-contract` 评审通过；解锁：`03-campaign-matrix-verification`。
- 实现/调试/评审技能：`trellis-implement-tdd-zh` / `trellis-debug-systematic-zh` / `trellis-review-twostage-zh`。
- 回滚触发：任一单战出现 `too_easy`/`too_lethal`/`encounter_too_fast`/`encounter_too_slow`，挑战不单调，File Manifest 越界，或 128 矩阵连续两次 verifier 失败。

## 冻结候选阶梯

每级均从任务起点重新应用，禁止累乘；每次只推进一级并保存独立 `/tmp/ember019-step-{step_id}-128.json`。选定规则：选择第一个满足全部 128 方向门的 step；无 step 通过则暂停，不自行扩大范围。

| Step | 奖励/经济 | 二章 HP 档 | 三章 HP 档 |
| --- | --- | --- | --- |
| R1 | accept `7.8`；skip `17`；potion `55%`；章金币 `0/5/10` | 不改 | 不改 |
| R2 | accept `7.4`；skip `18`；potion `60%`；章金币 `0/7/12` | 不改 | 不改 |
| R2-A | R2 | 普通 `[44,52,42,46,50]`；elite `104`；boss `114` | 不改 |
| R2-B | R2 | R2-A | 普通 `[50,52,50,50,54]`；elite `104`；boss `126` |

顺序中的二章普通数组依次对应 `volt_cultist/glass_sentinel/null_mender/storm_cantor/prism_scrapper`；三章数组依次对应 `void_scribe/gravity_lancer/core_mimic/memory_parasite/orbit_reclaimer`。`R2-B` 不改行动序列、intent damage、block、status 或 Boss phase；若仅降低 HP 仍不通过，停止而不是继续削伤害。

## 128 方向门

全部条件同时满足才选定 step：

- 12 cases 均 eligible，C0/C1/C2/C3 聚合胜率落入既有目标 `[0.27,0.33]`、`[0.17,0.26]`、`[0.12,0.23]`、`[0.08,0.15]`；单 cell 只允许既有 `0.03` 容差。
- 每挑战角色差不超过 `0.09`，挑战均值按 C0≥C1≥C2≥C3 单调（容差 `0.01`）。
- 每 case 的 `failure_concentration.attribution_flags` 为空；任一 encounter 的失败占比不超过 `0.5`。
- 21/21 第一章单战 pressure cases `risk_flags=[]`；数值树不新增 card/monster hard warning。
- 平均最终金币和牌组大小进入 `numerical_tree.economy_targets` 既有范围；不得通过改目标范围制造通过。

## 决策表

| 决策点 | 选定方案 | 原因 | 文件 |
| --- | --- | --- | --- |
| 变更顺序 | 先供给 R1/R2，再按归因只降二章、再降三章 HP | 先修构筑不足，避免把所有敌人一起削弱 | economy/enemies/tree |
| 敌人调整 | 只使用上表 exact max_hp；intent 与 phase 不改 | 单战 pressure 已通过，避免破坏可读性与攻击节奏 | `enemies.json` |
| 第一章 | 敌人、遭遇、地图、起始资源完全冻结 | 资深玩家反馈开局偏易且 21/21 单战已校准 | 所有相关文件 |
| 正式 observed | 本任务不写 256 observed rows | 128 只用于选方向 | `numerical_tree.json` 只更新 snapshot/selected step，不更新 rows |
| 真人数据 | 不读取、不混合 AI 报告 | 样本与分母契约不同 | none |

## 文件清单

| 操作 | 文件 | 精确修改 |
| --- | --- | --- |
| 新建 | `tests/test_act2_act3_rebaseline.gd` | candidate step、冻结项、数值预算和 128 报告契约 |
| 修改 | `data/config/economy.json` | 只改 selected step 对应 accept/skip/potion/chapter bonus 及 `balance_note` |
| 修改 | `data/enemies/enemies.json` | 仅在 R2-A/B 选中时改上表二三章 `max_hp` 和对应 `balance_note` |
| 修改 | `data/config/numerical_tree.json` | `economy_snapshot` 对齐实际配置；新增 `campaign_rebaseline.selected_step` 与候选证据路径；不改 `campaign_matrix.rows` |
| 修改 | `tests/test_numerical_balance_matrix.gd` | candidate-to-values、冻结目标、selected step 和实际配置一致性 |
| 修改 | `docs/09_NUMERICAL_TREE_AND_BALANCE.md` | 记录 128 step 对比、选定理由和待 256 正式验证状态 |
| 修改 | 本任务 `tdd-progress.md` | 记录逐 step RED/GREEN、命令和报告摘要 |

## MVP 兼容性契约

- 起始 HP/金币/牌组、角色卡池、第一章敌人/遭遇、challenge multipliers、pressure targets、地图固定层、CombatState 和 SaveManager schema 保持不变。
- economy 实际值必须与 `numerical_tree.audit_inventory.economy_snapshot` 一致。
- 每个 enemy intent 的公开 amount/hits/status、action id 和 phase id 不变；只允许表中 max_hp。

## 实现步骤

1. RED（AC-019-06）：新建 `test_act2_act3_rebaseline.gd`，断言 selected step 存在、候选值 exact、冻结字段不变；在生产配置未变时看到失败。
2. GREEN R1：只改 economy/snapshot/note，运行 128 campaign；若全部方向门通过，选 R1 并停止候选推进。
3. RED/GREEN R2：仅在 R1 未通过时把测试预期推进到 R2 exact values，重跑 128；不得同时改敌人。
4. RED/GREEN R2-A：仅在 R2 未通过且 attribution 显示 chapter_two 条件完成率低或二章失败占主要后章失败时，应用 exact 二章 HP 档；重跑 21 单战和 128 campaign。
5. RED/GREEN R2-B：仅在 R2-A 未通过且 chapter_three 仍是主要剩余失败章时，应用 exact 三章 HP 档；重跑 21 单战和 128 campaign。
6. 将第一个通过方向门的报告路径与 SHA-256 写入 docs 和 `campaign_rebaseline`；运行全部自检并收敛，不写正式 256 rows。

## 验收标准

- [ ] AC-019-06：配置只处于 R1/R2/R2-A/R2-B 之一，selected step 与 exact values、snapshot、balance notes 一致；冻结字段哈希/值不变。
- [ ] AC-019-07：每一步有独立 128 report，输入、seed、case 数和 schema 可复现；只选择第一个通过全部方向门的 step。
- [ ] AC-019-08：若修改二三章敌人，只改表中 max_hp；21/21 第一章 single pressure 与静态 monster budget 均无新增 risk/warning。
- [ ] AC-019-09：选定 128 矩阵满足四档聚合目标、角色差、单调性、最终经济/牌组范围和失败集中度门；不靠修改 targets 或 expected exception 列表通过。
- [ ] AC-019-10：`campaign_matrix.rows` 的 256 observed/risk 字段与任务起点完全一致，等待 019-03 工具同步。

## 自检命令

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_act2_act3_rebaseline.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_simulator.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_tree_auditor.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_balance_matrix.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tools/run_balance_simulation.gd -- --mode=campaign --iterations=128 --max-turns=80 --challenges=0,1,2,3 --output=/tmp/ember019-selected-128.json
```

## 范围外与禁止事项

- 不改 pressure threshold、campaign target、economy target、challenge multiplier、第一章敌人/遭遇、起始资源、卡牌效果、地图权重、CombatState、Main 或 SaveManager。
- 不改 intent/action/phase，不新增全局倍率，不恢复免费开局资源，不把 128 report 写入正式 256 observed rows。
- 候选全部失败时必须暂停并交证据包，禁止继续发明 R3 或弱化测试。
