# Post-018C UI Delivery Delta Audit

日期：2026-07-18

## Stage State Packet

```yaml
stage_state:
  state: S3_GAP_AUDIT
  loop_mode: L3
  audit_scope: delta
  current_round: 5
  max_rounds: 6
  open_gaps: 8
  tasks_created: 0
  tasks_completed: 3
  carry_over: 3
  critical_review_issues: 0
  next_legal_action: update delivery state and request confirmation for delivery-batch-018d-ui-run-page-mounts
  stop_conditions:
    - none
```

## 工作流与审计范围

| 项目 | 结论 | 证据 |
| --- | --- | --- |
| 源需求 | 语义未变化 | `docs/00_MASTER_PLAN.md` 与玩法/内容/发布范围自 `4032b8d` 后无变更；`docs/02/04/06/07` 仅回写实现证据 |
| Loop | L3 / delta | `.trellis/delivery-state.md` 已存在；`last_audited_commit=4032b8d` 后合并 018B/018C |
| Trellis workflow/spec | 未发现 | 仓库无 `.trellis/workflow.md`、`.trellis/config.yaml`、`.trellis/.version` 或 `.trellis/spec/`，延续 018A-C 的 prd/design/implement/JSONL/check/TDD/review 产物契约 |
| 当前 HEAD | `ae87384` | 018C 已合并 `master`，工作区干净 |
| 执行画像 | 强模型规划，高风险页面挂载 | 交易、奖励事务和地图信号必须保留 Main 单写入点，严格 TDD + verifier + 双阶段评审 |

## Delta Requirements Traceability Matrix

| ID | 需求 | 当前状态 | 实现证据 | 测试证据 | 精确缺口 | 建议任务 |
| --- | --- | --- | --- | --- | --- | --- |
| REQ-008 | PC 商用品质 UI、美术、动画、音频和打击感 | PARTIAL | `scripts/ui/AppShell.gd`, `scripts/ui/ForgeTheme.gd`, `scripts/ui/pages/*.gd`, `scripts/main/Main.gd`, `assets/art/generated/` | `tests/test_forge_ui_foundation.gd`, `tests/test_welcome_character_pages.gd`, `tests/test_ember_forge_route_rooms.gd`, `tests/test_ui_outcome_settings_compendium.gd`, `tests/test_visual_bounds.gd` | 欢迎、角色、结算、设置、图鉴已挂真实 AppShell；MapPage/EventPage/ShopExperience/CampfirePage/RewardPage 只存在独立 API，`Main.gd` 没有 preload/mount，实际地图、事件、商店、篝火、奖励/宝箱仍由旧内联树绘制；剩余 legacy 内容美术继续属于后续 REQ-006/008 批次 | `delivery-batch-018d-ui-run-page-mounts` |
| REQ-012 | 自动化验证、视觉防回归和可重复运行 | DONE | `tests/`, `tools/render_pc_gallery.gd`, `tools/verify_ui_visual_regression.gd`, `tools/profile_ui_performance.gd`, `tests/fixtures/ui_visual_contracts.json`, `tests/golden/ui_720p/` | 28/28 `tests/test_*.gd` 严格日志通过；11/11 区域金标通过；600 帧真实 Main profiler 通过 | 自动化基础设施与 11 页 PC 视觉门已建立。Windows release 目标机性能复测归入 REQ-011 发布门，不否定验证系统本身完成 | none |

## 完成度摘要

- 本次 delta：1 DONE、1 PARTIAL、0 MISSING、0 UNTESTED、0 UNCLEAR。
- 全量 12 项：4 DONE、7 PARTIAL、1 MISSING、0 UNTESTED、0 UNCLEAR。
- 机械比例：DONE 33.3%，PARTIAL 58.3%，MISSING 8.3%。
- open gaps：8（REQ-003/004/005/006/008/009/010/011）。

## 运行时挂载反证

- `scripts/main/Main.gd` 只 preload `WelcomePage`、`CharacterSelectPage`、`SettingsPage`、`CompendiumPage`、`OutcomePage`。
- `app_shell.mount_page(...)` 只出现在 welcome、character_select、outcome、settings、compendium 路径。
- `_refresh_map_choices/_refresh_event/_refresh_shop/_refresh_campfire/_refresh_treasure/_refresh_rewards` 仍直接清空并填充旧 `reward_row/map_view` 视觉树。
- 因此 `test_ember_forge_route_rooms.gd` 证明的是页面 API，不证明玩家实际路线已使用这些页面。

## 交付批次建议

| Batch ID | 范围 | 纳入 REQ | 排除 REQ | 风险 | 下一步动作 |
| --- | --- | --- | --- | --- | --- |
| `delivery-batch-018d-ui-run-page-mounts` | 先补齐五页缺失的 VM/signal 契约，再挂入真实 AppShell，删除对应旧视觉构造，保留 Main 事务/状态/probe；更新 5 页金标与性能/节点门 | REQ-008, REQ-012 regression | REQ-003/004/005/009 数值冻结；REQ-006 内容资产不替换；REQ-010 网格模式；REQ-011 发布管线 | high | 确认后创建契约补齐、运行时挂载、视觉验证 3 个有依赖任务，不立即写业务代码 |

## 批次执行约束

- 页面只消费 Dictionary VM 并发出 typed signal；不得直接写金币、牌组、奖励事务、地图状态或 SaveManager。
- 当前 018B 契约并非可直接挂载：Shop 缺 price adapter/remove mode/leave，Campfire 缺 arrival/forge/back，Reward 缺 card/potion 分离 skip、save、mastery 和 continue gate，Event 只发 id 而 Main 需要 Dictionary。精确映射见 `.trellis/audits/2026-07-18-018d-run-page-mount-evidence-pack.md`。
- Main 保留交易、奖励幂等、地图选择、事件完成、篝火恢复/锻造的唯一写入点。
- 五页逐一 RED→GREEN；每挂一页先跑对应 characterization test，再删除该页旧视觉构造。
- 玩家可见的禁用、售罄、已领取、部分恢复和空结果不能只靠颜色，热区不小于 44px。
- 继续使用现有暗炉/焦木/黄铜 token 与本地 Noto Sans SC；不引入 ui-ux 搜索返回的浅色 palette、外部字体或网络资源。
- 1280x720 与 1600x900 为正式 PC 门；小窗口只保留外层有界和关键动作可达烟测。
- worktree/verifier/review 必须开启；任何交易、奖励存档、地图信号或事件幂等回归立即停止。

## 阻塞项

无代码或需求阻塞。创建 018D 任务前仍需通过 Trellis S6 确认门。
