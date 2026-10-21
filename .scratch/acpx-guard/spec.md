# spec：acpx 派发确认开关

## 背景

插件已带 `hooks/hooks.json` 与 `hooks/workflow-guard.sh`。本次需求：

1. acpx 派发默认需要用户确认，并提供开关让用户免确认直派。
2. 删除 workflow-guard.sh 的规则二（按 agent 类型的票务派发门禁），由上述统一确认门禁取代。

行为契约以本文为准，实现方式由实施者决定，但脚本风格应与 workflow-guard.sh 一致（bash、jq 处理 stdin JSON）。

## 行为契约

### hooks/acpx-guard.sh（新增）

- 输入：stdin 的 PreToolUse JSON，取 `.tool_input.command`。
- 状态文件 `$HOME/.claude/acpx-guard`：内容 `on`（去除首尾空白后）时直接放行（exit 0，无输出）。
- 其余情况（`off`、文件不存在、内容其他值）：命令匹配到单词边界的 acpx 时，输出 `permissionDecision` 为 `ask` 的 `hookSpecificOutput`（`hookEventName: PreToolUse`），理由文案包含"acpx 子代理派发，需要用户确认"与"/acpx-guard on 可切换为免确认"。
- 单词边界判定：acpx 前后不能是字母、数字、下划线、连字符（即 `(^|[^a-zA-Z0-9_-])acpx([^a-zA-Z0-9_-]|$)`）。这样 `acpx-guard` 之类的文件名不会误触发。
- 无 acpx 时放行。
- 脚本注释使用中文，不出现 em-dash。

### hooks/hooks.json（修改）

- `description` 更新为同时描述两个护栏。
- PreToolUse 中：删除 workflow-guard 的 `Bash` 条目；新增 `Bash` matcher 条目调用 `"${CLAUDE_PLUGIN_ROOT}/hooks/acpx-guard.sh"`，timeout 10。

### hooks/workflow-guard.sh（修改）

- 整块删除规则二及其注释；规则一与 `deny()` 不变；文件头部注释同步（去掉派发拦截相关描述）。

### commands/acpx-guard.md（新增）

- frontmatter：`description` 说明开关语义；`argument-hint: "[on|off]，留空则翻转当前状态"`。
- 正文步骤：读取状态（`cat ~/.claude/acpx-guard 2>/dev/null`，输出为空视为 off）→ 确定目标状态（参数 `on`/`off` 直接采用，留空取反）→ 用 Write 工具把纯文本 `on` 或 `off` 写入状态文件（不要用 shell 重定向，会被 lean-ctx 拦截）→ 一句话报告旧状态到新状态。

### README.md（修改）

- 在"索引"小节之后新增一节，说明：插件自带 acpx 派发确认护栏，默认每次派发需确认；`/acpx-guard on` 免确认，`/acpx-guard off` 恢复确认；链接 `hooks/acpx-guard.sh` 与 `commands/acpx-guard.md`。不出现 em-dash。

### changeset（新增）

- `.changeset/acpx-guard.md`：patch，一句话描述本次变更（确认开关上线 + 规则二移除）。

## 验收标准

1. `claude plugin validate . --strict` 通过。
2. 功能自测（管道喂 stdin，三例全过）：
   - 状态 `off`、命令含 acpx：输出 ask JSON。
   - 状态 `on`、命令含 acpx：无输出、exit 0。
   - 命令无 acpx：无输出；`acpx-guard` 这类词不触发。
   - 附加：多行命令（如 `set -o pipefail` 换行后接 acpx）能命中。
3. workflow-guard.sh 中不再有 omp/dsh/kimi/zcode 派发拦截逻辑；规则一原样保留。
4. 所有新增、修改的散文与注释不出现 em-dash。
5. 不改动 `.claude-plugin/` 下的清单文件。
6. 完成后不执行 git commit，保持工作区改动待审。
