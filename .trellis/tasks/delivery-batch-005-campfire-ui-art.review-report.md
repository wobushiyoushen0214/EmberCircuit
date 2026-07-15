# 双阶段评审报告

## 被评审对象

- 任务：`delivery-batch-005-campfire-ui-art`
- diff 范围：`bf79182..L3 Round 1 工作树`
- Stage 1：主线程按 PC 篝火流程、资源契约、数值冻结和发布清单机械核对。
- Stage 2：Codex 强模型只读子代理（Ohm）独立检查正确性、动态牌组、滚动、节点生命周期和导出风险。

## Stage 1 · 规范符合

| 检查项 | 结果 | 证据 | 说明 |
| --- | --- | --- | --- |
| 到达页决策 | 通过 | `tests/test_run_flow.gd`, `07_campfire_720p.png` | PC 到达页只有房间叙事与休息/锻造两项主决策，不再混排升级牌。 |
| 完整牌组锻造 | 通过 | `tests/test_run_flow.gd`, `tests/test_visual_bounds.gd` | 候选按真实 `deck_index` 保序，重复牌实例可区分；16 张候选能滚动到最后一行。 |
| 720p 边界 | 通过 | `tests/test_visual_bounds.gd`, `07_campfire_forge_720p.png` | 到达页无滚动，锻造页隐藏系统滚动条并保留滚轮导航；正常十卡牌组完整显示。 |
| 资源契约 | 通过 | `data/config/art_assets.json`, `tests/test_art_asset_auditor.gd` | 房间图绑定 `room_illustration`，严格要求 `1536x1024 RGB` 且禁止 legacy fallback。 |
| 数值冻结 | 通过 | 当前 diff | 未修改卡牌、角色、怪物、成长、挑战或经济数值；休息 40% 和既有升级结算保持不变。 |
| 发布入口 | 通过 | `project.godot`, `export_presets.cfg`, `Main.gd`, `PLAYTEST_README_ZH.txt` | 四处版本一致升级为 `0.1.0-alpha.4` / build 4，未写入 API key 或生图响应。 |

## Stage 2 · 首轮发现

| 严重度 | 问题 | 处置 |
| --- | --- | --- |
| Major | 0 张可升级牌时仍可进入空锻造页。 | 到达页复用候选计数，0 张时禁用锻造并显示“无需锻造”；真实流程测试覆盖。 |
| Major | 原测试只选首个候选，没有覆盖返回、重复牌实例、超过两行的长牌组和滚到底。 | 新增锻造返回、非首位重复牌升级、未选重复牌不变、16 候选和最后一张完全进入视口的断言。 |
| Minor | 房间测试没有锁定专用契约和禁止 fallback。 | 新增 `contract_id=room_illustration` 与 `legacy_fallback_allowed=false` 断言。 |
| Minor | PNG 和 `.import` 在评审时尚未跟踪。 | 提交清单明确包含 `assets/art/generated/rooms/`，发布前再次检查 Git 状态。 |

## 复审结果

- Major 1：已关闭。
- Major 2：已关闭。
- 资源契约 minor：已关闭。
- Critical：0。
- Major：0。
- 最终裁决：允许提交并进入 `0.1.0-alpha.4` 产物构建。

## 验证证据

- 18/18 Godot 测试串行通过，并额外扫描日志中的 `SCRIPT ERROR` / `ERROR:`，避免仅依赖进程退出码。
- 严格资源审计：153 total、0 missing、0 hard error、74 legacy fallback。
- Godot headless 主场景启动通过。
- 1280x720 到达页和锻造页截图人工复核：无裁切、重叠或可见页面滚动条。
