# 023-03 TDD 进度

| AC ID | RED 测试 | GREEN 期望 | 状态 |
| --- | --- | --- | --- |
| AC-023-13 | selected/precondition/identity validation 不存在 | 无 selection 取消；合法 selection 绑定精确两份 256 artifact | pending |
| AC-023-14 | repeat 与共享精确 256 hard gate 未强制 | byte identity 与全部 raw hard threshold 通过 | pending |
| AC-023-15 | report-driven matrix sync 不存在 | 固定 rejection、失败不写入、精确 12-row source mapping | pending |
| AC-023-16 | PASS promotion 与 256 FAIL 精确 rollback 未固化 | v3 空 exception matrix 或 exact baseline restore；package flag 准确 | pending |
| AC-023-17 | 真实 256/repeat 与完整收尾证据不存在 | hashes、回归、AI/真人隔离、docs 和双阶段评审全过 | pending |

## 收尾核对

- [ ] 无 selected 128 时不存在 256 artifact。
- [ ] Primary/repeat byte-identical 且已记录 SHA-256。
- [ ] Matrix rows 由工具生成，没有手改 observed/economy/risk。
- [ ] 生产文件和 tests 只反映 PASS 或 rollback 一个分支。
- [ ] AI 证据未修改 real-human cohort。
- [ ] Stage 1 与独立强模型 Stage 2 无阻断。
