# TDD 进度：018D-03

| AC | 可观察结果 | 测试/工具 | 状态 | 备注 |
| --- | --- | --- | --- | --- |
| AC-018D-10 | 无调用旧视觉 helper 删除，业务/probe 回归绿 | run-flow + rg | done | 删除 Campfire/Event/Reward PC 内联树及专属样式 helper；compact 路径、业务回调、素材查找和 probes 保留；当前相对 HEAD 的 Main diff 净减少约 190 行。 |
| AC-018D-11 | 五页新金标与 720p/900p bounds，11页区域 diff绿 | gallery/visual/bounds | done | 首轮旧金标 RED 暴露四页空洞；补齐三栏 Reward、事件/篝火场景图、等高 Shop 货架后人工复核 720p/900p，通过 11/11 区域 verifier，六页未改基线像素稳定。 |
| AC-018D-12 | 五页20轮节点0增量、600帧预算、全量严格回归 | profiler/all tests | done | 真实 Main map->event->shop->campfire->reward 20 轮，节点增量 0、循环 Tween 2；600 帧 p95 14.42ms、1% low 66.35 FPS、输入 51.509ms、burst 10/20；28/28 tests 全绿。 |

## 最小实现收敛

- 删除项：`_add_pc_campfire_experience`、`_add_pc_campfire_forge_selection`、`_add_pc_event_experience`、`_add_pc_event_story`、`_add_pc_event_decisions`、`_add_pc_event_choice_content`、`_play_pc_room_reveal`、对应专属样式 helper、`_create_reward_action_column`；保留 compact 共用 helper。
- 复用项：现有 verifier、profiler、gallery、ForgeTheme/AppShell。
- 保留项：业务状态、回调、存档、遥测、错误路径、可访问性、probe。
- `trellis-minimal:`：无。

## 调试记录

- AC-018D-12 首次 GUI 采样出现 node delta `-2`；headless 对照为 `0`，路径探针确认页面结构不累积。按 systematic debug 将基线和终态都等待 350ms 页面进入/音频瞬态收敛后再取样，最终 GUI 报告回到 `0`。
