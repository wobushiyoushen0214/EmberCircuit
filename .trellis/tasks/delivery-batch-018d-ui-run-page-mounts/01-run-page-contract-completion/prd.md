# 018D-01：跑团页面契约补齐

## 需求 ID

- REQ-008
- AC-018D-01 ～ AC-018D-04

## 当前缺口

- 状态：PARTIAL。
- 代码：`scripts/ui/pages/MapPage.gd`, `EventPage.gd`, `ShopExperience.gd`, `CampfirePage.gd`, `RewardPage.gd`。
- 测试：`tests/test_ember_forge_route_rooms.gd` 只覆盖基本节点和少量禁用态。
- 缺口：Shop 无 remove mode/cancel/leave；Campfire 无 arrival/forge/back；Reward 无分离 skip/save/mastery/can_continue；Event 未覆盖未知/禁用信号边界；Map 未接精确 preview details。
- 风险：直接挂载会削减玩家现有操作和事务保护。

## 交付 Loop 控制

- 批次：`delivery-batch-018d-ui-run-page-mounts`
- Loop：L3；worktree/verifier：是/是。
- 技能：`trellis-implement-tdd-zh` → `trellis-debug-systematic-zh` → `trellis-review-twostage-zh`。
- 人工门：已由用户确认 018D。
- 最大修复/调试：2 / 3。
- 回滚触发：测试回归、File Manifest 越界、页面直接写业务状态、已有 signal/节点名消失。

## 复杂度与产物

- 复杂度：中。
- 执行模型：强模型编排，机械 TDD 实现。
- 必要产物：本目录全部 `prd/design/implement/implement.jsonl/check.jsonl/tdd-progress`。
- Spec：仓库无 `.trellis/spec`；以 018B PRD 和 018D evidence pack 为契约源。

## 决策表

| 决策点 | 选定方案 | 原因 | 文件 |
| --- | --- | --- | --- |
| Event 输出 | 保留 `choice_selected(choice_id)`；禁用项不发信号 | 页面不知道业务 Dictionary；Main 后续按当前事件查 id | `EventPage.gd` |
| Shop 价格 | 页面只发 item id；VM 显示 price/disabled_reason | Main 后续重新查当前 option price，防止信任视图值 | `ShopExperience.gd` |
| Shop 模式 | `mode=store/remove`；remove VM 用真实 `deck_index` | 保留重复卡准确删除 | `ShopExperience.gd` |
| Campfire 模式 | `mode=arrival/forge`；arrival 不渲染候选 | 保持现有两阶段体验 | `CampfirePage.gd` |
| Reward 信号 | 分离 `skip_card_requested`, `skip_potion_requested`, `save_requested`, `claim_mastery(id)` | 单一 skip 无法映射原回调 | `RewardPage.gd` |
| Reward 继续门 | VM `can_continue=false` 时按钮 disabled 且 tooltip 给出 `continue_reason` | 页面不自行推导事务完成度 | `RewardPage.gd` |
| Map preview | VM 传 title/risk/reward/description/successors 并调用 MapView setters | 保留现有固定详情栏 | `MapPage.gd` |

## 文件清单

| 操作 | 文件 | 精确修改 |
| --- | --- | --- |
| 修改 | `scripts/ui/pages/MapPage.gd` | configure 接入 preview detail 字段 |
| 修改 | `scripts/ui/pages/EventPage.gd` | 空选项/禁用项/未知 id 的结构与焦点语义 |
| 修改 | `scripts/ui/pages/ShopExperience.gd` | store/remove 两模式、候选、取消、离店、disabled_reason |
| 修改 | `scripts/ui/pages/CampfirePage.gd` | arrival/forge 两模式、返回/离店、候选仅 forge 显示 |
| 修改 | `scripts/ui/pages/RewardPage.gd` | 完整 typed signals、skip/save/mastery、combat/treasure、继续门 |
| 修改 | `tests/test_ember_forge_route_rooms.gd` | AC-01..04 的 RED/GREEN 结构和 signal 断言 |

## 挂载点

本任务只补齐页面内部契约，不接 Main。真正挂载由 018D-02 完成。

## 实现步骤

1. RED：在 `test_ember_forge_route_rooms.gd` 新增 Map preview、Event disabled、Shop 两模式、Campfire 两阶段、Reward 完整 action/signal 断言并看到失败。
2. GREEN AC-01：只改 Map/Event，使精确 preview 可见，禁用 choice 不发信号，空 choices 只有继续。
3. GREEN AC-02：只改 Shop，加入 store/remove mode、真实 deck index 候选、cancel/leave 和显式 disabled reason。
4. GREEN AC-03：只改 Campfire，arrival 仅两主动作，forge 才显示候选和 back。
5. GREEN AC-04：只改 Reward，加入分离 skip/save/mastery/can_continue 与 treasure 模式。
6. 运行本任务全部自检；执行最小实现收敛，不修改 Main。

## 验收标准

- [ ] AC-018D-01：MapPage 显示 VM 的精确风险/收益/描述/后继；Event disabled choice 按下不发 `choice_selected`，空选项发 continue。
- [ ] AC-018D-02：Shop store 模式有三货架、删卡、离店；remove 模式按真实 deck index 发 `remove_card`，有取消；disabled_reason 精确显示且不发购买信号。
- [ ] AC-018D-03：Campfire arrival 不出现升级候选；forge 显示所有候选并按真实 index 发信号，返回不触发升级。
- [ ] AC-018D-04：Reward combat 模式有分离 skip/save/mastery/continue；treasure 模式不显示无关 skip/save；`can_continue=false` 禁用继续。
- [ ] 所有交互热区至少 44px，disabled 控件不显示可点击手型且不进入错误路径。

## 自检命令

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_ember_forge_route_rooms.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_ui_accessibility_motion.gd
```

## 自动化测试要求

- Unit/structure：五页节点、按钮、disabled reason、mode 和 exact signal payload。
- Boundary：空 choices/items/candidates、重复 deck id 不影响真实 index、未知类型跳过不崩溃。
- Regression：018B 已有节点名与基本信号继续存在。

## 依赖与解锁

- 依赖：018B、018C。
- 解锁：`02-run-page-runtime-mounts`。

## 范围外与禁止事项

- 不修改 `Main.gd`、数据表、交易、奖励、存档、遥测或视觉金标。
- 不新增依赖、网络资源或全局状态。
- 不改文件清单之外文件，不 commit/push/merge，不自行评审完成。
