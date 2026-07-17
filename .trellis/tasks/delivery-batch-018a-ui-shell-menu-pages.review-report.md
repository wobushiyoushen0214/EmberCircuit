# Batch 018A 双阶段评审报告

## Review Round 1

### 被评审对象

- 任务：`delivery-batch-018a-ui-shell-menu-pages`
- diff 范围：`9b8f686..当前工作树`
- Stage 2 评审模型：Codex GPT-5（强模型评审）

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| AC 测试覆盖 | 通过 | - | `tdd-progress.md` | AC-018A-01～08 均有测试/回归证据，24/24 全量绿；PRD 的 AC-09 笔误已校正为 AC-08。 |
| 文件清单符合 | 通过 | - | `prd.md` File Manifest | 新增 `MenuCommandButton.gd`、`CharacterStageCard.gd` 已登记；无清单外产品代码文件。 |
| 禁止事项符合 | 通过 | - | 全部 diff | 未改战斗、数值、存档 schema、地图、商店、奖励或第三方资源。 |
| 决策表符合 | 通过 | - | `Main.gd`、`AppShell.gd`、页面类 | AppShell 动态挂载、token/motion 分层、预览/确认语义均保持。 |
| 挂载点接线 | 通过 | - | `Main.gd:build_layout/refresh` | Welcome/Character 页面已挂载，原回调、probe 和 focus 入口保留。 |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| 编排-计算分离 | 通过 | - | `scripts/ui/`、`Main.gd` | token/motion/page rendering 在 UI 层，Main 只协调 VM 与回调。 |
| 结构健康度 | 通过 | - | `Main.gd` | 本轮已删除旧角色卡/挑战条死构造函数，避免迁移后继续膨胀。 |
| 简化与复用 | 通过 | - | `tdd-progress.md` | 复用 Godot Control/Container/StyleBox/Tween，无新增依赖。 |
| 正确性（边界/错误/回归） | 通过但需修 | major | `Main.gd:2696` | reduced-motion 只传入 AppShell/page motion，菜单背景循环 tween 未被设置项停止。 |
| Motion 时间边界 | 通过但需修 | major | `ForgeMotion.gd:14` | duration 读取未 clamp，未完整落实 PRD 的 80–320ms 统一边界。 |
| 交互状态可达性 | 通过但需修 | minor | `CharacterSelectPage.gd:388` | 锁定挑战仍使用手型光标和 FOCUS_ALL，应与 disabled 语义一致。 |

### 问题汇总（按严重度）

- **Critical（阻断）**：无。
- **Major（应修）**：在 reduced-motion 下停止并清理菜单背景循环 tween；统一 clamp motion duration 到 80–320ms。
- **Minor（记录后续）**：锁定挑战设置 `CURSOR_ARROW` 与 `FOCUS_NONE`，解锁时恢复可交互状态。

### 裁决

- [ ] 有 critical → 打回 `trellis-implement-tdd-zh`
- [x] 仅 major/minor → 先修本轮标注项，再重审
- [ ] 全通过 → 交回编排会话推进任务状态

## Review Round 2

### 被评审对象

- 任务：`delivery-batch-018a-ui-shell-menu-pages`
- diff 范围：`9b8f686..当前工作树`
- Stage 2 评审模型：Codex GPT-5（强模型评审）

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| AC 测试覆盖 | 通过 | - | `tdd-progress.md` | AC-018A-01～08 完整；最终 24/24 严格回归通过。 |
| 文件清单符合 | 通过 | - | `prd.md` File Manifest | 产品代码、测试、文档与 UID sidecar 均在授权范围；无截图或 `.godot/` 跟踪。 |
| 禁止事项符合 | 通过 | - | 全部 diff | 未触碰战斗/数值/存档 schema/地图/商店/奖励数据，未引入依赖或第三方资产。 |
| 决策表符合 | 通过 | - | `ForgeTheme.gd`、`ForgeMotion.gd`、`AppShell.gd`、页面类 | token/motion/page/VM 分层与主 CTA、确认语义全部保持。 |
| 挂载点接线 | 通过 | - | `Main.gd` | AppShell、WelcomePage、CharacterSelectPage、原回调和旧 probe 全部接线。 |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| 编排-计算分离 | 通过 | - | `scripts/ui/`、`Main.gd` | Main 只保留 VM、状态路由与回调；旧视觉构造死代码已删除。 |
| 结构健康度 | 通过 | - | `scripts/ui/components/`、`scripts/ui/pages/` | 欢迎命令和角色舞台使用专用组件，没有回退为通用卡片堆叠。 |
| 简化与复用 | 通过 | - | `ForgeTheme.gd`、`ForgeMotion.gd` | 单一 token/motion 入口、平台原生 Tween/Control，无新增依赖。 |
| 正确性（边界/错误/回归） | 通过 | - | 全部测试 | reduced-motion 会杀持续 tween 并恢复静态比例；duration clamp 80–320ms；页面替换延迟释放安全。 |
| 交互与可访问性 | 通过 | - | `WelcomePage.gd`、`CharacterSelectPage.gd` | 44px 热区、可见焦点、disabled reason、锁定挑战退出焦点/手型、显式非颜色选中态。 |
| PC 视觉质量 | 通过 | - | `/tmp/embercircuit_pc_gallery/` | 1280×720、1600×900 欢迎/角色页无裁切或重叠；最新 720p 实图复核通过。 |

### 问题汇总（按严重度）

- **Critical（阻断）**：无。
- **Major（应修）**：无。
- **Minor（记录后续）**：无。

### 裁决

- [ ] 有 critical → 打回 `trellis-implement-tdd-zh`
- [ ] 仅 major/minor → 放行；major 建议本轮修
- [x] 全通过 → 交回编排会话推进任务状态
