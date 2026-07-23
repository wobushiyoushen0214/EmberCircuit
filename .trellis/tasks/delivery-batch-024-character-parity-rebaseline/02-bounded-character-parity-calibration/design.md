# Design: 024-02 有限角色平衡校准

## 需求覆盖

| 需求 | 当前 | 设计元素 | 本任务后预期 |
| --- | --- | --- | --- |
| REQ-003/004/005 | PARTIAL | exact catalog、单角色 64、唯一组合 64→128 | selected 128 或有证据的有界停机 |
| REQ-009 | PARTIAL | 每份实际报告的 compact digest 与唯一 verdict | AI 候选证据跨会话可复核 |

## MVP 兼容性契约

| 行为 | 证据 | 保留 | 回归 |
| --- | --- | --- | --- |
| 无 overlay/default byte identity | 024-01 tests | 是 | runtime test |
| 023 P1-P5 与 hard gate | 023 tests/docs | 是 | layered tests |
| 生产配置与正式 matrix 冻结 | `numerical_tree.json`/matrix test | 是，除 024 metadata | hash/semantic snapshot |
| v3 paired 80-turn attrition | 022/023 reports | 是 | gate identity tests |

## 决策表

| 决策 | 选定 | 排除 | 原因 |
| --- | --- | --- | --- |
| 搜索空间 | B0 + A1-A3/E1-E3/Y1-Y3 | 网格搜索、动态 A4 | 有界、可解释、最多 6,912 局 |
| 64 用途 | 角色内带 + 组合方向门 | 正式 hard pass | hard 样本最低 128 |
| 组合 | 每角色首个 PASS 的唯一 C1 | 多组合排名 | 避免事后挑最好结果 |
| 128 | 共享 023 hard gate | 新阈值或近似分数 | 保护既有目标不漂移 |
| 证据 | full `/tmp` + versioned compact | 只保存 SHA | 重启后仍可复核 raw gate 输入 |

## API / 数据契约

- `CharacterParityCandidateCatalog.validate(payloads) -> {ok,errors}`；`compose_selected(payloads, selected_steps) -> {ok,payload,errors}`。
- `CharacterParityCandidateGate.evaluate_role(report,id)` 与 `evaluate_combined_64(report,selected_reports)` 都返回 `{eligible,pass,failure_codes,raw_totals}`。
- runner adapter 隔离模拟、保存、digest 和 SHA；scripted tests 不运行正式 6,912 局即可覆盖控制流。
- verdict schema v1 顶层固定：`status/candidate_order/selected_steps/selected_candidate/steps/total_formal_runs/production_applied/matrix_updated/playtest_package_eligible`。

## 编排-计算分离

| 层 | 元素 | 落点 |
| --- | --- | --- |
| 编排 | A→E→Y、C1、64→128、预算、artifact | `run_character_parity_ladder.gd` |
| 计算 | exact fixture 与 C1 merge | `CharacterParityCandidateCatalog.gd` |
| 计算 | 单角色/组合 64 raw gate | `CharacterParityCandidateGate.gd` |
| 计算 | 128 hard | 既有 `LayeredPressureCandidateGate.gd`，只消费 |
| 计算 | compact digest | 024-01 `BalanceEvidenceDigest.gd`，只消费 |

## 挂载点

1. runner preflight 调 catalog 与 32-seed graph 检查。
2. runner 每个单角色 report 调 role gate。
3. runner 唯一 C1 调 combined gate，再调用 shared hard gate。
4. runner 每次报告调用 digest API 写 `.trellis/evidence/batch-024/`。
5. verdict 同步 `campaign_rebaseline_024` 与 `docs/14`，生产 flag 恒 false。

## 结构健康度

| 文件 | 当前行数 | 400 阈值 | 微重构 |
| --- | ---: | ---: | --- |
| `run_layered_pressure_ladder.gd` | 451 | 已超 | 不修改；新 runner 独立 |
| `LayeredPressureCandidateGate.gd` | 345 | 接近 | 只消费；64 gate 新文件 |
| `test_numerical_balance_matrix.gd` | 426 | 已超 | 只增加紧凑 024 dispatcher，不搬旧矩阵逻辑 |
| 新 catalog/gate/runner/tests | 0 | 400 | 每文件目标低于 400；runner 超过前先抽纯 helper，不扩 023 runner |

## 非目标

- 不写生产、不跑 256、不改静态角色目标、不更新包版本。
- 不修改战斗/AI/卡牌/敌人/挑战/真人遥测。

