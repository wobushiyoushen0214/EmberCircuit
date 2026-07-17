# Design: Batch 018B 跑团页面

## 编排-计算分离

- 编排：`Main.gd` 生成 VM、连接 signals、调用原交易/存档/地图函数。
- 显示/计算：`MapPage/EventPage/ShopExperience/CampfirePage/RewardPage` 负责布局、状态派生和交互信号；`ItemShelf/CardCompare` 负责纯显示数据转换。

## 页面契约

- Page 输入均为 Dictionary VM；不读取全局 SaveManager。
- Shop signal：`buy_card(id)`, `buy_relic(id)`, `buy_potion(id)`, `open_remove()`, `remove_card(index)`, `leave()`。
- Reward signal：`claim_card(id)`, `claim_relic(id)`, `claim_potion(id)`, `skip()`, `save()`, `continue()`。
- Map signal 与现有 API 完全同名。

## 兼容策略

迁移阶段保留旧节点名称和 Main `last_*` probes；先让新 page 通过结构测试，再删除重复 inline builder。删除重复代码不得改变回调参数、节点名称或滚动边界。

## 非目标

不做后章数值、不改商店价格/交易算法、不做全局 Main 拆分、不替换遗留敌人/事件美术。
