# Design: 023-02 分层压力与成长候选

## 编排-计算分离

| 层 | 元素 | 落点 |
| --- | --- | --- |
| 运行时编排 | layer 传入 pool selector | `MapGenerator.gd:_make_node` |
| 地图计算 | band 匹配与旧池 fallback | `MapGenerator.gd:_encounter_pool_for_layer` |
| Gate 计算 | 原始计数、目标、gap、单调、经济和失败集中；同一 API 参数化精确 128/256 样本 | `LayeredPressureCandidateGate.gd` |
| Ladder 编排 | P1-P5、64→128、repeat、artifact/verdict | `run_layered_pressure_ladder.gd` |
| 生产晋级 | selected overlay 写入或 baseline restore | 只在真实 verdict 后由任务步骤执行 |

## 决策表

| 决策 | 选定 | 排除 | 原因 |
| --- | --- | --- | --- |
| 遭遇节奏 | 可选 layer band + 旧池 fallback | 改敌人 HP/action | 单战无 risk，问题在全章共池 |
| 候选搜索 | 固定 P1-P5 串行 first-pass | 网格搜索/动态生成 P6 | 保证可复现和有界 |
| 64 | 只做方向门 | 当 hard sample | 低于 128 样本底线 |
| 128/256 | 同一全目标 hard gate，仅精确样本数不同 | 只看总胜率或复制最终阈值 | 防止角色、挑战、经济和集中度回归 |
| 生产写入 | 仅 selected 128 | 最优分数但未全过候选 | 用户要求逻辑严谨而非近似通过 |

## 挂载点

- `MapGenerator._make_node` 调用 layer pool helper。
- P1-P5 fixture 经 023-01 overlay 接入 simulator 三份数据。
- ladder 调用 v3 campaign suite 和 pure gate。
- numerical tree `campaign_rebaseline_023` 记录唯一裁决。
- `docs/13` 和 tests 绑定 verdict SHA、selected 与生产值。

## 结构健康度

- `MapGenerator.gd` 约 530 行，超过阈值；只添加一个无状态 pool selector，不搬动预算/连边算法。
- `BalanceSimulator.gd` 不在本任务 File Manifest，禁止继续增长。
- 新 gate、runner 和两个 test 独立成文件，单文件目标低于 400 行。

## 非目标

- 不做角色专属卡牌重设计；若 P1-P5 后角色差仍失败，按 stop condition 留给下一次 delta audit。
- 不生成正式 256 matrix，不打包试玩版。
