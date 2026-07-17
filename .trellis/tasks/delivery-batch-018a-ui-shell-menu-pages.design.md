# Design: Batch 018A 暗炉 UI Shell 与菜单页

## 需求覆盖

| 需求 | 当前 | 设计元素 | 预期 |
| --- | --- | --- | --- |
| REQ-008 | PARTIAL | token、AppShell、欢迎页、角色页 | PARTIAL→可继续迁移 |
| REQ-012 | PARTIAL | foundation/structure/bounds tests | 新页面契约有自动化证据 |

## MVP 兼容性契约

| 行为 | 证据 | 保留 | 回归 |
| --- | --- | --- | --- |
| 预览角色不启动跑团 | `Main.gd:_on_character_preview_selected` | 是 | `test_welcome_character_pages.gd` |
| 确认角色调用真实 start flow | `Main.gd:_on_character_confirm_pressed` | 是 | `test_run_flow.gd` |
| 旧 probe/node name | `tests/test_run_flow.gd`, `tests/test_visual_bounds.gd` | 是 | 全量 regression |

## 决策表

| 决策 | 选择 | 排除 | 原因 |
| --- | --- | --- | --- |
| PageHost | 动态 `AppShell.page_host` | 多 Scene 切换 | 保持 Main.tscn 与旧测试兼容 |
| 页面数据 | Dictionary view model | 页面直接读取全局 JSON | 编排/显示分离 |
| 样式 | `ForgeTheme` typed token | 页面内 Color 常量 | 防止跨页漂移 |
| 动效 | `ForgeMotion` 单一入口 | 页面各自 Tween | reduced-motion 一致 |

## 契约

- `ForgeTheme.color(id,fallback)`、`spacing(id)`、`font_size(id)`、`panel_style(variant)`、`button_style(state)`。
- `ForgeMotion.page_enter(control, reduced_motion)`、`press_scale(control, pressed, reduced_motion)`；reduced motion 不改变 layout bounds。
- `AppShell.mount_page(page,page_id)`、`clear_page()`、`set_context(title,subtitle)`；同一时刻只有一个 active page。
- `WelcomePage.configure(model)` 发出 `new_run_requested`、`continue_requested`、`archive_requested`。
- `CharacterSelectPage.configure(model)` 发出 `character_preview_requested`、`challenge_delta_requested`、`confirm_requested`、`back_requested`。

## 编排-计算分离

| 层 | 落点 |
| --- | --- |
| 编排层：页面路由、VM、旧回调、probe adapter | `scripts/main/Main.gd`, `scripts/ui/AppShell.gd` |
| 计算层：token lookup、duration clamp、page state rendering | `scripts/ui/ForgeTheme.gd`, `scripts/ui/ForgeMotion.gd`, page/component scripts |

## 挂载点

1. `Main._build_layout` 创建 AppShell。
2. `Main._refresh` 将 welcome/character VM 传给 PageHost。
3. Page signals 绑定 Main 原有 callbacks。
4. ForgeTheme/ForgeMotion 注入所有新组件样式和 motion。

## 非目标

- 不迁移地图及跑团页。
- 不修改 SaveManager/settings schema。
- 不删除 Main 旧节点/probe adapter。
