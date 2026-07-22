# 023-01 TDD 进度

| AC ID | RED 测试 | GREEN 期望 | 状态 |
| --- | --- | --- | --- |
| AC-023-01 | 合法 overlay schema/metadata 当前缺失 | 副本应用、SHA、排序 applied fields | pending |
| AC-023-02 | 非法文件/dataset/path/value 当前无拒绝契约 | 固定错误码、0 cases、CLI exit 1 | pending |
| AC-023-03 | 同实例候选隔离当前不可证 | 候选后默认等于全新默认 | pending |
| AC-023-04 | CLI 两参数当前未解析 | API/CLI 语义一致，历史参数不变 | pending |
| AC-023-05 | attrition-v1 当前不存在 | 按层/遭遇原始计数、均值与排序准确 | pending |

## 收尾核对

- [ ] 每条 AC 有真实 RED→GREEN 记录。
- [ ] 默认 before/after 报告 byte-identical。
- [ ] 定向和回归测试全绿，无未知 ERROR/SCRIPT ERROR。
- [ ] Stage 1 与独立强模型 Stage 2 无阻断。
