# 023-01 TDD 进度

| AC ID | 期望可观察结果 | 测试文件 | 测试命令 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- |
| AC-023-01 | 合法 overlay 返回唯一 metadata、深副本和排序 applied fields | `tests/test_balance_candidate_overlay.gd` | Godot overlay test | done | RED：helper 缺失退出 1；GREEN：schema/id/SHA/applied_fields/deep-copy 全过；sim/map/matrix/editor/cmp 全绿 |
| AC-023-02 | 九类非法输入返回固定错误码和空 datasets | 同上 | Godot overlay test | done | RED：id/dataset/path/duplicate/value 被接受；GREEN：九码和五类 value validator fail-closed；评审修复未知字段静默接受和近整数小数；JSON 整数 float 仍兼容；sim/map/matrix/editor/cmp 全绿 |
| AC-023-03 | 同实例 overlay→默认等于全新默认，生产输入不变 | 同上 | Godot overlay + baseline cmp | done | RED：simulator 忽略 overlay；GREEN：候选 metadata 接入、三引用恢复、同实例默认=全新默认；四生产 SHA 与 before/after cmp 不变 |
| AC-023-04 | CLI/API 两参数一致，rejected 退出 1，历史行为不变 | 同上 | Godot overlay/CLI tests | done | RED：parser 丢弃两个参数且非法 CLI 保存报告并返回 0；GREEN：接入 `--candidate-overlay`/`--candidate-diagnostics`，保存前拦截 rejected；overlay/sim/map/matrix/editor/cmp/hash/diff 全绿 |
| AC-023-05 | attrition-v1 逐层/逐遭遇原始计数、均值与排序准确 | 同上 | Godot overlay + simulator tests | done | RED：缺少聚合 helper；GREEN：手工节点聚合、运行时 opt-in 捕获和 sample path 快照全过；评审修复正 HP timeout 误计 death；未知/默认 diagnostics 保持 byte identity；全量自检全绿 |

## 收尾核对

- [x] 每条 AC 有真实 RED→GREEN 记录。
- [x] 默认 before/after 报告 byte-identical。
- [x] 定向和回归测试全绿，无未知 ERROR/SCRIPT ERROR。
- [x] Stage 1 与独立强模型 Stage 2 无阻断。

## 最小实现收敛

- 保留显式的 layer/encounter 两种输出 schema，因为字段集合不同且均为 PRD 契约；未新增依赖或递归 merge 抽象。
- 复用已有 `_rounded_rate`、稳定 `sort_custom` 和 `BalanceSimulator` 的运行时状态，不改变默认路径或生产数据。
- 保留 overlay fail-closed 校验、CLI 拒绝退出和默认报告回归保护；无 `trellis-minimal:` 简化注释。
