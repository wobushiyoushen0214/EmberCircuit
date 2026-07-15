# TDD Progress

- [x] AC-001 Boss 阶段徽章、阈值线和 tooltip
- [x] AC-002 战场内阶段横幅与真实上下文
- [x] AC-003 局部顿帧和重叠恢复
- [x] AC-004 720p 边界与三 Boss 图库

## 红绿证据

- RED：`test_run_flow.gd` 首次失败于 `phase feedback uses a stable battle-stage banner`。
- RED：`test_visual_bounds.gd` 首次只失败于横幅、徽章和阈值节点缺失及边界断言。
- RED：视觉复核发现旧强反馈条与新横幅重复，新增测试后稳定失败于 `battle-stage phase banner replaces the duplicate legacy feedback strip`。
- RED：Stage 1 审查后新增普通敌人负向测试，稳定失败于 `normal enemies never render boss phase badges or thresholds even when phase-shaped data exists`。
- RED：Stage 1 审查后在真实 SceneTree 内执行局部顿帧，稳定失败于舞台禁用、重叠延期和退出恢复三项断言。
- RED：Stage 2 审查后新增绝对生命阈值测试，稳定失败于 `boss health bar renders absolute hp_below thresholds on the same data-driven track`。
- GREEN：`test_run_flow.gd` 和 `test_visual_bounds.gd` 聚焦测试通过。
- GREEN：18/18 Godot 测试串行通过，逐日志扫描无 `SCRIPT ERROR` / `ERROR:`。

## 视觉证据

- `/tmp/embercircuit_pc_gallery/30_forge_bishop_phase_720p.png`
- `/tmp/embercircuit_pc_gallery/31_storm_archon_phase_720p.png`
- `/tmp/embercircuit_pc_gallery/32_nexus_heart_phase_720p.png`
- 三张图均为 `1280x720`，阶段横幅、常驻徽章、两条血量阈值和手牌区完整显示，无页面滚动条或缺帧黑区。

## 最小实现收敛

- 复用现有 `CombatState` 阶段运行态、`boss_phase_profiles`、敌人贴图、状态名和卡牌名查询，没有复制 Boss 阈值或行动规则。
- 复用 Godot `process_mode`、`Time.get_ticks_msec()`、忽略 time scale 的 SceneTreeTimer 和 Tween，没有新增依赖或单例。
- 只保留一个战场内阶段横幅；PC 阶段反馈会隐藏旧反馈条，胜败仍走原全屏终局提示。
- 图库通过真实 `_damage_enemy()` 进入阶段，并在读取 SubViewport 前等待 `RenderingServer.frame_post_draw`。
- 保留重叠顿帧的最晚截止时间与 `_exit_tree()` 恢复钩子，避免页面退出后留下错误处理状态。

当前阶段：GREEN，双阶段评审通过
