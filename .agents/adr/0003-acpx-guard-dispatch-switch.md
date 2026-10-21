# acpx 派发门禁改为统一确认开关；移除按 agent 的票务门禁

workflow-guard.sh 规则二此前按 agent 类型（omp/dsh/kimi/zcode）拦截 acpx 派发，要求仓库里已有实施票。这个门禁有两个问题：覆盖面取决于 agent 名单，维护成本高；把"能不能派发"绑死在票务状态上，而派发是否合适最终只有用户本人能实时判断。

## 决策

- 新增 `hooks/acpx-guard.sh`：任何 Bash 命令中出现 acpx 即要求用户确认（PreToolUse ask），状态文件 `~/.claude/acpx-guard` 为 `on` 时放行。
- 新增 `commands/acpx-guard.md`：`/acpx-guard [on|off]` 切换开关；缺省 `off`（每次确认），状态文件不存在同样视为 `off`。
- 删除 workflow-guard.sh 的规则二，以及 hooks.json 中 workflow-guard 的 Bash matcher 条目（规则一"无 ADR/SPEC 不建票"保留，它约束建票，不约束派发）。
- README 增补对应说明。

## 由此带来的不变量

- 派发是否放行由用户通过开关实时决定，不再依赖仓库内票务状态。
- 票务流程（spec、ADR、实施票）仍是本仓库工作流的一部分，只是不再与派发硬绑定。
- 两个护栏共用 hooks/hooks.json，新增护栏沿用 `${CLAUDE_PLUGIN_ROOT}` 引用脚本的形式。
