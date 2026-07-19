# 020-02 TDD Progress

| AC | RED | GREEN | 回归 | 状态 |
| --- | --- | --- | --- | --- |
| AC-020-06 | red | green | green | done：CLI 静态解析入口缺失时测试 parse error；增加 `parse_options_for_args` 与 `--strategy-profile=` 接线后 simulator/CLI smoke 通过，未知 profile 仍由 API 显式 fallback |
| AC-020-07 | red | green | green | done：competent 静态遭遇压力、牌组/遗物成熟度、低血避险、80% 篝火预览与 node-id 稳定 tie-break 断言转绿；current fixture 保持通过 |
| AC-020-08 | red | green | green | done：角色/牌组奖励评分、重复牌惩罚和升级 ID 解析断言转绿 |
| AC-020-09 | red | green | green | done：0.80 篝火恢复阈值和低血治疗药水断言转绿；空槽/无效消耗沿用既有保护 |
| AC-020-10 | red | green | green | done：CLI profile 未接线时无法生成 competent 报告；接线后 current/competent 各重复 128 runs，均 byte-identical 且 SHA 相同 |
| AC-020-11 | red | green | green | done：矩阵候选隔离检查入口缺失时 parse error；补齐 256/current/frozen rows 契约后，在两份 128 报告实际存在时通过；12 格差分文档已生成 |
| AC-020-12 | red | green | green | done：原先无可证伪门结果；C2/C3 胜率与 C0/C1 第一章门失败后按停机分支记录 `paused_no_strategy_passed`，生产 JSON 与正式矩阵未修改 |

## 128 paired 证据

- current：`/tmp/ember020-current-greedy-128.json`，SHA-256 `01fec3b5d81504c15562f13a071dcae1ef0d04af43fd5c1d564ae2e6d7204816`。
- competent：`/tmp/ember020-competent-player-v1-128.json`，SHA-256 `3be50129a576fe49b9d350e8da49465b702c33438635cbe9b5a9d951eb226019`。
- 两份重复报告与主报告分别完全一致。
- 差分门：C0/C1 胜率非回退通过，C2/C3 失败；C0/C1 第一章完成率下降超过 `0.02`，C2/C3 第一章门通过。
- 最终状态：`paused_no_strategy_passed`。

## 自检命令

- Godot editor import：退出 0。
- `tests/test_balance_simulator.gd`：通过。
- `tests/test_balance_card_telemetry.gd`：通过。
- `tests/test_numerical_balance_matrix.gd`：通过，且候选报告存在时验证 128/256 隔离。
- `tests/test_numerical_pressure_metrics.gd`：通过。
- 两组主报告与两组重复报告：退出 0，3×4×128、`max_turns=80`、paired seed。
- `cmp` 与 `shasum -a 256`：确定性通过。

## 最小实现收敛

- 删除项：未新增平行模拟器、策略注册框架或生产配置；差分只挂在既有 campaign helper 和 CLI parser。
- 复用项：复用既有 profile normalization、paired seed、card/relic/potion 数据、campaign result/aggregate/attribution 与 Godot CLI。
- 保留项：未知 profile fallback、空药水/无效药水保护、正式 256 rows 冻结断言、真人数据隔离。
- 新依赖：无。
- `trellis-minimal:` 注释：无；当前仅两个 profile，不建立额外抽象层。

## 收尾核对

- [x] 所有 AC 已有客观证据并完成。
- [x] 所有 PRD 自检命令通过。
- [x] 未修改生产 JSON、目标区间、expected exceptions、CombatState、MapGenerator 或真人 cohort。
- [x] 未执行 commit；等待 020-02 双阶段评审。
