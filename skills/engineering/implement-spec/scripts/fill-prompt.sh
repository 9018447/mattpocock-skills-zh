#!/usr/bin/env bash
# 模板填装：从 templates/ 原文件做字面替换生成派发 prompt，模板文件本身不动。
# 固定段原样保留；工作原则块按票类型取内置提炼文案（源为模板表格）；续作块按轮次取舍。
# 填装后残留任何 {{ 占位符即失败，对应模板自带的自查规则。
# ponytail: 票类型只认票面文本里的主类型标签，并发/共享状态类追加原则不自动判，编排者建票时写进票面即可。
set -euo pipefail

skill_dir="" type="" ticket="" repo="" goal_file="" ticket_file="" leads_file=""
while [ $# -gt 0 ]; do
  case "$1" in
    --skill-dir) skill_dir=$2; shift 2 ;;
    --type) type=$2; shift 2 ;;
    --ticket) ticket=$2; shift 2 ;;
    --repo) repo=$2; shift 2 ;;
    --goal-file) goal_file=$2; shift 2 ;;
    --ticket-file) ticket_file=$2; shift 2 ;;
    --leads-file) leads_file=$2; shift 2 ;;
    *) echo "fill-prompt: 未知参数 $1" >&2; exit 1 ;;
  esac
done
[ -n "$skill_dir" ] && [ -n "$type" ] && [ -n "$ticket" ] && [ -n "$repo" ] \
  && [ -n "$goal_file" ] && [ -n "$ticket_file" ] || { echo "fill-prompt: 参数不全" >&2; exit 1; }

SKILL_DIR="$skill_dir" TYPE="$type" TICKET="$ticket" REPO="$repo" \
GOAL_FILE="$goal_file" TICKET_FILE="$ticket_file" LEADS_FILE="${leads_file:-}" python3 <<'PY'
import os, re, sys

skill = os.environ["SKILL_DIR"]
tpl_dir = os.path.join(skill, "templates")
read = lambda p: open(p, encoding="utf-8").read()
goal = read(os.environ["GOAL_FILE"]).strip()
ticket_text = read(os.environ["TICKET_FILE"]).strip()
leads_path = os.environ["LEADS_FILE"]
leads = read(leads_path).strip() if leads_path and os.path.exists(leads_path) else ""

PRINCIPLES = {
    "common": [
        "test-behavior-not-implementation：测试对行为断言（输入到输出），不对实现细节断言",
        "prove-it-works：完工判据是证据（测试输出、运行结果），不是「应该没问题」",
        "minimize-reader-load：代码和注释写给下一个读的人，命名直白、路径写全、不省中间步骤",
    ],
    "bug-fix": ["fix-root-causes：追到根因再修，不打补丁掩盖症状",
                "attack-the-premise：同类修复连续失败两次，先检验共同假设"],
    "refactor": ["migrate-callers-then-delete-legacy-apis：先迁走所有调用方再删旧接口",
                 "subtract-before-you-add：先想能不能删代码解决问题，再想加代码"],
    "feature": ["sequence-verifiable-units：把工作拆成一串可独立验证的小单元，每步确认再前进"],
    "perf": ["explain-the-number：每个优化前后的数字都要有解释，解释不了的收益当作不存在"],
}

def principles_block(ticket_type):
    lines = list(PRINCIPLES["common"]) + PRINCIPLES.get(ticket_type, [])
    return "\n".join("- " + x for x in lines)

GOAL_PH = "{{一段话说清整个 Spec 的目标和当前主要矛盾}}"
ROLE_PH = "{{当前 Ticket 对解决主要矛盾的作用，一两句}}"
REPO_PH = "{{主检出绝对路径}}"
PRIN_PH = "{{按票类型从下表提炼写入 prompt，每条一两句中文提炼，不贴原文全文。全类型三条必带，命中类型追加。}}"

META_LINES = ("按占位符逐项填入后写入", "填完自查：", "按占位符逐项填入", "不得凭记忆重写本模板")

def fill_implement(tpl, ticket_type):
    text = "\n".join(l for l in tpl.split("\n") if not l.startswith(META_LINES))
    text = text.replace(GOAL_PH, goal)
    text = text.replace(ROLE_PH, ticket_text)
    text = text.replace(REPO_PH, os.environ["REPO"])
    text = text.replace(PRIN_PH, principles_block(ticket_type))
    block = re.compile(r"\{\{#续作\}\}.*?\{\{/续作\}\}\n?", re.S)
    if leads:
        return block.sub("## 续作说明\n\n" + leads + "\n", text)
    return block.sub("", text)

def section(text, header_prefix):
    m = re.search(r"^## " + re.escape(header_prefix) + r"[^\n]*\n(.*?)(?=^## |\Z)", text, re.S | re.M)
    return "## " + header_prefix + "\n" + m.group(1) if m else ""

tt = os.environ["TYPE"]
ticket_type = next((x for x in ("bug-fix", "refactor", "feature", "perf") if x in ticket_text), "")
t = os.environ["TICKET"]

if tt == "test":
    prompt = read(os.path.join(tpl_dir, "prompt-test.md")).replace("{{tNN}}", t)
elif tt == "run":
    # run 模板 = 实现票全部固定段 + 工作方式节替换（模板文件头部约定）
    body = fill_implement(read(os.path.join(tpl_dir, "prompt-implement.md")), ticket_type)
    replacement = re.search(r"^(## 工作方式[^\n]*\n.*?)(?=^## |\Z)", read(os.path.join(tpl_dir, "prompt-run.md")), re.S | re.M)
    if not replacement:
        raise SystemExit("fill-prompt: run 模板缺少工作方式节")
    prompt = re.sub(r"^## 工作方式[^\n]*\n.*?(?=^## )", replacement.group(1), body, flags=re.S | re.M)
    prompt = prompt.replace("{{tNN}}", t)
elif tt == "implement":
    prompt = fill_implement(read(os.path.join(tpl_dir, "prompt-implement.md")), ticket_type)
    prompt = prompt.replace("{{tNN}}", t)
else:
    raise SystemExit("fill-prompt: 未知类型 " + tt)

leftover = [x for x in re.findall(r"\{\{[^}]*\}\}", prompt)]
if leftover:
    raise SystemExit("fill-prompt: 占位符未清零: " + repr(leftover[:3]))
sys.stdout.write(prompt)
PY
