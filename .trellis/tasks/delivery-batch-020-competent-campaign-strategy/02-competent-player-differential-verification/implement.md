# Implementation Plan: 020-02

## 文件计划

| 步骤 | 文件 | 操作 | 位置 | 验证 |
| --- | --- | --- | --- | --- |
| 0 | `scripts/tools/BalanceSimulator.gd` | 只搬不改行为 | 仅提取 profile/score helper，不改变 current 分支 | editor + old tests |
| 1 | `tests/test_balance_simulator.gd` | modify | competent route/reward/campfire/potion fixtures | RED AC-020-06～09 |
| 2 | `scripts/tools/BalanceSimulator.gd` | modify | competent-only helper and dispatch branches | GREEN AC-020-06～09 |
| 3 | `tools/run_balance_simulation.gd` | modify | `_parse_options` | CLI profile pass-through |
| 4 | `tests/test_numerical_balance_matrix.gd` | modify | frozen matrix assertions | AC-020-11 |
| 5 | `docs/10_STRATEGY_DIFFERENTIAL_020.md` | new | paired report evidence and gate | AC-020-10～12 |
| 6 | task `verification-report.md` | new | final status/rollback decision | AC-020-12 |

## 结构健康度预检

| 文件 | 当前规模 | 阈值 | 结论 |
| --- | ---: | ---: | --- |
| `BalanceSimulator.gd` | 2776 行 | 400 行 | 不抽离公共模拟器；只新增 profile helper，记录技术债 |
| `tools/run_balance_simulation.gd` | 66 行 | 400 行 | 否 |

## 失败恢复

- current explicit/default 不等价：回退 competent dispatch，先恢复旧分支再重跑。
- route/reward fixture 不稳定：只修 profile seed/tie-break，不改变地图生成器。
- 128 differential gate 失败：保留报告、写 `paused_no_strategy_passed`，不改任何生产数值。
