# 调试报告

## Session 1

### 失败信号

- 复现命令：`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_simulator.gd`
- 原文：`Test failed: elite prediction uses the campaign max-turn horizon`，退出码 1，稳定复现。

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读栈 | `tests/test_balance_simulator.gd:220` 断言 outcome `turns <= 1`；`BalanceSimulator.gd:900-941` 在第 1 回合结束后 `end_player_turn()` 将计数推进到 2，下一轮入口以 `turn > max_turns` 标记 timeout。 |

### 假设记录

| 轮次 | 假设 | 验证方式 | 结论 |
| --- | --- | --- | --- |
| 1 | 实现已传入 `max_turns=1`，失败来自测试把“最多执行 1 回合”误解为返回计数必须不超过 1 | 读取真实 loop 与 `CombatState.end_player_turn()` 计数契约 | 成立；返回 `turns=2` 代表第 1 回合结束后在第 2 回合入口超时，没有执行第 2 回合动作 |

### 修复

- 根因：测试断言与既有 timeout/turn 计数语义不一致。
- 改动位置（一处）：`tests/test_balance_simulator.gd`，改为断言每个 outcome 为 timeout 且 `turns == 2`。
- 重跑原失败命令结果：绿，`Balance simulator smoke test passed.`。

### 防御性回归

- 这个 bug 能否从别处再发生：不能；断言直接复用现有 combat timeout 语义，未修改生产循环。

### 退出状态

- [x] 绿了，回到 TDD 循环失败的那一步
- [ ] 已回滚，升级
- [ ] 超 3 轮，升级强模型/人工

## Session 2

### 失败信号

- 复现命令：四项 Godot 自检在默认 HOME 下串行执行。
- 原文：`Failed to open 'user://logs/godot2026-07-20T11.16.06.log'`，随后 Godot 以 signal 11 崩溃，退出码 1；发生在测试脚本载入前。

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读栈 | 首个错误明确指向默认 `user://logs`，没有 GDScript 断言或解析栈。 |
| 最小探针 | 仅把 HOME 改为 `/tmp/ember021_review_home` 后重跑同一 `test_balance_simulator.gd`，立即通过。 |

### 假设记录

| 轮次 | 假设 | 验证方式 | 结论 |
| --- | --- | --- | --- |
| 1 | 默认 Godot 用户目录存在日志文件冲突/损坏，崩溃与本次代码无关 | 使用隔离 HOME 重跑原测试，再在同一隔离 HOME 跑完整四项自检 | 成立；全部退出码 0 |

### 修复

- 根因：共享默认 Godot 用户目录的日志写入冲突，不是生产代码或测试断言失败。
- 改动位置：不改代码；自检命令使用隔离 `HOME=/tmp/ember021_review_home`。
- 重跑结果：editor import、`test_balance_simulator.gd`、`test_combat_core.gd`、`test_numerical_balance_matrix.gd` 全绿。

### 防御性回归

- 这个 bug 能否从别处再发生：能；并发/历史 Godot 进程共用默认用户目录时可能复现。后续自动验证继续使用任务级隔离 HOME。

### 退出状态

- [x] 绿了，回到 TDD 收尾自检
- [ ] 已回滚，升级
- [ ] 超 3 轮，升级强模型/人工

## Session 3

### 失败信号

- 复现命令：`HOME=/tmp/ember021_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_simulator.gd`
- 原文：新增 `card_played -> bonus_damage` thorn fixture 在实现修复后仍选择不到预期的“安全攻击”，测试退出码 1，稳定复现。

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读失败断言与 fixture | `tests/test_balance_simulator.gd` 中危险候选与所谓安全候选均为 attack；两者都满足 fixture `offense_forging` 的 `card_type=attack` 条件。 |
| 对照真实触发契约 | 安全攻击同样产生一次额外 bonus damage，并因此承受第二次 thorn；实现拒绝它符合真实 `CombatState` 顺序。 |

### 假设记录

| 轮次 | 假设 | 验证方式 | 结论 |
| --- | --- | --- | --- |
| 1 | 生产实现已经正确计入 bonus damage，失败来自 fixture 把同样会触发成长来源的 attack 错标为安全 | 对照 relic `card_type=attack` 条件与两个候选的 card type | 成立；两个攻击都会触发 `offense_forging` |

### 修复

- 根因：测试候选设计错误，所谓安全攻击并不安全。
- 改动位置（一处）：`tests/test_balance_simulator.gd`，把安全候选改为不触发 attack 成长来源的 draw skill。
- 重跑原失败命令结果：绿，`Balance simulator smoke test passed.`；随后四项隔离 HOME 自检全绿。

### 防御性回归

- 这个 bug 能否从别处再发生：不能；fixture 现在显式分离“触发 bonus damage 的 attack”与“不触发该来源的 skill”，已局部封闭。

### 退出状态

- [x] 绿了，回到 Round 4 repair 回归步骤
- [ ] 已回滚，升级
- [ ] 超 3 轮，升级强模型/人工

## Session 4

### 失败信号

- 复现命令：`HOME=/tmp/ember021_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_simulator.gd`
- 原文：Round 7 新增 damage→block fixture 的两个 CombatState 生存对照断言与四个预期 RED 断言同时失败。

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读 fixture 与真实 enemy turn | `_combat_choice_fixture` 只设置 `current_action.intent`，真实 `resolve_prepared_enemy_turn()` 读取 `current_action.effects`；对照 fixture 实际没有造成伤害。 |
| 一次只改 fixture | 仅给两个 CombatState 对照实例补同一条 10 damage effect；不改 simulator。 |

### 假设记录

| 轮次 | 假设 | 验证方式 | 结论 |
| --- | --- | --- | --- |
| 1 | 额外失败来自测试没有为真实敌方回合提供 effects，而非生产 CombatState 或待修 shadow 行为 | 补 effects 后重跑同一命令 | 成立；CombatState 两条对照转绿，只剩三个 Round 7 实现缺口对应的四条 RED |

### 修复

- 根因：fixture 把 scorer 使用的 intent 摘要误当成真实敌方结算 effects。
- 改动位置：`tests/test_balance_simulator.gd` 两个对照实例，各补同一条敌方 damage effect。
- 重跑原失败命令结果：预期的四条 simulator RED 稳定保留；完成实现后目标测试与完整回归全绿。

### 防御性回归

- 这个 bug 能否从别处再发生：能；凡是调用 `end_player_turn()` 的对照 fixture 都必须显式提供 `current_action.effects`。本 fixture 现已把 intent 与真实 effects 同时写明。

### 退出状态

- [x] 绿了，回到 Round 7 repair 的实现步骤
- [ ] 已回滚，升级
- [ ] 超 3 轮，升级强模型/人工

## Session 5

### 失败信号

- 复现命令：`/usr/bin/time -p env HOME=/tmp/ember021_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tools/run_balance_simulation.gd -- --mode=campaign --iterations=1 --max-turns=80 --strategy-profile=competent-player-v2 --output=/tmp/ember021-v2-performance-smoke-round20.json`
- 首次观察：Round 19 记录 `real 0.69s`，Round 20 全默认范围观察为 `real 2.49s`；退出码均为 0。

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读报告 | `/tmp/ember021-v2-performance-smoke-round19.json` 的 `case_count=1`，本次全默认命令的 `case_count=12`，原始性能比较不成立。 |
| 单一假设验证 | 用完全相同的 `--characters=ember_exile --challenges=0` 范围重跑 Round 20，得到 `real 0.55s`；同时检查 immediate lethal 新分支，确认初版会对同一牌重复做完整 shadow resolution。 |

### 修复

- 根因一（比较误差）：性能基准 case 范围不一致，已局部封闭，后续 smoke 固定角色/挑战范围。
- 根因二（可收敛的重复工作）：`_competent_immediate_lethal_decision` 原本依次调用 HP、lethal、survival 三条入口，重复解析同一张牌；将已有 resolution 传入 survival summary，保留行为并减少重复递归。
- 重跑原失败命令结果：目标测试通过；同范围 smoke `real 0.55s`。

### 防御性回归

- 这个 bug 能否从别处再发生：性能比较可因扩大 case 范围再次误读；文档现固定单格命令和输出路径。重复 shadow 只能从新增旁路产生，当前 immediate lethal 已复用 resolution，局部封闭。

### 退出状态

- [x] 绿了，回到收尾自检
- [ ] 已回滚，升级
- [ ] 超 3 轮，升级强模型/人工
