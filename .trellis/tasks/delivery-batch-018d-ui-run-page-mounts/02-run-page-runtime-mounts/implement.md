# Implementation Plan: 018D-02

## 结构健康度预检

| 文件 | 当前行数 | 阈值 | 微重构 |
| --- | --- | --- | --- |
| `Main.gd` | 约 14k | 400 | 是：只新增紧邻各 refresh 的 VM/mount/adapter helper；不移动业务回调，旧视觉删除交给 018D-03 |
| 测试文件 | 大型 integration | 400 | 否：在现有领域段落旁新增断言，不拆文件 |

## 有序步骤

1. Map RED/GREEN、自检。
2. Event RED/GREEN、自检。
3. Campfire RED/GREEN、自检。
4. Shop RED/GREEN、自检。
5. Reward/Treasure RED/GREEN、自检。
6. 严格日志扫描本任务六套命令；更新 tdd-progress。

## 修改边界

- 允许：PRD 六个源/测试文件和本任务进度/调试报告。
- 禁止：data、SaveManager、CombatState、telemetry、gallery/golden/docs。

## 失败恢复

- 事务断言失败：停止页面继续迁移，使用 debug skill 对比原回调调用次数/参数；禁止改业务断言。
- active page 有但旧 root 可见：检查 `_set_page_regions` 与 shell visibility，只改当前 route 分支。
- node leak：检查 AppShell clear/mount 生命周期和旧 MapView 释放，不加宽预算。
