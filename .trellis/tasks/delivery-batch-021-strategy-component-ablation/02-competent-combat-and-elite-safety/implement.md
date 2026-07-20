# Implementation Plan: 021-02

## 文件计划

| 步骤 | 文件 | 操作 | 验证 |
| --- | --- | --- | --- |
| 1 | `tests/test_balance_simulator.gd` | 逐 AC 写 fixture；先仅写 AC-07 看 RED | 每条 AC 单独红绿 |
| 2 | `BalanceSimulator.gd` | 签名透传，current/v1 继续旧 scorer | 兼容 fixture GREEN |
| 3 | `BalanceSimulator.gd` | competent score/target 纯 helper | AC-07～11 GREEN |
| 4 | `BalanceSimulator.gd` | 3-seed predictor、完整 key、deep copy、hard reject | AC-12～14 GREEN |
| 5 | `docs/11...md` | 记录 fixture、预测边界和回归 | 文档证据 |

## 结构健康度预检

| 文件 | 当前规模 | 阈值 | 结论 |
| --- | ---: | ---: | --- |
| `BalanceSimulator.gd` | 3009+ 行 | 400 | 不拆平行类；将纯计算集中为相邻私有 helper，避免在 turn loop 内堆评分细节 |
| `test_balance_simulator.gd` | 370+ 行 | 400 | 仅新增局部 fixture helper；不新建未列测试文件 |

## 修改边界与失败恢复

- current/v1 变化：立即恢复旧 `_score_card` 调用路径，再修 profile dispatch。
- fixture 失败非显然：切换 `trellis-debug-systematic-zh`，一次只修一处。
- 预测递归/性能异常：检查 predictor 是否在预测战斗内再次触发 elite gate；预测战斗只走 combat，不运行 campaign route。
- 输入 state 变化：修 deep duplicate 与药水副本，不弱化等价断言。
