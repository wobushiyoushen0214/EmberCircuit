# Delivery Batch 015: 真人试玩证据门

## 需求 ID

- REQ-009
- REQ-012

## 目标

让真人试玩数据在达到 3 角色 × 4 挑战的 12/30 样本门前不会被历史截断、跨版本混组或重复报告污染，并提供可机器判定的 cohort 覆盖矩阵与游戏内导出摘要。

## 当前缺口

- 当前状态：`REQ-009 PARTIAL`。
- `scripts/core/PlaytestTelemetry.gd` 只保留 64 局，而方向门需要 144 个完成局、硬门需要 360 个完成局；`abandoned` 与完成局争用同一全局容量。
- `build_report()` 虽列出多个版本/配置指纹，但角色、挑战、卡牌和失败点仍跨指纹聚合。
- 仓库没有多报告导入、按 `run_id` 去重、冲突检测或 12/30 覆盖矩阵。
- v1 开发期脚本数据无法与真人样本区分，会误入硬门。

## 交付 Loop 控制

- 交付批次：`delivery-batch-015-playtest-evidence-gate`
- Loop 模式：`L3`
- 需要 worktree：是，路径 `/Users/lizhiwei/localProj/.worktrees/EmberCircuit-batch015`
- 需要 verifier：是
- 实现技能：`trellis-implement-tdd-zh`
- 调试技能：`trellis-debug-systematic-zh`
- 评审技能：`trellis-review-twostage-zh`
- 人工门：不需要；用户已授权持续完成游戏，本任务不修改任何正式数值。
- 最大修复尝试次数：2
- 最大调试假设轮数：3
- 回滚触发：严格回归失败、跨 cohort 混组、完成样本被 abandoned 挤出、旧数据进入硬门、File Manifest 越界。

## 复杂度与规划产物

- 复杂度：高；涉及遥测 schema、留存、聚合、合并和 UI 摘要，但拆成三个顺序 AC。
- 执行模型假设：GPT-5 强模型编排，TDD 按机械红绿循环。
- 必要产物：`prd.md`、`design.md`、`implement.md`、`implement.jsonl`、`check.jsonl`、`tdd-progress.md`。
- Spec 新鲜度：以 `docs/02_TECHNICAL_ARCHITECTURE.md`、`docs/03_CONTENT_AND_BALANCE.md`、`docs/09_NUMERICAL_TREE_AND_BALANCE.md` 和现有遥测测试为稳定契约；`.trellis/spec/` 不存在。

## 决策表

| 决策点 | 选定方案 | 原因 |
| --- | --- | --- |
| 遥测 schema | `SCHEMA_VERSION = 2` | 显式区分 v1 legacy 与新真人样本 |
| cohort 身份 | `schema_version + game_version + config_fingerprint` 的 SHA-256 | 不同代码版本、配置或 schema 禁止混组 |
| 新样本资格 | 新局默认 `sample_kind=human`、`gate_eligible=true`；可显式传 `fixture` | 生产路径可直接收集，测试可明确排除 |
| 旧样本迁移 | v1 归一化为 `legacy_unapproved`、`gate_eligible=false` | 旧开发脚本数据不能自动解冻数值 |
| 留存 | 每 cohort/角色/挑战格保留最近 40 个合格完成局，每 cohort 保留最近 96 个合格 abandoned；fixture/legacy 另保留最多 96 个诊断行，最多保留最近 4 个 cohort | 每格 30 局硬门有 10 局余量，abandoned 与非批准样本都不挤掉真人完成局 |
| 门状态 | `<12 insufficient`、`12-29 directional_ready`、`>=30 hard_gate_ready` | 对齐正式数值文档 |
| 单卡门 | 20 个完成局 | 对齐现有真人样本契约 |
| 多报告冲突 | 同 `run_id` 同内容去重；不同终局/内容返回错误并拒绝产出合并分析 | 禁止静默覆盖污染证据 |
| 兼容输出 | 顶层旧聚合字段映射到唯一/最新合格 primary cohort；完整结果写入 `cohorts` | 保留现有单报告消费者，禁止跨 cohort 合计 |

## MVP 兼容性契约

| 已有行为 | 必须保留 | 回归检查 |
| --- | --- | --- |
| 活动局、胜利、战败、放弃与终局幂等 | 是 | `test_playtest_telemetry.gd`、`test_playtest_run_integration.gd` |
| 报告隐私边界与原始匿名 runs | 是 | `test_playtest_telemetry.gd`、`test_save_manager.gd` |
| 单 cohort 的角色/挑战/卡牌/失败聚合 | 是 | `test_playtest_telemetry.gd` |
| 游戏内导出与复制路径 | 是 | `test_playtest_run_integration.gd` |

## 文件清单

| 操作 | 文件路径 | 说明 |
| --- | --- | --- |
| 新建 | `scripts/core/PlaytestEvidenceGate.gd` | 纯计算：cohort、留存、覆盖矩阵、报告去重合并 |
| 新建 | `scripts/core/PlaytestEvidenceGate.gd.uid` | Godot 脚本 UID sidecar，遵循仓库现有资源追踪惯例 |
| 修改 | `scripts/core/PlaytestTelemetry.gd` | schema v2、迁移、留存委托、cohort 报告 |
| 新建 | `tools/merge_playtest_reports.gd` | 离线多报告合并入口 |
| 新建 | `tools/merge_playtest_reports.gd.uid` | Godot 工具脚本 UID sidecar |
| 修改 | `scripts/main/Main.gd` | 导出时传期望 12 格并显示覆盖摘要 |
| 新建 | `tests/test_playtest_evidence_gate.gd` | cohort/留存/合并/冲突/门状态测试 |
| 新建 | `tests/test_playtest_evidence_gate.gd.uid` | Godot 测试脚本 UID sidecar |
| 修改 | `tests/test_playtest_telemetry.gd` | v1 迁移、v2 样本资格与单 cohort 兼容测试 |
| 修改 | `tests/test_playtest_run_integration.gd` | 游戏内覆盖摘要集成测试 |
| 修改 | `data/config/numerical_tree.json` | 仅同步 `human_playtest_targets.report_schema_version` 到运行时 v2，不修改玩法或平衡数值 |
| 修改 | `packaging/PLAYTEST_README_ZH.txt` | 采样分配、导出与合并说明 |
| 修改 | `docs/02_TECHNICAL_ARCHITECTURE.md` | schema/cohort/留存架构 |
| 修改 | `docs/03_CONTENT_AND_BALANCE.md` | 12/30 证据门规则 |
| 修改 | `docs/06_IMPLEMENTATION_LOG.md` | 本批交付记录 |
| 新建/修改 | `.trellis/tasks/delivery-batch-015-playtest-evidence-gate.*` | 规划、TDD 与评审证据 |

## 挂载点

| 挂载点 | 类型 | 位置 | 接线动作 |
| --- | --- | --- | --- |
| store 归一化 | 数据入口 | `PlaytestTelemetry.normalize_store()` | 迁移 v1 并执行 cohort-aware retention |
| 报告生成 | 数据出口 | `PlaytestTelemetry.build_report()` | 输出 `cohorts`、primary cohort 与覆盖矩阵 |
| 多报告合并 | CLI | `tools/merge_playtest_reports.gd` | 调用纯计算合并器并拒绝冲突 |
| 游戏内导出 | UI 命令 | `Main._on_export_playtest_report_pressed()` | 传入 3×4 期望格并显示 12/30 进度 |

## 验收标准

- `AC-001`: 生成 12 格 × 35 个完成局并追加 200 个 abandoned 后，归一化 store 每格仍保留 35 个完成局、每 cohort abandoned 不超过 96；v1 记录全部为 `legacy_unapproved` 且不能进入门状态；40→41 与 4→5 cohort 边界正确，fixture 不得挤出同 cohort 的真人完成局。
- `AC-002`: 两个不同 cohort 的胜率、卡牌 lift 和失败集中度分别计算，同 cohort 的 fixture/legacy 也不得进入真人 summary/card/failure/raw runs；同 `run_id` 同内容去重，不同内容返回 `duplicate_run_conflict`；非终局行返回 `malformed_run`；每格输出 `insufficient/directional_ready/hard_gate_ready` 与距 12/30 缺口。
- `AC-003`: 游戏内导出摘要显示 primary cohort 的方向格数、硬门格数和尚缺完成局；试玩说明包含按版本分 cohort、每格 12/30、导出合并命令。
- `AC-004`: 旧单 cohort 报告消费者继续读取顶层 `summary/by_character/by_challenge/by_character_challenge/card_telemetry/failure_encounters/runs`，但这些字段不得跨 cohort 合并。
- `AC-005`: 新增测试后 20 套 Godot 测试全部通过，逐套无 `SCRIPT ERROR` 或 `ERROR:`。

## 自检命令

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_playtest_evidence_gate.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_playtest_telemetry.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_playtest_run_integration.gd
for test in tests/test_*.gd; do ...; done  # 20/20，严格扫描 SCRIPT ERROR 与 ERROR:
```

## 范围外

- 不修改卡牌、角色、敌人、遗物、挑战、经济、路线或奖励数值。
- 不把当前 64 局开发数据批准为真人样本。
- 不实现自动联网上传、账号、服务器或云存储。
- 不在本批修复进行中战斗快照；列为下一玩法批次。
- 不在本批生成二/三章敌人美术；列为下一美术批次。

## 禁止事项

- 不得用扩大一个全局 `MAX_RUN_HISTORY` 代替 per-cohort/per-cell 留存保证。
- 不得让不同 cohort 的胜率、卡牌 lift 或失败集中度进入同一聚合。
- 不得静默接受同 `run_id` 冲突记录。
- 不得把 v1 legacy 或 fixture 样本计入 12/30 门。
- 不得引入第三方依赖或修改 File Manifest 外文件。
