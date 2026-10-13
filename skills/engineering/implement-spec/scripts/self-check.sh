#!/usr/bin/env bash
# 自检：shell 语法、workflow 输入引用完备性、模板填装、考卷拼装（jev dry-run 本地校验不外发）、
# jev 门控判定（桩注入）、workflow 引擎语法实测（夹具仓库 + stub lifecycle）。
# 不派发真实 agent，不访问网络。
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
skill=$(cd "$here/.." && pwd)
fail=0
note() { echo "self-check: $*"; }
bad() { echo "self-check: FAIL $*"; fail=1; }

# 1) shell 语法
for f in "$here"/*.sh; do bash -n "$f" || bad "bash -n $f"; done
note "shell 语法检查完成"

# 1.5) workflow 输入引用完备性：正文里的 {{ inputs.X }} 引用必须在 inputs 块声明过
# （防「step 引用了 inputs.agents 却忘声明」这类漂移——自检不传该输入时引擎静默落默认值）
refchk=$(python3 - "$skill"/workflows/*.yml <<'PY'
import re, sys
bad = []
for path in sys.argv[1:]:
    declared, refs, in_inputs = set(), set(), False
    for line in open(path, encoding="utf-8"):
        if re.match(r"^inputs:\s*$", line):
            in_inputs = True
            continue
        if in_inputs and re.match(r"^\S", line):
            in_inputs = False
        m = re.match(r"^  ([A-Za-z_][A-Za-z0-9_]*):", line) if in_inputs else None
        if m:
            declared.add(m.group(1))
        refs.update(re.findall(r"inputs\.([A-Za-z_][A-Za-z0-9_]*)", line))
    miss = refs - declared
    if miss:
        bad.append(f"{path}: 引用未声明 {sorted(miss)}")
print("; ".join(bad))
PY
)
if [ -z "$refchk" ]; then
  note "workflow 输入引用完备性通过"
else
  bad "workflow 输入引用漂移：$refchk"
fi

fx=$(mktemp -d); trap 'rm -rf "$fx"' EXIT
printf '整体目标：验证 workflow 化编排可用。' > "$fx/goal.txt"
printf '# 票 7：加一个加法函数\n\n验收：add(1,2)==3，有目标测试。bug-fix\n' > "$fx/ticket.md"
printf 'diff --git a/add.py b/add.py\n+++ b/add.py\ndef add(a,b):\n    return a+b\n' > "$fx/diff.diff"
printf '目标测试 3 个全部通过 EXIT=0\n' > "$fx/receipt.txt"

# 2) 模板填装：无占位符残留、固定段在、bug-fix 原则命中、续作块按轮注入
if bash "$here/fill-prompt.sh" --skill-dir "$skill" --type implement --ticket t07 \
     --repo /main/checkout --goal-file "$fx/goal.txt" --ticket-file "$fx/ticket.md" \
     > "$fx/prompt.md" \
  && ! grep -q '{{' "$fx/prompt.md" \
  && grep -q '工作环境' "$fx/prompt.md" \
  && grep -q 'fix-root-causes' "$fx/prompt.md"; then
  note "模板填装（implement，bug-fix 原则）通过"
else
  bad "模板填装 implement"
fi
if bash "$here/fill-prompt.sh" --skill-dir "$skill" --type implement --ticket t07 \
     --repo /main/checkout --goal-file "$fx/goal.txt" --ticket-file "$fx/ticket.md" \
     --leads-file "$fx/receipt.txt" > "$fx/prompt2.md" \
  && grep -q '续作说明' "$fx/prompt2.md" \
  && grep -q 'EXIT=0' "$fx/prompt2.md"; then
  note "续作块注入通过"
else
  bad "续作块注入"
fi

# 3) 考卷拼装 + jev 请求本地校验
if bash "$here/collect-exam.sh" --type implement --goal-file "$fx/goal.txt" \
     --ticket-file "$fx/ticket.md" --diff-file "$fx/diff.diff" \
     --receipt-file "$fx/receipt.txt" --out "$fx/exam.json" \
  && jev-decide decide "$fx/exam.json" --dry-run >/dev/null 2>&1; then
  note "考卷拼装与 jev 请求校验通过"
else
  bad "考卷拼装/jev 校验"
fi

# 4) jev 门控判定（桩注入，两种结果）
jev_ok="$fx/jev-ok"; jev_rev="$fx/jev-review"
cat > "$jev_ok" <<'JEOF'
#!/usr/bin/env bash
echo '{"decisions": {"completion": {"status": "selected", "value": "supported", "probability": 0.9, "margin": 0.5}, "weakens_test": {"status": "selected", "value": "preserves", "probability": 0.9, "margin": 0.5}, "review_priority": {"status": "scored", "value": 0, "levels": []}}}'
exit 0
JEOF
cat > "$jev_rev" <<'JEOF'
#!/usr/bin/env bash
echo '{"decisions": {"completion": {"status": "needs_review", "value": "supported", "probability": 0.6, "margin": 0.1}}}'
exit 2
JEOF
chmod +x "$jev_ok" "$jev_rev"
[ "$(JEV_CMD="$jev_ok" bash "$here/jev-gate.sh" "$fx/exam.json" "$fx/r1.json")" = PASS ] \
  && note "门控 PASS 判定通过" || bad "门控 PASS 判定"
[ "$(JEV_CMD="$jev_rev" bash "$here/jev-gate.sh" "$fx/exam.json" "$fx/r2.json")" = FAIL ] \
  && note "门控 FAIL（needs_review）判定通过" || bad "门控 FAIL 判定"

# 4.5) dispatch 透传校验：非法 agent 名在调用 acpx 之前被拒；implement 链缺 --agents 拒跑
if bash "$here/dispatch.sh" --worktree "$fx" --prompt "$fx/goal.txt" --log "$fx/d.log" \
     --chain implement --agents $'kimi; evil' 2>/dev/null; then
  bad "dispatch 未拒绝非法 agent 名"
else
  note "dispatch 非法 agent 名拒收通过"
fi
if bash "$here/dispatch.sh" --worktree "$fx" --prompt "$fx/goal.txt" --log "$fx/d2.log" \
     --chain implement 2>/dev/null; then
  bad "dispatch implement 链缺 --agents 未拒跑"
else
  note "dispatch implement 链显式存活要求通过"
fi

# 5) workflow 引擎语法实测：夹具仓库 + stub lifecycle，三类 YAML 各跑一次
# 票源为编排者显式给定的本地票文件清单（逐票携带当次存活派发链），无前沿扫描步骤
repo="$fx/repo"; mkdir -p "$repo/.specify"
git -C "$repo" init -q
git -C "$repo" config user.email t@t
git -C "$repo" config user.name t
echo x > "$repo/f.txt"
git -C "$repo" add .
git -C "$repo" commit -qm init
git -C "$repo" branch integ
mkdir -p "$fx/skill/workflows" "$fx/skill/scripts"
cp "$skill"/workflows/*.yml "$fx/skill/workflows/"
for s in ticket-lifecycle finalize; do
  { echo '#!/usr/bin/env bash'
    echo 'echo "$*" >> "$STUB_LOG"'
    echo 'exit 0'
  } > "$fx/skill/scripts/$s.sh"
  chmod +x "$fx/skill/scripts/$s.sh"
done

run_wf() { # $1 yaml  $2 期望 status  $3.. 额外 -i
  local yaml=$1 want=$2 name
  name=$(basename "$yaml")
  shift 2
  (cd "$repo" && export STUB_LOG="$fx/stub.log" JEV_CMD=/nonexistent \
     && specify workflow run "$yaml" -i repo_root="$repo" -i integration_branch=integ \
        -i spec_goal_file="$fx/goal.txt" "$@" --json >"$fx/out.json" 2>"$fx/err.log")
  local rc=$? got=""
  [ -f "$fx/out.json" ] && got=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("status",""))' "$fx/out.json" 2>/dev/null)
  # failed 状态本身是合法期望，引擎对其返回非零退出码
  if [ "$got" = "$want" ] && { [ "$want" = "failed" ] || [ "$rc" -eq 0 ]; }; then
    note "workflow $name 引擎实测通过（$want）"
  else
    bad "workflow $name 实测：rc=$rc status=$got；$(tail -3 "$fx/err.log" 2>/dev/null | tr '\n' ' ')"
  fi
}

rm -f "$fx/stub.log"
run_wf "$fx/skill/workflows/implement.yml" completed \
  -i "ticket_files=[{\"file\":\"$fx/ticket.md\",\"agents\":\"kimi dsh\"}]"
grep -q -- '--ticket-file' "$fx/stub.log" 2>/dev/null && note "显式票清单派发路径（fan-out/fan-in）通过" \
  || bad "未观察到 --ticket-file 派发：$(cat "$fx/stub.log" 2>/dev/null)"
grep -q -- '--agents kimi dsh' "$fx/stub.log" 2>/dev/null && note "逐票派发链透传（item.agents）通过" \
  || bad "item.agents 未渲染进派发命令"

# preflight 票文件存在性：缺失文件应让 run 转 failed 而非派发
rm -f "$fx/stub.log"
run_wf "$fx/skill/workflows/implement.yml" failed \
  -i 'ticket_files=[{"file":"/nonexistent/ticket-99.md","agents":"kimi"}]'

# preflight 存活链缺省：票缺 agents 应让 run 转 failed（派发链是活的决定，不落默认）
rm -f "$fx/stub.log"
run_wf "$fx/skill/workflows/implement.yml" failed \
  -i "ticket_files=[{\"file\":\"$fx/ticket.md\"}]"

rm -f "$fx/stub.log"
run_wf "$fx/skill/workflows/test.yml" completed -i ticket_file="$fx/ticket.md"
run_wf "$fx/skill/workflows/run.yml" completed -i "ticket_files=[\"$fx/ticket.md\"]"

# 结论
if [ "$fail" -eq 0 ]; then
  echo "self-check: 全部通过"
else
  echo "self-check: 存在失败项"
fi
exit "$fail"
