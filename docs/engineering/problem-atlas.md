## 它的作用

`problem-atlas` 为跨多个 [session](https://www.aihero.dev/ai-coding-dictionary/session) 的大型项目维护一张权威的规划地图（**Map**）：终点记为 **Goal**，Goal 之下是以 **Problem**（不补足就无法实现 Goal 的重大缺口）为单位的规划待办，每个 Problem 内以 **Tension**（真实的取舍、约束冲突或重大不确定性）为决策推进单位。

它只维护地图，不写产物：ADR、[SPEC](https://www.aihero.dev/ai-coding-dictionary/spec) 和实施 Issues 由各自的专用技能生成，Atlas 登记的只有证据、状态、依赖、指针和决策变更历史。这条纪律把它和"替你规划一切"的默认想象区分开：地图是索引，不是第二套文档。

## 何时使用

你通过键入 `/problem-atlas` 来调用它：[agent](https://www.aihero.dev/ai-coding-dictionary/agent) 不会主动触发它。

当规划本身成为需要长期维护的对象时用它：问题会不断生长，新决策会推翻已发布的规格，你要随时能回答"现在该做什么"。它和 [wayfinder](https://aihero.dev/skills-wayfinder) 各管一种"大"：

| 你面前是什么 | 跑什么 |
| --- | --- |
| 一块大到一次会话装不下、路线仍不清楚的工作 | [wayfinder](https://aihero.dev/skills-wayfinder)：解到路线清晰就交班，地图随之完结 |
| 一个跨会话持续演进的项目，规划需要一本长期账 | `/problem-atlas` |
| 决策已经做完、只差规格化的一段对话 | [acpx-to-spec](https://aihero.dev/skills-acpx-to-spec)：直接进主干流程，不需要地图 |

## 先决条件

它是有状态的技能，写入两处：Map 本身（一个带 `problem-atlas:map` 标签的跟踪项，或一份 `MAP.md`）和 Problem 记录（默认 `docs/problem-atlas/problems/<slug>.md`）。优先接一个已配置的 issue 跟踪器，由 [setup-matt-pocock-skills](https://aihero.dev/skills-setup-matt-pocock-skills) 配置；没有可用后端时可以退化为本地 Markdown，但不伪造远程 issue 编号或链接。

## 地图上有什么

- **Goal**：最终要达到的状态、成功判据、范围与硬约束。
- **Problem**：达成 Goal 的必要缺口，每条都要说明不解决时 Goal 会怎样失败；同时记两个不混淆的状态：规划（待研究 / 待决策 / 已决策 / 已规格化）与交付（未开始 / 进行中 / 已验证）。
- **Tension**：Problem 内的真实取舍，一个 Tension 只归一个 Problem，相关联的其他 Problem 用链接引用。
- **决策变更历史**：原决定、新决定、原因与确认来源，以及被波及的 SPEC 和 Issues。

两条**工作前沿**是地图的出口：**决策前沿**列出依赖齐备、未认领、可以调查或进入 [grilling](https://www.aihero.dev/ai-coding-dictionary/grilling) 的 Tension；**执行前沿**列出 acpx-to-tickets 已发布、规格仍有效、前置任务已完成的实施 Issue。任何时刻打开地图，两边各能说出一个明确的下一步。

## 它只登记，不写产物

- ADR 由用户显式调用 [acpx-domain-modeling](https://aihero.dev/skills-acpx-domain-modeling)、指定 Agent 并经 acpx 派发后判断和产出；Atlas 只登记路径与出处，没有 ADR 的决定记录用户确认及其来源。
- SPEC 由 acpx-to-spec 发布，可能在跟踪器里表现为一个规格 issue，但不是实施 [ticket](https://www.aihero.dev/ai-coding-dictionary/ticket)。
- 实施 Issues 由 [acpx-to-tickets](https://aihero.dev/skills-acpx-to-tickets) 拆出，保留其原生依赖与验收约定；Map 只引用，不复制正文。

交接之后，真实路径或 ID 必须**写回地图**。新决策使已发布的 SPEC 或实施 Issue 失效时，受影响任务标记待复核，复核完成前不得继续执行。实施 Issue 的真实状态以跟踪器为准：地图副本过期时，跟跟踪器走。

## 常见问题

**它和 wayfinder 到底差在哪？**

wayfinder 面向一块工作：地图清空、路线清晰，它就交班，地图随之完成。problem-atlas 面向一个项目：Map 是常设账本，问题生长和决策变更会持续刷新两条前沿。一次性的大工作用 wayfinder；要长期维护，建 Atlas。

**能让它顺手把 SPEC 和 ticket 也生成了吗？**

不能。格式、存放位置和发布规则归各自的技能管，Atlas 再写一套就出现两个真相来源。它的职责是把 Tension 推进到可以直接交接的程度，然后把真实链接登记回地图。

## 怎样算成功

- 打开 Map，决策前沿和执行前沿各能指出一个明确的下一步。
- 每条已确认的决策都能追到来源：一个 ADR 路径，或一条带出处的用户确认记录。
- SPEC 和实施 Issues 的链接在地图上真实可解析，且随决策变更保持更新。
- 一个被推翻的决策让受影响的任务显示待复核，而不是继续被执行。

## 它的定位

一个常设的规划层。它不在 grill-with-docs → acpx-to-spec → acpx-to-tickets → implement 这条主干链上，而是从项目层面喂养这条链：把规划待办和两条前沿维护到随时可以交接的程度。最近的邻居是 wayfinder，它解的是一块看不清路的工作，解完即止；当规划本身成为长期对象，就轮到 Atlas。整张技能地图见 [ask-matt](https://aihero.dev/skills-ask-matt)。
