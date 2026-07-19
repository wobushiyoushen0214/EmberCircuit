# TDD 进度：018D-02

| AC | 可观察结果 | 测试 | 状态 | 备注 |
| --- | --- | --- | --- | --- |
| AC-018D-05 | MapPage 真实 mount 与信号单次透传 | route/map/run tests | done | MapPage mount、单次 preview/select GREEN；六套自检全绿。 |
| AC-018D-06 | EventPage 合法/禁用/未知 choice 语义 | route/run tests | done | EventPage mount、合法/blocked/unknown id GREEN；六套自检全绿。 |
| AC-018D-07 | CampfirePage 两阶段与真实 deck index | route/run tests | done | CampfirePage 两阶段、真实/非法 index、长列表 GREEN；六套自检全绿。 |
| AC-018D-08 | ShopExperience 交易/删卡/禁用/未知 id | route/run tests | done | RED：PC 商店仍在 legacy reward_row；GREEN：真实 ShopExperience 购买、删卡、取消、禁用和 adapter 路径通过。 |
| AC-018D-09 | RewardPage combat/treasure/v5/mastery/continue | route/run/playtest tests | done | RED：combat/treasure 仍命中旧 chrome；GREEN：RewardPage 挂载、事务恢复、继续门和 720p bounds 六套自检全绿。 |

## 最小实现收敛

- 删除项：移除跨 AC 的未定义预写调用与重复测试分支；本任务按约束不删除旧视觉 helper。
- 复用项：原 Main 业务回调、AppShell、018D-01 page contracts、现有价格/奖励/存档/专精计算。
- 保留项：交易与奖励事务、遥测、未知 id/非法 index 错误路径、`last_*` probes、兼容节点名和非 PC legacy 路径。
- `trellis-minimal:`：无。

## 收尾核对

- [x] AC-018D-05 ～ AC-018D-09 全部 done，无 red/green 遗留。
- [x] 隔离 HOME 的 editor parse 与 PRD 六套自检最后一轮全绿；已扫描 `SCRIPT ERROR` / `Failed to load script` / `Test failed`。
- [x] 未新增依赖、autoload、data/schema 或未来扩展抽象。
- [x] Map/Event/Campfire/Shop/Reward 五个挂载点均接入 AppShell，页面 signal 只转发到原业务回调。
- [x] 未 commit/push/merge；等待双阶段评审。
