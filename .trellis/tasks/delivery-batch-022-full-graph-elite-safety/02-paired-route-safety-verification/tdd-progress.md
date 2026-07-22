# 022-02 TDD 进度

## 进度表

| AC ID | 期望可观察结果 | 测试/产物 | 测试命令 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- |
| AC-022-07 | 四 profile 使用相同 3x4x64 paired options、case axis 与 seed model | `tests/test_balance_simulator.gd`、四份 64 JSON | Godot `test_balance_simulator.gd` | done | RED：旧轴含 v1 且缺 v3；GREEN：精确切换为 current/combat-v1/v2/v3，Balance 自检通过 |
| AC-022-08 | gate 使用原始整数计数，candidate 固定为 v3 | `tests/test_balance_simulator.gd` | Godot `test_balance_simulator.gd` | done | RED：v2 unsafe/v3 safe fixture 被旧 v2 candidate 拒绝；GREEN：candidate 与整数边界 fixture 切到 v3，调试一处缩进后自检通过 |
| AC-022-09 | v3 64 FAIL 时停机且不存在 128 artifact | required artifact verifier、`verification-report.md` | Godot `test_balance_simulator.gd -- --require-route-safety-gate-artifacts` | done | 失败分支未触发：64 全门 PASS；正式运行 128 前已确认无 128 artifact，verifier 保留 FAIL 时禁止两份 128 的 fail-closed 分支 |
| AC-022-10 | 64 全 PASS 才运行四 profile 128，并验证重复 byte-identical | required artifact verifier、条件 128 JSON | 同上 | done | 初始 RED/GREEN：64 PASS 后补齐 8 份 128，主报告通过 profile/seed/axis/count/hard-gate 校验，四组 repeat byte-identical。Review Round 1 RED：64 内容改名为 128 仍可过门；GREEN：evaluator 接收 `required_iterations`，真实 64/128 调用分别精确绑定 64/128，错配 fixture fail-closed |
| AC-022-11 | current/v2 历史报告、正式 256 rows/profile/hash 不变 | `tests/test_numerical_balance_matrix.gd`、hash | Godot matrix/pressure tests | done | RED：冻结 profile 列表未显式覆盖 v3；GREEN：加入 v3 后 matrix/pressure 全绿，021→022 current/v2 byte-identical，生产 hash 不变 |

## 收尾核对

- [x] 所有适用 AC 状态为 `done`。
- [x] 无任何 AC 停留在 `red` / `green`。
- [x] `prd.md` 自检命令全集最后一次运行全绿。
- [x] 已执行最小实现收敛。
- [x] `design.md` 挂载点清单逐项已接线。
- [x] 未 commit；改动已暂存，等待 `trellis-review-twostage-zh`。

## Review Round 1 回流

- RED：独立强模型评审裁决 `C1/M0/m0`。`_load_component_gate_reports(128)` 只按文件名取报告，而 evaluator 只允许内容迭代数属于 `[64, 128]`，未要求内容精确为 128；新增 64 fixture 请求 128 的测试后，Godot 报 `Too many arguments`，证明缺少调用方契约。
- GREEN：`_evaluate_strategy_component_gate(reports, required_iterations=0)` 对非零要求做精确等值检查，并记录 `reference:required_iterations`；真实 64/128 artifact 路径分别传入 64/128。
- 回归：目标 BalanceSimulator、required artifact verifier、editor import、numerical matrix、pressure metrics、`git diff --check` 全绿；生产树 SHA-256 不变。

## 最小实现收敛

- 删除项：删除只为 flag RED 服务的同义断言；不新增平行 gate 框架。
- 复用项：复用 021 的整数 gate、原始计数校验、FileAccess byte compare 与正式 matrix hash 冻结。
- 保留项：保留四 profile/完整 3x4 axis、64→128 条件、报告内容迭代数精确绑定、坏计数 fail-closed、精确 `0.02/0.35` 边界与 128 双报告要求。
- `trellis-minimal:` 注释：无；没有临时上限或未来抽象。
