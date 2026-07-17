# TDD 进度：Batch 018B

| AC | 测试 | 状态 |
| --- | --- | --- |
| AC-018B-01 | `test_ember_forge_route_rooms.gd` | green：五个页面类、共享组件和兼容节点层级通过 |
| AC-018B-02 | `test_map_view.gd` | green：MapPage 持有 EmberMapView 并透传原信号 |
| AC-018B-03 | `test_run_flow.gd` | green：原地图/运行流程回归通过 |
| AC-018B-04 | `test_ember_forge_route_rooms.gd` | green：事件、商店、篝火和奖励状态结构通过 |
| AC-018B-05 | `test_run_flow.gd` | green：交易、删卡和篝火事务回归通过 |
| AC-018B-06 | `test_run_flow.gd` | green：奖励/宝箱领取、部分状态和存档流程回归通过 |
| AC-018B-07 | `test_visual_bounds.gd` | green：1280×720/1600×900 外层边界烟测通过 |
| AC-018B-08 | 全量严格回归 | green：全部 `tests/test_*.gd` 通过 |

备注：本批先落地独立页面与共享组件 API，保留 Main 的旧编排和 probes 以确保事务语义与既有视觉回归稳定；后续挂载替换可在 018C 单独执行。
