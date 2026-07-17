# Implementation Plan: Batch 018B

1. 读取 018A 组件 API，先写五页结构/信号 RED。
2. 迁移 MapPage，保留 MapView 两个 signal，跑 map/bounds。
3. 迁移 EventPage/CampfirePage，逐个覆盖禁用、空选项、重复牌、长牌组。
4. 新建 ShopExperience，所有状态写入仍回到 Main，跑交易回归。
5. 新建 RewardPage，统一战斗奖励/宝箱 view model，跑存档/部分领取回归。
6. 统一 motion/focus/token，跑 route rooms 截图与资源审计。
7. 全量严格回归后再进入双阶段评审。

结构阈值：Main.gd 继续超过胖文件阈值，只搬五个页面视觉树，不改业务函数签名；MapView 只增加状态绘制 helper，不重写地图算法。
