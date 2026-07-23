# 双阶段评审报告

## Review Round 1

### 被评审对象

- 任务：`01-character-overlay-and-evidence-contract`
- diff 范围：`f5c7f88..当前暂存`
- Stage 2 评审模型：独立强模型 `/root/stage2_review_02401`

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| AC 测试覆盖 | 通过 | - | 三个 024 测试 + PRD 自检全集 | AC-024-01 至 AC-024-06 均有定向/回归证据，最后一次九项自检退出码全为 0；未修改或弱化 023 测试。 |
| 文件清单符合 | 通过（流程例外已记录） | - | `git diff --cached --name-status` | 业务代码、测试、UID、TDD/review 产物均在 File Manifest；`debug-report.md` 是测试失败后由 `trellis-debug-systematic-zh` 强制生成的任务内流程证据，已在执行时报告，不属于产品代码扩散。 |
| 禁止事项符合 | 通过 | - | 当前 staged diff | 未改生产 JSON、numerical tree、matrix、卡牌/敌人/挑战、`CombatState.gd`、CLI 或包体；未引入依赖，未运行 A/E/Y 正式候选。 |
| 决策表符合 | 通过 | - | overlay/selector/digest/simulator | 保持 schema v1；角色/遗物按 id 唯一命中；重复/缺失 selector fail-closed；digest 为独立 helper；simulator 只增加五数据集薄接线。 |
| 挂载点接线 | 通过 | - | overlay:selector；simulator apply/restore；digest API | overlay 已委托 selector；player/relics 已加入 apply/assign/restore；`build/write_digest` API 已提供给后续 runner。 |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| 编排-计算分离 | 通过 | - | `BalanceCandidateOverlay.gd` / selector / digest | overlay 编排、selector 计算、simulator 生命周期和 digest 计算职责清晰。 |
| 结构健康度 | 通过 | - | 新 helper 与 simulator:183-222 | selector 56 行、digest 261 行；胖 simulator 只增加 10 行生命周期映射。 |
| 简化与复用 | 通过 | - | 当前 staged diff | 无新依赖、过度抽象或明显重复实现；最小实现收敛已记录。 |
| 正确性(边界/错误/回归) | 不符 | critical / major | `BalanceEvidenceDigest.gd:17-44,186` | source 文件未与 report Dictionary 绑定；gate 允许真实 gate 不可能产生的矛盾裁决。 |
| 规范符合(spec) | 通过 | - | 全 diff | 仓库无 `.trellis/spec/`；命名、目录、错误排序和测试组织符合现有 Godot 工具风格。 |

### 问题汇总（按严重度）

- **Critical（阻断）**：
  - `scripts/tools/BalanceEvidenceDigest.gd:17-44`：`case_rows/candidate_identity` 来自传入 report A，SHA 来自独立 `report_path` B；不同报告或非 JSON 文件仍可能成功，使 source SHA 无法证明 compact evidence。修复应解析 source 文件并与 report 严格绑定（或直接以文件为唯一源），并补 report/path mismatch 与非法 JSON RED。
- **Major（应修）**：
  - `scripts/tools/BalanceEvidenceDigest.gd:186`：gate 仅校验类型，接受 `{eligible:false,pass:true}` 或 pass 同时带 failure codes 等真实 gate 不可能输出的矛盾状态。应校验 `pass == eligible && failure_codes.is_empty()` 的既有 gate 关系，并拒绝空/重复错误码。
- **Minor（记录后续）**：无。

### 裁决

- [x] 有 critical → 打回 `trellis-implement-tdd-zh`，只修标注项，修后重新评审
- [ ] 仅 major/minor → 放行；major 建议本轮修，minor 记入任务备注
- [ ] 全通过 → 交回编排会话推进任务状态

## Review Round 2

### 被评审对象

- 任务：`01-character-overlay-and-evidence-contract`
- diff 范围：`f5c7f88..当前暂存（含 Round 1 修复）`
- Stage 2 评审模型：独立强模型 `/root/stage2_review_02401`

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| AC 测试覆盖 | 通过 | - | 三个 024 测试 + PRD 自检全集 | Round 1 两项问题均先补 RED；修复后九项自检再次退出 0，未弱化旧断言。 |
| 文件清单符合 | 通过（流程例外已记录） | - | staged name-status | 修复只触及 digest、对应测试、TDD/debug/review 流程产物；无新增范围外业务文件。 |
| 禁止事项符合 | 通过 | - | 当前 staged diff | 生产数据、旧 gate、CombatState、CLI、正式 matrix 和候选 fixture 仍未修改。 |
| 决策表符合 | 通过 | - | digest build/validation | 继续使用 schema v1 和固定错误码；source 语义绑定复用 `identity_mismatch/input_missing`，未扩 schema。 |
| 挂载点接线 | 通过 | - | overlay/selector、simulator、digest API | 挂载点保持完整，Round 1 修复未改变编排边界。 |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| 编排-计算分离 | 通过 | - | overlay/selector/digest/simulator | source/gate 校验仍位于独立 evidence 计算层。 |
| 结构健康度 | 通过 | - | `BalanceEvidenceDigest.gd` | digest 281 行，低于 400 行目标；未扩张 simulator。 |
| 简化与复用 | 通过 | - | Round 1 修复 diff | 使用 Godot JSON 归一化、FileAccess 和现有错误列表，无新依赖或额外抽象。 |
| 正确性(边界/错误/回归) | 通过 | - | digest:17-44,188-216；evidence tests | report/path 严格语义绑定；非法 JSON/错配、矛盾 verdict、空/重复/非字符串 code 均 fail-closed；旧排序/repeat/SHA/I/O 行为全绿。 |
| 规范符合(spec) | 通过 | - | 全 diff | 无 `.trellis/spec/`；命名、错误语义和测试风格与现有工具一致。 |

### 问题汇总（按严重度）

- **Critical（阻断）**：无。
- **Major（应修）**：无。
- **Minor（记录后续）**：无。

### 裁决

- [ ] 有 critical → 打回 `trellis-implement-tdd-zh`
- [ ] 仅 major/minor → 放行；major 建议本轮修，minor 记入任务备注
- [x] 全通过 → 交回编排会话推进任务状态
