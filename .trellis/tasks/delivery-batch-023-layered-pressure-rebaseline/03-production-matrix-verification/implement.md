# Implementation Plan: 023-03

## 文件计划

| 步骤 | 文件 | 操作 | 验证 |
| --- | --- | --- | --- |
| 1 | new sync helper/test | precondition、identity、axis、128 rejection RED→GREEN | AC-023-13 |
| 2 | existing hard gate + new test | 调用精确 256 mode，repeat mismatch 和全部边界 RED→GREEN | AC-023-14 |
| 3 | helper + CLI + matrix test | report-keyed mapping、dry-run/no-write/apply RED→GREEN | AC-023-15 |
| 4 | production configs/tree/tests | PASS promotion 或精确 FAIL rollback RED→GREEN | AC-023-16 |
| 5 | real artifacts/docs/state | 运行 256/repeat，执行唯一分支、回归与评审 | AC-023-17 |

## 有序步骤

0. 记录四个生产 JSON 和六个冻结文件 SHA/semantic snapshot；创建任何 256 artifact 前验证 023-02 selected precondition。
1. 写 AC-023-13 in-memory report 失败测试；实现纯 selection/report validation。
2. 写 AC-023-14 repeat/sample/boundary 失败测试；调用既有 hard gate 的 256 模式，禁止复制阈值。
3. 写 AC-023-15 row-source/no-write 失败测试；实现 pure keyed transformation，再实现薄 dry-run CLI 与 atomic apply。
4. 写 AC-023-16 PASS/rollback 失败测试。FAIL 精确恢复：无 layer band、pressure 4、三章 `[1,2]` campfire、heal 25、rarity 65/28/7；旧 matrix 不变。
5. 从 tree 解析 selected step，生成 primary/repeat 256，比较字节、跑 dry-run，只执行 PASS 或 rollback 其中一个分支。
6. 按真实 artifact 更新 docs/Trellis evidence；跑定向与完整回归、Stage 1、独立强模型 Stage 2。

## 修改边界

- 只允许 PRD File Manifest；新 `.gd` 对应 `.uid` 是机械 sidecar。
- `LayeredPressureCandidateGate.gd` 只消费不修改；如果 023-02 完成后无法接受精确 256，必须 reopen 023-02，不能在本任务复制逻辑。
- 冻结数据/代码、campaign targets、真人报告、release/export 和 packaging outputs 禁止修改。

## 失败恢复

- 前置失败：标记 canceled，不生成 256、不编辑生产。
- primary/repeat 不同：保留 artifact/SHA 证据，不 sync，执行精确 rollback。
- hard/sync 失败：保留 failure codes，不放宽检查，恢复 baseline candidate fields 与旧 matrix。
- atomic apply 输出验证失败：保持原 tree，只用 debug skill 检查 helper/CLI。
- apparent PASS 后回归失败：恢复记录的 pre-sync tree bytes，保留 artifact，进入系统调试；package eligibility=false。
