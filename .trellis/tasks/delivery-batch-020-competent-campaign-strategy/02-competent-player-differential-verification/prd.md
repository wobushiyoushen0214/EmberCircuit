# 020-02：competent-player-v1 策略与差分验证

## 需求 ID

- REQ-003
- REQ-004
- REQ-005
- REQ-009
- AC-020-06 ～ AC-020-12

## 依赖

- 依赖：`020-01-strategy-contract-diagnostics`。
- 原因：必须先有版本化 profile、逐局决策遥测和默认兼容门，才能比较策略而不污染旧报告。

## 当前缺口

- 当前状态：PARTIAL。
- 代码证据：`BalanceSimulator.gd:1253-1339` 路线分数没有战斗压力；`BalanceSimulator.gd:1564-1572` 奖励选择不读牌组；`BalanceSimulator.gd:1718-1752` 角色参数未使用；`BalanceSimulator.gd:1925-1943` 升级 ID 和角色上下文不完整；`BalanceSimulator.gd:1136-1167` 药水策略过于局部。
- 测试证据：`tests/test_balance_simulator.gd:200-240` 仅验证旧 route score 与 profile；没有 competent profile 的差分门。
- 缺口：无法回答“低胜率是数值压力还是模拟器策略”这一核心问题。

## 复杂度与规划产物

- 复杂度：高；只允许一个高风险任务。
- 执行模型假设：qwen3.6 35b 按已定决策机械实现，Stage 2 必须强模型/人工评审。
- 必要产物：`prd.md`、`design.md`、`implement.md`、`implement.jsonl`、`check.jsonl`。
- Spec 新鲜度：`.trellis/spec/` 缺失；使用本批审计、`BalanceSimulator.gd`、既有测试和数值树文档作为稳定上下文。

## 文件清单

| 操作 | 文件 | 精确修改 |
| --- | --- | --- |
| 修改 | `scripts/tools/BalanceSimulator.gd` | 只在 `competent-player-v1` 分支启用：角色/牌组感知奖励评分、修正升级条目解析、0.80 篝火恢复阈值、按 HP/牌组成熟度的路线评分、提前且有理由的药水决策；`current-greedy` 分支保持旧行为。 |
| 修改 | `tools/run_balance_simulation.gd` | 解析 `--strategy-profile=` 并传入 campaign options。 |
| 修改 | `tests/test_balance_simulator.gd` | 增加 competent profile 单元/fixture 断言和默认兼容断言。 |
| 修改 | `tests/test_numerical_balance_matrix.gd` | 增加正式矩阵冻结断言：020 报告不能覆盖 256 rows，矩阵 profile 仍 current-greedy。 |
| 新建 | `docs/10_STRATEGY_DIFFERENTIAL_020.md` | 记录 128 paired 报告路径、SHA-256、逐档胜率/章完成率/决策遥测、差分门和最终停机状态；不写入正式矩阵。 |
| 新建 | `.trellis/tasks/.../verification-report.md` | 记录候选报告和门结果。 |
| 新建 | `design.md`、`implement.md`、`implement.jsonl`、`check.jsonl`、`tdd-progress.md` | 规划、上下文和 TDD 证据。 |

## 决策表

| 决策点 | 选定方案 | 排除方案 | 原因 |
| --- | --- | --- | --- |
| 策略 profile | `competent-player-v1` 只改变模拟器决策，不改变游戏生产行为 | 改 `CombatState` 或生产 JSON | 先隔离归因 |
| 路线评分 | 仅用已加载 encounter/config 的静态压力估计 + 当前 HP/牌组/遗物；固定 tie-break | 真实额外战斗 roll、修改地图生成器 | 保持 paired seed 与确定性 |
| 牌组评分 | 角色 tags + 已有牌型/资源计数 + 重复惩罚；仍从既有牌数据读取效果 | 硬编码单卡胜率、改变掉落池 | 避免 overfit |
| 篝火 | competent 在 `hp_ratio <= 0.80` 休息，否则升级；每个篝火最多一个动作 | 改生产篝火恢复量或免费升级 | 只模拟决策差异 |
| 升级解析 | 统一先 `_base_card_id` 再读 `upgrade`，传入 character_id | 直接用带 `+` ID 查卡 | 修复可证实 bug |
| 药水 | 低于 50% HP 或可阻止当前攻击/可结束战斗时使用；仍尊重药水槽和顺序 | 每战自动消耗、恢复免费药水 | 可解释的资源管理 |
| 结果门 | 同输入 deterministic；C0-C3 平均胜率不低于 current，第一章完成率下降不超过 0.02 | 修改目标、把 128 写入正式 256 | 失败就停机，不造数 |

## MVP 兼容性契约

| 行为 | 证据 | 必须保留 | 回归 |
| --- | --- | --- | --- |
| 默认 current-greedy | 020-01、`test_balance_simulator.gd` | 是 | explicit/default cases 相等 |
| 21/21 single pressure | `test_balance_simulator.gd`、`test_numerical_pressure_metrics.gd` | 是 | strict regression |
| 正式矩阵 rows/hash | `data/config/numerical_tree.json`、`test_numerical_balance_matrix.gd` | 是 | JSON snapshot remains unchanged |
| 真人/AI 隔离 | `PlaytestEvidenceGate` tests | 是 | no report merge |

## 验收标准

- [ ] AC-020-06：`--strategy-profile=competent-player-v1` 和 API option 产生同一 profile/schema；未知 profile 回退 current 并标记 fallback。
- [ ] AC-020-07：competent route fixture 在低 HP 时选择可恢复节点，在高 HP 且牌组成熟时可选择奖励路线；同分候选按 node id 稳定 tie-break，current fixture 旧断言仍绿。
- [ ] AC-020-08：competent card reward fixture 对角色资源和重复牌有不同分数；至少一个角色专属资源牌优先于同分无关牌；升级带 `+` 的条目仍能找到合法 upgrade。
- [ ] AC-020-09：competent campfire/potion fixture 记录确定性动作；低于 50% HP 的治疗药水或可挡当前攻击的药水会被使用，空槽/无效药水不消耗。
- [ ] AC-020-10：相同 3×4×128 paired 输入的 competent report 重复运行完全相等，并输出 `/tmp/ember020-current-greedy-128.json` 与 `/tmp/ember020-competent-player-v1-128.json` 的 SHA-256。
- [ ] AC-020-11：差分报告逐角色/挑战输出 win rate、chapter-one completion、avg final gold/deck、决策遥测和 failure concentration；不覆盖正式 256 matrix。
- [ ] AC-020-12：若 competent profile 未达到“C0-C3 平均胜率均不低于 current 且第一章完成率下降不超过 0.02”的门，报告写 `paused_no_strategy_passed`，不改生产 JSON；若通过，报告只解锁下一轮候选设计，不直接改数值。

## 自检命令

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_simulator.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_balance_matrix.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_pressure_metrics.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tools/run_balance_simulation.gd -- --mode=campaign --strategy-profile=current-greedy --iterations=128 --max-turns=80 --challenges=0,1,2,3 --output=/tmp/ember020-current-greedy-128.json
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tools/run_balance_simulation.gd -- --mode=campaign --strategy-profile=competent-player-v1 --iterations=128 --max-turns=80 --challenges=0,1,2,3 --output=/tmp/ember020-competent-player-v1-128.json
```

## 禁止事项

- 不改任何生产 JSON、`campaign_targets`、正式 256 rows、CombatState、MapGenerator 或真人 cohort。
- 不把 competent profile 设置为默认，不删除 current-greedy 历史报告。
- 不通过降低目标、扩大容差、删除压力测试或写入 expected exception 来制造通过。
- 不实现新的全局倍率或自动恢复资源。
