# Batch 018A：暗炉 UI Shell、Token、动效基础与欢迎/角色页

## 需求 ID

- REQ-008
- REQ-012
- AC-018A-01 ～ AC-018A-08

## 目标

在不改变跑团、存档、遥测和战斗语义的前提下，把欢迎页与角色选择页从 `Main.gd` 的通用 reward flow 迁移到独立页面类，并建立 Batch 018 后续页面必须复用的暗炉 token、焦点、按钮和 motion API。

## 当前缺口

- 当前状态：PARTIAL。
- 代码证据：`scripts/main/Main.gd:_build_layout`, `_refresh_welcome`, `_refresh_character_select`, `_apply_button_skin`, `_character_button_style`。
- 测试证据：`tests/test_run_flow.gd`、`tests/test_visual_bounds.gd` 只验证功能/边界，不验证统一材质、焦点和页面契约。
- 缺口：没有 `AppShell`/页面实例/语义 token；欢迎页三个同级操作卡缺品牌主次；角色页没有独立舞台、选中重量和稳定确认区。
- 风险：继续在 15,000 行 `Main.gd` 堆页面树会让后续地图/商店迁移不可审计。

## 交付 Loop 控制

- 交付批次：`delivery-batch-018-ui-ember-forge-cohesion`
- Loop 模式：L3
- 需要 worktree：是
- 需要 verifier：是
- 实现技能：`trellis-implement-tdd-zh`
- 调试技能：`trellis-debug-systematic-zh`
- 评审技能：`trellis-review-twostage-zh`
- 人工门：需要 Stage 2 强模型评审；视觉金标需人工确认后才能更新。
- 最大修复尝试次数：2
- 最大调试假设轮数：3
- 回滚触发：测试回归、File Manifest 越界、Main 旧 probe 消失、页面状态/存档语义改变。

## 复杂度与规划产物

- 复杂度：高。
- 执行模型假设：Codex 编排 + 受控本地执行代理。
- 必要产物：`prd.md`、`design.md`、`implement.md`、`implement.jsonl`、`check.jsonl`、`tdd-progress.md`。
- Spec 新鲜度：`.trellis/spec/` 缺失；以 `.trellis/audits/2026-07-17-ember-spire-ui-reference.md`、邻近 Batch 017 产物和现有测试作为稳定契约。

## 上下文清单

| 类型 | 路径 | 用途 |
| --- | --- | --- |
| 视觉审计 | `.trellis/audits/2026-07-17-ember-spire-ui-reference.md` | token、motion、性能和全页面方向 |
| MVP 代码 | `scripts/main/Main.gd` | 保留状态、回调、旧 probe，迁移 `_refresh_welcome/_refresh_character_select` |
| MVP 场景 | `scenes/main/Main.tscn` | 保留 Main 根节点，不新增外部依赖 |
| 现有测试 | `tests/test_run_flow.gd` | 角色选择、欢迎、设置回归断言 |
| 现有测试 | `tests/test_visual_bounds.gd` | 1280×720/390×640 边界断言 |
| 字体/资产 | `assets/fonts/NotoSansSC-Variable.ttf`, `assets/art/generated/ui/menu_backdrop_v3_pc.png` | 不引入第三方字体，复用现有原创资源 |

## 决策表

| 决策点 | 选定方案 | 原因 | 影响文件 |
| --- | --- | --- | --- |
| 页面挂载 | `AppShell.mount_page(page,page_id)` 动态挂载，`Main.gd` 只传 view model/连接信号 | 保持单场景和旧测试入口，逐页迁移 | `AppShell.gd`, `Main.gd` |
| token 来源 | `data/config/ui_theme_tokens.json` 作为数据源，`ForgeTheme.gd` 只读并提供 typed helper | 禁止业务代码散落 Color | `ui_theme_tokens.json`, `ForgeTheme.gd` |
| motion | `ForgeMotion` 统一 80–320ms；`reduced_motion` 时位移/缩放为 0，仅 opacity/border 确认 | 可访问且可被后续页面复用 | `ForgeMotion.gd`, `ui_motion_profiles.json` |
| 主 CTA | 欢迎页只有“开始新跑团”为 primary；继续为 neutral；档案/设置进入 utility 区 | 建立明确品牌焦点 | `WelcomePage.gd`, `Main.gd` |
| 角色确认 | 角色卡只预览；确认按钮固定在页面 action row，点击才调用 `_on_character_confirm_pressed` | 防止选卡立即开局 | `CharacterSelectPage.gd`, `Main.gd` |
| 旧 probe | 保留 `last_welcome_*`、`last_character_selection_*`、原节点名和回调 | 兼容现有自动化测试一个迁移周期 | `Main.gd`, tests |

## MVP 兼容性契约

| 已有行为 | 证据 | 必须保留 | 回归检查 |
| --- | --- | --- | --- |
| 欢迎页新跑团/继续/图鉴回调 | `Main.gd:_on_new_run_pressed`, `_on_load_pressed`, `_on_compendium_pressed` | 是 | `test_run_flow.gd` |
| 角色卡预览不立即开局 | `Main.gd:_on_character_preview_selected` | 是 | `test_welcome_character_pages.gd` |
| 角色确认使用当前 challenge/character | `Main.gd:_on_character_confirm_pressed` | 是 | `test_run_flow.gd` |
| 旧字段和 1280×720 bounds | `tests/test_visual_bounds.gd` | 是 | visual bounds + new structure test |

## 参考实现

- 后端范例：无。
- 数据层范例：`scripts/core/SaveManager.gd:normalized_settings` 的 typed normalization 风格。
- 前端范例：`Main.gd:_add_reward_action_button`、`_add_character_select_card_layout`、`_apply_button_skin`。
- 替换说明：把 reward action button 的数据模型替换为 `ActionCard.configure(model)`；把角色 Button 内联树替换为 `CharacterSelectPage` 的 page-local card builder，但回调仍绑定 Main。

## 文件清单

| 操作 | 文件路径 | 说明 |
| --- | --- | --- |
| 新建 | `data/config/ui_theme_tokens.json` | 暗炉颜色、字号、间距、圆角、焦点环 token |
| 新建 | `data/config/ui_motion_profiles.json` | micro/hover/page/selection/reward/outcome 时间和 reduced-motion 规则 |
| 新建 | `scripts/ui/ForgeTheme.gd` | token 读取、StyleBox/Color/尺寸 typed helper |
| 新建 | `scripts/ui/ForgeMotion.gd` | 可中断页面入场、按压反馈、reduced-motion 策略 |
| 新建 | `scripts/ui/AppShell.gd` | 页面 host、utility action、context header、来源页返回信号 |
| 新建 | `scripts/ui/components/ForgePanel.gd` | 统一暗铁/焦木面板与 variant |
| 新建 | `scripts/ui/components/ActionCard.gd` | primary/neutral/tool 状态卡，≥44px 热区 |
| 新建 | `scripts/ui/components/MenuCommandButton.gd` | 欢迎页专用命令板、编号/焦点轨/存档状态，不复用表单式卡片 |
| 新建 | `scripts/ui/components/CharacterStageCard.gd` | 角色立绘舞台、属性/遗物/牌组信息与显式选中态 |
| 新建 | `scripts/ui/components/ResourceChip.gd` | 资源图标+数值语义组合，不只依赖颜色 |
| 新建 | `scripts/ui/components/PageHeader.gd` | 页面标题、短副标题、返回动作 |
| 新建 | `scripts/ui/pages/WelcomePage.gd` | 欢迎 hero 与三类动作信号 |
| 新建 | `scripts/ui/pages/CharacterSelectPage.gd` | 角色舞台、挑战轨道、预览/确认信号 |
| 修改 | `scripts/main/Main.gd` | `_build_layout` 挂 AppShell；`_refresh_welcome/_refresh_character_select` 改为 VM+信号编排；保留旧 probe |
| 修改 | `tests/test_run_flow.gd` | 新页面信号、主次 CTA、确认/返回回归 |
| 修改 | `tests/test_visual_bounds.gd` | 新 Shell/page 节点 1280×720 与 390×640 边界 |
| 新建 | `tests/test_forge_ui_foundation.gd` | token、motion、focus、热区、unknown token fallback |
| 新建 | `tests/test_welcome_character_pages.gd` | 欢迎/角色页面 API、主次 CTA、预览不启动、三角色和 challenge 边界 |
| 修改 | `docs/02_TECHNICAL_ARCHITECTURE.md` | UI 编排/页面组件边界 |
| 修改 | `docs/06_IMPLEMENTATION_LOG.md` | Batch 018A 记录 |

## 挂载点

| 挂载点 | 类型 | 位置 | 接线动作 |
| --- | --- | --- | --- |
| AppShell | 页面 host | `Main._build_layout` | 创建并挂入 root，提供 `page_host` |
| WelcomePage | 页面路由 | `Main._refresh` welcome 分支 | 传 welcome VM，连接 new/continue/archive |
| CharacterSelectPage | 页面路由 | `Main._refresh` character_select 分支 | 传角色/challenge VM，连接 preview/delta/confirm/back |
| ForgeTheme | 配置 | `Main._apply_button_skin` 兼容层 | 所有新组件只从 token 取色/尺寸 |
| ForgeMotion | 动效策略 | `AppShell` | page enter/press 状态都读取 reduced motion |

## 实现步骤

1. RED：在 `test_forge_ui_foundation.gd` 与 `test_welcome_character_pages.gd` 先断言新类/API/节点，确认当前缺失而失败。
2. 新增 token/motion JSON 与 `ForgeTheme/ForgeMotion`，只实现 typed read、fallback、duration clamp 和 reduced-motion 分支；跑 foundation test。
3. 新增 `ForgePanel/ActionCard/ResourceChip/PageHeader/AppShell`，确保焦点环、44px 热区和 press feedback 不改变布局；跑 foundation test。
4. 新增 `WelcomePage`，把三个 action card 做成 hero/primary/secondary/tool 层级；Main 只传 VM 并绑定原回调；跑欢迎页 test。
5. 新增 `CharacterSelectPage`，迁移角色卡/挑战轨道/确认行；保留 `last_*` probes 和原按钮回调；跑角色页 test。
6. 更新 `test_run_flow`/`test_visual_bounds`，然后执行全部 A 自检命令。
7. 只在所有测试绿后做最小实现收敛：删除重复 inline style，禁止新增抽象层和依赖。

## 行为约束

- `AppShell.mount_page` 同时只能有一个 active page；换页先发旧页 exit，再挂新页。
- 欢迎页首焦点必须是“开始新跑团”；无存档时“继续跑团” disabled 但仍显示原因。
- 角色预览不会改变 `playtest_active_run`、存档、遥测或 `run_started`；确认后才进入原始 start flow。
- 所有 interactive Control 最小尺寸 ≥44×44；focus 状态必须有 2px brass 外环。
- reduced motion 下不创建循环 Tween/粒子；状态确认仍在 80–120ms 内完成。
- 未知 token 使用 `bg_ink/text_primary` fallback，不抛异常、不加载网络资源。

## 验收标准

- [x] `test_forge_ui_foundation.gd` 通过，token JSON 版本、颜色、字号、motion duration 和 fallback 可读且确定。
- [x] `test_welcome_character_pages.gd` 通过；欢迎页 primary/secondary/tool 层级、无存档 disabled reason、角色三卡、challenge 首尾、预览不启动均有断言。
- [x] `Main.gd` 不再直接构造欢迎/角色页的主要视觉树，只保留 view model、回调和旧 probe adapter。
- [x] PC 正式视觉门 1280×720 与 1600×900 无页面级裁切/重叠；焦点顺序符合视觉顺序。小窗口只要求外层页面有界、关键动作可达，不作为构图金标。
- [x] 原 `test_run_flow.gd`、`test_visual_bounds.gd` 与现有全量回归通过。
- [x] `git diff --check` 通过，`.godot/`、截图临时文件、第三方资产未被跟踪。

## 自检命令

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_forge_ui_foundation.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_welcome_character_pages.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_run_flow.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_visual_bounds.gd
```

## 依赖与范围外

- 依赖：Batch 017 `40f9e4a`；无其他任务。
- 解锁：018B、018C。
- 范围外：地图/事件/商店/篝火/奖励/胜败/设置/图鉴页面迁移；新角色/卡牌/敌人；数值、存档 schema、商业构建、第三方资产和字体。

## 禁止事项

- 不改 `CombatState.gd`、卡牌/敌人/经济/地图/奖励数据。
- 不删除或改名现有 Main probe、节点名和既有回调。
- 不在页面组件里直接写 SaveManager、金币、牌组、遥测或战斗状态。
- 不引入第三方依赖、网络资源或参考站资产。
- 未通过双阶段评审不得标记完成。
