# 对象模型与状态

| 对象 | 意义 | 权威内容 |
|---|---|---|
| Goal | 最终目标、完成标准与范围 | Map |
| Map | 跨会话规划待办、关联索引、前沿与历史 | 主跟踪项或 `MAP.md` |
| Problem | 不补足就无法实现 Goal 的重大缺口；规划待办主体 | 独立 Problem 记录，Map 仅索引 |
| Tension | Problem 内的真实取舍、约束冲突或重大不确定性；决策推进单位 | Problem 内的命名条目 |
| ADR | 值得长期保留的架构决策及理由；由 `domain-modeling` 判断是否需要并产出 | 该 Skill 所指定的 ADR 位置 |
| SPEC/PRD | 对已作决策的需求与约束进行规格化；由 `to-spec` 产出 | `to-spec` 发布的规格链接 |
| Issue / Ticket | 由 `to-tickets` 拆出的单会话可完成、可验收的实施工作 | 所配置跟踪器中的实施 Issue |

**语义与容器分离：** 在本 Skill 的模型中，“Issue”专指实施 Ticket；但 GitHub 等跟踪器也可能把 Map 或 SPEC 作为 *物理上的 issue* 存储。不能因此把 Problem、SPEC 和实施 Issue 混为同一类业务对象。

## 因果与链接

- Goal 下有多个 Problem；每个 Problem 都必须说明不解决时 Goal 会怎样失败。
- Problem 下有多个 Tension。一个 Tension 归属一个 Problem；其他相关 Problem 用链接引用。
- 一个真实 Tension 可由 `/grilling` 决策；`domain-modeling` 只在满足其标准时产出 ADR。Map/Problem 为 **有 ADR 的决策**记录 ADR 指针；其余记录用户确认的决定与出处，不伪造 ADR。
- 多个决策或 ADR 可汇总为一份 SPEC；同一决策可影响多份规格。每份 SPEC 都由 `to-spec` 自己定格式、存储和链接。
- 实施 Issues 由 `to-tickets` 从已确定的 SPEC 拆分，保留其原生依赖和验收约定。Map 只引用，不复制它们的正文。

## 两种工作前沿

- **决策前沿**：尚待解决、依赖齐备、未认领、可以调查或 `/grilling` 的 Tension。
- **执行前沿**：`to-tickets` 已发布、规格仍有效、前置任务已完成、未认领的实施 Issue。Atlas 管理该列表，默认不实施。

Problem 的**规划状态**（待研究 / 待决策 / 已决策 / 已规格化）与**交付状态**（未开始 / 进行中 / 已验证）分开记录。Tension 可为 `待调查 / 待 grilling / 已决策 / 阻塞 / 重开`。实施 Issue 的真实状态以跟踪器为准，不在 Map 创建第二套独立状态源。

规划完成指核心 Tensions 已处理，所需规格与任务已发布且互相可追溯；这**不等于** Goal 已实施或验收。
