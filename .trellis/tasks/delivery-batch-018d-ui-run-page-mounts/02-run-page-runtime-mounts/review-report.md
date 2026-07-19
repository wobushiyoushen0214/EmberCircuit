# 双阶段评审报告：018D-02

## Review Round 1

### 被评审对象

- 任务：`02-run-page-runtime-mounts`
- diff 范围：`ae87384..staged worktree`，排除已在 018D-01 Round 1 通过的 page contract 改动
- Stage 2 评审模型：GPT-5 Codex（强模型）；本轮 Stage 1 命中 critical，Stage 2 暂停

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| AC 测试覆盖 | 不符 | critical | `tests/test_playtest_run_integration.gd:40-145` | 既有事务恢复测试验证数据状态，但未验证恢复后 active RewardPage、已完成项禁用、未完成项保留及 continue gate；该文件也未产生本任务 diff。 |
| 文件清单符合 | 通过 | - | `Main.gd`、run-flow、visual-bounds、任务产物 | 018D-02 实际改动位于清单内；018D-01 页面文件按前一评审报告单独计。 |
| 禁止事项符合 | 通过 | - | 全 diff | 未修改 data、CombatState、SaveManager schema、telemetry payload、资产或依赖。 |
| 决策表符合 | 不符 | critical | `scripts/main/Main.gd:12193-12208`, `12491-12594` | RewardPage 信号直接连接旧业务回调；未知/过期/重复 card/relic/potion/treasure/mastery/continue 信号没有 Main adapter 二次验证与 `RewardPage: ... id` warning。 |
| 挂载点接线 | 通过 | - | `Main.gd` map/event/campfire/shop/reward refresh | 五页均挂入 AppShell，旧业务回调仍是唯一写入。 |

### Stage 2 · 代码质量

- 本轮未进入：Stage 1 已有 critical，按门禁先打回 TDD。

### 问题汇总

- **Critical（阻断）**：
  - `Main.gd`：为 combat reward、treasure、mastery、continue 增加当前状态 adapter；未知/过期/重复信号必须 warning 并保持状态不变，合法信号才调用原回调。
  - `tests/test_playtest_run_integration.gd` / `tests/test_run_flow.gd`：补 RED，覆盖未知/重复信号不写状态，以及部分领取保存恢复后 RewardPage VM、按钮禁用与 continue gate 一致。
- **Major**：无。
- **Minor**：无。

### 裁决

- [x] 有 critical → 打回 `trellis-implement-tdd-zh`，只修标注项，修后重新评审
- [ ] 仅 major/minor → 放行
- [ ] 全通过 → 推进任务状态

## Review Round 2

### 被评审对象

- 任务：`02-run-page-runtime-mounts`
- diff 范围：Round 1 打回项修复后的 018D-02 实现；018D-03 视觉修改单独评审
- Stage 2 评审模型：GPT-5 Codex（强模型）

### Stage 1 · 规范符合

| 检查项 | 结果 | 严重度 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| AC 测试覆盖 | 通过 | - | `tests/test_run_flow.gd`、`tests/test_playtest_run_integration.gd`、`tests/test_visual_bounds.gd` | AC-018D-05～09 均有真实 mount、边界/未知 id、恢复与 bounds 断言；28/28 全量测试通过。 |
| 文件清单符合 | 通过 | - | 02 PRD File Manifest | Main、运行流程、playtest、bounds、任务产物均在清单内；页面契约改动归属 018D-01。 |
| 禁止事项符合 | 通过 | - | `scripts/main/Main.gd` | 未改 data、CombatState、SaveManager schema、telemetry payload、art manifest 或依赖。 |
| 决策表符合 | 通过 | - | `Main.gd:11550-11620` | Reward/treasure/card/relic/potion/mastery/continue 均经 Main adapter 二次验证；未知/过期请求 warning 且不写状态。 |
| 挂载点接线 | 通过 | - | `Main.gd` refresh/mount helpers | 五页进入唯一 AppShell host；MapView 替换旧实例；原回调和 probes 保留。 |

### Stage 2 · 代码质量

| 检查项 | 结果 | 严重度 | 位置 | 改进建议 |
| --- | --- | --- | --- | --- |
| 编排-计算分离 | 通过 | - | `Main.gd` VM helpers / page scripts | VM 只做展示数据变换，页面不读取业务状态；adapter 保留在 Main。 |
| 结构健康度 | 通过 | minor | `scripts/main/Main.gd` | 文件仍然偏大；018D-03 只删除无调用视觉 helper，未继续搬运业务，后续可独立拆分。 |
| 简化与复用 | 通过 | - | mount helpers | 复用 AppShell、ForgeTheme、既有回调/价格/奖励/存档计算，没有新依赖或重复交易实现。 |
| 正确性（边界/错误/回归） | 通过 | - | run-flow/playtest integration | unknown id、非法 deck index、disabled、部分恢复和 continue gate 均覆盖；预期 warning 已固定。 |
| 规范符合（spec） | 通过 | - | page contracts / task design | typed signals、44px 热区、兼容节点名和 `last_*` probe 符合任务约束。 |

### 问题汇总（按严重度）

- **Critical（阻断）**：无。
- **Major（应修）**：无。
- **Minor（记录后续）**：`Main.gd` 仍偏胖，列入后续结构重构，不阻断本批行为验收。

### 裁决

- [ ] 有 critical → 打回 `trellis-implement-tdd-zh`
- [x] 仅 major/minor → 放行；minor 记录后续
- [ ] 全通过 → 交回编排会话推进任务状态（进入 018D-03）
