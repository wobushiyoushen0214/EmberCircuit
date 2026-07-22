# 023-02 TDD 进度

| AC ID | RED 测试 | GREEN 期望 | 状态 |
| --- | --- | --- | --- |
| AC-023-06 | layer band 未被 MapGenerator 读取 | 指定层池准确，legacy/malformed fallback 不变 | pending |
| AC-023-07 | raw 64/128/256 gate 与固定错误码不存在 | exact boundary、身份和样本拒绝准确，同一 hard gate 只切换预期样本数 | pending |
| AC-023-08 | P1-P5 exact/prefix/32-seed 路径无契约 | 五候选静态与图预算全过 | pending |
| AC-023-09 | 64 fail-closed ladder 不存在 | 每步独立 artifact，fail 不创建 128 | pending |
| AC-023-10 | 128/repeat/first-pass 不存在 | 只晋级 eligible step，首个 hard pass 停止 | pending |
| AC-023-11 | selected/none 生产分支未固化 | selected exact apply 或 baseline restore | pending |
| AC-023-12 | 全部冻结/回归未验证 | hash、21 单战、静态、地图、matrix 全绿 | pending |

## 收尾核对

- [ ] P1-P5 均有真实 artifact 或明确 not-run 原因。
- [ ] 没有 P6、门槛修改或 report 手改。
- [ ] 生产状态与 verdict 一致，正式 matrix 未改。
- [ ] Stage 1 与独立强模型 Stage 2 无阻断。
