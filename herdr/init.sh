#!/usr/bin/env bash
# herdr 初始化：把本目录的配置链接到 ~/.config/herdr，并安装所需插件。
# 可重复执行（幂等）：已存在的正确链接会跳过，非链接的旧文件会先备份。
#
# 用法: ./init.sh
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HERDR_CONFIG_DIR:-$HOME/.config/herdr}"

PLUGIN_REPO="lmilojevicc/herdr-splits.nvim"   # 与 Neovim 分屏无缝互跳（ctrl+h/j/k/l）
PLUGIN_NAME="herdr-splits"

info() { printf '\033[32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m[warn]\033[0m %s\n' "$*" >&2; }
die() {
  printf '\033[31m[error]\033[0m %s\n' "$*" >&2
  exit 1
}

command -v herdr >/dev/null 2>&1 || die "未找到 herdr，请先安装：brew install herdr"

# link <本目录内的相对路径> <目标绝对路径>
link() {
  local src="$DOTFILES_DIR/$1" dst="$2" backup
  [ -e "$src" ] || die "缺少 $src"

  if [ -L "$dst" ]; then
    if [ "$(readlink "$dst")" = "$src" ]; then
      info "已链接：$dst"
      return
    fi
    rm -f "$dst"
  elif [ -e "$dst" ]; then
    backup="$dst.bak.$(date +%Y%m%d%H%M%S)"
    warn "$dst 已存在，备份为 $backup"
    mv "$dst" "$backup"
  fi

  ln -sfn "$src" "$dst"
  info "链接：$dst -> $src"
}

info "配置目录：$CONFIG_DIR"
mkdir -p "$CONFIG_DIR"

chmod +x "$DOTFILES_DIR"/scripts/*.sh
link config.toml "$CONFIG_DIR/config.toml"
link scripts "$CONFIG_DIR/scripts"

# config.toml 里 [[keys.command]] 的 shell 命令写的是绝对路径，换机器/换用户名需同步修改
if ! grep -q "$CONFIG_DIR/scripts/herdr-swap-tab.sh" "$DOTFILES_DIR/config.toml"; then
  warn "config.toml 中 herdr-swap-tab.sh 的绝对路径与 $CONFIG_DIR 不一致，请手动更新 [[keys.command]] 的 command 字段"
fi

# 插件：herdr plugin list 输出形如 "- herdr-splits (Herdr Splits) enabled [...]"
if herdr plugin list 2>/dev/null | grep -q -- "- $PLUGIN_NAME "; then
  info "插件 $PLUGIN_NAME 已安装，跳过"
else
  info "安装插件：$PLUGIN_REPO"
  herdr plugin install "$PLUGIN_REPO"
fi

# herdr-swap-tab.sh 直接调用 /usr/bin/jq 和 /usr/bin/nc（macOS 自带）
for bin in /usr/bin/jq /usr/bin/nc; do
  [ -x "$bin" ] || warn "缺少 $bin，herdr-swap-tab.sh（alt+left/right 交换 tab）将无法工作"
done

if herdr server reload-config >/dev/null 2>&1; then
  info "已热加载运行中的 herdr 配置"
else
  info "herdr 未在运行，配置将在下次启动时生效"
fi

info "完成"
