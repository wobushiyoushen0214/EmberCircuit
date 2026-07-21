# TDD 进度：021-02

| AC | 可观察结果 | 测试 | 状态 |
| --- | --- | --- | --- |
| AC-021-07 | current/v1 兼容与 lethal | `tests/test_balance_simulator.gd` | done |
| AC-021-08 | 防御缺口/防致命 | 同上 | done |
| AC-021-09 | 0费与状态顺序 | 同上 | done |
| AC-021-10 | 三角色资源与自伤安全 | 同上 | done |
| AC-021-11 | 多敌目标确定性 | 同上 | done |
| AC-021-12 | 3-seed/2-of-3/20% median | 同上 | done |
| AC-021-13 | 完整缓存键与无副作用 | 同上 | done |
| AC-021-14 | 精英硬拒绝 | 同上 | done |

## RED / GREEN 证据

- AC-021-07 RED：`tests/test_balance_simulator.gd` 调用 `_choose_card(combat, strategy_profile)` 时解析失败，提示现有签名最多 1 个参数；尚无 profile-aware combat dispatch。
- AC-021-07 GREEN：current/v1 与旧单参数选择一致；combat/v2 在过量护甲分数高于攻击的 fixture 中仍优先 exact lethal；四项自检全绿。
- AC-021-08 RED：competent 分支仍选择过量护甲，并在 5 HP/9 incoming 时选择非致命高伤攻击而非可存活的 5 block。
- AC-021-08 GREEN：competent block 只按真实缺口估值；已有足量 block 时选择有效攻击；可把必死变为存活的防御获得最高非 lethal 优先级；四项自检全绿。
- AC-021-09 RED：0 费抽牌/产能、vulnerable→攻击、weak→防御、0 费 burn→攻击四个 fixture 均被旧 additive scorer 的收益牌抢先。
- AC-021-09 GREEN：按 effect 与可支付 follow-up 识别 0 费启动和 vulnerable/weak/burn 顺序；状态达到 cap 时不再加启动权重；四项自检全绿。
- AC-021-10 RED：Ember 势能阈值、Arc 净产能启动和 Pyre 致死自伤过滤失败；真实 CombatState fixture 确认先击杀后自伤到 0 仍为 lost。
- AC-021-10 GREEN：按 effect 阈值识别势能与净产能 follow-up；致死自伤在 lethal 和一般 scorer 前均被拒绝，安全自伤/灼烧仍可选择；四项自检全绿。
- AC-021-11 RED：多个 lethal、无 lethal 高威胁、同威胁低 HP 三类 fixture 均按旧候选顺序错误选择 index 0。
- AC-021-11 GREEN：目标 rank 固定为威胁降序、HP 升序、index 升序；lethal 与非 lethal 路径均使用稳定目标优先级，重复调用完全一致；四项自检全绿。
- AC-021-12 RED：调用 `_elite_prediction_summary` 时报告 nonexistent function，3-seed predictor 与门槛 helper 尚未实现。
- AC-021-12 GREEN：纯 summary 固定 2-of-3、通常中位数和 `ceil(max_hp×0.20)`；偶数胜局取两个中间值平均，整数字段向下取整；真实 predictor 恰用 3 个唯一稳定 seed，重复输入完整结果一致；四项自检全绿。
- AC-021-13 RED：调用 `_elite_prediction_cache_key` 时报告 nonexistent function，完整 key 与 cache-hit 路径尚未实现。
- AC-021-13 GREEN：缓存键覆盖角色、挑战、遭遇、HP/maxHP、牌组及升级、遗物、药水、成长来源和 combat profile；预测只读输入 state，药水与嵌套数据前后深度相等，预置完整 key 可稳定命中；四项自检全绿。
- AC-021-14 RED：v2 仍选择缓存判定为不安全的可选精英，未记录 `elite_safety_rejected`，且前置宝箱 `14` 分可抵消后继不安全精英。
- AC-021-14 GREEN：仅 v2 启用预测硬门；直达不安全可选精英被剔除，路线前瞻的硬拒绝 sentinel 会向父路径传播，forced elite/current/v1 保持原行为；预测未命中由路线编排层写入 state-local cache；四项自检全绿。
- Review Round 1 RED：独立 `gpt-5.6-sol` 评审发现 5 个 major：预测使用 combat-only 药水策略、固定 60 回合、路线 preview key 仅含遗物数量、thorn 多段反伤未计入致死、自身伤害分数可压过非致死目标威胁顺序。
- Review repair GREEN：新增 exact v2 policy cache fixture、1-turn horizon/缓存键 fixture、等数量不同遗物 preview-key fixture、真实 thorn lethal fixture、带 1 block 的高威胁目标 fixture；逐项看到 RED 后修绿。预测现使用 exact `competent-player-v2` 策略与 campaign `max_turns`，route key 覆盖完整预测输入，攻击 HP 成本模拟真实 thorn hit 顺序，非 lethal 目标严格按 threat→HP→index 选定；四项自检全绿。
- Review Round 2 RED：强模型复审发现 4 个 major：weak 单独即可避免致死时未获得生存优先级、技能护甲百分比与 plating 未进入真实护甲估算、势能启动器未识别 `lose_momentum` 可解锁后续、多段伤害未逐 hit 模拟 Boss 阶段入场护甲。
- Review Round 2 repair GREEN：逐项新增 weak-only survival、runtime skill-block bonus、plating、momentum-cost follow-up、真实 Boss phase-block fixture 并看到 RED。现按施加 weak 后的真实 incoming 判断单卡保命；competent 护甲估算按基础/条件加成→技能百分比→frail→plating 顺序；势能 helper 汇总后续牌的 `lose_momentum` 成本；immediate lethal 对敌人副本逐 hit 扣除护甲/HP，并在存活 hit 后应用已跨越阶段的入场护甲。隔离 HOME 下四项自检全绿。
- Review Round 3 RED：独立强模型裁决 `C2/M1/m0`：AOE weak 在焦点敌人已达 cap 时会漏掉其他未 weak 敌人的保命收益；predictor miss 通过全局 `seed()/shuffle()` 改写调用方 RNG；真实技能护甲/frail/plating 只进入生存奖励，未替换旧基础防御评分。
- Review Round 3 repair GREEN：新增 partial-cap AOE weak、预测 miss 全局 RNG 不变、非致死真实防御缺口三个 fixture 并逐项看到 RED。AOE 状态 cap 改为读取全部存活目标的最低层数；competent block 分数先移除 legacy block 贡献，再按真实 runtime block 只奖励防御缺口；预测使用同文件内的 `PredictionCombatState`，仅覆写洗牌与随机目标三个 RNG 入口并由私有 `RandomNumberGenerator` 驱动，真实 `CombatState` 与 current/v1 路径不变。四项自检全绿，v2 1-run/80-turn smoke 为 `real 0.25s`。
- Review Round 4 RED：独立强模型裁决 `C6/M0/m0`：partial-cap AOE weak 仍重复计算已 weak 目标收益；self vulnerable/self burn 被误当成敌方状态启动器；runtime block 漏算可用 `block_gained -> gain_block`；防致死判断漏算同一卡 self vulnerable；thorn HP 代价漏算 Boss 阶段入场护甲；thorn/lethal 漏算 `card_played -> bonus_damage`。
- Review Round 4 repair GREEN：逐项新增“只计算未达 cap 目标边际 weak 收益”、self vulnerable/self burn 不得获得启动器优先级、可用 block-gained 成长护甲、self vulnerable 防御与干净防御真实生存对比、Boss phase block × 三段 thorn、bonus damage × thorn、bonus damage 完成 immediate lethal 七组 fixture，并全部先看到 RED。competent scorer 移除 vulnerable/weak/burn 的 legacy 敌方状态常数，启动器只接受 `enemy/all_enemies`；incoming 估算按卡牌状态结算更新 self vulnerable/weak；runtime block 纳入尚未消耗的 block-gained 来源；thorn 与 lethal 逐 hit 应用阶段护甲和可用 card-played bonus damage。隔离 HOME 下四项自检全绿。
- Review Round 5 RED：独立强模型裁决 `C5/M0/m0`：partial-cap AOE weak 的 block-followup 奖励仍未要求正边际减伤；block-gained helper 漏真实触发条件；thorn/lethal 跨 damage effect 未消费 enemy vulnerable/player weak；card-played bonus 使用出牌前 momentum/status 且漏 first-turn/every-N；AOE immediate lethal 只检查 focus enemy。
- Review Round 5 repair GREEN：新增 AOE weak 零边际 block-followup、turn-2 first-turn-only block trigger、跨 damage effect vulnerable×thorn、跨 damage effect player weak、damage→vulnerable→bonus lethal、card gain momentum→条件 bonus、first-turn-only bonus、every-N attack bonus、非 focus 敌人 AOE lethal fixture，全部先看到 RED。现 weak 防御启动要求 `incoming_after_weak < incoming_before`；block trigger helper对齐真实触发条件；shadow damage 按 effect 顺序消费 vulnerable/weak 与 momentum；card-played bonus 使用卡牌结算后的状态并模拟遗物顺序/once/cadence；AOE lethal 遍历全部存活目标。隔离 HOME 下四项自检全绿。
- Review Round 6 RED：独立强模型裁决 `C2/M0/m0`：多 block effect 仍重复使用原始 frail 并只触发一次 `block_gained`；thorn/self-damage 造成的真实 HP loss 没有执行 `player_hp_lost` 遗物，后续 damage effect 与 card-played bonus 使用陈旧势能。
- Review Round 6 repair GREEN：新增“双 block + 一层 frail + once block-gained”与“第一击 thorn → HP-loss 势能 → 条件第二击 → 条件 bonus lethal”两组真实 CombatState 对照 fixture，并先稳定看到三条失败断言。现 block shadow 逐 effect 维护势能、状态与遗物 once 字典，每段获得护甲后递归模拟 `block_gained` 再消费 frail；thorn/self-damage 按实际 HP loss 立即模拟 `player_hp_lost`，并把更新后的势能/used state传入后续 effect 和 card-played 条件。隔离 HOME 下 editor import、`test_balance_simulator.gd`、`test_combat_core.gd`、`test_numerical_balance_matrix.gd` 全绿。
- Review Round 7 RED：独立强模型裁决 `C3/M0/m0`：block shadow 跳过 damage 导致 `consume_momentum` 未生效；card-played shadow 忽略 `gain_block -> block_gained` 嵌套链；immediate lethal 忽略生产中真实存在的 `create_card -> card_created -> damage_all_enemies`。
- Review Round 7 repair GREEN：新增 damage 清势能后条件 block 失效、card-played gain-block 解锁后续 bonus、创建灼伤触发全体伤害斩杀三组真实 CombatState fixture，全部先看到行为断言 RED。现 damage shadow 被三条判定路径复用，逐 effect 处理势能消费、thorn HP loss、vulnerable/weak 与阶段护甲；card-played/card-created 遗物按 owned order、once/cadence/条件顺序动态执行，gain-block 会进入 block-gained 嵌套触发，创建牌按真实数量触发。隔离 HOME 下四项自检全绿。
- Review Round 8 RED：独立强模型裁决 `C6/M0/m0`：漏 `enemy_block_broken -> damage_broken_enemy`、block 后 `counter_pressure` 随机伤害、Boss 阶段入口的创建牌/状态/递归触发、card-played 资源与护甲对启动/生存评分的影响、同一卡按 effect 顺序更新 momentum 后的条件状态，以及偶数胜局 HP 使用较低值而非通常中位数。
- Review Round 8 repair GREEN：逐项新增破盾额外伤害、唯一敌人反压斩杀、Boss 阶段创建灼伤触发全体伤害、card-played 能量启动、card-played 嵌套护甲保命、先增势能再施加 self vulnerable 的真实死亡对照，以及 `[13,15] -> 14` 通常中位数边界 fixture，全部先看到 RED。shadow 现在按真实顺序传播敌方护甲、阶段副作用、card-created/card-played 遗物、能量/势能/护甲和条件状态；精英 summary 的偶数样本取中间两值平均。隔离 HOME 下 editor import 与三项脚本回归全绿，`git diff --check` 通过。
- Review Round 9 RED：独立强模型裁决 `C2/M0/m0`：Boss shadow 跨阶段后未同步 `phase_data/intent_index/current_action`，incoming 仍读旧意图；card-played bonus 破盾并由破盾遗物击杀时提前返回，漏算真实 attack-source thorn。
- Review Round 9 repair GREEN：新增“34→33 HP 后立即切换 10 点新阶段行动并在同一敌方回合击杀玩家”与“offense forging bonus 破盾、shield-break damage 击杀后仍由第二次 thorn 杀死玩家”两组真实 `CombatState` 对照 fixture，均先稳定看到 RED。phase shadow 现同步新阶段数据与首个行动；bonus damage 保留破盾击杀标记但在返回前结算 thorn。隔离 HOME 下四项自检全绿，`git diff --check` 通过。
- Review Round 10 RED：独立强模型裁决 `C2/M0/m1`：阶段入口只模拟 self status，漏 player-target vulnerable 与 damage；新阶段 `actions=[]` 时 shadow 清空 current action，没有按生产 `_enemy_actions` 回退基础 actions；审计文档的 smoke 证据过期。
- Review Round 10 repair GREEN：新增阶段入口 vulnerable 把 10 点新行动放大到 15、阶段入口 1 点 direct damage 在出牌中击杀玩家、以及空阶段 actions 回退基础 10 点攻击三组真实 `CombatState` 对照，全部先看到 RED。phase shadow 现按挑战倍率、enemy strength/weak、player vulnerable、hits、已获得护甲与 `player_hp_lost` 顺序执行 player damage，并在阶段 actions 为空时读取基础 actions。最新 v2 1-run smoke 为 `real 0.35s`；隔离 HOME 四项自检、冻结核对与 `git diff --check` 全绿。
- Review Round 11 RED：独立强模型裁决 `C3/M0/m0`：阶段入口已发生伤害与整张牌最终 block 聚合后允许后置护甲追溯抵消；阶段 direct damage 每 hit 漏玩家 thorn；on-enter 创建牌遗物伤害递归转入更深阶段后，外层仍用陈旧 phase actions 覆写最终意图。
- Review Round 11 repair GREEN：新增“阶段 7 伤→后置 7 block 不得获得防御收益”“阶段 hit 触发玩家 thorn 完成斩杀”“phase1 create-card AOE 递归进入 phase2 后保留 20 点最终意图”三组真实对照，全部先看到 RED。future incoming 现只包含尚未发生的敌方行动；阶段逐 hit 会执行玩家 thorn 并递归转阶段；函数末尾从最新 `enemy.phase_data` 选 actions。收敛时删除不再使用的 `resolved_incoming`。隔离 HOME 四项自检、冻结核对与 `git diff --check` 全绿，最新 smoke `real 0.43s`。
- Review Round 12 RED：独立评审最终回传异常但中断前确认至少 1 个 critical：future incoming 评分仍使用出牌前 HP/current block，阶段已消耗的初始护甲可被重复用于后续行动，阶段非致死 HP loss 也未进入未来致死比较。
- Review Round 12 repair GREEN：新增“初始 5 block 被阶段 5 damage 耗尽后，未来 5 damage 必须真实掉血”与“阶段先掉 6 HP，未来 6 damage 会杀死危险线、后置 6 block 可救安全线”真实对照；先因 `_estimated_card_survival_summary` 不存在看到 RED。现共享 `_shadow_card_resolution` 输出结算后 shadow，survival summary 返回 `player_hp/block_gain/block_spent/remaining_initial_block/remaining_card_block/remaining_block/future_incoming/survives`，评分完全使用该快照。`_estimated_card_block_gain` 删除重复循环并复用 summary。目标与四项隔离回归、冻结核对、`git diff --check` 全绿；最新 smoke `real 1.01s`。
- Review Round 13 RED：独立强模型裁决 `C2/M1/m0`。其一，卡牌先获得的 4 点护甲在阶段入口被真实消费并救命后，评分只看剩余护甲而漏掉这部分已实现的生存价值；其二，future incoming 只累计 intent 摘要，未按敌人顺序执行 `damage -> apply vulnerable -> later enemy damage`；同时 fatal、lethal 与 survival 各保留一套完整卡牌结算循环，存在语义漂移和重复递归成本。
- Review Round 13 repair GREEN：新增“5 HP、先置 4 block 吸收阶段 4 damage、未来 4 damage 后剩 1 HP”和 `polluted_lab` 的“7 damage→vulnerable→15 damage 实际合计 30”两组真实 `CombatState` 对照，分别先看到选牌/summary RED。现 survival summary 显式区分 `spent_card_block` 与 `remaining_card_block`，已实际阻止阶段伤害的卡牌护甲获得防致死优先级；future turn 按敌人及 action effects 顺序执行伤害、状态、护甲、创建牌、thorn 与递归阶段，并仅对历史 intent-only fixture 使用明确 fallback。Green 收敛把 fatal、lethal、survival 统一到 `_shadow_card_resolution`，共享 `killed_any` 与最终 shadow，不再维护三套卡牌 effect 循环。目标测试、editor import、三项脚本回归、冻结核对和 `git diff --check` 全绿；最新 v2 smoke `real 0.70s`。
- Review Round 14 RED：独立复审流在完整裁决前因并发/上游 503 中断，但已确认至少 1 个 critical：future enemy turn 直接执行 action，遗漏真实 `prepare_enemy_turn()` 在行动前的敌方 block 清零与 burn 结算。可构造为 1 HP/1 burn 敌人准备 20 damage；真实 burn 先杀敌且不攻击，shadow 却误判 20 incoming/玩家死亡。
- Review Round 14 repair GREEN：新增 1 HP、7 block、1 burn 敌人与 20 damage action 的真实 `CombatState` 对照，确认回合开始先清 block、burn 击杀且玩家保持 10 HP；summary 断言先稳定 RED。最小修复仅在 `_simulate_shadow_enemy_turn` 的每敌人行动前按生产顺序清 block、扣 burn/衰减层数、跳过已死亡敌人，并在存活时检查 burn 触发的 Boss 阶段。目标测试与隔离 HOME 四项回归、冻结核对、`git diff --check` 全绿；最新 smoke `real 0.67s`。
- Review Round 15 RED：独立强模型裁决 `C2/M0/m0`。其一，burn 触发阶段入口后，入口 damage→玩家 thorn 或 create-card relic 可嵌套击杀 Boss；真实 `prepare_enemy_turn()` 会再次检查 HP 并跳过行动，shadow 只检查玩家 HP，仍执行死敌 action。其二，burn 引发的阶段入口伤害虽真实扣除 shadow HP/block，却未累加到 `future_incoming`，使真实防御缺口少算入口伤害。
- Review Round 15 repair GREEN：先新增“2 HP Boss→1 burn→阶段入口 1 damage→玩家 thorn 反杀→不执行 20 damage action”fixture，summary 先稳定 RED；只补 phase 后 enemy HP 复查即 GREEN。再新增“burn 跨阶段入口 4 damage→新阶段 action 6 damage”的 10 点总压力 fixture，先看到 summary 仅返回 6 的 RED。现 future shadow 在模拟入口重置 `phase_incoming`，阶段 damage 递归累计，最终与 action incoming 合并；card-time 已结算阶段伤害不会泄漏到 future。隔离 HOME 四项回归、冻结核对、`git diff --check` 全绿；最新 smoke `real 0.58s`。
- Review Round 16 RED：独立强模型裁决 `C1/M0/m0`：真实 `prepare_enemy_turn()` 先为全部敌人清 block、结算 burn/阶段，再由 `resolve_prepared_enemy_turn()` 执行全部 action；shadow 却按每个敌人 prepare 后立刻 action。后排 burn 阶段先给玩家 vulnerable 时，生产中前排 10 damage 随后增至 15，shadow 却先结算 10 并误判存活。
- Review Round 16 repair GREEN：新增双敌真实对照：玩家 12 HP，enemy[0] 准备 10 damage，enemy[1] 为 2/4 HP、1 burn，burn 后跨 25% 阶段并给玩家 vulnerable；真实回合先全体 prepare，随后首敌 15 damage 击杀。summary 断言先稳定返回错误存活的 RED；实现仅将 `_simulate_shadow_enemy_turn` 拆为全体 prepare 与全体 action 两个稳定 index 循环后 GREEN。隔离 HOME 四项回归、冻结核对、`git diff --check` 全绿；最新 smoke `real 0.66s`。
- Review Round 17 RED：独立强模型裁决 `C1/M0/m0`：enemy resolve 后若仍有存活敌人，真实 `CombatState` 会立即调用 `_start_player_turn_internal()`，先清玩家 block、结算 player burn 并在致死时标记 lost；shadow 在 action 后直接返回 survives，漏掉下一玩家回合开场死亡。
- Review Round 17 repair GREEN：新增“玩家 2 HP，卡牌施加 self burn 2，敌人存活且 0 damage”真实对照；真实 `end_player_turn()` 在下一玩家回合 burn 致死，summary 先稳定错误返回 survives 的 RED。现 future shadow 在 actions 后先检查是否仍有存活敌人；只有战斗未胜且玩家仍活时才清 block、按直接 HP loss 结算/衰减 burn，再返回 survives。目标与隔离 HOME 四项回归、冻结核对、`git diff --check` 全绿；最新 smoke `real 0.35s`。
- Review Round 18 independent review：两个全新只读评审进程均在读取阶段因上游 `429 Too Many Requests` 超过重试上限，未形成 `C/M/m`，严格不视为通过。等待通道恢复期间，本地主会话继续完成性审计并确认一个 AC-021-10 critical：summary 已返回 next-turn self-burn 不存活，但无 block 的高伤牌在读取 survival 结果前直接返回基础高分，仍会压过安全低伤牌。
- Review Round 18 local RED/GREEN：新增“玩家 2 HP、敌人 40 HP/0 damage；危险牌先造成 30 damage 再施加 self burn 2，安全牌造成 1 damage”真实对照；危险线下一玩家回合 lost、安全线保持 2 HP，competent 选牌断言先稳定 RED。现 summary 区分 `survives_enemy_actions` 与下一玩家回合后的 `survives`；只有敌方行动后仍活、但随后由 player burn 新致死的卡牌才硬拒绝，不扩大到本来就无解的敌方致死局面。目标与隔离 HOME 四项回归、冻结核对、`git diff --check` 全绿；最新 smoke `real 0.71s`。
- Review Round 19 RED：独立强模型裁决 `C1/M0/m0`：敌方多段 damage effect 在首 hit 触发玩家 thorn，Boss 阶段入口改变 enemy strength/weak 或 player vulnerable；真实 `_damage_player` 每 hit 重新读取状态，shadow 却在整个 effect 开始时一次性快照伤害。
- Review Round 19 repair GREEN：新增“敌 2/6 HP、4×2 attack、玩家 9 HP/thorn 1；首 hit thorn 触发 33% 阶段并获得 strength 1，真实总伤害 4+5=9”对照，summary 先稳定返回 8/存活的 RED。现每个 enemy hit 都重新读取双方最新状态，同时保留 effect 开始时的 weak/vulnerable 消费快照，避免重复消费新获得的层数。隔离 HOME 四项回归、冻结核对、`git diff --check` 全绿；最新 smoke `real 0.69s`。
- Review Round 20 RED：独立强模型裁决 `C2/M0/m0`：partial lethal 直接从 immediate-lethal 分支返回，绕过下一玩家回合 self-burn 生存门；玩家多段攻击在首 hit 触发 Boss phase 后未逐 hit 读取新 vulnerable。
- Review Round 20 repair GREEN：新增“1 HP 前排 + 存活后排、击杀前排后 self burn 2”与“Boss 10 HP、4×2 首 hit 进入 60% phase 并给 vulnerable”两组真实 `CombatState` 对照，分别先看到危险牌被选和多段 lethal 漏判的 RED。immediate lethal 现在复用同一 `shadow_card_resolution` 的完整 survival summary，部分击杀且下回合自燃致死会被拒绝；玩家 damage effect 固定 effect-start momentum/hits，但每 hit 重读玩家 strength/weak 与敌方 vulnerable，仅消费 effect-start 已存在层数。隔离 HOME 下目标测试与四项完整回归全绿；可比单格 v2 smoke `real 0.55s`。
- Review Round 21：独立强模型完成完整 Stage 1/2 只读复审并独立重跑四项自检；AC-021-07～14、文件/冻结边界、决策表、五个挂载点、Round 20 两项修复、current/v1 兼容和 v2 精英硬门均通过，最终裁决 `C0/M0/m0`。
- 调试记录：max-turn 实现后断言因既有 turn 计数语义仍红，按 `debug-report.md` 定位为测试误把“执行 1 回合后在 turn=2 入口 timeout”写成 `turns<=1`；修正为 `timeout && turns==2` 后绿，未改生产 timeout 契约。
- 环境调试记录：四项回归首次复跑在默认 `user://logs` 写入阶段发生 Godot SIGSEGV；隔离 `HOME=/tmp/ember021_review_home` 后同一测试立即通过，随后 editor import 与三项脚本测试全部通过，确认是共享用户目录日志冲突而非代码失败。
- Fixture 调试记录：bonus-damage thorn fixture 初次 GREEN 后仍红，定位到所谓“安全攻击”也满足 `offense_forging` 的 attack 条件并触发第二次 thorn；只把安全候选改为不触发成长来源的 draw skill，原失败命令随即通过，生产实现未改。

## 最小实现收敛

- 没有新增依赖、文件、公开 API 或生产数据；复用现有 `CombatState`、稳定 seed、深复制、JSON 序列化与路线前瞻缓存。
- scorer、target rank、预测 summary/cache key、v2 safety gate 均保持为 `BalanceSimulator.gd` 相邻私有 helper，没有卡 ID 白名单。预测 RNG 隔离类只复用 `CombatState` 并覆写其三个随机入口，不复制结算、状态、遗物或敌人逻辑。
- 保留不可删除边界：current/v1 旧 scorer 分支、致死自伤过滤、3-seed/2-of-3/20% 门槛、完整 cache key、预测只读输入、forced elite 兼容与不可相加的硬拒绝。
- 评审修复继续复用现有真实 effect/hit/block/thorn、weak、技能护甲、plating、block-gained、card-played bonus damage 与 phase on-enter 语义；没有复制 `CombatState` 整体结算器，只增加 scorer 判定所需的最小只读预测。
- Round 8 继续复用统一 shadow effect/relic trigger 路径，没有为破盾、反压、阶段创建牌或 card-played 资源引入卡牌/遗物 ID 白名单；通常中位数直接使用排序数组与整数算术，无新依赖或抽象层。
- Round 9 只补齐生产 `_enter_enemy_phase` 已有字段同步，并移除 bonus damage 的过早返回；没有新增 helper、依赖、配置或评分权重。
- Round 10 继续在既有 phase shadow 内复用状态/HP-loss 数据结构；只新增当前评分所需的已吸收护甲与阶段直接伤害累计字段，没有新增公开 API、依赖、生产数据或权重。
- Round 11 删除无消费者的阶段伤害累计字段，只保留按 effect 顺序消费先置护甲的 `block_spent`；玩家 thorn 与最新 phase action 复用现有递归 phase helper，没有新增平行结算器。
- Round 12 把原 incoming 模拟抽成单一 `_shadow_card_resolution`，defense score、incoming helper 与 block helper 共享 survival summary，删除一整套重复 block 结算循环；没有新增依赖、生产数据、公开 API 或评分容差。
- Round 13 继续让 fatal 与 immediate lethal 复用 `_shadow_card_resolution`，只在共享返回值增加 `killed_any`；删除两套完整 effect/relic/phase 解析循环，保留目标合法性检查与全部既有真实结算 fixture。
- Round 14 未新增 helper 或并行结算器，只在现有 enemy-turn shadow 的 action 前补齐生产已有的 block/burn 顺序；复用 `_apply_shadow_phase_effects_after_hit` 处理 burn 后阶段切换。
- Round 15 继续复用同一 phase helper；仅增加 phase 后死亡复查和一个在 future-turn 开始归零的 `phase_incoming` 累计值，避免改动六个既有 bool 调用点或复制阶段解析。
- Round 16 未新增 helper、状态或权重，只把同一 enemy-turn 函数从一个交错循环拆成与生产一致的两遍循环；仍复用同一敌人副本、玩家 shadow 与 phase 累计。
- Round 17 只在同一 future-turn helper 末尾补生产已有的“战斗未结束→下一玩家回合清 block/burn”顺序，复用 `_apply_shadow_player_hp_loss` 与既有状态字典；没有模拟与生存判定无关的抽牌或 turn-start 收益。
- Round 18 只增加一个内部 `survives_enemy_actions` 观测字段并在现有 competent scorer 读取；没有新 helper、权重、依赖或生产数据，也不会改变 current/v1 scorer。
- Round 19 没有复制敌方结算器；只把既有 `_apply_shadow_enemy_damage_effect` 的伤害修正从 effect 级快照移到 hit 级读取，保留生产一致的 effect-start 状态消费语义。
- Round 20 只在 immediate-lethal 分支复用已生成的 `shadow_card_resolution`，避免为下一回合生存门重复完整解析同一张牌；没有新增并行结算器或评分权重。玩家多段伤害仅移动既有状态读取位置，保持 effect-start momentum/hit 与状态消费边界。
- 无 `trellis-minimal:` 注释；当前实现没有需要声明的临时上限或未来扩展点。

## 收尾核对

- [x] 所有 AC done；自检全绿；最小实现收敛完成。
- [x] current/v1 兼容、预测无副作用、挂载点接线均有证据。
- [x] 独立双阶段评审 `C0/M0/m0`；允许由编排会话提交 021-02。
