---
name: problem-atlas
description: 为跨会话大型项目维护 Goal、Problem、核心矛盾与双工作前沿；基于研究和用户决策追踪 ADR、SPEC 与实施 Issues，并把产物生成交给 acpx-domain-modeling、acpx-to-spec、acpx-to-tickets。
disable-model-invocation: true
---

# Problem Atlas

**管理规划，不代替其他 Skill 写产物。** Map 是项目的权威待办索引：以 **Problem**（达到 Goal 必须填补的缺口）为待办主体，以 **Tension**（主要矛盾或重大不确定性）为决策推进单位。ADR、SPEC 和实施 Issues 都由现有专用 Skill 生成；本 Skill 只维护证据、状态、依赖、指针和历史。

## 创建地图

1. 确认 Goal、成功标准及范围；搜索外部信息，检查仓库与既有决策。按需用 `/how` 调查当前机制、`/why` 追溯历史原因，区分事实、推断与假设。
2. 从不同视角倒推达成 Goal 所必需的 Problems，指出每个 Problem 中可以准确表述的 Tensions、前置依赖和待查证的问题。不要虚构矛盾或过早拆分实施任务。
3. 按 [Map 模板](assets/templates/map.md) 建立索引，必要时创建 [Problem 记录](assets/templates/problem.md)，展示问题集与决策前沿。**建图后停止；不自动进入 `/grilling`。**

## 推进地图

1. 读取 Map，选取用户指定或第一个未阻塞、未认领的 Tension；先认领，再调查。具体状态和追溯规则见 [model.md](references/model.md) 与 [tracker.md](references/tracker.md)。
2. 检索事实、验证推理，并以 `/grilling` 和用户解决真实取舍；涉及领域语言或架构决策时，提示用户显式运行 `/acpx-domain-modeling` 并指定执行 Agent，通过 acpx 处理文档沉淀；本 Skill 不自行调用该用户调用型 Skill。**仅由获派发的 `acpx-domain-modeling` Agent 决定是否值得形成 ADR**；没有 ADR 的决定仍须记录来源与确认历史。
3. 决策足够明确、需要多会话实施时，准备 Goal、Problem、已确认决策、ADR 指针及范围约束，交接给 **`/acpx-to-spec`** 生成 SPEC；再交接给 **`/acpx-to-tickets`** 生成单会话实施 Issues。**不套用本 Skill 的 ADR、SPEC 或 Issue 模板。**
4. `acpx-domain-modeling`、`acpx-to-spec`、`acpx-to-tickets` 都需要用户显式调用并指定派发 Agent；提示用户运行对应命令，获得产物后再把真实链接、依赖及最新状态写回 Map。不要声称已自动运行。默认不执行 Issues。
5. 更新 Problem、决策变更历史、**决策前沿**与**执行前沿**；变更已确认决策时追踪受影响的规格及 Issues。默认每次只推进一个 Tension。

## 按需读取

- [workflow.md](references/workflow.md)：证据、`/grilling`、技能交接和变更管理。
- [model.md](references/model.md)：术语、权威内容和状态判定。
- [tracker.md](references/tracker.md)：地图持久化、并发认领、依赖与前沿查询。
- `assets/templates/` **只有 `map.md` 和 `problem.md`**；产物格式遵循被调用 Skill 自身的规则。
