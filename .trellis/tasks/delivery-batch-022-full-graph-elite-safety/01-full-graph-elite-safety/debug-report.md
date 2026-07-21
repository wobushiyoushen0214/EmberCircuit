# 调试报告

## Session 1

### 失败信号

- 复现命令：`HOME=/tmp/ember022_ac04_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_simulator.gd`
- 原文：`Test failed: v3 falls back to the deterministic legacy score when no safe Boss route exists`，`tests/test_balance_simulator.gd:1586`，退出码 1。
- 是否稳定复现：是。

### 定位过程

| 用了哪招 | 结果 |
| --- | --- |
| 读栈 | 失败只指向 all-unsafe fixture 的具体候选期望，第二条“选择非空”断言通过；范围缩小到 `all_unsafe_choice` 的实际 node id 与旧评分 tie-break。 |

### 假设记录

| 轮次 | 假设 | 验证方式 | 结论 |
| --- | --- | --- | --- |
| 1 | 两条浅层精英都在 legacy depth=3 内被硬拒绝，实际进入稳定 node-id tie-break 并选择 `all_unsafe_event`，fixture 错把节点基础分当成最终 route score | 在失败断言前临时打印 `all_unsafe_choice` 并重跑原命令 | 成立；实际值为 `all_unsafe_event` |

### 修复

- 根因：fixture 忽略了旧 `_campaign_route_preview_score` 已在 depth=3 内看到两条不安全精英；两个 route score 都是 hard reject，competent profile 按稳定 node id 选择 `all_unsafe_event`。
- 改动位置：`tests/test_balance_simulator.gd` 的 AC-022-04 确定期望；删除临时日志并将期望改为 `all_unsafe_event`，不改生产实现。
- 重跑结果：原失败命令 GREEN，`Balance simulator smoke test passed.`。

### 防御性回归

- 这个 bug 不能从生产入口发生；它是局部 fixture 对旧 route score 契约的误读，第二条非空断言继续保护真实 AC。

### 退出状态

- [x] 绿了，回到 TDD 循环
- [ ] 已回滚，升级
- [ ] 超 3 轮，升级
