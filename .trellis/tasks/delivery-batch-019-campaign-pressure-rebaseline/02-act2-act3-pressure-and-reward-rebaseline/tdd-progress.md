# 019-02 TDD 进度

| AC ID | 期望可观察结果 | 测试文件 | 测试命令 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- |
| AC-019-06 | selected step 与 exact candidate、snapshot、冻结项一致 | `tests/test_act2_act3_rebaseline.gd` | Godot 对应 test | done | R1/R2/R2-A 均先看到候选 RED 再应用 exact 值；无候选通过后恢复 019 起点，并以 `paused_no_candidate_passed` 明确禁止误选。 |
| AC-019-07 | 候选逐级运行 12×128 且报告可复现 | 同上 | test + campaign CLI | stopped | R1 SHA `810111...1fdb4`，四档=`5.0/3.4/0.5/0.8%`；R2 SHA `a1b1ee...45aa`，四档=`5.5/3.1/0.5/0.5%`。R2-A 在 campaign 前触发静态回滚门，R2-B 继承该失败。 |
| AC-019-08 | 只改允许的二三章 max_hp，21/21 pressure 无 risk | 同上 | test + balance simulator | done | R2-A 仅改冻结表字段；第一章、single pressure 和 simulator 通过，但静态审计发现 `null_workshop:encounter_hp_low`，候选已完整回滚，warning 恢复为 0。 |
| AC-019-09 | 选定 128 report 通过目标、角色差、单调、经济和集中度门 | 同上 | campaign CLI | blocked | R1/R2 四档胜率均低于目标，R2-A/B 被静态 hard gate 淘汰；不存在可选 step，按 PRD 停止而非发明 R3。 |
| AC-019-10 | 256 observed rows 与任务起点完全一致 | `tests/test_numerical_balance_matrix.gd` | Godot 对应 test | done | 12 行 observed/risk/economy 精确快照保持 Batch 017 基线，未写入任何 128 结果。 |

## 收尾核对

- [x] 已穷尽冻结阶梯并触发 stop condition；无候选被误选。
- [x] 全部自检与双阶段评审完成（C0/M0/m1；产品门仍 blocked）。
- [x] R1/R2 报告路径和 SHA-256、R2-A 静态失败证据已记录。

## 最小实现收敛

- 删除项：回滚所有未通过的 economy/enemy 候选值；不保留 R2-A/B 的生产说明或 HP。
- 复用项：现有数据驱动 reward/enemy 配置与 BalanceSimulator。
- 保留项：归因 schema、冻结项、样本门、paired seed、完整报告证据和受控暂停状态。
