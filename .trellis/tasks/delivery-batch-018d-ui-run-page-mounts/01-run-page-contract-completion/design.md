# Design: 018D-01 跑团页面契约补齐

## 需求覆盖

| 需求 | 当前 | 设计元素 | 预期 |
| --- | --- | --- | --- |
| REQ-008 | PARTIAL | 五页完整 VM/signal/state | PARTIAL，可安全进入真实挂载 |

## MVP 兼容性契约

| 行为 | 证据 | 保留 | 回归 |
| --- | --- | --- | --- |
| 页面不写业务状态 | 018B PRD | 是 | 静态搜索与 signal 测试 |
| 旧稳定节点名 | `test_ember_forge_route_rooms.gd` | 是 | 同测试 |
| 44px/disabled/focus | ForgeTheme 与 accessibility test | 是 | `test_ui_accessibility_motion.gd` |

## 编排-计算分离

| 层 | 元素 | 落点 |
| --- | --- | --- |
| 页面编排 | 根据 VM mode 创建可见 controls，发 typed signal | 五个 page 文件 |
| 纯状态转换 | 不新增；disabled/can_continue 均由 VM 显式输入 | Main 在 018D-02 生成 |

## 契约

- 所有页面 `configure(model)` 可重复调用，先清空动态子节点再重建。
- signal payload 只包含稳定 id 或真实 deck index，不包含可篡改 price。
- `disabled_reason` 非空等价于 disabled；页面展示原因且不发业务 signal。
- mode 未知时退回安全只读态：Shop→store 空货架，Campfire→arrival，Reward→combat 且 continue disabled。

## 挂载点清单

- 本任务无运行时挂载；验收挂载点是 `tests/test_ember_forge_route_rooms.gd` 对五个公开契约的直接实例化。

## 非目标

- 不连接 Main，不生成真实交易/奖励，不删除旧视觉树。
