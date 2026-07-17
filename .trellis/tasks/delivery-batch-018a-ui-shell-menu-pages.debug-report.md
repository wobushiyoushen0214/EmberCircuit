# 调试报告

## Session 1

### 失败信号

- 复现命令：`HOME=/tmp/ember018a_tdd_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_welcome_character_pages.gd`
- 原文（堆栈/断言/退出码）：

```text
SCRIPT ERROR: Parse Error: The variable type is being inferred from a Variant value, so it will be typed as Variant. (Warning treated as error.)
          at: GDScript::reload (res://scripts/ui/components/CharacterStageCard.gd:204)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
```

- 是否稳定复现：是

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读栈 | `scripts/ui/components/CharacterStageCard.gd:204` 的 `crop_height := min(...)` |

### 假设记录

| 轮次 | 假设（具体到变量/分支/契约） | 验证方式 | 结论(成立/证伪) |
| --- | --- | --- | --- |
| 1 | 通用 `min()` 返回 `Variant`，`:=` 触发项目的 warning-as-error 契约 | 对照编译器原文与 199–209 行静态类型 | 成立 |

已排除项：

- 无；编译器已直接定位类型契约。

### 修复

- 根因：`crop_height` 使用通用 `min()` 做隐式类型推断。
- 改动位置（一处）：`scripts/ui/components/CharacterStageCard.gd:204`
- 重跑原失败命令结果：绿（`PASS: welcome character pages`）

### 防御性回归

- 这个 bug 能否从别处再发生：能，新增 GDScript 中通用泛型函数与 `:=` 组合都可能触发严格编译警告。
- 若能：已在 Batch 018A `check.jsonl` 记录严格编译回归点，回归测试为 `tests/test_welcome_character_pages.gd`。

### 退出状态

- [x] 绿了，回到 TDD 循环失败的那一步
- [ ] 已回滚，升级（附已排除项）
- [ ] 超 3 轮，升级强模型/人工

## Session 4

### 失败信号

- 复现命令：`HOME=/tmp/ember018a_run_check /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_run_flow.gd`
- 原文（堆栈/断言/退出码）：

```text
SCRIPT ERROR: Invalid access to property or key 'custom_minimum_size' on a base object of type 'null instance'.
          at: _run (res://tests/test_run_flow.gd:260)
```

- 是否稳定复现：是

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读栈 | `compact_roster` 由页面根节点非递归查找；实际层级是 `CharacterRosterScroll/CharacterRoster` |

### 假设记录

| 轮次 | 假设（具体到变量/分支/契约） | 验证方式 | 结论(成立/证伪) |
| --- | --- | --- | --- |
| 1 | compact roster 探针使用了错误父节点 | 对照 `_build_roster` 的嵌套结构 | 成立 |

### 修复

- 根因：测试把嵌套 HBox 当作页面直接子节点。
- 改动位置（一处）：`tests/test_run_flow.gd:256`。
- 重跑原失败命令结果：绿（`Run flow smoke test passed.`）

### 防御性回归

- 这个 bug 能否从别处再发生：能；节点探针必须区分直接路径与递归查找。
- 若能：欢迎/角色页面测试已有结构断言。

### 退出状态

- [x] 绿了，回到 TDD 循环失败的那一步
- [ ] 已回滚，升级（附已排除项）
- [ ] 超 3 轮，升级强模型/人工

## Session 2

### 失败信号

- 复现命令：`HOME=/tmp/ember018a_run_check /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_run_flow.gd`
- 原文（堆栈/断言/退出码）：

```text
SCRIPT ERROR: Cannot call method 'get_node_or_null' on a previously freed instance.
          at: _run (res://tests/test_run_flow.gd:92)
```

- 是否稳定复现：是

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读栈 | `tests/test_run_flow.gd:70–92`：第 70 行缓存页面，第 80/83 行两次预览均会刷新并替换 AppShell 页面，第 92 行仍访问旧实例 |

### 假设记录

| 轮次 | 假设（具体到变量/分支/契约） | 验证方式 | 结论(成立/证伪) |
| --- | --- | --- | --- |
| 1 | `character_page` 在 `_on_character_preview_selected()` 后成为已释放实例 | 对照调用序列、AppShell 页面替换契约与报错行 | 成立 |

已排除项：

- 不是生产页面生命周期错误；AppShell 正确释放被替换页面，测试持有陈旧引用。

### 修复

- 根因：测试未在刷新后重新读取活动页面。
- 改动位置（一处）：`tests/test_run_flow.gd` 第二次预览之后。
- 重跑原失败命令结果：陈旧实例错误已消失；命令继续到下一条独立旧断言（Session 3）。

### 防御性回归

- 这个 bug 能否从别处再发生：能，任何触发 `_refresh()` 的测试步骤都不能继续持有旧页面引用。
- 若能：现有 `tests/test_run_flow.gd` 将作为回归入口；待转绿后更新结果。

### 退出状态

- [ ] 绿了，回到 TDD 循环失败的那一步
- [ ] 已回滚，升级（附已排除项）
- [ ] 超 3 轮，升级强模型/人工

## Session 3

### 失败信号

- 复现命令：`HOME=/tmp/ember018a_run_check /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_run_flow.gd`
- 原文（堆栈/断言/退出码）：

```text
ERROR: Test failed: character selection keeps character stages in a bounded viewport
       [1] _run (res://tests/test_run_flow.gd:93)
```

- 是否稳定复现：是

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读栈 | `tests/test_run_flow.gd:93` 要求桌面 `CharacterRosterScroll`；`CharacterSelectPage._build_roster` 明确只在 compact 创建 Scroll，桌面创建 `HFlowContainer CharacterRoster` |

### 假设记录

| 轮次 | 假设（具体到变量/分支/契约） | 验证方式 | 结论(成立/证伪) |
| --- | --- | --- | --- |
| 1 | 测试仍引用旧/紧凑布局的 ScrollContainer 契约 | 对照 `_build_roster` 分支及当前桌面节点探针 | 成立 |

已排除项：

- 不是桌面名册缺少边界；新 720p 布局实测为 `1240×548` 且三卡均在同一行。

### 修复

- 根因：桌面流程断言使用了 compact-only 节点。
- 改动位置（一处）：`tests/test_run_flow.gd:93`。
- 重跑原失败命令结果：绿（`Run flow smoke test passed.`）

### 防御性回归

- 这个 bug 能否从别处再发生：能；desktop/compact 探针必须分别对应 HFlow/Scroll 契约。
- 若能：`tests/test_welcome_character_pages.gd` 已分别覆盖两种布局。

### 退出状态

- [x] 绿了，回到 TDD 循环失败的那一步
- [ ] 已回滚，升级（附已排除项）
- [ ] 超 3 轮，升级强模型/人工

## Session 5

### 失败信号

- 复现命令：`HOME=/tmp/ember018a_bounds_check /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_visual_bounds.gd`
- 原文（首个失败）：

```text
ERROR: Test failed: compact character select reward area stays above bottom controls
       [1] _run (res://tests/test_visual_bounds.gd:34)
```

- 是否稳定复现：是

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读栈 | `tests/test_visual_bounds.gd:28–35` 在欢迎页检查已隐藏的 legacy `page_scroll/reward_scroll/controls_scroll`，没有读取 `app_shell.active_page` |

### 假设记录

| 轮次 | 假设（具体到变量/分支/契约） | 验证方式 | 结论(成立/证伪) |
| --- | --- | --- | --- |
| 1 | compact 菜单边界测试仍绑定旧 reward-flow 宿主 | 对照 Main `_set_menu_shell_active()` 与当前 AppShell 节点 | 成立 |

### 修复

- 根因：边界测试没有沿当前 AppShell 欢迎→角色路径采样。
- 改动位置（一处）：`tests/test_visual_bounds.gd:28–35` compact 菜单块。
- 重跑原失败命令结果：compact 块通过；命令继续到 1600×900 的独立旧探针（Session 6）。

### 防御性回归

- 这个 bug 能否从别处再发生：能；其他 viewport 块也必须从 `app_shell.active_page` 取菜单节点。
- 若能：本测试将按 compact/1600×900/1280×720 三块逐步迁移。

### 退出状态

- [ ] 绿了，回到 TDD 循环失败的那一步
- [ ] 已回滚，升级（附已排除项）
- [ ] 超 3 轮，升级强模型/人工

## Session 6

### 失败信号

- 复现命令：`HOME=/tmp/ember018a_bounds_check /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_visual_bounds.gd`
- 原文（首个失败）：

```text
ERROR: Test failed: desktop welcome page exposes complete primary navigation
       [1] _run (res://tests/test_visual_bounds.gd:142)
```

- 是否稳定复现：是

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读栈 | 1600×900 块仍断言 3 个欢迎操作、从 `reward_row` 查页、断言 3 个挑战；当前契约为 AppShell/5 操作/4 挑战 |

### 假设记录

| 轮次 | 假设（具体到变量/分支/契约） | 验证方式 | 结论(成立/证伪) |
| --- | --- | --- | --- |
| 1 | desktop 边界块整体绑定旧 reward-flow 页面契约 | 对照 Main 计数、AppShell 活动页和页面节点 | 成立 |

### 修复

- 根因：1600×900 视口探针未迁移到新页面宿主。
- 改动位置（一处）：`tests/test_visual_bounds.gd` desktop 菜单块。
- 重跑原失败命令结果：1600×900 块通过；命令继续到 1280×720 的独立旧探针（Session 7）。

### 防御性回归

- 这个 bug 能否从别处再发生：能；1280×720 块仍需独立迁移。
- 若能：继续保留三档视口的结构与边界断言。

### 退出状态

- [ ] 绿了，回到 TDD 循环失败的那一步
- [ ] 已回滚，升级（附已排除项）
- [ ] 超 3 轮，升级强模型/人工

## Session 7

### 失败信号

- 复现命令：`HOME=/tmp/ember018a_bounds_check /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_visual_bounds.gd`
- 原文（首个失败）：

```text
ERROR: Test failed: default PC character select renders all three character cards
       [1] _run (res://tests/test_visual_bounds.gd:201)
SCRIPT ERROR: Cannot call method 'get_children' on a null value.
       at: _children_share_row (res://tests/test_visual_bounds.gd:502)
```

- 是否稳定复现：是

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读栈 | 1280×720 块从隐藏的 `reward_row` 查 `CharacterSelectPage`，得到 null 后传给同排检查 |

### 假设记录

| 轮次 | 假设（具体到变量/分支/契约） | 验证方式 | 结论(成立/证伪) |
| --- | --- | --- | --- |
| 1 | default-PC 探针仍绑定旧页面宿主和不可见工具条 | 对照活动 AppShell 页面及 720p 实图 | 成立 |

### 修复

- 根因：1280×720 菜单边界测试未迁移到当前可见节点树。
- 改动位置（一处）：`tests/test_visual_bounds.gd` default-PC 菜单块。
- 重跑原失败命令结果：绿（`Visual bounds smoke test passed.`）；随后 24-suite 全量严格回归 24/24 通过。

### 防御性回归

- 这个 bug 能否从别处再发生：不能；compact、1600×900、1280×720 三个菜单块均已迁移。

### 退出状态

- [x] 绿了，回到 TDD 循环失败的那一步
- [ ] 已回滚，升级（附已排除项）
- [ ] 超 3 轮，升级强模型/人工
