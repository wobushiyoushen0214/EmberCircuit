# 019-02 TDD 进度

| AC ID | 期望可观察结果 | 测试文件 | 测试命令 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- |
| AC-019-06 | selected step 与 exact candidate、snapshot、冻结项一致 | `tests/test_act2_act3_rebaseline.gd` | Godot 对应 test | pending | |
| AC-019-07 | 候选逐级运行 12×128 且报告可复现 | 同上 | test + campaign CLI | pending | |
| AC-019-08 | 只改允许的二三章 max_hp，21/21 pressure 无 risk | 同上 | test + balance simulator | pending | |
| AC-019-09 | 选定 128 report 通过目标、角色差、单调、经济和集中度门 | 同上 | campaign CLI | pending | |
| AC-019-10 | 256 observed rows 与任务起点完全一致 | `tests/test_numerical_balance_matrix.gd` | Godot 对应 test | pending | |

## 收尾核对

- [ ] 所有 AC 为 done；选定 step 是第一个通过方向门的候选。
- [ ] 全部自检全绿，报告路径和 SHA-256 已记录。
- [ ] 未 commit，已暂存并等待双阶段评审。

## 最小实现收敛

- 删除项：pending。
- 复用项：现有数据驱动 reward/enemy 配置与 BalanceSimulator。
- 保留项：冻结项、样本门、paired seed、完整报告证据。
