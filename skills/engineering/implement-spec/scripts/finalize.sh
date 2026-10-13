#!/usr/bin/env bash
# 收尾：open_pr 为真时把集成分支的 draft PR 标记为 ready（幂等，无 PR 或已 ready 均静默通过）。
set -euo pipefail

repo="" branch="" open_pr=false
while [ $# -gt 0 ]; do
  case "$1" in
    --repo) repo=$2; shift 2 ;;
    --branch) branch=$2; shift 2 ;;
    --open-pr) open_pr=$(echo "$2" | tr 'A-Z' 'a-z'); shift 2 ;;
    *) echo "finalize: 未知参数 $1" >&2; exit 1 ;;
  esac
done
[ -n "$repo" ] && [ -n "$branch" ] || { echo "finalize: 参数不全" >&2; exit 1; }

if [ "$open_pr" != true ]; then
  echo "finalize: open_pr 未开启，跳过 PR ready"
  exit 0
fi
if (cd "$repo" && gh pr ready "$branch" 2>/dev/null); then
  echo "finalize: PR 已标记 ready"
else
  echo "finalize: 无 PR 或已 ready，跳过"
fi
