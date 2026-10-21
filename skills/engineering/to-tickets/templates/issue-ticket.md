# 真实 Issue tracker 模板（派发时必须全文传递）

每张 ticket 发布成一个独立 Issue。若来源是已存在的 Issue 且 tracker 支持子 Issue，则创建时关联父 Issue。正文使用以下结构：

```md
## Parent

<来源父 Issue 的真实引用，仅当来源是已有 Issue 时包含本节>

## What to build

<此 ticket 使哪个端到端行为生效，从用户视角描述，不是分层实现清单>

## Acceptance criteria

- [ ] <可独立验证、在本 ticket 实施前尚未满足的验收标准 1>
- [ ] <可独立验证、在本 ticket 实施前尚未满足的验收标准 2>

## Blocked by

- <每个真实阻塞 Issue 的引用，或 None (can start immediately)>
```

发布时必须删除所有占位文字。平台已经支持并正确创建**原生阻塞边**时，正文省略整个 `## Blocked by` 节；否则保留该节并填写真实 Issue 引用或 `None (can start immediately)`。

如果没有来源父 Issue，则省略整个 `## Parent` 节。Tracker 原生子 Issue 关系与 Parent 引用按其配置规则执行，不得修改或关闭父 Issue。除非用户另有要求，应用已配置的 `ready-for-agent` 标签映射。
