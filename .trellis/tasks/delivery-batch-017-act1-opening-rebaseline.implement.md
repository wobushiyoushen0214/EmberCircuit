# Implementation Plan: 第一章与开局重标定

## 结构健康度预检

| 文件 | 结论 |
| --- | --- |
| `Main.gd` >15000 行 | 只在既有 intent helper 原位扩展，不做结构重构 |
| `BalanceSimulator.gd` >2400 行 | 只复用既有 campaign modifier 与攻击判断，不新增平行模块 |
| JSON 数据 | 原位逐 ID 修改，description/design/balance note 同步 |

## 严格 TDD 顺序

1. RED AC-001：新建重标定测试，先锁定候选 JSON、分数和 warning 清零。
2. GREEN AC-001：只修改起始包相关 JSON 与 numerical tree player targets。
3. RED/GREEN AC-002：先证明 single 缺 3 护甲/profile，再复用 campaign modifier source。
4. RED/GREEN AC-003：锁定 25%=18、金币 55/52/50 与未变化经济快照。
5. RED/GREEN AC-004：先锁三种复合 intent 的文字/投射/投影伤害，再接 Main 与 Simulator。
6. RED/GREEN AC-005：锁 7 遭遇精确静态指标，再修改 enemies/scaling/inventory。
7. RED AC-006：运行 64 paired seeds；若失败，严格按 PRD 阶梯一次改一个值。
8. GREEN AC-006 后运行 256 paired seeds，重生成 campaign matrix，更新 matrix 测试。
9. 完成 docs、Trellis 进度与 22/22 严格回归，执行最小实现收敛后进入双阶段评审。

## 修改边界

- 只允许 PRD File Manifest。
- `Main.gd` 只允许修改 `INTENT_ICON_PATHS` 与 `_intent_*` / forecast palette 相关函数。
- `BalanceSimulator.gd` 只允许修改 single modifier/profile 输出、复合攻击判断与必要的工具生成矩阵逻辑。
- 禁止改 CombatState 或增加新依赖。

## 失败恢复

- 定向测试出现稳定非预期红灯时切换 `trellis-debug-systematic-zh`。
- 64-seed 不达标时不得修改阈值；只按冻结阶梯逐值重跑。
- strict regression 或评审连续两次失败即暂停本批。
