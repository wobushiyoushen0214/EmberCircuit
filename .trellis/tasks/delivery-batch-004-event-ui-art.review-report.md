# 双阶段评审报告

## Review Round 1

### 被评审对象

- 任务：`delivery-batch-004-event-ui-art`
- diff 范围：`40849e4..Round 6 工作树`
- Stage 2 评审模型：Codex 强模型只读子代理（Lorentz），主线程负责修复后复审编排。

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| AC 测试覆盖 | 通过 | - | `tests/test_art_asset_auditor.gd`, `tests/test_run_flow.gd`, `tests/test_visual_bounds.gd` | 覆盖事件位图契约、单舞台、纵向选项、真实按钮接线、无滚动条和视口边界。 |
| 文件清单符合 | 通过 | - | Round 6 diff | 只改事件 UI/资源、测试、图库、版本和交付文档；未修改卡牌、角色、怪物、成长或挑战数值。 |
| 禁止事项符合 | 通过 | - | 全部 diff | 未引入依赖、API key、网络运行时代码或临时生图文件；`build/` 未纳入源码提交。 |
| 决策表符合 | 通过 | - | `data/config/art_assets.json`, `scripts/main/Main.gd` | PC 1280x720 优先、数据与表现分离、数值冻结、生成位图作为 `asset_path`，稳定事件路径保留为 `slot_path`。 |
| 挂载点接线 | 通过 | - | `scripts/main/Main.gd`, `tools/render_pc_gallery.gd` | 四张事件图经 manifest 加载；事件页、按钮状态、图库和发布版本均已接线。 |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| 编排-计算分离 | 通过 | - | `scripts/main/Main.gd` | 新增代码只编排 Control 和 Tween，不改事件效果计算。 |
| 结构健康度 | 通过 | minor | `scripts/main/Main.gd` | 主文件仍较大，但事件专用构造/样式函数连续归组，未新增跨域抽象。 |
| 简化与复用 | 通过 | - | `scripts/main/Main.gd` | 复用现有按钮样式、资源加载和路线图标；未复制事件结算逻辑。 |
| 正确性 | 通过 | - | `Main.gd`, 三项测试 | 事件滚动只在 PC 事件页关闭，其他页面刷新会恢复；Tween 绑定目标节点；四选项与宽屏均有验证。 |
| 规范符合 | 通过 | - | 资源清单、测试、文档 | 严格 RGB/尺寸契约、中文注释和现有 Godot 测试风格一致。 |

### 首轮问题与关闭证据

- `slot_path` 曾被误改到生成目录：`test_data_integrity.gd` 红灯后恢复稳定事件路径，原失败测试和 18 套回归均转绿；详见同批 debug report。
- Tween 最初绑定 `Main`：改为 `stage.create_tween()` / `control.create_tween()`，页面切换时随目标节点终止。
- 宽屏裁切只做了 720p 验证：事件内容宽度上限设为 1568 并居中，新增 `2048x1066` 截图，人工复核通过。
- 流程测试原先直接调用事件处理函数：改为 `first_event_choice_button.pressed.emit()` 验证真实信号接线。
- 图库原先只检查一张新图：四张正式候选事件图现均有 720p 实际裁切截图，阻塞/随机状态文案可见。

### 问题汇总（按严重度）

- **Critical（阻断）**：无。
- **Major（应修）**：无。
- **Minor（记录后续）**：headless 测试不执行真实显现 Tween，透明度/缩放像素结果继续依赖非 headless PC 图库；最长未来事件文案仍需沿固定裁切规则人工复核。

### 裁决

- [ ] 有 critical，打回实现。
- [x] 仅 minor，放行；已记录剩余视觉自动化边界。
- [ ] 全无问题。

## Review Round 2

- 修复后只读复审确认：无 critical、无 major。
- `stage/control.create_tween()`、1568 居中宽度上限、正式路线图标、真实 `pressed` 信号和 2048x1066 图库均未引入新的布局或导出风险。
- 最终裁决：允许提交 Round 6 源码并进入 `0.1.0-alpha.3` 产物构建。
