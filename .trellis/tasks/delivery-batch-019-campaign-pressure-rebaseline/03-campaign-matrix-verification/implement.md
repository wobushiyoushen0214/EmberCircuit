# Implementation Plan: 019-03

## 结构健康度预检

| 目标 | 当前规模 | 阈值 | 微重构 |
| --- | --- | --- | --- |
| `tests/test_campaign_matrix_verification.gd` | 新文件 | 400 | 保持单一验证入口 |
| `docs/09_NUMERICAL_TREE_AND_BALANCE.md` | 253 行 | 400 | 否 |

## 有序步骤

1. RED：新建 verification test，先断言 selected 128、256 report schema、sync tool 拒绝非 256/缺格报告和 observed source，看到缺失/不一致失败。
2. GREEN：运行 128 report，确认方向门和真人 cohort schema。
3. GREEN：实现最小 `sync_campaign_matrix.gd`，运行 256 report 后由工具校验完整轴并原子生成同步 tree；禁止手工填写。
4. 更新 docs、delivery state/run log，保留报告路径和 hash。
5. 运行完整 Godot regression、numerical auditor、UI/performance smoke；任何失败转 debug skill。
6. 执行最小实现收敛、Stage 1/2 review，未通过不得标记完成。

## 修改边界

- 允许：本 PRD 文件清单；Godot 首次导入为新 `.gd` 生成的 `.uid` sidecar 视为该源文件的机械产物。
- 禁止：除真实报告同步外修改 gameplay config；禁止删除 tests 或弱化目标。

## 失败恢复

- 报告与 rows 不一致：重新从工具输出生成，不手改 rows。
- 真人 schema 不足：保持 UNTESTED，不能把 AI 结果复制过去。
- 全量回归失败：调用 debug skill，最多 3 轮后升级。
