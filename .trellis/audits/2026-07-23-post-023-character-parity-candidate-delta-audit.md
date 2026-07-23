# 2026-07-23 Post-023 角色平衡候选 Delta Audit

## Stage State Packet

```yaml
stage_state:
  state: S6_CONFIRM
  loop_mode: L3
  audit_scope: delta
  current_round: 5
  max_rounds: 6
  open_gaps: 8
  tasks_created: 0
  tasks_completed: 0
  carry_over: 0
  critical_review_issues: 0
  next_legal_action: request-confirmation-for-delivery-batch-024-character-parity-rebaseline
  stop_conditions:
    - none
```

## Trellis 工作流上下文

| 项目 | 状态 | 本轮处理 |
| --- | --- | --- |
| Trellis 元数据 | `.trellis/.version`、`.trellis/.developer`、`.trellis/config.yaml`、`.trellis/workflow.md` 均不存在 | 延续 019-023 的 `prd/design/implement/JSONL/check/TDD/review` 产物约定 |
| `.trellis/spec/` | 不存在 | `docs/03`、`docs/09-13` 与 022/023 任务产物可解释当前行为；024-01 同时固定版本化候选证据契约 |
| 结构健康度 | `BalanceSimulator.gd=4399` 行、`test_balance_simulator.gd=2121` 行、023 runner `451` 行 | 模拟器只允许增加薄委托；角色 selector、证据摘要、gate 和 runner 必须独立文件，禁止继续扩张 023 runner |
| Spec 新鲜度 | 部分过期 | `docs/03` 仍把 `penitent_censer` 写为 1 点，生产 `relics.json` 为 2 点；024 最终晋级时必须同步修正文档，不把旧描述作为候选输入 |

## 路由、基线与审计范围

- 唯一路由：`mvp-to-delivery-delta-audit`。`docs/00-08` 源需求最新提交仍为 `df098ef`（2026-07-19），在上一轮审计前且本轮未再变化；023 业务、测试和任务证据自 `last_audited_commit=d265b1d` 后发生变化。
- Loop：L3，Round 5/6。本轮只更新受影响的 REQ-003/004/005/009，并规划一个 Batch 024；创建任务前停在确认门。
- 审计 HEAD：`4978d120a33a0eae7b004342f11c95665d4308e7`；MVP baseline：`2e3e857`。
- 023 最终裁决已版本化在 `docs/13_LAYERED_PRESSURE_REBASELINE_023.md` 与 `data/config/numerical_tree.json.campaign_rebaseline_023`：P1-P5 均通过 64 direction、均未通过 128 hard，`selected_step=""`，未生成 256 artifact，生产配置与试玩包冻结。
- 本轮不重跑旧 19,968 局 ladder。023 已足以否定“继续全局降低路线压力/提高全局稀有度”的路径；024 只为新角色候选生成新证据。

## 023 失败边界的机械重算

### P4 聚合缺口

P4 是 023 中通关率最高的候选。`docs/13` 的四档均值对应 128/角色、384/挑战的原始胜局如下：

| 挑战 | P4 胜局/384 | P4 均值 | 128 hard 合法聚合胜局 | 距下界至少缺少 |
| --- | ---: | ---: | ---: | ---: |
| C0 | 90 | 23.4375% | 104-126 | +14 |
| C1 | 63 | 16.4063% | 66-99 | +3 |
| C2 | 32 | 8.3333% | 47-88 | +15 |
| C3 | 18 | 4.6875% | 31-57 | +13 |

P4 总计 `203/1536=13.2161%`。P5 把全局卡牌稀有度改为 `60/30/10` 后，四档总胜局从 203 降到 185，且角色差、金币、牌组仍失败；因此 024 明确排除全局稀有度继续放宽。

### 128 原始整数边界

`LayeredPressureCandidateGate.gd` 的目标与容差换算为原始整数：

| 挑战 | 每挑战 384 局目标 | 每角色 128 局（含 ±3% cell 容差） |
| --- | ---: | ---: |
| C0 | 104-126 胜 | 31-46 胜 |
| C1 | 66-99 胜 | 18-37 胜 |
| C2 | 47-88 胜 | 12-33 胜 |
| C3 | 31-57 胜 | 7-23 胜 |

同一挑战角色差 `<=9%` 等价于最高与最低角色最多差 11 胜。只提高总胜局而不把胜局从 Arc 的行动密度优势重新分配给 Ember/Pyre，仍会被 hard gate 正确拒绝。

### 角色差的方向证据与证据保存缺口

023 会话中对正式 P4 报告的只读提取显示：Arc/Ember/Pyre 四挑战合计胜局为 `161/27/15`（各 512 局），第一章完成为 `356/244/148`；C0 平均出牌约 `291.4/173.2/130.9`。这些值解释了 P4 的主要矛盾是角色行动经济和累计生存，而不是统一敌人 HP。

但完整 P4 report 与 verdict 只写入 `/tmp`，会话重启后已不存在；仓库只保留 SHA、聚合均值和裁决。上述角色诊断只用于确定 024 调查方向，**不得作为任何 128/256 晋级证据**。024-01 必须把所有 gate 输入的 12 行原始摘要、primary/repeat SHA、候选身份和 failure codes 写入版本化 compact evidence；没有该文件时 runner 必须 fail-closed。

## 机械根因边界

| 角色 | 当前开局 | 可复核的结构问题 | 024 允许的校准方向 |
| --- | --- | --- | --- |
| Arc | 3 `spark_throw`、2 `pressure_probe`、2 `soot_step`、2 `ash_guard`、1 `static_primer`；配置初始势能 1，`arc_capacitor` 再给 1 | 4 张 0 费牌、4 张过牌、2 点实战开局势能；免费行动和过牌密度远高于另外两角 | 降为 1 点实战开局势能，逐级减少免费攻击/无条件攻击过牌，保留低费角色身份 |
| Ember | 5 `ember_strike`、4 `ash_guard`、1 `cooling_breath` | 只有 1 张条件过牌；牌组稳定但行动替换不足，P4 下难以形成中后章成熟牌组 | 用共享过牌攻击替换 1-2 张基础攻击；最高档只增加每战 2 点一次性开局护甲 |
| Pyre | 2 `ember_strike`、2 `penitent_cut`、4 `scar_guard`、`kindle_pain`、`cooling_breath` | 起始攻击只有 4 张；`penitent_censer` 要创建 `searing_wound` 才触发，起始包没有该闭环；1 点 `ash_rosary` 难以抵消跨战累计磨损 | 用专属灼烧攻击替换共享攻击，再引入一次性创口引擎；最高档只把念珠开局护甲 1 调至 3 |

第一章 21 个满血单战在 023 前置证据中全部无 pressure risk，且 P2/P3 的完整 cases 除候选 identity 外完全相同，证明三章篝火 `[2,2]` 在当前路线选择中没有产生可观察差异。024 复用 P4 作为路线/恢复底座，但不再新增全局路线或敌人候选。

## 需求追踪矩阵增量

| ID | 状态 | 023 后证据 | 精确缺口 | 024 建议 |
| --- | --- | --- | --- | --- |
| REQ-003 | PARTIAL | P1-P5 64/128 gate、repeat、裁决和生产冻结已实现 | 四档仍低于目标；P5 全局稀有度退步；角色候选不能进入现有 overlay | 角色 selector overlay、分角色有限校准、组合 128/256 门 |
| REQ-004 | PARTIAL | 三角色数据、专属卡/遗物和 v3 策略均已接线 | Arc 免费行动过强，Ember/Pyre 行动替换和累计生存不足；每挑战 9% 角色差未关闭 | 固定 A/E/Y 各三档，先单角色 64，再组合 hard gate |
| REQ-005 | PARTIAL | layer band、pressure3、campfire2、heal30 的 P4 方向最优 | P4 未被选中，生产仍是起点；继续全局降压会放大 Arc 优势 | 024 所有角色候选共用同一 P4 base，不再改变敌人或路线字段 |
| REQ-009 | PARTIAL | 023 有 report SHA、repeat identity 和 hard failure codes | `/tmp` 原始报告跨会话丢失，无法从仓库重放 12 行 gate 输入 | 版本化 compact evidence 是 64/128/256 的强制前置门 |

其余 REQ 状态不变：4 DONE、7 PARTIAL、1 MISSING，共 12 条；本轮 open gaps 仍为 8。REQ-006/008 的美术和 UI、REQ-010 网格模式、REQ-011 商业发布不混入本高风险数值批次。

## 选定 Batch 024（待确认）

`delivery-batch-024-character-parity-rebaseline`，P0，高风险，三个串行任务；024-02 是本批唯一高风险任务。

| 顺序 | 任务 | 复杂度/风险 | 交付边界 |
| --- | --- | --- | --- |
| 1 | `024-01-character-overlay-and-evidence-contract` | 中/中 | 为 `player.characters` 和指定 starter relic effect 增加 id-selector、allowlist、类型/重复/未知字段拒绝、全数据恢复；输出版本化 12 行 compact evidence；默认无 overlay 报告 byte-identical |
| 2 | `024-02-bounded-character-parity-calibration` | 高/高 | 固定 B0 与 A1-A3/E1-E3/Y1-Y3；按单角色 64 内带选择首个通过项，再运行组合 64 与 128 primary/repeat；首个门失败即按契约停机，不临时发明 A4/E4/Y4 |
| 3 | `024-03-production-256-and-playtest-package` | 中/中 | 仅组合 128 全门通过后运行 256 primary/repeat；全门通过才写生产数据、同步正式 matrix/docs 并打包最新 PC 试玩版；失败回滚且不生成新包 |

### 共享底座 B0

每个角色候选都从 023 生产起点重新应用同一 B0，不继承上一个候选的未声明值：

- 第一章普通遭遇使用 P1 layer band。
- `max_pressure_nodes_between_campfires=3`。
- 三章 campfire budget 均为 `[2,2]`。
- campfire heal 为 `30%`。
- 卡牌稀有度保持生产 `65/28/7`；P5 的 `60/30/10` 明确排除。
- 玩家 HP/能量/势能上限、敌人、挑战倍率、经济金币、选牌阈值和 `CombatState.gd` 保持冻结。

### 固定单角色候选

所有 starter deck 都精确为 10 张；表内数组即完整目标值，不使用“替换任意一张”语义。

| Step | 精确变化 |
| --- | --- |
| A1 | Arc `starting_momentum:1→0`；其余为 B0 |
| A2 | A1 + Arc deck=`[spark_throw,spark_throw,relay_strike,pressure_probe,pressure_probe,soot_step,soot_step,ash_guard,ash_guard,static_primer]` |
| A3 | A2 + Arc deck=`[spark_throw,spark_throw,relay_strike,pressure_probe,induction_coil,soot_step,soot_step,ash_guard,ash_guard,static_primer]` |
| E1 | Ember deck=`[ember_strike,ember_strike,ember_strike,ember_strike,pressure_probe,ash_guard,ash_guard,ash_guard,ash_guard,cooling_breath]` |
| E2 | Ember deck=`[ember_strike,ember_strike,ember_strike,pressure_probe,pressure_probe,ash_guard,ash_guard,ash_guard,ash_guard,cooling_breath]` |
| E3 | E2 + `ember_bottle` 的 `combat_start/gain_block amount:3→5` |
| Y1 | Pyre deck=`[brand_strike,brand_strike,penitent_cut,penitent_cut,scar_guard,scar_guard,scar_guard,scar_guard,kindle_pain,cooling_breath]` |
| Y2 | Pyre deck=`[brand_strike,brand_strike,penitent_cut,penitent_cut,scar_guard,scar_guard,scar_guard,scar_guard,kindle_pain,wound_offering]` |
| Y3 | Y2 + `ash_rosary` 的 `combat_start/gain_block amount:1→3` |

候选只引用现有卡牌和现有效果，不新增战斗解释器语义。`player.player` 的旧 Ember 兼容镜像在 E1-E3 只用于 runtime production promotion 时同步；候选模拟只按 `characters[id]` 生效，overlay 必须测试不会误改镜像或其他角色。

### 单角色 64 内带与组合门

每个角色按 A1→A3、E1→E3、Y1→Y3 独立运行 `4挑战×64`，选择第一个同时满足下表原始胜局的 step；没有通过项立即写 `paused_no_arc_candidate_passed`、`paused_no_ember_candidate_passed` 或 `paused_no_pyre_candidate_passed` 并停止，不运行组合报告。

| 挑战 | 64 局内带胜局 | 选择理由 |
| --- | ---: | --- |
| C0 | 18-21 | 完整落在 27%-33% 目标的原始整数范围 |
| C1 | 11-16 | 完整落在 17%-26% 目标的原始整数范围 |
| C2 | 8-13 | 位于 12%-23% 目标内并收窄上界，使角色间最大差不超过 5/64 |
| C3 | 6-9 | 完整落在 8%-15% 目标的原始整数范围 |

三个角色都有 selected step 后，生成唯一组合候选 C1，其内容精确等于 B0 加三个角色各自第一个通过的 A/E/Y step：

1. 组合 64 必须再次通过四档目标、每挑战角色差 `<=9%`、挑战单调和身份门；失败即停机。
2. 组合 64 通过后才生成 128 primary/repeat；二者必须 byte-identical。
3. 128 复用 `LayeredPressureCandidateGate.evaluate_hard(report,128)` 的全部原始整数门：聚合目标、cell ±3%、角色差 9%、单调 1%、失败集中 50%、金币 100-180、牌组 16-19。
4. 任一 128 门失败，状态为 `paused_no_character_parity_candidate_passed`；不生成 256、不修改生产、不打包。
5. 任务 024-02 最大候选样本为：B0 `768` + 九个角色候选 `2304` + 组合 64 `768` + 组合 128 primary/repeat `3072` = `6912` 局；通过项可提前停止对应角色后续 step。

### 256 与试玩包门

- 024-03 只接受 024-02 唯一 selected 128 candidate，生成 `3×4×256` primary/repeat，共 `6144` 局；不得重新选候选。
- `evaluate_hard(report,256)`、repeat identity、静态数值树、地图 32-seed、全量回归和双阶段评审全部通过后，才把 B0、角色 deck/momentum 和两个可能的 starter relic amount 精确写入生产。
- 正式 matrix 必须由 256 report 同步，不能手改 row；`docs/03`、`docs/09`、新 `docs/14` 与 `numerical_tree.json` 同步实际 snapshot。
- 只有 `playtest_package_eligible=true` 才构建新 PC 测试包；否则保留当前已发布测试包，不用失败候选覆盖。
- Batch 024 最坏完整样本上限为 `6912+6144=13056` 局，低于 023 的 19,968 局；调试 fixture/smoke 不计为正式证据。

## 批次限制与停止条件

- `max_gap_tasks=3`，`max_high_risk_tasks=1`，隔离 worktree、verifier、严格 TDD、Stage 1 和独立强模型 Stage 2 全部必需。
- 024-01 不改变生产数据；候选 selector 只允许 Arc/Ember/Pyre 的 `starting_momentum`、完整 `starter_deck_ids`，以及 `ember_bottle/ash_rosary` 指定 combat-start amount。其他 player/card/relic path 一律拒绝。
- 024-02 不修改 `CombatState.gd`、卡牌定义、敌人、挑战、target、金币或真人 cohort；不降低 gate，不按距离选“最接近”候选。
- 024-03 的生产写入与打包是条件分支；128/256 任一失败必须回滚并保存版本化 compact evidence。
- 任一 critical、两次 verifier 失败、File Manifest 越界、候选耗尽或 Round 6 仍未通过时暂停并重新切 scope，不自动开启第 7 轮。

## Confirmation Gate

本轮未创建 Batch 024 task、未修改业务代码/生产数值/正式 matrix，也未运行新模拟或打包。需要用户确认本审计与 `delivery-batch-024-character-parity-rebaseline` 后，才能创建完整 PRD/design/implement/JSONL/check 产物；创建后再按严格 TDD 推进。
