# 工程技能（Engineering）

日常编码工作中使用的技能。

## 用户调用（User-invoked）

只有你输入它们时才可达（Claude Code：`disable-model-invocation: true`；Codex：`agents/openai.yaml` 中的 `policy.allow_implicit_invocation: false`）。

- **[ask-matt](./ask-matt/SKILL.md)**：询问哪个技能或流程适合你的情况。本仓库中用户调用技能的路由器。
- **[grill-with-docs](./grill-with-docs/SKILL.md)**：盘问式会话，同时构建你项目的领域模型，内联打磨术语并更新 `GLOSSARY.md` 和 ADR。
- **[triage](./triage/SKILL.md)**：让 issue 走一遍由分类角色组成的状态机。
- **[improve-codebase-architecture](./improve-codebase-architecture/SKILL.md)**：扫描代码库寻找深化机会，以可视化 HTML 报告呈现，然后对你挑中的那个进行盘问。
- **[setup-matt-pocock-skills](./setup-matt-pocock-skills/SKILL.md)**：为本仓库配置工程技能（issue 跟踪器、分类标签、领域文档布局）。每个仓库运行一次。
- **[acpx-domain-modeling](./acpx-domain-modeling/SKILL.md)**：通过 acpx 派发给用户指定的 Agent，核对术语并维护 Glossary 与必要的 ADR。
- **[acpx-to-spec](./acpx-to-spec/SKILL.md)**：通过 acpx 派发给用户指定的 Agent，把当前对话整理为 spec 并发布 Issue。
- **[acpx-to-tickets](./acpx-to-tickets/SKILL.md)**：通过 acpx 派发给用户指定的 Agent，将计划或 spec 拆成 tracer-bullet Issues；批准拆票草案后再发布并创建阻塞边。
- **[implement-acpx](./implement-acpx/SKILL.md)**：通过 acpx 将一组已确定的 tickets 派发给用户指定的 Agent 实现。
- **[implement-spec](./implement-spec/SKILL.md)**：在一条集成分支上实现整份 spec。把 ticket 当任务图推进，在可领取的前沿并行运行实施者子 agent 以获得最大并发，最后以 `/code-review` 收尾。
- **[problem-atlas](./problem-atlas/SKILL.md)**：为跨会话的大型项目维护一份目标/问题地图：记录 Goal、Problem、核心矛盾与双工作前沿，基于研究与你的决策更新 ADR、SPEC 与实施 issue，并把产物生成交给 `acpx-domain-modeling`、`acpx-to-spec`、`acpx-to-tickets`。
- **[wayfinder](./wayfinder/SKILL.md)**：把一大块工作（超过一个 agent 会话能容纳的量）规划成 issue 跟踪器上一张由决策 ticket 组成的共享地图，逐个解决，直到通往目的地的道路清晰。
- **[retro](./retro/SKILL.md)**：在一次会话之后，为编码 agent 的**环境**（导航、自动化检查、编码规范、引导文件、工具）提出改进建议，按严重程度排序。

## 模型调用（Model-invoked）

模型或用户均可调用（丰富的触发措辞，让模型能主动拿起来用）。

- **[prototype](./prototype/SKILL.md)**：构建一次性原型回答设计问题：一个可分享的 HTML 文件用于状态/逻辑，或几个可切换的 UI 变体。

- **[diagnosing-bugs](./diagnosing-bugs/SKILL.md)**：针对疑难 bug 和性能回归的训练有素的诊断循环：构建一个对*这个* bug 变红的反馈循环 → 最小化 → 假设 → 插桩 → 修复 → 回归测试。
- **[research](./research/SKILL.md)**：对照高信任度的一手来源调查问题，并把发现作为带引用的 Markdown 文件留在仓库里，作为后台 agent 运行。
- **[tdd](./tdd/SKILL.md)**：带红-绿-重构循环的测试驱动开发。一次一个垂直切片地构建功能或修复 bug。
- **[codebase-design](./codebase-design/SKILL.md)**：设计深度模块的共享训练和词汇：小接口、干净接缝、通过接口可测试。
- **[code-review](./code-review/SKILL.md)**：对自某个固定点以来的 diff 做双轴审查：**标准**（是否遵循仓库的编码标准，外加 Fowler 坏味道基线？）和**规格**（是否忠实实现了源 issue/spec？），作为并行子代理运行。
- **[pr](./pr/SKILL.md)**：PR body 应有的形状：以能说清变更的最小可视化做摘要，加上证明其可行的 before/after 证据，再加上合并风险判断（单向门或双向门，外加爆炸半径）。
- **[wizard](./wizard/SKILL.md)**：生成一个交互式 bash 向导，引导人完成只有他们能执行的步骤：配置基础设施、设置凭据或 CI 密钥、走一遍陌生的第三方仪表盘，或执行一次性的迁移或切换。
