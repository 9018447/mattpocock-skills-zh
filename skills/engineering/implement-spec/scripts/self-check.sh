#!/usr/bin/env bash
# 自检：shell 语法、模板填装、考卷拼装（jev dry-run 本地校验不外发）、
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

# 4.5) dispatch 透传校验：非法 agent 名在调用 acpx 之前被拒
if bash "$here/dispatch.sh" --worktree "$fx" --prompt "$fx/goal.txt" --log "$fx/d.log" \
     --chain implement --agents $'kimi; evil' 2>/dev/null; then
  bad "dispatch 未拒绝非法 agent 名"
else
  note "dispatch 非法 agent 名拒收通过"
fi

# 4.6) dispatch zcode 分支：包装缺失时按失败退出走换链，错误落日志
if HOME=/nonexistent-dispatch-zcode bash "$here/dispatch.sh" --worktree "$fx" --prompt "$fx/goal.txt" --log "$fx/d-zcode.log" \
     --chain implement --agents zcode 2>/dev/null; then
  bad "dispatch zcode 包装缺失未报错"
elif ! grep -q "zcode-acp 包装缺失" "$fx/d-zcode.log"; then
  bad "dispatch zcode 失败原因不是包装缺失"
else
  note "dispatch zcode 包装缺失安全换链通过"
fi

# 5) workflow 引擎语法实测：夹具仓库 + stub lifecycle，三类 YAML 各跑一次
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
cp "$here/frontier.sh" "$fx/skill/scripts/"
for s in ticket-lifecycle finalize; do
  { echo '#!/usr/bin/env bash'
    echo 'echo "$*" >> "$STUB_LOG"'
    echo 'exit 0'
  } > "$fx/skill/scripts/$s.sh"
  chmod +x "$fx/skill/scripts/$s.sh"
done

run_wf() { # $1 yaml  $2 期望 status
  local yaml=$1 want=$2 name
  name=$(basename "$yaml")
  (cd "$repo" && export FRONTIER_CMD='if [ -s q.txt ]; then cat q.txt; : > q.txt; else echo "[]"; fi' \
     STUB_LOG="$fx/stub.log" JEV_CMD=/nonexistent \
     && specify workflow run "$yaml" -i repo_root="$repo" -i integration_branch=integ \
        -i spec_goal_file="$fx/goal.txt" -i ticket=7 --json >"$fx/out.json" 2>"$fx/err.log")
  local rc=$? got=""
  [ -f "$fx/out.json" ] && got=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("status",""))' "$fx/out.json" 2>/dev/null)
  if [ "$rc" -eq 0 ] && [ "$got" = "$want" ]; then
    note "workflow $name 引擎实测通过（$want）"
  else
    bad "workflow $name 实测：rc=$rc status=$got；$(tail -3 "$fx/err.log" 2>/dev/null | tr '\n' ' ')"
  fi
}

run_wf "$fx/skill/workflows/implement.yml" completed
# 空前沿：lifecycle（带 --ticket 参数）不应被调用，finalize 可以
[ -f "$fx/stub.log" ] && grep -q -- '--ticket' "$fx/stub.log" \
  && bad "空前沿却调用了 lifecycle: $(cat "$fx/stub.log")" || note "空前沿零派发通过"

printf '[7]\n' > "$repo/q.txt"
rm -f "$fx/stub.log"
run_wf "$fx/skill/workflows/implement.yml" completed
grep -q -- '--ticket 7' "$fx/stub.log" 2>/dev/null && note "单票派发路径（do-while/if/fan-out/fan-in）通过" \
  || bad "未观察到 --ticket 7 派发：$(cat "$fx/stub.log" 2>/dev/null)"

rm -f "$repo/q.txt" "$fx/stub.log"
run_wf "$fx/skill/workflows/test.yml" completed
run_wf "$fx/skill/workflows/run.yml" completed

# 结论
if [ "$fail" -eq 0 ]; then
  echo "self-check: 全部通过"
else
  echo "self-check: 存在失败项"
fi
exit "$fail"
