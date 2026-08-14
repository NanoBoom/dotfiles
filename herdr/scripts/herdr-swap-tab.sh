#!/bin/bash
# 把当前 tab 与左/右相邻的 tab 交换位置（tmux: swap-window -t -1 / +1）
# herdr 没有内置的 move/swap tab 动作，这里走 socket API 的 tab.move。
#
# 用法: herdr-swap-tab.sh left|right
#
# tab.list 返回的是全部 workspace（窗口）的 tab，而 tab.move 的 insert_index 是
# workspace 内坐标，所以要先按 focused tab 的 workspace_id 过滤再算下标，否则会
# 拿到跨窗口的全局下标而报 insert_index out of bounds。
#
# insert_index 是「原列表坐标」：表示插到当前 insert_index 位置那个 tab 的前面。
# 所以左移是 idx-1，右移是 idx+2。
set -euo pipefail

dir="${1:-right}"
sock="${HERDR_SOCKET_PATH:-$HOME/.config/herdr/herdr.sock}"

api() { printf '%s\n' "$1" | /usr/bin/nc -U "$sock"; }

IFS=$'\t' read -r tab_id idx count <<<"$(
  api '{"id":"swap-tab:list","method":"tab.list","params":{}}' |
    /usr/bin/jq -r '
      .result.tabs as $all
      | ($all | map(select(.focused)) | first) as $cur
      | if $cur == null then ["", -1, 0]
        else ($all | map(select(.workspace_id == $cur.workspace_id))) as $t
          | [$cur.tab_id, ($t | map(.focused) | index(true)), ($t | length)]
        end
      | @tsv'
)"

[ -n "$tab_id" ] && [ "$idx" -ge 0 ] || exit 0

case "$dir" in
left)
  [ "$idx" -gt 0 ] || exit 0 # 已经在最左边，改成 target=$count 可实现循环
  target=$((idx - 1))
  ;;
right)
  [ "$idx" -lt $((count - 1)) ] || exit 0 # 已经在最右边，改成 target=0 可实现循环
  target=$((idx + 2))
  ;;
*)
  echo "用法: $0 left|right" >&2
  exit 2
  ;;
esac

# 正常静默（keybinding 调用，stdout 无处可去），只把错误抛到 stderr
api "{\"id\":\"swap-tab:move\",\"method\":\"tab.move\",\"params\":{\"tab_id\":\"$tab_id\",\"insert_index\":$target}}" |
  /usr/bin/jq -r 'if .error then "tab.move 失败: \(.error.message)" else empty end' >&2
