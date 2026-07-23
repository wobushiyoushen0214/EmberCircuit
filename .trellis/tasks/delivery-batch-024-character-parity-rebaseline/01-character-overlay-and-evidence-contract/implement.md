# Implementation Plan: 024-01

## 文件计划

| 步骤 | 文件 | 操作 | 精确位置 | 验证 |
| --- | --- | --- | --- | --- |
| 1 | `tests/test_character_balance_candidate_overlay.gd` | new | AC-024-01/02 tests | 新测试先 RED |
| 2 | overlay + selector | modify/new | constants、validation、apply delegate | selector tests GREEN |
| 3 | `tests/test_balance_candidate_runtime.gd` | new | AC-024-03/06 | runtime test RED |
| 4 | `BalanceSimulator.gd` | modify | `_apply_candidate_overlay/_restore_candidate_overlay` | runtime GREEN |
| 5 | `tests/test_balance_evidence_digest.gd` | new | AC-024-04/05 | evidence test RED |
| 6 | `BalanceEvidenceDigest.gd` | new | build/write/validation | evidence GREEN |
| 7 | all manifest tests | run | self-check commands | 全绿 |

## 结构健康度预检

| 目标 | 当前行数 | 阈值 | 微重构 | 结论 |
| --- | ---: | ---: | --- | --- |
| `BalanceCandidateOverlay.gd` | 247 | 400 | 否 | selector 逻辑独立，overlay 预计低于 400 |
| `BalanceSimulator.gd` | 4399 | 400 | 不在本任务搬迁 | 只改约 50 行 apply/restore；搬迁 campaign 逻辑风险超出 File Manifest |
| `test_balance_candidate_overlay.gd` | 434 | 400 | 否 | 不继续增长，新测试独立文件 |
| 新 selector/digest/tests | 0 | 400 | 否 | 每文件目标低于 400 |

## 有序步骤

0. 不做行为搬迁；先用 editor parse 和原 overlay test 固定基线。
1. 写 AC-024-01 的 allowlist/value RED，运行单测确认 `dataset_forbidden`。
2. 最小扩展 dataset/path/value validation，复跑至 GREEN。
3. 写 AC-024-02 的唯一/缺失/重复 selector RED，实现独立 helper 至 GREEN。
4. 写 AC-024-03 的 simulator 成功/拒绝/恢复 RED，只修改 apply/restore 薄接线至 GREEN。
5. 写 AC-024-04 的 4/12 case digest RED，实现合法 build 至 GREEN。
6. 写 AC-024-05 malformed/repeat/I/O RED，补稳定错误与 write_digest 至 GREEN。
7. 执行 AC-024-06 全量自检与最小实现收敛，更新 tdd-progress，不提交。

## 修改边界

- 允许：PRD File Manifest 的源代码、测试和本任务流程产物。
- 禁止：生产 JSON、023 fixtures、LayeredPressureCandidateGate、CLI、CombatState、Main、文档数值、包体。
- 不能改变：无 overlay byte identity、旧 allowlist、v3 campaign 结算、报告 schema。
- 禁止依赖：第三方库、autoload、editor plugin。

## 失败恢复

- selector 测试出现错误实体变化：检查 deep copy 和唯一 id index，不加入回滚式原地写。
- runtime default 漂移：只检查五份 original/assigned/restored mapping，不改 campaign case 计算。
- digest malformed 崩溃：增加安全类型 accessor并返回固定错误，不放宽输入。
- 原 023 测试失败：回退新 path 分支，保持旧 dictionary path 原代码路径。
