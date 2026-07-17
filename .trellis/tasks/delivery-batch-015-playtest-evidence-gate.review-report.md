# 双阶段评审报告

## Review Round 1

### 被评审对象

- 任务：`delivery-batch-015-playtest-evidence-gate`
- diff 范围：`18d3a31..当前 worktree`
- Stage 2 评审模型：未执行；Stage 1 存在 critical，按门禁停止

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| AC 测试覆盖 | 不符 | critical | `prd.md:96`、`tdd-progress.md:9` | AC-001 至 AC-004 的定向测试已绿；严格全量为 19/20，`test_numerical_balance_matrix.gd` 因报告 schema 契约仍为 1 而失败，AC-005 未完成。 |
| 文件清单符合 | 不符 | critical | `prd.md:64-79` | 三个仓库惯例 `.gd.uid` sidecar 未列入 Manifest；修复剩余 schema 回归还需要修改未列入的 `data/config/numerical_tree.json`。 |
| 禁止事项符合 | 通过 | - | `prd.md:115-121` | 未引入第三方依赖，未改玩法/经济/角色/敌人等正式数值，未把 legacy/fixture 计入门。 |
| 决策表符合 | 通过 | - | `prd.md:41-53` | schema v2、cohort SHA-256、40/96/4 留存、12/30 状态、20×2 单卡样本就绪、冲突拒绝和 eligible primary 均有实现与测试。 |
| 挂载点接线 | 通过 | - | `design.md` 挂载点清单 | `normalize_store()`、`build_report()`、离线 CLI、Main 3×4 导出摘要均已接线；CLI 合并继承完整期望矩阵。 |

### Stage 2 · 代码质量

未执行。Stage 1 的 AC-005 与 File Manifest 两项 critical 必须先解除。

### 问题汇总（按严重度）

- **Critical（阻断）**：
  - `data/config/numerical_tree.json:211` 的 `human_playtest_targets.report_schema_version` 仍为 1，而 `PlaytestTelemetry.SCHEMA_VERSION` 已为 2；严格回归因此只有 19/20。该文件不在当前 File Manifest，需用户确认扩展后才能修复。
  - `scripts/core/PlaytestEvidenceGate.gd.uid`、`tests/test_playtest_evidence_gate.gd.uid`、`tools/merge_playtest_reports.gd.uid` 是 Godot 自动生成且符合仓库惯例的 sidecar，但未被当前 Manifest 明列。
- **Major（应修）**：无。
- **Minor（记录后续）**：无。

### 已关闭的预审问题

- 同 `run_id` 时完成局稳定优先于 abandoned。
- 合并时从 schema、游戏版本和配置指纹重算 cohort ID，不信任输入中的旧 ID。
- primary 选择最新含合格完成局的 cohort，fixture/legacy 不抢占顶层兼容字段。
- 多报告合并继承输入报告的 3×4 期望矩阵。
- AC-002 已覆盖独立胜率、卡牌、失败集中度、`insufficient` 和精确 12/30 缺口。
- AC-004 已逐项覆盖顶层 dimensions、card、failure 和 raw runs 仅来自 primary。
- 单卡对照保留旧 lift 兼容字段，并新增两侧各 20 局的 `*_sample_ready`。
- 损坏报告嵌套字段在进入聚合前返回 `malformed_report` / `malformed_run`，不再触发脚本错误。
- `PlaytestTelemetry.gd` 中已由证据门替代的六个旧聚合 helper 已删除，证据门紧凑分号语句已拆开。

### 裁决

- [x] 有 critical → 等待 File Manifest 扩展确认；确认后只修标注项并重新运行 20/20 与 Stage 1
- [ ] 仅 major/minor → 放行
- [ ] 全通过 → 进入 Stage 2

## Review Round 2

### 被评审对象

- 任务：`delivery-batch-015-playtest-evidence-gate`
- diff 范围：`18d3a31..Manifest 扩展与 20/20 后`
- Stage 2 评审模型：独立 GPT-5 子代理

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| AC 测试覆盖 | 通过 | - | `tdd-progress.md` | AC-001 至 AC-005 均有自动化测试；20/20 严格扫描全绿。 |
| 文件清单符合 | 通过 | - | `prd.md:64-83` | 用户确认后已纳入 schema 元数据与三个 Godot UID sidecar，当前 diff 无清单外文件。 |
| 禁止事项符合 | 通过 | - | `prd.md:119-125` | 未引入依赖、未改玩法数值、未批准 legacy/fixture。 |
| 决策表符合 | 通过 | - | `prd.md:41-53` | schema/cohort/留存/12-30/20/冲突/primary 均按约定实现。 |
| 挂载点接线 | 通过 | - | `design.md` | 四个挂载点全部接线。 |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| 编排-计算分离 | 通过 | - | `PlaytestEvidenceGate.gd` / `PlaytestTelemetry.gd` / `Main.gd` | 纯计算与编排边界清晰。 |
| 结构健康度 | 通过 | - | 同上 | 删除旧聚合 helper，没有继续膨胀 `Main.gd`。 |
| 简化与复用 | 通过 | - | `tdd-progress.md` | 无新依赖或多余抽象。 |
| 正确性 | 不符 | critical | `PlaytestEvidenceGate.gd:_aggregate_cohort()` | 同 cohort 的 fixture 会进入 summary、card、failure 和 raw runs；必须只聚合 eligible human。 |
| 正确性边界 | 不符 | major | `merge_reports()` / `retain_runs()` | 未拒绝非终局 outcome；缺少 40→41、4→5 cohort 核心边界。 |

### 裁决

- [x] 有 critical → 打回 TDD，只修标注项后重新评审

## Review Round 3

### 被评审对象

- 任务：`delivery-batch-015-playtest-evidence-gate`
- diff 范围：`18d3a31..Stage 2 修复后最终 worktree`
- Stage 2 评审模型：独立 GPT-5 子代理

### Stage 1 · 规范符合

Stage 1 继续 PASS；新增 fixture 隔离、非终局拒绝和留存硬边界均已回写 PRD/TDD 证据，最终 20/20 严格扫描再次全绿。

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| 编排-计算分离 | 通过 | - | `PlaytestEvidenceGate.gd` | 证据过滤、留存、聚合和合并仍集中在纯计算层。 |
| 结构健康度 | 通过 | - | `PlaytestTelemetry.gd` | 保留薄编排层并提供语义正确的 abandoned 上限常量与兼容别名。 |
| 简化与复用 | 通过 | - | 全 diff | 未新增依赖或多余抽象。 |
| 正确性 | 通过 | - | `PlaytestEvidenceGate.gd`、`test_playtest_evidence_gate.gd` | 同 cohort fixture 不进入真人 summary/card/failure/coverage/raw runs；primary 使用 eligible 时间；非终局输入被拒绝。 |
| 边界与回归 | 通过 | - | `test_playtest_evidence_gate.gd` | 40→41、4→5 cohort、fixture 独立配额、冲突与损坏容器均有回归。 |

### 问题汇总（按严重度）

- **Critical（阻断）**：无。
- **Major（应修）**：无。
- **Minor（记录后续）**：
  - `tools/merge_playtest_reports.gd` 仍直接写目标文件；极端磁盘/flush 失败可能留下部分 JSON。命令会非零退出且不影响核心证据计算，后续批次改为同目录临时文件成功后替换。

### 裁决

- [ ] 有 critical → 打回
- [x] 仅 minor → 放行；minor 记录后续
- [ ] 全无问题 → 放行
