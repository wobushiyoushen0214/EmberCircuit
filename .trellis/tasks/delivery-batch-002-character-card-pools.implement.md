# 实现记录

- `data/cards/cards.json` 新增 9 张角色专属卡牌和升级数据。
- `data/config/art_assets.json` 新增 9 个正式卡牌资源槽。
- `scripts/combat/CombatState.gd` 的 `can_play_card` 统一校验 `lose_momentum` 资源成本。
- `tests/test_combat_core.gd` 覆盖势能门槛、一次性电池和自伤防御牌。
- `tests/test_run_flow.gd` 覆盖三角色奖励池隔离和新卡出现。
