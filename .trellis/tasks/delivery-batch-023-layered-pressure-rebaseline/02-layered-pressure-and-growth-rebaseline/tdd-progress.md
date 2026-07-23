# 023-02 TDD 进度

| AC ID | RED 测试 | GREEN 期望 | 状态 |
| --- | --- | --- | --- |
| AC-023-06 | layer band 未被 MapGenerator 读取 | 指定层池准确，legacy/malformed fallback 不变 | done |
| AC-023-07 | raw 64/128/256 gate 与固定错误码不存在 | exact boundary、身份和样本拒绝准确，同一 hard gate 只切换预期样本数 | done |
| AC-023-08 | P1-P5 exact/prefix/32-seed 路径无契约 | 五候选静态与图预算全过 | done |
| AC-023-09 | 64 fail-closed ladder 不存在 | 每步独立 artifact，fail 不创建 128 | done |
| AC-023-10 | 128/repeat/first-pass 不存在 | 只晋级 eligible step，首个 hard pass 停止 | done |
| AC-023-11 | selected/none 生产分支未固化 | selected exact apply 或 baseline restore | done |
| AC-023-12 | 全部冻结/回归未验证 | hash、21 单战、静态、地图、matrix 全绿；Stage 1/2 无 critical | done |

## AC-023-06 证据

- RED：`test_map_generator.gd` 新增 L0、L1-L2、L3-L6、elite/boss 和 fallback 断言；运行后 7 条 layer-pool 断言失败，退出码 1。
- GREEN：`MapGenerator._encounter_pool_for_layer()` 接入 `_make_node()`；相同测试通过，退出码 0。
- 回归：Godot editor import、`test_act1_rebaseline.gd`、`test_numerical_tree_auditor.gd`、`test_numerical_balance_matrix.gd`、`test_balance_simulator.gd` 全部退出码 0。
- 最小实现：只保留一个无状态 selector；复用原有 RNG 抽取，不新增依赖，不改变 legacy/no-match 的 RNG 消耗。

## AC-023-07 证据

- RED：`test_layered_pressure_candidate_gate.gd` 首次运行因 gate 文件不存在退出码 1。
- GREEN：新增 `LayeredPressureCandidateGate.gd`；同一 raw-count fixture 的 `evaluate_hard(report, 128)` 与 `evaluate_hard(report, 256)` 均通过，64 direction 通过，固定错误码和舍入字段欺骗断言均通过。
- 边界修复：错误类型的 identity/case/attrition 字段 fail-closed 返回 `input_missing`；角色 gap 使用交叉乘法，不截断后比较。
- Stage 2 修复：严格校验 schema 整数、boolean、lower-hex SHA 和非空 applied fields；要求第一章 `entry_runs==runs` 且 `0<=completed_runs<=entry_runs`，所有非法嵌套类型均通过安全 accessor fail-closed，不再触发 `int()` 崩溃。
- 回归：editor import、地图、overlay、Act 1、NumericalTreeAuditor、正式 matrix、BalanceSimulator 全部退出码 0。
- 最小实现：gate 只消费纯报告对象；128/256 共用同一阈值常量和计算路径，未复制第二套 hard gate，也未修改 simulator 或生产 JSON。

## AC-023-08 证据

- RED：`test_layered_pressure_rebaseline.gd` 首次运行因 P1-P5 五份 fixture 不存在退出码 1。
- GREEN：五份完整累积 overlay 经生产 validator 接受；candidate id、exact changes、strict prefix、三章 x 32 seed 的完整路径/预算/分支/恢复/压力/遭遇 band 全过。
- 调试：P2 chapter_two seed 25 暴露 optional elite + treasure 组合突破 pressure 3；收紧组合检查后全绿，legacy max4 三章 32-seed digest 保持 `b61ca0a471c8797eae2d2c01efed49f8c29726042306f921d7da71520c6bae9a`。
- JSON 边界：合法 layer 数值由 JSON 解析为精确整数浮点时仍命中 band；非整数和 malformed 继续 fallback。
- 最小实现：P1-P5 只新增冻结 fixture；组合检查只在新 pressure 3 契约触发，不重排或改写 legacy max4 图。

## AC-023-09 证据

- RED：集成测试因 `run_layered_pressure_ladder.gd` 不存在退出码 1。
- GREEN：runner 固定 P1-P5，preflight 后生成 baseline 与五份真实 3x4x64 v3 attrition report；verdict 为 `direction_complete`，P1-P5 direction 均通过。
- 64 report SHA：P1 `0c393d93...a3f12`、P2 `50226352...b8a2`、P3 `18f6e4eb...15bd`、P4 `1da241b1...6565`、P5 `e4d26e4b...ff17`；完整值保存在 `/tmp/ember023-layered-ladder-verdict.json`。
- Fail-closed：纯 direction failure fixture 不能请求 hard；64 阶段完成后 `/tmp` 无任何 `ember023-P*-128*.json`。
- Stage 2 修复：runner 自身执行 exact P1-P5、strict-prefix 与五候选三章 x 32 seed 完整路径/预算/压力/恢复/分支 preflight；最终 verdict 记录 `preflight.ok=true`。
- 最小实现：AC-023-09 只生成/裁决 64；direction PASS 标为 `direction_passed_pending_hard`，128/repeat/first-pass 留给 AC-023-10。

## AC-023-10 证据

- RED：`test_layered_pressure_rebaseline.gd` 新增 shared hard gate、128 repeat artifact、repeat mismatch 和 first-pass stop 静态契约；runner 缺少三处实现时退出码 1。
- GREEN：runner 仅对 direction PASS step 生成 128 主/复跑，字节不同以 `report_repeat_mismatch` fail-closed；调用共享 `evaluate_hard(report, 128)`，首个 hard PASS 写 `selected_128_candidate` 并 `break`。
- Stage 2 修复：report/save/I/O 故障统一返回 `ok=false/status=execution_failed`；可注入 adapter 的可执行测试覆盖 direction fail、repeat mismatch、first hard pass stop 和 I/O failure，正常候选 rejection 不再与执行故障混淆。
- 最终真实 ladder：严格修复后 P1-P5 的 128 主/复跑 SHA 均逐步相同；五步全部 `rejected_hard_gate`，最终状态 `paused_no_layered_candidate_passed`，`selected_step` 为空，verdict SHA-256 为 `8b3ef30c44e1151f066447580f558a1af438edca0d845896840fbcc3c2266ff1`。
- 128 SHA：P1 `0c7387a6...7b52b`、P2 `875ee6ea...549b0`、P3 `f4c59ae3...0aa1`、P4 `7c334e05...e9eae`、P5 `d9138cd3...41d4`；完整 verdict 为 `/tmp/ember023-layered-ladder-verdict.json`。
- 最小实现：临时阶段日志和调试探针已删除；未修改 simulator、生产配置、正式 matrix 或 gate 门槛。

## AC-023-11 证据

- RED：`test_layered_pressure_rebaseline.gd` 新增 023 status/verdict/results、生产起点和正式 matrix 冻结断言；缺少 `campaign_rebaseline_023` 时 6 条元数据断言失败，退出码 1。
- GREEN：`numerical_tree.json` 写 `paused_no_layered_candidate_passed`、空 selected、verdict SHA、P1-P5 artifact/SHA/failure codes，设置 `production_applied=false`、`matrix_updated=false`、`playtest_package_eligible=false`；目标测试退出码 0。
- 生产冻结：map `9688ff52...a6090`、level tree `3a53497a...c0dc`、economy `0d2c917e...3ff6`；未写任何 P1-P5 changes，正式 matrix 仍为 current-greedy/256/paired/12 rows。
- 文档：`docs/13_LAYERED_PRESSURE_REBASELINE_023.md` 以修复后 `19,968` 局作为唯一正式证据，累计执行量 `39,936` 只作运行统计，记录五步四档胜率、SHA、失败门和 023-03/试玩包锁定结论。

## 收尾核对

- [x] P1-P5 均有真实 artifact 或明确 not-run 原因。
- [x] 没有 P6、门槛修改或 report 手改。
- [x] 生产状态与 verdict 一致，正式 matrix 未改。
- [x] Stage 1 与独立强模型 Stage 2 无阻断；Round 2 为 C0/M0/m1。

## AC-023-12 最终证据

- editor import、Gate、overlay/ladder、Act 1、NumericalTreeAuditor、正式 matrix、BalanceSimulator、MapGenerator 全部退出码 0。
- 生产冻结 SHA：map `9688ff52...a6090`、level tree `3a53497a...c0dc`、economy `0d2c917e...3ff6`；六个冻结文件保持原 SHA。
- 最终 ladder preflight `ok=true`；正式样本 `19,968` 局；P1-P5 的 128 primary/repeat artifact 全部 byte-identical；没有 256 artifact。
- Stage 1 通过；独立 Stage 2 Round 2 结论 `critical=0`、`major=0`、`minor=1`，唯一 minor 为 runner 文件超过设计目标行数，记录后续重构，不阻断本批。

## 最小实现收敛

- 删除：已删除临时 runner 阶段日志和 `_debug_sequence.gd` 探针；没有保留一次性调试入口或未来扩展点。
- 复用：JSON/FileAccess/HashingContext、BalanceSimulator、BalanceCandidateOverlay 与 MapGenerator 均复用 Godot/项目既有能力；未新增依赖。
- 保留：layer-band malformed/no-match fallback、raw integer validation、固定 failure codes、artifact byte compare、P1-P5 preflight 和生产冻结属于已声明安全边界，不做简化删除。
- `trellis-minimal:`：仅 MapGenerator pressure-3 组合检查有注释；升级条件是未来生产 pressure contract 不再需要保留 legacy max4 graph digest。
