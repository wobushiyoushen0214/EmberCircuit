# 019-03：完整跑团矩阵与交付验证

## 需求 ID

- REQ-003
- REQ-004
- REQ-005
- REQ-009
- REQ-012
- AC-019-11 ～ AC-019-15

## 目标

消费 019-02 已通过方向门的配置，先跑 128 方向回归，再跑 256-seed 正式 3×4 矩阵；由工具报告同步 `data/config/numerical_tree.json` 的 observed rows/summary，完成全量 Godot regression、静态数值审计、真人 cohort schema 检查和双阶段评审证据。

## 前置条件

- 019-01 和 019-02 已通过 Stage 1/Stage 2，无 critical；selected step、冻结项和 `/tmp/ember019-selected-128.json` 已记录。
- 当前分支处于 019 worktree，工作树无未解释改动；`campaign_matrix.rows` 仍为任务起点快照。

## 交付控制

- 批次：`delivery-batch-019-campaign-pressure-rebaseline`；Loop：L3；worktree/verifier：是/是。
- 依赖：`02-act2-act3-pressure-and-reward-rebaseline`；本任务完成后才可更新 batch 状态为 delivered。
- 实现/调试/评审：`trellis-implement-tdd-zh` / `trellis-debug-systematic-zh` / `trellis-review-twostage-zh`。
- 人工门：Stage 2 强模型/人工质量评审；real-human schema 只做字段与 cohort 隔离检查，不把 AI 报告当真人证据。
- 回滚触发：手写 observed、矩阵轴缺失、报告与 JSON 不一致、真人/AI 混合、任一关键回归失败。

## 决策表

| 决策点 | 选定方案 | 原因 | 文件 |
| --- | --- | --- | --- |
| 128 方向门 | `--iterations=128`、12 cases、paired seed | 先捕捉方向错误，降低 256 成本 | report/test |
| 256 正式矩阵 | `--iterations=256 --challenges=0,1,2,3` | 与正式 numerical_tree schema 一致 | report/tree |
| observed 来源 | 只从 `/tmp/ember019-campaign-matrix-256.json` 工具输出读取 | 禁止手写聚合结果 | `numerical_tree.json` |
| 真人 cohort | 仅验证 `PlaytestEvidenceGate` schema_version/cohort_id/denominator | AI 与真人目标、分母不同 | tests |
| docs 更新 | 同步 selected step、256 report 摘要、失败归因、已知剩余风险 | 文档必须反映真实报告 | `docs/09...md`、`docs/07...md` |

## 文件清单

| 操作 | 文件 | 精确修改 |
| --- | --- | --- |
| 新建 | `tests/test_campaign_matrix_verification.gd` | 128/256 report schema、轴、目标、真人隔离和 observed 来源断言 |
| 新建 | `tools/sync_campaign_matrix.gd` | 结构化读取 256 report 和 numerical tree，校验完整 3×4 轴后原子生成同步后的 tree；拒绝 64/128/缺格/重复格/非 paired 报告 |
| 修改 | `data/config/numerical_tree.json` | 仅由真实 256 report 同步 observed/summary/risk fields 与 selected step |
| 修改 | `docs/09_NUMERICAL_TREE_AND_BALANCE.md` | 更新矩阵、归因、命令、风险和证据路径 |
| 修改 | `docs/07_CURRENT_STATE_AND_NEXT_STEPS.md` | 更新当前 campaign 证据与后续建议 |
| 修改 | `tests/test_numerical_balance_matrix.gd` | 正式 observed 与报告一致性断言 |
| 修改 | `.trellis/delivery-state.md` | 019 状态、REQ 证据、next action |
| 修改 | `.trellis/delivery-run-log.jsonl` | 追加 batch-delivered 记录 |
| 新建 | 本任务 `tdd-progress.md`、`review-report.md` | TDD/双阶段评审证据 |

## 验收标准

- [ ] AC-019-11：128 方向报告 12 cases、schema=1、paired seed、selected step 配置和归因门全绿。
- [ ] AC-019-12：256 正式报告 12 cells，每 cell 256 runs；challenge target、角色差、单调、经济范围、失败集中度和 `risk_flag` 由测试核对。
- [ ] AC-019-13：`numerical_tree.json` 每个 observed 字段与 256 工具报告精确一致，报告 hash/path 写入交付证据；不手写 observed。
- [ ] AC-019-14：全量 `tests/test_*.gd`、数值树审计、campaign/single balance、PlaytestEvidenceGate schema、visual/performance smoke 全绿；无未知 `ERROR`/`SCRIPT ERROR`。
- [ ] AC-019-15：AI report 与真人 report 分离，真人报告缺样本时保持 `insufficient_samples`/UNTESTED，不伪造 DONE；Stage 1/2 review 无 critical。

## 自检命令

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_campaign_matrix_verification.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tools/run_balance_simulation.gd -- --mode=campaign --iterations=128 --max-turns=80 --challenges=0,1,2,3 --output=/tmp/ember019-direction-128.json
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tools/run_balance_simulation.gd -- --mode=campaign --iterations=256 --max-turns=80 --challenges=0,1,2,3 --output=/tmp/ember019-campaign-matrix-256.json
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tools/sync_campaign_matrix.gd -- --report=/tmp/ember019-campaign-matrix-256.json --tree=res://data/config/numerical_tree.json --output=/tmp/ember019-numerical-tree-synced.json
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tools/run_numerical_tree_audit.gd -- --output=/tmp/ember019-numerical-tree-audit.json
for test in tests/test_*.gd; do /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://$test || exit 1; done
```

## 范围外与禁止事项

- 不在验证任务里继续改生产数值；不手改 observed、expected exception 或目标范围来凑绿。
- 不把真人报告、fixture、旧报告或 64/128 方向报告写进 256 正式 observed 字段。
- 不新增 UI、美术、音频、网格模式、发布管线或存档 schema 改动。
