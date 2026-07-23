# Post-024 角色策略可信度 Delta Audit 自我评审

## 结论

整体 PASS，可进入 S4/S5 并停在 S6_CONFIRM；Critical 0、Major 0、Minor 0。

| 维度 | 结果 | 证据 |
| --- | --- | --- |
| A 需求追踪 | PASS | REQ-003/004/005/009 均列出 024 代码、evidence、文档和策略源码证据；没有把角色数值或 v3 误标 DONE |
| B 完成度 | PASS | 机械计数仍为 4 DONE、7 PARTIAL、1 MISSING，open gaps=8 |
| C 任务拆分 | PASS | v4 契约→唯一高风险集成→配对可信度验证，三个串行任务且只有 025-02 高风险 |
| D PRD 质量 | N/A | 尚未创建 tasks/PRD；确认后必须逐项复制本审计的 v4 决策表、File Manifest、fixtures、门和停止状态 |
| E 执行友好性 | PASS | 版本隔离、burn 分类、自伤 baseline、创口清理、香炉评分、诊断字段和 64 门均已定死 |
| F 测试规划 | PASS | decision fixtures、v3 回归、profile mapping、elite prediction、primary/repeat、attrition direction 和 evidence verdict 均有明确断言 |
| G Bug 分类 | PASS | 四项 Pyre 偏差均归为策略可信度阻塞 bug；Arc/Ember 未证实部分保持调查项，不提前调数值 |
| H 风险识别 | PASS | CombatState、生产 JSON、正式 matrix、真人 cohort、旧 ladder、128/256 与包体全部显式冻结 |

## S3 检查清单

- [x] A1：四条受影响需求均保持 PARTIAL，并说明已完成基础设施与尚未关闭的可信度/生产缺口。
- [x] A2：实现证据精确到 BalanceSimulator 的 _competent_status_starter_priority、_card_player_hp_cost_is_fatal、_competent_card_score、_score_card、_campaign_card_reward_score 和现有 test_balance_simulator fixtures。
- [x] A3：同时覆盖功能分类错误、敌方回合生存边界、长战污染、遗物非致死评分、策略版本隔离、证据保存与 deterministic repeat。
- [x] B1：DONE 4、PARTIAL 7、MISSING 1、UNTESTED 0、UNCLEAR 0，共 12。
- [x] B2：没有用 B0 的低胜率直接宣称生产角色过弱；已把代码可证明的策略偏差与仍需实证的角色强度分开。
- [x] H1：最高风险是直接修改 v3 导致历史证据失真，以及修 AI 后误把方向性 64 结果当正式调值证据；两项均已设硬禁止。
- [x] H2：明确排除生产调值、A4/E4/Y4、旧 ladder、128/256、UI/美术、网格、商业发布和试玩包。

## S5 批次检查清单

- [x] C1：025-01 只固定版本化语义契约，025-02 只做模拟器行为接线，025-03 只做 evidence/gate；功能实现与最终验证分离。
- [x] C2：025-02 标记为唯一高复杂度/高风险；BalanceSimulator 4407 行和 test_balance_simulator 2121 行触发结构门，新增计算/测试必须进独立文件。
- [x] C3：025-02 依赖 025-01；025-03 依赖前两项；无循环依赖。
- [x] C4：三项均是阻塞角色数值继续迭代的 P0；REQ-005 只冻结，不混入路线实现。
- [x] D1-D9：当前无 PRD，N/A；确认后 PRD 不得包含占位符，必须给出精确函数、fixture、profile、状态码、自检命令和允许/禁止文件。
- [x] E1：所有策略分支均已定死，不允许执行模型临时选择“调权重”或“看结果再决定”。
- [x] E2：复用现有 v3 competent meta、predictive-v2、shadow resolution、candidate overlay 与 compact evidence；只新增 v4 role-aware 分支。
- [x] E3：禁止修改 CombatState、生产卡牌/遗物/角色/敌人/地图/挑战/经济、正式 matrix、真人 cohort 和包体。
- [x] E4/E5：Godot 4/GDScript、严格 headless tests、独立 helper、版本化 evidence、worktree/verifier/双阶段评审均明确。

## 证据复核

- 024 verdict SHA-256：f70b155537c31573ef53c7e6afcfb49bc998497626fc5343760663624a10a413。
- 024-B0 source report SHA-256：af199c189e4208dce26776f9e95e749950655279cedd90f071ff2f7f6463ba4d，与 compact evidence 声明一致。
- Pyre C0 intro_patrol：110 visits、8 deaths、2464 total HP loss、22.400 average。
- Pyre C0 cinder_kennels：55 visits、10 deaths、1132 total HP loss、20.582 average。
- 两遭遇加权平均损血：(2464+1132)/(110+55)=21.7939，025 方向门的 10% 改善上界为 19.6145，审计写为 19.615。
- A1/A2/A3 原始胜局分别为 24/13/6/6、22/16/7/6、25/23/9/8；没有把 A2 视为 selected。

## MVP 兼容性

- competent-player-v1/v2/v3 继续保留原 profile 名称、组件映射和历史语义。
- v4 只在明确选择 competent-player-v4 时生效；默认 current-greedy 和 v3 报告不新增 role diagnostics 字段。
- v4 full-graph elite safety 复用 predictive-v2 路由算法，但 elite combat prediction 必须调用 v4 出牌语义。
- 025 的 64 evidence 只能决定“策略是否可信到足以重新审计数值”，不能选择生产候选。

## 统计

- 适用检查项：A、B、C、E、F、G、H。
- 通过：全部适用项。
- 未通过：0。
- 不适用：D（任务 PRD 尚未创建）。
- Critical/Major/Minor：0/0/0。

## 人工门

当前正确下一步是确认 delivery-batch-025-role-strategy-credibility。确认前不得创建 task、实现 v4、运行 025 正式配对报告或修改生产数值。
