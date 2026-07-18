# TDD 进度：Batch 018C

| AC | 期望可观察结果 | 测试/证据 | 状态 | 备注 |
| --- | --- | --- | --- | --- |
| AC-018C-01/02 | 胜败页面独立挂载，旧节点/probe 和终局失败重试语义不变 | `test_ui_outcome_settings_compendium.gd`, `test_playtest_run_integration.gd`, `test_run_flow.gd` | done | OutcomePage 初始 RED；Main 继续持有唯一存档/遥测编排 |
| AC-018C-03/04 | settings v2 迁移、默认、clamp、未知字段清理与即时保存 | `test_save_manager.gd`, `test_ui_outcome_settings_compendium.gd` | done | migration/clamp 初始 RED，0.25 步长已覆盖 |
| AC-018C-05/06 | 设置四组控件与图鉴六分类/搜索/筛选/排序/模板/未发现保护可用 | `test_ui_outcome_settings_compendium.gd` | done | 未发现 VM 不传真实名称、正文、数值或 tooltip |
| AC-018C-07/08 | motion policy、键盘焦点、44px 热区、对比度和 Escape 返回稳定 | `test_ui_accessibility_motion.gd` | done | reduced motion 关闭位移/缩放/持续粒子并保留 opacity 确认 |
| AC-018C-09/10 | 11 页 1280x720 区域视觉回归稳定且截图确定性可重复 | `verify_ui_visual_regression.gd`, `tests/golden/ui_720p/*` | done | 固定 `seed(0xEC018C)`；最终 11 页全绿，最大 changed ratio 0 |
| AC-018C-11 | 粒子/tween/节点/输入/帧预算达标 | `test_ui_performance_budget.gd`, `/tmp/embercircuit-ui-performance.json` | done | macOS Apple M4：p95 14.201ms，1% low 66.88 FPS，输入 20.432ms，节点增量 0；Windows release 待目标机复测 |
| AC-018C-12 | 项目导入、全部 Godot 测试与严格错误日志扫描全绿 | `tests/test_*.gd`, Godot editor import | done | 28/28 测试通过，无脚本错误、断言失败或节点泄漏 |

## 收尾核对

- [x] 所有 AC 状态为 `done`。
- [x] 无任何 AC 停留在 `red` / `green`。
- [x] `prd.md` 可在当前 macOS 环境执行的自检命令最后一次运行全绿。
- [x] 已执行最小实现收敛并重跑定向及全量回归。
- [x] `design.md` 四个挂载点已接线。
- [x] 改动等待双阶段评审后提交。

## 最小实现收敛

- 删除项：移除 `Main.gd` 中已无调用的旧胜利、战败和图鉴视觉构造树及样式函数，避免新旧页面双实现。
- 复用项：复用 `ForgeTheme`、`ForgeMotion`、`AppShell`、现有 SaveManager 原子保存和既有 Main 终局回调。
- 保留项：保留旧终局节点名、全部 `last_*` probe、终局 receipt/telemetry/save 顺序、失败重试及未发现信息保护。
- `trellis-minimal:` 注释：无。
