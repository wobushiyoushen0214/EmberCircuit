# Delivery Batch 015 TDD 进度

| AC | 状态 | 测试 | 备注 |
| --- | --- | --- | --- |
| AC-001 cohort 留存与 legacy 隔离 | done | `test_playtest_evidence_gate.gd`、`test_playtest_telemetry.gd` | RED: v1/64局/跨格丢失；GREEN: schema v2、legacy 隔离、12格×35与96 abandoned |
| AC-002 分 cohort 聚合与多报告合并 | done | `test_playtest_evidence_gate.gd` | RED: 双版本混组/无合并器；GREEN: 独立胜率、12/30 门、同 run 去重、冲突拒绝 |
| AC-003 游戏内覆盖摘要与说明 | done | `test_playtest_run_integration.gd` | RED: 导出后无 12/30 覆盖摘要；GREEN: 传入 3×4 期望矩阵并显示方向格、硬门格和尚缺局数，试玩说明补齐 cohort/合并命令 |
| AC-004 单 cohort 兼容输出 | done | `test_playtest_telemetry.gd`、`test_playtest_evidence_gate.gd` | 旧顶层 summary/dimensions/card/failure/runs 均只映射最新合格 primary cohort，不再跨版本计算 lift |
| AC-005 20 套严格回归 | done | 全部 `tests/test_*.gd` | 用户确认扩展 Manifest 后，仅同步 `human_playtest_targets.report_schema_version` 为 2；20/20 逐套通过且严格扫描无 `SCRIPT ERROR` / `ERROR:` |

## 最小实现收敛

- 计算逻辑统一放入一个纯 `RefCounted`，不向超大 `Main.gd` 或 `PlaytestTelemetry.gd` 继续堆算法。
- 复用现有 JSON、FileAccess、SHA-256 和匿名 run schema，不引入依赖。
- 删除 `PlaytestTelemetry.gd` 已由证据门替代的六个旧聚合 helper；拆开证据门中的紧凑分号语句，保留现有输入校验、冲突拒绝和隐私边界。
- 新增终局优先去重、eligible primary、12 格合并继承、cohort 重算、损坏报告拒绝和单卡 20×2 样本就绪回归；没有新增抽象层或第三方依赖。
- CLI 冒烟验证：相同报告退出 0 并生成可解析 JSON；同 `run_id` 内容冲突退出 1 且不产出合并分析。
- Stage 2 Round 1 打回后补齐同 cohort fixture 隔离、eligible primary 时间排序、非终局输入拒绝、40→41、4→5 cohort 与 fixture 不争用真人配额；每项均先出现稳定红灯再最小修复变绿。
