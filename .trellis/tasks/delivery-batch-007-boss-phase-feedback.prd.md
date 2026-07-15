# PRD：PC Boss 阶段与战斗反馈重构

## 目标

在不修改卡牌、角色、敌人、挑战或经济数值的前提下，提高三章 Boss 阶段阈值、切换效果和下一行动的可读性，并移除全局时间缩放造成的 UI 卡顿。

## 验收标准

### AC-001 Boss 阶段轨道

- PC Boss 舞台存在稳定节点 `BossPhaseBadge`。
- 两个配置阶段显示为 `阶段 1/3`、`阶段 2/3`、`阶段 3/3`。
- Boss HP 条按数据中的 `hp_percent_below` 显示两个稳定节点 `BossPhaseThreshold_0/1`。
- 普通敌人不显示阶段徽章或阈值线。
- 敌人 tooltip 显示当前阶段、下一阈值和下一阶段说明。

### AC-002 战场内阶段横幅

- `phase` feedback 使用 `BossPhaseBanner`，不再显示全屏 `cinematic_overlay`。
- 横幅显示真实 Boss 名、阶段名、阶段序号、入场效果摘要和切换后的下一意图。
- 横幅颜色、音频、射线和角色动画继续读取现有 `boss_phase_profiles`。
- `won/lost` 仍使用原有全屏胜败提示。
- 横幅不阻塞鼠标，动画结束自动释放；headless 下保留节点供契约测试。

### AC-003 局部顿帧

- 受击顿帧不修改 `Engine.time_scale`。
- 非 headless 运行时只暂时禁用 `enemy_stage_stack` 的处理，手牌、菜单、反馈层和 UI Tween 不被减速。
- 重叠请求以最晚截止时间为准，结束后恢复原 process mode。
- 节点退出时必须恢复战场处理状态。

### AC-004 PC 视觉证据

- `1280x720` 下阶段徽章、阈值线和横幅完整位于战场内，无页面滚动条、裁切或布局溢出。
- PC 图库新增熔炉主教、风暴执政官、回路核心三个阶段切换截图。

## 文件清单

- `scripts/main/Main.gd`
- `tests/test_run_flow.gd`
- `tests/test_visual_bounds.gd`
- `tools/render_pc_gallery.gd`
- `.trellis/delivery-state.md`
- `docs/06_IMPLEMENTATION_LOG.md`
- `docs/07_CURRENT_STATE_AND_NEXT_STEPS.md`
- `project.godot`
- `export_presets.cfg`
- `packaging/PLAYTEST_README_ZH.txt`
- `.trellis/delivery-run-log.jsonl`
- 本任务的 `design.md`、`tdd-progress.md`、`review-report.md`

## 禁止事项

- 不修改 `data/cards/`、`data/enemies/`、`data/config/player.json`、`monster_scaling.json`、挑战或经济数值。
- 不增加网络依赖、插件或新的运行时单例。
- 不用新的全屏黑色遮罩替代旧遮罩。
- 不把 Boss 阶段规则复制到 UI；阈值、名称、效果和行动必须读取 `CombatState` 运行态及敌人数据。

## 自检命令

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_run_flow.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_visual_bounds.gd
```
