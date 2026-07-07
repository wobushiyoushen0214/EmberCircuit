# 实现日志

## 2026-07-07

已完成：

- 创建 Godot 项目 `EmberCircuit`。
- 写入完整设计文档、技术架构、内容平衡、美术音频管线和逐步路线图。
- 建立带注释的数据文件：
  - 30 张左右原创卡牌。
  - 8 个普通敌人。
  - 2 个精英敌人。
  - 1 个 Boss。
  - 10 个遗物。
  - 5 个遭遇配置。
- 实现第一版数据驱动战斗核心：
  - 抽牌、弃牌、消耗。
  - 能量、护甲、生命、势能。
  - 敌人意图和敌人行动。
  - 伤害、格挡、易伤、虚弱、灼烧、力量。
  - 部分遗物触发。
- 实现极简可运行 UI：
  - 玩家资源。
  - 敌人生命、护甲、状态、意图。
  - 手牌按钮。
  - 战斗日志。
  - 结束回合和重开。
- 实现连续遭遇和战斗胜利三选一卡牌奖励。
- 实现精英和 Boss 后的遗物奖励。
- 实现线性章节路线节点：
  - 普通战斗。
  - 问号事件。
  - 商店。
  - 篝火。
  - 精英。
  - Boss。
- 将章节路线、商店价格、删卡价格、篝火恢复比例数据化。
- 实现问号事件系统和第一批事件数据。
- 实现篝火恢复、篝火升级、商店买卡、商店删卡。
- 加入第一批 SVG 占位美术资源和资产清单。
- 实现单槽位跑团存档/读档。
- 实现分叉地图生成后端和地图生成配置。
- 新增状态词条数据表，并让战斗 UI 显示中文状态名。
- 将分叉地图接入实际跑团 UI：
  - 新跑团会生成地图图结构。
  - 完成节点后进入地图选择界面。
  - 玩家只能选择从当前节点连出的下一层节点。
  - 存档保存当前地图、已完成节点、可选节点和当前节点。
- 实现牌组查看器：
  - 显示当前牌组列表。
  - 显示攻击、技能、能力、状态/诅咒和升级牌统计。
  - 升级牌以 `+` 标记。
- 实现篝火升级预览：
  - 显示升级前后费用。
  - 显示升级前后描述。
- 实现占位音频管理器：
  - UI、出牌、结束回合、奖励、地图、篝火、商店、保存、错误和药水事件均有临时音色配置。
  - headless 模式自动 no-op，避免自动化测试被音频设备阻塞。
- 实现药水系统：
  - 新增 `data/potions/potions.json`，包含 8 个带注释的原创药水。
  - 新增玩家药水槽配置和商店药水价格配置。
  - 战斗中可使用药水，支持伤害、护甲、抽牌、能量、势能、状态和治疗效果。
  - 战斗奖励可获得药水，商店可购买药水。
  - 存档会保存当前持有药水。
  - 新增 `assets/art/potion_placeholder.svg` 占位资源。
- 扩展第一章问号事件池：
  - `data/events/events.json` 从 2 个事件扩展到 10 个事件。
  - 新事件覆盖金币、治疗、加牌、删卡、获得遗物和获得药水。
  - `data/config/map_generation.json` 的 `event_pool` 已引用完整事件池。
- 新增数据完整性测试：
  - 校验事件池规模。
  - 校验地图事件池引用存在。
  - 校验事件效果引用的卡牌、遗物和药水存在。
  - 校验药水数据保留设计、平衡和实现注释。
- 实现数据驱动 Boss 阶段机制：
  - `forge_bishop` 现在配置 66% 和 33% 两个生命阶段。
  - 阶段数据包含 `phase_note`、入场效果和独立行动循环。
  - `CombatState` 会在敌人生命跨过阈值时进入阶段、执行入场效果、重置意图并切换行动表。
  - 战斗 UI 会在敌人名称旁显示当前阶段名。
  - 数据完整性测试会校验 Boss 阶段阈值、注释、行动和创建卡牌引用。
- 实现第一版正式地图视觉界面：
  - 新增 `scripts/map/MapView.gd`，负责分层显示地图节点和自绘路线连线。
  - 地图节点会区分可前往、已完成和暂不可达状态。
  - 点击可前往节点会复用现有 `_on_map_node_pressed` 路线逻辑。
  - 地图选择界面不再依赖旧的纯文本路线预览和奖励行按钮。
  - 新增 `tests/test_map_view.gd`，覆盖节点按钮生成、可选节点统计和点击信号。
- 实现第一版战斗表现层美化：
  - 敌人区域从纯按钮改为“占位美术 + 状态按钮”的视觉面板。
  - 敌人美术会按 `sprite_key` 加载 SVG，占位缺失时按普通敌人/Boss fallback。
  - 手牌按钮按攻击、技能、能力、状态/诅咒使用不同色系和卡框图标。
  - 药水槽按钮使用药水 SVG 图标和独立样式。
  - 通过 Godot headless import 生成 `potion_placeholder.svg.import` 和对应导入纹理。

验证：

- JSON 数据通过 `jq` 校验，包含药水数据。
- Godot headless 战斗 smoke test 通过。
- Godot headless 主场景启动通过。
- Godot headless 跑团流程 smoke test 通过。
- Godot headless 存档 smoke test 通过。
- Godot headless 地图生成 smoke test 通过。
- Godot headless 地图视图 smoke test 通过。
- Godot headless 音频 smoke test 通过。
- Godot headless 数据完整性 smoke test 通过。
- Godot headless 跑团测试覆盖地图选择和牌组查看器。
- Godot headless 跑团测试覆盖升级预览。
- Godot headless 测试覆盖战斗使用药水、主场景药水按钮、商店购买药水和存档药水字段。
- Godot headless 跑团测试覆盖事件发放药水。
- Godot headless 战斗测试覆盖 Boss 两段转阶段和阶段行动循环切换。
- Godot headless 跑团测试覆盖敌人占位美术加载、手牌按钮样式和药水图标加载。

最新验证命令：

```bash
jq empty data/cards/cards.json data/enemies/enemies.json data/relics/relics.json data/potions/potions.json data/encounters/encounters.json data/config/player.json data/config/economy.json data/config/chapter_one_route.json data/config/map_generation.json data/events/events.json data/statuses/statuses.json
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/lizhiwei/localProj/EmberCircuit --script res://tests/test_combat_core.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/lizhiwei/localProj/EmberCircuit --script res://tests/test_run_flow.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/lizhiwei/localProj/EmberCircuit --script res://tests/test_save_manager.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/lizhiwei/localProj/EmberCircuit --script res://tests/test_map_generator.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/lizhiwei/localProj/EmberCircuit --script res://tests/test_map_view.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/lizhiwei/localProj/EmberCircuit --script res://tests/test_audio_manager.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/lizhiwei/localProj/EmberCircuit --script res://tests/test_data_integrity.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/lizhiwei/localProj/EmberCircuit --quit-after 2
```

下一步：

- 增加战斗动画、受击反馈和更正式的卡牌/药水美术。
- 增加 Boss 阶段专属表现反馈。
- 增加事件系统条件和随机结果。
