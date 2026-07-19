# 019-01 双阶段评审报告

## Review Round 1

### 被评审对象

- 任务：`.trellis/tasks/delivery-batch-019-campaign-pressure-rebaseline/01-campaign-failure-attribution-contract`
- diff 范围：`0834853..HEAD`（隔离 worktree 未提交 diff）
- Stage 2 评审模型：GPT-5 强模型

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| AC 测试覆盖 | 通过 | - | `tests/test_balance_simulator.gd:160-215` | AC-019-01～05 均有 schema、边界、summary、determinism 断言；RED/GREEN 已记录 |
| 文件清单符合 | 通过 | - | 任务 PRD File Manifest | 仅修改 `BalanceSimulator.gd`、`test_balance_simulator.gd`、进度/调试/评审产物；无 data 改动 |
| 禁止事项符合 | 通过 | - | `scripts/tools/BalanceSimulator.gd` | 未改数值、CombatState、SaveManager、telemetry、真人 cohort 或新增依赖 |
| 决策表符合 | 通过 | - | `BalanceSimulator.gd:82-90,2117-2175,2473-2585` | schema 独立版本、config 样本门、失败分母、旧 risk flag 均按规划落地 |
| 挂载点接线 | 通过 | - | `run_campaign_suite()`、`_campaign_result()`、两个 aggregation methods | 报告、run snapshot、case 聚合、summary 聚合和测试入口均已接线 |
| 范围符合 | 通过 | - | 全 diff | 未实现 019-02/03 数值和矩阵同步内容 |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| 编排-计算分离 | 通过 | - | `BalanceSimulator.gd:1358-1455,2192-2370` | 生命周期快照与纯聚合函数分开；未创建平行 simulator |
| 结构健康度 | 记录 | minor | `BalanceSimulator.gd`（约 2790 行） | 现有文件已偏胖，本任务按 PRD 只能扩展既有入口；后续可独立拆 `CampaignAttribution`，本任务不越界 |
| 简化与复用 | 通过 | - | `_record_campaign_failure()`、现有 `_rounded_rate()` | failure map 去重，复用现有 config/DataLoader/聚合模式，无新依赖 |
| 正确性（边界/错误/回归） | 通过 | - | `BalanceSimulator.gd:2117-2175,2192-2370` | 0 losses、未到达章节、64/128 样本门、失败集中度 tie-break、paired determinism 均有覆盖 |
| 规范符合 | 通过 | - | 任务 PRD/design/check | 无 `.trellis/spec`；命名和测试风格与现有 Godot suite 一致 |

### 验证证据

- `test_balance_simulator.gd`：通过，输出 `Balance simulator smoke test passed.`
- `test_numerical_pressure_metrics.gd`：通过。
- `test_numerical_balance_matrix.gd`：通过。
- editor import：退出码 0。
- 12×128 campaign report：通过 schema/样本门；两次报告 SHA-256 均为 `329d716d39f71162392bde406f2484ce81456691a67c825f10be43732a6cdd2e`。
- 生产 `data/`：无 diff。

### 问题汇总（按严重度）

- **Critical（阻断）**：无。
- **Major（应修）**：无。
- **Minor（记录后续）**：`BalanceSimulator.gd` 继续偏胖；在本批禁止跨文件重构，后续维护批次可抽离纯 attribution calculator。

### 裁决

- [x] 仅 minor，放行；minor 记录后续。
- [ ] 有 critical，打回实现。
- [ ] 全部无问题，直接标记完成。

结论：Stage 1 PASS，Stage 2 PASS（C0/M0/m1）。019-02 可在隔离 worktree 中读取 `/tmp/ember019-attribution-128.json` 后开始；不得把该 128 报告写入正式 observed matrix。
