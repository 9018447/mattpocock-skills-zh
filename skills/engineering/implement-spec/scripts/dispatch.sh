#!/usr/bin/env bash
# 派发降级链包装：按候补链逐个 agent 尝试 acpx 派发，命中撞限签名或静默死亡自动换下一个。
# 链与错误签名依据 references/recovery.md（2026-10-09 定案：omp 到 kimi 到 dsh，zcode 收尾）；
# rate_limited 为 2026-10-13 zcode 桥实测新增（GLM provider 429）。
# 存活原则：implement 链不写死默认——派发链是活的决定，由编排者当次按各 agent 存活状态
# 逐票显式指定（--agents）；codex 单 agent 是运行/测试票的常设裁定（用户 2026-10-10），不属存活链。
# 成功判据：退出码 0 且日志出现 [done] end_turn；静默死亡判据：无 end_turn 且 worktree 零改动。
# ponytail: 不做进程存活轮询，同步 exec 阻塞到结束；要看进度由编排者 tail 日志。
set -euo pipefail

worktree="" prompt="" log="" chain=implement agents=""
while [ $# -gt 0 ]; do
  case "$1" in
    --worktree) worktree=$2; shift 2 ;;
    --prompt) prompt=$2; shift 2 ;;
    --log) log=$2; shift 2 ;;
    --chain) chain=$2; shift 2 ;;
    --agents) agents=$2; shift 2 ;;
    *) echo "dispatch: 未知参数 $1" >&2; exit 1 ;;
  esac
done
[ -d "$worktree" ] && [ -f "$prompt" ] && [ -n "$log" ] || { echo "dispatch: 参数不全" >&2; exit 1; }

case "$chain" in
  implement)
    [ -n "$agents" ] || { echo "dispatch: implement 链必须当次显式指定存活 agent（--agents \"短名…\"），技能不写死默认链" >&2; exit 1; } ;;
  codex) agents="${agents:-codex}" ;;
  *) echo "dispatch: 未知链 $chain" >&2; exit 1 ;;
esac
# 透传覆盖：空格分隔的短名（omp-acp/kimi/dsh/codex/zcode）或 ACP 桥路径。
# 出口校验的信任边界思路：白名单之外只放行安全路径字符，
# 派发串里的分号引号永远到不了 shell。
for a in $agents; do
  case "$a" in
    omp-acp|kimi|dsh|codex|zcode) ;;
    *) echo "$a" | grep -Eq '^[A-Za-z0-9_./-]+$' \
       || { echo "dispatch: 非法 agent 名: $a" >&2; exit 1; } ;;
  esac
done
read -ra agents_arr <<< "$agents"

proxy="${CODEX_PROXY:-http://127.0.0.1:7890}"

run_agent() {
  local agent=$1
  case "$agent" in
    omp-acp) acpx --cwd "$worktree" --approve-all --agent 'omp acp' exec -f "$prompt" ;;
    kimi)    acpx --cwd "$worktree" --approve-all kimi exec -f "$prompt" ;;
    dsh)     acpx --cwd "$worktree" --approve-all dsh exec -f "$prompt" ;;
    codex)   env HTTP_PROXY="$proxy" HTTPS_PROXY="$proxy" INITIAL_AGENT_MODE=agent-full-access \
             acpx --cwd "$worktree" --approve-all --model gpt-6-luna codex exec -f "$prompt" ;;
    zcode)   zbin="$HOME/.local/bin/zcode-acp"  # 桥包装：动态定位 Linux 引擎 bundle；uv tool upgrade 会抹掉它
             [ -x "$zbin" ] || { echo "dispatch: zcode-acp 包装缺失: $zbin" >&2; return 1; }
             acpx --cwd "$worktree" --approve-all --agent "$zbin" exec -f "$prompt" ;;
    *)       # 其他值按 ACP 桥原始命令透传（--agent 是逃生舱，如 zcode-acp、omp acp）
             acpx --cwd "$worktree" --approve-all --agent "$agent" exec -f "$prompt" ;;
  esac
}

attempt=0
for agent in "${agents_arr[@]}"; do
  attempt=$((attempt + 1))
  target="$log"
  [ "$attempt" -gt 1 ] && target="$log.attempt$((attempt - 1))"
  [ -f "$target" ] && mv "$target" "$target.old"
  echo "dispatch: 派发 $agent（第 $attempt 次尝试）" >&2

  rc=0
  set -o pipefail
  run_agent "$agent" 2>&1 | tee "$log" || rc=$?
  set +o pipefail

  if grep -Eq 'quota|usage limit|Usage limit reached|AccountQuotaExceeded|rate_limited|1308|403.*(limit|quota)' "$log"; then
    echo "dispatch: $agent 命中配额签名，换链" >&2
    continue
  fi
  if [ "$rc" -ne 0 ]; then
    echo "dispatch: $agent 退出码 $rc，换链" >&2
    continue
  fi
  if ! grep -q '\[done\] end_turn' "$log"; then
    if [ -z "$(git -C "$worktree" status --porcelain)" ]; then
      echo "dispatch: $agent 疑似静默死亡（无 end_turn 且零改动），换链" >&2
      continue
    fi
    echo "dispatch: $agent 无 end_turn 但盘上有改动，按成功收下" >&2
  fi
  echo "dispatch: $agent 完成" >&2
  exit 0
done

echo "dispatch: 候补链用尽仍未成功" >&2
exit 1
