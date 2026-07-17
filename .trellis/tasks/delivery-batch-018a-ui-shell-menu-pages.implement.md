# Implementation Plan: Batch 018A

## 文件计划

| 步骤 | 文件 | 操作 | 精确位置 | 验证 |
| --- | --- | --- | --- | --- |
| 0 | `scripts/main/Main.gd` | characterization | 保留旧 probe/node name 快照 | `test_run_flow.gd` |
| 1 | `data/config/ui_theme_tokens.json`, `ui_motion_profiles.json` | new | token/schema | foundation test |
| 2 | `scripts/ui/ForgeTheme.gd`, `ForgeMotion.gd` | new | typed helpers | foundation test |
| 3 | `scripts/ui/AppShell.gd`, `scripts/ui/components/*.gd` | new | host/components | foundation test |
| 4 | `scripts/ui/pages/WelcomePage.gd` | new | configure/signals/render | welcome test |
| 5 | `scripts/ui/pages/CharacterSelectPage.gd` | new | configure/signals/render | character test |
| 6 | `scripts/main/Main.gd` | modify | `_build_layout`, `_refresh_welcome`, `_refresh_character_select` | run_flow/bounds |
| 7 | tests/docs | modify | regression and log | full strict suite |

## 结构健康度预检

`Main.gd` 当前约 15,500 行，命中胖文件阈值。只允许把欢迎/角色“视觉树构造”搬入 page 类，保留状态路由和 callbacks；不改签名、不改变存档/战斗行为。

## 失败恢复

- 新 API 缺失：回到 foundation test，先修类名/签名。
- 页面状态回归：恢复旧 `_refresh_*` adapter，保持 probe，再分步迁移。
- bounds 回归：只调整 token spacing/minimum size，不改业务状态或滚动语义。
