#!/usr/bin/env bash
# 工作流护栏：无 ADR/SPEC 不建票；无票不派重型 agent（codex 豁免）
set -euo pipefail
input=$(cat)
tool=$(jq -r '.tool_name // ""' <<<"$input")

deny() {
  jq -n --arg reason "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason}}'
  exit 0
}

# 规则一：往 .scratch/*/issues/ 建票前，同目录要有 spec.md，且仓库有 ADR（docs/adr 或 .agents/adr）
if [[ "$tool" == "Write" || "$tool" == "Edit" || "$tool" == "MultiEdit" ]]; then
  f=$(jq -r '.tool_input.file_path // ""' <<<"$input")
  if [[ "$f" == *".scratch/"*"/issues/"*".md" ]]; then
    feature=$(dirname "$(dirname "$f")")
    root=$(dirname "$(dirname "$feature")")
    missing=()
    [[ -f "$feature/spec.md" ]] || missing+=("SPEC：$feature/spec.md 不存在")
    if ! compgen -G "$root/docs/adr/*.md" >/dev/null && ! compgen -G "$root/.agents/adr/*.md" >/dev/null; then
      missing+=("ADR：$root 下没有 docs/adr/ 或 .agents/adr/ 决策记录")
    fi
    if ((${#missing[@]})); then
      deny "建票被拦（本项目规矩：没有 ADR/SPEC 不建票）。缺：$(printf '%s；' "${missing[@]}") 先走 /grilling 裁定、/acpx-to-spec 出规格，再回来建票。"
    fi
  fi
fi

# 规则二：acpx 派发 omp/dsh/kimi/zcode 前，.scratch/*/issues/ 下要有实施票（codex 不拦）
if [[ "$tool" == "Bash" ]]; then
  cmd=$(jq -r '.tool_input.command // ""' <<<"$input")
  if [[ "$cmd" == *acpx* ]] && printf '%s' "$cmd" | grep -qE -- '--agent[[:space:]]+["'"'"']?(omp|dsh|kimi|zcode)\b|--model[[:space:]]+["'"'"']?zcode\b'; then
    root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
    if ! compgen -G "$root/.scratch/*/issues/*.md" >/dev/null; then
      deny "派发被拦（本项目规矩：没有实施票不派 omp/dsh/kimi/zcode）。$root/.scratch/*/issues/ 下没有任何票。codex 派发不受此限；票就绪后引用票路径重试。"
    fi
  fi
fi

exit 0
