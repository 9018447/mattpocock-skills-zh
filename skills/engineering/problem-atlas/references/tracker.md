# Map、Problem 与跟踪器

Problem Atlas 管理的是**索引与追溯**，不接管 `acpx-domain-modeling`、`acpx-to-spec` 或 `acpx-to-tickets` 的文档格式、存放位置、发布标签和依赖规则。

先读取仓库的 `docs/agents/issue-tracker.md`，按其中适用的 Map/Wayfinding 与 Issue 操作执行；若未配置，提示使用 `/setup-matt-pocock-skills`。无可用后端时可将 Map 与 Problem 保存为本地 Markdown，但不能伪造远程 issue 编号或链接。

建议 Map 用一个带 `problem-atlas:map` 标签的跟踪项（或 `MAP.md`）存储。Problem 作为独立记录，用 Map 上的命名链接索引；默认可用 `docs/problem-atlas/problems/<slug>.md`，若仓库已有组织约定则遵循之。Tension 是 Problem 内的命名条目，不创建实施 Issue 来替代它。

**产物由各自的 Skill 发布：**

- ADR 与领域术语由 `acpx-domain-modeling` 管理，Atlas 只登记现有路径和决定的出处。
- SPEC 由 `acpx-to-spec` 发布，可能在 Issue 跟踪器中表现为规格 issue，但不是实施 Ticket。
- 实施 Issues 由 `acpx-to-tickets` 发布，使用其原生父子、阻塞和验收机制；Atlas 不另行创建模板或强加 `problem-atlas:issue` 标签。

## 状态与并发

- 开始解决 Tension 前检查状态，并在跟踪器或 Problem 记录中写入认领；已认领的工作不进入决策前沿。
- 每个 Problem 只保留必要摘要、Tension 状态及 ADR/SPEC/Issue **指针**。Map 不复制研究内容、规格正文或任务描述。
- 优先使用跟踪器原生分配、子项及阻塞关系。查询执行前沿时以 `acpx-to-tickets` 发布的真实状态为准，而不是 Map 中可能过期的副本。
- 创建或链接对象必须使用其真实路径或 ID；在人类可读内容中用标题包裹链接，避免裸编号墙。
- 新决策可能使已发布 SPEC 或实施 Issue 失效：记录旧/新决策及关联位置，将受影响任务标记 `待复核`（依跟踪器能力），复核完成前不得继续执行。
