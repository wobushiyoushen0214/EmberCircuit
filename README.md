# EmberCircuit

`EmberCircuit` 是一个 Godot 4.x 原创卡牌肉鸽项目。当前路线是先完成稳定的类杀戮尖塔战斗、地图、奖励、遗物和 Boss 闭环，再把“移动壁垒”的九宫格空间战术作为扩展模式接入。

## 当前里程碑

- Godot 项目已创建。
- `docs/` 保存完整设计、开发计划、美术音频管线和数据规范。
- `data/` 保存带注释的卡牌、敌人、遗物、药水、遭遇、事件、经济和地图数值。
- `scripts/` 保存数据驱动战斗核心、跑团 UI、存档、音频、地图生成和地图视图逻辑。

## 运行

用 Godot 4.x 打开本目录，运行主场景：

```text
res://scenes/main/Main.tscn
```

命令行验证：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/lizhiwei/localProj/EmberCircuit --quit-after 2
```

完整 smoke test 入口见 `docs/06_IMPLEMENTATION_LOG.md`。

## 设计原则

- 数据与表现分离：`CombatState` 是战斗唯一数据源，UI 只渲染状态。
- 卡牌和敌人数值可配置：所有基础数值放在 `data/`，并附带设计意图。
- 先做完整闭环，再做内容量：每个阶段都要求可运行、可验证。
