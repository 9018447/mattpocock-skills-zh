---
name: implement-spec
description: "在代码中实现 /to-spec 与 /to-tickets 的产物。"
disable-model-invocation: true
---

## Workflow 模式（默认）

编排逻辑已固化为三份 specify workflow（`workflows/`，按票型分：实现 / 运行 / 全量测试），派发降级链、模板填装、考卷拼装与票级 jev 审查由 `scripts/` 承担。**票源是本地 markdown 票文件**（issue 跟踪器的 `.scratch/**/issues/*.md`，文件名以「数字-」开头）：编排者每次运行显式给定票清单（合法 JSON），脚本与引擎对票库零扫描、票面零远程查询——远端托管（GitHub 或其他）与本技能的票源无关。**派发链是活的决定，逐票显式指定**：每张票的清单元素携带当次存活的 agent 链（`{"file":…,"agents":"…"}`），撞限、停用、额度未恢复的不进链，技能不写死默认链——preflight 对缺 agents 的票直接拒跑。prompt 按票面生成：票面正文进「任务背景」，票面类型标签选工作原则。`gh` 仅 `open_pr=true` 的 PR 收尾需要。前置：`specify`（≥1.1）、`acpx`、`jev-decide`、`python3` 可用，任一缺失走下方旧版编排。改动本目录后先跑 `scripts/self-check.sh`。

编排者职责五步：

1. **列票**：开工前通读 issue 跟踪器全部目录的 `Status:` 行，向用户呈现开放票全清单，并确认本次范围的票与其他未闭票互不重叠——范围只装本次 spec 的票。（参考命令：`grep -riH -m1 -E '^\*{0,2}status\*{0,2}:' <repo>/.scratch/*/issues/*.md`）
2. **开工**：从范围里挑出当前无阻塞的票作为第一波（被阻塞的票等阻塞票闭后再起一波），创建集成分支并把主检出停在其上（lifecycle 把票分支合并进主检出的当前分支），提交票文件与整体目标文件（一段话说清 spec 目标与当前主要矛盾）后再建 worktree，然后 `specify workflow run workflows/implement.yml -i repo_root=<主检出绝对路径> -i integration_branch=<分支名> -i spec_goal_file=<目标文件> -i ticket_files='[{"file":"<票1绝对路径>","agents":"<当次存活链>"},…]' --json` 记录 run_id。链写当次存活的短名（omp-acp/kimi/dsh/codex/zcode，空格分隔）或 ACP 桥路径，按票面性质与各 agent 当前状态逐票分工；本波含 run 类票时同时 `run workflows/run.yml ...`。要求 PR 时加 `-i open_pr=true`。
3. **守护**：run 启动后先确认 `.worktrees/tNN` 出现再进入长等（引擎 `--json` 只在结束时输出）；之后 `specify workflow status <run_id> --json` 查进度；run `failed` 时按 `references/recovery.md` 处置，然后 `specify workflow resume <run_id> --json`。
4. **收尾**：按阻塞图起后续波次直至范围内票全闭环；implement 与 run 均完成后 `run workflows/test.yml ... -i ticket_file=<全量测试票路径>`；对集成分支调用 `open-code-review-delegate` 终审，把问题建成 issue，再跑一次 implement.yml 消化；全部闭环后合流：`open_pr=true` 时 PR 标 ready；否则由编排者把集成分支合并回 main。
5. **升级**：修复轮用尽仍 failed 的 run、test 票 jev 不通过，报告用户裁决。

workflow 语法与 run/resume 语义见上游参考 <https://github.com/github/spec-kit/blob/main/docs/reference/workflows.md>。注意：该页示例把 `steps`/`inputs` 写在 `workflow:` 之下，1.1.x 引擎实际从顶层读取，以 CLI 为准。

## 旧版编排（回退）

specify workflow 引擎不可用，或同一 run 反复 failed 无法恢复时，读 [references/prompts-fallback.md](./references/prompts-fallback.md) 并按其执行，一字不差照旧。
