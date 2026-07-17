# Delivery Batch 016 TDD 进度

| AC | 状态 | 测试 | 备注 |
| --- | --- | --- | --- |
| AC-001 纯指标契约 | done | `test_numerical_pressure_metrics.gd` | RED：缺纯模块；补契约后小样本 too-easy 与 p90 慢尾断言失败。Stage 1：62 胜+2 败 mutation 锁定三类分母。Stage 2 Critical-1：64 个全 timeout/失败局、0 胜局时精确 RED 出现伪 encounter_too_fast；仅在 turn_sample_count>0 时评估快慢后 GREEN，timeout/lethal 保留 |
| AC-002 opening package | done | `test_numerical_tree_auditor.gd` | RED：精确总分、独立目标/风险、贡献明细、条件排除与 pressure_contract 路径缺失。GREEN：91.38 / 82.47 / 88.41，三角色 opening_package_high。Stage 2 Major-1：combat_start 的 min_card_cost/card_type/every_n_attack_cards 原误计固定收益；与运行时条件集合对齐后全部进入 conditional_trigger exclusions，first_turn_only/once_per_* 保留 |
| AC-003 静态遭遇压力 | done | `test_numerical_tree_auditor.gd` | RED：base action、空窗、前三伤害、C0 EHP 层级与独立 summary 全缺失。GREEN：intro 4/6、1、34；Boss 2/5、2、15；96/104=0.9231。Stage 2：纯 EHP 锁定逐敌 ceil 与 safe ratio；Round 2 major 再与 CombatState 完全对齐，enemy/boss multiplier 各自下限0.1、每敌最终至少1HP |
| AC-004 单战过易风险 | done | `test_balance_simulator.gd` | RED：小样本 pressure schema 与 64-seed too-easy 风险全缺失。GREEN：小样本仅诊断；Ember intro 主风险 normal_too_easy，三角色第一章 Boss 主风险 boss_too_easy，复合风险与旧字段兼容 |
| AC-005 schema 与严格回归 | done | `test_numerical_balance_matrix.gd`、全量 | RED：version、异常 inventory、opening summary 与 single/campaign strategy 缺失。GREEN：version 3、pressure schema 1、current-greedy、256-seed opening 报告与 21/21 严格扫描通过 |

## 最小实现收敛

- 删除/避免：未增加第三方依赖、未复制 CombatState 结算、未修改正式玩法数值，也未把 pressure issues 混入旧 budget severity/issues。
- 复用：Godot Array 排序/数学函数、既有 DataLoader、真实 CombatState、现有 chapter expected_turns 与挑战倍率。
- 保留：64 样本硬门、条件 opening exclusion、旧 case 字段/risk_flag、campaign 冻结矩阵、独立 pressure severity/inventory 与确定性回归。
- `trellis-minimal:`：无；当前纯函数和两层编排均直接服务已声明 AC，无未来扩展抽象。
- 隔离 worktree 首轮严格扫描因缺 `.godot/imported` 失败；按系统调试只执行 Godot 预导入后原测试转绿，21/21 日志无 `SCRIPT ERROR` / `ERROR:`。
