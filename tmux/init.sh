#!/usr/bin/env sh

set -eu

TMUX_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

mkdir -p "$HOME/.tmux/scripts"
ln -sfn "$TMUX_DIR/tmux.conf" "$HOME/.tmux.conf"
ln -sfn "$TMUX_DIR/scripts/im-switch.sh" "$HOME/.tmux/scripts/im-switch.sh"

echo "Tmux 配置已链接："
echo "  $HOME/.tmux.conf -> $TMUX_DIR/tmux.conf"
echo "  $HOME/.tmux/scripts/im-switch.sh -> $TMUX_DIR/scripts/im-switch.sh"
