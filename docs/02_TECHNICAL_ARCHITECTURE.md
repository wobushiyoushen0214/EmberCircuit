# 技术架构

## 1. 核心原则

项目采用数据与表现分离。

- `CombatState` 是战斗唯一数据源。
- `EffectResolver` 负责卡牌、敌人和遗物效果结算。
- UI 只读取状态并发送请求，不直接修改生命、手牌、敌人或奖励。
- 所有数值优先放在 `data/`，脚本只实现规则解释器。

## 2. 目录职责

```text
scenes/      Godot 场景文件
scripts/     GDScript 逻辑
data/        卡牌、敌人、遗物、遭遇和配置
docs/        设计、计划、数据规范和资产管线
assets/      美术、音频、字体和特效资源
tests/       自动化验证脚本
```

## 3. 关键脚本

- `scripts/core/DataLoader.gd`：读取 JSON 数据。
- `scripts/core/GameState.gd`：跨战斗存档和运行状态。
- `scripts/combat/CombatState.gd`：战斗状态机。
- `scripts/main/Main.gd`：当前 MVP 的主界面和战斗展示。

## 4. 数据格式

JSON 文件允许 `_comment`、`notes`、`balance_note`、`design_note` 字段。这些字段用于人类阅读，不参与规则结算。

## 5. 事件流

战斗中统一使用事件概念驱动遗物和状态：

- `combat_start`
- `turn_start`
- `card_played`
- `damage_dealt`
- `block_gained`
- `enemy_block_broken`
- `enemy_died`
- `combat_won`

## 6. 测试策略

优先验证纯数据层：

- 抽牌、洗牌、弃牌。
- 能量消耗。
- 伤害和护甲。
- 状态叠加和递减。
- 敌人意图与实际行动一致。
- 遗物触发次数。

表现层测试放在第二优先级，主要检查按钮、文本和流程切换。

## 7. 真人试玩遥测

真人试玩数据与 profile、跑团存档、启发式 AI 模拟报告分离：

- `scripts/core/PlaytestTelemetry.gd` 是纯数据层，负责 schema 归一化、逐局事件、聚合和报告生成，不依赖 UI 节点。
- `scripts/core/SaveManager.gd` 只负责读写 `user://ember_circuit_playtest_telemetry.json` 和导出 `user://ember_circuit_playtest_report.json`。
- `scripts/main/Main.gd` 将真实操作路径映射到遥测 API，并把当前活动局快照嵌入普通跑团存档。
- `data/config/numerical_tree.json.human_playtest_targets` 保存真人样本门槛，不与 AI 的 `campaign_matrix` 混用。

每局以匿名随机 `run_id`、版本、Godot 版本和游戏配置 SHA-256 指纹开始。指纹按稳定顺序读取卡牌、角色、挑战、地图、经济、怪物、遭遇、事件、药水、遗物和状态配置，用于阻止不同数值版本的样本被误合并。

运行时记录角色、挑战、显示尺寸/缩放、系统平台、区域设置、路线节点、遭遇结果、回合数、节点前后生命/金币/牌组规模、卡牌展示/获取/删除/升级/打出、遗物与药水获取、药水使用、奖励跳过、事件选择和存档加载次数。它不记录用户名、主目录、硬件序列号或网络标识，也不会自动联网发送。当前不提供伤害来源、总伤害、总格挡、总治疗或逐动作耗时事件流，分析时不得从净生命变化伪造这些指标。

落盘策略避开高频动画路径：出牌只更新内存；回合结束、节点开始/完成、奖励选择、商店/事件结算、手动保存、读取和胜负终局才建立检查点。历史最多保留最近 64 局；胜率分母只包含 `victory + defeat`，`abandoned` 和活动局单列。读取另一份存档会把被替换的活动局记为放弃，恢复局的 `loads` 加一；若恢复的是先前被标记放弃的同一局，会撤销旧放弃行，避免重复计数。
