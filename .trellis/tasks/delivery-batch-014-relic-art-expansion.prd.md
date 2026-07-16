# Delivery Batch 014: 通用遗物生产位图扩展

## 目标

把贯穿角色开局、战斗 HUD、奖励、宝箱、商店和图鉴的高频遗物从临时 SVG 迁移为统一风格的生产位图，并补齐熔痕苦修者的第二件开局遗物。

## 范围

- 灰烬念珠、沉重齿轮、战鼓残片、熔芯戒指、破盾楔、空白契约、回声石和旧罗盘。
- `data/config/art_assets.json` 的稳定资源槽位。
- 遗物资源契约、完整性测试与 PC 视觉证据。
- 不修改卡牌、角色、敌人、遗物效果、经济或挑战数值。

## 验收标准

- `AC-001`: 八件遗物均使用独立 `512x512 RGBA` PNG，并保留原 SVG `slot_path` 作为稳定替换槽位。
- `AC-002`: 每张 PNG 有真实透明像素、完整轮廓和适合 32px HUD 的明确主形；不得包含文字、Logo、水印或 UI 卡框。
- `AC-003`: 三名角色的全部六件开局遗物均切换到生产位图。
- `AC-004`: 遗物生产位图总数从 5 提升到 13，资源审计 `hard_errors = 0`。
- `AC-005`: 奖励页、商店、宝箱、图鉴和战斗遗物栏继续从同一个资源清单解析图标。
- `AC-006`: `1280x720` PC 截图不存在裁切、重叠、文本挤压或滚动条回归。
- `AC-007`: 19 套既有回归测试全部通过，运行日志不得出现 `SCRIPT ERROR` 或 Godot `ERROR:`。

## 文件清单

- `assets/art/generated/relics/relic_*_v2_pc.png`
- `assets/art/generated/relics/relic_*_v2_pc.png.import`
- `data/config/art_assets.json`
- `tests/test_art_asset_auditor.gd`
- `tests/test_data_integrity.gd`
- `tests/test_visual_bounds.gd`
- `tools/render_pc_gallery.gd`
- `docs/06_IMPLEMENTATION_LOG.md`
- `.trellis/tasks/delivery-batch-014-relic-art-expansion.*.md`

## 自检命令

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_art_asset_auditor.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_data_integrity.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_visual_bounds.gd
for test in tests/test_*.gd; do ...; done  # 每套检查退出码、SCRIPT ERROR 与 Godot ERROR:
```

## 生产约束

- 使用用户指定的 `gpt-image-2` 接口生成正方形色键源图，再确定性去底和 Lanczos 缩放。
- API 凭据、接口响应、色键源图和临时提示词不得进入 Git。
- 生图失败或透明处理不合格的资源不得在清单中伪装成生产完成。
