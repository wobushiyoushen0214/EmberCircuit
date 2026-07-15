# Design：PC Boss 阶段与战斗反馈重构

## 编排与计算分离

- `CombatState.gd` 继续唯一负责阶段阈值判断、阶段运行态、入场效果和下一行动。
- `Main.gd` 只读取 `enemy.data.phases`、`phase_index`、`phase_data` 和 `current_action`，生成 PC 表现。
- `vfx_profiles.json` 继续提供颜色、射线、缩放、时长和音频；本批不修改其数值。

## 挂载点

1. `_add_pc_enemy_stage_layout()` 挂载 `BossPhaseBadge`。
2. `_add_pc_enemy_health_plate_layout()` 挂载阈值线。
3. `_enemy_tooltip_text()` 挂载阶段预告。
4. `_show_cinematic_prompt()` 将 `phase` 路由到 `_show_boss_phase_banner()`；`won/lost` 保持原路径。
5. `_request_hit_stop()` 只调度 `enemy_stage_stack.process_mode`，不写 `Engine.time_scale`。
6. `render_pc_gallery.gd` 通过真实 `_damage_enemy()` 触发三个 Boss 阶段反馈。

## 稳定节点

- `BossPhaseBadge`
- `BossPhaseBadgeLabel`
- `BossPhaseThreshold_0`
- `BossPhaseThreshold_1`
- `BossPhaseBanner`
- `BossPhaseBannerPortrait`
- `BossPhaseBannerTitle`
- `BossPhaseBannerNote`
- `BossPhaseBannerEffect`
- `BossPhaseBannerIntent`

## 布局

- 阶段徽章固定在 Boss 舞台右上角，尺寸不参与敌人横向排版。
- 阈值线是 HP 条内部 2px 标记，不增加 HP plate 高度。
- 阶段横幅宽度限制在 `min(620, stage_width - 32)`，位于战场上部偏中，不改变 `root_box` 高度。
- 动画使用忽略 time scale 的 Tween，约 0.18 秒进入、0.95 秒停留、0.20 秒退出。

