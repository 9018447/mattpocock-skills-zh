---
name: implement-spec
description: "在代码中实现 /to-spec 与 /to-tickets 的产物。"
disable-model-invocation: true
---

## Workflow 模式（默认）

编排逻辑已固化为三份 specify workflow（`workflows/`，按票型分：实现 / 运行 / 全量测试），派发降级链、模板填装、考卷拼装与票级 jev 审查由 `scripts/` 承担。前置：`specify`（≥1.1）、`gh`、`acpx`、`jev-decide`、`python3` 可用，任一缺失走下方旧版编排。改动本目录后先跑 `scripts/self-check.sh`。

编排者职责四步：

1. **开工**：创建集成分支，写整体目标文件（一段话说清 spec 目标与当前主要矛盾），然后 `specify workflow run workflows/implement.yml -i repo_root=<主检出绝对路径> -i integration_branch=<分支名> -i spec_goal_file=<目标文件> --json` 记录 run_id；若存在 run 类票，同时 `run workflows/run.yml ...`。要求 PR 时加 `-i open_pr=true`；换派链用 `-i agents="kimi dsh"`（空格分隔短名或 ACP 桥路径，默认 omp→kimi→dsh）。
2. **守护**：`specify workflow status <run_id> --json` 查进度；run `failed` 时按 `references/recovery.md` 处置，然后 `specify workflow resume <run_id> --json`。
3. **收尾**：implement 与 run 均完成后 `run workflows/test.yml ... -i ticket=<测试票号>`；对集成分支调用 `open-code-review-delegate` 终审，把问题建成 issue，再跑一次 implement.yml 消化；全部闭环后 PR ready。
4. **升级**：修复轮用尽仍 failed 的 run、test 票 jev 不通过，报告用户裁决。

workflow 语法与 run/resume 语义见上游参考 <https://github.com/github/spec-kit/blob/main/docs/reference/workflows.md>。注意：该页示例把 `steps`/`inputs` 写在 `workflow:` 之下，1.1.x 引擎实际从顶层读取，以 CLI 为准。

## 旧版编排（回退）

specify workflow 引擎不可用，或同一 run 反复 failed 无法恢复时，读 [references/prompts-fallback.md](./references/prompts-fallback.md) 并按其执行，一字不差照旧。

