# TDD 进度：018D-01

| AC | 可观察结果 | 测试 | 状态 | 备注 |
| --- | --- | --- | --- | --- |
| AC-018D-01 | Map 精确 preview；Event 禁用/空选项 signal 正确 | `test_ember_forge_route_rooms.gd` | done | RED 指向 preview 未转发；GREEN 后 editor/route/accessibility 全绿。 |
| AC-018D-02 | Shop store/remove/leave/cancel 与 disabled reason 完整 | `test_ember_forge_route_rooms.gd` | done | RED 指向 disabled_reason；store/remove、真实 index、cancel/leave GREEN，自检全绿。 |
| AC-018D-03 | Campfire arrival/forge/back 与真实 deck index 完整 | `test_ember_forge_route_rooms.gd` | done | arrival/forge 分层、真实 index、back/leave GREEN，自检全绿。 |
| AC-018D-04 | Reward skip/save/mastery/continue/treasure 契约完整 | `test_ember_forge_route_rooms.gd` | done | split skip/save/mastery、continue gate、treasure/unknown mode GREEN，自检全绿。 |

## 最小实现收敛

- 删除项：无；只移除了动态节点在重建前的父容器引用，未同步释放既有节点。
- 复用项：ForgeTheme、ChoiceRow、现有 page 类、Godot 原生 `ScrollContainer` 与 `Button`。
- 保留项：旧节点名与 `skip/save` 兼容 signal、typed signal、disabled/focus/44px 回归、未知 mode 只读边界。
- `trellis-minimal:`：无；没有引入未来扩展点或新依赖。

## 收尾核对

- [x] 所有 AC 状态为 done。
- [x] 无 AC 停留在 red / green。
- [x] editor、route room、accessibility 自检最后一次全绿。
- [x] 已执行最小实现收敛：动态节点先 detach 再 queue_free，复用既有主题/控件能力。
- [x] `design.md` 挂载点清单已核对；本子任务无 Main 运行时挂载。
- [x] 未 commit；改动已暂存，等待双阶段评审。
