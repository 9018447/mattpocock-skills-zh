# Glossary 与 Glossary Map 模板（派发时必须全文传递）

## 单 context：`GLOSSARY.md`

默认仓库根目录一个 `GLOSSARY.md`。仅在首个已确认术语需要持久化时创建。

```md
# {Context 名称}

{一两句话说明该 context 的职责和存在理由。}

## Language（语言）

**Order**：
{一两句话定义这个概念是什么。}
_Avoid_：Purchase, transaction

**Invoice**：
发送给客户的付款请求（交付后）。
_Avoid_：Bill, payment request

**Customer**：
下单的个人或组织。
_Avoid_：Client, buyer, account
```

### 写入规则

- 对同一个概念选择一个最准确的标准术语，其他同义词列在 `_Avoid_`。
- 一条定义通常一至两句话，描述“是什么”，不是接口、实现或具体任务。
- 只写 context 独有的领域概念；timeouts、错误类型和工具函数等通用编程概念不属于 Glossary。
- 自然出现聚类时按子标题分组；否则使用简洁的平面术语表。
- 对已确认术语就地更新和去重。未确认定义、临时猜测、spec、任务列表、实施决策都不能写入。
- 用户语言与既有 Glossary 矛盾时先查证并澄清，不得静默覆盖。

## 多 context：`GLOSSARY-MAP.md`

如果仓库根目录已存在 `GLOSSARY-MAP.md`，先读取它再确定本次所属 context。术语写入该 context 的 Glossary，不全部堆到根目录。需要新增 context 时先确定其边界；不得为了少数新术语擅自拆分现有模型。

```md
# Glossary Map

## Contexts

- [Ordering](./src/ordering/GLOSSARY.md) — 接收并跟踪客户订单
- [Billing](./src/billing/GLOSSARY.md) — 生成发票并处理付款
- [Fulfillment](./src/fulfillment/GLOSSARY.md) — 管理仓库拣货和发货

## Relationships（关系）

- **Ordering → Fulfillment**：Ordering 发出 `OrderPlaced` 事件；Fulfillment 消费后开始拣货
- **Fulfillment → Billing**：Fulfillment 发出 `ShipmentDispatched` 事件；Billing 消费后生成发票
- **Ordering ↔ Billing**：共享 `CustomerId` 和 `Money` 类型
```

以上名称只是形态示例，不是本项目事实。若只有根目录 Glossary，视为单 context；两者都不存在时先使用单 context 默认，不因本技能被调用而创建空文件。多 context 下归属不明时向用户澄清。
