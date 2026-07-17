# TDD 进度：第一章与开局重标定

| AC ID | 期望可观察结果 | 测试文件 | 状态 | 备注 |
| --- | --- | --- | --- | --- |
| AC-001 | 三角色候选 JSON、完整有序十张牌组、deck/opening 精确命中且 warning 清零 | `tests/test_act1_rebaseline.gd` | done | 完整牌组与 legacy Ember 同步；分数 73.86/65.97/76.21 与 79.14/75.77/79.73 |
| AC-002 | single 注入 steel_manual 且 profile 明确 | `tests/test_act1_rebaseline.gd`, `tests/test_balance_simulator.gd` | done | single 开场护甲为 bottle3+manual3；profile 与 skill_book_id 已输出 |
| AC-003 | 篝火 25%=18，金币 55/52/50 | `tests/test_act1_rebaseline.gd`, `tests/test_run_flow.gd` | done | JSON 与 campaign 均按 ceil 恢复 18 |
| AC-004 | 三种复合意图完整显示并计作攻击 | `tests/test_act1_rebaseline.gd`, `tests/test_run_flow.gd` | done | Main/Simulator 已锁详细文本、compact badge、攻击图标、攻击主色、徽标色、投射与伤害投影；真实 Ashen Edict 三效果完整预告 |
| AC-005 | 七遭遇静态压力和 112/96 层级精确命中 | `tests/test_act1_rebaseline.gd`, `tests/test_numerical_tree_auditor.gd` | done | 七遭遇静态值与 scaling 上限全部精确通过 |
| AC-006 | 64-seed 21 case 无禁止风险，Arc cards/turn≤5.3 | `tests/test_balance_simulator.gd`, `tests/test_numerical_pressure_metrics.gd` | done | schema v2 直接锁定高胜高损耗不误报、低损耗高胜仍报过易；21/21 risk_flags 为空 |
| AC-007 | 256 paired + 3×4×256 matrix + 22/22 strict regression | 数值测试、文档与全量 | done | single 21/21 无风险；campaign 12 格按 current-greedy 记录预期低胜率诊断；22/22 严格回归、错误日志 0 |

## 最小实现收敛

- 删除项：无新增抽象、依赖或未来扩展点可删；无效的 HP/伤害候选增量已在模拟阶段回滚。
- 复用项：复用现有 `NumericalPressureMetrics.aggregate_runs/risk_flags`、campaign modifier source、Main intent helper 与既有严格测试入口。
- 保留项：保留 schema v1 兼容输出字段、确定性 paired seed、完整意图预告、attrition p50/p90 边界与旧系统回归保护。
- `trellis-minimal:` 注释：无；本批仅原位数据、条件和既有 helper 扩展。

## 收尾核对

- [x] 所有 AC 状态为 `done`。
- [x] 无任何 AC 停留在 `red` / `green`。
- [x] `prd.md` 自检与 22 套严格回归最后一次运行全绿。
- [x] 已执行最小实现收敛。
- [x] `design.md` 挂载点逐项接线。
- [x] 未 commit/push/merge，等待双阶段评审。
