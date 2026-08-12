#!/bin/bash
# 把当前 tab 与左/右相邻的 tab 交换位置（tmux: swap-window -t -1 / +1）
# herdr 没有内置的 move/swap tab 动作，这里走 socket API 的 tab.move。
#
# 用法: herdr-swap-tab.sh left|right
#
# tab.move 的 insert_index 是「原列表坐标」：表示插到当前 insert_index 位置那个
# tab 的前面。所以左移是 idx-1，右移是 idx+2。
set -euo pipefail

dir="${1:-right}"
sock="${HERDR_SOCKET_PATH:-$HOME/.config/herdr/herdr.sock}"

api() { printf '%s\n' "$1" | /usr/bin/nc -U "$sock"; }

read -r tab_id idx count <<<"$(
  api '{"id":"swap-tab:list","method":"tab.list","params":{}}' |
    /usr/bin/jq -r '
      .result.tabs as $t
      | [($t | map(select(.focused))[0].tab_id // ""),
         ($t | map(.focused) | index(true) // -1),
         ($t | length)]
      | @tsv'
)"

[ -n "$tab_id" ] && [ "$idx" -ge 0 ] || exit 0

case "$dir" in
  left)
    [ "$idx" -gt 0 ] || exit 0            # 已经在最左边，改成 target=$count 可实现循环
    target=$((idx - 1))
    ;;
  right)
    [ "$idx" -lt $((count - 1)) ] || exit 0  # 已经在最右边，改成 target=0 可实现循环
    target=$((idx + 2))
    ;;
  *)
    echo "用法: $0 left|right" >&2
    exit 2
    ;;
esac

api "{\"id\":\"swap-tab:move\",\"method\":\"tab.move\",\"params\":{\"tab_id\":\"$tab_id\",\"insert_index\":$target}}" >/dev/null
