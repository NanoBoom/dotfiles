# Start configuration added by Zim install {{{
#
# User configuration sourced by interactive shells
#


# -----------------
# Debug
# -----------------
if [[ "$PROFILE_STARTUP" == true ]]; then
  zmodload zsh/zprof
fi

# -----------------
# Zsh configuration
# -----------------

#
# History
#

# Remove older command from the history if a duplicate is to be added.
setopt HIST_IGNORE_ALL_DUPS

#
# Input/output
#

# Set editor default keymap to emacs (`-e`) or vi (`-v`)
bindkey -e

# Prompt for spelling correction of commands.
#setopt CORRECT

# Customize spelling correction prompt.
#SPROMPT='zsh: correct %F{red}%R%f to %F{green}%r%f [nyae]? '

# Remove path separator from WORDCHARS.
WORDCHARS=${WORDCHARS//[\/]}

# -----------------
# Zim configuration
# -----------------

# Use degit instead of git as the default tool to install and update modules.
#zstyle ':zim:zmodule' use 'degit'

# --------------------
# Module configuration
# --------------------

#
# git
#

# Set a custom prefix for the generated zsh-defer aliases. The default prefix is 'G'.
#zstyle ':zim:git' zsh-defer aliases-prefix 'g'

#
# input
#

# Append `../` to your input for each `.` you type after an initial `..`
#zstyle ':zim:input' double-dot-expand yes

#
# termtitle
#

# Set a custom terminal title format using prompt expansion escape sequences.
# See http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html#Simple-Prompt-Escapes
# If none is provided, the default '%n@%m: %~' is used.
#zstyle ':zim:termtitle' format '%1~'

#
# zsh-autosuggestions
#

# Disable automatic widget re-binding on each precmd. This can be set when
# zsh-users/zsh-autosuggestions is the last module in your ~/.zimrc.
ZSH_AUTOSUGGEST_MANUAL_REBIND=1

# Customize the style that the suggestions are shown with.
# See https://github.com/zsh-users/zsh-autosuggestions/blob/master/README.md#suggestion-highlight-style
#ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=242'

#
# zsh-syntax-highlighting
#

# Set what highlighters will be used.
# See https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters.md
# ZSH_HIGHLIGHT_HIGHLIGHTERS=(main)

# Customize the main highlighter styles.
# See https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters/main.md#how-to-tweak-it
#typeset -A ZSH_HIGHLIGHT_STYLES
#ZSH_HIGHLIGHT_STYLES[comment]='fg=242'

#
# autoswitch_virtualenv
#
AUTOSWITCH_DEFAULT_PYTHON=python3

# ------------------
# Initialize modules
# ------------------

ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim
# Download zimfw plugin manager if missing.
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  if (( ${+commands[curl]} )); then
    curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  else
    mkdir -p ${ZIM_HOME} && wget -nv -O ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  fi
fi

# source defer load plugin
source ${ZIM_HOME}/modules/zsh-defer/zsh-defer.plugin.zsh

# setup default python
# export AUTOSWITCH_DEFAULT_PYTHON=/usr/bin/python3

# Install missing modules, and update ${ZIM_HOME}/init.zsh if missing or outdated.
if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZIM_CONFIG_FILE:-${ZDOTDIR:-${HOME}}/.zimrc} ]]; then
  zsh-defer source ${ZIM_HOME}/zimfw.zsh init -q
fi
# Initialize modules.
source ${ZIM_HOME}/init.zsh

# ------------------------------
# Post-init module configuration
# ------------------------------

#
# zsh-history-substring-search
#

zmodload -F zsh/terminfo +p:terminfo
# Bind ^[[A/^[[B manually so up/down works both before and after zle-line-init
for key ('^[[A' '^P' ${terminfo[kcuu1]}) bindkey ${key} history-substring-search-up
for key ('^[[B' '^N' ${terminfo[kcud1]}) bindkey ${key} history-substring-search-down
for key ('k') bindkey -M vicmd ${key} history-substring-search-up
for key ('j') bindkey -M vicmd ${key} history-substring-search-down
unset key
# }}} End configuration added by Zim install

# zsh zsh-autosuggestions keybind
zsh-defer bindkey '^O' autosuggest-accept
zsh-defer bindkey '^ ' autosuggest-execute


# ------------------
# Binary Load
# ------------------

path=(
  $HOME/.local/bin
  $path
)
export PATH


# ------------------
# Alias
# ------------------
zsh-defer alias icat="kitten icat"
zsh-defer alias vim=nvim
zsh-defer alias vi=nvim
# 智能判断 SSH Alias
if [[ -n "$TMUX" ]]; then
    # 如果在 Tmux 内部，直接使用原生 ssh
    zsh-defer alias ssh="ssh"
else
    # 如果不在 Tmux 内部，使用 kitten ssh (利用其 terminfo 自动分发功能)
    zsh-defer alias ssh="kitten ssh"
fi
if [[ $(uname) == "Linux" ]]; then
    zsh-defer alias open=xdg-open
fi


# # ------------------
# # My Custom Config
# # ------------------
#
# # Zsh 自带钩子：每次终端准备打印 prompt 提示符（准备让你输入下一条命令）前，执行该函数
# precmd() {
#   # 强制切换为英文 ABC
#   macism com.apple.keylayout.ABC
# }

# zoxide load
if [[ -f ~/.zoxide_init.zsh ]]; then
  # 静态配置文件存在，直接加载
  zsh-defer source ~/.zoxide_init.zsh
else
  # 静态配置不存在，动态生成
  if (( $+commands[zoxide] )); then
    zoxide init --cmd j zsh > ~/.zoxide_init.zsh
    zsh-defer source ~/.zoxide_init.zsh
  fi
fi

# vfox load
eval "$(vfox activate zsh)"
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

# rust load
. "$HOME/.cargo/env"

# --- Claude Code 优化版 ---

claude() {
    # 1. 设置标志位 (仅对当前 Pane 生效)
    tmux set-option -p @claude_active 1
    
    # 2. 只有当前是激活 pane 时才立即切中文（防止脚本后台启动干扰前台）
    # 大部分时候你是前台启动，这里肯定会执行
    if [ "$(tmux display-message -p '#{pane_active}')" = "1" ]; then
        macism im.rime.inputmethod.Squirrel.Hans
    fi

    # 3. 运行主程序
    command claude "$@"

    # 4. 程序退出后的清理逻辑
    
    # 4.1 移除标志位
    tmux set-option -p -u @claude_active
    
    # 4.2 【关键修改】检查当前 Pane 是否拥有焦点
    # 如果 Claude 在后台结束（比如你切到了别的 Pane），不要修改当前的输入法
    if [ "$(tmux display-message -p '#{pane_active}')" = "1" ]; then
        macism com.apple.keylayout.ABC
    fi
}
