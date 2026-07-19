# 020-02 双阶段评审报告

## Review Round 1

### 被评审对象

- 任务：`.trellis/tasks/delivery-batch-020-competent-campaign-strategy/02-competent-player-differential-verification`
- diff 范围：`b3a945e..worktree`；其中 020-01 产物已在独立 review-report 通过，本报告聚焦 020-02。
- Stage 2 评审模型：GPT-5（强模型评审）。

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| AC 测试覆盖 | 通过 | - | `tests/test_balance_simulator.gd:14-242`、`tests/test_numerical_balance_matrix.gd:72-93`、`verification-report.md` | AC-020-06～09 有 CLI/路线/奖励/升级/篝火/药水断言；AC-020-10～12 有重复 128 报告、逐格差分、矩阵隔离和停机证据 |
| 文件清单符合 | 通过 | - | 020-02 全 diff | 只改 `BalanceSimulator.gd`、CLI、两份既有测试，并新建约定的差分文档、验证/TDD/review 产物；020-01 文件属于已评审前置任务 |
| 禁止事项符合 | 通过 | - | `git diff --cached --name-only` | 未改任何生产 JSON、`CombatState.gd`、`MapGenerator.gd`、目标区间、expected exception 或真人 cohort/report；未新增依赖 |
| 决策表符合 | 通过 | - | `BalanceSimulator.gd:76-135`、`:697-715`、`:1171-1203`、`:1289-1450`、`:1867-1910`、`:2108-2131` | profile 分支、静态压力、牌组/遗物成熟度、固定 tie-break、角色奖励、0.80 篝火、升级解析和药水门均按选定方案实现 |
| 挂载点接线 | 通过 | - | `run_campaign_suite` → campaign state/result/aggregate；`run_balance_simulation.gd:11-68` | profile、路线、奖励/升级、战斗资源与 CLI/差分证据五个挂载点均实际接线 |
| 范围符合 | 通过 | - | 全 diff | 未改生产战斗/地图行为，未把 competent 设为默认，失败后未发明新数值候选 |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| 编排-计算分离 | 通过 | - | `BalanceSimulator.gd:1289-1450`、`:1867-1910` | 入口只做 profile dispatch，路线压力/成熟度/奖励评分位于独立 helper，可由现有 fixture 直接测试 |
| 结构健康度 | 记录 | minor | `scripts/tools/BalanceSimulator.gd` | 文件原已偏胖，本批继续增加策略与遥测；后续独立技术债可抽离纯 campaign strategy evaluator，但不应在失败验证批次扩大范围 |
| 简化与复用 | 通过 | - | 全 diff、`tdd-progress.md` | 复用既有数据加载、paired seed、campaign result/aggregate/attribution 和 CLI；无新依赖、平行模拟器或预留框架 |
| 正确性（边界/错误/回归） | 通过 | - | `_campaign_strategy_config`、CLI smoke、128 repeat、current SHA、矩阵测试 | unknown profile 显式 fallback；空药水/无效药水沿用保护；current 完整报告哈希保持 `01fec...`；两 profile 重复报告 byte-identical |
| 测试隔离 | 记录 | minor | `tests/test_numerical_balance_matrix.gd:78-93` | 测试会在特定 `/tmp/ember020-*` 文件存在时追加检查；这有利于本批验收，但长期 CI 可改成显式 fixture/独立 verifier，避免陈旧临时文件造成环境相关失败 |
| 规范符合（spec） | 通过 | - | `.trellis/spec/` 不存在 | GDScript 命名、错误语义和既有测试风格一致；任务文档已说明无 package spec |

### 问题汇总（按严重度）

- **Critical（阻断）**：无。
- **Major（应修）**：无。
- **Minor（记录后续）**：
  - `BalanceSimulator.gd` 继续偏胖；建议后续独立抽离纯策略评估器，不在本批重构。
  - 矩阵测试对约定 `/tmp` 报告做条件式增强校验；长期可迁移为显式 fixture 或独立 verifier。

### 验证证据

- Godot editor import：退出 0。
- `tests/test_balance_simulator.gd`：`Balance simulator smoke test passed.`
- `tests/test_balance_card_telemetry.gd`：`Balance card telemetry contract test passed.`
- `tests/test_numerical_balance_matrix.gd`：`Numerical balance matrix contract test passed.`
- `tests/test_numerical_pressure_metrics.gd`：`Numerical pressure metrics test passed.`
- current 128 与 repeat：byte-identical，SHA-256 `01fec3b5d81504c15562f13a071dcae1ef0d04af43fd5c1d564ae2e6d7204816`。
- competent 128 与 repeat：byte-identical，SHA-256 `3be50129a576fe49b9d350e8da49465b702c33438635cbe9b5a9d951eb226019`。
- `git diff --cached --check`：通过。

### 裁决

- [x] 仅 minor，无 critical/major；020-02 放行并交回编排会话提交、合并和状态回写。
