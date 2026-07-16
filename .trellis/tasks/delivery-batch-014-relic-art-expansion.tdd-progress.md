# Delivery Batch 014 TDD 进度

## 进度表

| AC ID | 期望可观察结果 | 测试文件/证据 | 测试命令 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- |
| AC-001 | 八个稳定槽位解析到独立 512x512 RGBA PNG | `test_art_asset_auditor.gd`、资源元数据 | 资源审计 | done | 评审后补齐逐 ID 路径、槽位、尺寸、RGBA、占比、唯一路径与唯一内容断言 |
| AC-002 | 透明像素、轮廓和小尺寸可读性合格 | 资源审计、人工图像复核 | 资源审计 + 截图复核 | done | 八张源图已逐张检查 |
| AC-003 | 六件开局遗物全部使用生产位图 | `test_data_integrity.gd` | 数据完整性测试 | done | 评审后补齐三角色各两件、合计六件且互异的精确断言 |
| AC-004 | 生产遗物数量至少 13，hard_errors 为 0 | `test_art_asset_auditor.gd` | 资源审计 | done | 全量严格自检通过 |
| AC-005 | 所有遗物页面继续走统一 manifest | `art_assets.json`、图库证据 | 数据完整性 + 图库 | done | 未增加 UI 硬编码路径 |
| AC-006 | 720p HUD 与图鉴无溢出 | `test_visual_bounds.gd`、图库 36/37 | 视觉边界测试 + 图库 | done | 截图已人工复核 |
| AC-007 | 19 套测试严格全绿 | 全部 `tests/test_*.gd` | 严格回归循环 | done | 19/19；无 `SCRIPT ERROR` 或 Godot `ERROR:` |

## 收尾核对

- [x] 所有 AC 状态为 `done`。
- [x] 无任何 AC 停留在 `red` / `green`。
- [x] `prd.md` 自检命令全集最后一次运行全绿。
- [x] 已执行最小实现收敛：沿用统一资源清单与既有审计器，没有新增依赖或 UI 专用资源路径。
- [x] `design.md` 挂载点已接线：manifest、审计器、HUD 压力态和图鉴快照均已覆盖。
- [x] 未 commit；严格回归与双阶段评审已完成，等待交付提交。

## 最小实现收敛

- 删除项：无；本批没有新增业务抽象。
- 复用项：复用 Godot 资源加载、现有 `ArtAssetAuditor`、统一 `art_assets.json` 和图库工具。
- 保留项：保留尺寸、RGBA、真实透明像素、生产数量、开局遗物与 720p 溢出回归保护。
- 评审修复：补齐八张位图的 `.png.import` sidecar，保证干净检出后的导入 UID 与参数稳定。
- `trellis-minimal:` 注释：无。
