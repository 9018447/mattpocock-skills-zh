---
name: acpx-to-tickets
description: 通过 acpx 把计划、spec 或对话拆成 tracer-bullet ticket 并发布到项目 issue tracker，执行交给用户明确指定的 Agent；草案先经用户批准，编排者只转交、派发与结果回传。
disable-model-invocation: true
---

# acpx-to-tickets：用户指定 Agent，acpx 纯派发

本 Skill 不绑定任何 Agent。**目标 Agent 必须由用户针对本次任务明确指定**，且只能通过 acpx 派发。编排者是纯派发者：只总结对话、装配 prompt、回传结果，不分析代码、不拆 ticket、不设计阻塞边、不编写验收标准，也不发布 issue。

## 前置条件

- 目标 Agent 必须来自用户的明确指示：当前请求，或当前对话中明确适用于本次任务的指定。没有指定时，只询问“要派发给哪个 Agent？”，然后停止。
- 项目的 issue tracker 与分类标签词汇应已提供；缺失时提示运行 `/setup-matt-pocock-skills` 并停止。不猜测 tracker、项目或标签。
- 仅用用户指定的 Agent 标识做 acpx 路由，不改名、不替换、不兜底切换。目标 Agent 无法通过 acpx 使用时报告阻塞，请用户重新指定，不改成本地执行。

## 派发流程

1. **确认目标 Agent**。按前置条件取得用户指定的标识。完成标准：拿到 Agent 标识。
2. **总结上下文为 prompt 并落盘**。把计划、spec 或对话中已确定的信息输入整理成派发 prompt，使用`\writing-for-agents`写入项目目录下的 prompt 文件（如 `prompts/`），并指向相关的 ADR 和 spec。只总结用户说过的内容，不添加对话之外的推断。prompt 中显式写明五点：
   - 触发 `\to-tickets` skill（执行侧技能名，保持无前缀），由目标 Agent 拆分为 tracer-bullet issue 并生成阻塞关系；
   - **用户对话上下文和仓库探索**的详细总结(重要)
   - 相关 ADR 和 spec 的位置；
   - 产出直接落盘到项目目录，无需回询确认；
   - 目标 Agent 是执行末端，不得继续向下派发，不得使用 acpx 或 subagent。
   完成标准：五点齐备，prompt 脱离当前对话仍能独立交代任务。
3. **派发给目标 Agent**。交给用户指定的 Agent 执行，编排者不接管、不代写。完成标准：拿到目标 Agent 的拆票草案。
4. **转交草案并取得批准**。告诉用户草案位置；Agent 的建议或编排者的判断都不能代替用户批准。完成标准：用户明确批准，或流程在此停止。

## 产出与用户确认

用户确认即完成。草案未获得批准，编排者按异议做小修 tickets 后再确认；小修只限用户指出的异议本身,除非用户明确要求，否则不再重新派回Agent.
