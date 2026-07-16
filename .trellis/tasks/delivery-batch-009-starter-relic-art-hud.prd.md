# Delivery Batch 009: 起始遗物生产美术与战斗 HUD

## 目标

让三名角色每局必见的起始遗物使用生产位图，并在 PC 战斗中持续可见，提升构筑信息可读性和成品感。

## 验收标准

- 三个起始遗物使用独立 `512x512 RGBA` 透明 PNG，不再读取首版 SVG。
- 遗物分区拥有正式生产契约，检查尺寸、比例、通道、透明边与主体占比。
- PC 战斗遗物带位于顶部 HUD，不能因沉浸模式隐藏。
- `1280x720` 下资源块、遗物、药水和战场互不遮挡，无页面滚动条。
- 不修改卡牌、角色、怪物、遗物效果和经济数值。

## 范围

- `assets/art/generated/relics/`
- `data/config/art_assets.json`
- `scripts/main/Main.gd`
- `tests/test_data_integrity.gd`
- `tests/test_run_flow.gd`
