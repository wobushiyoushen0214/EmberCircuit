# 美术资源完整性审计器 TDD 进度

## 进度表

| AC ID | 期望可观察结果 | 测试文件 | 测试命令 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- |
| AC-008-01 | 五类槽位全部收集且 total 等于数组长度总和 | `tests/test_art_asset_auditor.gd` | Godot headless test | done | 真实清单与内存夹具均通过 |
| AC-008-02 | PNG/SVG/缺失路径分别归入三档且计数守恒 | `tests/test_art_asset_auditor.gd` | Godot headless test | done | 三档分类和优先级通过 |
| AC-008-03 | 报告含 summary/items 且逐项字段、优先级完整 | `tests/test_art_asset_auditor.gd` | Godot headless test | done | CLI JSON 与逐项字段通过 |

## 收尾核对

- [x] 所有 AC 状态为 `done`。
- [x] 无任何 AC 停留在 `red` / `green`。
- [x] `prd.md` 自检命令全集最后一次运行全绿。
- [x] 已执行最小实现收敛。
- [x] `design.md` 挂载点清单逐项已接线。
- [ ] 未 commit；改动已暂存，等待双阶段评审。

## 最小实现收敛

- 删除项：无；实现仅保留单一审计入口和单一 CLI 入口
- 复用项：Godot JSON、FileAccess 与 ResourceLoader
- 保留项：缺失路径分类、字段完整性和计数守恒回归保护
- `trellis-minimal:` 注释：无
