# 调试报告：018D-01

## Session 1

### 失败信号

- 复现命令：`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_ember_forge_route_rooms.gd`
- 原文：`FAIL: map page forwards exact preview title, risk, reward, description and successors`，退出码 1。
- 是否稳定复现：是，资产导入后连续两次同点失败。

### 定位过程

| 方法 | 结果 |
| --- | --- |
| 读栈/断言 | 缩小到 `MapPage.configure()` 后 `NodePreviewPanel` 的五个 `Preview*` label。 |

### 假设记录

| 轮次 | 假设 | 验证方式 | 结论 |
| --- | --- | --- | --- |
| 1 | `MapView` 在 `set_preview_details()` 后的布局或重建覆盖了显式详情 | 打印五个 label 实际值并与 VM 比对 | 证伪：五项 VM 均已转发 |
| 2 | 测试遗漏 `MapView` 既有的后继列表 `- ` 前缀 | 对比实际 `后续节点\n- 核心 [首领]` 与断言 | 成立 |

### 修复

- 根因：测试期望遗漏了 `MapView._refresh_preview_panel_text()` 的稳定列表符号。
- 改动位置：`tests/test_ember_forge_route_rooms.gd` 的后继精确文本断言。
- 重跑原失败命令结果：绿；随后 editor、route room、accessibility 全绿。

### 防御性回归

- 这个 bug 能否从别处再发生：不能；精确格式只由 `MapView` 一个公开渲染入口产生，已在现有回归测试中直接断言。

### 退出状态

- [x] 绿了，回到 TDD 循环失败的那一步
- [ ] 已回滚，升级
- [ ] 超 3 轮，升级强模型/人工

### 防御性回归结果

- Event、Shop store/remove、Campfire forge 的重复 `configure()` 断言先后复现稳定名丢失，均已在对应清理函数中先 detach 再 `queue_free()`，原 route-room 命令全绿。
- 未知 Shop/Campfire/Reward mode 的只读边界已加入同一 route-room 测试并全绿；没有遗留可从页面直接执行的业务入口。

## Session 2

### 失败信号

- 复现命令：`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_ember_forge_route_rooms.gd`
- 原文：`Cannot call method 'emit_signal' on a null value` at `tests/test_ember_forge_route_rooms.gd:271`。
- 是否稳定复现：是。

### 定位过程

| 方法 | 结果 |
| --- | --- |
| 读栈 | 第二次 `RewardPage.configure()` 后按稳定名找不到新 continue 按钮。 |

### 假设记录

| 轮次 | 假设 | 验证方式 | 结论 |
| --- | --- | --- | --- |
| 1 | `_clear_actions()` 只 `queue_free`，同帧重建时旧同名节点仍占名，新节点被自动重命名 | 打印第二次 configure 后 `_action_column` 子节点名 | 成立：新按钮名为 `@Button@34` |

### 修复

- 根因：动态子节点只 `queue_free()` 未先 detach，同帧同名重建触发 Godot 自动改名。
- 改动位置：`scripts/ui/pages/RewardPage.gd:_clear_actions()`。
- 重跑原失败命令结果：绿；editor、route room、accessibility 全绿。

### 防御性回归

- 这个 bug 能否从别处再发生：能；Event/Shop/Campfire 使用相同清理模式。已在 `check.jsonl` 记录并追加重复 configure 回归断言。

### 退出状态

- [x] 绿了，回到 TDD 循环失败的那一步
- [ ] 已回滚，升级
- [ ] 超 3 轮，升级强模型/人工
