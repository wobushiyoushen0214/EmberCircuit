# Design: 018D-02 真实运行时挂载

## 需求覆盖

| 需求 | 当前 | 设计 | 预期 |
| --- | --- | --- | --- |
| REQ-008 | PARTIAL | 五页 VM/adapter/AppShell mount | PARTIAL，跑团高频页完成统一 shell |

## 编排-计算分离

| 层 | 元素 | 落点 |
| --- | --- | --- |
| 编排 | 状态分支、页面实例化、signal 连接、调用原业务回调 | `Main.gd` refresh/mount/adapter |
| 纯变换 | 当前 Main state→Dictionary VM；id→当前 option/choice 查找 | `Main.gd` 独立 `_..._page_model/_find...` helper |
| 展示 | VM→controls、controls→typed signal | 018D-01 五页，不在本任务改业务 |

## 数据/状态契约

- page id：`map`, `event`, `shop`, `campfire`, `reward`。
- Event id 只在当前 `_event_by_id(current_event_id).choices` 中解析。
- Shop id 只在当前三类 option 数组中解析，price 取匹配 Dictionary。
- Campfire `deck_index` 必须在 `0 <= index < run_deck_ids.size()` 且当前卡可升级。
- Reward id 只在当前 reward arrays 中解析；mastery id 只在当前 eligible masteries 中解析。

## 挂载点清单

同 PRD 五项；Stage 1 必须逐项核对 active_page_id、signal、业务回调和清理。

## 非目标

- 不重构整个 Main，不改业务函数签名，不改页面美术 token，不删旧 helper。
