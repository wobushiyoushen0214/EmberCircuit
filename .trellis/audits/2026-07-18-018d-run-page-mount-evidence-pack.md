# Batch 018D Run Page Mount Evidence Pack

日期：2026-07-18

## 结论

018B 的五个页面类不仅尚未挂入 `Main.gd`，其当前 signal/VM 也不足以无损承载真实跑团流程。018D 必须先补齐页面契约，再逐页挂载并删除旧视觉树；直接 mount 会丢失交易价格、删卡流程、篝火两阶段、奖励跳过/保存/专精等能力。

## 页面契约映射

| 页面 | 现有输入/信号 | Main 真实回调 | 当前不兼容点 | 018D 固定方案 |
| --- | --- | --- | --- | --- |
| `MapPage` | `node_selected(id)`, `node_previewed(id)`；内部新建 `MapView` | `_on_map_node_pressed(id)`, `_on_map_node_previewed(id)` | Main 构造的旧 `map_view` 仍在树内；新 page 的 MapView 未成为 `Main.map_view`，旧 probe/测试继续指向旧实例 | mount 时将 `Main.map_view` 指向 page.map_view，释放旧实例；page 信号直连原回调，VM 传 graph/available/completed/current/preview details |
| `EventPage` | `choice_selected(choice_id)`, `continue_requested` | `_on_event_choice_pressed(choice: Dictionary)` | 只发 id，真实结算、blocked reason、随机结果、一次性事件需要完整 choice Dictionary | Main VM 为每个 choice 保留公开 id/label/description/blocked_reason；adapter 按当前 event choices 精确查 id 后调用原 Dictionary 回调；未知 id 忽略并记录错误，不执行效果 |
| `ShopExperience` | `buy_card(id)`, `buy_relic(id)`, `buy_potion(id)`, `open_remove`, `remove_card(index)`, `leave` | `_on_shop_buy_*_pressed(id, price)`, `_on_shop_remove_card_pressed()`, `_on_shop_remove_card_selected(index)`, `_on_shop_remove_cancel_pressed()` | buy signal 不带 price；页面没有 remove-selection 模式、取消或离店按钮；药水槽/售罄状态只能部分显示 | VM item 带稳定 id/price/disabled_reason；Main adapter 只从当前 option 数组重新查 price，禁止信任页面价格；页面增加 `mode=store/remove`、删卡候选、取消和离店命令 |
| `CampfirePage` | `rest_requested`, `forge_requested`, `upgrade_card_requested(index)`, `leave` | `_on_campfire_heal_pressed()`, `_on_campfire_forge_pressed()`, `_on_campfire_forge_back_pressed()` 与升级卡回调 | 当前 configure 总是把全部升级候选塞入到达页；没有 forge/back/leave 的完整两阶段动作，`leave` 未接 UI | VM 固定 `mode=arrival/forge`；arrival 仅显示休息/锻造，forge 显示按真实 deck index 的候选与返回；升级仍由 Main 写牌组 |
| `RewardPage` | `claim_card/relic/potion`, `skip`, `save`, `continue_requested` | `_on_reward_*`, `_on_skip_card_reward_pressed`, `_on_skip_potion_reward_pressed`, `_on_save_pressed`, `_on_deck_mastery_pressed`, `_advance_to_next_node`, treasure callbacks | `skip/save` 没有生成按钮；单个 skip 无法区分卡牌/药水；无 mastery signal；continue 未按全部奖励完成态禁用；treasure 与 combat 的动作不同 | 扩展为 `skip_card_requested`, `skip_potion_requested`, `save_requested`, `claim_mastery(id)`；VM 固定 combat/treasure 模式、done/pending/can_continue；继续按钮按真实事务状态禁用 |

## 旧视觉构造删除点

| 路径 | 旧构造入口 | 删除前保护测试 |
| --- | --- | --- |
| Map | `_refresh_map_choices` 中旧 page region/map_view 编排 | map graph、预览、选择、旧 `last_map_*` probes |
| Event | `_add_pc_event_experience`, `_add_pc_event_story`, `_add_pc_event_decisions`, `_add_event_choice_layout` 的 PC 页面用途 | 四选项、blocked choice 不发效果、随机结果、one-time 完成 |
| Shop | `_refresh_shop`, `_refresh_shop_remove_selection` 内商品/删卡视觉树 | 买卡/遗物/药水价格与禁用、重复交易、真实 deck index 删卡 |
| Campfire | `_add_pc_campfire_experience`, `_add_pc_campfire_forge_selection` 及其纯视觉 helper | heal 精确值、forge/back、重复牌真实 index、长牌组末端可达 |
| Reward/Treasure | `_refresh_rewards`, `_refresh_treasure` 的卡/物品/action 视觉树与纯样式 helper | reward v5 恢复、部分领取、skip、save、mastery、treasure 幂等与继续门 |

只删除已被新页面完全替代的视觉 helper。状态生成、交易、存档、遥测、音频、发现记录、奖励生成和回调函数必须保留。

## 建议任务拆分

| 顺序 | Task | 复杂度 | 依赖 | 可观察验收 |
| --- | --- | --- | --- | --- |
| 1 | `01-run-page-contract-completion` | 中 | 018B | 五页 VM/signal 能表达全部真实状态；结构测试先红后绿，不改 Main 交易/状态 |
| 2 | `02-run-page-runtime-mounts` | 高 | 01 | Main preload/mount 五页并只连接原回调；玩家路径不再出现旧页面根；run-flow/事务/地图测试全绿 |
| 3 | `03-run-page-visual-verification` | 中 | 02 | 5 页 720p/900p bounds、区域 golden、20 轮路由切换节点增量和 600 帧预算通过；删除无调用旧视觉 helper |

每轮最多 3 个任务、最多 1 个高风险任务，符合 L3 批次限制。

## 预期 File Manifest

- 修改：`scripts/main/Main.gd`
- 修改：`scripts/ui/pages/MapPage.gd`
- 修改：`scripts/ui/pages/EventPage.gd`
- 修改：`scripts/ui/pages/ShopExperience.gd`
- 修改：`scripts/ui/pages/CampfirePage.gd`
- 修改：`scripts/ui/pages/RewardPage.gd`
- 修改：`tests/test_ember_forge_route_rooms.gd`
- 修改：`tests/test_run_flow.gd`
- 修改：`tests/test_playtest_run_integration.gd`
- 修改：`tests/test_visual_bounds.gd`
- 修改：`tests/test_ui_performance_budget.gd`
- 修改：`tools/render_pc_gallery.gd`
- 修改：`tools/profile_ui_performance.gd`
- 修改：`tests/fixtures/ui_visual_contracts.json`
- 修改：`tests/golden/ui_720p/03_reward_720p.png` 至 `07_campfire_720p.png` 中对应路线页金标
- 修改：`docs/02_TECHNICAL_ARCHITECTURE.md`, `docs/04_ART_AUDIO_PIPELINE.md`, `docs/06_IMPLEMENTATION_LOG.md`, `docs/07_CURRENT_STATE_AND_NEXT_STEPS.md`
- 新建：018D 的 prd/design/implement/implement.jsonl/check.jsonl/tdd-progress/debug/review 任务产物

不修改任何 data 数值表、CombatState、SaveManager schema、遥测 payload、资产清单或生产素材。

## RED 顺序

1. 页面契约 RED：缺少 shop remove/leave、campfire mode/back、reward skip/save/mastery/can_continue、event id adapter 错误路径。
2. Map/Event/Campfire mount RED：`app_shell.active_page_id` 和稳定节点根仍不是新 page。
3. Shop mount RED：交易前后页面、金币、售罄、药水满、删卡模式未由 page 驱动。
4. Reward/Treasure mount RED：部分领取、保存恢复、mastery、continue gate 未由 page 驱动。
5. 旧 helper 无引用检查 RED/收敛：只在全部集成测试绿后删除。
6. 新金标与路由切换性能 RED，生成并人工检查后 GREEN。

## 回滚触发

- 任一购买金额、奖励内容、存档事务或遥测事件变化。
- blocked event choice 仍发出效果，或未知 choice id 可执行。
- 重复点击造成二次购买、二次领取、二次治疗或二次删卡。
- MapView 选择/预览信号发射次数改变。
- 旧 `last_*` probe 或兼容节点名在迁移周期内消失。
