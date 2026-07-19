# Batch 018D：跑团页面契约补齐、真实挂载与视觉验收

## 需求 ID

- REQ-008
- REQ-012 regression
- AC-018D-01 ～ AC-018D-12

## 目标

把 018B 已存在但尚未承载真实流程的 Map/Event/Shop/Campfire/Reward 页面补齐为完整契约，接入真实 `AppShell`，删除对应旧视觉树，并用事务回归、区域金标和性能门证明迁移没有削减玩法。

## 子任务顺序

1. `01-run-page-contract-completion`：补齐五页 VM/signal/state，不修改 Main 业务编排。
2. `02-run-page-runtime-mounts`：Main 生成 VM、连接原回调并挂载五页，不改变业务语义。
3. `03-run-page-visual-verification`：删除无调用旧视觉 helper，更新截图、区域合同、性能和文档。

依赖严格串行；每个子任务必须先完成严格 TDD 和自身自检，第三任务结束后统一双阶段评审。

## 统一兼容契约

- 页面只消费 Dictionary VM 并发出 typed signal，不直接写金币、牌组、奖励、地图、存档或遥测。
- Main 保留交易、奖励幂等、地图选择、事件完成、篝火恢复/锻造的唯一写入点。
- 所有旧 `last_*` probe、兼容节点名、交易价格、奖励内容、存档事务和遥测 payload 不变。
- blocked event choice、买不起/售罄/药水满、奖励未完成和未知 ID 都不得执行状态写入。
- 不改卡牌、遗物、敌人、经济、事件效果、地图生成、挑战、CombatState 或 SaveManager schema。

## 交付控制

- Loop：L3；worktree/verifier：是/是。
- 实现/调试/评审：`trellis-implement-tdd-zh` / `trellis-debug-systematic-zh` / `trellis-review-twostage-zh`。
- 每个任务最大修复 2 次、最大调试 3 轮。
- 任一交易、奖励存档、地图信号、事件幂等或旧 probe 回归立即停止。

## 全批自检

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --quit
for test in tests/test_*.gd; do /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://$test || exit 1; done
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://tools/render_pc_gallery.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tools/verify_ui_visual_regression.gd -- --actual=/tmp/embercircuit_pc_gallery --contracts=res://tests/fixtures/ui_visual_contracts.json --output=/tmp/ember018d-visual.json
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://tools/profile_ui_performance.gd -- --width=1280 --height=720 --warmup=120 --frames=600 --output=/tmp/ember018d-performance.json
```

## 证据入口

- `.trellis/audits/2026-07-18-post-018c-ui-delta-audit.md`
- `.trellis/audits/2026-07-18-018d-run-page-mount-evidence-pack.md`
- `.trellis/tasks/delivery-batch-018b-ui-run-pages.prd.md`
- `.trellis/tasks/delivery-batch-018c-ui-outcome-accessibility-validation.prd.md`
