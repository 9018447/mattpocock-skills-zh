#!/usr/bin/env bash
# 拼装 jev 考卷：把 diff、票面、测试回执组装成 jev-decide 的请求 JSON。
# 门控问题统一用 choice，通过标签写死在 jev-gate.sh。
# ponytail: diff 全文进考卷，超长 diff 会顶到模型上下文上限；需要裁剪时在这里加 hunk 预算。
set -euo pipefail

type="" goal_file="" ticket_file="" diff_file="" receipt_file="" out=""
while [ $# -gt 0 ]; do
  case "$1" in
    --type) type=$2; shift 2 ;;
    --goal-file) goal_file=$2; shift 2 ;;
    --ticket-file) ticket_file=$2; shift 2 ;;
    --diff-file) diff_file=$2; shift 2 ;;
    --receipt-file) receipt_file=$2; shift 2 ;;
    --out) out=$2; shift 2 ;;
    *) echo "collect-exam: 未知参数 $1" >&2; exit 1 ;;
  esac
done
[ -n "$type" ] && [ -n "$goal_file" ] && [ -n "$ticket_file" ] && [ -n "$diff_file" ] \
  && [ -n "$receipt_file" ] && [ -n "$out" ] || { echo "collect-exam: 参数不全" >&2; exit 1; }

DIFF_FILE="$diff_file" GOAL_FILE="$goal_file" TICKET_FILE="$ticket_file" \
RECEIPT_FILE="$receipt_file" EXAM_TYPE="$type" OUT="$out" python3 <<'PY'
import json, os

def read(p):
    return open(p, encoding="utf-8", errors="replace").read() if os.path.getsize(p) else ""

state = {
    "goal": read(os.environ["GOAL_FILE"]).strip(),
    "ticket": read(os.environ["TICKET_FILE"]).strip(),
    "diff": read(os.environ["DIFF_FILE"]),
    "test_receipt": read(os.environ["RECEIPT_FILE"]).strip(),
}

GATE_COMMON = "只依据 state 中的证据判断，证据不足选 unknown。"

def choice(name, instructions, criteria):
    return name, {"type": "choice", "instructions": instructions, "criteria": criteria}

t = os.environ["EXAM_TYPE"]
qs = {}
if t == "implement":
    n, q = choice("completion", "diff 与 test_receipt 是否足以认定票面验收已达成？" + GATE_COMMON,
                  {"supported": "验收已实现且有证据支持", "unsupported": "证据不足以认定验收达成",
                   "unknown": "关键证据缺失"})
    qs[n] = q
    n, q = choice("weakens_test", "该 diff 是否削弱了原有回归检查（改软断言、删测试、跳过用例）？" + GATE_COMMON,
                  {"preserves": "原有检查未被削弱", "weakens": "存在削弱原有检查的改动", "unknown": "证据不足"})
    qs[n] = q
elif t == "run":
    n, q = choice("receipts_match", "test_receipt 中的运行凭证是否符合票面预期？" + GATE_COMMON,
                  {"match": "凭证与预期一致", "mismatch": "凭证与预期不符", "unknown": "证据不足"})
    qs[n] = q
elif t == "test":
    n, q = choice("coverage_ok", "全量测试回执是否覆盖 spec 目标且未发现未解释的失败？" + GATE_COMMON,
                  {"covered": "覆盖充分且无未解释失败", "gap": "存在覆盖缺口或未解释失败", "unknown": "证据不足"})
    qs[n] = q
    n, q = choice("weakens_test", "测试改动是否削弱了原有检查？" + GATE_COMMON,
                  {"preserves": "未被削弱", "weakens": "存在削弱", "unknown": "证据不足"})
    qs[n] = q
else:
    raise SystemExit("collect-exam: 未知类型 " + t)

qs["review_priority"] = {"type": "score",
    "instructions": "本次改动还需要多少人工复核注意力？",
    "criteria": ["无具体疑点", "局部疑点需要查看", "与验收条件直接冲突"]}

request = {"state": state, "questions": qs}
with open(os.environ["OUT"], "w", encoding="utf-8") as f:
    json.dump(request, f, ensure_ascii=False, indent=2)
PY
