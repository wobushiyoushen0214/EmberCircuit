# 调试报告：第一章与开局重标定

## Session 1：候选被旧回合目标误报过慢

### 失败信号

- 复现命令：64-seed single suite，3 角色×7 遭遇。
- 稳定结果：19/21 flagged；其中普通战 p50 为 6–9、p90 为 7–11，精英 p50 为 8–13、p90 为 9–13，却仍使用削弱 opening 之前的 normal `[3,6]`、elite `[5,8]`。

### 定位与假设

- 读栈定位到 `NumericalPressureMetrics._risk_flags()`：p50 超过 max 或 p90 超过 max+半区间即 `encounter_too_slow`。
- 假设：`encounter_too_slow` 是第一章 expected-turn 目标过期，而不是候选战斗真的拖成木桩。
- 验证：实际回合分布稳定落在 normal 6–11、elite 8–13，且完美胜率均为 0；静态攻击密度与空窗已通过。

### 最小修复

- 只更新第一章 normal expected turns 为 `[5,9]`，elite 为 `[7,13]`；Boss 保持 `[8,12]`。
- 同步 `monster_scaling.json` 与 `numerical_tree.json`，不改胜率/完美率 pressure threshold。

### 防御性回归

- 该问题可在下次 opening 大幅变化时重现；`test_balance_simulator.gd` 的 64-seed gate 会继续保护实际回合分布。

## Session 2：高损血胜局被误报过易

### 失败信号

- normal 多个 case 胜率 100%，但 p50 损血为 9–41；elite 的 Ember executor 胜率 100%，p50 损血 52。
- schema v1 只要 `win_rate>max` 或 `perfect_win_rate>max` 就判过易，忽略肉鸽跨战斗的生命消耗。

### 根因与最小修复

- 根因：`NumericalPressureMetrics._risk_flags()` 的过易契约没有 attrition 维度。
- schema 升为 2；各 tier 增加 `hp_loss_p50_min=8/20/30`。
- `too_easy` 现在要求完美率越界，或“胜率越界且 p50 损血低于下限”；不改胜率上下限。

### 防御性回归

- synthetic perfect-win 测试继续保证真正无伤碾压会报 too-easy；Batch 017 64/256 报告保证高损血胜局不会误报。

## Session 3：角色专属致死点

### 失败信号

- schema v2 后只剩 3 个 flagged case：Arc Boss 6.25%，Pyre 两精英 35.94%/23.44%。

### 假设与验证

- Pyre 假设：把防御从免费 `ash_rosary` 移到 4 张主动 `scar_guard`，能改善长战且保留 opening 上限。验证 `scar_guard 7/10 + ash_rosary 1` 后两精英为 68.75%/53.13%，无风险；deck/opening 为 76.21/79.73。
- Arc 假设 A：用 `ash_guard` 替换 `forge_focus`。验证后 Boss 仅 12.5% 且战斗更慢，证伪并回滚。
- Arc 假设 B：单张消耗的 `static_primer` 保持 0 费，避免低质量起手额外损失一整点能量。验证后 Boss 34.38%，无风险；opening 仍为 76.83。

### 最小修复

- Pyre 保留主动 7/10 护甲，把免费念珠降至 1。
- Arc 保留单张 0 费消耗预充；用 64-seed 实测上沿 `cards_played_per_turn≤5.3` 防止行动数失控，不强迫高节奏角色同质化到 4.3。
- Arc 用第二张 `ash_guard` 替换纯资源 `forge_focus`，Boss 64-seed 胜率从 6.25% 提升到可接受区间；starter/opening 为 65.97/75.77。
- normal p50 损血下限按角色最大生命约 10% 取 7。按冻结阶梯把灰烬猎犬 +2/+4 HP 都未改变 p50=7，已回滚无效增量；7 点损血本身已是可累计的路线成本。
- 256-seed Arc intro 的 p50/p90 为 6/12，完美率 17.6%；单独提高煤烟盗兵两个伤害值没有单调改善 p50，已回滚。schema v2 因此同时要求 p50 与 p90 都低于 `7/10` 才算低消耗，避免只看中位数忽略明显长尾。

## Session 4：成长系统旧断言未同步 Spark Throw 重标定

### 失败信号

- 复现命令：`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_progression_systems.gd`
- 稳定结果：退出码 1；`tests/test_progression_systems.gd:122` 仍期待 `spark_throw 4 + offense_forging 2 = 6`，实际正式卡牌已重标定为 `3 + 2 = 5`。

### 定位与假设

- 读栈直接定位到唯一失败断言。
- 假设：成长效果逻辑正确，失败来自测试继续使用 Batch 017 前的基础伤害常量。
- 验证：`data/cards/cards.json` 与 `test_act1_rebaseline.gd` 均精确锁定 `spark_throw=3/5`；失败实际值为 5，且只差旧基础伤害的一点。

### 最小修复

- 正式扩展 File Manifest 纳入 `tests/test_progression_systems.gd`。
- 只把该断言的总伤害从 6 同步为 5，并把说明改为明确引用重标定后的 3 点基础伤害。
- 原失败命令重跑退出码 0：`Progression systems smoke test passed.`

### 防御性回归

- 这个问题可在以后修改基础卡伤害但遗漏跨系统测试时再次发生；`check.jsonl` 纳入 `tests/test_progression_systems.gd`，全量 strict suite 继续保护成长修正与基础卡牌的组合值。

## Session 5：Boss 三效果行动的易伤未进入意图预告

### 失败信号

- Stage 2 评审定位 `forge_bishop/final_rite/ashen_edict`：真实 effects 同时包含 6 点伤害、1 层易伤和 1 张灼伤牌，但 `attack_status_card` intent 只声明并显示伤害与状态牌。
- RED 命令：`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_act1_rebaseline.gd`
- 稳定结果：退出码 1，真实 Boss fixture 的 intent 字段、详细预告和 compact 预告三项同时失败。

### 定位与假设

- 读栈与真实 action 数据直接定位到 `data/enemies/enemies.json` 的 `ashen_edict` 以及 `Main._intent_text/_intent_compact_text`。
- 假设：战斗结算正确，缺陷仅是 intent schema 实例未声明可选状态，显示 helper 也未组合第三种效果。
- 验证：effects 已有 `apply_status vulnerable=1`，CombatState 无需修改；手工双效果 fixture 均正常。

### 最小修复

- `ashen_edict.intent` 增加 `status=vulnerable/status_amount=1`。
- `attack_status_card` 详细预告在可选 status 存在时同时显示伤害、状态和状态牌；compact 预告显示 `6+易1+伤1`。
- 原失败测试重跑退出码 0；未新增 intent 类型、依赖或战斗结算分支。

### 防御性回归

- 这个问题可在以后新增三效果 action 时再次发生；`test_act1_rebaseline.gd` 直接读取真实 Boss action，保证 intent 与真实三效果不再漂移。
