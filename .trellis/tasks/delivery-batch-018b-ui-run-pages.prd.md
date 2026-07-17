# Batch 018B：地图、事件、商店、篝火与奖励页面迁移

## 需求 ID

- REQ-008
- REQ-012
- AC-018B-01 ～ AC-018B-08

## 目标与当前缺口

依赖 018A 的 AppShell/ForgeTheme/组件 API，把地图、事件、商店、篝火、奖励/宝箱从 `Main.gd` 内联视觉树迁移到独立页面类。当前地图/事件/篝火功能可用但材质、状态和页面层级不统一；商店仍是裸 flow；奖励与宝箱没有“已领取/售罄/部分领取”的统一状态视觉。

代码证据：`scripts/main/Main.gd:_refresh_map_choices/_refresh_event/_refresh_shop/_refresh_campfire/_refresh_treasure/_refresh_rewards`、`scripts/map/MapView.gd`、`scripts/ui/CurveTrail.gd`；测试证据：`tests/test_map_view.gd`、`tests/test_run_flow.gd`、`tests/test_visual_bounds.gd`。

## 交付 Loop 控制

- 交付批次：`delivery-batch-018-ui-ember-forge-cohesion`
- Loop：L3；worktree/verifier：是/是；实现/调试/评审技能：`trellis-implement-tdd-zh` / `trellis-debug-systematic-zh` / `trellis-review-twostage-zh`。
- 依赖：`delivery-batch-018a-ui-shell-menu-pages`。
- 最大修复 2 次，最大调试 3 轮；任何交易、地图信号、奖励事务、存档语义回归立即回滚。

## 决策表

| 决策 | 选定方案 | 影响 |
| --- | --- | --- |
| Shop | 新建独立 `ShopExperience`，只发信号，不直接改金币/库存 | `ShopExperience.gd`, `Main.gd` |
| Map | `MapPage` 持有原 MapView，透传两个原信号；CurveTrail 只做短促高亮，不常驻动画 | `MapPage.gd`, `MapView.gd`, `CurveTrail.gd` |
| Event/Campfire | 迁移现有 PcEvent/PcCampfire/PcCampfireForgeSelection 节点名和回调 | page scripts, Main |
| Reward/Treasure | 一个 `RewardPage` view model 处理战斗奖励与宝箱，领取仍调用原事务函数 | `RewardPage.gd`, `Main.gd` |
| 资产 | 只复用/新增原创本地资产；资源缺失走 art manifest fallback，不网络加载 | `art_assets.json`, tests |

## MVP 兼容性契约

- `MapView.node_selected/node_previewed`、`Main._on_map_node_pressed/_on_map_node_previewed` 不变。
- 事件禁用原因和一次性完成标记仍由 Main/数据层决定，页面只显示并发出 choice signal。
- 商店原子交易、删卡选择、药水槽满和售罄状态仍由 Main 唯一写入。
- 篝火恢复/锻造、奖励部分领取/存档恢复、宝箱金币/遗物幂等全部保留。
- 保留 `PcEventExperience`、`PcCampfireExperience`、`PcCampfireForgeSelection` 节点名和旧 `last_*` probes。

## 文件清单

| 操作 | 文件 |
| --- | --- |
| 新建 | `scripts/ui/components/ChoiceRow.gd`, `ItemShelf.gd`, `CardCompare.gd` |
| 新建 | `scripts/ui/pages/MapPage.gd`, `EventPage.gd`, `ShopExperience.gd`, `CampfirePage.gd`, `RewardPage.gd` |
| 修改 | `scripts/main/Main.gd`（五个 `_refresh_*` 只编排 VM/信号） |
| 修改 | `scripts/map/MapView.gd`, `scripts/ui/CurveTrail.gd`（状态材质/短促高亮，保留 API） |
| 修改 | `tests/test_map_view.gd`, `tests/test_run_flow.gd`, `tests/test_visual_bounds.gd` |
| 新建 | `tests/test_ember_forge_route_rooms.gd` |
| 修改 | `data/config/art_assets.json`, `tests/test_art_asset_auditor.gd`, `tests/test_data_integrity.gd` |
| 修改 | `docs/02_TECHNICAL_ARCHITECTURE.md`, `docs/04_ART_AUDIO_PIPELINE.md`, `docs/06_IMPLEMENTATION_LOG.md`, `docs/07_CURRENT_STATE_AND_NEXT_STEPS.md` |

## 挂载点

1. `Main._refresh` map/event/shop/campfire/treasure/reward 分支挂 page host。
2. Page signals 绑定原地图、事件、交易、篝火和奖励回调。
3. `MapPage` 接回 `MapView` 两个 signal；`RewardPage` 接回原存档事务。
4. ForgeTheme/ActionCard/ChoiceRow/ItemShelf 统一样式。

## 实现步骤与 RED 顺序

1. 先在 `test_ember_forge_route_rooms.gd` 和现有测试新增结构/API 断言，确认五个页面类、ShopExperience 独立信号、旧节点名兼容性为 RED。
2. GREEN 公共 ChoiceRow/ItemShelf/CardCompare 与 MapPage；先跑 map/view/bounds。
3. GREEN EventPage/CampfirePage，覆盖全部禁用/空选项/重复牌/长牌组边界。
4. GREEN ShopExperience，固定金币 HUD、分类货架、售罄占位、删卡柜台和所有禁用原因；交易仍由 Main 写入。
5. GREEN RewardPage，按金币→卡牌→遗物/药水→继续组织战斗奖励与宝箱；覆盖部分领取/恢复/空遗物池。
6. 更新文档与资源审计；运行页面截图和全量回归。

## 验收标准

- [ ] 五个 page class 独立存在，Main 不再构造其主要视觉树。
- [ ] 地图五种节点状态、风险/收益/后继预览、键盘焦点与 1280×720 无横向滚动条。
- [ ] 事件单舞台显示代价/收益/禁用原因；空选项有继续，禁用选项不发信号。
- [ ] ShopExperience 有商人 hero、金币、三类货架、售罄/买不起/药水满/无可删牌文字态，重复点击不发重复交易。
- [ ] 篝火休息/锻造两阶段，恢复预览精确，重复牌按真实索引，长牌组能到末端。
- [ ] 奖励/宝箱阶段顺序、已领取/跳过/部分恢复/遗物池耗尽均有结构断言且事务语义不变。
- [ ] 动作热区 ≥44×44、对比度 ≥4.5:1、reduced-motion 无位移/错峰粒子。
- [ ] 相关测试、视觉边界、资源审计和全量严格回归通过。

## 自检命令

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_ember_forge_route_rooms.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_map_view.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_run_flow.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_visual_bounds.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_art_asset_auditor.gd
```

## 范围外/禁止事项

- 不改经济、卡牌、敌人、地图生成、事件效果、存档 schema、遥测 payload、CombatState。
- 不删除旧节点名/probe，不在 page 内直接写 SaveManager/金币/牌组。
- 不引入第三方依赖，不复制参考站资源，不创建常驻粒子或无限扫光。
