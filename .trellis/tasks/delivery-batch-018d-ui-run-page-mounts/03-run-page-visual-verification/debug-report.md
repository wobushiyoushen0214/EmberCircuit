# Debug Report: 018D-03

## Session 1: AC-018D-10 legacy helper gate

- Reproduction: `Godot --headless --path . --script res://tests/test_visual_bounds.gd`
- RED signal: static source assertions found `_add_pc_campfire_experience`, `_add_pc_event_experience`, `_add_pc_event_choice_content`, and `_create_reward_action_column` still present.
- Verified scope with `rg`: these helpers had no active PC call after 018D-02; compact event/treasure helpers were retained where still reachable.
- Minimal fix: removed only the uncalled PC construction/style helpers and removed the PC-only reward action-column factory; simplified the compact event choice layout so no deleted PC helper remained referenced.
- Re-run: visual bounds and run-flow passed; no business callback/probe regression.

## Session 2: AC-018D-11 visual RED

- Reproduction: visual verifier against existing goldens produced failed pages `03_reward_720p`, `04_map_720p`, `05_event_720p`, `06_shop_720p`, `07_campfire_720p`; six untouched pages remained pixel-stable.
- Manual evidence: first screenshots showed large empty Reward/Event/Shop/Campfire surfaces, so replacing goldens directly was rejected.
- Minimal fix: added read-only `art_path` fields to Main VMs; upgraded Reward to receipt/offers/actions zones, Event/Campfire to production art stages, and Shop to equal-height icon shelves. No transaction or signal signature changed.
- Re-run: 1280x720 and 1600x900 screenshots showed no overlap/crop/unreachable action; five revised goldens and exact semantic regions passed 11/11 visual verification.

## Session 3: AC-018D-12 profiler node delta

- Reproduction: GUI profiler first reported `node_delta_after_20_switches=-2`; p95/1% low/input/tween/particle budgets were already within limits.
- Verification: the same route loop in headless mode reported node delta `0`; a node-path probe showed only auto-generated page instance IDs differed, not accumulated structure. The discrepancy was a transient GUI/audio/page-enter lifetime before the baseline settled.
- Minimal fix: wait 350ms after the warm-up route cycle and after the 20-cycle route loop before taking counts, keeping the same settled timing at both ends. Removed the temporary path probe after confirmation.
- Final re-run: Apple M4 report passed with route IDs `map,event,shop,campfire,reward`, 20 rounds, node delta `0`, looping tweens `2`, p95 `14.42ms`, 1% low `66.35 FPS`, input `51.509ms`, burst `10/20`.

## 防御性收尾

- 页面换入、旧页释放和异步 page-enter 动画是唯一涉及节点生命周期的入口；两端稳定采样与 20 轮 route loop 已覆盖该入口，问题已局部封闭。
