# 调试报告

## Session 1

### 失败信号

- 复现命令：`HOME=/tmp/ember022_ac08_green /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_simulator.gd`
- 原文：`SCRIPT ERROR: Parse Error: Expected statement, found "Indent" instead.`，`tests/test_balance_simulator.gd:1886`。
- 是否稳定复现：是；进程退出码异常为 0，但严格日志判定失败。

### 定位过程

| 用了哪招 | 结果 |
| --- | --- |
| 读栈 | `tests/test_balance_simulator.gd:1886` 的 `if profile == "competent-player-v3"` 比相邻 profile 变量多一个 tab。 |

### 假设记录

| 轮次 | 假设 | 验证方式 | 结论 |
| --- | --- | --- | --- |
| 1 | 单行多余缩进导致 GDScript parser 在无新 block 处遇到 Indent | 用 `sed -n ...l` 查看 tab 层级并与 1884-1885 对比 | 成立 |

### 修复

- 根因：AC-022-08 最小迁移补丁给条件块多加一层 tab。
- 改动位置：`tests/test_balance_simulator.gd:1886`。
- 重跑原失败命令结果：GREEN，`Balance simulator smoke test passed.`，无 SCRIPT ERROR。

### 防御性回归

- 这个 bug 能否从别处再发生：不能；它是局部补丁语法错误，editor/import 与严格日志自检会封闭。

### 退出状态

- [x] 绿了，回到 TDD 循环失败的那一步
- [ ] 已回滚，升级
- [ ] 超 3 轮，升级强模型/人工
