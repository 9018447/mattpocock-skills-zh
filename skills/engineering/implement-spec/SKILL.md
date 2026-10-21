---
name: implement-spec
description: "在代码中实现 /acpx-to-spec 与 /acpx-to-tickets 的产物。"
disable-model-invocation: true
---

你已被提供一份 spec。该 spec 应关联若干 ticket，用以描述如何实现该 spec。

应该已经为你提供了 issue 跟踪器。如果没有，请告诉用户运行 `/setup-matt-pocock-skills`。

目标是整份 spec 在一条**集成分支**上实现完成，每张 ticket 都按 issue 跟踪器关闭工作的方式解决。

这些 ticket 不是一份步骤清单。它们是一张**任务图**，彼此之间存在阻塞关系。这意味着始终存在一个**前沿（frontier）**：可立即被领走的 ticket。

与子智能体之间的通信应保持精简。通信主要通过**上下文指针**：指向 spec、ticket、研究笔记与历史 commit。无需重复指针已经能触达的信息。

**实施者子智能体**应在后台运行，以获得最大并发。

## 派发

所有子智能体经 [acpx](https://github.com/openclaw/acpx) 派发。每个派发任务的完成标准：prompt 逐项填写 `templates/` 下对应模板后写入 `prompts/tNN.md`，日志 tee 到 `.agent-results/<agent>-tNN.log`。模板不得凭记忆重写。

| 模板 | 用于 |
| --- | --- |
| `templates/prompt-implement.md` | 实现票（默认） |
| `templates/prompt-run.md` | 票面标注 `含 N 次真实运行` 或预计真实运行总时长 ≥20 分钟的票 |
| `templates/prompt-test.md` | 实现票闭环后，编排者单独派发的全量测试票 |

- **实施者**：`deepseek harness`、`kimi code`、`omp`或`pi`，都支持 ACP 协议。撞限互补。
- **合并 / 探查 / 测试 / 运行**：`codex`。

异常与恢复协议（额度撞限降级、acpx 静默死亡、中断续作、进程存活核查）在 `references/recovery.md`，命中对应情况才读。

## 步骤

1. 阅读 spec 与 ticket，理解任务图。

2. （可选）使用一个**探查子智能体**完成 ticket 所需的探查工作：相关的代码库文件或外部文档。确保该探查子智能体能够保存文件：它应把 Markdown 笔记保存在仓库之外、所有后续子智能体都能访问的目录中。这让**实施者子智能体**可以专心实现，而非探查。

3. 创建集成分支。如果 issue 跟踪器通过 PR 关闭工作，或者用户要求一个 PR，则在步骤 5 的第一次合并之后开一个 draft PR（一个在 main 之上没有 commit 的分支开不了 PR），并标记为关闭对应的 spec 与 ticket。

4. 使用**实施者子智能体**逐一实现每张 ticket，每个都在自己的 worktree、自有的分支上工作。每张票按「派发」一节的对应模板填写后派发。每个实施者子智能体：
   - 开始前先确认其 worktree 基于集成分支，如果不是则重置到该分支；
   - 调用 Skill 工具并传入 `tdd` 来构建 ticket；
   - 在报告完成之前，把集成分支的顶部合并进自己的分支。

5. 一旦某个**实施者子智能体**完成，使用一个**合并子智能体**将其工作合并进集成分支，本票闭环，随后按 `templates/prompt-test.md` 派发全量测试票。

6. 如果这改变了可领取 ticket 的**前沿**，立刻启动更多**实施者子智能体**去处理新出现的 ticket。这保证了最大并发。

7. 所有 ticket 完成后，对集成分支调用 Skill 工具并传入 `open-code-review-delegete`。用一个**实施者子智能体**一次性修复 code review 提出的全部问题。

8. 如果存在 draft PR，将它标记为 ready for review。否则，按 issue 跟踪器关闭工作的方式逐张解决 ticket，并报告集成分支。

9. 清理所有**实施者子智能体**的 worktree。
