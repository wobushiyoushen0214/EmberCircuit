# Design: 024-03 正式 256、生产晋级与试玩包

## 需求覆盖

| 需求 | 当前 | 设计元素 | 本任务后预期 |
| --- | --- | --- | --- |
| REQ-003/004/005 | PARTIAL | selected-bound 256、promotion、static+matrix sync | 已验证生产基线或精确回滚 |
| REQ-009 | PARTIAL | versioned 256 digest 与 AI/真人隔离 | 正式 AI 证据可审计 |
| REQ-011/012 | PARTIAL/DONE | conditional alpha.9 与全量门 | 可分发包或明确不打包 |

## 数据流

```text
selected 128 verdict -> bound C1 256 primary + identical repeat -> compact digest
 -> shared hard gate -> pure promotion + static audit -> matrix dry-run
 -> PASS: atomic production/tree apply -> full regression -> review -> source commit -> alpha.9
 -> FAIL: exact Batch 024 baseline + evidence only + package locked
```

## 决策表

| 决策 | 选定 | 排除 | 原因 |
| --- | --- | --- | --- |
| 生产写入 | pure deep-copy helper 后统一落盘 | runner 直接逐文件改 | 允许单测与原子回滚 |
| matrix | report keyed + static report | 手填 rows | 保证来源可审计 |
| 静态目标 | PRD 的 selected-step 固定映射 | 运行后临时扩大范围 | 规划阶段定死 |
| 包体 | hard/static/regression/review 后 | 128或失败候选包 | 保护真人 cohort |
| 发布平台 | Windows x86_64 单包 | 同时扩大 macOS 发布 | 延续 alpha.8 PC 测试范围 |

## API 契约

- `CharacterParityProductionPromotion.build(map,level,economy,player,relics,selected_payload)`：成功返回五份 deep copy 和 provenance；失败 datasets 为空。
- `CampaignMatrixSync.build_synced_tree(tree,static,primary,repeat,selection,hard)`：成功返回 deep-copied tree；失败 tree 为空。
- CLI 将文件 I/O、dry-run、临时解析与 atomic replace 留在薄编排层。

## 编排-计算分离

| 层 | 元素 | 落点 |
| --- | --- | --- |
| 编排 | 256 pair、digest、hard、apply/rollback、docs/build | 执行步骤 + `sync_campaign_matrix.gd` |
| 计算 | selected overlay → 五数据集 | `CharacterParityProductionPromotion.gd` |
| 计算 | report/static → matrix/tree | `CampaignMatrixSync.gd` |
| 计算 | 256 thresholds | 既有 `LayeredPressureCandidateGate.gd` |
| 发布 | export/archive/verification | 外层评审后命令 |

## 挂载点

1. `campaign_rebaseline_024.selected_candidate` 绑定唯一 256 overlay。
2. shared hard gate 控制 promotion/sync 是否可执行。
3. promotion helper 控制生产五数据集。
4. sync CLI `--apply` 控制正式 numerical tree。
5. Main/project/export/README 四版本入口控制 alpha.9 cohort 与包体。

## 结构健康度

| 目标 | 当前 | 阈值 | 处理 |
| --- | ---: | ---: | --- |
| `Main.gd` | 约 14k | 400 | 只改版本常量，不重构 |
| `test_numerical_balance_matrix.gd` | 426 | 400 | sync cases 放新 test，旧文件只替换 freeze dispatcher |
| `NumericalTreeAuditor.gd` | 约 860 | 400 | 只消费，不修改 |
| 新 helper/CLI/tests | 0 | 400 | 各自低于 400，pure logic 与 I/O 分离 |

## 非目标

- 不再搜索候选，不改 024 gate，不做 macOS/Steam/签名/安装器。
- 不以 AI 报告宣称真人难度已验证。

