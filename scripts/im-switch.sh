#!/usr/bin/sh

PID="$1"

if pstree -ap "$PID" | grep -q claude; then
  im-select-mspy.exe -k=ctrl+space 中文模式
else
  im-select-mspy.exe -k=ctrl+space 英语模式
fi
