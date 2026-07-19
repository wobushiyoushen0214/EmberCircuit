# 018D-03：跑团页面旧树收敛与视觉/性能验收

## 需求 ID

- REQ-008
- REQ-012 regression
- AC-018D-10 ～ AC-018D-12

## 当前缺口

- 状态：PARTIAL/UNTESTED，依赖 018D-02。
- 挂载完成后 Main 仍会保留无调用旧视觉 helper；现有金标对应旧运行时页面；profiler 只切设置/图鉴，不覆盖五个新 route page。
- 风险：死代码形成双实现，截图金标误验旧页面，反复路由产生节点/tween 累积。

## 交付 Loop 控制

- 批次：`delivery-batch-018d-ui-run-page-mounts`
- Loop：L3；worktree/verifier：是/是。
- 技能：TDD / systematic debug / two-stage review。
- 最大修复/调试：2 / 3。
- 回滚触发：区域视觉失败两次、性能预算失败两次、误删业务 helper、全量回归失败、File Manifest 越界。

## 复杂度与决策

- 复杂度：中。
- 删除规则：先 `rg` 证明 helper 无调用，再删除纯视觉构造；任何状态生成、回调、音频、telemetry、asset lookup 或 probe 保留。
- 金标：只更新 `03_reward_720p`、`04_map_720p`、`05_event_720p`、`06_shop_720p`、`07_campfire_720p`，其他六页必须像素稳定。
- 性能：profiler 20 轮依次 mount/clear map→event→shop→campfire→reward；节点增量 0、循环 tween≤2、输入≤100ms、p95≤20ms、1% low≥45 FPS。
- 视觉：沿用暗炉 token、本地字体和固定 seed；不引入新资产。

## 文件清单

| 操作 | 文件 | 精确修改 |
| --- | --- | --- |
| 修改 | `scripts/main/Main.gd` | 删除经 rg 证明无调用的五页旧纯视觉 helper |
| 修改 | `scripts/ui/pages/RewardPage.gd` | 收据/战利品/命令三栏与自适应卡面高度，保持 signal 契约 |
| 修改 | `scripts/ui/pages/EventPage.gd` | 事件生产插画与完整四选项分栏，保持 choice id 契约 |
| 修改 | `scripts/ui/pages/ShopExperience.gd` | 等高货架与现有卡/遗物/药水图标，保持价格和交易 signal 契约 |
| 修改 | `scripts/ui/pages/CampfirePage.gd` | 房间生产插画、生命状态和到达/锻造双阶段，保持真实 deck index 契约 |
| 修改 | `tests/test_visual_bounds.gd` | active page 720p/900p、底部动作、滚动末端、无旧 root |
| 修改 | `tests/test_ui_performance_budget.gd` | 五 route pages 的节点/tween预算静态门 |
| 修改 | `tools/render_pc_gallery.gd` | 五页 setup 使用真实 mount page，保持固定 seed |
| 修改 | `tools/profile_ui_performance.gd` | 20 轮五页切换和真实战斗 600 帧 |
| 修改 | `tests/fixtures/ui_visual_contracts.json` | 五页区域 rect，阈值不放宽 |
| 修改 | `tests/golden/ui_720p/03_reward_720p.png` | 新 RewardPage 金标 |
| 修改 | `tests/golden/ui_720p/04_map_720p.png` | 新 MapPage 金标 |
| 修改 | `tests/golden/ui_720p/05_event_720p.png` | 新 EventPage 金标 |
| 修改 | `tests/golden/ui_720p/06_shop_720p.png` | 新 ShopExperience 金标 |
| 修改 | `tests/golden/ui_720p/07_campfire_720p.png` | 新 CampfirePage 金标 |
| 修改 | 对应五个 `.png.import` | Godot import metadata |
| 修改 | `docs/02_TECHNICAL_ARCHITECTURE.md` | Main→VM→page→signal→Main 边界 |
| 修改 | `docs/04_ART_AUDIO_PIPELINE.md` | 五页视觉/状态/金标规则 |
| 修改 | `docs/06_IMPLEMENTATION_LOG.md` | 018D 实现与验证结果 |
| 修改 | `docs/07_CURRENT_STATE_AND_NEXT_STEPS.md` | 当前完成度与下一缺口 |

## 挂载点

- Gallery 的五个标准 page id 必须来自真实 Main 路由。
- Visual contracts 的五个页面区域必须覆盖标题/主体/动作，不用全屏宽松阈值。
- Profiler 的 route switch loop 必须进入五个 active_page_id。
- 文档必须声明 018B pages 已真实挂载，不再说“后续挂载”。

## 实现步骤

1. RED AC-10：加入无旧 root/无调用 helper 断言或静态搜索，确认旧视觉 helper 仍存在；逐组删除并每组跑 run-flow。
2. RED AC-11：重新渲染前先用旧金标验证五页差异失败；人工检查新截图无重叠/空洞/裁切后，只更新五张金标并验证 11/11。
3. RED AC-12：profiler 加五页 20 轮切换，初始节点增量/输入统计不满足新字段；实现采样并达到预算。
4. 跑全部 `tests/test_*.gd` 严格日志、editor import、visual verifier、profiler。
5. 更新四份文档、TDD 进度，执行最小实现收敛并交双阶段评审。

## 验收标准

- [ ] AC-018D-10：五页旧 PC 视觉构造 helper 无调用且已删除；业务/状态/回调/probe 全保留；Main 行数净减少。
- [ ] AC-018D-11：五页 1280x720 与 1600x900 无重叠、裁切、无用途空洞或不可达动作；11 页区域回归全绿，阈值仍 mean≤1%、changed≤2%。
- [ ] AC-018D-12：五页 20 轮切换节点增量 0、循环 tween≤2；600 帧 p95≤20ms、1% low≥45、输入≤100ms；全量严格回归无未知 ERROR/泄漏。
- [ ] 018D 三任务 TDD 进度完整，Stage 1/2 无 critical 后才可标记交付。

## 自检命令

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_visual_bounds.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_ui_performance_budget.gd
for test in tests/test_*.gd; do /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://$test || exit 1; done
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://tools/render_pc_gallery.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tools/verify_ui_visual_regression.gd -- --actual=/tmp/embercircuit_pc_gallery --contracts=res://tests/fixtures/ui_visual_contracts.json --output=/tmp/ember018d-visual.json
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://tools/profile_ui_performance.gd -- --width=1280 --height=720 --warmup=120 --frames=600 --output=/tmp/ember018d-performance.json
```

## 自动化与人工验证

- Regression：全部 Godot tests 严格日志。
- Visual：11 页区域 diff；人工检查五张新图的构图和状态层级。
- Performance：真实 Main route loop + combat 600 frames。
- Manual 原因：像素阈值不能判断构图美感，需查看五张 720p/900p 图片；只评审布局和可读性，不重新选风格。

## 视觉验收修订

- 首轮真实挂载截图暴露 Reward/Event/Shop/Campfire 大面积无用途空洞，违反 AC-018D-11；因此将四个既有 page 实现加入 File Manifest，只补视觉结构和 Main 的只读 `art_path` VM 字段，不修改 signal、交易或奖励契约。
- 修订经用户总体 UI 优化授权覆盖，仍不新增素材、数值、业务状态或依赖；原 018D-01/02 行为测试必须继续全绿。

## 依赖与范围外

- 依赖：018D-01、018D-02 全绿。
- 不新增功能/素材/数值/发布配置，不修改 page contract 或业务回调签名。
- 不放宽阈值、不删测试、不 commit/push/merge、不自行评审完成。
