#!/usr/bin/env sh

PID="$1"

# pane 里跑着 nvim 就别碰输入法，im-select.nvim 在管
if pstree "$PID" | grep -qE 'n?vim'; then
  exit 0
fi

if [ "$(uname)" = "Darwin" ]; then
  # macOS: 需要 brew install pstree
  if pstree "$PID" | grep -q claude; then
    macism im.rime.inputmethod.Squirrel.Hans
  else
    macism com.apple.keylayout.ABC
  fi
else
  # Windows/WSL
  if pstree -ap "$PID" | grep -q claude; then
    im-select-mspy.exe -k=ctrl+space 中文模式
  else
    im-select-mspy.exe -k=ctrl+space 英语模式
  fi
fi
