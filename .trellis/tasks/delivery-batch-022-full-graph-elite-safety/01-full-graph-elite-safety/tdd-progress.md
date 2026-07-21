# 022-01 TDD 进度

## 进度表

| AC ID | 期望可观察结果 | 测试文件 | 测试命令 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- |
| AC-022-01 | v3 API/CLI 接受且映射为 competent/competent/predictive-v2 | `tests/test_balance_simulator.gd` | Godot `test_balance_simulator.gd` | done | RED 两条；GREEN 后 editor/Balance/Combat/matrix/hash 全绿 |
| AC-022-02 | 五层以上不安全精英漏斗在有安全 Boss 路线时被 v3 拒绝，旧 profiles 不变 | `tests/test_balance_simulator.gd` | Godot `test_balance_simulator.gd` | done | RED 两条；GREEN 后 editor/Balance/Combat/matrix/hash 全绿，v2 兼容通过 |
| AC-022-03 | 预测安全的精英路线仍可达并可选 | `tests/test_balance_simulator.gd` | Godot `test_balance_simulator.gd` | done | AC-022-02 通用递归已满足；新增反向回归首跑即绿，无额外实现；四项自检与 hash 全绿 |
| AC-022-04 | 全部路线不安全时使用确定性旧评分 fallback | `tests/test_balance_simulator.gd` | Godot `test_balance_simulator.gd` | done | fixture 初始期望误读旧 depth=3 hard-reject tie；系统调试后原命令与四项自检全绿 |
| AC-022-05 | preview-state cache 隔离、cycle guard 与重复选择确定 | `tests/test_balance_simulator.gd` | Godot `test_balance_simulator.gd` | done | RED：宝箱环 stack overflow；active path 改为 node id 后 GREEN，cache/state 与重复选择断言全绿 |
| AC-022-06 | editor/import、目标与回归全绿，生产 hash 不变 | 项目回归 | PRD 四项自检 | done | 最终 editor、Balance、Combat、matrix、diff/hash 全绿；v3 单格 smoke real 0.35s |

## 收尾核对

- [x] 所有 AC 状态为 `done`。
- [x] 无 AC 停留在 `red` / `green`。
- [x] PRD 自检全集全绿。
- [x] 已执行最小实现收敛。
- [x] design 挂载点逐项接线。
- [x] Stage 1 规范评审通过；独立强模型 Stage 2 为 `C0/M0/m1`，无阻断项。

## 最小实现收敛

- 删除项：无；实现只有一个 full-graph helper 和两个 profile dispatch 判定，没有平行 simulator、配置或抽象层。
- 复用项：现有 `_campaign_elite_is_safe`、`_campaign_preview_state_after_node`、`_successor_nodes`、preview key 与 route score fallback。
- 保留项：v2 历史分支、safe-candidate 非空门、无安全路径 fallback、cache state 隔离、node active-path 环保护和生产冻结测试。
- `trellis-minimal:` 注释：无；实现没有临时上限或未来扩展点。
