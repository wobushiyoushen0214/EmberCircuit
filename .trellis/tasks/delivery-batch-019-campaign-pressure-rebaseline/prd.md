# 019：跑团失败归因与跨章压力重标定

## 需求 ID

- REQ-003
- REQ-004
- REQ-005
- REQ-009

## 目标

关闭 018D 后完整跑团在章节到达、遭遇失败集中度、角色/挑战差异和跨章续航上的诊断缺口，并以真实配对模拟证据重新标定二、三章压力、奖励与经济。批次必须保持启发式 AI 与真人 cohort 隔离，不把 64-seed 方向报告写入正式矩阵。

## 当前缺口

- 3×4×256 current-greedy 矩阵 12 格均为 `campaign_win_rate_low`；C0/C1/C2/C3 平均胜率为 `6.5%/3.8%/2.0%/1.2%`。
- C0 角色差为 `10.5%`，超过启发式 AI 的 `9%` 门槛；64-seed 方向报告总平均胜率 `2.0%`、平均完成章节 `0.38`。
- 现有报告只有失败计数，缺少可复现的章节进入/完成、章末资源和跨章续航归因。
- 现有单战 21/21 pressure cases 没有禁止风险，因此禁止用全局 pressure threshold、全局倍率或免费开局资源修复 campaign 缺口。

## 交付 Loop 控制

- 交付批次：`delivery-batch-019-campaign-pressure-rebaseline`
- Loop：L3；需要 worktree：是；需要 verifier：是。
- 子任务依赖：`01` → `02` → `03`，严格串行。
- 实现技能：`trellis-implement-tdd-zh`
- 调试技能：`trellis-debug-systematic-zh`
- 评审技能：`trellis-review-twostage-zh`
- 人工门：Stage 2 需要强模型或人工复核；出现 critical、File Manifest 越界、verifier 连续两次失败或同一 REQ 两轮无进展时暂停。
- 每个任务最大修复尝试 2 次、最大调试假设轮 3 次；实现者不得 commit、push、merge 或自行标记完成。

## 子任务

1. `01-campaign-failure-attribution-contract`：只扩展现有 `BalanceSimulator` 的 campaign 聚合与契约测试，不改生产数值。
2. `02-act2-act3-pressure-and-reward-rebaseline`：仅在 01 的 128-seed 归因门通过后，按冻结阶梯逐值调整二、三章敌人、奖励和经济。
3. `03-campaign-matrix-verification`：运行 128-seed 方向门、256-seed 正式矩阵、全量 Godot regression、真人 schema 检查，并用真实报告同步正式矩阵。

## 批次排除

- REQ-006 内容美术、REQ-008 正式音频/演出、REQ-010 九宫格模式、REQ-011 Steam/安装器/商业签名。
- 不改 `CombatState`、`SaveManager` schema、挑战 pressure thresholds、全局敌人倍率、免费开局生命/金币/牌组或真人报告的胜率分母。

## 批次验收

- 归因报告能在相同输入和 seed 下复现，并按章节、遭遇、角色、挑战、跨章续航输出字段；64 runs 明确为诊断样本，128+ 才有 hard-gate eligibility。
- 二、三章重标定只改文件清单内的实际数据和对应快照/说明，单战 pressure 21/21 回归保持无禁止风险，挑战胜率单调。
- 256-seed 正式矩阵所有 12 格由工具报告生成，目标区间、角色差、最终金币/牌组范围和 risk flags 均由测试核对；observed 字段禁止手写。
- 全量 Godot 测试、数值树审计、campaign report schema、真人 cohort schema 和双阶段评审通过。

## 证据入口

- `.trellis/audits/2026-07-19-post-018d-gameplay-balance-delta-audit.md`
- `.trellis/audits/2026-07-19-post-018d-gameplay-balance-self-review.md`
- `scripts/tools/BalanceSimulator.gd`
- `data/config/numerical_tree.json`
- `docs/09_NUMERICAL_TREE_AND_BALANCE.md`

## 2026-07-19 执行结果

- 019-01 完成并通过双阶段评审：归因 schema、章节/跨章快照、失败集中度和角色/挑战聚合可复现。
- 019-02 触发冻结阶梯停机：R1/R2 四档胜率均低于目标；R2-A 新增 `null_workshop:encounter_hp_low` hard warning；R2-B 继承该二章 HP 档。
- 所有候选生产数值已回滚，`selected_step` 为空，批次状态为 `paused_no_candidate_passed`。
- 019-03 因缺少通过方向门的 selected step 取消，未运行或同步正式 256 observed rows。
