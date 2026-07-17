# Delivery Batch 016 Review Evidence

## Stage 1 critical remediation

- Critical：原 AC-001 synthetic aggregate fixture 为 64 个全胜局，虽然断言文案声明 HP loss 使用全 runs、turns 仅胜局、perfect 分母为全 runs，但没有失败样本证明这些口径。
- 修复范围：仅强化 `tests/test_numerical_pressure_metrics.gd`；正式实现与玩法数值均未修改。
- 新 fixture：62 个胜局、1 个零 HP 损失失败局、1 个 `99` HP 损失且 `101` 回合的失败局；胜局 turns 为 `1..62`，与失败 turns `97/101` 明确分离。
- 精确契约：`zero_damage_win_count=40`，零损血失败不计 perfect；`perfect_win_rate=40/64`；HP loss `p50=0/p90=17` 使用全部 64 runs；`turn_sample_count=62`、turns `p50=31/p90=56` 仅使用胜局。
- Mutation evidence：临时把失败局也加入 `winning_turns`，定向测试退出 1，并精确失败 `turn percentiles exclude both failure runs` 与 `turn percentiles use nearest-rank over wins only`；立即回滚 mutation 后定向测试通过。
- 回归证据：四套数值定向测试全部通过；21 套 Godot 测试逐套退出 0，严格扫描无 `SCRIPT ERROR` / `ERROR:`，`STRICT_PASS_COUNT=21`。
- 最终实现状态：`scripts/tools/NumericalPressureMetrics.gd` 无未暂存或额外实现改动，等待 Stage 1 复审。

## Stage 2 Critical-1 remediation

- Critical：当全部 runs 都失败或 timeout 时，胜局回合样本为空；旧逻辑把默认 `turns_p50=0` 与 expected min 比较，错误追加 `encounter_too_fast`。
- RED fixture：64 个全 timeout/失败局，`turn_sample_count=0`；断言仍包含 `timeout_check` 与 `normal_too_lethal`，但绝不包含 `encounter_too_fast/slow`。原实现精确失败 duration 断言。
- 最小修复：只在 `turn_sample_count > 0` 时计算 fast/slow；timeout、lethal、too-easy 优先级和其余聚合字段不变。
- GREEN：AC-001 定向测试通过；随后 AC-001 至 AC-004 四套数值定向回归全部通过。
- 范围：未处理其他 Stage 2 finding，未修改正式玩法数值。

## Stage 2 Major-1 remediation

- Major：opening 审计只识别部分运行时条件键，导致带 `min_card_cost`、`card_type` 或 `every_n_attack_cards` 的 `combat_start` 效果可能被误计为确定性收益。
- RED：三个独立 fixture 的 contribution 非空且 exclusion reason 不是 `conditional_trigger`，共 6 条断言失败。
- 最小修复：只扩展 `_opening_effect_is_deterministic()` 的外部条件键集合，与 `CombatState._relic_condition_failed()` 对齐。
- 保留语义：`first_turn_only` 仍允许固定首回合收益；`once_per_turn/once_per_combat` 只限制次数，不作为外部条件排除。
- GREEN：Auditor 定向测试及四套数值定向回归全部通过。
- 范围：未处理 minor 或其他 finding，未修改正式玩法数值。

## Stage 2 Critical-2 remediation

- Critical：Auditor 原先先汇总遭遇基础 HP 再乘倍率；多敌 `[33,33]×1.05` 得到 `69.3`，与运行时逐敌缩放并 ceil 后求和的 `70` 不一致。
- RED：纯函数入口缺失；synthetic Auditor 双敌 fixture 也未得到 `70`。
- 最小修复：`NumericalPressureMetrics` 新增 `effective_hp_for_enemies()` 与 `safe_ratio()`；Auditor 收集每个敌人的基础 HP，委托逐敌 ceil，总层级比委托安全除法。
- 精确契约：单敌 `101×0.96→97`；双敌 `[33,33]×1.05→70`；`safe_ratio(97,104)=97/104`，零分母返回 0。
- 冻结兼容：当前第一章 Boss/elite 仍为 `96/104=0.9231`，四套数值定向回归全部通过。
- 范围：未处理其他 Stage 2 finding，未修改正式玩法数值。

## Review Round 3 · 最终裁决

### 被评审对象

- 任务：`delivery-batch-016-numerical-pressure-contract`
- diff 范围：`0b99a64..worktree staged diff`
- Stage 1：独立机械评审代理 Round 2
- Stage 2：独立强模型评审代理 Round 3

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 说明 |
| --- | --- | --- | --- |
| AC 测试覆盖 | 通过 | - | 五条 AC 均有 RED/GREEN；AC-001 以 62 胜 2 败 fixture 和 mutation 证明三类样本口径 |
| 文件清单符合 | 通过 | - | 相对 `0b99a64` 的全部改动均在 PRD File Manifest 或任务证据通配范围 |
| 禁止事项符合 | 通过 | - | 未修改正式玩法数值、CombatState、UI、存档、路线或构建版本；无新依赖 |
| 决策表符合 | 通过 | - | nearest-rank、64 样本门、胜局 turns、全局 HP loss、复合风险与兼容字段均按决策实现 |
| 挂载点接线 | 通过 | - | Simulator 聚合、Auditor opening/encounter、matrix inventory 四处均已接线 |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 说明 |
| --- | --- | --- | --- |
| 编排-计算分离 | 通过 | - | 分位数、风险、循环行动、EHP 与 ratio 位于纯计算模块；Auditor/Simulator 仅编排 |
| 结构健康度 | 通过 | - | 未继续向 2453 行 Simulator 堆纯算法；新模块职责单一 |
| 简化与复用 | 通过 | - | 复用 Godot 数组/数学函数、DataLoader、真实 CombatState 语义，无第三方依赖 |
| 正确性 | 通过 | - | 零胜局不产生 duration 风险；EHP 镜像逐敌倍率下限、ceil 与 min 1；opening 条件键与运行时对齐 |
| 兼容与确定性 | 通过 | - | 旧 case 字段和 `risk_flag` 保留；相同 options cases 完全一致；旧 budget severity 与 pressure 独立 |

### 验证证据

- 四套数值定向测试通过。
- 最终严格全量：`21/21`，逐套退出 0，无 `SCRIPT ERROR` 或 `ERROR:`。
- 256-seed opening：21 cases，平均胜率 `0.996`，`normal_too_easy=12`、`elite_too_easy=6`、`boss_too_easy=3`。
- 第一章 Boss：Ember `0.97265625`、Arc `0.9609375`、Pyre `0.99609375`，三者均复合 `encounter_too_fast`。
- 静态基线：opening warning `3`、monster pressure warning `16`、旧 monster budget warning `0`。
- `git diff --check` 与 `git diff --cached --check` 通过。

### 问题汇总

- Critical：0
- Major：0
- Minor：2
  - 未接入正式地图的候选遭遇 `feedback_crossing` 在默认 simulator 中仍输出空 `chapter_id` 与哨兵 expected turns；后续显式标记“不适用”。
  - 旧 `_risk_flag()` 已无生产调用；后续删除或标记 deprecated。

### 裁决

- [x] Stage 1 PASS。
- [x] Stage 2 PASS。
- [x] 无阻断问题，可提交并进入 Batch 017 的实际第一章数值重标定规划。

## Stage 2 Round 2 Major remediation

- Major：pure EHP helper 尚未完整镜像 `CombatState._modified_enemy_max_hp()` 的两个倍率下限和每敌最低生命。
- RED：低 multiplier fixture 与 base HP 0 fixture 精确失败。
- 最小修复：enemy multiplier 与 boss multiplier 分别使用 `max(0.1, value)`；合并后每敌使用 `max(1, ceil(int(base_hp)×combined))`。
- 精确契约：`[10],0.05,0.05→1`；`[999],0.05,0.05→10`；`[0],1,1→1`；正常 `101×0.96→97` 保持。
- GREEN：四套数值定向回归全部通过。
- 范围：未处理 minor，未修改正式玩法数值。
