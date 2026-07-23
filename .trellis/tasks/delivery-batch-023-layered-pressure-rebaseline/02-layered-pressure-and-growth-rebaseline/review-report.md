# 双阶段评审报告

## Review Round 1

### 被评审对象

- 任务：`delivery-batch-023-layered-pressure-rebaseline/02-layered-pressure-and-growth-rebaseline`
- diff 范围：`d265b1d..working tree staged diff`
- Stage 2 评审模型：独立强模型 reviewer `/root/stage2_review_02301`

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| AC 测试覆盖 | 通过 | - | `tests/test_map_generator.gd`、`tests/test_layered_pressure_candidate_gate.gd`、`tests/test_layered_pressure_rebaseline.gd`、`tests/test_numerical_balance_matrix.gd` | AC-023-06 至 AC-023-12 均有自动化断言与真实 artifact 证据，当前全绿。 |
| 文件清单符合 | 通过 | - | staged diff 21 files | 生产/测试/文档落点均在 PRD manifest；任务自己的 check/debug/progress/review 为流程产物。无 selected，因此三个条件生产 JSON 未修改。 |
| 禁止事项符合 | 通过 | - | full diff / frozen SHA | 未修改 simulator、CombatState、玩家/卡牌/敌人/遭遇/challenge，未引入 P6、新依赖、门槛降低或手改报告。 |
| 决策表符合 | 通过 | - | `MapGenerator.gd`、`LayeredPressureCandidateGate.gd`、runner | layer-band fallback、固定 P1-P5、64 direction、共享参数化 128/256 hard gate、首个通过停止均按决策表实现。 |
| 挂载点接线 | 通过 | - | `MapGenerator._make_node`、runner、`campaign_rebaseline_023` | selector 接入运行时；overlay 接入 simulator；runner 接 gate；无候选裁决写 numerical tree/docs。 |
| 生产/回滚分支 | 通过 | - | `data/config/numerical_tree.json`、`docs/13_LAYERED_PRESSURE_REBASELINE_023.md` | 五候选均 hard FAIL；生产配置与正式 matrix 冻结，023-03 和试玩包锁定。 |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| malformed attribution fail-closed | 不符 | critical | `LayeredPressureCandidateGate.gd:_validate_report/_raw_totals` | 错误 verdict 生成不得继续强转 Array/Dictionary。 |
| first-act raw count 范围 | 不符 | critical | `LayeredPressureCandidateGate.gd:_validate_report` | 要求 `entry_runs==runs` 且 `0<=completed_runs<=entry_runs`。 |
| runner preflight | 不符 | critical | `run_layered_pressure_ladder.gd:_validate_candidates` | runner 自身执行 exact/strict-prefix 和 32-seed 完整路径预算门。 |
| identity 严格类型 | 不符 | major | `LayeredPressureCandidateGate.gd:_validate_report` | 禁止数字/布尔强制转换，校验 schema、lower-hex SHA 和 applied field 类型。 |
| report/I/O 故障传播 | 不符 | major | `run_layered_pressure_ladder.gd:run_ladder` | 生成/保存故障必须 `ok=false`、进程退出 1。 |
| runner 分支测试 | 不符 | major | `test_layered_pressure_rebaseline.gd:_test_ladder_static_contract` | 用可执行编排覆盖 direction fail、repeat mismatch、first pass 和 I/O failure。 |

### 问题汇总（按严重度）

- **Critical（阻断）**：3；malformed attribution 崩溃、伪造 first-act raw count 可晋级、runner 未执行完整冻结 preflight。
- **Major（应修）**：3；identity 强制转换、执行/I/O 故障伪装为正常暂停、关键分支只做源码字符串断言。
- **Minor（记录后续）**：0。

### 裁决

- [x] 有 critical → 打回 `trellis-implement-tdd-zh`
- [ ] 仅 major/minor → 放行
- [ ] 全通过 → 交回编排会话推进任务状态

## Review Round 2

### 被评审对象

- 任务：`delivery-batch-023-layered-pressure-rebaseline/02-layered-pressure-and-growth-rebaseline`
- diff 范围：`d265b1d..working tree`（combined staged + unstaged diff）
- Stage 2 评审模型：独立强模型 reviewer `/root/stage2_review_02301`

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| AC 测试覆盖 | 通过 | - | `tests/test_layered_pressure_candidate_gate.gd`、`tests/test_layered_pressure_rebaseline.gd`、回归套件 | AC-023-06 至 AC-023-12 均有测试和最终运行证据。 |
| 文件清单符合 | 通过 | - | `git diff d265b1d` | 改动符合 PRD manifest；未选候选时生产 JSON 仍冻结。 |
| 禁止事项符合 | 通过 | - | frozen SHA / full diff | 未修改冻结战斗数据、正式 matrix、真人 cohort；无 P6、无降门槛、无手改报告。 |
| 决策表符合 | 通过 | - | Gate、MapGenerator、runner | 共享 128/256 hard gate、P1-P5 顺序、fail-closed 和 first-pass stop 均符合。 |
| 挂载点接线 | 通过 | - | MapGenerator、runner、numerical tree | layer selector、overlay、verdict 元数据和回滚分支均接线。 |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| 编排-计算分离 | 通过 | - | `LayeredPressureCandidateGate.gd`、runner adapter seam | Gate 保持纯计算；runner 的关键分支可通过 adapter 执行验证。 |
| 结构健康度 | 记录 | minor | `tools/run_layered_pressure_ladder.gd:32-451` | 文件约 451 行，超过 `design.md` 的 `<400` 目标；后续可拆分 preflight/graph helper，本轮不扩大范围。 |
| 简化与复用 | 通过 | - | Gate/runner/tests | 复用既有 simulator、overlay、JSON/FileAccess/HashingContext，无新依赖或重复 gate。 |
| 正确性（边界/错误/回归） | 通过 | - | Gate `_validate_report`、runner `run_ladder_with_adapter` | malformed attribution、raw count、严格身份、I/O failure、repeat mismatch 和 first-pass stop 均有可执行测试。 |
| 规范符合（spec） | 通过 | - | PRD/design/check.jsonl | 命名、错误码、冻结边界和日志证据符合任务契约。 |

### 问题汇总（按严重度）

- **Critical（阻断）**：0。
- **Major（应修）**：0。
- **Minor（记录后续）**：1；runner 文件约 451 行，超过设计目标 `<400`，不影响当前正确性或可测试性。

### 裁决

- [ ] 有 critical → 打回 `trellis-implement-tdd-zh`
- [x] 仅 major/minor → 放行；minor 记录后续重构
- [ ] 全通过 → 交回编排会话推进任务状态
