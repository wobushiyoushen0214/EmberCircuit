# TDD 进度：024-01

| AC ID | 期望可观察结果 | 测试文件 | 测试命令 | 状态 | 备注 |
| --- | --- | --- | --- | --- | --- |
| AC-024-01 | 新 allowlist 合法值通过，非法 dataset/path/value 固定拒绝 | `tests/test_character_balance_candidate_overlay.gd` | Godot 单测 | done | RED：六条合法 path 原先均返回 `dataset_forbidden`。GREEN：扩展五数据集、六条精确 allowlist 与值校验；调用方缺失 dataset 仍 fail-closed。定向测试、023 overlay/gate/rebaseline、simulator 和 editor parse 全绿。 |
| AC-024-02 | id selector 唯一命中，缺失/重复拒绝且 source/其他实体不变 | `tests/test_character_balance_candidate_overlay.gd` | Godot 单测 | done | RED：selector 不存在，generic writer 破坏数组且缺失/重复 id 未拒绝。GREEN：独立 selector 按 id 唯一命中五个目标实体，0/多命中返回固定错误；source、其他实体与旧三数据集保持不变。定向与相关回归全绿。 |
| AC-024-03 | simulator 五数据集成功/拒绝后完全恢复 | `tests/test_balance_candidate_runtime.gd` | Godot 单测 | done | RED：simulator 仅传旧三数据集，合法角色候选被拒绝。GREEN：apply/assign/restore 薄接线扩展到 player/relics；成功、拒绝、overlay→default 与 reject→default 均保持五数据集及默认报告 identity。editor 和相关回归全绿。 |
| AC-024-04 | compact evidence 合法 4/12 case 字段与排序精确 | `tests/test_balance_evidence_digest.gd` | Godot 单测 | done | RED：digest helper 不存在。GREEN：schema v1 builder 精确保留 4/12 case 原始计数、首章、失败集中、金币/牌组、候选身份、source SHA 与严格 gate 字段，并按角色/挑战排序；相关回归全绿。 |
| AC-024-05 | malformed/repeat/I/O 固定错误且 fail-closed | `tests/test_balance_evidence_digest.gd` | Godot 单测 | done | Review Round 1 RED：report/path 可错配且 gate 可伪造矛盾 verdict。GREEN：source 必须为合法 JSON 并与 report 语义绑定；pass 必须等于 eligible 且无 failures，failure codes 非空唯一。原有错误顺序/repeat/I/O 全部保持绿。 |
| AC-024-06 | editor、023 overlay/gate/rebaseline、simulator 全绿 | PRD 自检全集 | 多命令 | done | Review Round 1 修复后再次按 PRD 原样顺序执行 editor、三项 024 测试、023 overlay/gate/rebaseline、simulator 与 diff-check，九项退出码均为 0；仅有已知 macOS system CA 提示，无 SCRIPT/Parse Error。 |

## 收尾核对

- [x] 所有 AC 为 done。
- [x] Review Round 1 修复后自检全集再次全绿。
- [x] 最小实现收敛完成。
- [x] design 挂载点全部接线：overlay→selector、simulator 五数据集 apply/assign/restore、digest build/write API。
- [x] 未 commit；等待 Review Round 2。

## 最小实现收敛

- 删除项：未发现只为未来扩展存在的工厂、配置、接口或依赖；selector/digest 均为 PRD 明确要求的独立计算层，simulator 只保留 10 行生命周期薄接线。
- 复用项：复用 Godot `Dictionary.duplicate(true)`、`FileAccess`、`HashingContext`、`JSON` 与现有 overlay/runner 契约；未新增第三方依赖、autoload 或 plugin。
- 保留项：保留精确 allowlist/value 校验、唯一 id/重复 id fail-closed、五数据集恢复、身份/矩阵/raw rows/gate/repeat/I/O 校验及既有 023 回归保护；这些属于 trust boundary，不能为缩短代码删除。
- `trellis-minimal:` 注释：无；当前实现没有已知需未来升级的有界简化。
