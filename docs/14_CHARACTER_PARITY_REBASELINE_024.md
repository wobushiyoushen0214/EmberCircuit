# Batch 024 有限角色平衡重标定

## 裁决

2026-07-23 完整执行固定 `B0 + A1-A3/E1-E3/Y1-Y3` 漏斗。B0 完成后，Arc 的 A1、A2、A3 均未同时进入四个挑战档的原始胜局范围；runner 按契约立即停止，最终状态为 `paused_no_arc_candidate_passed`，没有 selected step 或 selected candidate。

- Verdict：`.trellis/evidence/batch-024/character-parity-verdict.json`
- Verdict SHA-256：`f70b155537c31573ef53c7e6afcfb49bc998497626fc5343760663624a10a413`
- Preflight：`ok=true`，固定十候选顺序；10 fixtures × 3 章节 × 32 seeds，共 960 张地图图结构通过。
- 正式样本：B0 `3×4×64=768` 局，加 A1-A3 `3×1×4×64=768` 局，共 `1,536` 局。
- 先前因会话中断留下的局部 B0/A1/A2 文件已由本次完整运行覆盖，不作为额外正式样本。
- 未运行 E1-E3、Y1-Y3、组合 C1、128 primary/repeat 或 256；未生成试玩包。

## Arc 原始结果

单角色 64 门要求 C0 `18-21`、C1 `11-16`、C2 `8-13`、C3 `6-9` 胜。下表顺序均为 C0/C1/C2/C3，每格 64 局。

| Step | 原始胜局 | Failure codes | 结论 |
| --- | --- | --- | --- |
| A1 | `24 / 13 / 6 / 6` | `role_win_band_c0`、`role_win_band_c2` | C0 偏高且 C2 偏低，拒绝 |
| A2 | `22 / 16 / 7 / 6` | `role_win_band_c0`、`role_win_band_c2` | C0 偏高且 C2 偏低，拒绝 |
| A3 | `25 / 23 / 9 / 8` | `role_win_band_c0`、`role_win_band_c1` | C0、C1 偏高，拒绝 |

A2 最接近边界，但仍有两个挑战档越界；本批禁止按距离选“最接近”，因此不能晋级。A3 改善了高挑战胜局，却同步把低挑战推到上界之外，也不能选用。

## 版本化证据

| Step | Full report SHA-256 | Compact digest SHA-256 |
| --- | --- | --- |
| B0 | `af199c189e4208dce26776f9e95e749950655279cedd90f071ff2f7f6463ba4d` | `28d3f74627e324fa92c0233fb968bdf2c344fe4efc284e23bfb137c416aa5482` |
| A1 | `d54e72561b35fbba300f9af6675e56d856885351f5c8fcef219bdba4a7c8b13f` | `db77f3403922ec62c6d84d50562070f5b71cd57f343448bc364d0a3006a4a3f1` |
| A2 | `6cba1ca0596fdb89394a90a35cb51f92da24599d6a21bce6cc63943fdfe152bc` | `0da4f7ebb01ead442ca24dd34a9d0a3b83a25d66880e153c8e4b9f3a8d06f813` |
| A3 | `3e7c876d0e2d9ed3bd9163e0bceb04baf318619a8f75f558577f9ac6f93a7261` | `a6820edd5137bb3c8b4546461e82052b45c9a13337e5622e95edefcd61c4e3a6` |

Compact digests 位于 `.trellis/evidence/batch-024/`，保存候选身份、原始 case rows、gate verdict、full report 路径与 SHA；未运行步骤没有伪造摘要。

## 生产冻结

本轮没有合法 128 candidate，因此不把 B0 或任何 Arc 候选写入生产：

- `player.json` SHA-256：`f803ba56a07823a4ef6d15c932a666cdb0a0a762f4851e96e01e4546cb6c1d09`
- `relics.json` SHA-256：`32dacd91caa59d32637ccec0610f7c2b94344c46a5be61f11cac85bf24969ca0`
- `map_generation.json` SHA-256：`9688ff522b29a3c3dbc5bb1d54fe0255445a1643921034b9d17636f34f8a6090`
- `level_tree.json` SHA-256：`3a53497ab7d4014a838d55acb927a3296b9e2037c4e4a67b7eb7861e80aec0dc`
- `economy.json` SHA-256：`0d2c917e51fcc57d612e34fe71de5690b9b66f4ccfcf36da38a7710db3603ff6`
- 正式 `campaign_matrix` 继续使用 `current-greedy`、`3×4×256`、80 turns 和 paired seeds；12 行及 expected exceptions 语义不变。

卡牌、敌人、遭遇、挑战与 `CombatState.gd` 也保持任务起点 SHA。`campaign_rebaseline_024.production_applied`、`matrix_updated`、`playtest_package_eligible` 均为 `false`。

## 后续边界

024-03 必须标记为 `canceled_no_selected_128_candidate`，不得运行 256 或构建新数值试玩包。若继续数值迭代，需要以本轮 Arc 的分档错位为新一批候选规划输入；不能在 024 内发明 A4、降低 gate 或把 A2 近似通过。
