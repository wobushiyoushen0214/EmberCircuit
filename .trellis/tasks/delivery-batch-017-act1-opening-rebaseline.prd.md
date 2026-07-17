# Delivery Batch 017: 第一章与开局重标定

## 需求 ID

- REQ-003
- REQ-004
- REQ-005
- REQ-009
- REQ-012

## 目标

在 Batch 016 pressure 契约基础上重标定三角色起始包、起始经济、篝火恢复与第一章敌人，并把已被真实 attrition 证据证伪的过易分类升级为 schema v2，使开局不再以免费稳定性消除取舍，同时保证敌人复合行动被完整预告。

## 交付 Loop 控制

- 交付批次：`delivery-batch-017-act1-opening-rebaseline`
- Loop 模式：L3；审计范围：delta；复杂度：高。
- worktree：`/Users/lizhiwei/localProj/.worktrees/EmberCircuit-batch017`
- 分支：`codex/batch-017-act1-opening-rebaseline`
- verifier：必须；实现技能：`trellis-implement-tdd-zh`；调试技能：`trellis-debug-systematic-zh`；评审技能：`trellis-review-twostage-zh`。
- 人工门：已通过；用户两次确认正式数值重标定继续执行。
- 最大修复尝试 2；最大调试假设 3。
- 回滚触发：File Manifest 越界、严格回归失败、隐藏复合意图、手改 observed matrix、弱化 pressure thresholds、破坏存档/路线/后章行为。

## 决策表

| 决策点 | 选定方案 | 原因 |
| --- | --- | --- |
| 数值树版本 | `version=4`，`pressure_contract.schema_version=2` | 正式基线变化；真实候选证明过易判定必须计入累计损血 |
| single 默认 modifier | 复用 `_campaign_modifier_sources({"skill_book_id":"steel_manual"})` | 与真实游戏/campaign 一致，不复制结算逻辑 |
| single profile | `loadout_profile=starter_deck_relics_default_skill_book`，并输出 `skill_book_id=steel_manual` | 明确证据口径 |
| 复合意图 | `attack_block`、`attack_buff`、`attack_status_card` | 不允许次要效果暗结算 |
| 恢复取整 | 保留 `ceil(max_hp*25/100)` | 69/70 HP 都恢复 18 |
| 商店经济 | 只改起始金币，不改价格和奖励 | 隔离变量 |
| 模拟策略 | 保留 `current-greedy` | 只作 paired regression，不冒充真人胜率 |
| 调整纪律 | 候选先完整落地；若 64-seed 失败，只能按 PRD 的冻结阶梯一次改一个值并重跑 | 防止阈值迁就结果 |

## 冻结数值

### 起始包

| 角色 | 修改 | 金币 | deck score | opening package |
| --- | --- | ---: | ---: | ---: |
| Ember | `ember_strike 7/9→6/8`；`ember_bottle 6→3`；`cracked_charm` 改为首次实际损血后每战抽1 | 55 | 73.86 | 79.14 |
| Arc | `spark_throw 4/6→3/5`；`forge_focus→ash_guard`；保留单张 `static_primer cost 0/0` 且消耗；`insulated_battery 5→2` | 52 | 65.97 | 75.77 |
| Pyre | 起始牌改 2×`penitent_cut`+2×`ember_strike`；`penitent_cut 7/9→6/8`；保留 `scar_guard 7/10`；`ash_rosary 7→1` | 50 | 76.21 | 79.73 |

`cracked_charm.effects[0]` 精确为 `{trigger:"player_hp_lost",type:"draw",amount:1,min_hp_lost:1,once_per_combat:true}`。Arc 保留角色初始势能 1 与 `arc_capacitor` 开场势能 1。Pyre 的 `penitent_censer` 继续仅作为条件 contribution exclusion。

### 经济

- `campfire.heal_percent_of_max_hp=25`。
- `players.starting_gold_range=[50,55]`。
- 不改商店价格、战斗金币、掉落与删牌价格。

### 第一章敌人

| 敌人 | HP | 行动循环 |
| --- | ---: | --- |
| soot_raider | 34 | 8伤；5伤+6甲；12伤 |
| ash_hound | 28 | 5×2；弱1；11伤 |
| plague_alchemist | 40 | 7伤+易伤；5伤+伤口牌；7甲 |
| bomb_mite | 24 | 力量2；15伤 |
| iron_shell_guard | 40 | 6伤+8甲；12伤；12甲 |
| thorn_shield | 34 | 6甲+尖刺1；10伤 |
| ember_wraith | 34 | 6伤+灼烧3；12伤；8甲 |
| twinblade_executor | 86 | 8×2；10伤+易伤；22伤 |
| furnace_colossus | 96 | 8伤+12甲；18伤；12伤+灼烧4 |
| forge_bishop | 116 | 基础：6伤+力量、5×3、6伤+伤口、10甲、22伤；P1：4×4、6伤+伤口、11甲+力量、22伤；P2：5×4、6伤+易伤+伤口、12甲+力量、24伤 |

同步 chapter-one 上限：normal max damage 15，elite max damage 22，boss HP max 116、max damage 24。

静态 7 遭遇顺序 `intro/polluted/iron/cinder/executor/furnace/boss`：HP/峰值 `62/23,64/22,74/22,62/23,86/22,96/18,116/24`；攻击比 `.833,.6,.6,.667,1,1,.8`；最长零伤空窗 ≤1；前三伤害 `46,27,28,39,48,38,27`；Boss/elite C0 EHP `112/96=1.1667`。

## File Manifest

修改：

- `data/cards/cards.json`
- `data/config/player.json`
- `data/relics/relics.json`
- `data/enemies/enemies.json`
- `data/config/economy.json`
- `data/config/numerical_tree.json`
- `data/config/monster_scaling.json`
- `scripts/tools/BalanceSimulator.gd`
- `scripts/tools/NumericalPressureMetrics.gd`
- `scripts/main/Main.gd`
- `tests/test_balance_simulator.gd`
- `tests/test_combat_core.gd`
- `tests/test_data_integrity.gd`
- `tests/test_numerical_pressure_metrics.gd`
- `tests/test_numerical_tree_auditor.gd`
- `tests/test_numerical_balance_matrix.gd`
- `tests/test_progression_systems.gd`
- `tests/test_run_flow.gd`
- `docs/03_CONTENT_AND_BALANCE.md`
- `docs/06_IMPLEMENTATION_LOG.md`
- `docs/09_NUMERICAL_TREE_AND_BALANCE.md`
- `.trellis/delivery-state.md`
- `.trellis/delivery-run-log.jsonl`
- `.trellis/tasks/delivery-batch-017-act1-opening-rebaseline.*`

新建：

- `tests/test_act1_rebaseline.gd`
- `tests/test_act1_rebaseline.gd.uid`

## 挂载点

| 挂载点 | 接线动作 |
| --- | --- |
| 起始配置 | legacy Ember 与 `characters.ember_exile` 同步；三角色金币/牌组/遗物读取真实 JSON |
| default skill book | `_run_single_combat()` 传入 campaign 同源 modifier sources |
| 复合意图 | Main 的图标、颜色、文字、badge、投射与 Simulator 攻击识别全部登记三种类型 |
| 静态审计 | numerical tree inventory、角色 targets、monster scaling 与 warning IDs 同步 |
| paired evidence | 64/256 single 与 3×4×256 campaign 用工具生成，不手写 observed 字段 |

## 验收标准

- `AC-001`：新测试精确锁定三角色牌组、卡牌、遗物、金币、deck/opening 分数 `73.86/65.97/76.21` 与 `79.14/75.77/79.73`；三者落入目标区间且 opening warning 清零。
- `AC-002`：`_run_single_combat()` 注入默认 `steel_manual`；single 输出新 loadout profile 与 `skill_book_id=steel_manual`；同 seed 确定性不变，默认开场 3 护甲与 campaign/真实游戏一致。
- `AC-003`：25% 篝火在 69/70 最大生命时都恢复 18；三角色起始金币精确为 55/52/50；商店和战斗奖励经济快照不变。
- `AC-004`：三种复合意图在战斗 UI 中同时显示伤害与次要效果，并被 Simulator 计作攻击；不得隐藏格挡、强化或状态牌。
- `AC-005`：七个第一章遭遇精确命中冻结静态指标；攻击比、空窗、前三伤害和 `112/96=1.1667` 全部通过，旧 budget severity/issues 语义不变。
- `AC-006`：64 paired seeds 的 21 个 case 均 `pressure_gate_eligible=true`；schema v2 的 `too_easy` 同时使用胜率、完美率和 p50/p90 损血，不得把高损血胜局误报过易；不得含 `*_too_lethal`、`encounter_too_fast`、`encounter_too_slow`；Arc cards/turn 作为角色节奏诊断，不作为跨角色同质化硬门。
- `AC-007`：最终 256 paired seeds 保持 AC-006；重新生成 `3×4×256` campaign matrix，保留 `strategy_profile=current-greedy`；22/22 Godot 测试逐套退出 0 且日志无 `SCRIPT ERROR`/`ERROR:`；文档与 Trellis 证据同步。

## 冻结逐值调整阶梯

只有 AC-006 的 64-seed 报告失败时才启用；每次只执行一行并完整重跑 21 case，命中目标即停止：

1. normal `too_easy/too_fast`：对应遭遇总 HP 最低的敌人 +2，单敌累计最多 +4；同步 scaling 上限。
2. elite `too_easy/too_fast`：对应精英 HP +4，累计最多 +8；同步 scaling 上限。
3. boss `too_easy/too_fast`：Boss HP +4，累计最多 +8；同步 scaling 上限与 EHP 测试。
4. 任一 `too_lethal`：仅把该遭遇峰值最高的直接伤害 -1；累计最多 -2。
5. `too_slow`：仅回退该遭遇最后一次 HP 增量；不得调高玩家免费资源。

禁止调整 pressure threshold、挑战倍率、全局敌人倍率、起始生命、商店价格或后章数值来凑绿。

## 自检命令

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_act1_rebaseline.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_simulator.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_combat_core.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_data_integrity.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_tree_auditor.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_balance_matrix.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_run_flow.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tools/run_balance_simulation.gd -- --iterations=256 --max-turns=30 --characters=ember_exile,arc_tinker,pyre_ascetic --challenges=0 --encounters=intro_patrol,polluted_lab,iron_checkpoint,cinder_kennels,executor_elite,furnace_colossus_elite,chapter_one_boss --output=/tmp/embercircuit-act1-candidate-256.json
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tools/run_balance_simulation.gd -- --mode=campaign --iterations=256 --max-turns=80 --characters=ember_exile,arc_tinker,pyre_ascetic --challenges=0,1,2,3 --output=/tmp/embercircuit-campaign-rebaseline.json
```

严格全量：逐个运行 `tests/test_*.gd`，任一非零退出或日志匹配 `SCRIPT ERROR|ERROR:` 即失败；预期 `STRICT_PASS_COUNT=22`。

## 范围外与禁止事项

- 不改 CombatState、存档、地图、挑战、路线、商店、后章数据、完整页面 UI、美术、音频或构建版本。
- 不引入第三方依赖；不手改 campaign observed rates；不删除或弱化旧测试。
- 不把 current-greedy campaign 低胜率当作真人难度结论。
- 实现者不得 commit/push/merge，不得自行标记完成；双阶段评审通过后由主会话处理。
