# Design: 022-02 配对路线安全验证

## 编排-计算分离

- 命令与报告编排留在 `verification-report.md` 和测试脚本。
- gate 计算复用 021 的整数计数逻辑，仅把 candidate profile 改为 v3。
- 正式矩阵冻结断言独立于诊断 artifact。

## 挂载点

| 挂载点 | 位置 | 动作 |
| --- | --- | --- |
| profile axis | `tests/test_balance_simulator.gd` | 加入 v3 并移除对 v2 作为 candidate 的硬编码 |
| 64 artifact | `/tmp/ember022-{profile}-64.json` | 四份相同 options |
| conditional 128 | `verification-report.md` | 64 全 PASS 才生成 |
| stop state | `docs/12...`、`.trellis/delivery-state.md` | 记录 pass/fail 和下一动作 |

## 结构健康度预检

测试文件已超过 400 行；只扩展现有 gate helper 和 artifact loader，不新建平行验证框架。
