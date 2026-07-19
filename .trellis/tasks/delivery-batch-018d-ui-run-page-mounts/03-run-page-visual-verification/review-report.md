# 双阶段评审报告：018D-03

## Review Round 1

### 被评审对象

- 任务：`03-run-page-visual-verification`
- diff 范围：`ae87384..当前工作树`，仅按 018D-03 PRD File Manifest 与已记录的 018D-03 实现/验证范围核对
- Stage 2 评审模型：GPT-5 Codex（强模型）

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| AC 测试覆盖 | 通过 | - | `tests/test_visual_bounds.gd`、`tests/test_ui_performance_budget.gd`、`tools/verify_ui_visual_regression.gd` | AC-018D-10 的旧 helper/root 静态门、AC-018D-11 的 720p/900p bounds 与 11 页区域回归、AC-018D-12 的 20 轮路由/600 帧预算均有测试或验证工具；28/28 全量测试通过。 |
| 文件清单符合 | 通过 | - | 018D-03 `prd.md` File Manifest | Main、四个运行页、视觉/性能测试与工具、合同、五张金图、四份文档及任务产物均在清单内；未新增依赖、数据表或生产资源。 |
| 禁止事项符合 | 通过 | - | `scripts/main/Main.gd`、`scripts/ui/pages/*.gd` | 未修改 `CombatState`、`SaveManager schema`、telemetry payload、art manifest、数值数据或业务回调签名。 |
| 决策表符合 | 通过 | - | `scripts/main/Main.gd:4161-4199`、`scripts/main/Main.gd:6853-6898`、`scripts/main/Main.gd:11495-11634` | 五页均由只读 VM 进入 `page.configure`，typed signal 回到 Main adapter；区域合同未放宽，性能阈值未放宽。 |
| 挂载点接线 | 通过 | - | `tools/render_pc_gallery.gd:176-208`、`tools/profile_ui_performance.gd:207-222`、`docs/02_TECHNICAL_ARCHITECTURE.md:74-76` | Gallery、visual contract、profiler route loop 和文档四处均声明并实际使用 `map/event/shop/campfire/reward` 五个 active page id。 |
| 范围符合 | 通过 | - | 018D-03 `prd.md` 非目标与禁止事项 | 仅删除无调用旧视觉树、补齐既有页面布局/素材呈现与验证；未引入新玩法、数值、素材或依赖。 |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| 编排-计算分离 | 通过 | - | `scripts/main/Main.gd` VM/adapter 与 `scripts/ui/pages/*.gd` | Main 负责状态快照、路由和业务回调；页面只做展示树与 signal；视觉比较和性能计算复用现有工具。 |
| 结构健康度 | 通过 | minor | `scripts/main/Main.gd` | 文件仍偏胖，但本任务只删除无调用 PC 视觉 helper，没有继续把业务逻辑搬入；后续可独立拆分。 |
| 简化与复用 | 通过 | - | `ForgeTheme`、`AppShell`、现有 gallery/verifier/profiler | 复用既有主题、壳层、图像比较和性能评估，不新增万能工具或依赖；页面只增加必要的真实素材布局。 |
| 正确性（边界/错误/回归） | 通过 | - | `RewardPage.gd`、`CampfirePage.gd`、`EventPage.gd`、`ShopExperience.gd` | 页面非法 mode/未知 choice/非法 deck index/禁用按钮均防御；Main adapter 保留未知/过期请求 warning 与状态不变；视觉、性能、完整回归均通过。 |
| 规范符合（spec） | 通过 | - | `docs/02_TECHNICAL_ARCHITECTURE.md`、`docs/04_ART_AUDIO_PIPELINE.md` | Main→VM→page→typed signal→Main 边界、暗炉 token、本地字体、44px 热区和金标规则与项目约定一致。 |

### 问题汇总（按严重度）

- **Critical（阻断）**：无。
- **Major（应修）**：无。
- **Minor（记录后续）**：`Main.gd` 仍偏胖，后续结构重构时再拆分 VM/route orchestration；不阻断 018D-03 交付。

### 验证证据

- Godot editor import：通过。
- 视觉 bounds：通过。
- UI performance budget：通过。
- 11/11 区域视觉回归：`/tmp/ember018d-visual.json`，`failed_pages: []`。
- 最终 GUI 性能：`/tmp/ember018d-performance.json`，600 帧，p95 `14.42ms`，1% low `66.35 FPS`，最大输入延迟 `51.509ms`，节点增量 `0`，循环 Tween `2`，路由切换 `20` 轮，route ids 五项齐全。
- 完整回归：`tests/test_*.gd` 共 28 个，全部返回 `rc=0`。

### 裁决

- [ ] 有 critical → 打回 `trellis-implement-tdd-zh`
- [x] 仅 major/minor → 放行；minor 记录后续
- [ ] 全通过 → 交回编排会话推进任务状态

