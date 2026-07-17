# Implementation Plan: Batch 018C

1. RED Outcome compatibility/restore tests，提取 OutcomePage/OutcomeStage。
2. RED/GREEN SaveManager settings v2 migration，先跑 save manager。
3. RED/GREEN SettingsPage 分组、slider/toggle、reset confirm、来源页返回。
4. RED/GREEN CompendiumPage rail/search/template/lock/empty state。
5. 接入 ForgeMotion/AppShell 全局 reduced motion、flash、particle policy。
6. RED/GREEN accessibility/focus/44px/contrast and performance leak tests。
7. 固定字体、时间、seed、particle profile 生成 11 张金标，运行区域 visual diff。
8. 运行 600 帧性能采样、全量严格回归和双阶段评审。

结构约束：Main.gd 只抽离 outcome/settings/compendium 视觉树，保留存档/遥测/旧 probe；SaveManager 不改 run/profile/playtest schema。
