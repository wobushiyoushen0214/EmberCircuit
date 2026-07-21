# 021-03 四组件配对验证报告

- 日期：2026-07-21
- 最终状态：`paused_no_strategy_component_passed`
- 裁决：64 方向门未全部通过，按 AC-021-18 停止；未运行或生成 128 报告。
- 边界：没有修改策略实现、生产 JSON、`CombatState.gd`、真人试玩证据或正式 256 matrix。

## 验收结果

| AC | 结果 | 证据 |
| --- | --- | --- |
| AC-021-15 | PASS | 四 profile 均为 3 角色×4 挑战×64、`max_turns=80`、`paired_by_iteration`，每份 12 cases。 |
| AC-021-16 | PASS（验证机制）；实际 gate FAIL | 测试层 gate 使用 `wins/runs` 与 `completed_runs/runs` 原始计数；v2 胜率四档 PASS，C0/C1 第一章 FAIL，elite gate FAIL。 |
| AC-021-17 | PASS | 默认 current 与显式 current byte-identical；v1 兼容 fixture 全绿；正式矩阵仍为 256/current/paired，数值树 SHA-256 未变。 |
| AC-021-18 | PASS（停机分支） | 64 未全过，因此未启动 128，状态写为 `paused_no_strategy_component_passed`。 |
| AC-021-19 | NOT RUN BY GATE | 128 确定性与八份 SHA-256 仅在 64 全过后适用；本轮不存在 128 输出。 |
| AC-021-20 | PASS | 本报告与 `docs/11_STRATEGY_COMPONENT_AUDIT_021.md` 记录逐门结果、唯一状态和下一步边界。 |

## 配对输入契约

四份报告使用同一命令轴，仅 `--strategy-profile` 不同：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  --script res://tools/run_balance_simulation.gd -- \
  --mode=campaign --iterations=64 --max-turns=80 \
  --characters=ember_exile,arc_tinker,pyre_ascetic \
  --challenges=0,1,2,3 \
  --strategy-profile=<profile> \
  --strategy-diagnostics=component-v1 \
  --output=/tmp/ember021-<profile>-64.json
```

| Profile | Cases | Runs/case | Seed model | Max turns | SHA-256 |
| --- | ---: | ---: | --- | ---: | --- |
| `current-greedy` | 12 | 64 | `paired_by_iteration` | 80 | `05d28aab84cd28d2b789bafcbb55f358828c838f9ba70165022e40481c9f38d0` |
| `competent-player-v1` | 12 | 64 | `paired_by_iteration` | 80 | `8a09242dafdd216fe34674bfcdc3870ce4cbde2cf27054f507c59e8a3a1866c4` |
| `competent-combat-v1` | 12 | 64 | `paired_by_iteration` | 80 | `9dc1ad91eab916f19246126d726b0985fb7670f897166911ffdf64144f35d1cf` |
| `competent-player-v2` | 12 | 64 | `paired_by_iteration` | 80 | `b375c1fb73a5fa13ad7e0e700ab01e3f265f9220a6d633188ae80b3947bf0220` |

## 64 组件结果

百分比仅用于展示；硬门直接使用整数计数，不用展示值做二次舍入。

| Profile | C0 胜率/第一章 | C1 胜率/第一章 | C2 胜率/第一章 | C3 胜率/第一章 | Elite 死亡/访问 |
| --- | --- | --- | --- | --- | --- |
| current | 4.69% / 40.10% | 2.08% / 27.08% | 0.52% / 11.46% | 0.52% / 5.73% | 1/15 (6.67%) |
| v1 meta | 5.73% / 28.65% | 4.17% / 18.23% | 0.00% / 8.85% | 0.00% / 4.17% | 157/247 (63.56%) |
| combat-v1 | 10.94% / 42.19% | 6.25% / 34.90% | 1.04% / 17.71% | 0.00% / 9.38% | 1/22 (4.55%) |
| v2 | 7.81% / 28.65% | 2.60% / 21.88% | 2.08% / 14.06% | 1.04% / 7.81% | 159/256 (62.11%) |

## v2 硬门

每档分母均为 `3×64=192`。第一章门要求 v2-current 不低于 `-0.02`；精英门要求访问大于 0 且死亡/访问不高于 `0.35`。

| 门 | Current | v2 | 差值 | 结果 |
| --- | ---: | ---: | ---: | --- |
| C0 平均胜率 | 9/192 | 15/192 | +0.03125 | PASS |
| C0 第一章完成率 | 77/192 | 55/192 | -0.11458 | FAIL |
| C1 平均胜率 | 4/192 | 5/192 | +0.00521 | PASS |
| C1 第一章完成率 | 52/192 | 42/192 | -0.05208 | FAIL |
| C2 平均胜率 | 1/192 | 4/192 | +0.01563 | PASS |
| C2 第一章完成率 | 22/192 | 27/192 | +0.02604 | PASS |
| C3 平均胜率 | 1/192 | 2/192 | +0.00521 | PASS |
| C3 第一章完成率 | 11/192 | 15/192 | +0.02083 | PASS |
| v2 elite safety | 访问 > 0 | 159/256 = 0.62109 | 上限 0.35 | FAIL |

## 兼容与冻结证据

- Fail-closed artifact verifier：`Godot --headless --path . --script res://tests/test_balance_simulator.gd -- --require-component-gate-artifacts`，结果 PASS。该模式强制四份 64 报告与默认/显式 current 报告存在、JSON 可解析、原始计数合法，并断言八个可能的 128/重复输出路径均不存在。
- 默认 current 报告：`/tmp/ember021-default-current-64.json`。
- 显式 current 报告：`/tmp/ember021-current-greedy-64.json`。
- 两者 `cmp` 相等，SHA-256 均为 `05d28aab84cd28d2b789bafcbb55f358828c838f9ba70165022e40481c9f38d0`。
- `tests/test_balance_simulator.gd` 的 v1 meta、旧 combat scorer、药水、升级、奖励与路线 fixture 全绿。
- `data/config/numerical_tree.json` SHA-256 保持 `1f0cc2cbf45739c8b82abb92380c91138673a716d0031be0b57c5c0eacd5845e`；正式 matrix 保持 12 rows、256 iterations、`current-greedy`、`paired_by_iteration`、80 turns。

## 停机裁决

64 gate 的 C0/C1 第一章完成率和 v2 精英死亡率失败。因此：

- 不生成四 profile 的 128 报告，也不伪造 AC-021-19 的重复哈希。
- 不降低 `0.02` 或 `0.35` 门槛，不加入 expected exception。
- 不修改生产数值或把 64 诊断写入正式 256 rows。
- 下一步必须重新审计 meta 路线与精英选择的组合效应；不能直接进入数值候选审计。
