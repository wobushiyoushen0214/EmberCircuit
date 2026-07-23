# 调试报告

## Session 1：路线节点可见但无法点击

### 失败信号

- 复现命令：`HOME=/tmp/ember-route-click-red /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_ember_forge_route_rooms.gd`
- 原文：

```text
FAIL: map page routes a real mouse click through its decorative chrome to an available node
EXIT_CODE=1
```

- 是否稳定复现：是。

### 定位过程

| 方法 | 结果 |
| --- | --- |
| 读代码与控件矩形 | `MapPage.gd:_build_shell()` 中 `MapRoomMargin` 与 `MapRoomColumn` 都覆盖地图区域，且默认 `mouse_filter=STOP`。 |
| 加诊断日志 | PC 尺寸视口下把两层设为 `IGNORE` 后，悬停命中 `EmberMapView/@Button@3`，点击发出 `selected=["shop"]`。 |
| 单层反证 | 将 `MapRoomMargin` 或 `MapRoomColumn` 任一层恢复为 `STOP`，悬停命中装饰容器且 `selected=[]`。 |
| 测试环境诊断 | 无头 `SceneTree.root` 默认仅 `64×64`，原回归点击坐标在视口外；设置为 `1280×720` 后真实 GUI 派发有效。 |

### 假设记录

| 轮次 | 假设 | 验证方式 | 结论 |
| --- | --- | --- | --- |
| 1 | 全屏装饰容器截获了原本应到达路线按钮的鼠标事件。 | 记录 `gui_get_hovered_control()`，逐层切换 `mouse_filter`。 | 成立。 |
| 2 | 修复后回归仍红是生产代码无效。 | 打印根视口和点击坐标，使用实际 PC 视口重跑。 | 证伪；是测试视口过小。 |

### 修复

- 根因：地图后添加的 `MapRoomMargin/MapRoomColumn` 是视觉说明层，却以默认 `STOP` 覆盖整个地图热区。
- 改动位置：`scripts/ui/pages/MapPage.gd`，仅把上述两个装饰容器设为 `MOUSE_FILTER_IGNORE`。
- 回归保护：`tests/test_ember_forge_route_rooms.gd` 使用 `1280×720` 根视口并向真实可选路线按钮发送鼠标按下/释放事件。
- 原失败命令：绿，输出 `PASS: ember forge route rooms`。

### 防御性回归

- 这个 bug 能否从别处再发生：能；任何覆盖地图的后置装饰层若恢复 `STOP` 都会再次截获事件。
- 已在 `delivery-batch-018b-ui-run-pages.check.jsonl` 记录真实鼠标点击回归点。

### 退出状态

- [x] 绿了，返回实现验证阶段。
- [ ] 已回滚，升级。
- [ ] 超 3 轮，升级强模型/人工。
