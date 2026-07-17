# Batch 018 全页面暗炉 UI Delta Audit

日期：2026-07-17

## Stage State Packet

```yaml
stage_state:
  state: S3_GAP_AUDIT
  loop_mode: L3
  audit_scope: delta
  current_round: 3
  max_rounds: 6
  open_gaps: 8
  tasks_created: 0
  tasks_completed: 0
  carry_over: 3
  critical_review_issues: 0
  next_legal_action: create the three confirmed Batch 018 UI tasks and planning artifacts
  stop_conditions:
    - none
```

## 交付 Loop 元数据

| 项目 | 值 | 说明 |
| --- | --- | --- |
| Loop 模式 | L3 | 用户已确认扩展并继续，允许推进到评审门 |
| 审计范围 | delta | 源需求主文档未改变；用户新增完整页面 UI 质量反馈，REQ-008/REQ-012 及相关任务证据变化 |
| MVP baseline | `2e3e857` | 数值重基线 full audit 的稳定基线 |
| Last audited | `ef222ae` | Batch 017 玩法与测试提交 |
| 当前 HEAD | `40f9e4a` | Batch 017 状态同步已合并 |
| Trellis workflow/spec | 未发现 `.trellis/workflow.md` 或 `.trellis/spec/` | 延续邻近任务的 prd/design/implement/JSONL/check/TDD/review 产物契约 |
| 执行模型假设 | Codex/GPT-5 强模型编排，受控执行代理实现 | 高风险结构迁移，必须严格 TDD 与双阶段评审 |

## 用户决策与参考边界

- 用户明确要求欢迎页、角色选择页及其余页面全部摆脱当前“低级感”，不能只改战斗皮肤。
- 参考 `https://www.k399.games/app/ember-spire-555b` 的暗炉、焦木、暗铁、黄铜、余烬材质和短促状态反馈。
- 只吸收视觉规律与交互节奏；不复制第三方代码、图像、字体、Logo 或具体版式。
- 参考审计证据：`.trellis/audits/2026-07-17-ember-spire-ui-reference.md`。

## Delta Requirements Traceability Matrix

| ID | 当前状态 | 实现证据 | 测试证据 | 本轮缺口 | 计划任务 |
| --- | --- | --- | --- | --- | --- |
| REQ-008 | PARTIAL | `scripts/main/Main.gd`, `scripts/map/MapView.gd`, `scripts/ui/PcEventExperience.gd`, `scripts/ui/PcCampfireExperience.gd`, `scripts/ui/PcDefeatExperience.gd`, `scripts/ui/RunCompletionPanel.gd`, `assets/art/generated/ui/` | `tests/test_run_flow.gd`, `tests/test_visual_bounds.gd`, `tests/test_map_view.gd`, `tools/render_pc_gallery.gd` | 功能和 720p 边界存在，但欢迎/角色/设置/图鉴仍由通用 reward flow 动态拼装；商店无独立舞台；跨页无统一 token、focus、motion、reduced-motion 和视觉金标 | 018A/018B/018C |
| REQ-012 | PARTIAL | `tests/`, `tools/render_pc_gallery.gd` | Batch 017 22/22 strict regression | 现有测试证明功能与边界，不证明 10 类页面的视觉层级、状态完整性、对比度、动效降级、稳定节点数与截图差异 | 018A/018B/018C |
| REQ-006 | PARTIAL | `assets/art/generated/`, `data/config/art_assets.json` | `tests/test_art_asset_auditor.gd` | 仍有 legacy 内容资产，但本批只允许复用/新增原创 UI 装饰，不扩大到敌人/事件/卡图生产替换 | 本轮排除 |
| REQ-003/004/005/009 | PARTIAL | Batch 017 已交付 | 22/22 + 双阶段评审 | UI 迁移不得改变玩法数值、模拟结果或真实战斗结算 | 回归契约 |

## 页面差距矩阵

| 页面 | 当前结构证据 | 可验收缺口 |
| --- | --- | --- |
| 欢迎 | `Main._refresh_welcome()` 在 `reward_row` 创建三个同级操作卡 | 品牌 hero、唯一主 CTA、继续的存档态、工具入口层级、键盘焦点和稳定布局 |
| 角色选择 | `Main._refresh_character_select()` 动态创建挑战条、三角色按钮和确认行 | 三角色同屏舞台、明确选中重量、起始牌/遗物摘要、挑战轨道、确认不立即开局 |
| 地图 | `MapView.gd` 已有图结构/风险预览 | 暗炉材质、路径/节点五态、风险与奖励非纯颜色表达、焦点与预览层级 |
| 事件 | 已有 `PcEventExperience` | 代价/收益 glyph、禁用原因、结果态与统一 shell/token |
| 商店 | `Main._refresh_shop()` 直接向通用 flow 堆商品与服务 | 独立 `PcShopExperience`、固定金币、分类货架、售罄/买不起/药水满/删卡柜台 |
| 篝火 | 已有 `PcCampfireExperience` 与 ForgeSelection | 统一材质、两主选择、升级前后并排、长牌组首尾可达 |
| 奖励/宝箱 | `Main._refresh_rewards/_refresh_treasure()` | 金币→卡牌→遗物/药水→继续层级，已领取/跳过/背包满状态 |
| 胜败结算 | 已有 Defeat/RunCompletion 单舞台 | 视觉情绪、统计/解锁层级、持久化失败恢复动作不丢失 |
| 设置 | `_refresh_settings_view()` 的同形按钮网格 | 分组 slider/toggle，新增 reduced motion/flash intensity/particle density 并迁移旧设置 |
| 图鉴 | `_refresh_compendium_view()` 通用工具栏与卡片 | 左 rail、搜索筛选、分类模板、未发现不泄露、空结果与长中文 |

## 当前批次

- batch_id: `delivery-batch-018-ui-ember-forge-cohesion`
- priority: P1
- risk: high
- mode: L3
- audit_scope: delta
- worktree_required: true
- verifier_required: true
- max_gap_tasks: 3
- max_high_risk_tasks: 1

| 顺序 | Task | 范围 | 复杂度 | 依赖 |
| --- | --- | --- | --- | --- |
| 1 | `delivery-batch-018a-ui-shell-menu-pages` | AppShell/ForgeTheme/Motion 基建；欢迎与角色选择迁移 | 高 | Batch 017 |
| 2 | `delivery-batch-018b-ui-run-pages` | 地图、事件、商店、篝火、奖励/宝箱迁移 | 中 | 018A |
| 3 | `delivery-batch-018c-ui-outcome-accessibility-validation` | 胜败、设置、图鉴、设置迁移、全页面视觉/性能验收 | 中 | 018A、018B |

## 统一设计契约

- colors：`bg_ink #0B0908`、`surface_forge #17130F`、`surface_wood #21170F`、`surface_blood #211012`、`text_primary #EFE7DA`、`text_muted #AAA092`、`ember #E8622C`、`brass #C9A45C`、`danger #A32633`、`block #6FA8B8`。
- spacing：4/8/12/16/24/32；radius：4/8/12；border：1/2。
- type：display 34–40、page title 24–28、section 18、body 14、caption 12、critical number 18–24。
- state：normal/hover/pressed/focus/disabled/selected/locked/claimed/danger；focus 必须有 2px 外环，状态不得只靠颜色。
- motion：micro 80–120ms、hover 120–160ms、page 220–320ms、selection 180–240ms、reward 500–700ms、outcome 600–900ms；reduced motion 关闭持续位移/呼吸/扫光/粒子，保留 80–120ms opacity 确认。
- 1280×720 正文对比度 ≥4.5:1，大字 ≥3:1；正文 ≥14px，caption ≥12px，交互热区 ≥44×44。

## MVP 兼容性与停止条件

- `Main.gd` 保留状态、存档、交易、遥测和战斗协调；页面类只消费 view model 并发出信号。
- 现有测试直接访问的 Main 字段、节点名和 telemetry probe 至少保留一个迁移周期。
- 页面不得改变卡牌/敌人/经济/奖励/存档/真人遥测语义。
- 视觉测试固定字体、随机种子、时间和粒子档，禁止用宽松全屏阈值掩盖回归。
- 任一任务出现 critical review、两次 verifier 失败、File Manifest 越界或 Main 迁移导致功能回归时停止。

## Self Review

- A/B：REQ-008 与 REQ-012 状态、代码证据、测试证据和具体缺口完整；机械统计为 0 DONE、2 PARTIAL、0 MISSING/UNTESTED/UNCLEAR（本次 delta 范围）。
- C：三个任务按基础/跑团页/结算验收分组，无循环依赖；只有 018A 标记高风险。
- D/E：技术选择、设计 token、迁移边界、回归契约和禁止事项已定死；任务产物要求延续邻近 Trellis 任务。
- H：最大风险是 1.5 万行 Main 的状态/回调断裂，已要求先 characterization test、保留 adapter、逐页迁移。
- 结论：PASS，可按用户已有确认直接创建三个任务；实现仍须逐任务 TDD 与双阶段评审。
