# 019-02 双阶段评审报告

## Review Round 1

### 被评审对象

- 任务：`.trellis/tasks/delivery-batch-019-campaign-pressure-rebaseline/02-act2-act3-pressure-and-reward-rebaseline`
- diff 范围：`0834853..worktree`，含 019-01 依赖实现、019-02 候选证据与受控暂停收尾
- Stage 2 评审模型：GPT-5.1 强模型

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| AC 测试覆盖 | 通过（stop path） | - | `tests/test_act2_act3_rebaseline.gd`、`tests/test_numerical_balance_matrix.gd` | 覆盖候选顺序、失败证据、生产回滚、目标冻结和 256 rows 精确冻结；AC-019-09 因无候选通过按 PRD blocked，不伪造 GREEN |
| 文件清单符合 | 通过 | - | 019-02 PRD File Manifest | 产品改动仅落在 test/tree/docs；失败的 economy/enemy 候选已完整回滚。UID sidecar 为 Godot editor 生成的既有项目约定；delivery state/log、父任务和 019-03 进度属于受控暂停编排收尾 |
| 禁止事项符合 | 通过 | - | 全 diff | 未改 target、challenge、第一章、起始资源、卡牌、地图、CombatState、Main、SaveManager、真人 cohort 或正式 256 observed |
| 决策表符合 | 通过 | - | `numerical_tree.json.campaign_rebaseline` | R1→R2→R2-A 顺序执行；R2-A 静态 hard warning 后停止，R2-B 因继承失败不重复运行，未发明 R3 |
| 挂载点接线 | 通过 | - | test/tree/docs | 奖励与敌人候选未通过后均撤回；暂停状态、证据、回归测试和文档已接线 |
| 范围符合 | 通过 | - | 全 diff | 019-03 因缺少 selected step 取消；未新增 sync 工具或运行 256 正式同步 |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| 编排-计算分离 | 通过 | - | `BalanceSimulator.gd`、任务进度/报告 | 快照生命周期、case 聚合与任务候选编排分离；没有把候选阶梯写进运行时模拟器 |
| 结构健康度 | 记录 | minor | `scripts/tools/BalanceSimulator.gd` | 文件继续偏胖；本批按 PRD 复用唯一模拟器，后续独立维护批次可抽离纯 attribution calculator |
| 简化与复用 | 通过 | - | `_record_campaign_failure()`、现有 DataLoader/targets | 没有新依赖或平行模拟器；未通过数值全部删除，只保留机器可读证据与回归保护 |
| 正确性（边界/错误/回归） | 通过 | - | attribution helpers、两个 rebaseline tests | 失败分母、0 losses、未到达章节、64/128 eligibility、稳定 tie-break、正式 rows 冻结均有保护；29/29 Godot tests 全绿 |
| 规范符合 | 通过 | - | 任务 PRD/design/check | 无 `.trellis/spec`；GDScript、JSON、测试与既有项目风格一致 |

### 验证证据

- 全量 `tests/test_*.gd`：29/29 通过。
- editor import：退出码 0。
- R1 12×128：SHA-256 `81011187edea19ff3071425c4ab1db7879bb59df0dcde18d8a3f75a8f5c1fdb4`。
- R2 12×128：SHA-256 `a1b1ee36e16d4af7844b8ccc9d900d6169dfef03bd29d8ef3936798aa9da45aa`。
- R2-A 静态审计：唯一新增 hard warning 为 `null_workshop:encounter_hp_low`（86 < 88）；回滚后 `test_numerical_tree_auditor.gd` 通过。
- `git diff --exit-code -- data/config/economy.json data/enemies/enemies.json`：通过，生产候选值无残留。

### 问题汇总（按严重度）

- **Critical（阻断代码合并）**：无。
- **Major（应修）**：无。
- **Minor（记录后续）**：`BalanceSimulator.gd` 偏胖，后续可独立抽离 attribution calculator。
- **产品门阻塞（不是评审缺陷）**：冻结候选无一通过，019-02 不得标记完成，019-03 不得启动。

### 裁决

- [x] Stage 1 PASS，Stage 2 PASS（C0/M0/m1）；允许合并归因能力、测试和受控暂停证据。
- [x] 保持 019-02 为 blocked/paused，要求下一轮重新规划候选阶梯。
- [ ] 将 019-02 或 019-03 标记为 delivered。

结论：代码质量门通过，但产品方向门未通过。合并后暂停，禁止在当前批次继续发明 R3。
