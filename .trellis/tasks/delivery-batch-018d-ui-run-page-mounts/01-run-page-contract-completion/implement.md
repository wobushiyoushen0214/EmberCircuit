# Implementation Plan: 018D-01

## 结构健康度预检

| 文件 | 当前行数级别 | 阈值 | 微重构 |
| --- | --- | --- | --- |
| 五个 page | 84-131 行 | 400 | 否；原地扩展 |
| route room test | 约 130 行 | 400 | 否 |

## 有序步骤

1. 只编辑测试，加入 AC-01 并看到 RED；再只改 Map/Event 变绿。
2. 只编辑测试，加入 AC-02 并看到 RED；再只改 Shop 变绿。
3. 只编辑测试，加入 AC-03 并看到 RED；再只改 Campfire 变绿。
4. 只编辑测试，加入 AC-04 并看到 RED；再只改 Reward 变绿。
5. 跑 editor import、route room、accessibility；更新 tdd-progress。

## 修改边界

- 允许：PRD 文件清单六个文件及本任务 tdd-progress/debug-report。
- 禁止：Main、data、SaveManager、CombatState、gallery/golden。

## 失败恢复

- parse error：只修报错 page/test 行并重跑原命令。
- signal 未发：先检查按钮 disabled 与 signal 连接，不改断言迁就实现。
- 动态节点重复：在 configure 前同步 detach/free 旧动态节点，再重跑 20 次 configure 测试。
