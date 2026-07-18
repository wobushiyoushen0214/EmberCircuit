# 调试报告

## Session 1

### 失败信号

- 复现命令：`HOME=/tmp/ember018c_tdd_outcome_green /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_ui_outcome_settings_compendium.gd`
- 原文（堆栈/断言/退出码）：

```text
Parse Error: Cannot infer the type of "terminal_outcome_open" variable because the value doesn't have a set type.
at: res://scripts/main/Main.gd:2586
Parse Error: Cannot infer the type of "menu_shell_active" variable because the value doesn't have a set type.
at: res://scripts/main/Main.gd:2587
```

- 是否稳定复现：是

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读栈 | `scripts/main/Main.gd:2586-2587` 的两个局部布尔变量 |

### 假设记录

| 轮次 | 假设（具体到变量/分支/契约） | 验证方式 | 结论(成立/证伪) |
| --- | --- | --- | --- |
| 1 | `combat` 为动态类型，使含 `combat.phase` 的布尔表达式无法静态推断局部变量类型 | 对照报错行与 `var combat` 声明 | 成立 |

已排除项：

- 测试脚本语法错误；堆栈明确指向 Main 局部变量推断。

### 修复

- 根因：动态 `combat` 表达式没有为局部布尔变量提供可推断的静态类型。
- 改动位置（一处）：`scripts/main/Main.gd:2586-2587`
- 重跑原失败命令结果：绿

### 防御性回归

- 这个 bug 能否从别处再发生：不能；显式类型将该局部推断问题封闭，项目导入门会覆盖同类解析错误。

### 退出状态

- [x] 绿了，回到 TDD 循环失败的那一步
- [ ] 已回滚，升级（附已排除项）
- [ ] 超 3 轮，升级强模型/人工

## Session 3

### 失败信号

- 复现命令：`HOME=/tmp/ember018c_outcome_runflow /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_run_flow.gd`
- 原文（堆栈/断言/退出码）：`Object is locked and can't be freed`，堆栈指向 `AppShell.gd:76`，由 OutcomePage 按钮 signal 触发。
- 是否稳定复现：是

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读栈 | 脱离场景树运行的 AppShell 在 signal 回调中走 `page.free()` 分支 |

### 假设记录

| 轮次 | 假设（具体到变量/分支/契约） | 验证方式 | 结论(成立/证伪) |
| --- | --- | --- | --- |
| 1 | 同步 `free()` 正在发射按钮 signal 的 OutcomePage 导致对象锁错误 | 堆栈同时指向 `_release_active_page` 与 OutcomePage lambda | 成立 |

### 修复

- 根因：AppShell 在树外分支同步释放正在发射 signal 的页面。
- 改动位置（一处）：`scripts/ui/AppShell.gd:_release_active_page`
- 重跑原失败命令结果：绿

### 防御性回归

- 这个 bug 能否从别处再发生：不能；所有 AppShell 页面统一帧末释放。

### 退出状态

- [x] 绿了，回到 TDD 循环失败的那一步
- [ ] 已回滚，升级（附已排除项）
- [ ] 超 3 轮，升级强模型/人工

## Session 2

### 失败信号

- 复现命令：`HOME=/tmp/ember018c_outcome_bounds /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_visual_bounds.gd`
- 原文（堆栈/断言/退出码）：

```text
Horizontal overflow: ScrollContainer rect=[P: (14.0, 69.0), S: (1268.0, 576.0)] viewport=1280.0
Test failed: default PC completion visible sections fit width
Test failed: default PC completion actions stay inside reward viewport
```

- 是否稳定复现：是

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读栈 | `Main.gd:3970` 把兼容副本内容宽度直接设为 scroll 内容宽；`ForgeTheme.panel_style` 还增加左右各 8px 内容边距 |

### 假设记录

| 轮次 | 假设（具体到变量/分支/契约） | 验证方式 | 结论(成立/证伪) |
| --- | --- | --- | --- |
| 1 | 兼容 OutcomePage 未扣除 PanelContainer 的 16px 水平内容边距，反向撑宽隐藏的 reward_scroll | 将兼容宽度减少 16px 后原命令仍同样失败 | 证伪，改动已回滚 |

已排除项：

- AppShell 可见页宽度；失败节点位于旧 `root_box/reward_scroll` 兼容树。

### 修复

- 根因：旧视觉测试仍把终局定义为 `reward_row` 子树，与 018C 的 AppShell 全屏契约冲突；隐藏副本组合高度也天然超过旧视口。
- 改动位置：删除隐藏兼容副本，并将终局边界断言迁移到 `app_shell.active_page`。
- 重跑原失败命令结果：绿

### 防御性回归

- 这个 bug 能否从别处再发生：不能；视觉边界测试已直接覆盖胜利和战败的 AppShell 页面。

### 退出状态

- [x] 绿了，回到 TDD 循环失败的那一步
- [ ] 已回滚，升级（附已排除项）
- [ ] 超 3 轮，升级强模型/人工

## Session 4

### 失败信号

- 复现命令：第二次运行 `render_pc_gallery.gd` 后执行 `verify_ui_visual_regression.gd`。
- 原文：`02_combat_720p` 的 `stage` changed ratio 5.42%，`hand` 11.98%；其余 10 页全部通过。
- 是否稳定复现：是；连续两轮图库只有战斗页随机区域变化。

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读栈/搜索 | `CombatState.gd:_build_starting_deck` 使用全局 `Array.shuffle()`；`render_pc_gallery.gd:_capture` 未固定全局随机种子 |

### 假设记录

| 轮次 | 假设（具体到变量/分支/契约） | 验证方式 | 结论(成立/证伪) |
| --- | --- | --- | --- |
| 1 | 每次截图前未重置全局 RNG，导致初始手牌和相关战斗呈现变化 | 变化仅发生于含洗牌的战斗页，其他确定性页面像素一致 | 成立 |

### 修复

- 根因：图库截图夹具没有在每个 capture 前固定全局 RNG。
- 改动位置（一处）：`tools/render_pc_gallery.gd:_capture`
- 重跑原失败命令结果：绿；11 页全部通过，最大 changed pixel ratio 为 0。

### 防御性回归

- 这个 bug 能否从别处再发生：不能；所有图库 capture 共用该入口并逐次重置 seed。

### 退出状态

- [x] 绿了，回到 TDD 循环失败的那一步
- [ ] 已回滚，升级（附已排除项）
- [ ] 超 3 轮，升级强模型/人工

## Session 5

### 失败信号

- 复现命令：`HOME=/tmp/ember018c_combat_layout_green ... --script res://tests/test_visual_bounds.gd`
- 原文：1600×900 战斗页 `TextureRect` global rect 为 `(30,64,1629,543)`，越出右边界。
- 是否稳定复现：是。

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 加一行布局探针 | 越界节点是 `enemy_stage_stack` 的 `battle_background`，`EXPAND_FIT_WIDTH_PROPORTIONAL + KEEP_ASPECT_COVERED` 在加高舞台后反向扩大控件宽度 |

### 假设记录

| 轮次 | 假设（具体到变量/分支/契约） | 验证方式 | 结论(成立/证伪) |
| --- | --- | --- | --- |
| 1 | 背景 TextureRect 的比例 expand mode 改变了控件最小宽度，而不是仅裁切纹理 | 探针确认唯一相关越界节点、expand=3/stretch=6 | 成立 |

### 修复

- 根因：全锚点背景仍使用按比例扩展控件尺寸的 expand mode。
- 改动位置（一处）：`scripts/main/Main.gd` 的 `battle_background.expand_mode`。
- 重跑原失败命令结果：绿。

### 防御性回归

- 这个 bug 能否从别处再发生：不能；PC 720p/900p 边界测试覆盖背景全锚点尺寸。

### 退出状态

- [x] 绿了，回到 TDD 循环失败的那一步
- [ ] 已回滚，升级（附已排除项）
- [ ] 超 3 轮，升级强模型/人工

## Session 6

### 失败信号

- 复现命令：`HOME=/tmp/ember018c_combat_runflow ... --script res://tests/test_run_flow.gd`
- 原文：`PC combat uses a large stage and compact log strip` 断言失败。
- 是否稳定复现：是。

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读栈 | `test_run_flow.gd:567` 仍要求 PC 战斗舞台 `<=430px`，与新贴底布局的 449px 动态舞台冲突 |

### 假设记录

| 轮次 | 假设（具体到变量/分支/契约） | 验证方式 | 结论(成立/证伪) |
| --- | --- | --- | --- |
| 1 | 失败来自已被用户新需求取代的固定上限，而非页面越界 | `test_visual_bounds` 已证明 720p/900p 贴底且不越界 | 成立 |

### 修复

- 根因：旧回归把大舞台误写成 430px 上限。
- 改动位置（一处）：`tests/test_run_flow.gd:567` 改为动态舞台下限 + 视口上限。
- 重跑原失败命令结果：绿。

### 防御性回归

- 这个 bug 能否从别处再发生：不能；visual bounds 同时保护贴底、舞台/手牌顺序和全视口边界。

### 退出状态

- [x] 绿了，回到 TDD 循环失败的那一步
- [ ] 已回滚，升级（附已排除项）
- [ ] 超 3 轮，升级强模型/人工
