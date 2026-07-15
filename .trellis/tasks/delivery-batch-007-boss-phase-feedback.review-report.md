# 双阶段评审报告

## Review Round 1

### 被评审对象

- 任务：`delivery-batch-007-boss-phase-feedback`
- diff 范围：`7694f57..L3 Round 3 工作树`
- Stage 1：独立只读代理 Planck。
- Stage 2：独立只读强模型代理 Mendel。

### Stage 1 · 首轮规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| AC-001 | 部分通过 | major | `Main.gd:9704`, `test_run_flow.gd:330` | 阈值线最初仅看 `phases`，未显式限制 Boss；缺普通敌人负向契约。 |
| AC-002 | 通过 | - | `Main.gd:10834`, `test_run_flow.gd:881` | `phase` 已路由到战场横幅，胜败保留终局遮罩。 |
| AC-003 | 不通过 | critical | `Main.gd:12398`, `test_visual_bounds.gd:274` | 首轮 headless 测试未执行 process mode 禁用、重叠延期和退出恢复。 |
| AC-004 | 通过 | - | `render_pc_gallery.gd:132` | 三张 `1280x720` Boss 阶段图存在并人工验收。 |
| 文件与禁止事项 | 通过 | - | 当前 diff | 未修改任何卡牌、角色、怪物、成长、挑战或经济数值；未新增依赖、插件或单例。 |

### Stage 2 · 首轮代码质量

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| 阈值数据一致性 | 应修 | major | `Main.gd:9742` | tooltip 支持 `hp_below`，血条最初只支持百分比阈值。 |
| 图库失败语义 | 应修 | major | `render_pc_gallery.gd:147`, `render_pc_gallery.gd:280` | setup 失败最初只 `push_error`，仍可能保存错误截图并退出 0。 |
| 横幅输入类型 | 应修 | minor | `Main.gd:10834` | `phase_data` 需要 Dictionary 类型保护。 |

### 首轮裁决

- 有 1 项 critical，打回 TDD 实现。
- 两项 Stage 2 major 与一项 minor 一并在本轮关闭。

## Review Round 2

### 修复与复审证据

| 问题 | 修复 | 验证 |
| --- | --- | --- |
| AC-003 未执行真实路径 | SceneTree 内的 headless 测试不再跳过局部顿帧；覆盖禁用舞台、重叠请求超过首截止时间、恢复原 `PROCESS_MODE_ALWAYS`、全局 time scale 不变和 `remove_child()` 触发 `_exit_tree()` 恢复。 | `tests/test_visual_bounds.gd:274-293` |
| 普通敌人可能出现阈值 | 阈值轨道显式要求 `tier == boss`；用带 phase-shaped data 的普通敌人做负向测试。 | `Main.gd:9704`, `tests/test_run_flow.gd:319-333` |
| 阶段契约覆盖不足 | 增加 `阶段 3/3`、66% 与阶段说明、Boss 名/阶段序号、鼠标穿透及 won/lost 终局遮罩断言。 | `tests/test_run_flow.gd:1432-1476`, `tests/test_run_flow.gd:919-951` |
| 绝对生命阈值缺失 | `_boss_phase_threshold_ratio()` 统一支持 `hp_percent_below` 与 `hp_below`。 | `Main.gd:9742`, `tests/test_run_flow.gd:1443-1459` |
| 图库可能假阳性 | Boss setup 返回 bool；失败时跳过保存并累计失败，最终非零退出；截图读取真实第一阶段阈值并验证横幅存在。 | `render_pc_gallery.gd:140-181`, `render_pc_gallery.gd:280-314` |
| 阶段动画属性竞争 | phase 不再触发通用闪烁；专属动画按原始角色缩放恢复并忽略 time scale。 | `Main.gd:10632-10647`, `Main.gd:12141-12165` |

### 最终裁决

- Stage 1 复审：Critical 0，先前阻断已关闭。
- Stage 2 复审：Critical 0 / Major 0 / Minor 0。
- 18/18 Godot 测试与项目解析严格通过，日志无 `SCRIPT ERROR` / `ERROR:`。
- 三张 Boss 阶段图库重新生成并人工检查通过；图库命令成功退出 0。
- 测试与图库前后真实 Profile、设置、真人遥测和报告 SHA-256 完全一致。
- 裁决：允许提交源码并进入 `0.1.0-alpha.6` 产物构建。

### 残余风险

- 批次外既有的“数值先结算、动作后播放”和缺少统一演出队列问题仍存在，作为后续战斗演出批次处理；本批没有扩大该行为，也不影响 Boss 阶段 HUD 与局部顿帧验收。
