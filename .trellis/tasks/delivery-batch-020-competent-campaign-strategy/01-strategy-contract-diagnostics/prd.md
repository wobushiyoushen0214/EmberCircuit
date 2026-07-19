# 020-01：策略契约与决策遥测

## 需求 ID

- REQ-004
- REQ-009
- AC-020-01 ～ AC-020-05

## 当前缺口

- 当前状态：PARTIAL。
- 代码证据：`scripts/tools/BalanceSimulator.gd:73-101` 固定输出 `current-greedy`；`scripts/tools/BalanceSimulator.gd:123-219` 的 campaign state 没有策略版本和完整决策计数；`scripts/tools/BalanceSimulator.gd:2426-2478` 的 sample run 只保留部分结果。
- 测试证据：`tests/test_balance_simulator.gd:140-230` 已断言旧 schema、paired seed 和归因字段，但没有 profile 参数或决策遥测契约。
- 缺口：无法在同一 seed 下比较两个策略，也无法知道篝火、奖励、商店和药水决策是如何影响失败。
- 风险：直接调生产数值会把策略弱点误判成敌人压力。

## 复杂度与规划产物

- 复杂度：中。
- 执行模型假设：qwen3.6 35b 本地模型按 TDD 机械实现。
- 必要产物：`prd.md`、`design.md`、`implement.md`、`implement.jsonl`、`check.jsonl`。
- Spec 新鲜度：`.trellis/spec/` 不存在；稳定契约使用本批审计、`docs/09_NUMERICAL_TREE_AND_BALANCE.md` 和现有测试。

## 文件清单

| 操作 | 文件 | 精确修改 |
| --- | --- | --- |
| 修改 | `scripts/tools/BalanceSimulator.gd` | `run_campaign_suite()`、`_run_campaign_case()`、`_run_campaign_once()`、`_campaign_result()`、`_aggregate_campaign_case()`、`_summarize_campaign_run()` 增加 `campaign_strategy_schema_version=1`、策略 profile 和决策遥测；默认 profile 仍为 `current-greedy`。 |
| 修改 | `tests/test_balance_simulator.gd` | 增加 profile 默认/显式兼容、schema 字段、决策计数非负、同 seed 完全确定性和 sample 字段断言。 |
| 新建 | `design.md` | 记录状态契约、编排/计算分离和挂载点。 |
| 新建 | `implement.md` | 记录逐步实现计划和失败恢复。 |
| 新建 | `implement.jsonl` | 列出审计、数值树和测试上下文。 |
| 新建 | `check.jsonl` | 列出验证前必须读取的契约和回归说明。 |
| 新建 | `tdd-progress.md` | 记录 AC 红→绿进度。 |

## 决策表

| 决策点 | 选定方案 | 排除方案 |
| --- | --- | --- |
| 默认 profile | 省略 `strategy_profile` 等同 `current-greedy` | 改变旧调用默认行为 |
| profile schema | `campaign_strategy_schema_version=1`，只允许 `current-greedy` 与 `competent-player-v1` 两个字符串 | 写自由文本或覆盖旧 `version=1` |
| 未知 profile | 归一化为 `current-greedy` 并输出 `strategy_profile_fallback=true` | 静默执行未知分支 |
| 决策计数 | 逐局整数计数，聚合为 case 平均值；缺失计数按 0 | 从最终牌组反推行为 |
| sample | 保留既有三个失败优先样本，并附决策遥测 | 扩大样本或写入正式矩阵 |

## MVP 兼容性契约

| 已有行为 | 证据 | 必须保留 | 回归 |
| --- | --- | --- | --- |
| `run_campaign_suite()` paired-by-iteration seed | `BalanceSimulator.gd:114-121`、`test_balance_simulator.gd` | 是 | 旧 campaign deterministic test |
| `strategy_profile=current-greedy` | `BalanceSimulator.gd:82-87`、`test_numerical_balance_matrix.gd` | 是 | 默认/显式 profile JSON 相等 |
| 019 attribution fields | `BalanceSimulator.gd:2133-2178` | 是 | chapter/failure schema tests |

## 验收标准

- [ ] AC-020-01：省略 `strategy_profile` 与显式 `strategy_profile=current-greedy` 在相同输入下逐 case 结果完全一致，旧字段仍存在。
- [ ] AC-020-02：campaign 顶层和 case 都输出整数 `campaign_strategy_schema_version=1`、归一化 profile 和 `strategy_profile_fallback`。
- [ ] AC-020-03：每个 case 的决策遥测包含 `campfire_heal_count`、`campfire_upgrade_count`、`card_reward_offer_count`、`card_reward_accept_count`、`card_reward_skip_count`、`shop_card_purchase_count`、`shop_potion_purchase_count`、`potions_used_count`，值均为非负整数或非负均值。
- [ ] AC-020-04：sample run 含 `strategy_profile`、schema version 和同名决策计数；64/128 样本门和 019 attribution flags 语义不变。
- [ ] AC-020-05：相同 profile、角色、挑战、迭代和 max_turns 重复执行，完整 `cases` JSON 完全相等；既有 balance simulator、card telemetry 和 numerical matrix tests 回归通过。

## 自检命令

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_simulator.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_card_telemetry.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_balance_matrix.gd
```

## 禁止事项

- 不修改生产 JSON、正式矩阵、CombatState、真人报告。
- 不删除或弱化 019 测试断言。
- 不在本任务实现 competent 的策略分支；那属于 020-02。
- 不新增平行 simulator。
