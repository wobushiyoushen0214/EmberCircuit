# Implementation Plan: 数值压力契约

## 结构健康度预检

| 文件 | 当前行数 | 阈值 | 结论 |
| --- | ---: | ---: | --- |
| `BalanceSimulator.gd` | 2453 | 400 | 不再堆纯算法；只加编排和委托 |
| `NumericalTreeAuditor.gd` | 634 | 400 | 只组织数据；循环和分位数下沉新模块 |
| `test_balance_simulator.gd` | 现有单文件 | 400 | 纯算法场景放新测试，既有文件只做集成 |

## 有序步骤

1. RED AC-001：新建纯指标测试，锁定分位数、样本口径、风险顺序与循环行动算法。
2. GREEN AC-001：新建 `NumericalPressureMetrics.gd`，只实现使测试变绿的纯函数。
3. RED/GREEN AC-002：在 Auditor 测试先锁定三角色完整 opening package，再加载遗物/技能书并输出贡献与排除项。
4. RED/GREEN AC-003：先锁定 intro、Boss 与 96/104 层级，再接入静态行动压力和 EHP。
5. RED/GREEN AC-004：先锁定 case schema、64 seeds too-easy 与小样本门，再让 Simulator 委托纯模块。
6. RED/GREEN AC-005：冻结 version 3、策略声明与异常 inventory；更新数值文档和实现日志。
7. 运行 256 seeds opening 基线、21 套严格回归、最小实现收敛和双阶段评审。

## 修改边界

- 仅允许 PRD File Manifest。
- 禁止修改正式数值源、CombatState、Main、SaveManager、地图、UI、美术、音频和构建版本。
- 禁止新增第三方依赖。

## 失败恢复

- 任一定向测试该绿不绿时切换 `trellis-debug-systematic-zh`，一次只修一个稳定失败。
- 当前错误基线未产生 too-easy 时先核对样本口径和 tier/expected-turns 绑定，禁止调低断言凑绿。
- verifier 或 review 两次失败即停止本批。
