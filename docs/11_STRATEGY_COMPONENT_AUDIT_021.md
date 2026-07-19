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
- 当前安全门：等待确认后才能创建 Batch 021 Trellis tasks；确认前不写业务代码。
