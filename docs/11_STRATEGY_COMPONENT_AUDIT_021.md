# Batch 021 前置审计：策略组件消融与胜任战斗

## 1. 审计裁决

- 当前阶段：`mvp-to-delivery-delta-audit`，Loop 模式 `L3`，审计范围仅覆盖 `REQ-003/004/005/009`。
- Batch 020 的 `competent-player-v1` 不是完整胜任玩家：它改变路线、奖励、商店、篝火、升级和药水，但战斗内出牌仍调用旧 `_choose_card(combat)` / `_score_card(...)`。
- 020 的回退主要由“更主动进入精英 + 旧战斗 AI 无法承担风险”构成，不能继续靠静态路线权重或生产数值试错。
- 建议下一批为 `delivery-batch-021-strategy-component-ablation`：先建立组件消融和路线理由遥测，再实现胜任战斗策略与精英生存预测，最后执行 64 → 128 paired gate。
- 在 021 通过前继续冻结生产 JSON、正式 256 matrix、真人 cohort、`CombatState.gd` 和默认 `current-greedy`。

## 2. Trellis 与基线

| 项 | 值 |
| --- | --- |
| Trellis workflow/config/spec | 未提供；沿用现有任务中的 `prd.md`、`design.md`、`implement.md`、`implement.jsonl`、`check.jsonl`、`tdd-progress.md`、`review-report.md` 产物契约 |
| MVP baseline | `2e3e857` |
| 上次策略审计提交 | `d550003` |
| 本次代码基线 | `0e45202` |
| 020 正式诊断 | `/tmp/ember020-current-greedy-128.json`、`/tmp/ember020-competent-player-v1-128.json` |
| 021 只读探针 | `/tmp/ember021-strategy-audit.json` |
| 021 探针 SHA-256 | `6db74ddbdef1a737424ffb59e42715454d2d246b348d393c70195d1fa0d5201f` |

`d550003..0e45202` 之间没有修改 `BalanceSimulator.gd`、平衡测试、生产数值、地图、正式矩阵或真人遥测；唯一业务改动是角色选择页取消整页重挂载，因此 020 策略证据仍适用。

## 3. 代码证据

### 3.1 战斗 profile 没有进入出牌决策

- `scripts/tools/BalanceSimulator.gd:821-872`：`strategy_profile` 传入 `_try_use_potion(...)`，但出牌固定调用 `_choose_card(combat)`。
- `scripts/tools/BalanceSimulator.gd:908-1000`：`_choose_card` 和 `_score_card` 不读取 profile，也没有 lethal line、出牌顺序、能量利用或角色资源策略分支。
- 因此 `competent-player-v1` 的战斗升级仅限更早使用部分药水，主体出牌仍是旧 greedy。

### 3.2 牌组成熟度是软分数，不是精英安全门

- `scripts/tools/BalanceSimulator.gd:1382-1400`：成熟度低于 `0.35` 时精英得到较低分，但不会被拒绝。
- `scripts/tools/BalanceSimulator.gd:1303-1321`：深度 3 路线分数直接累加当前与未来节点；宝箱 `14` 分、事件/商店等收益可以抵消低成熟精英的负分。
- `scripts/tools/BalanceSimulator.gd:1441-1457`：成熟度只按高价值牌占比和升级占比计算，不含当前挑战、实际精英胜率预测或剩余生命安全边际。
- 三名角色起始牌组的实测成熟度均为 `0.0000`；问题不是起始牌组被直接判为成熟，而是获得少量奖励后，累计路线收益仍可绕过软阈值。

### 3.3 地图提供安全路线，精英不是全局强制

- `data/config/level_tree.json` 要求每章路径预算为 `0-1` 精英，并声明 `no_forced_elite_after_treasure=true`。
- `tests/test_map_generator.gd:76-119` 验证每章同时存在 0 精英安全路线和至少一条精英路线。
- `tests/test_map_generator.gd:190-208` 验证宝箱节点存在非精英出口。
- 因此精英访问激增属于策略选择结果，不是地图预算强制结果。

## 4. 3×4×128 组件诊断

每个 profile 共 `3 角色 × 4 挑战 × 128 = 1536` 局，使用与 020 相同的 `paired_by_iteration` 和 `max_turns=80`。

| Profile | 精英访问 | 精英胜利 | 精英死亡 | 精英存活率 | 普通战访问 | 篝火访问 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `current-greedy` | 36 | 35 | 1 | 97.2% | 5673 | 2129 |
| `competent-player-v1` | 514 | 189 | 325 | 36.8% | 5412 | 1591 |

- 精英访问量增加 `14.3×`；514 次精英访问全部能由 189 胜 + 325 死解释。
- current 的精英死亡按挑战为 `1/0/0/0`，competent 为 `111/101/65/48`。
- competent 精英死亡按角色为 Ember `132`、Arc `103`、Pyre `90`。

### 4.1 精英死亡时的成熟度

| 角色 | 精英访问 | 胜 / 死 | 死亡成熟度均值 | 最小 / 最大 | 死亡时平均牌组 | 平均遗物 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Ember Exile | 165 | 33 / 132 | 0.2044 | 0.0000 / 0.4706 | 13.76 | 2.08 |
| Arc Tinker | 237 | 134 / 103 | 0.2104 | 0.0714 / 0.3333 | 13.64 | 2.04 |
| Pyre Ascetic | 112 | 22 / 90 | 0.2138 | 0.0769 / 0.4531 | 13.30 | 2.01 |

死亡成熟度均值都远低于 `0.35`，且多数死亡发生在仍只有两件起始遗物附近。现有“成熟度阈值”没有形成可判定的精英准入条件。

## 5. 需求 Delta Matrix

| REQ | 状态 | 已有证据 | 本次确认的缺口 | 021 目标 |
| --- | --- | --- | --- | --- |
| REQ-003 数值树/难度 | PARTIAL | 017 正式 256 matrix、019/020 paired 报告 | 未分离路线策略与战斗策略，不能判断低胜率应归因于 AI 还是生产数值 | 先以组件消融证明策略贡献，不直接改数值 |
| REQ-004 角色与构筑 | PARTIAL | 三角色数据、奖励评分、成长系统 | 战斗 AI 不理解 lethal、防御缺口、能量顺序、状态顺序和角色资源；Pyre/Ember 精英存活明显不足 | 加入可测试的胜任战斗策略，并用真实 CombatState fixture 验证 |
| REQ-005 敌人/遭遇 | PARTIAL | 压力预算、单战 21/21 pressure contract、失败集中度 | 路线只读静态 HP/峰值伤害，未用当前牌组/遗物/挑战预测精英生存 | 用小样本确定性精英战预测作为硬准入，不改敌人数据 |
| REQ-009 平衡证据 | PARTIAL | 策略 schema v1、128 确定性、卡牌/失败遥测 | 正式报告没有 node visit、optional elite offer/accept、route reason、component profile 聚合 | 增加 opt-in 组件诊断 schema 和 paired ablation 报告 |

其余 REQ 状态本轮不变。完整项目仍为 `3 DONE / 8 PARTIAL / 1 MISSING`；本批不宣称提高整体完成度，只关闭策略归因缺口。

## 6. 建议批次：delivery-batch-021-strategy-component-ablation

### 021-01：策略组件消融契约与遥测

- 优先级：P0；复杂度：中；风险：中。
- File Manifest：
  - 修改 `scripts/tools/BalanceSimulator.gd`
  - 修改 `tools/run_balance_simulation.gd`
  - 修改 `tests/test_balance_simulator.gd`
  - 更新 `docs/11_STRATEGY_COMPONENT_AUDIT_021.md`
- 固定 profile：
  - `current-greedy`：历史默认，行为与默认输出保持兼容。
  - `competent-player-v1`：020 历史 profile，继续表示 competent meta + current combat。
  - `competent-combat-v1`：current meta + competent combat。
  - `competent-player-v2`：competent meta + competent combat + elite survival gate。
- 新增 opt-in `strategy_diagnostics=component-v1`；默认关闭，关闭时 current/v1 报告不增加字段。
- 开启时 case 输出：`strategy_components`、`node_visit_counts`、`elite_visits/wins/deaths`、`optional_elite_offer_count`、`optional_elite_accept_count`、`route_choice_reason_counts`。
- 路线选择必须记录确定性 reason code，不写自由文本；同分继续按 node id 稳定排序。

### 021-02：胜任战斗策略与精英生存硬门

- 优先级：P0；复杂度：高；风险：高（本批唯一高风险任务）。
- File Manifest：
  - 修改 `scripts/tools/BalanceSimulator.gd`
  - 修改 `tests/test_balance_simulator.gd`
- `_choose_card(combat, strategy_profile)` 接收 profile；`current-greedy` 与 `competent-player-v1` 必须继续走旧 scorer。
- `competent-combat-v1` / `competent-player-v2` 至少覆盖以下独立 fixture：
  1. 可立即击杀时，lethal 优先于非致命护甲或成长牌。
  2. 无 lethal 且将受伤时，优先填补真实防御缺口，过量护甲不无限加分。
  3. 0 费抽牌/产能与状态启动器在对应收益牌前执行，不因先花完能量而丢失可用序列。
  4. vulnerable/weak/burn 等状态顺序先于受益攻击或防御；已存在状态不重复虚高评分。
  5. Ember 势能收益、Arc 零费/产能、Pyre 自伤/灼烧均有角色资源 fixture；自伤不能把玩家直接送入死亡，除非同一卡按真实结算顺序先完成最终 lethal。
  6. 多敌目标优先处理可击杀或当前威胁最高目标，且选择结果确定性。
- `competent-player-v2` 对每个精英候选执行 3 个稳定种子的只读战斗预测，输入真实角色、挑战、当前 HP、牌组、遗物、药水和成长 modifier；只有至少 `2/3` 预测胜利且胜局剩余 HP 中位数不低于 `ceil(max_hp × 0.20)` 才允许进入精英。
- 精英预测缓存键必须覆盖角色、挑战、遭遇、HP、牌组、遗物、药水、成长来源与 combat profile；预测使用药水副本，不消耗真实 state。
- 不安全精英在路线前瞻中返回硬拒绝分，宝箱或未来收益不得抵消；生成图若存在安全后继，必须选择非精英路线。

### 021-03：组件差分与停机验证

- 优先级：P0；复杂度：中；风险：中；依赖 021-01/02。
- File Manifest：
  - 修改 `tests/test_balance_simulator.gd`
  - 修改 `tests/test_numerical_balance_matrix.gd`
  - 更新 `docs/11_STRATEGY_COMPONENT_AUDIT_021.md`
  - 新建 `.trellis/tasks/delivery-batch-021-strategy-component-ablation/03-paired-component-verification/verification-report.md`
- 先运行四 profile 的 `3×4×64` paired direction gate；只有 `competent-player-v2` 满足以下全部条件才运行 128：
  - C0-C3 每档三角色平均胜率均不低于 `current-greedy`。
  - C0-C3 每档第一章完成率相对 current 的下降均不超过 `0.02`。
  - 精英访问数大于 0，且精英死亡 / 精英访问不高于 `0.35`。
  - current 默认与显式 profile 结果一致；020 v1 行为保持历史兼容。
- 64 通过后运行四 profile 的 `3×4×128`，同一 profile 重复报告必须 byte-identical；128 使用相同硬门，不扩大容差。
- 失败写 `paused_no_strategy_component_passed`；通过只解锁下一次数值候选审计，不直接修改生产数值或正式 matrix。

## 7. 禁止事项

- 不修改 `data/cards/`、`data/enemies/`、`data/encounters/`、`data/config/player.json`、`data/config/economy.json`、`data/config/numerical_tree.json`。
- 不修改 `scripts/combat/CombatState.gd`、`scripts/map/MapGenerator.gd`、`scripts/main/Main.gd`、真人遥测 schema 或试玩报告。
- 不把新 profile 设置为游戏默认，不删除/改名 `current-greedy` 或 `competent-player-v1`。
- 不把 64/128 报告写入正式 256 rows，不降低目标区间、不扩大容差、不添加 expected exception 制造通过。
- 不用单一 seed、单角色或单挑战结果替代完整 paired gate。

## 8. 自我评审

- A 状态判定：通过；四个受影响 REQ 都有具体代码、测试和报告证据，均保持 PARTIAL。
- B 完成度：通过；本轮没有把策略审计误写成完整数值交付。
- C 批次拆分：通过；契约/遥测、唯一高风险行为、最终验证三任务串行，最多 3 个任务且仅 1 个高风险。
- H 风险：通过；默认兼容、性能、递归预测、药水副作用、生产数值隔离和真人证据边界均已列明。
- 当前安全门：用户已于 2026-07-20 确认 Batch 021；021-01 已进入严格 TDD，生产数值与正式矩阵仍冻结。

## 9. 021-01 实施证据：组件契约与 opt-in 遥测

- 四个 profile 已固定为：
  - `current-greedy` → `current/current/off`
  - `competent-player-v1` → `competent/current/off`
  - `competent-combat-v1` → `current/competent/off`
  - `competent-player-v2` → `competent/competent/predictive-v1`
- CLI 与 API 均接受四个 profile；未知 profile 仍显式回退 `current-greedy`。
- `--strategy-diagnostics=component-v1` 为严格 opt-in。默认、未知 diagnostics 和 020 v1 报告不增加 021 字段；默认/显式 current 的既有兼容断言保持通过。
- 开启诊断时，report/case/sample 输出 `strategy_components`；case/sample 还输出节点访问、精英访问/胜/死、optional elite offer/accept 和路线 reason code。
- 精英计数满足 `elite_visits = elite_wins + elite_deaths`，accept 不超过 offer；路线 reason 只使用 `highest_score` 与 `stable_node_id_tiebreak`。021-02 的 `elite_safety_rejected` 将在硬门实现后接入。
- 同一 options 的完整 component report 重复 JSON 相等；早期候选同分但后续出现唯一更高分时，reason 正确记录最终 `highest_score`，不会误报已淘汰的 tie。
- 第一轮独立评审发现并打回 1 critical / 2 major：四 profile 的 diagnostics tie-break 覆盖不足、v2 meta 旧分支不完整、强制精英误计为 optional。修复后，diagnostics-on 四 profile 均稳定排序，diagnostics-off current 保留历史首候选行为；v2 的路线/奖励/篝火/升级/药水统一走 competent meta；只有存在非精英替代时才累计 optional elite。
- 后续独立复审继续补齐 current/未知/v1 关闭模式的八字段全层级隔离、sample 节点与精英 path 对账，以及 optional elite 拒绝 1/0、接受 1/1、case/sample 传播。最终强模型裁决为 `C0/M0/m0`。

### 9.1 回归结果

| 命令 | 结果 |
| --- | --- |
| Godot headless editor import/parse | PASS |
| `tests/test_balance_simulator.gd` | PASS |
| `tests/test_balance_card_telemetry.gd` | PASS |
| `tests/test_numerical_balance_matrix.gd` | PASS |

021-01 没有修改任何生产 JSON、`CombatState.gd`、地图、Main、真人报告或正式 256 rows；下一步只允许进入 021-02 的胜任战斗与精英安全门。

## 10. 021-02 实施证据：胜任战斗与精英生存硬门

- `_run_single_combat_with_loadout` 已把 exact strategy profile 传入 `_choose_card(combat, strategy_profile)`；`current-greedy` 与 `competent-player-v1` 继续调用历史 `_score_card`，只有 `competent-combat-v1` / `competent-player-v2` 使用 competent combat helper。
- 战斗 fixture 覆盖 immediate lethal、Boss 阶段护甲伪斩杀、真实防御缺口、防止致死、weak 单卡保命、技能护甲百分比/plating、可用 `block_gained -> gain_block` 成长护甲、0 费抽牌/产能、vulnerable/weak/burn 启动与状态 cap，以及 Ember 势能门槛与 `lose_momentum` 后续、Arc 净产能、Pyre 安全/致死自伤。实现按 effect 与真实可执行状态评分，没有卡 ID 白名单。
- 多敌目标固定按当前威胁降序、HP 升序、稳定 index 升序；非致死选择先锁定该词典序目标，再比较卡牌收益，因此目标的少量护甲不会把攻击转向低威胁敌人。lethal 与一般攻击路径重复输入均返回相同选择。
- v2 精英预测对完整当前战斗输入派生 3 个唯一稳定 seed，并使用真实 `competent-player-v2` 出牌与药水策略及本次 campaign 的 `max_turns`；至少 `2/3` 获胜，且胜局剩余 HP 的通常中位数达到 `ceil(max_hp × 0.20)` 才标记安全。偶数胜局取两个中间值平均；现有整数字段对 `.5` 向下取整，不改变与整数安全阈值的比较结果。
- prediction cache key 覆盖角色、挑战、遭遇、HP/maxHP、campaign max-turn horizon、牌组及升级、遗物、药水、成长来源、modifier 与 exact policy profile。route preview cache key 同样覆盖完整路线/预测输入，避免不同遗物或构筑但数量相同的汇合分支互相复用安全结果。predictor 本身只读输入并使用深复制 loadout；路线编排层负责把 miss 写入 campaign-local cache，完整 key 命中直接复用。
- 自伤安全除显式 `damage_self` 外，还按真实目标、伤害段数、护甲吸收与敌方 thorn 层数估算每段反伤；会因多段反伤死亡的“lethal”与普通攻击都会被拒绝。
- 生存判定会先计算同一卡状态结算后的真实敌方伤害：enemy/all-enemies weak 能降低对应敌人的 incoming，self vulnerable 会提高随后对玩家的真实伤害；因此表面过量护甲但会给自己 vulnerable 的牌不能冒充保命牌。weak 单独把致死降为可存活时获得最高非斩杀优先级。competent 护甲估算与 `CombatState` 对齐为条件基础值、技能护甲百分比、frail、plating、尚未消耗的 block-gained 成长护甲的真实顺序。
- AOE 状态 cap 按全部存活目标逐个计算缺失层数和边际收益：焦点敌人已 weak 不会掩盖其他未 weak 敌人的保命收益，也不会让已 weak 目标重复贡献收益。self vulnerable/self burn 不属于敌方状态启动器，不能获得攻击启动优先级。真实 runtime block 不只用于致死判断，也会替换 legacy block 的基础缺口评分，非致死局面同样按真实护甲选择。
- AOE weak 的防御 follow-up 奖励同样要求正边际减伤；仅有未达 cap 但零威胁的目标时不会获得启动器巨额奖励。block-gained 成长来源会检查 `first_turn_only`、once、势能、上下文费用/类型与 every-N 条件，不把真实不可触发的成长护甲计入生存线。
- immediate lethal 不再把多段伤害聚合为单次总伤害；它逐 hit 模拟敌人护甲与 HP，并在存活 hit 后应用已跨越 Boss 阶段的 `on_enter` 护甲，避免阶段转场造成伪斩杀。thorn HP 成本使用同一逐 hit 阶段护甲顺序，因此阶段入场护甲迫使额外命中时也会计入额外反伤。
- 可用的 `card_played -> bonus_damage` 成长来源按真实触发条件进入 immediate lethal 与 thorn HP 成本：成长伤害可以补足斩杀，也可能因为额外 thorn hit 把攻击变为致死自伤；once-per-turn/once-per-combat、势能、费用与卡牌类型条件均在估算前检查。
- thorn/lethal shadow 按卡牌 effect 顺序维护玩家势能与双方状态：enemy vulnerable 和 player weak 在各自 damage effect 结束后消费，后续 effect 不会继续复用已消费层数；卡牌先施加 vulnerable 或获得势能时，随后 `card_played` bonus 使用结算后的快照。first-turn-only、every-N attack 与 once 条件均有不可触发 fixture。
- 多段 block 现在按真实结算逐 effect 处理：每段独立计算条件基础值、技能百分比、当前 frail 与 plating，获得护甲后立即执行 `block_gained` 链及 once 状态，再消费一层 frail；因此第二段不会错误复用首段的脆弱，也不会把成长护甲压缩为单次触发。
- thorn 与显式 self-damage 的 shadow HP loss 会立即执行可用的 `player_hp_lost` 遗物，并把更新后的势能和使用状态带入同一卡后续 effect 与 `card_played` 条件。第一击尖刺触发势能、解锁条件第二击及成长伤害的真实链路已有 CombatState 对照 fixture。
- 同一卡 damage→block 的顺序也使用统一 shadow damage：damage 的 `consume_momentum` 会在后续条件 block 前清空势能；damage 触发 thorn 时，`player_hp_lost` 获得的势能则会进入后续 block 条件，避免用出牌前快照制造伪保命。
- `card_played` 遗物不再预先收集 bonus 列表，而是按真实 owned/effect 顺序动态执行。`gain_block` 会立即进入 `block_gained` 嵌套链，嵌套得到的势能可解锁同次 card-played 后续 bonus；bonus 的 thorn HP loss 也会更新再后续条件。
- `create_card` 会在卡牌存在时按创建数量执行 `card_created` 遗物；生产已有的 `ember_ritual` / `burn_forging` 全体直伤现在可被识别为 immediate lethal，并与 once 状态、阶段转场保持同一 shadow 快照。
- 敌方护甲从正数降为零时，shadow 会执行真实 `enemy_block_broken -> damage_broken_enemy` 遗物链；若额外伤害再次跨越 Boss 阶段，也继续应用同一阶段入口副作用。获得护甲后会按真实顺序执行 `block_gained`，并在只剩一个存活目标时确定性模拟 `counter_pressure` 随机伤害，避免多敌场景伪造随机斩杀。
- Boss 阶段入口 shadow 不再只估算 block，还会执行 self 状态与 `create_card -> card_created` 遗物递归链；阶段创建牌触发的全体伤害、破盾与后续阶段效果共用同一敌人副本和触发状态。
- 跨越 Boss 阶段阈值时，shadow 会与生产 `_enter_enemy_phase` 一致同步 `phase_data`、`intent_index=0` 和新阶段首个 `current_action`；因此同一卡造成转阶段后，防致死评分读取的是新阶段即将执行的攻击，而不是旧意图摘要。
- 阶段入口对玩家施加的状态与直接伤害也按生产 `_resolve_enemy_effect` 顺序模拟：敌伤使用挑战倍率、enemy strength/weak、player vulnerable 与 hits，逐段消耗当前护甲并触发 `player_hp_lost`；阶段直接伤害与后续行动共同进入本回合 incoming。若阶段没有自定义 actions，则与 `_enemy_actions` 一致回退敌人基础 actions，而不是把意图清空。
- 已发生的阶段直接伤害不会再与卡牌后续获得的护甲做总量抵扣；防御评分只读取卡牌结算后尚未发生的敌方行动，因此 `damage -> phase damage -> block` 不能获得追溯防御收益。阶段伤害每个 hit 后还会执行玩家 thorn；thorn 造成的敌人死亡或再次转阶段立即进入同一递归链。
- 防御评分现在读取共享 survival summary：阶段结算后的玩家 HP、阶段已消费的初始/卡牌护甲、仍剩余的初始/卡牌护甲以及未来行动伤害。先置护甲被阶段伤害耗尽后不会再抵第二次，阶段非致死 HP loss 也会缩小后续生存边际；后置护甲仍只对尚未发生的行动生效。
- 已消费的卡牌护甲与已消费的初始护甲分开记录：若卡牌先置护甲已在阶段入口真实吸收伤害并把玩家从死亡线救回，即使结算后剩余为零，这部分 `spent_card_block` 仍进入防致死评分；不会因只看最终 block 而错误选择必死资源牌。
- future incoming 不再只相加 intent 数字，而是按敌人和当前 action effects 的实际顺序执行。前一个敌人先造成伤害并施加 vulnerable 后，后一个敌人的攻击会使用更新后的状态；同时覆盖 enemy/player 状态、护甲、创建牌、thorn 和递归阶段。仅测试历史遗留的 intent-only action 使用显式 damage fallback。
- future enemy turn 还对齐 `prepare_enemy_turn()` 的行动前顺序：每个存活敌人先清除上回合护甲，再结算 burn；burn 击杀后跳过该敌人的 action，burn 跨 Boss 阶段时先执行新阶段入口效果并读取更新后的行动。
- burn 跨阶段的入口递归结束后会再次检查敌人 HP；若入口 damage 触发玩家 thorn，或入口创建牌触发 `card_created` 伤害并击杀 Boss，则与真实 `prepare_enemy_turn()` 一致跳过死敌行动。阶段入口对玩家造成的伤害单独在 future-turn 起点归零后累计，再与新阶段 action 合并，因此不会漏算防御缺口，也不会重复 card-time 已结算伤害。
- 多敌 future turn 与生产相同拆成两个全局阶段：第一遍按稳定敌人 index 为全部存活敌人清 block、结算 burn 和阶段入口；第二遍才按相同 index 执行当前 action。后排 burn 阶段施加的玩家 vulnerable 因而会正确影响前排随后执行的攻击，不再出现单敌 prepare→action 的交错顺序。
- enemy resolve 后若仍有存活敌人，survival shadow 会进入下一玩家回合的致死边界：先清玩家 block，再结算并衰减 player burn；burn 把 HP 降到 0 时返回不存活。若全部敌人已死，则与生产 `_check_combat_end()` 一致先判胜，不额外结算下一回合 burn。
- competent scorer 会区分“敌方行动已经致死”与“敌方行动后仍活、但下一玩家回合 self burn 新致死”。后一类非斩杀牌无论是否含 block 都被硬拒绝，避免高伤基础分掩盖确定死亡；前一类无解局面不因该规则被额外扩大拒绝范围。
- enemy multi-hit shadow 每 hit 重新读取当前 strength/weak/vulnerable；玩家 thorn 在前一 hit 触发 Boss 阶段后，阶段新增的 strength、weak 或玩家 vulnerable 会影响同一 action 的后续 hit，且只消费 action 开始时已存在的状态层数。
- immediate lethal 的候选现在也必须通过同一卡完整 survival summary；若只击杀部分敌人且下一玩家回合 self burn 会致死，则不会被 immediate-lethal 旁路提前选中；最终击杀全部敌人仍先判胜，不额外结算 burn。
- 玩家多段 damage effect 固定 effect-start 的 momentum、bonus 与 hit 数，但每个 hit 重新读取当前玩家 strength/weak 和目标 vulnerable；首 hit 触发 Boss phase 后新增的 vulnerable 会影响后续 hit，同时只消费 effect 开始时已存在的状态层数。
- 若阶段入口的创建牌遗物伤害让同一 Boss 连续跨越多个阶段，外层阶段函数结束时会从最新 `enemy.phase_data` 读取最终 actions，避免把更深阶段意图覆写回旧阶段。
- `card_played` 的抽牌、能量、势能与护甲现在进入 0 费启动、资源启动和防致死评分；`gain_block` 会继续进入 `block_gained` 嵌套链。同一卡的 incoming/status 估算按 effect 顺序维护势能、玩家状态、伤害、创建牌、护甲与 card-played 触发，避免用出牌前 momentum 判断后续条件状态。
- card-played `bonus_damage` 即使在破盾后由 `shield_break_wedge` 完成击杀，也不会提前结束 HP 成本估算；与真实 `_damage_enemy` 一致，本次 attack-source 额外伤害仍结算目标 thorn，避免把玩家与敌人同归于尽的牌误判为安全 lethal。
- all-enemies immediate lethal 会遍历全部存活目标；即使高威胁 focus 敌人未死，只要 AOE 确实击杀其他敌人，仍进入最高斩杀优先级。
- fatal、immediate lethal 与 survival 现在统一复用 `_shadow_card_resolution`；共享最终玩家快照、敌人副本和 `killed_any`，删除三套并行的卡牌 effect/relic/phase 循环，降低语义漂移与 3×4×64 验证中的重复递归成本。
- 精英预测使用继承真实 `CombatState` 的 RNG 隔离实例：仅将起始牌组洗牌、弃牌堆回洗和随机存活目标切换到预测私有 `RandomNumberGenerator`，其余结算完全复用生产实现。因此 predictor cache miss 不再调用全局 `seed()` 或消耗调用方 RNG，cache hit/miss 的外部随机状态一致。
- 仅 `competent-player-v2` 启用 `predictive-v1` safety gate。不安全可选精英使用不可与收益相加的 hard-reject sentinel；若宝箱/事件后的唯一后继是不安全精英，拒绝会向父路线传播。forced elite 不按 optional gate 拒绝，current/v1 仍使用历史路线评分。
- diagnostics 的路线理由现已包含 `elite_safety_rejected`。固定 smoke 记录 `elite_safety_rejected=1` 且没有进入精英；该 smoke 只用于接线/性能证据，不作为胜率结论。

### 10.1 回归与性能烟测

| 检查 | 结果 |
| --- | --- |
| Godot headless editor import/parse | PASS |
| `tests/test_balance_simulator.gd` | PASS（含 AC-021-07～14） |
| `tests/test_combat_core.gd` | PASS |
| `tests/test_numerical_balance_matrix.gd` | PASS |
| v2 单角色/单挑战/1 iteration campaign smoke | PASS，Round 20 可比单格 `real 0.55s`（`ember_exile/C0/max_turns=80`，受控沙箱启动），无递归预测或超时 |

最新性能 smoke 输出为 `/tmp/ember021-v2-performance-smoke-round20.json`，只验证 predictor 在 campaign 路线中可完成、不会递归进入 campaign gate；正式方向性与统计结论必须等待 021-03 的四 profile `3×4×64` paired gate，不能由该 1-run 样本推断。

021-02 没有修改生产卡牌、敌人、遭遇、角色、经济或数值树 JSON，也没有修改 `CombatState.gd`、`MapGenerator.gd`、`Main.gd`、正式 256 matrix 或真人试玩证据。完整游戏交付状态仍保持原判定，本阶段只关闭策略实现与精英安全门缺口。

021-02 最终独立双阶段复审裁决为 `C0/M0/m0`；本任务允许进入 021-03。021-03 的四 profile `3×4×64` paired verification 已完成并按硬门停机；本批不包含方向性数值通过结论、master 合并或试玩包。

## 11. 021-03 实施证据：四组件配对验证与停机裁决

四 profile 已使用完全相同的三角色、四挑战、64 iterations、80 max turns、`paired_by_iteration` 和 `component-v1` diagnostics 生成 12-case 报告。测试层 gate 从合法域内的 `wins/runs` 与第一章 `completed_runs/runs` 计算，不依赖三位小数展示率，也不会手工舍入后改变 `0.02` 边界；elite 门以 `20×deaths <= 7×visits` 判定并覆盖等号边界。显式 artifact verifier 强制四份 64 报告存在且所有 128/重复输出不存在。

| Profile | C0 胜率/第一章 | C1 胜率/第一章 | C2 胜率/第一章 | C3 胜率/第一章 | Elite 死亡/访问 |
| --- | --- | --- | --- | --- | --- |
| current | 4.69% / 40.10% | 2.08% / 27.08% | 0.52% / 11.46% | 0.52% / 5.73% | 1/15 |
| v1 meta | 5.73% / 28.65% | 4.17% / 18.23% | 0.00% / 8.85% | 0.00% / 4.17% | 157/247 |
| combat-v1 | 10.94% / 42.19% | 6.25% / 34.90% | 1.04% / 17.71% | 0.00% / 9.38% | 1/22 |
| v2 | 7.81% / 28.65% | 2.60% / 21.88% | 2.08% / 14.06% | 1.04% / 7.81% | 159/256 |

v2 的 C0-C3 胜率均不低于 current；但第一章完成率在 C0 下降 `22/192=0.11458`、C1 下降 `10/192=0.05208`，均超过 `0.02`。v2 虽有 256 次精英访问，死亡 159 次，`159/256=0.62109` 超过 `0.35`。因此 64 gate 未全过，按固定决策表写 `paused_no_strategy_component_passed`，未启动或生成 128 报告。

默认 current 与显式 `current-greedy` 的完整 64 报告 byte-identical，SHA-256 均为 `05d28aab84cd28d2b789bafcbb55f358828c838f9ba70165022e40481c9f38d0`。四份 profile 报告和逐门结果见 `03-paired-component-verification/verification-report.md`。`data/config/numerical_tree.json` SHA-256 仍为 `1f0cc2cbf45739c8b82abb92380c91138673a716d0031be0b57c5c0eacd5845e`，正式 matrix 保持 3×4×256、`current-greedy`、80 turns。

本轮只完成策略组件验证，没有证明游戏数值已经适合资深玩家，也没有解锁下一轮生产数值候选。下一步需重新审计 competent meta 与 elite safety 的组合：combat-v1 单独提高前两档进度且精英死亡率低，而 v2 仍继承 meta 的高精英暴露和死亡集中；不得通过降低门槛、扩大容差或把失败 64 报告写入正式矩阵来绕过问题。
