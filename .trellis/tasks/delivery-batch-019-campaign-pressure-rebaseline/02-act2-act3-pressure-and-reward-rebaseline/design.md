# Design: 019-02 二三章压力、奖励与经济重标定

## 需求覆盖

| 需求 | 当前 | 设计元素 | 预期 |
| --- | --- | --- | --- |
| REQ-003/004/005 | PARTIAL | 固定候选阶梯 + 128 paired attribution gate | 获得唯一可进入 256 验证的候选 |

## MVP 兼容性契约

冻结开局、第一章、challenge、pressure targets、地图、intent/phase、CombatState 和存档 schema；只允许 PRD 表内 economy 与二三章 max_hp 变化。

## 上下文清单

| 类型 | 路径 | 用途 |
| --- | --- | --- |
| 归因证据 | `/tmp/ember019-attribution-128.json` | 决定是否允许进入本任务及 chapter bottleneck |
| 实际配置 | `data/config/economy.json` | 奖励/金币唯一运行时来源 |
| 实际配置 | `data/enemies/enemies.json` | 敌人 max_hp 唯一运行时来源 |
| 预算 | `data/config/monster_scaling.json` | 二三章 HP 边界，禁止越界 |
| 契约 | `data/config/numerical_tree.json` | target、snapshot、矩阵与 selected step |

## 编排-计算分离

| 层 | 元素 | 落点 |
| --- | --- | --- |
| 编排层 | R1→R2→R2-A→R2-B 的逐级执行与停机规则 | 本任务 `implement.md`/`tdd-progress.md` |
| 计算层 | 生产 reward/gold/max_hp 值与 BalanceSimulator 真实模拟 | 现有 JSON + `BalanceSimulator.gd`，不新增算法 |

## 挂载点清单

| 挂载点 | 类型 | 位置 | 接线动作 |
| --- | --- | --- | --- |
| Reward config | 配置项 | `economy.json` | selected step exact values |
| Enemy HP | 配置项 | `enemies.json` | 仅 R2-A/B 的 exact max_hp |
| Numerical snapshot | 配置项 | `numerical_tree.json` | 与实际 economy/selected step 对齐 |
| Direction gate | 工具报告 | `/tmp/ember019-selected-128.json` | 12×128 paired 输出和 SHA-256 |
| Regression | 测试 | `test_act2_act3_rebaseline.gd` | 冻结项、候选、预算、报告门 |

## 非目标

- 不重新设计卡牌 AI、角色基础数值、敌人行动、地图或目标区间。
- 不写 256 正式 observed matrix。
