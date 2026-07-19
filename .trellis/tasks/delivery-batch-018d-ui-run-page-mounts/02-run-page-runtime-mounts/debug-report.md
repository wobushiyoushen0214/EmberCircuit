# 调试报告：018D-02

## Session 1

### 失败信号

- 复现命令：`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_visual_bounds.gd`
- 原文：PC event 的 stage/choice 四条 bounds 断言失败，退出码 1。
- 是否稳定复现：是。

### 定位过程

| 方法 | 结果 |
| --- | --- |
| 读栈 | `tests/test_visual_bounds.gd:438-444` 仍从 legacy `reward_row/reward_scroll` 查事件页。 |

### 假设记录

| 轮次 | 假设 | 验证方式 | 结论 |
| --- | --- | --- | --- |
| 1 | 生产 EventPage 已正确挂载，失败仅来自 bounds 根未迁移 | run-flow 的 active EventPage 与四选项断言已绿 | 成立 |

### 修复

- 根因：测试使用已废弃的 PC 事件布局根。
- 改动位置：`tests/test_visual_bounds.gd` PC event bounds 段。
- 重跑原失败命令结果：绿；随后本任务六套自检全绿。

### 防御性回归

- 这个 bug 能否从别处再发生：能；后续 Campfire/Shop/Reward 挂载时同步迁移对应 bounds 根。

### 退出状态

- [x] 绿了，回到 TDD 循环失败的那一步
- [ ] 已回滚，升级
- [ ] 超 3 轮，升级强模型/人工

## Session 2

### 失败信号

- 复现命令：`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_visual_bounds.gd`
- 原文：Campfire 的 arrival/forge/long-deck bounds 仍查 legacy 根；首次迁移另有 `Expected indented block` 语法错误。
- 是否稳定复现：是。

### 定位与修复

- 根因：bounds 根未迁到 `CampfirePage`，且迁移 patch 的 `for` 体缩进少一级。
- 单点修复：PC Campfire 从 `app_shell.active_page` 查 stage/list/internal scroll；修正循环缩进。
- 重跑原命令：绿；随后六套自检全绿。

### 防御性回归

- 长牌组仍断言所有真实 index 候选存在、内部可滚动、最后一项完整可达；未弱化覆盖。

### 退出状态

- [x] 绿了，回到 TDD 循环。

## Session 3

### 失败信号

- 原始自检命令：`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit`。
- 首次原文：`Failed to open user://logs/...` 后 Godot `signal 11`；立即重跑通过，因此该日志崩溃不可稳定复现，未据此修改代码。
- 稳定复现命令：`HOME=/tmp/ember018d_tdd_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit`。
- 稳定原文：`Function "_combat_reward_page_model()" not found` 与 `Function "_mount_reward_page()" not found`，位置 `scripts/main/Main.gd:11937`。

### 定位过程

| 方法 | 结果 |
| --- | --- |
| 读栈 + 检查 staged diff | `_refresh_rewards()` 已提前调用 AC-09 helper，但仓库中没有对应函数定义；默认 Godot 缓存曾掩盖解析失败。 |

### 假设记录

| 轮次 | 假设 | 验证方式 | 结论 |
| --- | --- | --- | --- |
| 1 | AC-09 的预写 mount 调用越过了当前 AC-08 边界，导致干净环境解析失败 | `rg` 查找函数定义并对照 cached/working diff | 成立：只有调用，没有定义。 |

### 修复

- 根因：在 AC-08 尚未完成自检时提前写入 AC-09 的调用，违反单 AC TDD 顺序。
- 改动位置：`scripts/main/Main.gd:_refresh_rewards()`，仅移除四行未实现的 PC reward mount 分支。
- 重跑原失败命令结果：绿；AC-09 保持 pending，后续从独立 RED 开始。

### 防御性回归

- 这个 bug 能否从别处再发生：能；已在 `check.jsonl` 记录用隔离 HOME 跑 editor parse，避免缓存掩盖未定义调用。

### 退出状态

- [x] 绿了，回到 TDD 循环失败的那一步
- [ ] 已回滚，升级
- [ ] 超 3 轮，升级强模型/人工

## Session 4

### 失败信号

- 复现命令：`HOME=/tmp/ember018d_tdd_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_run_flow.gd`。
- 原文：`PC combat reward hides legacy reward chrome`。

### 定位与修复

- 读栈确认 RewardPage 已挂载，最终覆盖点是 `_apply_pc_combat_chrome()` 把 `reward_scroll.visible` 重新设为 `true`。
- 单点修复：active page 为 `reward` 时不再显示 legacy reward scroll；保留非 PC 与未迁移路径。
- 重跑结果：combat reward 断言绿，测试继续推进到 treasure。

### 退出状态

- [x] 绿了，回到 TDD 循环。

## Session 5

### 失败信号

- 同一 run-flow 命令依次暴露 `PC treasure mounts RewardPage without combat reward chrome` 和 boss 奖励旧 `reward_row` 断言。

### 定位与修复

- treasure 根因：`_refresh_treasure()` 仍把 legacy reward region 设为可见；改为 PC RewardPage 模式时隐藏。
- boss 根因：测试仍要求旧 reward surface 可见；迁移为 active RewardPage、旧区隐藏、战场隐藏的等强断言。
- 重跑结果：`test_run_flow.gd` 通过。

### 防御性回归

- 两个入口均由同一 run-flow 覆盖 combat、treasure、boss 奖励，不再依赖旧视觉树。

### 退出状态

- [x] 绿了，回到 TDD 循环。

## Session 6

### 失败信号

- 复现命令：`HOME=/tmp/ember018d_tdd_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_visual_bounds.gd`。
- 原文：`default PC combat reward uses a dedicated action column`、`default PC combat rewards stay on one visual row`。

### 定位与修复

- 根因：bounds 测试仍从 legacy `reward_row` 查动作列并要求横向单行，而 RewardPage 契约为页内纵向动作列。
- 单点修复：从 active RewardPage 查 `RewardActionColumn/RewardActions`，断言页面在 1280×720 内、旧 scroll 隐藏、动作列横纵边界成立。
- 重跑结果：visual bounds 通过；随后隔离 HOME 的六套自检全绿且无脚本/测试失败文本。

### 防御性回归

- 这个 bug 能否从别处再发生：能；后续 018D-03 将继续以 active page 为视觉/性能根，不再从 legacy reward_row 取 PC 跑团页。

### 退出状态

- [x] 绿了，回到 TDD 循环。
