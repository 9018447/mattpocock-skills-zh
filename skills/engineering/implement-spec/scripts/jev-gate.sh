#!/usr/bin/env bash
# jev 门控：跑 jev-decide，打印 PASS 或 FAIL，报告存盘。除用法错误外总以 0 退出：
# FAIL 是流程数据不是故障，workflow 与 lifecycle 据此走修复循环。
# PASS 判定：decide 退出码 0，且每个门控问题 status=selected 且值等于通过标签。
# score 类的 review_priority 只进报告，不参与门控。
# JEV_CMD 环境变量仅供 self-check 注入桩，生产不得设置。
set -euo pipefail

[ $# -eq 2 ] || { echo "usage: jev-gate.sh <request.json> <report.json>" >&2; exit 1; }
req=$1
report=$2

err=$(mktemp)
rc=0
out=$("${JEV_CMD:-jev-decide}" decide "$req" 2>"$err") || rc=$?
{ printf '%s\n' "$out"; cat "$err"; } > "$report"
rm -f "$err"

RC="$rc" REPORT="$report" python3 <<'PY'
import json, os

PASS_LABEL = {
    "completion": "supported",
    "weakens_test": "preserves",
    "receipts_match": "match",
    "coverage_ok": "covered",
}
rc = int(os.environ["RC"])
try:
    # decide 的 JSON 报告在 stdout 前段，其后可能拼有 stderr 文本，取第一个完整对象
    raw = open(os.environ["REPORT"], encoding="utf-8").read()
    report = json.JSONDecoder().raw_decode(raw)[0]
except Exception:
    print("FAIL")
    raise SystemExit(0)
decisions = report.get("decisions", {})
if rc != 0 or not decisions:
    print("FAIL")
    raise SystemExit(0)
for name, passing in PASS_LABEL.items():
    if name not in decisions:
        continue  # 该类型考卷不含此问题
    d = decisions[name]
    if d.get("status") != "selected" or d.get("value") != passing:
        print("FAIL")
        raise SystemExit(0)
print("PASS")
PY
