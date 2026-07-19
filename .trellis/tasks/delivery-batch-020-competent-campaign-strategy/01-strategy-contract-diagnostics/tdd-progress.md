# 020-01 TDD Progress

| AC | RED | GREEN | 回归 | 状态 |
| --- | --- | --- | --- | --- |
| AC-020-01 | red | green | green | done | RED: default/current explicit comparison initially exposed missing strategy fields; GREEN added normalized profile chain; editor + balance/card telemetry/matrix regression passed |
| AC-020-02 | red | green | green | done | RED: top-level/case schema and fallback assertions failed; GREEN added schema v1 and unknown-profile fallback |
| AC-020-03 | red | green | green | done | RED: all eight decision counters absent; GREEN added state counters and aggregate averages |
| AC-020-04 | red | green | green | done | RED: sample profile/schema/telemetry absent; GREEN copied stable fields into sample summaries |
| AC-020-05 | red | green | green | done | RED run used campaign fixture; repeated cases remained deterministic after GREEN |

## 最小实现收敛

- 删除项：无；只扩展既有 campaign state/result/aggregate 链路。
- 复用项：既有 paired seed、`_campaign_result()`、`_aggregate_campaign_case()`、`_summarize_campaign_run()` 和现有 Godot tests。
- 保留项：019 attribution schema、样本门、旧 `version=1`、默认 current-greedy 行为和正式 matrix freeze。
- `trellis-minimal:` 注释：无；策略算法留给 020-02，避免在契约任务引入未来抽象。

## 收尾核对

- [x] 所有 AC 状态为 done。
- [x] `prd.md` 自检命令：editor、balance simulator、card telemetry、numerical matrix 均退出 0。
- [x] 未执行 commit；等待 020-01 规范/质量评审。
