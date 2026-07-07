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
