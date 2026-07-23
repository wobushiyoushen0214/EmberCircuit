# TDD 进度：024-02

| AC ID | 期望可观察结果 | 测试 | 状态 |
| --- | --- | --- | --- |
| AC-024-07 | 十份 exact fixture/catalog 与唯一 C1 composition | `test_character_parity_rebaseline.gd` | done（RED：catalog/fixture 缺失 11 项；GREEN：exact、拒绝、overlay、C1 compose 全绿） |
| AC-024-08 | 4 格 64 role raw band 与固定错误 | `test_character_parity_candidate_gate.gd` | done（RED：gate 缺失；GREEN：四档上下界、scope、identity、matrix、错误顺序全绿） |
| AC-024-09 | A/E/Y first-pass 与三种耗尽立即停机 | `test_character_parity_rebaseline.gd` | done（RED：runner 缺失；GREEN：A/E/Y 首个通过及三种耗尽立即停机全绿） |
| AC-024-10 | 唯一组合 64 target/cell/gap/单调/row identity | 两个新测试 | done（RED：combined API/C1 编排缺失；GREEN：聚合/单格/5胜差/单调/row identity 与唯一组合全绿） |
| AC-024-11 | 组合 128/repeat/shared hard gate | integration + 023 gate | done（RED：hard gate 参数/调用缺失；GREEN：primary/repeat、byte identity、共享 hard 与无 256 全绿） |
| AC-024-12 | 每份实际 report 有 versioned compact digest/verdict | integration | done（RED：digest/verdict 接线缺失；GREEN：逐阶段摘要、128 repeat 绑定、写失败停机全绿） |
| AC-024-13 | 32-seed preflight 与正式 runs ≤6912 | integration | done（RED：预算/preflight API 缺失；GREEN：6912/6913 边界与 960 graph 全绿） |
| AC-024-14 | 真实 selected/paused 状态同步 tree/docs 且生产冻结 | runner + matrix | done（RED：024 tree/docs/evidence 元数据缺失，7 项预期断言失败；GREEN：真实 Arc 耗尽 verdict、4 份 digest、tree/docs/SHA 同步且生产/正式 matrix 冻结） |
| AC-024-15 | 定向/回归/freeze/双评审无阻断 | PRD 自检全集 | done（editor、11 项测试、10 个冻结 SHA、verdict/digest/tree SHA 与两个 diff check 全绿；Review Round 4 为 C0/M0/m0） |

## 真实运行证据

- 正式 runs：`1,536`；B0 `768` + A1-A3 `768`。会话中断的局部运行已由完整重跑覆盖，不重复计数。
- selected steps：空；最终状态 `paused_no_arc_candidate_passed`。A1=`24/13/6/6`、A2=`22/16/7/6`、A3=`25/23/9/8`，均未同时进入四档原始胜局范围。
- verdict SHA：`f70b155537c31573ef53c7e6afcfb49bc998497626fc5343760663624a10a413`；B0/A1/A2/A3 digest SHA 依次为 `28d3f746...5482`、`db77f340...a3f1`、`0da4f7eb...f813`、`a6820edd...e3a6`。
- preflight：10 fixtures × 3 chapters × 32 seeds = 960 graph 全部有效。
- 生产与 matrix freeze：player/relic/map/level/economy 五份 SHA 与任务起点一致；正式 matrix 仍为 current-greedy `3×4×256`，matrix contract 全绿。
- AC-024-07 回归：editor parse、024-01 角色 overlay、023 layered rebaseline 与 `git diff --check` 均退出 0；仅有已知 macOS system CA 提示。
- AC-024-08 回归：editor parse、AC-024-07 exact catalog 与共享 023 hard gate 均退出 0。
- AC-024-09 回归：editor parse、角色 raw gate 与 `git diff --check` 均退出 0；scripted 分支未运行正式样本。
- AC-024-10 回归：editor parse、两项 024 定向测试与共享 023 hard gate 均退出 0；64 组合边界以原始整数校验。
- AC-024-11 回归：editor parse、024 combined gate 与 023 shared hard gate 均退出 0；scripted 128 PASS/FAIL/repeat mismatch 分支全绿。
- AC-024-12 回归：editor parse、024-01 digest、024 gate/runner 均退出 0；verdict 固定只写一次，I/O 失败返回 `evidence_write_failed`。
- AC-024-13 回归：10 fixtures × 3 chapters × 32 seeds 共 960 graph 全部有效；worst-case scripted funnel 精确 6,912 runs，map smoke/editor parse 全绿。
- AC-024-14 回归：完整 runner 退出 0 并写唯一 verdict；numerical tree/docs/evidence 同步后 matrix contract 退出 0，仅更新新增 provenance 后的整树 SHA 断言。

## 最小实现收敛

- 删除项：无可安全删除的实现；catalog exact 校验、64 raw gate、runner 停机/预算/I/O 分支均直接对应 AC 与 fail-closed 边界。
- 复用项：128 原样复用 `LayeredPressureCandidateGate`，摘要原样复用 `BalanceEvidenceDigest`，模拟、overlay、地图图结构与 Godot JSON/SHA API 均复用现有实现；未增加依赖。
- 结构：catalog 214 行、gate 379 行、runner 377 行、rebaseline test 399 行，编排与计算分文件且新文件均不超过 400 行目标；未扩张既有 023 runner 或 4,399 行 simulator。
- 保留校验：exact fixture/identity、原始 case rows、角色 scope、重复/缺格、预算、repeat byte identity、证据 I/O 与生产冻结均不可为简化而删除。
- `trellis-minimal:`：无；没有保留带已知上限的未来占位或额外扩展点。
- AC-024-15 自检：editor、11 个定向/回归测试、冻结 SHA 与 `git diff --check` 全部退出 0；正式 runner 使用 AC-024-14 刚完成的唯一完整运行，不重复生成正式样本。
- Review Round 1：Stage 1 通过；独立强模型 Stage 2 发现 Critical 2 / Major 3 / Minor 0，打回实现修复真实写盘错误、精确行比较、128 错误证据、losses 原值和 tree/verdict/docs 绑定。
- Review 修复 RED→GREEN：近整数浮点与 losses 原值各出现 1 条 gate 红灯后转绿；真实 post-open 写错误 seam 缺失红灯后转绿；128 primary/repeat 的空报告/保存失败共 4 条红灯后统一固定错误码并记录 step；matrix binding helper 缺失红灯后实现 verdict SHA/status/selected/runs/flags/digest/tree/docs 强绑定及漂移拒绝。
- Review 修复收敛：删除 gate 中不符合精确比较的 `_canonical`；复用单一 `_report_stage_failure`；rebaseline test 收敛到 399 行，未新增依赖或未来抽象。
- Review 修复后回归：editor、11 个定向/回归测试、10 份冻结生产 SHA 与 `git diff --check` 再次全部退出 0；正式 runner/evidence 未重跑或改写。Round 2 Stage 1 重新核对无阻断。
- Review Round 2 修复 AC-024-07：新增 `5.000001` 候选值拒绝断言先出现 1 条红灯；catalog 与测试 canonical 改为只归一严格整数浮点后转绿，不再接受近整数漂移。
- Review Round 2 修复 AC-024-12：repeat mismatch 缺少摘要断言先出现 2 条红灯；runner 现为两份不相同的 128 full report 分别写 standalone digest，并在 verdict step 绑定双路径/SHA 后转绿；byte-identical 分支仍只写一份绑定 repeat SHA 的 digest。
- Review Round 2 修复后回归：editor、11 个定向/回归测试、10 份冻结生产 SHA、verdict/digest/tree SHA 与 `git diff --check` 全绿；正式 runner/evidence 未重跑或改写。
- Review Round 3：Stage 1 通过；独立强模型 Stage 2 发现 Critical 1 / Major 0 / Minor 0，指出 repeat 生成/保存失败时已保存 primary 128 缺少 standalone digest 与 verdict 绑定。
- Review Round 3 修复 AC-024-12：四个 128 生成/保存失败分支先增加 primary digest 断言，其中 repeat 生成与 repeat 保存失败出现 4 条红灯；runner 随后在 repeat 阶段失败前为已保存 primary 写 standalone digest，并把 full path/SHA 与 digest path/SHA 绑定进 verdict step 后全部转绿。primary digest 写失败仍统一转为 `evidence_write_failed` 并 fail-closed。
- Review Round 3 修复后定向回归：`test_character_parity_rebaseline.gd` 退出 0；测试文件机械收敛为 399 行，未削弱断言。
- Review Round 3 修复后完整回归：editor、11 个定向/回归测试、10 个冻结生产 SHA、verdict/digest/tree SHA、`git diff --check` 与 `git diff --cached --check` 全部退出 0；正式 runner/evidence 未重跑或改写。
- Review Round 4：独立只读强模型复审 session `019f8d5a-da7f-77c1-9c34-5e0e33bfa944`；Stage 1 通过，Stage 2 为 Critical 0 / Major 0 / Minor 0，裁决 PASS。复审明确确认 repeat 生成/保存失败的 primary digest/verdict 绑定及 digest 写失败 fail-closed。

## 收尾核对

- [x] 全部已执行 AC 有 RED→GREEN 证据。
- [x] 样本预算未超限，未重跑 023 ladder。
- [x] 没有“最接近”或额外候选。
- [x] 自检全集与双阶段评审通过。
- [x] 评审完成前实现体未 commit。
