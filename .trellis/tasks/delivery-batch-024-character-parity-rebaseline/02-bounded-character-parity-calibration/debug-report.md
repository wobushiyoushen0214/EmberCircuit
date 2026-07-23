# 调试报告

## Session 1

### 失败信号

- 复现命令：`HOME=/tmp/ember024_tdd_home /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_character_parity_rebaseline.gd`
- 原文：10 个合法 fixture 的 `AC-024-07 {step} changes are exact` 断言全部失败，进程退出 1。
- 是否稳定复现：是。

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读栈 | `tests/test_character_parity_rebaseline.gd:207,247`；把结构 canonical 改成容器直接 `==` 后，catalog 已接受的全部 10 个 fixture 仍被测试拒绝。 |

### 假设记录

| 轮次 | 假设 | 验证方式 | 结论 |
| --- | --- | --- | --- |
| 1 | Godot JSON 把 fixture 整数解析为 `TYPE_FLOAT`，而测试期望值是 `TYPE_INT`；直接相等和直接序列化都缺少严格整数归一。 | 临时类型日志显示 B0 首值 `payload=3`、`expected=2`；Godot 枚举分别对应 Float/Int。 | 成立 |

已排除项：仅按键排序序列化不能解决数字类型差异。

### 修复

- 根因：测试最小化时删除了 exact integral-float 归一，导致 JSON Float 与期望 Int 的合法差异被误判；近整数又必须保持不归一。
- 改动位置（一处）：`tests/test_character_parity_rebaseline.gd` 的 `_canonical` helper，仅把严格等于整数的 Float 归一。
- 重跑原失败命令结果：绿，退出 0；文件收敛为 399 行。

### 防御性回归

- 这个 bug 能否从别处再发生：不能；仅影响本测试的结构比较写法，生产 catalog 另有独立近整数拒绝用例。

### 退出状态

- [x] 绿了，回到 TDD 循环失败的那一步
- [ ] 已回滚，升级（附已排除项）
- [ ] 超 3 轮，升级强模型/人工

## Session 2

### 失败信号

- 复现命令：冻结 SHA 核对 shell harness。
- 原文：`zsh:16: command not found: git`，随后 `shasum`、`awk` 同样不可用，进程退出 127。
- 是否稳定复现：是；进入循环后首个文件即失败。

### 定位过程

| 用了哪招 | 结果（缩小到哪里） |
| --- | --- |
| 读首个失败点并核对 zsh 变量语义 | 循环变量命名为 `path`；zsh 的 `path` 是与 `$PATH` 绑定的特殊数组，赋文件名会覆盖命令搜索路径。 |

### 假设记录

| 轮次 | 假设 | 验证方式 | 结论 |
| --- | --- | --- | --- |
| 1 | harness 的 `path` 变量覆盖 `$PATH`，与项目内容无关。 | 只把变量改为 `file_path`，其余冻结列表与比较逻辑原样重跑。 | 成立 |

### 修复

- 根因：zsh 特殊变量名冲突。
- 改动位置：仅测试命令内的循环变量；没有改项目代码或证据。
- 重跑结果：10 个冻结文件全部与 `6e0f5f9` 一致，verdict/digest/tree SHA 与冻结值一致，两个 diff check 退出 0。

### 退出状态

- [x] 绿了，回到 TDD 循环失败的那一步
- [ ] 已回滚，升级（附已排除项）
- [ ] 超 3 轮，升级强模型/人工
