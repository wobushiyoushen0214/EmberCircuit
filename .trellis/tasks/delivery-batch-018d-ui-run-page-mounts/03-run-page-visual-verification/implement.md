# Implementation Plan: 018D-03

## 结构健康度预检

| 文件 | 当前 | 阈值 | 微重构 |
| --- | --- | --- | --- |
| Main.gd | 约 14k 行 | 400 | 是：只删无调用旧视觉 helper，不搬业务 |
| gallery/profiler | 约 200 行 | 400 | 否 |
| visual test | 大型 integration | 400 | 否，沿现有页面分段追加 |

## 有序步骤

1. rg + RED 测试锁定旧 root/helper，删除一组、跑一组回归。
2. 更新 gallery/contract，生成五张候选图，人工看图后更新金标。
3. 扩展 profiler route loop，跑 600 帧。
4. 全量严格回归；文档；进度；最小实现；评审交接。

## 修改边界

- 仅 PRD File Manifest 和本任务进度/调试/评审产物。
- 禁止 data、page contract、business callback、SaveManager、CombatState、telemetry。

## 失败恢复

- visual diff：先查 seed/page state/viewport/字体，不改阈值；确认预期变化才更新对应五张 golden。
- node delta：查 active page 生命周期和 signal/tween，禁止提高预算。
- 旧 helper 删除导致 parse/reference 失败：恢复该 helper并定位真实引用，记录在 debug report 后再决定。
