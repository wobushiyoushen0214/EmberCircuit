# Design: Batch 018C 结算/设置/图鉴与验收

## 编排-计算分离

- 编排：`Main.gd` 生成 outcome/settings/compendium VM，连接旧回调和 SaveManager。
- 计算：`SaveManager.normalized_settings` 纯迁移/clamp；`ForgeMotion` 纯 motion policy；`verify_ui_visual_regression` 纯区域指标。

## 关键契约

- `normalized_settings(raw)` 输出固定 schema v2，未知字段丢弃，旧字段保留。
- `ForgeMotion.resolve_policy(settings)` 在 reduced motion 下返回 `particle_density=0`、无位移/缩放、保留 opacity confirmation。
- `CompendiumPage` 未发现 item 的 title/body/tooltip 全部为锁定提示，不读取隐藏正文。
- `OutcomePage` signals 不直接操作存档；Main 保留唯一状态写入。

## 非目标

不把所有 Main 页面一次性重写；不改变终局事务顺序；不制作第三方资产复制品；不以截图阈值替代结构/功能测试。
