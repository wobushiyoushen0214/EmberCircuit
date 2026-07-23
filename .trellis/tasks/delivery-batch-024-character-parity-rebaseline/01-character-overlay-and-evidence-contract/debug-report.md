# 调试报告

## Session 1

### 失败信号

- 复现命令：`HOME=/tmp/ember024_tdd_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_candidate_overlay.gd`
- 原文（堆栈/断言/退出码）：

```text
退出码 1
ERROR: Test failed: AC-023-02 dataset returns only its fixed error code
GDScript backtrace:
    [0] _check (res://tests/test_balance_candidate_overlay.gd:434)
    [1] _test_invalid_overlays_fail_closed (res://tests/test_balance_candidate_overlay.gd:167)
    [2] _run (res://tests/test_balance_candidate_overlay.gd:16)
```

- 是否稳定复现：是。

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读栈 | `tests/test_balance_candidate_overlay.gd:103-105` 的旧 fixture 期望 `dataset_forbidden`；fixture 使用新纳入 allowlist 的 `player`，而该测试传入的数据集不含 `player`。 |
| 查契约与实际分支 | `scripts/tools/BalanceCandidateOverlay.gd:_validate_payload` 只检查静态 `DATASET_NAMES`，因此现在越过 dataset 检查并返回 `path_forbidden`。 |

### 假设记录

| 轮次 | 假设（具体到变量/分支/契约） | 验证方式 | 结论 |
| --- | --- | --- | --- |
| 1 | 根因是 `load_and_apply` 校验时没有把调用方实际提供的数据集纳入 dataset fail-closed 判断，导致缺失的 `player` 被视为可用数据集。 | 对照旧 fixture、`_datasets_fixture()` 和新增五数据集契约；确认旧输入只有三份数据，新 024 输入显式包含 `player/relics`。 | 成立 |

已排除项：

- 不是新 allowlist 错把 `player.max_hp` 放行；该路径仍返回 `path_forbidden`。
- 不是 source mutation 或 metadata 泄漏；失败发生在固定错误码断言。

### 修复

- 根因：静态 dataset allowlist 与调用方实际 dataset 可用性没有同时校验。
- 改动位置（一处）：`scripts/tools/BalanceCandidateOverlay.gd:_validate_payload` 的 dataset 分支；`load_and_apply` 传入调用方 datasets，直接单测仍可省略该参数。
- 重跑原失败命令结果：绿，退出码 0，输出 `Balance candidate overlay tests passed.`。

### 防御性回归

- 这个 bug 能否从别处再发生：不能；所有静态允许 dataset 都经过同一可用性分支，`player/relics` 以及旧三数据集没有旁路，已局部封闭。

### 退出状态

- [x] 绿了，回到 TDD 循环失败的那一步
- [ ] 已回滚，升级（附已排除项）
- [ ] 超 3 轮，升级强模型/人工

## Session 4

### 失败信号

- 复现命令：`HOME=/tmp/ember024_tdd_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_evidence_digest.gd`
- 原文（堆栈/断言/退出码）：

```text
退出码 1
Balance evidence digest test failed with 4 assertion(s).
- AC-024-05 duplicate case returns stable errors
- AC-024-05 missing case returns stable errors
- AC-024-05 runs mismatch returns stable errors
- AC-024-05 malformed raw case returns stable errors
```

- 是否稳定复现：是。

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读栈与夹具 | 四个用例都修改内存 report，却继续传入原始合法 `report_path`；新增 source binding 因而正确追加 `identity_mismatch`，使单错误预期不再成立。 |

### 假设记录

| 轮次 | 假设（具体到变量/分支/契约） | 验证方式 | 结论 |
| --- | --- | --- | --- |
| 1 | 旧夹具没有把各 malformed report 写到对应 source 文件，导致用例同时触发绑定错误。 | 对照四个 build 调用的 report 与共同 `report_path`；其他 source mismatch 专项测试已按预期转绿。 | 成立 |

已排除项：

- source binding 实现未误拒绝合法 report；AC-024-04 合法 4/12 case 仍通过。
- gate invariant 修复已通过新增三组 RED。

### 修复

- 根因：测试夹具在新增信任边界后不再满足“一次隔离一个错误”的前提。
- 改动位置（一处）：`tests/test_balance_evidence_digest.gd` 的 malformed report source paths。
- 重跑原失败命令结果：绿，退出码 0，输出 `Balance evidence digest test passed.`。

### 防御性回归

- 这个 bug 能否从别处再发生：不能；所有修改 report 的单错误夹具现在都写入对应 source，另有专门 mismatch 用例保护绑定错误。

### 退出状态

- [x] 绿了，回到 TDD 循环失败的那一步
- [ ] 已回滚，升级（附已排除项）
- [ ] 超 3 轮，升级强模型/人工

## Session 2

### 失败信号

- 复现命令：`HOME=/tmp/ember024_tdd_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_balance_evidence_digest.gd`
- 原文（堆栈/断言/退出码）：

```text
退出码 1
Balance evidence digest test failed with 1 assertion(s).
- AC-024-05 written JSON equals returned digest
```

- 是否稳定复现：是。

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读栈与写入点 | `BalanceEvidenceDigest.gd:68` 直接写 `JSON.stringify(result.digest)`；失败断言在测试中重新 parse 后做 Dictionary 严格相等。输出文件内容完整且字段正确。 |

### 假设记录

| 轮次 | 假设（具体到变量/分支/契约） | 验证方式 | 结论 |
| --- | --- | --- | --- |
| 1 | JSON parse 对数字 Variant 类型的归一化使 Dictionary 严格相等失败，断言没有直接验证 writer 写出的字节。 | 对照唯一写入语句与实际输出文件；writer 字节定义就是返回 digest 的 `JSON.stringify`。 | 成立 |

已排除项：

- 文件未写入、截断或缺字段；输出文件存在且是完整 compact digest。
- builder 返回失败；该用例已通过 `ok` 与文件存在断言。

### 修复

- 根因：测试在序列化边界后比较归一化 Dictionary，而不是比较实际写入字节。
- 改动位置（一处）：`tests/test_balance_evidence_digest.gd` 的 writer 成功断言。
- 重跑原失败命令结果：绿，退出码 0，输出 `Balance evidence digest test passed.`。

### 防御性回归

- 这个 bug 能否从别处再发生：不能；writer 成功路径只有这一处序列化边界，测试现在直接比较文件字节与返回 digest 的同一序列化结果。

### 退出状态

- [x] 绿了，回到 TDD 循环失败的那一步
- [ ] 已回滚，升级（附已排除项）
- [ ] 超 3 轮，升级强模型/人工

## Session 3

### 失败信号

- 复现命令：`HOME=/tmp/ember024_tdd_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_character_balance_candidate_overlay.gd`
- 原文（堆栈/断言/退出码）：

```text
退出码 1
Character balance candidate overlay test failed with 2 assertion(s).
- AC-024-02 overlay delegates all five entity selectors
- AC-024-02 duplicate id returns selector_ambiguous
```

- 是否稳定复现：是。

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读栈与契约 | 两条失败都经过 relic selector；精确路径为 `[relics,id,effects,0,amount]` 共 5 段，而 `BalanceCandidateSelector.gd:_apply_relic` 守卫写成 `size() != 6`。 |

### 假设记录

| 轮次 | 假设（具体到变量/分支/契约） | 验证方式 | 结论 |
| --- | --- | --- | --- |
| 1 | `_apply_relic` 的错误长度守卫在唯一/重复 id 查找前统一返回 `path_forbidden`。 | 逐段计数测试输入并对照守卫；两条失败恰好都是 relic 路径，player 唯一/缺失路径已通过。 | 成立 |

已排除项：

- player selector、深拷贝和缺失 id 分支已通过，不是共同根因。
- overlay allowlist 已接受精确 relic path，失败发生在 selector 委托后。

### 修复

- 根因：遗物精确尾路径长度常量写错。
- 改动位置（一处）：`scripts/tools/BalanceCandidateSelector.gd:_apply_relic` 的长度守卫。
- 重跑原失败命令结果：绿，退出码 0，输出 `Character balance candidate overlay test passed.`。

### 防御性回归

- 这个 bug 能否从别处再发生：不能；024 只允许这一种固定遗物尾路径，唯一和重复 id 均经过同一守卫，已有两条回归断言保护。

### 退出状态

- [x] 绿了，回到 TDD 循环失败的那一步
- [ ] 已回滚，升级（附已排除项）
- [ ] 超 3 轮，升级强模型/人工
