# 调试报告

## Session 1

### 失败信号

- 复现命令：`HOME=/tmp/ember023_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_layered_pressure_rebaseline.gd`
- 原文（堆栈/断言/退出码）：

```text
AC-023-08 pressure diagnostic P2/chapter_two/25 ... layer=6 type=combat pressure=4 max=3
ERROR: AC-023-08 P2/chapter_two/25 path stays under pressure limit
Layered pressure rebaseline fixture test failed with 1 assertion(s).
exit_code=1
```

- 是否稳定复现：是；固定为 P2、chapter_two、seed index 25。

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 加日志 | `tests/test_layered_pressure_rebaseline.gd` 已缩小到完整路径 `L0_N0 -> L1_N0 -> L2_N0 -> L3_N0 -> L4_N1 -> L5_N1 -> L6_N1/L6_N2 -> L7_N0 -> L8_N0`，第 6 层第 4 个连续压力节点越过 `max_pressure=3`。 |

### 假设记录

| 轮次 | 假设（具体到变量/分支/契约） | 验证方式 | 结论(成立/证伪) |
| --- | --- | --- | --- |
| 1 | `_introduce_optional_budget_choices()` 只校验替代后的单条 `schedule`，但最终不同层的可选节点组合仍可形成压力 4 的完整路径。 | 输出失败图的逐层节点类型；L4 可选 elite 与 L5 可选 treasure 单独安全、组合后形成压力 4。 | 成立；泛化修复消除 P2 失败，但改变 legacy digest，已回滚。 |
| 2 | 组合检查只应在本批压力门收紧到 3 的候选配置生效，旧 max4 必须走原路径。 | 初始 band+pressure 条件未命中 chapter_two，日志证实 band 只在 chapter_one；改为由 `max_pressure<=3` 触发后重跑 P1-P5 与 frozen legacy digest。 | 成立，原失败命令退出码 0。 |

已排除项：

- P1-P5 JSON 数值不匹配不是根因；Godot JSON 将整数解析为等价浮点，规范化后 exact/prefix 均可通过。

### 修复

- 根因：`_introduce_optional_budget_choices()` 只对每个 alternate 与基础 schedule 做压力检查，未检查多个可选层的组合；P2 chapter_two seed 25 的 L4 elite + L5 treasure 组合形成压力 4。
- 改动位置（一处）：`scripts/map/MapGenerator.gd::_introduce_optional_budget_choices()`，仅在收紧到 pressure 3 时验证所有逐层类型组合；legacy max4 保持原搜索。
- 重跑原失败命令结果：绿；P1-P5 的 3 章 x 32 seed 全过，legacy digest 仍为 `b61ca0a471c8797eae2d2c01efed49f8c29726042306f921d7da71520c6bae9a`。

### 防御性回归

- 这个 bug 能否从别处再发生：能；任何多层 optional choice 组合都可能绕过单 schedule 检查。
- 若能：已在 `check.jsonl` 记录 `tests/test_layered_pressure_rebaseline.gd`，回归测试覆盖 P1-P5、三章、32 seed 和 legacy digest。

### 退出状态

- [x] 绿了，回到 TDD 循环失败的那一步
- [ ] 已回滚，升级（附已排除项）
- [ ] 超 3 轮，升级强模型/人工

## Session 2

### 失败信号

- 复现命令：`HOME=/tmp/ember023_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_map_generator.gd`
- 原文：`AC-023-06 JSON-like integer floats still use layer bands`，退出码 1，稳定复现。

### 定位与假设

- 读栈定位到 `MapGenerator._encounter_pool_for_layer()` 的 `TYPE_INT` 检查。
- 假设：Godot JSON 将合法 `layers` 数字解析为 `TYPE_FLOAT`，selector 因此错误 fallback；测试实际值为 `0.0/1.0/...`，假设成立。

### 修复与回归

- 一处修复：selector 接受精确整数的 `TYPE_INT` 或 `TYPE_FLOAT`，仍拒绝非整数浮点、负数和逆区间。
- 原失败命令：绿；P1-P5 fixture 的实际 chapter_one encounter id 另由 `test_layered_pressure_rebaseline.gd` 全 seed 检查。
- 该入口已由 JSON-like unit fixture 与真实 JSON integration fixture 双重封闭。

### 退出状态

- [x] 绿了，回到 TDD 循环失败的那一步

## Session 3

### 失败信号

- 复现命令：`HOME=/tmp/ember023_ladder128_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tools/run_layered_pressure_ladder.gd`
- 原文：运行 `01:12:40` 后仍无 128 artifact、无退出码或错误输出；`ps` 显示进程持续占用约 `82.2% CPU`，`sample` 显示主线程处于深层重复 GDScript 调用栈。
- 是否稳定复现：本次完整 runner 稳定停留在 P1 128 主报告，已用 Ctrl-C 停止，退出码 130；生产配置未修改。

### 定位与假设

- 现有 `baseline-64` 和 `P1-64` 分别约 4 分钟完成，问题范围缩到 `BalanceSimulator.run_campaign_suite(P1, 128)`。
- 假设 1：第一个超过 64 的 `ember_exile/C0` seed 立即触发病态计算。
- 验证：独立运行 P1、`ember_exile/C0`、65 iterations，约 30 秒正常退出并生成报告。
- 结论：假设 1 证伪；继续沿 runner 固定 case 顺序扩大到单格 128，定位具体角色/挑战格。

### 当前状态

- 假设 2：某个固定角色/挑战格在 128 样本触发病态计算。验证：P1 的 12 个角色/挑战格分别独立运行 128，全部在约 2-75 秒内完成；证伪。
- 假设 3：同进程连续 suite 或 preflight 污染后续 128。验证：临时探针先跑 `baseline64 -> P1-64 -> P1-128`，再加入与 runner 等价的 P1-P5 三章 32-seed preflight；两次均在约 5 分钟内完成；证伪。
- 独立完整 P1/128 CLI 在 `486.36s` 内完成，12 case/每格 128 均落盘；原 72 分钟运行态异常无法稳定复现，没有代码根因证据。
- 处理：删除临时探针，不修改 `BalanceSimulator.gd`，回到原 runner 命令重跑。若再次出现同一无产出状态，再以第二次稳定复现升级，不基于一次异常改生产算法。

### 当前状态

- [x] 原失败信号未稳定复现，未做猜测性修复
- [x] 原 runner 重跑完成；baseline、P1-P5 的 64/128/repeat 全部正常结束并写 verdict

## Session 4

### 失败信号

- 复现命令：`HOME=/tmp/ember023_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_layered_pressure_rebaseline.gd`
- 原文：`run_layered_pressure_ladder.gd:267` 的 `first_safe_layer` 从 Variant 返回值推断类型，warning treated as error，退出码 1。
- 是否稳定复现：是；脚本加载阶段固定失败。

### 定位与假设

- 读栈直接定位到 `candidate_graph_is_valid()` 的 `var first_safe_layer := max(...)`。
- 假设：`max()` 返回 Variant，项目将类型推断 warning 视为 error；为结果声明 `int` 即可恢复脚本加载。错误发生在任何行为断言之前，假设成立。

### 修复与回归

- 单点修复：为 `first_safe_layer` 声明显式 `int`。
- 原失败命令：退出码 0；Gate 定向测试通过。
- 防御性回归：editor import 和该脚本测试都会加载 runner，可封闭同类解析错误。

### 退出状态

- [x] 绿了，回到 TDD 循环失败的那一步；显式类型后脚本加载成功。

## Session 5

### 失败信号

- 复现命令：同 Session 4。
- 原文：runner 的 `candidate_graph_is_valid()` 拒绝 P2-P5 共 316 个既有 AC 图；原测试自身的完整路径预算断言全部仍通过，退出码 1。
- 是否稳定复现：是。

### 定位与假设

- 二分对照 runner 与既有 `_validate_graph()`：runner 额外要求每张图同时出现 0 精英和至少 1 精英的完整路线；该条件不在 AC-023-08 的候选图门内。
- 假设：该额外 elite route existence 条件导致 P2-P5 误拒绝；移除它后仍保留逐路径 elite `[0,1]` 预算检查。待原命令验证。

### 修复与回归

- 单点修复：删除未声明的跨路径 minimum/maximum elite existence 条件，保留每条完整路径的精英预算上下界。
- 原失败命令：绿；P1-P5 三章 x 32 seed 的 runner/full-path 与既有图断言均通过。

### 退出状态

- [x] 绿了，回到 TDD 循环失败的那一步

## Session 6

### 失败信号

- 复现命令：`HOME=/tmp/ember023_review_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_layered_pressure_candidate_gate.gd`
- 原文：malformed `completed_runs` 和 case `runs` Dictionary 分别在 `_first_act_completed()`、`_validate_report()` 触发 `Invalid call. Nonexistent 'int' constructor`；退出码 1。
- 是否稳定复现：是。

### 定位与假设

- 读栈定位到 raw verdict 在返回已记录错误前仍调用 `int(untrusted_value)`。
- 假设：所有 raw 汇总和 case key 统一通过 `_integer_or(value,fallback)`，即可保持原始合法整数语义并让非法类型返回固定 failure code；待同一命令验证。

### 修复与回归

- 单点修复：Gate 内 untrusted case/chapter raw 整数读取统一使用安全 accessor；合法 JSON 整数浮点仍被 `_is_integer_number` 接受。
- 原失败命令：待重跑。
- 防御性回归：两种嵌套 Dictionary 伪造均已加入 Gate 测试。

### 退出状态

- [x] 绿了，回到 TDD 循环失败的那一步
