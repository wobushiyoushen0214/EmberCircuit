# 019-03 TDD 进度

| AC ID | 期望可观察结果 | 测试文件 | 测试命令 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- |
| AC-019-11 | 128 direction report schema/step/归因门全绿 | `tests/test_campaign_matrix_verification.gd` | Godot 对应 test + CLI | pending | |
| AC-019-12 | 256 12 cells 达到正式矩阵契约 | 同上 | Godot 对应 test + CLI | pending | |
| AC-019-13 | observed rows 精确来自 256 report | `tests/test_numerical_balance_matrix.gd` | Godot 对应 test | pending | |
| AC-019-14 | 全量回归、审计、smoke 全绿 | 全项目 tests/tools | 全量命令 | pending | |
| AC-019-15 | 真人/AI 隔离且 Stage 1/2 无 critical | `tests/test_playtest_evidence_gate.gd` | Godot 对应 test | pending | |

## 收尾核对

- [ ] 所有 AC done。
- [ ] observed 来源、report hash、回归输出和评审报告齐全。
- [ ] delivery state/run log 已回写；未遗漏真人 UNTESTED 状态。

## 最小实现收敛

- 删除项：pending。
- 复用项：现有 simulator/auditor/test suites。
- 保留项：来源校验、cohort 隔离、全量回归和禁止手写保护。
