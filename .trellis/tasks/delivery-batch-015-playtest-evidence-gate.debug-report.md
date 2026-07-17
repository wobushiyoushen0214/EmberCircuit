# Delivery Batch 015 调试报告

## Session 1

### 失败信号

- 复现命令：`Godot --headless --path . --script res://tests/test_playtest_evidence_gate.gd`
- 稳定复现：是。
- 原文：`PlaytestTelemetry.gd:469 The variable type is being inferred from a Variant value (Warning treated as error)`。

### 定位与假设

- 读栈直接定位到 `source_schema_version` 的 `max()` 推断。
- 假设：Godot 将 `max()` 返回视为 Variant，严格 warning 门要求显式 `int` 类型；查看行内容确认成立。

### 修复

- 仅把该变量声明改为 `var source_schema_version: int`。
- 防御性回归：同类 Variant 推断仍由全量脚本编译门保护，无需新增独立测试。

## Session 2

- 原失败重跑后稳定定位到 `PlaytestEvidenceGate.gd:72` 与 `:75` 的两个 `max()` 推断。
- 本轮只修 `:72` 的 `start` 为显式 `int`，随后重跑原命令。

## Session 3

- Session 2 重跑后只剩 `PlaytestEvidenceGate.gd:75` 同类警告，证明前一修复有效。
- 将 `abandoned_start` 声明为显式 `int`，这是同一已验证根因的最后入口。

## Session 4（独立自检事件）

- 失败：旧 telemetry 测试期待 `bounded-014` 为最新 96 局首项。
- 定位：夹具时间戳使用 `index % 60` 循环，按完成时间排序时不存在与插入顺序一致的“最新”。
- 修复：只把夹具改为按日/小时单调递增；生产实现不变。

## Session 5（AC-002 编译事件）

- 失败：`PlaytestEvidenceGate.gd:368-371` 四个 `max()` 结果被推断为 Variant。
- 定位：同一 `_finalize_card_aggregate` 计数块。
- 修复：四个派生计数显式声明为 `int`，不改计算公式。

## Session 6（集成回归事件）

- 失败：真实终局集成期望最新战败位于 `runs[-1]`，留存器在同秒按 `run_id` 重排。
- 根因：最终 `_sort_runs()` 不保留 store 插入顺序。
- 修复：选择配额后按原输入 sequence 恢复顺序；配额选择与 cohort 隔离不变。
