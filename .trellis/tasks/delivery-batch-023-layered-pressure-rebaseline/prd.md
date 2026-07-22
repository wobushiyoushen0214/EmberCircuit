# Batch 023：分层压力与成长重标定

## 需求 ID

- REQ-003
- REQ-004
- REQ-005
- REQ-009
- AC-023-01 ～ AC-023-17

## 目标

在 `competent-player-v3` 已通过路线安全门的基础上，以隔离候选 overlay 验证第一章遭遇分层、路线压力间距、篝火数量/恢复和奖励品质。只允许第一个同时通过 64 方向门、128 硬门和 256 正式门的候选进入生产数值树；任何阶段失败都保留证据并回滚，禁止打包未通过候选。

## 当前缺口

- 022 v3 的 C0-C3 128 平均胜率为 `8.9/5.5/3.1/2.9%`，全部低于目标，C0/C1 角色差 `16.5/10.9%`。
- `/tmp/ember023-act1-single-64.json` 的 21 个第一章单战 case 全部无 risk，但 `iron_checkpoint` 的三角色 HP 损失 p50/p90 均值为 `36.0/50.3`。
- `MapGenerator._make_node()` 从全章 `encounter_by_type.combat` 池抽取遭遇，强制开场层也可抽到高磨损中段战。
- 019 的 R1/R2 只增加奖励数量、药水和金币，胜率几乎不变；本批禁止重复该方向或恢复免费开局资源。

## 交付 Loop 控制

- 批次：`delivery-batch-023-layered-pressure-rebaseline`；Loop：L3；Round：4。
- worktree：`/Users/lizhiwei/localProj/EmberCircuit-batch023`；分支：`codex/batch-023-layered-pressure-rebaseline`。
- 每任务必须 verifier；实现使用 `trellis-implement-tdd-zh`，失败使用 `trellis-debug-systematic-zh`，完成前使用 `trellis-review-twostage-zh`。
- Stage 2 必须由独立强模型执行；最大修复 2 次，最大调试假设 3 轮。
- 回滚：File Manifest 越界、生产冻结项变化、默认模拟行为漂移、静态/路径/样本门失败、review critical 或 verifier 连续失败两次。

## 串行任务

| 顺序 | 任务 | 风险 | 解锁条件 |
| --- | --- | --- | --- |
| 1 | `023-01-candidate-overlay-and-attrition-contract` | 中 | overlay fail-closed、默认 byte identity、attrition-v1 归因全绿 |
| 2 | `023-02-layered-pressure-and-growth-rebaseline` | 高，本批唯一高风险 | 023-01 Stage 2 无阻断；按 P1-P5 顺序选择首个 64+128 通过候选 |
| 3 | `023-03-production-matrix-verification` | 中 | 023-02 存在 selected step；否则任务取消且不得创建 256 报告 |

## 固定候选阶梯

| Step | 变化 |
| --- | --- |
| P1 | 第一章普通遭遇：L0=`intro_patrol`；L1-L2=`intro_patrol,polluted_lab,cinder_kennels`；L3-L6=`polluted_lab,iron_checkpoint,cinder_kennels` |
| P2 | P1 + `max_pressure_nodes_between_campfires=3` |
| P3 | P2 + 三章 `node_budget.campfire=[2,2]` |
| P4 | P3 + 篝火恢复 `30%` |
| P5 | P4 + 战斗卡稀有度 `common/uncommon/rare=60/30/10` |

P1-P5 从任务起点按上表累积；未声明字段保持 023 起点，禁止发明 P6。玩家起始 HP/牌组/金币/势能/遗物、卡牌效果、敌人 HP/action/phase、药水 `45%`、金币 `0/3/6`、接受阈值 `8.2`、跳过阈值 `15`、challenge 和 campaign targets 全部冻结。

## 验证门

- 64 方向门使用 v3、3×4、paired：每挑战胜局不得低于 `[16,8,5,3]`；第一章完成不得低于 `[76,60,35,19]`，且 C0 至少 `84/192`、C1 至少 `66/192`。
- 128 硬门：四档平均落入 `[0.27,0.33]/[0.17,0.26]/[0.12,0.23]/[0.08,0.15]`；单格允许 3% 容差；角色差不超过 9%；挑战单调容差 1%；单遭遇失败占比不超过 50%；最终金币 `100-180`、牌组 `16-19`，均值容差 0.5。
- 256 正式门重复全部 128 门，并要求相同命令 repeat byte-identical、完整回归和双阶段评审无阻断。

## MVP 兼容性契约

- 无 overlay、无 attrition diagnostics 时，默认报告与任务起点 byte-identical。
- 未声明 `encounter_layer_bands` 的章节继续使用 `encounter_by_type`。
- P1-P5 只通过模拟 overlay 比较；未通过前不修改生产 JSON或正式 matrix。
- `CombatState.gd` 仍是唯一战斗结算器；AI 报告不写入真人 cohort。

## 停止条件

- 任一候选 64 失败：保存报告和 SHA，继续下一候选，不运行该候选 128。
- 候选 64 通过但 128 失败：保存两份报告和 gate 结果，继续下一候选。
- P1-P5 均失败：记录 `paused_no_layered_candidate_passed`，生产配置和正式 matrix 保持起点，023-03 取消。
- selected candidate 的 256 失败：回滚生产候选，正式 matrix 不更新，试玩包继续锁定。

## 禁止事项

- 不修改目标、容差、expected exception 来制造通过。
- 不手改 report、胜局数、matrix observed rows 或 SHA。
- 不混入 UI、资产、音频、网格模式、发布、真人遥测或 `Main.gd` 重构。
- 不在任务分支外实现，不在 Stage 2 前标记完成。
