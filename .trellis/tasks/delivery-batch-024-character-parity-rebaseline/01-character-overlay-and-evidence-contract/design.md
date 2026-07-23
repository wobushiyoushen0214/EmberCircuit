# Design: 024-01 角色候选 Overlay 与版本化证据契约

## 需求覆盖

| 需求 ID | 当前状态 | 设计元素 | 本任务后预期 |
| --- | --- | --- | --- |
| REQ-003 | PARTIAL | 角色/遗物受控候选入口 | PARTIAL，解锁数值校准 |
| REQ-004 | PARTIAL | id selector 与角色隔离 | PARTIAL，尚未选择生产数值 |
| REQ-009 | PARTIAL | compact evidence v1 | PARTIAL，后续报告可版本化复核 |

## MVP 兼容性契约

| 已有行为 | 证据 | 必须保留 | 回归检查 |
| --- | --- | --- | --- |
| 023 schema v1 与七条旧 path | `test_balance_candidate_overlay.gd` | 是 | 原测试全绿 |
| 无 overlay 默认报告 | 同实例 byte identity 测试 | 是 | `test_balance_candidate_runtime.gd` |
| map/level/economy 恢复 | 023 tests | 是 | overlay 与 rebaseline tests |
| v3 campaign 语义 | `test_balance_simulator.gd` | 是 | simulator regression |

## 上下文清单

| 类型 | 路径 | 为什么重要 | 编辑前必须读取 |
| --- | --- | --- | --- |
| 代码 | `scripts/tools/BalanceCandidateOverlay.gd` | schema、error order、deep copy 和 metadata 来源 | 是 |
| 代码 | `scripts/tools/BalanceSimulator.gd:183-232` | 唯一允许修改的 simulator 区域 | 是 |
| 测试 | `tests/test_balance_candidate_overlay.gd` | 临时 fixture 与 byte identity 范例 | 是 |
| 数据 | `data/config/player.json`、`data/relics/relics.json` | collection/id/effect shape | 是 |
| 契约 | `.trellis/audits/2026-07-23-post-023-character-parity-candidate-delta-audit.md` | allowlist、证据字段与冻结项 | 是 |

## 决策表

| 决策点 | 选定方案 | 排除方案 | 原因 | 影响文件 |
| --- | --- | --- | --- | --- |
| array traversal | collection 后一段解释为 entity id | 数字 entity index | 数据排序不影响身份 | `BalanceCandidateSelector.gd` |
| effect traversal | entity 命中后只允许 `effects.0.amount` | trigger/type 动态匹配 | 两件目标遗物只有单效果，契约最窄 | `BalanceCandidateSelector.gd`、`BalanceCandidateOverlay.gd` |
| mutation | 五份 source 全部 deep copy 后修改 | 原地写再回滚 | 防失败路径污染 | `BalanceCandidateOverlay.gd` |
| simulator | 保存并恢复五份实例字段 | 重新 load_default_data | 避免 I/O 和非候选数据重载差异 | `BalanceSimulator.gd` |
| evidence repeat | 有 repeat 时强制 byte-identical | 只比较摘要 | 保护完整报告确定性 | `BalanceEvidenceDigest.gd` |

## 契约

### API / Interface

- `BalanceCandidateSelector.apply(dataset_name:String, dataset:Dictionary, path_parts:Array, value) -> Dictionary`
  - 成功：`{ok:true,errors:[]}`，只修改传入 deep copy。
  - 失败：`{ok:false,errors:[selector_not_found|selector_ambiguous|path_forbidden]}`。
- `BalanceEvidenceDigest.build(report:Dictionary, gate_verdict:Dictionary, report_path:String, repeat_path:String="") -> Dictionary`。
- `BalanceEvidenceDigest.write_digest(output_path:String, report:Dictionary, gate_verdict:Dictionary, report_path:String, repeat_path:String="") -> Dictionary`。

### Data / State

| 字段/状态 | 类型 | 允许值 | 默认值 | 校验规则 |
| --- | --- | --- | --- | --- |
| dataset | String | 五个固定 dataset | 无 | allowlist |
| selector id | String | 精确生产 id | 无 | 唯一命中 |
| deck | Array[String] | size=10 | 无 | 每项非空 |
| evidence case_count | int | 4 或 12 | 无 | 等于 case_rows 数量 |
| repeat_path | String | 空或现存文件 | 空 | 非空时 byte-identical |

## 编排-计算分离

| 层 | 本次元素 | 落点 |
| --- | --- | --- |
| 编排层 | load/copy/apply/error/metadata | `BalanceCandidateOverlay.gd` |
| 计算层 | id 命中与尾路径写入 | `BalanceCandidateSelector.gd` |
| 编排层 | simulator 五数据集赋值/恢复 | `BalanceSimulator.gd` |
| 计算层 | report/gate/repeat 校验与 compact row | `BalanceEvidenceDigest.gd` |

## 挂载点清单

| 挂载点 | 类型 | 位置 | 接线动作 |
| --- | --- | --- | --- |
| dataset map | 输入 | `BalanceSimulator._apply_candidate_overlay` | 加入 player/relics |
| overlay selector | 委托 | `BalanceCandidateOverlay.load_and_apply` | 新 path 调 selector |
| success assignment | 状态 | `_apply_candidate_overlay` | 替换五实例字段 |
| restore | 生命周期 | `_restore_candidate_overlay` | 恢复五实例字段 |
| digest API | 后续 runner 接口 | `BalanceEvidenceDigest` | 提供 build/write_digest |

## 非目标

- 不实现 024 candidate catalog、role gate、ladder 或生产晋级。
- 不修改卡牌、战斗、路线和奖励逻辑。
