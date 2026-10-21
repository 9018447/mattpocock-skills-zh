---
name: to-tickets
description: 通过 acpx 将计划、spec 或对话拆分为 tracer-bullet Issues 的任务派发给用户明确指定的 Agent；先转交拆票草案取得用户批准，再由同一 Agent 发布 Issues 和阻塞关系。
disable-model-invocation: true
---

# To Tickets：用户指定 Agent，acpx 纯派发

本 Skill 不绑定任何 Agent。**目标 Agent 必须由用户明确指定**，只能通过 **acpx** 派发。编排者不分析代码、不拆 ticket、不设计依赖边、不编写验收标准，也不发布 Issue。

## 前置条件

- 目标 Agent 必须来自用户对本任务的明确指定（可沿用当前对话中明确适用于本任务的指定）。没有指定时只询问目标 Agent 并停止；不得默认 Kimi 或自行选择。
- 项目的 issue tracker 与分类标签词汇应已提供；若缺失，提示运行 `/setup-matt-pocock-skills` 并停止。不猜测 tracker、项目或标签。
- 目标 Agent 无法通过 acpx 使用时报告阻塞，不更换 Agent、不回退本地执行。
- **发布前必须取得用户对拆票草案的批准**。Agent 的建议或编排者的判断都不能代替用户批准。

## 职责边界

**编排者**：确认 Agent 和 tracker 配置、传递已有对话与来源引用、装配完整强制文件、经 acpx 派发、转交草案给用户审批、将用户的批准或修改意见续派给同一 Agent、回传执行结果。

**目标 Agent**：读取完整源 spec/计划/Issue 及评论、检查仓库和 ADR、设计 tracer-bullet 垂直切片、验证阻塞边、起草方案、根据用户反馈修改、经批准后在正确 tracker 发布并设置标签及依赖。

编排者不得自行获取来源并据此拆票、改动草案、推导依赖或验收标准、创建文件/Issue，也不得在 Agent 失败时接管。

## 必须全文交付给 Agent 的文件

每一次派发（包括审批后的继续执行）必须先读取并将以下三个文件的**完整原文**放入 acpx 消息：

1. `references/agent-instructions.md`：读取来源、垂直拆分、重构例外、审批门槛、各 tracker 发布要求及结果协议。
2. `templates/local-ticket.md`：本地文件式 ticket 的完整模板。
3. `templates/issue-ticket.md`：真实 Issue tracker 的完整模板。

这些文件是目标 Agent 的强制执行契约。不得只传路径、文件名、链接、摘要或“请自行阅读”，不得改写、截断或省略。无法完整传递时停止派发并报告。

## 两阶段派发

### 阶段 A：草案

1. 确认用户指定的目标 Agent 和 issue tracker 配置。
2. 从当前对话忠实提取已有目标、spec/ADR、决策、限制和用户提供的源 Issue ID、路径或 URL；不擅自填充未知事实。
3. 通过 acpx 派发，消息按顺序包含：
   - `【目标 Agent】`：用户指定的精确 Agent 标识。
   - `【任务上下文和来源】`：对话事实、项目配置、spec/ADR/计划及原始引用。
   - `【执行阶段】`：`draft_only`，禁止发布。
   - `【Agent 执行指令｜必须遵守】`：reference 全文。
   - `【本地 Ticket 模板｜必须严格使用】`：local template 全文。
   - `【Issue Ticket 模板｜必须严格使用】`：issue template 全文。
   - `【交付指令】`：返回带编号的完整草案、每张 ticket 的交付行为及依赖，状态为 `needs_approval`。
4. 将 Agent 返回的草案原样呈现给用户，征求粒度、阻塞边、合并和拆分的意见。此阶段**不创建 Issue 或本地 ticket 文件**。

### 阶段 B：批准后发布

5. 用户要求调整时，把完整反馈连同原始草案、原任务上下文、三个强制文件的全文再次经 acpx 派发给**同一 Agent**，执行阶段仍是 `draft_only`；反复进行，直到获得明确批准。
6. 用户明确批准某一确定版本后，再经 acpx 向同一 Agent 派发 `publish_approved`，附上**获得批准的草案全文、用户批准内容、原始来源信息和三个强制文件全文**。不得让 Agent 在缺少被批准版本时发布。
7. 仅根据 Agent 的实际返回反馈已发布的 ticket 列表、Issue 链接、阻塞关系与标签状态；若部分失败，如实报告并停止，不自行修复或声称成功。

## 硬性约束

- 只通过 acpx 派发给用户明确指定的 Agent。本 Skill 不定义 acpx 命令。
- **references 和 templates 全文传递**是草案、修改和发布阶段都不可绕过的条件。
- **无用户明确批准，不发布任何 tickets**。用户要求修改不等于批准。
- 不得关闭、修改源父 Issue；目标 Agent 负责创建子 Issue（tracker 支持时）。
- 除非用户明确另有指示，已发布 ticket 应使用配置中 `ready-for-agent` 的真实标签映射，无需再次分诊。
