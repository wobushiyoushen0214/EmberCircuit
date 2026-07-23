# Implementation Plan: 024-02

## 文件计划

| 步骤 | 文件 | 操作 | 精确位置 | 验证 |
| --- | --- | --- | --- | --- |
| 1 | fixtures/catalog/test | new | exact B0/A/E/Y 与 compose | AC-024-07 RED→GREEN |
| 2 | role gate/test | new | 4-case 64 raw bands | AC-024-08 |
| 3 | runner/rebaseline test | new | first-pass/paused branches | AC-024-09 |
| 4 | catalog/gate/runner | extend | unique C1 + combined64 | AC-024-10 |
| 5 | runner | extend | 128 repeat + shared hard | AC-024-11 |
| 6 | runner/evidence tests | extend | digest/verdict/budget/preflight | AC-024-12/13 |
| 7 | tree/matrix/docs | conditional modify | actual verdict metadata only | AC-024-14 |
| 8 | all checks | run | regression/review | AC-024-15 |

## 结构健康度预检

| 目标 | 当前 | 阈值 | 结论 |
| --- | ---: | ---: | --- |
| 新 catalog/gate | 0 | 400 | 独立纯计算文件 |
| 新 runner | 0 | 400 | adapter/控制流；超过前下沉纯逻辑，不改 023 runner |
| 新 tests | 0 | 400 | gate 与 integration 分文件 |
| `test_numerical_balance_matrix.gd` | 426 | 400 | 只增加 024 helper/dispatcher；不做行为搬迁 |

## 有序步骤

0. 记录五个生产 JSON、正式 matrix 对象和冻结文件 SHA；跑 024-01 与 023 gate 基线。
1. 先写 exact fixture/catalog 失败断言，再创建十份 JSON 与 pure catalog。
2. 先写 role gate 全边界 RED，再实现固定 error order 与 raw totals。
3. 用 scripted adapter 写 A/E/Y first-pass、三种耗尽和“不调用后续阶段”RED，再实现 runner 控制流。
4. 写 C1 exact compose、组合 raw target/cell/gap/monotonic/selected-row RED，再最小实现。
5. 写 128 前置、repeat mismatch、shared hard call 和无 256 RED，再实现。
6. 写 AC-024-12 的 digest 缺失/I/O RED 与 AC-024-13 的预算超限 RED，接 024-01 API；每步复跑定向测试。
7. 运行真实 ladder 一次；按唯一真实状态写 compact evidence、tree metadata 与 docs/14。
8. 跑全部自检、最小实现收敛并更新 tdd-progress；不 commit，进入双阶段评审。

## 修改边界

- 允许：PRD File Manifest 与本任务流程产物。
- 禁止：生产五 JSON 的值、正式 matrix 对象、cards/enemies/encounters/challenges/CombatState、AI/真人 cohort、版本和 build。
- 不得改变：024-01 digest、023 hard gate、v3 paired 80-turn semantics。
- 禁止依赖：第三方库、autoload、editor plugin。

## 失败恢复

- exact/catalog 失败：只修 fixture 或 pure validator，不改候选值。
- role/combined gate 与预期冲突：用整数分子/分母重算，不读 rounded rate。
- report/repeat/digest 写失败：保留已生成 artifact，返回固定 paused/error，不继续下一阶段。
- 无 candidate：写对应 paused verdict，确认五个生产 JSON 与 matrix 起点语义相同，取消 024-03。
- 回归失败：进入 `trellis-debug-systematic-zh`，最多 3 轮，不扩大 File Manifest。
