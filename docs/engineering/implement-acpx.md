## 它的作用

`implement-acpx` 把一组已经确定的实施 tickets 交给你指定的 Agent，并把结果带回当前会话。它会先整理 tickets、代码库探索和相关资料，再把这些上下文写进目标仓库中的派发 prompt。

目标 Agent 负责实现整组 tickets；当前会话负责把任务交接清楚。你可以检查它收到的依据和完成报告，不必把实现过程留在当前会话里。

## 何时使用

你通过键入 `/implement-acpx` 来调用它：agent 不会主动触发它。

当一组已经确定的 tickets 要交给一个用户指定的 Agent 实现时使用它。需要多个实施 Agent 并行推进一整份 spec 并集成结果时，改用 [implement-spec](https://aihero.dev/skills-implement-spec)。工作尚未拆成 tickets 时，先用 [acpx-to-tickets](https://aihero.dev/skills-acpx-to-tickets)。

## 先决条件

调用时提供 tickets、目标仓库和执行 Agent。若使用 issue 引用，仓库必须已经配置 issue tracker；该配置由 [setup-matt-pocock-skills](https://aihero.dev/skills-setup-matt-pocock-skills) 提供。

技能会在目标仓库保存一份 prompt，记录任务范围、相关文件、来源和完成要求，供目标 Agent 执行。

## 派发 prompt

prompt 是交接的关键：它把 tickets 的验收标准、相关代码与测试路径、spec 和 ADR、外部资料及探索发现放在一起。目标 Agent 可以据此找到证据并实现用户已经决定的工作，而无需猜测当前会话里的隐含背景。

## 常见问题

**我还没有 tickets，可以直接让它把工作拆开吗？**

不行。它只实现已经确定的 tickets，不负责拆票或补写验收标准。先用 [acpx-to-tickets](https://aihero.dev/skills-acpx-to-tickets) 生成并确认 tickets。

**我没有指定执行 Agent，它会自己选一个吗？**

不会。它会先询问目标 Agent；无法连接你指定的 Agent 时会报告阻塞，不会自动换人或在本地接手实现。

**一个目标 Agent 会并行处理 tickets 吗？**

派发 prompt 会列出整组 tickets 和它们的依赖顺序，具体的实现调度由目标 Agent 完成。若你需要本仓库技能负责并行运行实施者并集成到一条分支，用 [implement-spec](https://aihero.dev/skills-implement-spec)。

## 怎样算成功

- 派发 prompt 列出的 ticket 与你指定的集合一致，且每张 ticket 都有来源和验收标准。
- 关键代码、测试、spec、ADR 与外部资料都有可定位的路径或链接。
- 目标 Agent 的报告逐项说明了完成状态、提交或变更、验证结果和阻塞。
- 当前会话不会把未报告或未验证的工作说成已完成。

## 它的定位

`implement-acpx` 是已定 tickets 之后的单 Agent 派发步骤，适合把一组任务交给同一个目标 Agent。它的邻居是 [acpx-to-tickets](https://aihero.dev/skills-acpx-to-tickets)，因为该技能生成它消费的 tickets；[implement-spec](https://aihero.dev/skills-implement-spec) 则适合并行实现整份 spec。拿不准该走哪条路径时，查看 [ask-matt](https://aihero.dev/skills-ask-matt)。
