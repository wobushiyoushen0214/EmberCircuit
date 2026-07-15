# 调试报告

## Session 1

### 失败信号

- 复现命令：`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_data_integrity.gd`
- 原文：`Test failed: event art slot <id> has stable replacement slot_path`，四个新位图事件均触发，退出码 1。
- 是否稳定复现：是。

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读栈 | `tests/test_data_integrity.gd:369-372` 要求事件 `slot_path` 以稳定的 `res://assets/art/events/` 前缀开头。 |
| 对照基线 | `data/config/art_assets.json` 四个新位图槽把 `asset_path` 和 `slot_path` 同时改成了 `assets/art/generated/events/`。 |

### 假设记录

| 轮次 | 假设（具体到变量/分支/契约） | 验证方式 | 结论 |
| --- | --- | --- | --- |
| 1 | 新位图只应替换 `asset_path`，长期替换契约的 `slot_path` 必须保留原事件资源路径。 | 对照失败断言、当前 JSON 与 `HEAD` 基线值。 | 成立。 |

已排除项：

- 位图尺寸、通道、导入或加载失败；同一轮严格资源审计已经通过这些检查。

### 修复

- 根因：把当前运行资源路径误当成了长期稳定替换槽位。
- 改动位置（一处）：`data/config/art_assets.json` 四个生产事件项的 `slot_path`。
- 重跑原失败命令结果：绿。

### 防御性回归

- 这个 bug 能否从别处再发生：能。
- 现有 `tests/test_data_integrity.gd::_validate_art_slot()` 已遍历全部资源槽并检查分类前缀，无需新增重复测试。

### 退出状态

- [x] 绿了，回到完整交付验证。
- [ ] 已回滚，升级。
- [ ] 超 3 轮，升级强模型/人工。
