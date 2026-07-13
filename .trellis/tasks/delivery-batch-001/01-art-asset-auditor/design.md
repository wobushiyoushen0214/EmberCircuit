# Design: 美术资源完整性审计器

## 编排-计算分离

| 层 | 元素 | 落点 |
| --- | --- | --- |
| 编排层 | 加载 JSON、打印报告 | `tools/run_art_asset_audit.gd` |
| 计算层 | 收集槽位、质量分类、优先级、汇总 | `scripts/tools/ArtAssetAuditor.gd` |

## 数据契约

- `audit(art_data: Dictionary) -> Dictionary`
- 返回 `{summary: {total, production_candidate, first_pass, missing}, items: Array}`。
- `priority` 允许 `high`、`medium`、`low`；missing 为 high，first_pass 为 medium，production_candidate 为 low。

## 挂载点清单

- [ ] `run_art_asset_audit.gd` 可从项目根目录运行。
- [ ] `test_art_asset_auditor.gd` 加载真实清单。
- [ ] 每个 item 保留稳定 section/id/path，供后续任务引用。

## 非目标

- 不自动生成或替换图片。
- 不改变资源清单 schema。
