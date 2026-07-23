# TDD 进度：024-01

| AC ID | 期望可观察结果 | 测试文件 | 测试命令 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- |
| AC-024-01 | 新 allowlist 合法值通过，非法 dataset/path/value 固定拒绝 | `tests/test_character_balance_candidate_overlay.gd` | Godot 单测 | pending | 未开始 |
| AC-024-02 | id selector 唯一命中，缺失/重复拒绝且 source/其他实体不变 | `tests/test_character_balance_candidate_overlay.gd` | Godot 单测 | pending | 未开始 |
| AC-024-03 | simulator 五数据集成功/拒绝后完全恢复 | `tests/test_balance_candidate_runtime.gd` | Godot 单测 | pending | 未开始 |
| AC-024-04 | compact evidence 合法 4/12 case 字段与排序精确 | `tests/test_balance_evidence_digest.gd` | Godot 单测 | pending | 未开始 |
| AC-024-05 | malformed/repeat/I/O 固定错误且 fail-closed | `tests/test_balance_evidence_digest.gd` | Godot 单测 | pending | 未开始 |
| AC-024-06 | editor、023 overlay/gate/rebaseline、simulator 全绿 | PRD 自检全集 | 多命令 | pending | 未开始 |

## 收尾核对

- [ ] 所有 AC 为 done。
- [ ] 自检全集最后一次全绿。
- [ ] 最小实现收敛完成。
- [ ] design 挂载点全部接线。
- [ ] 未 commit；等待双阶段评审。

## 最小实现收敛

- 删除项：尚未执行。
- 复用项：尚未执行。
- 保留项：尚未执行。
- `trellis-minimal:` 注释：尚未执行。
