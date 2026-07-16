# Delivery Batch 013: 战斗奖励事务存档

## 目标

让 PC 战斗胜利奖励页成为可安全退出和继续的恢复点，同时保持奖励、经济和真人遥测幂等。

## 验收标准

- `AC-013-01`：战斗胜利奖励页允许保存；战败和完整通关仍禁止保存。
- `AC-013-02`：v5 跑团存档记录 schema、跑团/章节/节点/遭遇归属、奖励前金币基线、金币显示、精确卡牌/遗物/药水 ID 及三类完成标记。
- `AC-013-03`：读取后恢复同一批奖励选项和处理状态，不重复增加金币、已领取内容、胜场、奖励曝光或节点开始计数。
- `AC-013-04`：只允许把结构完整的奖励事务恢复到相同跑团、章节、战斗节点与遭遇；未知 ID、错节点或损坏事务会回滚已入账战利品金币，并从迁移写回中清除。
- `AC-013-05`：v4 及更早存档安全迁移到 v5；载入另一局时不得把旧战斗 HP 写入新存档。
- `AC-013-06`：PC `1280x720` 奖励页新增保存命令后无换行、裁切、重叠或系统滚动条。
- `AC-013-07`：本批不得修改角色、卡牌、怪物、成长、挑战或经济数值。

## 文件清单

- `scripts/core/SaveManager.gd`
- `scripts/main/Main.gd`
- `tests/test_save_manager.gd`
- `tests/test_playtest_run_integration.gd`
- `assets/art/generated/ui/icons/control_save_run.svg`
- `assets/art/generated/ui/icons/control_save_run.svg.import`
- `project.godot`
- `export_presets.cfg`
- `packaging/PLAYTEST_README_ZH.txt`
- `docs/06_IMPLEMENTATION_LOG.md`
- `docs/07_CURRENT_STATE_AND_NEXT_STEPS.md`
- `docs/02_TECHNICAL_ARCHITECTURE.md`
- `.trellis/tasks/delivery-batch-013-reward-transaction-save.*`

## 行为约束

- 运行状态仍是唯一事实源；存档只记录可重建的稳定 ID 和事务标记，不序列化 Godot 节点或完整 Resource。
- 恢复前必须验证当前地图节点和遭遇所有权，不能只检查 `active=true`。
- 迁移写回必须保留合法奖励事务并清除非法事务。
- 终局存档归属、Profile 奖励凭证和匿名遥测隐私 schema 不得回退。
