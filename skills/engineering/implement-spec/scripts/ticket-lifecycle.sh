#!/usr/bin/env bash
# 单票生命周期：worktree 就绪、填模板派发、拼考卷、jev 审查、合并或修复循环。
# 修复轮上限 --max-rounds（默认 2），用尽仍未过则退出码 1，run 转 failed，编排者按 recovery.md 接手。
# test 票只测不改：不合并，审查不过同样转 failed 交编排者。
# 票源为本地 markdown 票文件（--ticket-file，文件名须以「数字-」开头），票面零远程查询；
# 仅 open_pr=true 的 PR 收尾用 gh（需 GitHub 远端）。
set -euo pipefail

repo="" branch="" ticket_file="" type="" goal_file="" skill_dir="" max_rounds=2 open_pr=false agents=""
while [ $# -gt 0 ]; do
  case "$1" in
    --repo) repo=$2; shift 2 ;;
    --branch) branch=$2; shift 2 ;;
    --ticket-file) ticket_file=$2; shift 2 ;;
    --type) type=$2; shift 2 ;;
    --goal-file) goal_file=$2; shift 2 ;;
    --skill-dir) skill_dir=$2; shift 2 ;;
    --max-rounds) max_rounds=$2; shift 2 ;;
    --open-pr) open_pr=$(echo "$2" | tr 'A-Z' 'a-z'); shift 2 ;;
    --agents) agents=$2; shift 2 ;;
    *) echo "lifecycle: 未知参数 $1" >&2; exit 1 ;;
  esac
done
[ -n "$repo" ] && [ -n "$branch" ] && [ -n "$ticket_file" ] && [ -n "$type" ] \
  && [ -n "$goal_file" ] && [ -n "$skill_dir" ] || { echo "lifecycle: 参数不全" >&2; exit 1; }
case "$type" in implement|run|test) ;; *) echo "lifecycle: 未知类型 $type" >&2; exit 1 ;; esac

die() { echo "lifecycle: $*" >&2; exit 1; }
script_dir=$(cd "$(dirname "$0")" && pwd)
R=$(cd "$repo" && pwd)
D=$(cd "$skill_dir" && pwd)
[ -f "$ticket_file" ] || die "票文件不存在: $ticket_file"
stem=$(basename "$ticket_file" .md)
num=${stem%%-*}
case "$num" in ''|*[!0-9]*) die "票文件名须以「数字-」开头（如 04-column.md）: $stem" ;; esac
t=$(printf 't%02d' "$num")
wt="$R/.worktrees/$t"
br="ticket/$t"
res="$R/.agent-results"
mkdir -p "$res" "$R/prompts"

# worktree 就绪：存在即复用（半成品保留，续作语境由模板续作节交代），缺失则基于集成分支新建
if [ ! -d "$wt" ]; then
  git -C "$R" worktree add "$wt" -b "$br" "$branch" 2>/dev/null \
    || git -C "$R" worktree add "$wt" "$br" || die "无法创建 worktree $wt"
fi
git -C "$wt" checkout -q "$br" || die "无法切换 $wt 到 $br"

# 票面落盘（本地票文件即标题加正文，作为 prompt 的本票作用与考卷的 ticket 段）
cp "$ticket_file" "$res/ticket-$t.md" || die "读取票面失败: $ticket_file"

case "$type" in
  implement) chain=implement ;;
  *) chain=codex ;;  # run/test 票默认 codex（模板约定）
esac

diff_file="$res/diff-$t.diff"
receipt_file="$res/receipt-$t.md"
: > "$diff_file"   # test 票无代码 diff，考卷 diff 段留空

verdict=FAIL
for round in $(seq 0 "$max_rounds"); do
  if [ "$type" != test ]; then
    git -C "$R" diff "$branch...$br" > "$diff_file" 2>/dev/null || : > "$diff_file"
  fi

  fill_args=(--skill-dir "$D" --type "$type" --ticket "$t" --repo "$R"
             --goal-file "$goal_file" --ticket-file "$res/ticket-$t.md")
  [ "$round" -gt 0 ] && fill_args+=(--leads-file "$res/leads-$t.md")
  bash "$script_dir/fill-prompt.sh" "${fill_args[@]}" > "$R/prompts/$t.md" \
    || die "模板填装失败（$t 第 $round 轮）"

  log="$res/${chain}-$t.log"
  dispatch_args=(--worktree "$wt" --prompt "$R/prompts/$t.md" --log "$log" --chain "$chain")
  [ -n "$agents" ] && dispatch_args+=(--agents "$agents")
  bash "$script_dir/dispatch.sh" "${dispatch_args[@]}" \
    || die "派发失败（$t 第 $round 轮），编排者按 recovery.md 处置"

  tail -c 4000 "$log" > "$receipt_file" || : > "$receipt_file"
  bash "$script_dir/collect-exam.sh" --type "$type" --goal-file "$goal_file" \
    --ticket-file "$res/ticket-$t.md" --diff-file "$diff_file" \
    --receipt-file "$receipt_file" --out "$res/exam-$t.json" || die "考卷拼装失败（$t）"
  verdict=$(bash "$script_dir/jev-gate.sh" "$res/exam-$t.json" "$res/jev-$t.json")
  echo "lifecycle: $t round=$round verdict=$verdict"
  [ "$verdict" = PASS ] && break
  if [ "$round" = "$max_rounds" ]; then
    die "$t: jev 审查 $max_rounds 轮修复未过，升级编排者"
  fi
  # 下一轮修复语境：jev 报告渲染成续作说明
  python3 - "$res/jev-$t.json" > "$res/leads-$t.md" <<'PY'
import json, sys
r = json.load(open(sys.argv[1]))
print("上一轮 jev 审查未通过，按以下判定修复：")
print()
for name, d in r.get("decisions", {}).items():
    if d.get("status") == "scored":
        continue
    print(f"- {name}: status={d.get('status')} value={d.get('value')} probability={d.get('probability')}")
print()
print("原始报告见 .agent-results/jev-*.json，从盘上现状接手修复，不推倒重来；")
print("本场景允许在 ticket 分支上提交（固定段第 6 条的本场景例外）。")
PY
done
[ "$verdict" = PASS ] || die "$t: 审查未通过"  # seq 意外为空的兜底

# 合并（test 票不合并：测试不改实现，产物是回执）
if [ "$type" != test ]; then
  if ! git -C "$R" merge --no-ff -q "$br" -m "merge $t into $branch" 2>"$res/merge-$t.err"; then
    git -C "$R" merge --abort 2>/dev/null || true
    # 冲突退回工人：在自己分支上合并集成分支顶部、解决冲突（对应模板续作节语义），再并回
    cat > "$res/leads-$t.md" <<NOTE
集成分支与本票分支存在冲突：在当前 worktree 内执行 git merge "$branch"，
逐个解决冲突（以集成分支为准处理公共文件，以本票验收为准处理本票文件），
跑通与改动直接相关的目标测试后在 $br 分支上提交（固定段第 6 条的本场景例外）。
NOTE
    bash "$script_dir/fill-prompt.sh" --skill-dir "$D" --type "$type" --ticket "$t" \
      --repo "$R" --goal-file "$goal_file" --ticket-file "$res/ticket-$t.md" \
      --leads-file "$res/leads-$t.md" > "$R/prompts/$t.md" || die "冲突轮填装失败"
    merge_args=(--worktree "$wt" --prompt "$R/prompts/$t.md" --log "$res/${chain}-$t.merge.log" --chain "$chain")
    [ -n "$agents" ] && merge_args+=(--agents "$agents")
    bash "$script_dir/dispatch.sh" "${merge_args[@]}" || die "冲突解决派发失败（$t）"
    git -C "$R" merge --no-ff -q "$br" -m "merge $t into $branch (resolved)" \
      || die "$t: 冲突解决后仍无法合并，升级编排者"
  fi
  # draft PR（幂等）：集成分支尚无 PR 时创建
  if [ "$open_pr" = true ]; then
    if ! (cd "$R" && gh pr list --head "$branch" --state open --json url | grep -q '"url"'); then
      (cd "$R" && gh pr create --draft --head "$branch" \
        --title "spec: $branch" --body "集成实现，关联票 $stem（关闭逻辑见 issue tracker）") \
        || echo "lifecycle: draft PR 创建失败，收尾时重试" >&2
    fi
  fi
fi
echo "lifecycle: $t done"
