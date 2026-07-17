# 双阶段评审报告：第一章与开局重标定

## Review Round 1

### 被评审对象

- 任务：`delivery-batch-017-act1-opening-rebaseline`
- diff 范围：`e982705..工作树`
- Stage 2 评审模型：Codex 强模型代理

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| AC 测试覆盖 | 不符 | critical | `tests/test_act1_rebaseline.gd` | 缺完整三角色牌组、复合意图图标/颜色和 attrition 直接分支测试 |
| 文件清单符合 | 不符 | critical | `prd.md` File Manifest | 漏列 `NumericalPressureMetrics.gd`，并需纳入两个跨系统回归测试 |
| 禁止事项符合 | 通过 | - | 全 diff | 未改全局倍率、后章、CombatState 或商店价格 |
| 决策表符合 | 不符 | major | `design.md` | pressure schema 仍写 v1，与正式 v2 冲突 |
| 挂载点接线 | 通过 | - | `Main.gd`, `BalanceSimulator.gd` | 三种复合攻击已接线 |

### 裁决

- [x] 有 critical，打回 TDD/系统调试，只修标注项后重审。

## Review Round 2

### 被评审对象

- 任务：`delivery-batch-017-act1-opening-rebaseline`
- diff 范围：`e982705..工作树`
- Stage 2 评审模型：Codex 强模型代理

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| AC 测试覆盖 | 通过 | - | `tests/test_act1_rebaseline.gd`, `tests/test_numerical_pressure_metrics.gd` | 精确牌组、复合视觉契约和 schema v2 分支均覆盖 |
| 文件清单符合 | 通过 | - | `prd.md` File Manifest | 用户确认扩展后的全部改动均在清单内 |
| 禁止事项符合 | 通过 | - | 全 diff | 无越界实现 |
| 决策表符合 | 通过 | - | `prd.md`, `design.md` | schema v2 与最终候选一致 |
| 挂载点接线 | 通过 | - | `design.md` | 五个挂载点均已接线 |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| 编排-计算分离 | 通过 | - | `NumericalPressureMetrics.gd`, `BalanceSimulator.gd` | 纯指标与模拟编排保持分离 |
| 结构健康度 | 不符 | critical | `data/enemies/enemies.json:192`, `Main.gd:9865` | 真实 Boss 三效果行动隐藏易伤，必须补齐 intent 与显示 |
| 简化与复用 | 通过 | - | 全 diff | 复用既有 helper，无新依赖 |
| 正确性 | 不符 | critical | `tests/test_act1_rebaseline.gd` | 应直接读取真实 Ashen Edict，而非只测手工双效果 fixture |
| 规范符合 | 不符 | major | `docs/03_CONTENT_AND_BALANCE.md:128` | `cinder_kennels` 仍写旧总生命 56 |

### 裁决

- [x] 有 critical，打回 TDD，补真实 Boss fixture 与完整三效果预告后重审。

## Review Round 3

### 被评审对象

- 任务：`delivery-batch-017-act1-opening-rebaseline`
- diff 范围：`e982705..工作树`
- Stage 2 评审模型：Codex 强模型代理

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| AC 测试覆盖 | 通过 | - | `tests/test_act1_rebaseline.gd:25`, `tests/test_numerical_pressure_metrics.gd:70` | AC-001～AC-007 均有可观察测试证据 |
| 文件清单符合 | 通过 | - | `prd.md` File Manifest | 当前全部修改及新增文件均在清单内 |
| 禁止事项符合 | 通过 | - | 全 diff | 未触碰冻结范围或引入依赖 |
| 决策表符合 | 通过 | - | `prd.md`, `design.md` | version 4/schema v2/default steel_manual/复合意图均一致 |
| 挂载点接线 | 通过 | - | `design.md` | 全部挂载点完成 |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| 编排-计算分离 | 通过 | - | `scripts/tools/NumericalPressureMetrics.gd` | 指标逻辑保持纯计算，模拟器只负责编排 |
| 结构健康度 | 通过 | - | `scripts/main/Main.gd:9865` | 仅在既有 intent helper 原位扩展，没有扩大页面结构职责 |
| 简化与复用 | 通过 | - | `scripts/main/Main.gd:9971` | compact 状态 helper 职责单一，未知状态安全回退，无过度抽象 |
| 正确性(边界/错误/回归) | 通过 | - | `data/enemies/enemies.json:192`, `tests/test_act1_rebaseline.gd:118` | Ashen Edict 的伤害、易伤、灼伤牌三效果与详细/compact 预告完全一致；空 status 路径兼容旧动作 |
| 规范符合(spec) | 通过 | - | `docs/03_CONTENT_AND_BALANCE.md:128`, `docs/09_NUMERICAL_TREE_AND_BALANCE.md` | 正式数值、campaign 诊断与实现一致 |

### 问题汇总（按严重度）

- **Critical（阻断）**：无。
- **Major（应修）**：无。
- **Minor（记录后续）**：无。

### 验证证据

- Godot 预导入退出码 0。
- 第三轮严格回归：22/22 测试退出码 0，日志 `SCRIPT ERROR|ERROR:` 为 0。
- 日志：`/tmp/embercircuit-batch017-regression-round3-20260717`。
- `git diff --check` 通过，`.godot/` 跟踪文件数为 0。
- `3×7×256` single：21/21 pressure case 无风险。
- `3×4×256` campaign：保留 current-greedy 12 格低胜率诊断，不冒充真人难度。

### 裁决

- [x] 全通过，交回编排会话推进任务状态。
