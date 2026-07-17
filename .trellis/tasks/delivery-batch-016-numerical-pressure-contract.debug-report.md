# 调试报告

## Session 1

### 失败信号

- 复现命令：逐套运行 `tests/test_audio_manager.gd` 后扫描日志中的 `SCRIPT ERROR|ERROR:`。
- 原文（堆栈/断言/退出码）：

```text
ERROR: Cannot open file 'res://.godot/imported/ui_click.wav-27a1a14815f4272c438d6dd4385cee0b.sample'.
ERROR: Failed loading resource: res://assets/audio/ui_click.wav.
STRICT_SCAN_FAIL tests/test_audio_manager.gd
```

- 是否稳定复现：是；单独重跑后仍出现相同的 `.godot/imported/*.sample` 缺失。

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读栈 | `assets/audio/*.wav.import` 指向 `res://.godot/imported/*.sample`；当前隔离 worktree 完全不存在 `.godot` 目录，源 WAV 存在。 |

### 假设记录

| 轮次 | 假设（具体到变量/分支/契约） | 验证方式 | 结论(成立/证伪) |
| --- | --- | --- | --- |
| 1 | 隔离 worktree 尚未执行 Godot import，导致已跟踪 `.wav.import` 引用的本地导入缓存缺失 | 运行 Godot `--import`，确认 `.godot/imported` 生成后重跑原失败测试与严格扫描 | 成立 |

已排除项：

- 源音频缺失：`assets/audio` 下 WAV 与 `.import` sidecar 均存在。

### 修复

- 根因：隔离 worktree 从未建立被 Git 忽略的 `.godot/imported` 缓存；`.wav.import` sidecar 引用的 `.sample` 因此无法加载。
- 改动位置（一处）：仅生成被 Git 忽略的 Godot 本地导入缓存，不修改应用代码或正式数据。
- 重跑原失败命令结果：绿；`test_audio_manager.gd` 输出 `Audio manager smoke test passed.`，严格扫描无 `SCRIPT ERROR` / `ERROR:`。

### 防御性回归

- 这个 bug 能否从别处再发生：能；任何新隔离 worktree 首次严格回归前都可能缺少导入缓存。
- 若能：已在 `check.jsonl` 记录隔离 worktree 全量测试前的统一预导入步骤；应用测试无需修改。

### 退出状态

- [x] 绿了，回到 TDD 循环失败的那一步
- [ ] 已回滚，升级（附已排除项）
- [ ] 超 3 轮，升级强模型/人工

## Session 5

### 失败信号

- 复现命令：`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_tree_auditor.gd`
- 原文：

```text
ERROR: runtime relic condition is excluded from deterministic opening value: conditional_min_card_cost
ERROR: runtime relic condition is excluded from deterministic opening value: conditional_card_type
ERROR: runtime relic condition is excluded from deterministic opening value: conditional_every_n_attack_cards
```

- 是否稳定复现：是；每个条件键同时导致 contribution 与 exclusion reason 两条断言失败，共 6 项。

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读栈 | `_opening_effect_is_deterministic()` 的条件键集合少于 `CombatState._relic_condition_failed()`，缺 `min_card_cost/card_type/every_n_attack_cards`。 |

### 假设记录

| 轮次 | 假设（具体到变量/分支/契约） | 验证方式 | 结论(成立/证伪) |
| --- | --- | --- | --- |
| 1 | opening 审计条件键未与运行时 relic 条件同步 | 只补齐三个缺失键，重跑原测试 | 成立；6 项 RED 全部转绿 |

已排除项：

- `first_turn_only`：它是允许计分的固定首回合条件，不属于外部状态门。
- `once_per_turn/once_per_combat`：它们限制触发次数，不决定首次固定开场是否发生，本次不加入排除集合。

### 修复

- 根因：运行时条件键集合漂移。
- 改动位置（一处）：`NumericalTreeAuditor._opening_effect_is_deterministic()` 条件键数组。
- 重跑原失败命令结果：绿。

### 防御性回归

- 这个 bug 能否从别处再发生：能；若 CombatState 后续增加新的外部 relic 条件键，Auditor 需同步并补 fixture。
- 当前三键均有逐键 RED/GREEN 保护；本次不处理其他 finding。

### 退出状态

- [x] 绿了，回到 Stage 2 复审
- [ ] 已回滚，升级（附已排除项）
- [ ] 超 3 轮，升级强模型/人工

## Session 4

### 失败信号

- 复现命令：定向运行 `test_numerical_pressure_metrics.gd` 与 `test_numerical_tree_auditor.gd`。
- 原文：

```text
Parse Error: Static function "effective_hp_for_enemies()" not found in base "NumericalPressureMetrics".
Parse Error: Static function "safe_ratio()" not found in base "NumericalPressureMetrics".
ERROR: auditor delegates multi-enemy effective HP to per-enemy ceiling semantics
```

- 是否稳定复现：是。

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读栈 | Auditor 在 `_audit_encounter()` 中先汇总基础 HP 再乘倍率，双敌 `[33,33]×1.05` 得到 `69.3`，不符合运行时逐敌 ceil 后求和的 `70`。 |

### 假设记录

| 轮次 | 假设（具体到变量/分支/契约） | 验证方式 | 结论(成立/证伪) |
| --- | --- | --- | --- |
| 1 | EHP 和层级比缺少共享纯函数，Auditor 的总和后乘法会低估多敌遭遇 | 新增纯 fixture 与 synthetic 双敌 Auditor fixture，再委托纯函数 | 成立；两套定向转绿 |

已排除项：

- 当前第一章冻结值变化：Boss `100×0.96` 仍为 `96`，最高单体精英仍为 `104`，比例仍为 `0.9231`。

### 修复

- 根因：EHP 计算顺序与运行时逐敌生命缩放语义不一致。
- 改动位置：`NumericalPressureMetrics.effective_hp_for_enemies()` / `safe_ratio()`；Auditor 只收集基础 HP 并委托。
- 重跑原失败命令结果：绿。

### 防御性回归

- 这个 bug 能否从别处再发生：不能；纯函数与 Auditor synthetic fixture 同时锁定单敌、多敌和零分母。

### 退出状态

- [x] 绿了，回到 Stage 2 复审
- [ ] 已回滚，升级（附已排除项）
- [ ] 超 3 轮，升级强模型/人工

## Session 3

### 失败信号

- 复现命令：`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_pressure_metrics.gd`
- 原文：

```text
ERROR: Numerical pressure metrics test failed with 1 issue(s).
ERROR:  - duration risks require at least one winning-turn sample
```

- 是否稳定复现：是；64 个全 timeout/失败局、`turn_sample_count=0` 时稳定产生伪 `encounter_too_fast`。

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读栈 | `NumericalPressureMetrics.risk_flags()` 无条件用空胜局样本产生的 `turns_p50=0` 比较 expected min，误判过快。 |

### 假设记录

| 轮次 | 假设（具体到变量/分支/契约） | 验证方式 | 结论(成立/证伪) |
| --- | --- | --- | --- |
| 1 | 快慢风险缺少 `turn_sample_count>0` 可用性门 | 只在该条件内执行 fast/slow 判断，重跑原测试 | 成立；原测试转绿 |

已排除项：

- timeout/lethal 优先级错误：新 fixture 中两者均正确保留，只有 duration 风险为伪阳性。

### 修复

- 根因：空 winning-turn sample 的默认 p50/p90 为 0，却被当成有效持续时间。
- 改动位置（一处）：`scripts/tools/NumericalPressureMetrics.gd` 的 fast/slow 风险分支增加 `turn_sample_count > 0` 门。
- 重跑原失败命令结果：绿。

### 防御性回归

- 这个 bug 能否从别处再发生：不能；所有调用方统一经过纯函数的样本可用性门。

### 退出状态

- [x] 绿了，回到 Stage 2 复审
- [ ] 已回滚，升级（附已排除项）
- [ ] 超 3 轮，升级强模型/人工

## Session 2

### 失败信号

- 复现命令：`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_pressure_metrics.gd`
- 原文（Stage 1 要求的临时错误 mutation）：

```text
ERROR: Numerical pressure metrics test failed with 2 issue(s).
ERROR:  - turn percentiles exclude both failure runs
ERROR:  - turn percentiles use nearest-rank over wins only
```

- 是否稳定复现：是；仅在把失败局错误加入 `winning_turns` 时稳定失败。

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 单点 mutation | `NumericalPressureMetrics.aggregate_runs()` 中 `winning_turns.append(turns)` 的胜局条件决定 turn_sample_count 与 turns p50/p90 口径。 |

### 假设记录

| 轮次 | 假设（具体到变量/分支/契约） | 验证方式 | 结论(成立/证伪) |
| --- | --- | --- | --- |
| 1 | 新 fixture 能识别失败局误入胜局回合样本 | 临时把 `winning_turns.append(turns)` 移到 `if won` 外，运行定向测试 | 成立；精确两条断言 RED |

已排除项：

- 旧全胜 fixture 的假阳性：已替换为 62 胜、1 个零损血失败、1 个 99 HP 损失/101 回合失败。

### 修复

- 根因：Stage 1 发现旧 fixture 没有失败局，无法证明样本分母分流正确。
- 改动位置（一处）：只强化 `tests/test_numerical_pressure_metrics.gd` fixture 与精确断言。
- 重跑原失败命令结果：临时 mutation 下 RED；立即回滚 mutation 后 GREEN。`NumericalPressureMetrics.gd` 最终无实现 diff。

### 防御性回归

- 这个 bug 能否从别处再发生：不能；同一 aggregate fixture 同时锁定 perfect、HP-loss 和 winning-turns 三种分母。

### 退出状态

- [x] 绿了，回到 Stage 1 复审
- [ ] 已回滚，升级（附已排除项）
- [ ] 超 3 轮，升级强模型/人工

## Session 6

### 失败信号

- 复现命令：`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_pressure_metrics.gd`
- 原文：

```text
ERROR: enemy and boss HP multipliers each have the runtime 0.1 floor
ERROR: each enemy effective HP has the runtime minimum of one
```

- 是否稳定复现：是。

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读栈 | 纯 helper 使用 multiplier 下限 0.0 且没有每敌 `max(1, ...)`，与 `CombatState._modified_enemy_max_hp()` 不一致。 |

### 假设记录

| 轮次 | 假设（具体到变量/分支/契约） | 验证方式 | 结论(成立/证伪) |
| --- | --- | --- | --- |
| 1 | helper 缺两个独立 0.1 multiplier floor 与最终 1HP floor | 增加边界 fixture后只修改 helper，重跑原测试 | 成立；转绿 |

已排除项：

- 正常倍率回归：既有 `101×0.96→97` 与双敌逐敌 ceil fixture 继续通过。

### 修复

- 根因：pure EHP 只镜像了逐敌 ceil，没有完整镜像运行时倍率/生命下限。
- 改动位置（一处）：`NumericalPressureMetrics.effective_hp_for_enemies()`。
- 重跑原失败命令结果：绿。

### 防御性回归

- 这个 bug 能否从别处再发生：不能；pure helper 是 Auditor 唯一 EHP 入口，低倍率、零HP与正常倍率均有 fixture。

### 退出状态

- [x] 绿了，回到 Stage 2 Round 2 复审
- [ ] 已回滚，升级（附已排除项）
- [ ] 超 3 轮，升级强模型/人工
