# Implementation Plan: 024-03

## 文件计划

| 步骤 | 文件 | 操作 | 验证 |
| --- | --- | --- | --- |
| 1 | promotion helper/test | new | selected/invalid/deep-copy/legacy/relic RED→GREEN |
| 2 | sync helper/test | new | 256/repeat/hard/static/keyed rows RED→GREEN |
| 3 | CLI/test | new | dry-run/no-write/atomic apply RED→GREEN |
| 4 | production/tree/tests/docs | conditional | PASS apply 或 exact rollback |
| 5 | all tests/review | run | static/map/full regression + Stage 1/2 |
| 6 | version/build/docs/state | conditional PASS | alpha.9 export/archive verification |

## 结构健康度预检

- 超阈值 `Main.gd` 只改一行版本常量；`test_numerical_balance_matrix.gd` 只改 024 状态 dispatcher。
- 新 promotion/sync/CLI/test 分文件，不把纯逻辑塞进 runner。
- 不执行“只搬不改”微重构：跨 14k Main 或既有 matrix test 的搬迁会扩大 File Manifest 风险；由定向薄改和全量回归守住行为。

## 有序步骤

0. 验证 024-02 selected 128、评审报告与 compact evidence；记录五生产 JSON、tree 和版本入口 bytes/SHA。
1. 写 promotion 所有失败测试后实现 pure deep-copy；先不落生产。
2. 写 sync 的 128/repeat/identity/hard/static/row-source RED；实现 pure helper。
3. 写 CLI dry-run/no-write/temp validation/atomic apply RED；实现薄 I/O。
4. 生成真实 256 primary/repeat、比较 byte、写 digest、跑 shared hard；失败立即走 rollback。
5. PASS 时在内存构建 promotion+tree，先对临时输出跑 static/map/matrix；全部绿才原子应用。FAIL 只写证据 metadata/docs。
6. 跑定向和全部 `tests/test_*.gd`、freeze、AI/真人隔离；更新 tdd-progress，执行 Stage 1/独立 Stage 2。
7. 评审无阻断后由外层提交/合并；PASS 才升级四版本入口、构建/验证 alpha.9，并用第二个发布证据提交回写 SHA。

## 修改边界

- 只允许 PRD File Manifest 与任务流程产物；build zip 是忽略产物。
- 024 hard gate、candidate fixtures、full reports、cards/enemies/encounters/challenges/CombatState、真人原始报告禁止修改。
- 失败分支不得改 alpha.8 版本入口或生成 alpha.9。

## 失败恢复

- 前置缺失：canceled，零写入。
- 256/repeat/digest/hard 失败：保留证据，恢复起点，package=false。
- promotion/static/sync 失败：不 apply 临时结果；原 tree/五 JSON bytes 保持，进入系统调试。
- apply 后回归失败：用步骤0的 bytes 恢复五 JSON/tree/version入口，保留 artifacts，package=false。
- package 验证失败：保留已提交源码，删除不完整临时目录而不覆盖 alpha.8；不登记 artifact delivered。

