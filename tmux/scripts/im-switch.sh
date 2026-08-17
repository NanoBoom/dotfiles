#!/usr/bin/env sh

CLIENT_NAME="$1"
PANE_ID="$2"
PID="$3"

# 后台 hook 结束时焦点可能已经改变，避免旧任务覆盖当前 pane 的输入法。
is_current_pane() {
  [ "$(tmux display-message -p -t "$CLIENT_NAME" '#{pane_id}' 2>/dev/null)" = "$PANE_ID" ]
}

if [ "$(uname)" = "Darwin" ]; then
  process_tree=$(pstree "$PID")

  # pane 里跑着 nvim 就别碰输入法，im-select.nvim 在管
  if printf '%s\n' "$process_tree" | grep -qE 'n?vim'; then
    exit 0
  fi

  # macOS: 需要 brew install pstree
  if printf '%s\n' "$process_tree" | grep -q claude; then
    input_method='im.rime.inputmethod.Squirrel.Hans'
  else
    input_method='com.apple.keylayout.ABC'
  fi

  is_current_pane || exit 0
  macism "$input_method"
else
  process_tree=$(pstree -ap "$PID")

  # Windows/WSL
  if printf '%s\n' "$process_tree" | grep -q claude; then
    input_mode='中文模式'
  else
    input_mode='英语模式'
  fi

  is_current_pane || exit 0
  im-select-mspy.exe -k=ctrl+space "$input_mode"
fi
