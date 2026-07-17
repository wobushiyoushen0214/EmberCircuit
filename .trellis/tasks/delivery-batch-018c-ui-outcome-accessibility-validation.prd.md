# Batch 018C：结算、设置、图鉴与全页面视觉/可访问性验收

## 需求 ID

- REQ-008
- REQ-012
- AC-018C-01 ～ AC-018C-12

## 当前缺口

胜利/战败、设置和图鉴仍由 `Main.gd` 内联构造，虽然功能测试存在，但没有独立页面契约、设置 v1→v2 迁移、reduced-motion/闪光/粒子策略、键盘焦点/44px 热区、语义截图金标和稳定节点/帧预算门。

证据：`scripts/main/Main.gd:_build_run_completion_panel/_add_pc_defeat_experience/_refresh_settings_view/_refresh_compendium_view`；`scripts/core/SaveManager.gd:normalized_settings`；`tests/test_save_manager.gd`、`tests/test_visual_bounds.gd`、`tools/render_pc_gallery.gd`。

## 交付 Loop 控制

- 交付批次：`delivery-batch-018-ui-ember-forge-cohesion`
- Loop：L3；worktree/verifier：是/是；实现/调试/评审：`trellis-implement-tdd-zh` / `trellis-debug-systematic-zh` / `trellis-review-twostage-zh`。
- 依赖：018A、018B；最终验收前不得跳过 outcome/settings/compendium 回归。
- 最大修复 2 次，最大调试 3 轮；任何终局存档/遥测回归立即停止。

## 决策表：settings v2

| 字段 | 类型 | 默认 | 约束 |
| --- | --- | --- | --- |
| `version` | int | 2 | normalized_settings 总是输出 2 |
| `reduced_motion` | bool | false | 不从旧 screen_shake 推断 |
| `flash_intensity` | float | 1.0 | clamp 0..1，步长 0.25 |
| `particle_density` | float | 1.0 | clamp 0..1，步长 0.25 |

旧声音、音量、震屏、顿帧、漂浮文字和教程字段原值保留；未知字段丢弃；settings 仍独立原子保存，不写跑团/遥测。

## MVP 兼容性契约

- 胜利：profile receipt → telemetry victory → 删除所属 run save 的顺序不变。
- 战败存储/遥测失败显示重试、禁用重新开始；恢复后不重复炉印/receipt/telemetry。
- 保留 `RunCompletionPanel`、`PcDefeatExperience`、`DefeatCleanupRetryButton` 节点名和全部 `last_*` probe。
- 图鉴未发现条目不泄露名称、正文、数值、图像、tooltip 或设计注释。
- 现有 SaveManager 原子替换、旧 settings 归一化和 `test_run_flow` 行为不变。

## 文件清单

| 操作 | 文件 |
| --- | --- |
| 修改 | `scripts/main/Main.gd`（outcome/settings/compendium 只生成 VM/连接 signal） |
| 修改 | `scripts/core/SaveManager.gd`（normalized_settings schema v2/迁移） |
| 修改 | `scripts/ui/AppShell.gd`, `scripts/ui/ForgeMotion.gd`（全局策略接入） |
| 新建 | `scripts/ui/components/OutcomeStage.gd` |
| 新建 | `scripts/ui/pages/OutcomePage.gd`, `SettingsPage.gd`, `CompendiumPage.gd` |
| 修改 | `tests/test_save_manager.gd`, `tools/render_pc_gallery.gd` |
| 新建 | `tests/test_ui_outcome_settings_compendium.gd`, `test_ui_accessibility_motion.gd`, `test_ui_performance_budget.gd` |
| 新建 | `tools/verify_ui_visual_regression.gd`, `tools/profile_ui_performance.gd` |
| 新建 | `tests/fixtures/ui_visual_contracts.json` 与 `tests/golden/ui_720p/00_welcome_720p.png` 至 `10_compendium_720p.png` |
| 修改 | `docs/04_ART_AUDIO_PIPELINE.md`, `docs/06_IMPLEMENTATION_LOG.md`, `docs/07_CURRENT_STATE_AND_NEXT_STEPS.md` |

## 挂载点

1. Main outcome/settings/compendium route 挂入 AppShell。
2. SaveManager normalized_settings v2 接入设置读写。
3. ForgeMotion/AppShell 接入 reduced-motion、flash、particle 策略。
4. Gallery/visual contracts/performance tools 接入交付验收。

## RED 顺序

1. OutcomePage 结构、终局失败恢复和兼容节点 RED；提取页面但保留 Main 状态写入。
2. SaveManager v1→v2 migration、clamp、unknown field RED。
3. SettingsPage 分组/slider/toggle/即时保存与 reset confirm RED。
4. CompendiumPage rail/search/template/未发现/空结果 RED。
5. 全页面 motion/focus/44px/对比度 RED；reduced-motion 关闭循环 Tween/粒子但保留 opacity/border。
6. 11 页语义区域 visual contracts 先因缺金标 RED，固定字体/时间/种子后生成金标并人工签核。
7. 节点/粒子/tween 泄漏与 600 帧性能 RED；最后全量 strict regression。

## 验收标准

- [ ] OutcomePage/OutcomeStage 渲染胜败，Main 只编排，终局存储失败恢复语义和旧 probe 全部通过。
- [ ] SaveManager v1→v2 迁移、默认、极值 clamp、未知字段清理和原子保存通过。
- [ ] 设置四组、slider/toggle、reduced motion/flash/particle、即时保存、恢复默认确认和来源页返回通过。
- [ ] 图鉴六分类 rail、搜索/筛选/排序、至少三种内容模板、未发现不泄露、空结果恢复动作通过。
- [ ] 11 页 motion policy、focus order、44×44、对比度和 Escape 返回通过。
- [ ] 1280×720 11 张金标按区域差异 ≤1% 平均 RGB、≤2% 差异像素；不使用宽松全屏阈值。
- [ ] 常驻粒子≤60、半密度≤30、零密度/reduced-motion 为0；普通 burst≤18、Boss≤30；每页循环 tween≤2；20次开关无节点/tween累积。
- [ ] Windows release 采样 warmup120/frame600，p95≤20ms、1% low≥45 FPS、输入反馈≤100ms；全量测试无错误日志。

## 自检命令

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_save_manager.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_ui_outcome_settings_compendium.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_ui_accessibility_motion.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_ui_performance_budget.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_visual_bounds.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://tools/render_pc_gallery.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tools/verify_ui_visual_regression.gd -- --actual=/tmp/embercircuit_pc_gallery --contracts=res://tests/fixtures/ui_visual_contracts.json
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://tools/profile_ui_performance.gd -- --width=1280 --height=720 --warmup=120 --frames=600 --output=/tmp/embercircuit-ui-performance.json
```

## 范围外/禁止事项

- 不改变卡牌/敌人/经济/地图/事件效果/挑战/CombatState 或真人遥测 payload。
- 不删除旧终局节点/probe，不把 settings 写进 run save。
- 不用全屏宽松像素阈值、不隐藏对比度/焦点失败、不引入网络资源或第三方字体。
