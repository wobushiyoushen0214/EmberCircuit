# 双阶段评审报告

## 被评审对象

- 任务：`delivery-batch-006-defeat-ui-save-integrity`
- diff 范围：`c8320c3..L3 Round 2 工作树`
- Stage 1：主线程按 PC 战败页、终局事务、旧档迁移、存储隔离、数值冻结和发布清单机械核对。
- Stage 2：Codex 强模型只读子代理（Averroes）独立检查存档所有权、奖励/遥测幂等、原子恢复、失败重试和测试数据安全。

## Stage 1 · 规范符合

| 检查项 | 结果 | 证据 | 说明 |
| --- | --- | --- | --- |
| PC 战败结算 | 通过 | `tests/test_run_flow.gd`, `tests/test_visual_bounds.gd`, `29_defeat_720p.png` | 单一结算舞台复原实际章节、角色和存活敌人；四个正常动作均为真实接线。 |
| 720p 边界 | 通过 | `tests/test_visual_bounds.gd`, `tests/test_playtest_run_integration.gd` | 正常态和存储失败重试态均关闭系统滚动条，舞台、摘要和动作保持在 `1280x720` 内。 |
| 终局事务 | 通过 | `SaveManager.gd`, `Main.gd`, 三项存档/遥测测试 | 顺序为永久奖励落盘、终局遥测落盘、按同一 `run_id` 删除本局存档；失败保留恢复存档。 |
| 旧档兼容 | 通过 | `tests/test_playtest_run_integration.gd` | alpha.1/v2 无身份存档获得稳定 `legacy_<hash>`，跨两次实例加载不变化。 |
| 数值冻结 | 通过 | 当前 diff | 未修改卡牌、角色、怪物、成长、挑战或经济数值。 |
| 发布入口 | 通过 | `project.godot`, `export_presets.cfg`, `Main.gd`, `PLAYTEST_README_ZH.txt` | 版本一致升级为 `0.1.0-alpha.5` / build 5；未包含 API key、API 响应或 `build/`。 |

## Stage 2 · 首轮与中期发现

| 严重度 | 问题 | 处置 |
| --- | --- | --- |
| Critical | 战败/通关可能删除另一活动局拥有的单槽存档。 | 增加顶层 `run_id` 和 `delete_run_for_run_id()` 所有权校验；不匹配时保留存档。 |
| Critical | Boss 与完整通关永久奖励可因旧存档重复领取。 | Profile v3 增加 Boss/通关领取凭证；保存失败回滚内存，重复凭证不再发奖。 |
| Critical | alpha.1/v2 存档没有跨重启稳定身份。 | 从原始 JSON 的 SHA-256 派生稳定 legacy ID，加载后写回 v4 顶层和活动遥测。 |
| Critical | Profile 等 JSON 使用直接截断写，失败时可能损坏旧数据。 | 全部本地 JSON 改为已验证 `.tmp`、`.bak` 和原子替换，并增加中断恢复测试。 |
| Critical | 自动化和图库可能写入真实 `user://` 数据。 | SaveManager 增加隔离命名空间；所有相关测试/图库迁移到独立路径。 |
| Major | 战败路线总数使用扁平分支节点，首战显示 `1/16`。 | 改用节点层数和地图总层数，图库及流程测试锁定为 `1/8`。 |

## Stage 2 · 最终阻断复审

| Critical | 修复与关闭证据 |
| --- | --- |
| 胜利遥测已归档但存档清理失败后，真实“继续”路径会被仅接受活动局的 Boss 入口拦截。 | Boss/通关入口在无活动局时只接受同一终局 ID 已存在的领取凭证，不能新增凭证；随后可验证归档胜利并重试删除。`test_playtest_run_integration.gd` 覆盖。 |
| 同一 `run_id` 的已归档胜负可能被陈旧活动快照覆盖为另一结果。 | `set_active_run()` 拒绝恢复已归档胜负；终局追加保留首次 victory/defeat；读取陈旧终局存档会直接按所有权清理。`test_playtest_telemetry.gd` 覆盖冲突结果。 |
| `delete_run_for_run_id()` 未先恢复 `.tmp/.bak`，可能残留可恢复存档却报告成功。 | 所有权删除先执行原子恢复；无主文件但仍有不可恢复侧文件时返回失败。`test_save_manager.gd` 覆盖仅剩有效 `.bak` 的删除。 |
| 两份测试仍捕获并以 `FileAccess.WRITE` 回写真实文件。 | 删除真实文件捕获/恢复代码；测试只访问 `run_save_path()` 等隔离路径。源码扫描和测试前后真实文件 SHA-256 均确认无变化。 |

## 最终裁决

- 首轮与中期 critical：全部关闭。
- 最终阻断复审 critical：4 项全部关闭。
- 新增 critical：0。
- 新增 major：0。
- Stage 2 修复后复审：通过。
- 裁决：允许提交源码并进入 `0.1.0-alpha.5` 产物构建。

## 验证证据

- Godot 4.7 headless 项目解析通过。
- 18/18 Godot 测试串行通过，并扫描 `SCRIPT ERROR` / `ERROR:`；未仅依赖进程退出码。
- 测试前后真实设置、Profile、真人遥测和报告 SHA-256 完全一致，真实跑团存档始终不存在。
- PC 图库 `29_defeat_720p.png` 为 `1280x720`，人工检查确认战场、`1/8` 路线、摘要、炉印回执和动作完整显示，无裁切、重叠或可见滚动条。
