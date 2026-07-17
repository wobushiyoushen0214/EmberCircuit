# Design: 真人试玩证据门

## 编排-计算分离

| 层 | 元素 | 落点 |
| --- | --- | --- |
| 计算层 | cohort ID、样本资格、per-cell 留存、覆盖矩阵、报告去重与冲突检测 | `scripts/core/PlaytestEvidenceGate.gd` |
| 数据编排层 | run schema v2、旧数据迁移、store 归一化、单 store 报告兼容输出 | `scripts/core/PlaytestTelemetry.gd` |
| UI 编排层 | 期望角色/挑战列表、导出摘要 | `scripts/main/Main.gd` |
| 离线编排层 | 读取多个 JSON、调用合并器、写出单个 JSON | `tools/merge_playtest_reports.gd` |

## 数据契约

每条 v2 run 新增：

| 字段 | 类型 | 约束 |
| --- | --- | --- |
| `source_schema_version` | int | 新局为 2，v1 迁移保留 1 |
| `sample_kind` | string | `human/fixture/legacy_unapproved` |
| `gate_eligible` | bool | 只有 `human` 为 true |
| `cohort_id` | string | 64 位 SHA-256 |

每个 cohort 报告新增：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `cohort_id` | string | 唯一分析边界 |
| `game_version` | string | 游戏构建版本 |
| `config_fingerprint` | string | 配置 SHA-256 |
| `telemetry_schema_version` | int | 数据 schema |
| `coverage.cells` | array | 期望 3×4 格，含完成数、状态、缺口 |
| `coverage.directional_ready_cells` | int | 完成数 ≥12 的格数 |
| `coverage.hard_gate_ready_cells` | int | 完成数 ≥30 的格数 |
| `coverage.missing_finished_for_directional` | int | 全矩阵距方向门缺口 |
| `coverage.missing_finished_for_hard_gate` | int | 全矩阵距硬门缺口 |

## 留存算法

1. 归一化并按 `run_id` 去重，终局优先于 abandoned。
2. 按 cohort 最近完成时间选择最近 4 个 cohort。
3. 每 cohort 内，胜利/战败按 `character_id|challenge_level` 分组，各保留最近 40 个。
4. abandoned 单独保留最近 96 个，不得挤出完成局。
5. active run 独立存放，不占历史配额。

## 合并算法

1. 从每个报告读取 `runs`，拒绝缺少匿名 `run_id` 的行。
2. 同 `run_id` 的规范化 JSON 完全一致时去重。
3. 同 `run_id` 内容不同则返回 `{ok:false,error_code:"duplicate_run_conflict",run_id:...}`，不产生分析。
4. 合并后的 runs 仍按 cohort 分别聚合；顶层兼容字段只映射 primary cohort。

## 挂载点清单

- [ ] `normalize_store()` 调用 per-cell retention。
- [ ] `build_report()` 输出 cohort 列表和 primary coverage。
- [ ] 游戏内导出传入角色与挑战的 12 格期望列表。
- [ ] CLI 支持多个输入文件与 `--out`。

## 非目标

- 不改变现有匿名字段集合以外的隐私边界。
- 不自动判断旧数据是否真人；一律不批准。
- 不实现统计显著性检验或贝叶斯模型。
