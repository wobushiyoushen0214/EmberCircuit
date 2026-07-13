# 三章 Boss 演出完善

## 需求 ID

- REQ-008

## 目标

为三章 Boss 提供独立舞台视觉、阶段动画配置和专属音频映射，同时保持战斗数值与阶段逻辑不变。

## 交付控制

- 批次：`delivery-batch-001`
- 模式：L2
- worktree/verifier：必须
- 依赖：`01-art-asset-auditor`
- 复杂度：高，必须补 `design.md` 和 `implement.md` 后才能实现

## 文件边界

- 允许：Boss 表现资源、`art_assets.json`、`vfx_profiles.json`、表现层脚本和相关测试。
- 禁止：Boss 生命、行动伤害、阶段阈值和奖励经济。

## 验收标准

- 第一、二、三章 Boss 均有独立非占位舞台资源。
- 阶段切换有可区分动画/VFX/音频画像。
- 10 套回归测试和三张 Boss 720p 截图通过。
