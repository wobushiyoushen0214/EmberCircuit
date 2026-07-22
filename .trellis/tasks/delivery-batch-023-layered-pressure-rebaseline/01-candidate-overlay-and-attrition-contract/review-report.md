# 双阶段评审报告

## Review Round 1

### 被评审对象

- 任务：`01-candidate-overlay-and-attrition-contract`
- diff 范围：`9230dc5..当前暂存`
- Stage 2 评审模型：独立强模型 `/root/stage2_review_02301`

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| AC 测试覆盖 | 通过 | - | `tests/test_balance_candidate_overlay.gd` | AC-023-01 至 AC-023-05 均有定向测试且当时为绿 |
| 文件清单符合 | 通过 | - | `git diff --cached --name-status` | 业务改动均在 File Manifest；PRD 修正为已报告的 runtime schema 冲突 |
| 禁止事项符合 | 通过 | - | 全 diff | 未改生产 JSON、MapGenerator、CombatState、Main、正式 matrix 或真人报告 |
| 决策表符合 | 通过 | - | helper/simulator/CLI | 独立 helper、隔离副本、opt-in diagnostics、固定错误码均按契约 |
| 挂载点接线 | 通过 | - | simulator/CLI | lifecycle、node capture、case aggregation、parser、CLI exit 均接线 |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| 编排-计算分离 | 通过 | - | `BalanceCandidateOverlay.gd` / `BalanceSimulator.gd` | 校验和应用位于独立计算 helper |
| 结构健康度 | 通过 | - | 新 helper 与相邻聚合 | 未把 overlay 校验堆入胖模拟器 |
| 简化与复用 | 通过 | - | 全 diff | 无新依赖或未来抽象 |
| 正确性(边界/错误/回归) | 不符 | critical/major | overlay helper / attrition aggregation | 未知字段静默接受；timeout 误计 death；近整数小数被接受 |
| 规范符合(spec) | 通过 | - | 全 diff | 仓库无 `.trellis/spec/`，命名与测试风格符合现有约定 |

### 问题汇总（按严重度）

- **Critical（阻断）**：未知顶层/change 字段未 fail-closed；正 HP timeout 被计为 death。
- **Major（应修）**：`is_equal_approx` 使接近整数的小数通过整数校验。
- **Minor（记录后续）**：无。

### 裁决

- [x] 有 critical → 打回 `trellis-implement-tdd-zh`，只修标注项，修后重新评审
- [ ] 仅 major/minor → 放行
- [ ] 全通过 → 交回编排会话推进任务状态

## Review Round 2

### 被评审对象

- 任务：`01-candidate-overlay-and-attrition-contract`
- diff 范围：`9230dc5..当前暂存（含 Round 1 修复）`
- Stage 2 评审模型：独立强模型 `/root/stage2_review_02301`

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| AC 测试覆盖 | 通过 | - | `tests/test_balance_candidate_overlay.gd` | 新增未知字段、近整数、合成 timeout 与真实 timeout 回归 |
| 文件清单符合 | 通过 | - | 当前 diff | 修复仅触及 helper、simulator、定向测试与任务记录 |
| 禁止事项符合 | 通过 | - | 当前 diff | 生产数据和禁止模块仍未修改 |
| 决策表符合 | 通过 | - | overlay/attrition 分支 | 未知字段用固定 `value_invalid` 拒绝；death 使用真实结算 HP |
| 挂载点接线 | 通过 | - | simulator/CLI | 挂载点保持完整，默认分支 byte-identical |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| 编排-计算分离 | 通过 | - | helper/simulator | 无新增混层 |
| 结构健康度 | 通过 | - | 相邻 helper | 修复为局部条件，无结构扩散 |
| 简化与复用 | 通过 | - | 全 diff | 精确比较和字段 allowlist 为最小修复 |
| 正确性(边界/错误/回归) | 通过 | - | helper:76-114,212-217；simulator:3703-3742 | 三项缺陷均封闭，未发现新 critical/major |
| 规范符合(spec) | 通过 | - | 全 diff | 错误码、排序、命名与测试风格保持一致 |

### 问题汇总（按严重度）

- **Critical（阻断）**：无。
- **Major（应修）**：无。
- **Minor（记录后续）**：无。

### 裁决

- [ ] 有 critical → 打回 `trellis-implement-tdd-zh`
- [ ] 仅 major/minor → 放行
- [x] 全通过 → 交回编排会话推进任务状态
