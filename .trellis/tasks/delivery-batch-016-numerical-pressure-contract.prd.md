# Delivery Batch 016: 数值压力契约

## 需求 ID

- REQ-003
- REQ-005
- REQ-009
- REQ-012

## 目标

建立可执行的开局强度、单战压力与遭遇结构契约，让当前第一章“高胜率、低损血、固定空窗、Boss 层级倒挂”被自动化测试识别；本批不修改任何正式玩法数值。

## 当前缺口

- 第一章 starter-only 5376 场单战平均胜率 99.6%，但现有风险仍为 `ok`。
- Auditor 只计算起始牌组，不计算初始势能、起始遗物、固定首回合抽牌和默认 `steel_manual`。
- Simulator 只输出平均值，不输出无伤率、p50/p90、每回合出牌数或复合风险。
- `expected_turns` 仅存在于 JSON 注释预算，没有进入模拟验收。
- 第一章 Boss C0 EHP 为 96，低于最高精英 104，但没有层级门。

## 交付 Loop 控制

- 交付批次：`delivery-batch-016-numerical-pressure-contract`
- Loop 模式：`L3`
- 需要 worktree：是，路径 `/Users/lizhiwei/localProj/.worktrees/EmberCircuit-batch016`
- 需要 verifier：是
- 实现技能：`trellis-implement-tdd-zh`
- 调试技能：`trellis-debug-systematic-zh`
- 评审技能：`trellis-review-twostage-zh`
- 人工门：已通过；用户在 full audit 后明确回复“确认执行”。
- 最大修复尝试次数：2
- 最大调试假设轮数：3
- 回滚触发：严格回归失败、当前错误基线未触发风险、旧 schema 消费者破坏、File Manifest 越界、正式玩法数值发生变化。

## 复杂度与规划产物

- 复杂度：高；跨纯计算、静态审计、模拟聚合和冻结矩阵，但不改运行时战斗行为。
- 执行模型假设：GPT-5 强模型编排，严格按 AC 红绿循环。
- 必要产物：`prd.md`、`design.md`、`implement.md`、`implement.jsonl`、`check.jsonl`、`tdd-progress.md`、`review-report.md`。
- Spec 新鲜度：以 `.trellis/audits/2026-07-17-numerical-rebaseline-full-audit.md`、`docs/09_NUMERICAL_TREE_AND_BALANCE.md` 和现有数值测试为权威契约；`.trellis/spec/` 不存在。

## 决策表

| 决策点 | 选定方案 | 原因 |
| --- | --- | --- |
| 压力 schema | `numerical_tree.version=3`，`pressure_contract.schema_version=1` | 与旧静态预算明确分层 |
| 硬门样本 | 每 case 至少 64 次 | 小样本仍输出诊断，但不作为调参证据 |
| 分位数 | nearest-rank：`ceil(p*n)-1` | 可复算、确定性强 |
| turns 样本 | 仅胜局 | 快速死亡不得被误判为战斗过快 |
| HP loss 样本 | 全部 runs | 失败局损失必须进入压力分布 |
| 完美胜率 | `zero_damage_win_count / runs` | 失败和受伤胜局都不能进入完美样本 |
| cards/turn | `sum(cards_played) / sum(turns)` | 避免逐局平均造成短局偏权 |
| 风险输出 | 新增 `risk_flags[]`；旧 `risk_flag` 保留为最高优先级首项 | 向后兼容并保留复合问题 |
| 策略声明 | `strategy_profile=current-greedy` | 旧弱策略矩阵不再代表真人难度 |
| 正式数值 | 全部冻结 | 先量后调，Batch 017 才改值 |

## 压力阈值

- opening package 目标：Ember `[72,80]`、Arc `[70,78]`、Pyre `[72,80]`。
- 单战胜率上限：normal `0.95`、elite `0.90`、boss `0.85`。
- 完美胜率上限：normal `0.55`、elite `0.35`、boss `0.15`。
- 静态结构：攻击行动占比至少 `0.60`；最长连续零直接伤害行动最多 `1`；前三行动伤害至少为 tier 峰值伤害下限的 `1.25` 倍；Boss/最高精英 C0 EHP 比至少 `1.15`。

## MVP 兼容性契约

| 已有行为 | 必须保留 | 回归检查 |
| --- | --- | --- |
| 战斗、敌人行动与卡牌运行时行为 | 是 | `test_combat_core.gd`、全量回归 |
| Simulator 旧 case 字段和 `risk_flag` | 是 | `test_balance_simulator.gd` |
| Auditor 原 budget `severity/issues` 语义 | 是 | `test_numerical_tree_auditor.gd` |
| campaign 冻结矩阵数值 | 是 | `test_numerical_balance_matrix.gd` |
| 相同 options 生成相同 cases | 是 | deterministic repeat test |

## 文件清单

| 操作 | 文件路径 | 说明 |
| --- | --- | --- |
| 新建 | `scripts/tools/NumericalPressureMetrics.gd` | 纯计算：分位数、聚合、风险排序、循环行动压力与 EHP 比 |
| 新建 | `scripts/tools/NumericalPressureMetrics.gd.uid` | Godot UID sidecar |
| 新建 | `tests/test_numerical_pressure_metrics.gd` | 纯算法 RED/GREEN 测试 |
| 新建 | `tests/test_numerical_pressure_metrics.gd.uid` | Godot UID sidecar |
| 修改 | `scripts/tools/NumericalTreeAuditor.gd` | opening package、静态遭遇压力和层级编排 |
| 修改 | `scripts/tools/BalanceSimulator.gd` | 逐局结果委托聚合、expected turns、风险与策略声明 |
| 修改 | `tests/test_numerical_tree_auditor.gd` | 锁定 opening package 和静态压力基线 |
| 修改 | `tests/test_balance_simulator.gd` | 锁定 64 seeds 过易风险和兼容字段 |
| 修改 | `tests/test_numerical_balance_matrix.gd` | 冻结 pressure schema、异常 inventory 和策略声明 |
| 修改 | `data/config/numerical_tree.json` | 只新增压力测量阈值和冻结异常，不改正式玩法值 |
| 修改 | `docs/09_NUMERICAL_TREE_AND_BALANCE.md` | 记录压力契约、指标口径与 Batch 017 门 |
| 修改 | `docs/06_IMPLEMENTATION_LOG.md` | 记录本批交付证据 |
| 新建/修改 | `.trellis/tasks/delivery-batch-016-numerical-pressure-contract.*` | 规划、TDD 与评审证据 |

## 挂载点

| 挂载点 | 类型 | 位置 | 接线动作 |
| --- | --- | --- | --- |
| 纯指标聚合 | 计算调用 | `BalanceSimulator._aggregate_case()` | 委托 `NumericalPressureMetrics` 生成新增字段和风险 |
| opening package | 审计入口 | `NumericalTreeAuditor._audit_players()` | 加载遗物/技能书并输出贡献与排除项 |
| 遭遇结构 | 审计入口 | `NumericalTreeAuditor._audit_monsters()` | 输出行动压力、C0 EHP 和章节层级 |
| 冻结矩阵 | 质量门 | `test_numerical_balance_matrix.gd` | 声明 `current-greedy`，冻结当前异常供 Batch 017 单调消除 |

## 验收标准

- `AC-001`: 纯指标模块用 synthetic runs 锁定 nearest-rank p50/p90、全 runs HP loss、胜局 turns、完美胜率、cards/turn、64 样本硬门、复合 `risk_flags` 和兼容 `risk_flag` 优先级。
- `AC-002`: 三角色 opening package 输出贡献明细和排除项，精确总分为 Ember `91.38`、Arc `82.47`、Pyre `88.41`；三者均命中 `opening_package_high`，Pyre 条件性香炉进入 exclusions 而不计固定分。
- `AC-003`: `intro_patrol` 静态指标为攻击比 `4/6`、空窗 `1`、前三行动伤害 `34`；第一章 Boss 基础攻击比 `2/5`、空窗 `2`、前三行动伤害 `15`；Boss C0 EHP `96`、最高精英 `104`、比值约 `0.9231` 并命中层级风险。
- `AC-004`: case 输出 chapter/loadout/schema/无伤率/损血与回合分位数/cards-per-turn/expected turns/风险数组；固定 64 seeds 下 Ember `intro_patrol` 主风险为 `normal_too_easy`，三角色第一章 Boss 主风险均为 `boss_too_easy`；小样本不得 `pressure_gate_eligible`。
- `AC-005`: `numerical_tree.version=3`，campaign 与 single report 均声明 `strategy_profile=current-greedy`；旧字段保持兼容；新增后 21 套 Godot 测试全部通过，逐套无 `SCRIPT ERROR` 或 `ERROR:`。

## 自检命令

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_pressure_metrics.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_tree_auditor.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_simulator.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_balance_matrix.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tools/run_balance_simulation.gd -- --iterations=256 --max-turns=30 --characters=ember_exile,arc_tinker,pyre_ascetic --challenges=0 --encounters=intro_patrol,polluted_lab,iron_checkpoint,cinder_kennels,executor_elite,furnace_colossus_elite,chapter_one_boss --output=/tmp/embercircuit-opening-pressure-contract.json
for test in tests/test_*.gd; do ...; done  # 21/21，严格扫描 SCRIPT ERROR 与 ERROR:
```

## 范围外

- 不修改卡牌、角色、遗物、技能书、敌人、遭遇、经济、篝火、挑战或路线正式数值。
- 不升级 heuristic AI 为 beam search；策略升级与实际调值放 Batch 017。
- 不用全局 HP/伤害倍率制造难度。
- 不把 27.5% current-greedy campaign 胜率当作真人难度证明。

## 禁止事项

- 不得改动 File Manifest 外文件。
- 不得把 pressure issues 混入旧 budget `severity/issues`，必须使用独立字段。
- 不得用平均值替代要求的 p50/p90。
- 不得让不足 64 次的 case 进入硬门。
- 不得删除或弱化旧测试、冻结矩阵或兼容字段。
- 不得引入第三方依赖。
