# 021-02：胜任战斗策略与精英生存硬门

## 需求 ID

- REQ-003
- REQ-004
- REQ-005
- AC-021-07 ～ AC-021-14

## 依赖与当前缺口

- 依赖：021-01 四 profile 与组件诊断契约。
- 状态：PARTIAL。
- 证据：`_choose_card(combat)` / `_score_card(...)` 不读 profile；020 v1 精英 514 访、325 死，软成熟度可被未来收益抵消。
- 风险：本批唯一高风险任务；错误 scorer 或递归预测可能破坏确定性、性能或 current/v1 历史行为。

## 交付 Loop 控制

- Loop L3；worktree/verifier 必须；Stage 2 必须强模型。
- 最大修复 2 次；最大调试假设 3 轮。
- 回滚：current/v1 scorer 变化、药水真实 state 被预测消耗、缓存键不完整、非清单文件改动、回归或 performance 失控。

## 复杂度与规划产物

- 复杂度：高；执行者只能按已定 fixture 与决策表机械实现。
- 必要产物：全部 Trellis 规划/上下文/进度/评审产物。
- `.trellis/spec/` 不存在；稳定依据为 `docs/11...`、真实 `CombatState` 调用模式和现有 simulator tests。

## 决策表

| 决策 | 固定方案 | 禁止方案 |
| --- | --- | --- |
| dispatch | `_choose_card(combat, strategy_profile)`；current/v1 调旧 scorer，combat/v2 调 competent scorer | 修改 CombatState 或替换旧 scorer |
| 首要顺序 | immediate lethal > 防止致命伤害 > 0费启动/产能/抽牌 > 状态启动 > 真实防御缺口 > 资源收益 > 一般伤害 | 固定卡名白名单 |
| 防御 | 只给 `min(block_gain, max(0,incoming-current_block))` 缺口收益；防止 lethal 额外高权重 | 无限奖励过量 block |
| 状态 | vulnerable/weak/burn 只按尚缺层数与本回合后续受益估值；已存在足量不重复虚高 | 单纯按状态字段加常数 |
| 自伤 | 若真实结算后玩家 HP≤0 则拒绝，除非同一卡先完成最终 lethal 且 CombatState 的实际顺序允许 | 只看卡面净值 |
| 目标 | 可击杀目标优先；否则按本回合威胁、HP、稳定 index 排序 | 随机目标 |
| elite gate | 仅 v2；3 个由完整缓存键派生的稳定种子；至少 2/3 胜且胜局剩余 HP 中位数≥ceil(max_hp×0.20) | 静态成熟度、单 seed 或平均 HP |
| 副作用 | 深拷贝牌组/遗物/药水/modifier，预测不能写回 state；命中 cache 复用同一判定 | 消耗真实药水 |
| 硬拒绝 | 不安全精英返回不可被前瞻收益抵消的拒绝；存在安全候选时必须非精英 | 大负分但仍可相加 |

## 文件清单

| 操作 | 文件 | 修改 |
| --- | --- | --- |
| 修改 | `tests/test_balance_simulator.gd` | 先写 lethal、防御缺口、0费顺序、状态顺序、三角色资源、自伤、多敌目标、预测门/缓存/副作用/硬拒绝 fixture。 |
| 修改 | `scripts/tools/BalanceSimulator.gd` | profile-aware choose/score/target；competent 纯 helper；v2 精英预测、完整缓存键与硬拒绝。 |
| 修改 | `docs/11_STRATEGY_COMPONENT_AUDIT_021.md` | 回写 fixture、回归、预测门与性能证据。 |
| 新建 | 本目录规划/进度/评审产物 | 保存证据。 |

## MVP 兼容性契约

- `current-greedy` 与 `competent-player-v1` 继续走原 `_score_card` 行为，020 fixtures 与报告保持兼容。
- combat/v2 只调用现有 `CombatState` 公共行为，不修改真实结算规则。
- v2 gate 只影响 optional elite 路线；地图与 encounter 数据冻结。
- 相同完整 state/cache key 的预测结果确定且无外部副作用。

## 验收标准

- [ ] AC-021-07：current/v1 的选择 fixture 与 020 基线一致；combat/v2 在可立即击杀时选可执行 lethal。
- [ ] AC-021-08：无 lethal 时先填真实防御缺口，过量护甲不会压过有效攻击/资源；防止本回合死亡的防御具有最高非 lethal 优先级。
- [ ] AC-021-09：0费抽牌/产能/启动器先于其收益牌；vulnerable/weak/burn 在能产生本回合收益时先施加，已足量状态不重复虚高。
- [ ] AC-021-10：Ember 势能、Arc 零费/产能、Pyre 自伤/灼烧各有独立 fixture；自伤安全断言符合真实结算顺序。
- [ ] AC-021-11：多敌时优先确定性 lethal，否则选择当前威胁最高目标，同输入重复结果相同。
- [ ] AC-021-12：v2 精英预测恰用 3 个稳定种子；2/3 胜且胜局 HP 中位数达 20% 才安全，边界值用 `ceil`。
- [ ] AC-021-13：缓存键覆盖角色、挑战、遭遇、HP/maxHP、牌组及升级、遗物、药水、成长来源、combat profile；预测前后真实药水/state 深度相等。
- [ ] AC-021-14：不安全精英为硬拒绝，未来宝箱/事件收益不能抵消；有安全后继时选择非精英；相关回归全绿。

## 自检命令

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_simulator.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_combat_core.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_numerical_balance_matrix.gd
```

## 解锁与范围外

- 解锁：021-03 paired verification。
- 不改生产数值、CombatState、地图、正式 matrix、真人报告；不为 fixture 硬编码具体卡 ID 分支；不新增随机源或依赖。
