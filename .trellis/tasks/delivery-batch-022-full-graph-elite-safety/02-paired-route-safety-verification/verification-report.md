# 022-02 完整图路线安全配对验证报告

- 日期：2026-07-21（2026-07-22 加固 artifact 迭代数绑定）
- 业务裁决：`route_safety_component_gate_passed`
- 结论：v3 的 64 方向门全部通过，因此按契约运行四 profile 128 与 repeat；128 原始计数仍通过同一门，四组重复报告 byte-identical。
- 边界：该结果只解锁下一轮生产数值候选审计；没有修改生产 JSON、正式 256 matrix、CombatState、地图或真人证据，也不直接解锁试玩包。

## 验收结果

| AC | 结果 | 证据 |
| --- | --- | --- |
| AC-022-07 | PASS | 四 profile 均为 3 角色 x C0-C3 x 64、80 turns、`paired_by_iteration`、`component-v1`，每份 12 cases。 |
| AC-022-08 | PASS | candidate 固定 v3；win/chapter/elite 门使用原始整数计数和交叉乘法，`7/20` 边界 fixture 通过。 |
| AC-022-09 | PASS（失败分支未触发） | 64 门计算前不存在 128 artifact；verifier 在 64 FAIL 时要求两份 128 都不存在。 |
| AC-022-10 | PASS | 64 全门 PASS 后生成 8 份 128；verifier 将 64/128 调用分别精确绑定到报告内 `iterations_per_case`，错配时 fail-closed；四份 128 主报告通过 profile/seed/axis/raw-count/hard-gate 校验，且各自与 repeat byte-identical。 |
| AC-022-11 | PASS | 021 current/v2 64 与 022 同 profile 报告 byte-identical；正式 matrix 仍为 256/current/paired/12 rows，生产树 hash 不变。 |

## 配对输入

四份报告只改变 `--strategy-profile`：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  --script res://tools/run_balance_simulation.gd -- \
  --mode=campaign --iterations=<64|128> --max-turns=80 \
  --characters=ember_exile,arc_tinker,pyre_ascetic \
  --challenges=0,1,2,3 --strategy-profile=<profile> \
  --strategy-diagnostics=component-v1 \
  --output=/tmp/ember022-<profile>-<iterations><-repeat?>.json
```

## 64 硬门

每行分母均为三角色合计 `192`。第一章门要求 candidate 相对 current 的下降不超过 `0.02`，即最多 `3.84/192`；使用整数交叉乘法判定。

| 挑战 | Current wins | v3 wins | 胜率门 | Current 第一章 | v3 第一章 | 第一章门 |
| --- | ---: | ---: | --- | ---: | ---: | --- |
| C0 | 9 | 16 | PASS | 77 | 76 | PASS，下降 `1/192` |
| C1 | 4 | 8 | PASS | 52 | 60 | PASS |
| C2 | 1 | 5 | PASS | 22 | 35 | PASS |
| C3 | 1 | 3 | PASS | 11 | 19 | PASS |

- v3 elite：`17/133=0.12782`，PASS（上限 `0.35`）。
- v2 对照：`159/256=0.62109`；v3 将精英死亡率降低 `0.49327`，同时精英访问从 256 降至 133。
- 裁决：四档胜率、四档第一章和 elite 门全部 PASS，允许 128。

## 128 确认

每行分母均为三角色合计 `384`。

| 挑战 | Current wins | v3 wins | 胜率门 | Current 第一章 | v3 第一章 | 第一章门 |
| --- | ---: | ---: | --- | ---: | ---: | --- |
| C0 | 24 | 34 | PASS | 138 | 147 | PASS |
| C1 | 11 | 21 | PASS | 101 | 112 | PASS |
| C2 | 7 | 12 | PASS | 43 | 57 | PASS |
| C3 | 6 | 11 | PASS | 26 | 37 | PASS |

- v3 elite：`49/260=0.18846`，PASS。
- v2 对照：`332/521=0.63724`。
- 128 同样通过方向门，但正式数值树仍冻结；下一步需独立规划生产候选审计，不能把策略诊断直接写入正式 256 matrix。
- Review Round 1 加固：新增“64-run 内容被 128 路径加载”fixture，必须返回 `paired_options_passed=false` 和 `reference:required_iterations`；required artifact verifier 已在真实 64/128 调用点分别传入精确期望值。

## Artifact Hash

| Profile | 64 SHA-256 | 128 SHA-256 | Repeat |
| --- | --- | --- | --- |
| `current-greedy` | `05d28aab84cd28d2b789bafcbb55f358828c838f9ba70165022e40481c9f38d0` | `175f0cc3badd2c56d47dfea20ed5a262be3cf727026c1825100c066ebe7fc85c` | byte-identical |
| `competent-combat-v1` | `9dc1ad91eab916f19246126d726b0985fb7670f897166911ffdf64144f35d1cf` | `998995113a76d75034b4a07a498781b3da0a06c5b378e4d79ccad0552a964fd2` | byte-identical |
| `competent-player-v2` | `b375c1fb73a5fa13ad7e0e700ab01e3f265f9220a6d633188ae80b3947bf0220` | `9a93c0383be6560a9192bbff6805d36c2940d7d2682a852aa29625d374177012` | byte-identical |
| `competent-player-v3` | `6a49a92a00d8c4061e392e1c5be7e74217ce8095c587f4bcf76200082bfaced3` | `bb8bb6ab34e18216500f2f867d6ad3eb761122457bb265032ca3544416bbb738` | byte-identical |

生产 `data/config/numerical_tree.json` SHA-256：`1f0cc2cbf45739c8b82abb92380c91138673a716d0031be0b57c5c0eacd5845e`。
