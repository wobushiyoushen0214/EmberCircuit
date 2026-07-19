# 018D-02：跑团页面真实运行时挂载

## 需求 ID

- REQ-008
- AC-018D-05 ～ AC-018D-09

## 当前缺口

- 状态：PARTIAL。
- 页面类存在且 018D-01 将补齐契约，但 `Main.gd` 未 preload/mount 五页；实际玩家流程仍使用旧内联视觉树。
- 风险：挂载跨越地图信号、事件 Dictionary、商店价格、篝火索引、奖励 v5 事务，是本批唯一高风险任务。

## 交付 Loop 控制

- 批次：`delivery-batch-018d-ui-run-page-mounts`
- Loop：L3；worktree/verifier：是/是。
- 技能：`trellis-implement-tdd-zh` / `trellis-debug-systematic-zh` / `trellis-review-twostage-zh`。
- 人工门：用户已确认 018D；实现后必须强模型 Stage 2。
- 最大修复/调试：2 / 3。
- 回滚触发：任一交易金额、奖励内容、存档事务、地图 signal 次数、事件效果、篝火索引、遥测 payload 或旧 probe 改变。

## 复杂度与产物

- 复杂度：高，已拆为五条逐页 AC。
- 产物：本目录完整规划/TDD/调试/评审产物。
- Spec：无 `.trellis/spec`；evidence pack、018B PRD、reward transaction tests 为稳定契约。

## 决策表

| 决策点 | 选定方案 | 禁止方案 |
| --- | --- | --- |
| 页面路由 | 扩展 `_refresh` 和 `_set_menu_shell_active`，运行页直接 mount 到现有 AppShell host | 新建第二套路由/第二个 shell |
| VM 构建 | Main 新建 `_map/_event/_shop/_campfire/_reward_page_model` 纯 Dictionary helper | 页面读取 Main 字段或 autoload |
| Event adapter | `_on_event_page_choice_selected(id)` 从当前 event choices 精确查 id，再调用 `_on_event_choice_pressed(Dictionary)`；未找到只记录错误并返回 | 由页面传完整 Dictionary 或按 index 猜测 |
| Shop adapter | 按 id 从当前 `shop_*_options` 查 item 和真实 price，再调用原 buy 回调；未找到返回 | 信任页面传 price |
| MapView | mount 后 `Main.map_view = page.map_view`，旧实例 detach/free；所有既有测试继续访问 Main.map_view | 同时保留两个活动 MapView |
| Campfire | VM mode 由 `campfire_upgrade_selection_open` 决定；信号连接原 heal/forge/back/upgrade 回调 | 页面自己改 deck/hp |
| Reward | VM done/pending/can_continue 由 Main 现有状态生成；signals 连接原 reward/skip/save/mastery/advance/treasure 回调 | 页面推导或写 reward state |
| 兼容 probes | 在生成 VM 时继续设置现有 `last_*`，测试路径改为 `app_shell.active_page` 但 probe 名不删 | 重命名/删除 probe |

## 文件清单

| 操作 | 文件 | 精确修改 |
| --- | --- | --- |
| 修改 | `scripts/main/Main.gd` | preload 五页；新增 VM/adapter/mount helper；逐页替换 refresh 的视觉构造调用；保留业务回调 |
| 修改 | `tests/test_ember_forge_route_rooms.gd` | Main 实例真实 mount/page id/signal adapter 断言 |
| 修改 | `tests/test_map_view.gd` | Main.map_view 指向 mount page 且选择/预览各发一次 |
| 修改 | `tests/test_run_flow.gd` | 事件、商店、篝火、奖励/宝箱的 active page 与事务回归 |
| 修改 | `tests/test_playtest_run_integration.gd` | 奖励 v5 部分领取/恢复与页面状态一致 |
| 修改 | `tests/test_visual_bounds.gd` | 五页边界断言从旧 reward_row 根迁到 active page |

## 挂载点

| 挂载点 | 位置 | 动作 |
| --- | --- | --- |
| 路由可见性 | `Main._refresh/_set_menu_shell_active` | map/event/shop/campfire/treasure/reward 状态显示 AppShell |
| Map | `_refresh_map_choices` | configure/mount MapPage，连接原两个回调，更新 Main.map_view |
| Event/Shop/Campfire | 对应 `_refresh_*` | configure/mount page，连接 adapter/原回调 |
| Reward/Treasure | `_refresh_rewards/_refresh_treasure` | 在状态生成后 mount RewardPage，连接所有原事务回调 |
| 返回/清理 | AppShell page change | 旧 page queue_free，无节点累积 |

## 实现步骤

1. RED AC-05：新增真实 Main MapPage mount 断言，看到仍无 preload/mount；GREEN 只挂 Map 并跑 map tests。
2. RED AC-06：新增 EventPage active root、blocked/unknown id、真实 choice effect 断言；GREEN 只挂 Event。
3. RED AC-07：新增 Campfire arrival/forge/back/heal/duplicate index 断言；GREEN 只挂 Campfire。
4. RED AC-08：新增 Shop store/remove/buy/disabled/unknown id 断言；GREEN 只挂 Shop，price 必须从当前 options 查。
5. RED AC-09：新增 combat reward/treasure/partial restore/mastery/continue gate 断言；GREEN 只挂 Reward/Treasure。
6. 每条 AC 绿后跑该领域原回归；全部绿后跑本任务全套并记录最小实现。

## 行为约束与错误路径

- Event/Shop/Reward 未知 id：不得调用业务回调，不改变任何状态；`push_warning` 包含页面名和 id。
- Disabled 控件自身不发 signal；adapter 仍必须二次验证当前业务条件。
- 页面重复 configure/mount 20 次后，Main 节点数回到基线，signal 不重复连接。
- reward/treasure 的 `can_continue` 完全等于现有业务门，不因 UI 简化提前放行。
- Map preview 和 select 每次用户动作只调用一次原回调。

## 验收标准

- [ ] AC-018D-05：玩家地图 active_page_id=`map`，Main.map_view 属于 MapPage；选择/预览语义不变。
- [ ] AC-018D-06：事件 active_page_id=`event`；blocked/unknown 不执行，合法 id 执行同一 Dictionary choice。
- [ ] AC-018D-07：篝火 active_page_id=`campfire`；arrival/forge/back/heal/升级真实 index 全部保留。
- [ ] AC-018D-08：商店 active_page_id=`shop`；买卡/遗物/药水、售罄/买不起/药水满、删卡/取消全部保留且不重复交易。
- [ ] AC-018D-09：战斗奖励与宝箱 active_page_id=`reward`；金币、卡/遗物/药水、skip/save/mastery/continue、部分恢复和幂等全部保留。
- [ ] 原 `last_*` probes 和兼容节点名仍可观察；全套自检无未知 ERROR/泄漏。

## 自检命令

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_ember_forge_route_rooms.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_map_view.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_run_flow.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_playtest_run_integration.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_visual_bounds.gd
```

## 依赖与解锁

- 依赖：`01-run-page-contract-completion` 全绿。
- 解锁：`03-run-page-visual-verification`。

## 范围外与禁止事项

- 不改 page 契约之外的新功能、不改 data/CombatState/SaveManager/telemetry/art assets。
- 本任务不删除大块旧 helper；只停止调用，删除留给 018D-03。
- 不改 File Manifest 外文件，不 commit/push/merge，不自行评审完成。
