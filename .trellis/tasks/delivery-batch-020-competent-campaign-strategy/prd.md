# Batch 020：胜任玩家跑团策略重基线

## 需求 ID

- REQ-003
- REQ-004
- REQ-005
- REQ-009

## 目标

在不改变任何生产 JSON、正式 256 矩阵或真人 cohort 的前提下，为 campaign simulator 建立可切换、可复现且可审计的 `competent-player-v1` 策略 profile。先证明旧 `current-greedy` 的低通关率是否由模拟器决策不足造成，再决定后续是否允许数值候选。

## 交付 Loop 控制

- 交付批次：`delivery-batch-020-competent-campaign-strategy`
- Loop 模式：L3
- 需要 worktree：是
- 需要 verifier：是
- 实现技能：`trellis-implement-tdd-zh`
- 调试技能：`trellis-debug-systematic-zh`
- 评审技能：`trellis-review-twostage-zh`
- 人工门：策略差分门未通过时必须暂停，不允许发明 R3 或改生产数值。
- 最大修复尝试次数：2
- 最大调试假设轮数：3
- 回滚触发：verifier critical、回归失败、File Manifest 外改动、默认 profile 行为变化、正式矩阵/生产 JSON 被修改。

## 任务顺序

1. `01-strategy-contract-diagnostics`：策略入口、版本、逐局决策遥测。
2. `02-competent-player-differential-verification`：熟练策略实现和 128 paired differential report，依赖 020-01。

## 范围外

- 不修改 `data/cards`、`data/enemies`、`data/encounters`、`data/config/player.json`、`data/config/economy.json`、`data/config/numerical_tree.json`。
- 不修改 `campaign_targets`、challenge multiplier、开局资源、CombatState、Main、SaveManager。
- 不把 128 报告同步进正式 256 observed/risk 字段。
- 不将 AI 结果当真人难度证明。
