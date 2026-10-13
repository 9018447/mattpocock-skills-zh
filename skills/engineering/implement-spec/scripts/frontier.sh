#!/usr/bin/env bash
# 前沿查询：输出可领票号的 JSON 数组（如 [7,9]），无票输出 []。
# 输出只允许非负整数数组，这是 fan-out 与 lifecycle 的信任边界：
# 票号以纯数字进入 run 字段，票面文本永远不进命令行。
# FRONTIER_CMD 仅供 self-check 覆盖默认 gh 查询，生产不得设置。
# ponytail: label 未做字符校验，编排者传普通 label；要开放任意输入再加白名单。
set -euo pipefail

repo=${1:?usage: frontier.sh <repo_root> [label]}
label=${2:-}

if [ -n "${FRONTIER_CMD:-}" ]; then
  out=$(eval "$FRONTIER_CMD") || { echo "frontier: FRONTIER_CMD 执行失败" >&2; exit 1; }
else
  label_args=()
  [ -n "$label" ] && label_args+=(--label "$label")
  out=$(gh issue list --repo "$repo" --state open "${label_args[@]}" --json number --jq '[.[].number]') \
    || { echo "frontier: gh 查询失败" >&2; exit 1; }
fi

# 出口校验：不是非负整数数组就失败，绝不让脏数据流向 fan-out
python3 - "$out" <<'PY'
import json, sys
try:
    items = json.loads(sys.argv[1])
    assert isinstance(items, list) and all(isinstance(i, int) and i >= 0 for i in items)
except Exception:
    sys.exit("frontier: 输出不是非负整数数组")
print(json.dumps(items))
PY
