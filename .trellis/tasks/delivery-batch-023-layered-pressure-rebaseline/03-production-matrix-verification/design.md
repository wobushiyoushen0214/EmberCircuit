# Design: 023-03 正式 256 矩阵验证

## 需求覆盖

| 需求 | 当前 | 设计元素 | 本任务后预期 |
| --- | --- | --- | --- |
| REQ-003/004/005 | PARTIAL | selected-bound v3 256/repeat、共享 hard gate、report-driven matrix | 已验证生产基线或精确回滚 |
| REQ-009 | PARTIAL | artifact SHA/provenance 与 AI/真人隔离 | AI 正式证据可审计，真人证据继续独立 |

## 编排-计算分离

| 层 | 元素 | 落点 |
| --- | --- | --- |
| 编排 | 解析 selected、生成 primary/repeat、调用 dry-run/apply、回写 docs/state | 执行命令与 `tools/sync_campaign_matrix.gd` |
| 阈值计算 | 256 raw hard verdict | 既有 `LayeredPressureCandidateGate.gd`，expected iterations=256 |
| 数据计算 | 校验轴/身份，按角色挑战 key 构建 matrix 副本 | 新 `CampaignMatrixSync.gd` |
| 生产状态 | accepted tree apply 或精确 candidate rollback | CLI apply 分支与 baseline 契约测试 |

## 数据流

```text
selected 128 verdict -> selected overlay identity -> 256 report + identical repeat
       -> shared 256 hard gate -> CampaignMatrixSync dry-run
       -> PASS: atomic formal tree apply + package eligibility
       -> FAIL: no matrix apply + exact P1-P5 production rollback + package locked
```

## API 契约

`CampaignMatrixSync.build_synced_tree(tree, report, repeat_report, selected_verdict, hard_verdict)` 返回 `{ok, tree, errors, provenance}`。

- 成功：返回 deep-copied tree，排序去重后的 errors 为空。
- 失败：tree 为空、errors 为固定排序去重错误，所有输入保持不变。
- provenance 含 selected step、candidate ID/SHA、primary/repeat path/SHA、精确 sample/profile/seed metadata 和 hard-gate result。
- CLI 文件 I/O 与 helper 分离，unit tests 不写生产文件即可覆盖全部分支。

## Matrix Mapping

| 目标字段 | 来源 | 规则 |
| --- | --- | --- |
| `strategy_profile` | 固定验证 option | 精确 `competent-player-v3` |
| `iterations_per_cell` | report | 精确 256 |
| `seed_model` / `max_turns` | report | paired / 80 |
| row key | report case | 唯一 `character_id:challenge_level` |
| `observed_win_rate` | case `win_rate` | 精确 report 数值 |
| `avg_final_gold` | case 同名字段 | 精确 report 数值 |
| `avg_final_deck_size` | case 同名字段 | 精确 report 数值 |
| `risk_flag` | case 同名字段 | 必须为 `ok` |
| 其余 row 字段 | 当前正式 row | deep-preserve |
| 三组 expected issues/cells | 独立 PASS 结果 | 全门通过后才为空 |

## 挂载点

- `campaign_rebaseline_023` 的 selected identity 控制唯一可运行 fixture。
- `LayeredPressureCandidateGate` 控制唯一正式阈值 verdict。
- `CampaignMatrixSync` 控制唯一 row transformation。
- CLI `--apply` 控制唯一 numerical tree replacement。
- Numerical matrix test 控制正式 source binding 与 rollback behavior。

## 结构健康度

- `tests/test_numerical_balance_matrix.gd` 当前 411 行，超过阈值；只把过时 freeze 分支替换成紧凑的 PASS/rollback dispatcher，sync unit cases 放到新 test。
- `docs/09_NUMERICAL_TREE_AND_BALANCE.md` 268 行，`docs/07_CURRENT_STATE_AND_NEXT_STEPS.md` 174 行；只更新现有 campaign 章节，不建平行文档。
- 新 helper、CLI、test 各自目标低于 400 行；不得搬动 simulator 或 auditor 行为。

## 非目标

- 不做新候选搜索、策略改动、战斗改动、真人平衡结论、打包或 UI 工作。
- 不实现第二套 hard gate，不重设计 matrix schema。
