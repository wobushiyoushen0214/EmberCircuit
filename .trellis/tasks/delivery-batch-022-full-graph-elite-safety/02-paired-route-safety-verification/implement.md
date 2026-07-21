# Implementation Plan: 022-02

1. 先把 `COMPONENT_GATE_PROFILES` 与 artifact loader 改成四个 022 profile，新增 v3 candidate 的纯数据 gate RED。
2. 更新 tests 中所有 v2 candidate、旧 021 路径与 128 禁止文件断言，保证 64 fail-closed。
3. 运行四份 64 报告；只有 v3 每档门全过才运行四份 128 和重复报告。
4. 写 `verification-report.md` 与 `docs/12...`，记录命令、SHA-256、逐档 PASS/FAIL 和状态。
5. 运行完整自检、freeze hash 和 `git diff --check`。

允许修改：本任务 `tests/test_balance_simulator.gd`、`tests/test_numerical_balance_matrix.gd`、`verification-report.md`、`docs/12...`。禁止修改生产策略实现、JSON、正式矩阵或 021 文档历史结果。

