# 020-02 验证报告

## 裁决

- 状态：`paused_no_strategy_passed`。
- deterministic：通过；current 与 competent 各自重复运行均字节完全一致。
- 胜率差分门：失败；C2、C3 平均胜率低于 current。
- 第一章门：失败；C0、C1 下降超过 0.02。
- 正式矩阵隔离：通过；256/current-greedy/冻结 rows 未改变。

## 验收标准

| AC | 结果 | 证据 |
| --- | --- | --- |
| AC-020-06 | 通过 | CLI profile 接线、API normalization、unknown fallback 与 schema v1 单测 |
| AC-020-07 | 通过 | 低血路线、静态遭遇压力、牌组/遗物成熟度、稳定 node-id tie-break 与 80% 篝火预览单测 |
| AC-020-08 | 通过 | 角色/牌组奖励评分、重复惩罚、升级 ID 解析单测 |
| AC-020-09 | 通过 | 0.80 篝火恢复阈值与低血药水策略单测 |
| AC-020-10 | 通过 | 两组重复 128 报告 byte-identical；SHA 见项目差分文档 |
| AC-020-11 | 通过 | 12 格 outcome/resource/telemetry/failure concentration 已记录；矩阵冻结测试通过 |
| AC-020-12 | 通过（停机分支） | 差分门失败后记录 `paused_no_strategy_passed`，未改生产数值 |

## 差分门摘要

| 挑战 | current 胜率 | competent 胜率 | 胜率门 | current 第一章 | competent 第一章 | 第一章门 |
| --- | --- | --- | --- | --- | --- | --- |
| C0 | 6.3% | 7.0% | 通过 | 35.9% | 27.4% | 失败 |
| C1 | 2.9% | 5.0% | 通过 | 26.3% | 20.9% | 失败 |
| C2 | 1.8% | 0.8% | 失败 | 11.2% | 9.6% | 通过 |
| C3 | 1.6% | 0.5% | 失败 | 6.8% | 4.9% | 通过 |

## 证据

- 完整分析：`docs/10_STRATEGY_DIFFERENTIAL_020.md`。
- current SHA-256：`01fec3b5d81504c15562f13a071dcae1ef0d04af43fd5c1d564ae2e6d7204816`。
- competent SHA-256：`3be50129a576fe49b9d350e8da49465b702c33438635cbe9b5a9d951eb226019`。
- 两份主报告与重复报告均位于 `/tmp`，未纳入正式 matrix。

## 冻结确认

- 未修改 `data/cards/*.json`、`data/enemies/*.json`、`data/encounters/*.json`、player/economy/numerical tree 生产配置。
- 未修改 `CombatState.gd`、`MapGenerator.gd`、真人 cohort/report。
- 未降低目标区间、未扩大容差、未写 expected exception。
- 未把 competent 设为默认。
