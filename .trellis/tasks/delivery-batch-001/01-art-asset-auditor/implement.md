# Implementation Plan: 美术资源完整性审计器

## 文件计划

| 步骤 | 文件 | 操作 | 验证方式 |
| --- | --- | --- | --- |
| 1 | `tests/test_art_asset_auditor.gd` | 先写三条 AC 测试 | 测试因脚本缺失或断言失败而红 |
| 2 | `scripts/tools/ArtAssetAuditor.gd` | 实现纯数据审计 | 单测变绿 |
| 3 | `tools/run_art_asset_audit.gd` | 增加 JSON CLI | headless 运行输出 JSON |
| 4 | 全部 | 运行回归 | 两条自检命令通过 |

## 修改边界

- 仅允许 PRD File Manifest 中四个文件。
- 禁止修改资源加载、数值和现有素材。

## 结构健康度预检

- 新文件均低于 250 行，不需要微重构。
- `Main.gd` 11994 行但本任务禁止修改。
