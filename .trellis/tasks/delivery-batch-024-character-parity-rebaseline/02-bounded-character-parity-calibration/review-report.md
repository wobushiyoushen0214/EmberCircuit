# 双阶段评审报告

## Review Round 1

### 被评审对象

- 任务：`delivery-batch-024-character-parity-rebaseline/02-bounded-character-parity-calibration`
- diff 范围：`6e0f5f9..staged working tree`
- Stage 2 评审模型：独立临时只读 Codex `gpt-5.6-sol`，session `019f8d20-4a91-7f61-a70c-55ef97cf0ebe`

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| AC 测试覆盖 | 通过 | - | `tdd-progress.md`、024 tests、matrix test | AC-024-07 至 AC-024-15 均有自动化或真实 runner 证据；自检全集全绿。 |
| 文件清单符合 | 通过 | - | `git diff --cached 6e0f5f9 --name-status` | 29 个改动均为 manifest 文件、条件 evidence 或任务流程产物。 |
| 禁止事项符合 | 通过 | - | frozen SHA / full diff | 未修改生产五 JSON、卡牌、敌人、遭遇、挑战、CombatState、正式 matrix rows；无额外候选、256 或包体。 |
| 决策表符合 | 通过 | - | catalog、gate、runner、verdict | exact catalog、首过停机、唯一 C1、共享 128 hard gate、6,912 上限均按冻结决策实现。 |
| 挂载点接线 | 通过 | - | runner preflight/role/combined/hard/digest/verdict | 五个挂载点均已接线，真实 Arc 耗尽分支保存四份 digest 与唯一 verdict。 |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| 编排-计算分离 | 通过 | - | catalog/gate/runner | 计算与编排分文件，128 hard/digest 均复用既有模块。 |
| 结构健康度 | 通过 | - | 新文件均低于 400 行 | 未扩张 023 runner 或 simulator。 |
| 真实写盘失败传播 | 不符 | critical | `run_character_parity_ladder.gd:306` | 写 JSON 后 flush、检查 get_error 并关闭；真实 helper seam 覆盖成功打开后写失败。 |
| selected row 精确相等 | 不符 | critical | `CharacterParityCandidateGate.gd:69,348` | 不得用 `is_equal_approx` 把近整数浮点归一后比较。 |
| 128 错误语义/step 证据 | 不符 | major | `run_character_parity_ladder.gd:123-136` | 统一为固定 `input_missing/evidence_write_failed`，并把失败步骤写入 verdict steps。 |
| losses 原始行一致性 | 不符 | major | `CharacterParityCandidateGate.gd:237,295` | 校验并使用报告中的 losses，不能以 `runs-wins` 替代精确字段比较。 |
| tree/verdict/docs 绑定 | 不符 | major | `test_numerical_balance_matrix.gd:90` | 读取真实 verdict，核对 SHA/status/selected/runs/flags/evidence SHA，并绑定 docs。 |

### 问题汇总（按严重度）

- **Critical（阻断）**：2；真实 JSON 写盘错误可能被误报成功，selected row 的近似整数归一可能错误放行组合 64。
- **Major（应修）**：3；128 错误码/step 证据、losses 原始值、AC-024-14 回归绑定不足。
- **Minor（记录后续）**：0。

### 裁决

- [x] 有 critical → 打回 `trellis-implement-tdd-zh`，只修标注项，修后重新评审
- [ ] 仅 major/minor → 放行；major 建议本轮修，minor 记入任务备注
- [ ] 全通过 → 交回编排会话推进任务状态

## Review Round 2

### 被评审对象

- 任务：`delivery-batch-024-character-parity-rebaseline/02-bounded-character-parity-calibration`
- diff 范围：`6e0f5f9..staged working tree`
- Stage 2 评审模型：独立临时只读 Codex `gpt-5.6-sol`，session `019f8d35-c0cb-7702-822c-34e193d216fa`

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| AC 测试覆盖 | 通过 | - | 024 tests、matrix test | AC-024-07 至 AC-024-15 均有自动化/真实证据；Round 1 修复回归全绿。 |
| 文件清单符合 | 通过 | - | `git diff --cached 6e0f5f9 --name-status` | 改动仍限定于 manifest、条件 evidence 与任务流程产物。 |
| 禁止事项符合 | 通过 | - | frozen SHA / full diff | 无生产数值、正式 matrix rows、额外候选、256 或包体改动。 |
| 决策表符合 | 通过 | - | catalog、gate、runner | 固定候选、首过停机、共享 hard gate 与样本上限未漂移。 |
| 挂载点接线 | 通过 | - | runner 与 evidence | catalog/gate/hard/digest/verdict 均接线。 |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| Round 1 五项修复 | 通过 | - | catalog/gate/runner/tests/matrix | 原 2 Critical / 3 Major 均落实，新增测试能击中旧实现。 |
| exact catalog 近整数漂移 | 不符 | critical | `CharacterParityCandidateCatalog.gd:48,192-214` | catalog/test 不得用 `is_equal_approx` 把 `5.000001` 归一为 5。 |
| repeat mismatch compact evidence | 不符 | critical | `run_character_parity_ladder.gd:145-151` | 两份 non-identical 128 full report 已实际生成时必须保存可版本化摘要并由 verdict 绑定。 |

### 问题汇总（按严重度）

- **Critical（阻断）**：2；exact catalog 仍可放行近整数漂移，repeat mismatch 分支缺少 compact digest。
- **Major（应修）**：0。
- **Minor（记录后续）**：0。

### 裁决

- [x] 有 critical → 打回 `trellis-implement-tdd-zh`，只修标注项，修后重新评审
- [ ] 仅 major/minor → 放行；major 建议本轮修，minor 记入任务备注
- [ ] 全通过 → 交回编排会话推进任务状态

## Review Round 3

### 被评审对象

- 任务：`delivery-batch-024-character-parity-rebaseline/02-bounded-character-parity-calibration`
- diff 范围：`6e0f5f9..staged working tree`
- Stage 2 评审模型：独立临时只读 Codex `gpt-5.6-sol`，session `019f8d4c-2977-7483-aa2a-2a7547714497`

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| AC 测试覆盖 | 通过 | - | 024 tests、matrix test | AC-024-07 至 AC-024-15 均有自动化/真实证据；Round 2 修复回归全绿。 |
| 文件清单符合 | 通过 | - | `git diff --cached 6e0f5f9 --name-status` | 改动仍限定于 manifest、条件 evidence 与任务流程产物。 |
| 禁止事项符合 | 通过 | - | frozen SHA / full diff | 未改生产数值、正式 matrix rows、正式 evidence；未运行额外候选、256 或打包。 |
| 决策表符合 | 通过 | - | catalog、gate、runner | Arc 三候选均失败即停机的正式裁决未漂移；条件 128 分支保持 fail-closed。 |
| 挂载点接线 | 通过 | - | runner 与 evidence | catalog/gate/hard/digest/verdict 均已接线。 |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| Round 2 两项修复 | 通过 | - | catalog/runner/tests | exact catalog 近整数漂移与 repeat mismatch 双摘要均已落实。 |
| repeat 阶段失败的 primary evidence | 不符 | critical | `run_character_parity_ladder.gd` 的 repeat 生成/保存失败分支 | primary 128 已保存后，即使 repeat 生成或保存失败，也必须先为 primary 写 standalone digest 并由 verdict 绑定；digest 写失败须 fail-closed。 |

### 问题汇总（按严重度）

- **Critical（阻断）**：1；repeat 阶段失败时，已保存的 primary 128 full report 缺少可版本化 compact digest/verdict 绑定。
- **Major（应修）**：0。
- **Minor（记录后续）**：0。

### 裁决

- [x] 有 critical → 打回 `trellis-implement-tdd-zh`，只修标注项，修后重新评审
- [ ] 仅 major/minor → 放行；major 建议本轮修，minor 记入任务备注
- [ ] 全通过 → 交回编排会话推进任务状态

## Review Round 4

### 被评审对象

- 任务：`delivery-batch-024-character-parity-rebaseline/02-bounded-character-parity-calibration`
- diff 范围：`6e0f5f9..staged/index tree`
- Stage 2 评审模型：独立临时只读 Codex `gpt-5.6-sol`，session `019f8d5a-da7f-77c1-9c34-5e0e33bfa944`

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| AC 测试覆盖 | 通过 | - | 024 tests、matrix test、TDD evidence | AC-024-07 至 AC-024-15 均有 RED→GREEN、真实证据或回归门，editor 与 11 项测试全绿。 |
| 文件清单符合 | 通过 | - | `git diff --cached 6e0f5f9 --name-status` | 实现、测试、条件 evidence 与流程报告均在 manifest 或已记录的强制流程产物范围。 |
| 禁止事项符合 | 通过 | - | frozen SHA / full diff | 10 个生产/战斗冻结文件与起点一致；未重跑正式 ladder、023、256 或打包。 |
| 决策表符合 | 通过 | - | catalog、gate、runner、verdict | 固定候选顺序、首过/耗尽停机、共享 128 hard gate、6,912 上限均未漂移。 |
| 挂载点接线 | 通过 | - | catalog/gate/hard/digest/verdict | 五个挂载点完整；真实 Arc 耗尽 verdict 与四份摘要保持冻结。 |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| repeat 阶段失败的 primary evidence | 通过 | - | `run_character_parity_ladder.gd:123,218` | repeat 生成/保存失败均先写 primary standalone digest，verdict step 绑定 full/digest path 与 SHA。 |
| primary digest 写失败 | 通过 | - | `run_character_parity_ladder.gd:223` | 原始错误统一收敛为 `evidence_write_failed` 并立即 fail-closed，无后续错误覆盖。 |
| mismatch/identical 分流 | 通过 | - | `run_character_parity_ladder.gd:145` | mismatch 写两份 standalone digest；byte-identical 只写一份绑定 repeat 的 digest。 |
| Round 1/2/3 回归 | 通过 | - | catalog/gate/runner/tests/matrix | 写错误传播、精确行/losses、近整数拒绝、双摘要与 tree/verdict/docs 绑定均保持有效。 |
| 结构与复用 | 通过 | - | 新文件均低于 400 行 | 编排与计算分离，复用共享 hard gate、digest、overlay、simulator 与地图校验。 |

### 问题汇总（按严重度）

- **Critical（阻断）**：0。
- **Major（应修）**：0。
- **Minor（记录后续）**：0。

### 裁决

- [ ] 有 critical → 打回 `trellis-implement-tdd-zh`，只修标注项，修后重新评审
- [ ] 仅 major/minor → 放行；major 建议本轮修，minor 记入任务备注
- [x] 全通过 → 交回编排会话推进任务状态
