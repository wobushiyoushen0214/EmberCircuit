# Batch 024：角色平衡候选重标定

## 需求 ID

- REQ-003
- REQ-004
- REQ-005
- REQ-009
- AC-024-01 至 AC-024-22

## 目标

在 023 五个全局压力候选全部未通过 128 hard gate 后，以角色行动经济和累计生存为唯一调参轴，建立可隔离、可重放、可版本化的角色候选漏斗。只有唯一组合候选连续通过单角色 64、组合 64、组合 128 primary/repeat 和组合 256 primary/repeat 的全部原始整数门，才能写入生产配置并构建 `0.1.0-alpha.9` PC 试玩版。

## 批次状态

- Loop：L3，Round 5/6，`completed_with_pause`。
- 用户确认：2026-07-23 明确回复“确认执行”。
- worktree：`/Users/lizhiwei/localProj/EmberCircuit-batch024`。
- branch：`codex/batch-024-character-parity-rebaseline`。
- verifier：必须；Stage 1 与独立强模型 Stage 2 均必须无阻断。
- 唯一高风险任务：`024-02-bounded-character-parity-calibration`。
- 样本上限：024-02 最多 6,912 局；024-03 条件式最多 6,144 局；合计最多 13,056 局。
- 最终裁决：024-02 正式运行 `1,536` 局后为 `paused_no_arc_candidate_passed`；A1/A2/A3 均未同时通过四档原始胜局门，未选择“最接近”候选。
- 任务结果：024-01 completed；024-02 completed（Review Round 4 C0/M0/m0）；024-03 `canceled_no_selected_128_candidate`。
- 生产结果：未运行 Ember/Pyre/组合 64/128/256，未修改生产数值或正式 matrix，未构建 alpha.9 试玩包。

## 串行任务

| 顺序 | 任务 | 风险 | 解锁条件 |
| --- | --- | --- | --- |
| 1 | `024-01-character-overlay-and-evidence-contract` | 中 | selector、五数据集恢复、compact evidence 和默认 byte identity 全绿 |
| 2 | `024-02-bounded-character-parity-calibration` | 高 | 024-01 双阶段评审无阻断 |
| 3 | `024-03-production-256-and-playtest-package` | 中 | 024-02 产生唯一 `selected_128_candidate`；否则取消 |

## 全批冻结项

- 不修改 `scripts/combat/CombatState.gd`、卡牌定义、敌人、遭遇、挑战倍率、campaign targets、金币奖励、AI 选牌阈值或真人 cohort。
- 不降低 `LayeredPressureCandidateGate.gd` 的 128/256 门；不按距离选择“最接近”候选。
- 不继续使用 P5 全局 `60/30/10` 稀有度；B0 固定为 P4 的 layer/pressure/campfire/heal，卡牌稀有度保持生产 `65/28/7`。
- 不发明 A4/E4/Y4、第二个组合候选或第 7 轮自动扩展。
- 任一候选耗尽、repeat 不一致、critical review、两次 verifier 失败或 File Manifest 越界立即停机。

## 完成定义

- 024-01、024-02、024-03 均通过严格 TDD 和双阶段评审；若 024-02 无 selected，则 024-03 以 `canceled_no_selected_128_candidate` 结束，不视为漏执行。
- 256 primary/repeat 全门通过后，生产 snapshot、正式 matrix、`docs/03`、`docs/09`、`docs/14` 和包体版本完全一致。
- 未通过时生产配置、正式 matrix、`playtest_package_eligible=false` 和现有 alpha.8 包体保持不变。
