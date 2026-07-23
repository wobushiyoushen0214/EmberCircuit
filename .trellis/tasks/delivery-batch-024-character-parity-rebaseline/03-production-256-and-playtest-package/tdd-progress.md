# TDD 进度：024-03

| AC ID | 期望可观察结果 | 测试/门 | 状态 |
| --- | --- | --- | --- |
| AC-024-16 | selected-bound 256 前置；无 selected 取消 | campaign matrix test | pending |
| AC-024-17 | pure promotion、legacy mirror、relic文案、非法输入不变 | production promotion test | pending |
| AC-024-18 | 256 primary/repeat/digest/shared hard 全过 | gate + evidence | pending |
| AC-024-19 | static+report keyed matrix、dry-run/apply | campaign matrix verification | pending |
| AC-024-20 | PASS 全量晋级或 FAIL 精确 rollback | static/matrix/map tests | pending |
| AC-024-21 | 真实 6,144 局、全量严格回归、AI/真人隔离 | artifacts + all tests | pending |
| AC-024-22 | 双评审、提交后 alpha.9 构建与校验 | review + package gates | pending |

## 条件状态

- 状态：pending 024-02 selected 128。
- 若前置失败：写 `canceled_no_selected_128_candidate`，其余 AC 不伪造完成。
- 256 artifact/SHA：未开始。
- production/matrix/package：未开始。

## 收尾核对

- [ ] 256 primary/repeat byte-identical 且 digest 已版本化。
- [ ] shared hard、static、map、matrix、全量回归全绿。
- [ ] Stage 1/独立 Stage 2 无阻断。
- [ ] PASS 才有 alpha.9；FAIL 保留 alpha.8。
- [ ] build 未进入 Git，artifact SHA 已回写。

