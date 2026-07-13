# 美术资源完整性审计器

## 需求 ID

- REQ-008
- AC-008-01
- AC-008-02
- AC-008-03

## 目标

新增纯数据审计器，读取 `data/config/art_assets.json` 并输出所有美术槽位的正式候选、首版资源和缺失资源清单，为后续批量替换提供机器证据。

## 当前缺口

- 当前状态：PARTIAL
- 证据：`data/config/art_assets.json` 有路径与替换说明；`tests/test_data_integrity.gd` 只验证存在和最低质量。
- 缺口：没有统一质量分级、分类统计和 JSON 报告。
- 风险：继续凭截图挑素材会漏项，无法量化正式美术覆盖率。

## 交付 Loop 控制

- 交付批次：`delivery-batch-001`
- Loop 模式：L2
- 需要 worktree：是
- 需要 verifier：是
- 实现技能：`trellis-implement-tdd-zh`
- 调试技能：`trellis-debug-systematic-zh`
- 评审技能：`trellis-review-twostage-zh`
- 人工门：不需要，用户已授权直接开发
- 最大修复尝试次数：2
- 最大调试假设轮数：3
- 回滚触发：测试回归、File Manifest 越界、改变运行时资源加载行为

## 复杂度与规划产物

- 复杂度：中
- 执行模型假设：Codex
- 必要产物：`prd.md`、`design.md`、`implement.md`、`tdd-progress.md`
- Spec 新鲜度：`.trellis` 初次建立；以 `docs/04_ART_AUDIO_PIPELINE.md` 和资源清单为契约。

## 上下文清单

| 类型 | 路径 | 用途 |
| --- | --- | --- |
| 数据契约 | `data/config/art_assets.json` | 槽位结构与路径 |
| 现有测试 | `tests/test_data_integrity.gd` | 资源存在和质量检查范例 |
| 美术规范 | `docs/04_ART_AUDIO_PIPELINE.md` | 替换原则 |

## 决策表

| 决策点 | 选定方案 | 原因 | 影响文件 |
| --- | --- | --- | --- |
| 质量分级 | `production_candidate` / `first_pass` / `missing` | 与当前 PNG/首版 SVG/缺失三态一致 | `ArtAssetAuditor.gd` |
| 正式候选判定 | `assets/art/generated/*.png` 或 `.webp/.jpg` | 当前正式生成位图均位于该目录 | `ArtAssetAuditor.gd` |
| 首版判定 | 可加载 SVG | 现有 SVG 是可用但待替换首版 | `ArtAssetAuditor.gd` |
| 输出格式 | Dictionary + CLI JSON | 便于测试和批处理 | auditor + runner |

## MVP 兼容性契约

| 已有行为 | 证据 | 必须保留 | 回归检查 |
| --- | --- | --- | --- |
| `Main.gd` 按现有 asset_path 加载资源 | `scripts/main/Main.gd` | 是 | 10 套回归测试 |
| 资源清单字段不变 | `data/config/art_assets.json` | 是 | `test_data_integrity.gd` |

## 文件清单

| 操作 | 文件路径 | 说明 |
| --- | --- | --- |
| 新建 | `scripts/tools/ArtAssetAuditor.gd` | 纯数据分类和汇总 |
| 新建 | `tools/run_art_asset_audit.gd` | CLI 输出 JSON |
| 新建 | `tests/test_art_asset_auditor.gd` | AC 红绿测试 |
| 新建 | `.trellis/tasks/delivery-batch-001/01-art-asset-auditor/tdd-progress.md` | TDD 记录 |

## 挂载点

| 挂载点 | 类型 | 位置 | 接线动作 |
| --- | --- | --- | --- |
| 审计脚本入口 | CLI | `tools/run_art_asset_audit.gd` | 加载 auditor 并打印 JSON |
| 回归测试 | test | `tests/test_art_asset_auditor.gd` | 验证分级和计数 |

## 验收标准

- [ ] AC-008-01：审计器收集 `battle_background_slots`、`event_art_slots`、`card_art_slots`、`relic_icon_slots`、`potion_icon_slots` 的全部条目，`total` 等于五类数组长度总和。
- [ ] AC-008-02：生成位图分为 `production_candidate`，可加载 SVG 分为 `first_pass`，不存在路径分为 `missing`，三类数量之和等于 `total`。
- [ ] AC-008-03：CLI 报告包含 `summary` 和逐项 `items`，每项包含 `section`、`id`、`asset_path`、`quality_tier`、`priority`；首版资源优先级至少为 `medium`。
- [ ] 不修改资源加载或战斗数值。

## 自检命令

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_art_asset_auditor.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_data_integrity.gd
```

## 自动化测试要求

- Unit：构造内存清单验证三种质量分级。
- Integration：加载真实 `art_assets.json`，验证总数和逐项字段。
- Regression：数据完整性测试继续通过。

## 禁止事项

- 不修改 `Main.gd`、战斗数据或任何现有美术资源。
- 不引入第三方依赖。
- 不在实现技能阶段 commit/push。
