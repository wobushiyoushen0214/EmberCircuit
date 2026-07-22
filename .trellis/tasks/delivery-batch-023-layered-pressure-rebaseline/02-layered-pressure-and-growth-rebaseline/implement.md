# Implementation Plan: 023-02

## 文件计划

| 步骤 | 文件 | 操作 | 验证 |
| --- | --- | --- | --- |
| 1 | MapGenerator + map tests | layer band RED→GREEN，旧 graph 回归 | AC-023-06 |
| 2 | gate + gate test | raw-count direction/hard 边界 RED→GREEN；`evaluate_hard` 精确 128/256 参数契约 | AC-023-07 |
| 3 | P1-P5 + rebaseline test | exact/prefix/32-seed 路径 RED→GREEN | AC-023-08 |
| 4 | ladder runner | 64 fail-closed 和 artifact | AC-023-09 |
| 5 | ladder runner | 128/repeat/first-pass | AC-023-10 |
| 6 | production configs/tree/docs | 按 verdict selected 或 restore | AC-023-11 |
| 7 | regression/review | hash、21 单战、静态、地图、matrix | AC-023-12 |

## 修改边界

- 允许文件仅限 PRD File Manifest。
- `BalanceSimulator.gd` 与 023-01 helper 只消费，不修改。
- frozen SHA 文件、正式 matrix rows/profile/iterations 和真人 cohort 禁止修改。

## 失败恢复

- 旧 graph 漂移：检查 helper 是否在 band 缺失时直接返回原 pool，禁止重播 RNG 或改变抽取次数。
- candidate graph 失败：只修 schema/helper，不改变 P1-P5 值或路径预算。
- gate 与 report summary 冲突：以 raw integer 重新计算，不能信任 rounded rate 或放宽目标。
- P1-P5 全失败：恢复 map/level/economy 起点，写暂停裁决并取消 023-03。
