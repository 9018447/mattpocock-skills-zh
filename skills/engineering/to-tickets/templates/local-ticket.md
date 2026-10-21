# 本地 Ticket 模板（派发时必须全文传递）

每张 ticket 一份独立文件，使用 `.scratch/<feature-slug>/issues/<NN>-<slug>.md`。`NN` 按依赖优先的顺序从 `01` 递增。正文严格使用以下结构：

```md
# <NN>: <Ticket 标题>

**What to build:** 此 ticket 使哪个端到端行为生效。从用户角度描述，而非逐层实现清单。

**Blocked by:** 制约此 ticket 的其他 ticket 的编号及标题，或 "None (can start immediately)"。

**Status:** ready-for-agent

- [ ] 可验证、且在实施前不应已成立的验收标准 1
- [ ] 可验证、且在实施前不应已成立的验收标准 2
```

按实际需要增加验收标准，但不要把全部 ticket 合在一份文件中。阻塞引用必须匹配实际编号。此模板的具体目录布局是 tracker 约定，不与“禁止在 ticket 描述中写实现文件路径”的规则冲突。
