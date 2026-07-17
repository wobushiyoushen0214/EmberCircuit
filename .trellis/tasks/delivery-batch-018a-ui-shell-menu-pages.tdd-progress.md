# TDD 进度：Batch 018A

| AC | 测试 | 状态 |
| --- | --- | --- |
| AC-018A-01 | `test_forge_ui_foundation.gd` | done |
| AC-018A-02 | `test_forge_ui_foundation.gd` | done |
| AC-018A-03 | `test_welcome_character_pages.gd` | done |
| AC-018A-04 | `test_welcome_character_pages.gd` | done |
| AC-018A-05 | `test_run_flow.gd` | done |
| AC-018A-06 | `test_visual_bounds.gd` | done |
| AC-018A-07 | 全量严格回归 | done |
| AC-018A-08 | Stage 1/Stage 2 review | done |

## 实现证据

- AC-018A-01/02 RED：新 foundation preload 缺少 `ForgeTheme/ForgeMotion/AppShell/组件` 文件；GREEN：新增 token/motion JSON、typed helper、focus/44px 组件，`test_forge_ui_foundation.gd` 通过。
- AC-018A-03/04 RED：Welcome/Character 页面 preload 缺失；GREEN：新增页面 API、primary/secondary/tool 层级、禁用原因、三角色、挑战轨道、预览/确认信号，`test_welcome_character_pages.gd` 通过。
- AC-018A-05 GREEN：`Main.gd` 创建 AppShell 并将页面 VM/信号接入原回调；`test_run_flow.gd` 通过。
- AC-018A-06 GREEN：1280×720、1600×900 PC 页面边界与同排名册通过；390×640、540×540 仅保留外层有界/关键动作可达的兼容烟测，正式视觉金标按用户决定限定为 PC 桌面。
- AC-018A-07 GREEN：动态执行全部 24 个 `tests/test_*.gd`，24/24 exit 0；除 macOS 系统 CA 查询提示外，无未知 `ERROR:`、`SCRIPT ERROR`、失败断言、leaked/still-in-use。
- AC-018A-08 GREEN：Review Round 1 C0/M2/m1；逐条 RED→GREEN 修复 motion clamp、reduced-motion 持续 tween、锁定挑战交互语义；Review Round 2 C0/M0/m0 放行。

## 最小实现收敛

- 复用 Godot `Control`/`Container`/`StyleBoxFlat` 和现有 Main reward host，未引入第三方依赖。
- 页面通过 `AppShell.mount_page` 保留完整页面根节点；Main 仅协调状态、view model、信号和旧 probe。
- 保留 unknown token fallback、reduced-motion、44px interactive minimum 和 disabled reason，不删除旧回调/状态保护。
- 删除 Welcome VM 中 5 个已无消费的图标加载字段、角色页死宽度变量，以及 Main 内整套未调用的旧角色卡/挑战条构造函数；未引入第三方依赖或未来扩展抽象。
- `ForgeMotion.duration` 统一 clamp 80–320ms；reduced-motion 禁止菜单背景持续循环；锁定挑战同步 disabled 光标/焦点语义。
- 已执行 foundation/page/run-flow/visual-bounds、自检导入、24-suite 全量严格回归与双阶段评审，全部通过。

实现者不得自行标记完成；每条 AC 必须先 RED、再 GREEN、再回归。
