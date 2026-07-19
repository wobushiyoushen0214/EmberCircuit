# 技术架构

## 1. 核心原则

项目采用数据与表现分离。

- `CombatState` 是战斗唯一数据源。
- `EffectResolver` 负责卡牌、敌人和遗物效果结算。
- UI 只读取状态并发送请求，不直接修改生命、手牌、敌人或奖励。
- 所有数值优先放在 `data/`，脚本只实现规则解释器。

## 2. 目录职责

```text
scenes/      Godot 场景文件
scripts/     GDScript 逻辑
data/        卡牌、敌人、遗物、遭遇和配置
docs/        设计、计划、数据规范和资产管线
assets/      美术、音频、字体和特效资源
tests/       自动化验证脚本
```

## 3. 关键脚本

- `scripts/core/DataLoader.gd`：读取 JSON 数据。
- `scripts/core/GameState.gd`：跨战斗存档和运行状态。
- `scripts/combat/CombatState.gd`：战斗状态机。
- `scripts/main/Main.gd`：当前 MVP 的主界面和战斗展示。

## 4. 数据格式

JSON 文件允许 `_comment`、`notes`、`balance_note`、`design_note` 字段。这些字段用于人类阅读，不参与规则结算。

## 5. 事件流

战斗中统一使用事件概念驱动遗物和状态：

- `combat_start`
- `turn_start`
- `card_played`
- `damage_dealt`
- `block_gained`
- `enemy_block_broken`
- `enemy_died`
- `combat_won`

## 6. 测试策略

优先验证纯数据层：

- 抽牌、洗牌、弃牌。
- 能量消耗。
- 伤害和护甲。
- 状态叠加和递减。
- 敌人意图与实际行动一致。
- 遗物触发次数。

表现层测试放在第二优先级，主要检查按钮、文本和流程切换。

## 7. UI Shell 与页面边界

- `data/config/ui_theme_tokens.json` 与 `ui_motion_profiles.json` 是暗炉颜色、字号、间距和动效时长的唯一新页面数据源。
- `ForgeTheme`/`ForgeMotion` 负责 typed token、fallback、StyleBox 和 reduced-motion；页面不得直接读取存档、战斗或遥测状态。
- `AppShell` 管理单一 active page，并以完整页面根节点挂载 Welcome/CharacterSelect；`Main.gd` 只构建 view model、连接原回调并维护旧 probe。
- `MenuCommandButton` 是欢迎页专用命令控件，`CharacterStageCard` 是角色选择专用舞台；两者避免把菜单重新塞回通用奖励卡抽象。
- `WelcomePage` 与 `CharacterSelectPage` 只发请求信号；角色预览不启动跑团，固定确认动作才进入原始 start flow。
- 新交互组件保持至少 `44×44` 热区、2px 黄铜焦点环和 unknown token fallback；reduced-motion 不改变布局边界。
- UI 视觉金标以 PC 1280×720、1600×900 为准；更小窗口只承诺页面外层有界和关键动作可达，不反向压缩桌面构图。

### Batch 018B 路由房间边界

- `MapPage`、`EventPage`、`ShopExperience`、`CampfirePage`、`RewardPage` 只接受 Dictionary view model，并通过 typed signals 将选择交还给 `Main.gd`。
- `ChoiceRow`、`ItemShelf`、`CardCompare` 复用 `ForgeTheme` 的面板、按钮和焦点样式；页面不读取 SaveManager、金币、牌组、CombatState 或遥测。
- 018D 已将五页真实挂入唯一 `AppShell.page_host`。运行链路固定为 `Main 状态 -> 只读 VM -> page.configure -> typed signal -> Main adapter -> 原业务回调`；页面不得绕过 adapter 写入交易、奖励、牌组、存档或遥测。
- Event/Shop/Reward adapter 必须按当前 Main 状态重新查找 id 与价格，Campfire 必须重新验证真实 deck index；未知、过期或重复请求只发 warning，不执行事务。Map preview/select 每个用户动作只转发一次。
- `Main.map_view` 始终指向当前 `MapPage` 内唯一 MapView；AppShell 换页会移除并释放旧页。旧 `last_*` probes 与兼容节点名继续保留，但五页旧 PC 内联视觉构造已删除。
- PC 页面可以从 Main VM 接收只读 `art_path` 用于事件、篝火、卡牌、遗物和药水展示；资源路径不构成业务授权，点击后的合法性仍由 Main adapter 判定。

## 8. 真人试玩遥测

真人试玩数据与 profile、跑团存档、启发式 AI 模拟报告分离：

- `scripts/core/PlaytestTelemetry.gd` 是采集与 schema 归一化层；`scripts/core/PlaytestEvidenceGate.gd` 是纯计算层，负责 cohort、留存、覆盖矩阵和多报告合并，二者都不依赖 UI 节点。
- `scripts/core/SaveManager.gd` 统一管理跑团存档、设置、Profile、真人遥测和报告路径；所有 JSON 先写入并校验 `.tmp`，再通过 `.bak` 替换主文件，启动读取时会恢复已验证的中断写入。终局清理必须以活动 `run_id` 校验单槽存档归属，测试/图库使用隔离存储命名空间。
- `scripts/main/Main.gd` 将真实操作路径映射到遥测 API，并把当前活动局快照嵌入普通跑团存档。
- `data/config/numerical_tree.json.human_playtest_targets` 保存真人样本门槛，不与 AI 的 `campaign_matrix` 混用。

每局以匿名随机 `run_id`、版本、Godot 版本和游戏配置 SHA-256 指纹开始。cohort 由遥测 schema、游戏版本和配置指纹共同派生；任何一项不同都禁止合并胜率、卡牌 lift 或失败集中度。v1 数据迁移为 `legacy_unapproved`，不会自动进入 12/30 样本门。即使 fixture 与真人拥有相同 cohort 身份，summary、胜率、卡牌、失败集中度和 raw runs 也只消费 `sample_kind=human && gate_eligible=true` 的记录；非批准行仅保留诊断计数。顶层兼容字段映射到最新含合格完成局的 cohort；离线合并会重算 cohort 身份并继承输入报告的完整期望覆盖矩阵。

Profile v3 使用 `reward_receipt_ids` 持久化 `boss:<run_id>:<chapter_id>` 和 `completion:<run_id>` 领取凭证。Boss 炉印、Boss 统计和完整通关奖励只有在 Profile 保存成功后才关闭结算；重复读取旧存档不会重复发放永久奖励。

跑团存档 schema v5 在顶层保存 `run_id`，并以独立奖励事务保存战斗奖励的跑团/章节/节点/遭遇归属、金币基线、精确内容 ID 和处理标记。恢复时按当前数据表重建内容并校验全部事务不变量；非法事务会回滚已入账战利品金币后清除。alpha.1/v2 旧存档没有身份时，以原始存档文本的 SHA-256 派生稳定的 `legacy_<hash>`，第一次读取后写回顶层和活动遥测，跨重启保持一致。终局提交顺序固定为永久奖励/Profile 落盘、同一局遥测落盘、按 `run_id` 删除本局存档；任一步失败都保留可恢复存档，战败页提供显式重试。

运行时记录角色、挑战、显示尺寸/缩放、系统平台、区域设置、路线节点、遭遇结果、回合数、节点前后生命/金币/牌组规模、卡牌展示/获取/删除/升级/打出、遗物与药水获取、药水使用、奖励跳过、事件选择和存档加载次数。它不记录用户名、主目录、硬件序列号或网络标识，也不会自动联网发送。当前不提供伤害来源、总伤害、总格挡、总治疗或逐动作耗时事件流，分析时不得从净生命变化伪造这些指标。

落盘策略避开高频动画路径：出牌只更新内存；回合结束、节点开始/完成、奖励选择、商店/事件结算、手动保存、读取和胜负终局才建立检查点。留存按 cohort 和角色/挑战格执行：每格保留最近 40 个合格完成局，每 cohort 另保留 96 个合格 abandoned；fixture/legacy 走独立的 96 行诊断配额，最多保留最近 4 个 cohort，因此非批准样本不得挤掉真人证据。胜率分母只包含 `victory + defeat`，`abandoned` 和活动局单列。读取另一份存档会把被替换的活动局记为放弃，恢复局的 `loads` 加一；若恢复的是先前被标记放弃的同一局，会撤销旧放弃行，避免重复计数。
