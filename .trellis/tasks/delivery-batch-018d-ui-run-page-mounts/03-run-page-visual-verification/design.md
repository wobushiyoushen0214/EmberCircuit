# Design: 018D-03 视觉验证

## 需求覆盖

| 需求 | 当前 | 设计 | 预期 |
| --- | --- | --- | --- |
| REQ-008 | PARTIAL | 真实五页视觉、旧树删除 | 继续 PARTIAL，页面统一度完成但生产内容美术仍待后续 |
| REQ-012 | DONE | route page regression 扩展 | DONE 保持 |

## 编排-计算分离

| 层 | 元素 | 落点 |
| --- | --- | --- |
| 编排 | gallery setup、route switch profiler | tools scripts |
| 纯计算 | 区域 RGB/changed ratio、performance evaluate_snapshot | 复用现有 verifier/profiler，不新建算法 |
| 运行 UI | 删除无调用旧 helper | Main.gd |

## 挂载点清单

1. 五个标准 gallery capture 进入对应 active_page_id。
2. 五个 visual contract 覆盖语义区域。
3. profiler route loop 实际 mount 五页。
4. docs 四处状态一致。

## 非目标

- 不更换风格、字体、素材，不创建新页面或新测试框架。
