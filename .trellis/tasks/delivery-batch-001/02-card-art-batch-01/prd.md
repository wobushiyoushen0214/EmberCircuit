# 高频卡牌正式插画第一批

## 需求 ID

- REQ-008

## 目标

根据任务 01 报告，把三角色起始牌组和高频奖励中仍为 `first_pass` 的卡牌替换为 784x1168 正式位图，并更新资源清单和截图回归。

## 交付控制

- 批次：`delivery-batch-001`
- 模式：L2
- worktree/verifier：必须
- 依赖：`01-art-asset-auditor`
- 复杂度：中

## 文件边界

- 允许：`assets/art/generated/card_*_pc.png`、对应 `.import`、`data/config/art_assets.json`、相关测试和截图库。
- 禁止：卡牌数值、CombatState、地图和存档逻辑。

## 验收标准

- 审计报告确定的第一批高频卡牌全部从 `first_pass` 变为 `production_candidate`。
- 每张图无文字/水印，784x1168，可在 1280x720 卡面中读取主体。
- 数据完整性、跑团和视觉边界测试通过。
