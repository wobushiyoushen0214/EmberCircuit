# Batch 023 分层压力重标定

## 裁决

2026-07-23 在完成 malformed attribution、原始计数、严格身份类型、runner preflight、I/O 故障传播和可执行分支测试修复后，重新完整执行固定 P1-P5 的 `competent-player-v3` 配对样本阶梯。五个候选均通过 64 方向门，但均未通过 128 hard gate；最终状态为 `paused_no_layered_candidate_passed`，`selected_step` 为空。

- Verdict：`/tmp/ember023-layered-ladder-verdict.json`
- Verdict SHA-256：`8b3ef30c44e1151f066447580f558a1af438edca0d845896840fbcc3c2266ff1`
- Runner preflight：`ok=true`，候选顺序固定为 P1-P5，五候选均通过三章 x 32 seed 完整路径、预算、压力、恢复和分支验证。
- 正式 ladder 样本：baseline 与 P1-P5 的 64 方向样本 `4,608` 局，加五候选 128 主/复跑 `15,360` 局，共 `19,968` 局完整 AI 跑团。
- 修复前后两次完整 ladder 累计执行 `39,936` 局；修复前的 `19,968` 局已被最终重跑覆盖，不作为独立正式证据叠加。
- 调试探针、失败重试和历史批次不计入上述裁决样本，禁止把重复运行抬高为独立证据。
- P1-P5 128 主报告与各自 repeat 均 byte-identical。
- 未生成任何 256 artifact。

## 候选结果

目标四档均值依次为 C0 `27%-33%`、C1 `17%-26%`、C2 `12%-23%`、C3 `8%-15%`。

| Step | C0 / C1 / C2 / C3 | 128 SHA-256 | Hard gate |
| --- | --- | --- | --- |
| P1 | `18.23% / 10.68% / 5.73% / 4.95%` | `0c7387a6aaa85cf8ac3d239188f0eccebc3452d40f5785f70a564481ac37b52b` | 平均、单格、角色差、失败集中、金币、牌组失败 |
| P2 | `19.27% / 14.06% / 5.73% / 3.65%` | `875ee6ea8429d7a09cf80c009dbfef773485656125161285edeb9f6ab5c549b0` | 平均、单格、角色差、失败集中、金币、牌组失败 |
| P3 | `19.27% / 14.06% / 5.73% / 3.65%` | `f4c59ae3a0ab8172c6493555301963e370ab412a71763233e4ebf40872340aa1` | 平均、单格、角色差、失败集中、金币、牌组失败 |
| P4 | `23.44% / 16.41% / 8.33% / 4.69%` | `7c334e0559a37fd9380302882078120a486a2331e6d78534cf095d7fc75e9eae` | 平均、单格、角色差、失败集中、金币、牌组失败 |
| P5 | `21.35% / 13.80% / 8.07% / 4.95%` | `d9138cd3a2793fe599d18461334c11e2dbc6541813a3e167a79346fd252641d4` | 平均、单格、角色差、金币、牌组失败 |

P4 是本阶梯中通关率最高的候选，但 C0-C3 仍全部低于目标下界，同时角色差、最终金币和最终牌组不合格，因此不能按“最接近”晋级。P5 的稀有度调整没有改善整体结果。

## 生产冻结

无候选通过时，生产值保持 Batch 023 起点：

- `map_generation.json` 不写 `chapter_one.encounter_layer_bands`；SHA-256 `9688ff522b29a3c3dbc5bb1d54fe0255445a1643921034b9d17636f34f8a6090`。
- `level_tree.json` 保持 pressure `4`、三章 campfire `[1,2]`；SHA-256 `3a53497ab7d4014a838d55acb927a3296b9e2037c4e4a67b7eb7861e80aec0dc`。
- `economy.json` 保持 heal `25`、rarity `65/28/7`；SHA-256 `0d2c917e51fcc57d612e34fe71de5690b9b66f4ccfcf36da38a7710db3603ff6`。
- 正式 campaign matrix 继续使用 `current-greedy`、`3x4x256`、80 turns 和 paired seeds；rows 与 expected exceptions 不变。

`data/config/numerical_tree.json` 的 `campaign_rebaseline_023` 记录完整裁决，`production_applied=false`、`matrix_updated=false`、`playtest_package_eligible=false`。

## 后续边界

023-03 的 256 正式矩阵任务取消为 `canceled_no_selected_128_candidate`，不得生成 256 artifact 或构建新数值试玩包。下一次迭代必须基于本轮原始 failure codes 重新规划候选边界；禁止降低 gate、手改报告、把 P4 近似通过或在本批发明 P6。
