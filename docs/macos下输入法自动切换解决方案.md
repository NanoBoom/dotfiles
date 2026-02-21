# macOS 下输入法自动切换解决方案

## 目录

- [概述](#概述)
- [系统架构](#系统架构)
- [环境要求](#环境要求)
- [工作原理](#工作原理)
- [配置指南](#配置指南)
  - [1. 安装依赖工具](#1-安装依赖工具)
  - [2. Zsh 配置](#2-zsh-配置)
  - [3. Tmux 配置](#3-tmux-配置)
  - [4. Neovim 配置](#4-neovim-配置)
  - [5. 鼠须管快捷输入配置（可选）](#5-鼠须管快捷输入配置可选)
- [使用效果](#使用效果)
- [故障排查](#故障排查)
- [进阶定制](#进阶定制)

## 概述

本方案实现了在 macOS 开发环境中，根据不同应用场景自动切换输入法的功能。主要解决以下痛点：

- **Claude Code**：启动时自动切换到中文输入法，退出后恢复英文
- **Neovim**：Insert 模式使用中文，Normal 模式使用英文
- **Tmux Pane 切换**：在不同 pane 间切换时，自动匹配对应应用的输入法状态
- **快捷输入**：通过鼠须管自定义短语，快速输入 Claude Code 命令

## 系统架构

```
┌─────────────────────────────────────────────────────────┐
│                    macOS 输入法系统                      │
│                         (macism)                        │
└────────────┬────────────────────────────┬───────────────┘
             │                            │
    ┌────────▼────────┐          ┌───────▼────────┐
    │   Tmux Hooks    │          │  Zsh Function  │
    │  (pane-focus)   │          │   (claude())   │
    └────────┬────────┘          └───────┬────────┘
             │                            │
    ┌────────▼────────────────────────────▼────────┐
    │         Tmux Pane 状态管理                    │
    │      (@claude_active 标志位)                  │
    └────────┬────────────────────────┬─────────────┘
             │                        │
    ┌────────▼────────┐      ┌───────▼──────────┐
    │  Claude Code    │      │     Neovim       │
    │  (中文输入法)    │      │  (im-select.nvim)│
    └─────────────────┘      └──────────────────┘
```

## 环境要求

- **操作系统**：macOS
- **Shell**：Zsh
- **终端复用器**：Tmux
- **编辑器**：Neovim
- **输入法**：鼠须管（Squirrel）或其他支持的输入法
- **输入法切换工具**：[macism](https://github.com/laishulu/macism)

## 工作原理

### 核心机制

整个方案基于三个层次的协同工作：

#### 1. Tmux 层：Pane 状态管理

Tmux 通过 `pane-focus-in` hook 监听 pane 切换事件，并根据以下条件决定输入法：

- **Claude Code 检测**：通过 `@claude_active` 标志位或 pane title 识别
- **Neovim 检测**：通过 `pane_current_command` 识别，但不主动切换（由 Neovim 插件管理）
- **其他应用**：默认切换到英文输入法

#### 2. Zsh 层：Claude Code 生命周期管理

通过包装 `claude` 命令，在启动和退出时执行输入法切换：

- **启动时**：设置 `@claude_active` 标志位，切换到中文输入法
- **退出时**：清除标志位，恢复英文输入法
- **焦点检测**：只在当前 pane 处于激活状态时才切换，避免后台干扰

#### 3. Neovim 层：模式感知切换

通过 `im-select.nvim` 插件监听 Neovim 模式变化：

- **Insert 模式**：自动切换到中文输入法
- **Normal/Command 模式**：自动切换到英文输入法
- **FocusGained 事件**：窗口获得焦点时恢复默认输入法

### 数据流

```
用户操作 → Tmux 事件 → 检查 pane 状态 → 调用 macism → 切换输入法
                ↓
         设置/清除标志位
                ↓
         影响下次切换判断
```

## 配置指南

### 1. 安装依赖工具

#### 安装 macism

```bash
brew install macism
```

#### 获取输入法标识符

```bash
# 查看当前使用的输入法
macism

# 列出所有可用的输入法（使用系统配置）
defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleEnabledInputSources | grep -E '(KeyboardLayout Name|Input Mode|Bundle ID)'

# 常用输入法标识符：
# - 英文：com.apple.keylayout.ABC
# - 鼠须管简体中文：im.rime.inputmethod.Squirrel.Hans
# - 鼠须管繁体中文：im.rime.inputmethod.Squirrel.Hant
```

**提示**：切换到你想要的输入法，然后运行 `macism` 即可获取其标识符。

### 2. Zsh 配置

在 `~/.zshrc` 中添加以下函数：

```bash
# Claude Code 输入法自动切换
claude() {
    # 1. 设置标志位 (仅对当前 Pane 生效)
    tmux set-option -p @claude_active 1

    # 2. 只有当前是激活 pane 时才立即切中文（防止脚本后台启动干扰前台）
    if [ "$(tmux display-message -p '#{pane_active}')" = "1" ]; then
        macism im.rime.inputmethod.Squirrel.Hans
    fi

    # 3. 运行主程序
    command claude "$@"

    # 4. 程序退出后的清理逻辑

    # 4.1 移除标志位
    tmux set-option -p -u @claude_active

    # 4.2 检查当前 Pane 是否拥有焦点
    # 如果 Claude 在后台结束（比如你切到了别的 Pane），不要修改当前的输入法
    if [ "$(tmux display-message -p '#{pane_active}')" = "1" ]; then
        macism com.apple.keylayout.ABC
    fi
}
```

**配置说明**：

- `tmux set-option -p @claude_active 1`：设置 pane 级别的自定义变量，标记当前 pane 正在运行 Claude Code
- `tmux display-message -p '#{pane_active}'`：检查当前 pane 是否处于激活状态（返回 1 表示激活）
- `command claude "$@"`：调用原始的 `claude` 命令，`"$@"` 传递所有参数
- `tmux set-option -p -u @claude_active`：清除标志位（`-u` 表示 unset）

**为什么需要焦点检测？**

如果在 Claude Code 运行时切换到其他 pane，然后 Claude Code 在后台退出，不检查焦点会导致其他 pane 的输入法被意外修改。

### 3. Tmux 配置

在 `~/.tmux.conf` 中添加以下 hook：

```bash
# Pane 切换时的输入法自动切换
set-hook -g pane-focus-in 'run-shell " \
    is_claude=\"#{?@claude_active,1,0}\"; \
    if [ \"#{pane_title}\" = \"✳ Claude Code\" ] || [ \"\$is_claude\" = \"1\" ]; then \
        macism im.rime.inputmethod.Squirrel.Hans; \
    elif [ \"#{pane_current_command}\" = \"nvim\" ] || [ \"#{pane_current_command}\" = \"vim\" ]; then \
        :; \
    else \
        macism com.apple.keylayout.ABC; \
    fi \
"'
```

**配置说明**：

- `set-hook -g pane-focus-in`：设置全局 hook，在任何 pane 获得焦点时触发
- `#{?@claude_active,1,0}`：Tmux 条件表达式，如果 `@claude_active` 存在则返回 1，否则返回 0
- `#{pane_title}`：当前 pane 的标题（Claude Code 会设置特定标题）
- `#{pane_current_command}`：当前 pane 正在运行的命令
- `:` 是 shell 的空操作命令，表示不做任何事（Neovim 的输入法由插件管理）

**判断逻辑**：

1. **Claude Code 检测**：通过 pane title 或 `@claude_active` 标志位识别 → 切换到中文
2. **Neovim 检测**：识别但不切换，交由 Neovim 插件管理
3. **其他应用**：默认切换到英文

**为什么使用 OR 逻辑？**

- `pane_title` 检测：适用于 Claude Code 正常运行时
- `@claude_active` 标志位：适用于 Claude Code 启动瞬间（title 可能还未更新）

### 4. Neovim 配置

#### 安装插件

使用 Lazy.nvim 安装 [im-select.nvim](https://github.com/NanoBoom/im-select.nvim)：

在 `~/.config/nvim/lua/plugins/im-select.lua` 中添加：

```lua
return {
  "NanoBoom/im-select.nvim",
  event = "VeryLazy",
  config = function()
    require("im_select").setup({
      default_im_select = "com.apple.keylayout.ABC",
      insert_im = "im.rime.inputmethod.Squirrel.Hans",
      set_default_events = { "InsertLeave", "CmdlineLeave", "FocusGained" },
    })
  end,
}
```

**配置说明**：

- `default_im_select`：默认输入法（Normal 模式使用）
- `insert_im`：Insert 模式使用的输入法
- `set_default_events`：触发切换到默认输入法的事件
  - `InsertLeave`：离开 Insert 模式时
  - `CmdlineLeave`：离开命令行模式时
  - `FocusGained`：窗口获得焦点时

**插件修改说明**：

原版 `im-select.nvim` 不支持明确指定 Insert 模式的输入法。如果你使用的是修改版，可以通过 `insert_im` 参数直接指定，避免依赖"记忆上次输入法"的逻辑。

**可用命令**：

- `:ImSelectToggle` - 临时禁用/启用输入法自动切换功能

### 5. 鼠须管快捷输入配置（可选）

通过鼠须管的自定义短语功能，可以快速输入 Claude Code 命令。

#### 配置自定义短语引擎

创建或编辑 `~/Library/Rime/rime_mint.custom.yaml`：

```yaml
# Rime Custom
# encoding: utf-8

patch:
  "engine/translators/+":
    - table_translator@mint_simple            # 薄荷自定义短语

  # 薄荷自定义短语
  mint_simple:
    dictionary: ""
    user_dict: dicts/rime_mint.simple
    db_class: stabledb
    enable_completion: false
    enable_sentence: false
    initial_quality: 99
    comment_format:
      - xform/^.+$//
```

**配置说明**：

- `table_translator@mint_simple`：注册一个名为 `mint_simple` 的翻译器
- `user_dict: dicts/rime_mint.simple`：指定词典文件路径（相对于 Rime 用户目录）
- `initial_quality: 99`：设置高优先级，确保自定义短语优先显示
- `comment_format: - xform/^.+$//`：隐藏候选词的注释

#### 创建词典文件

创建 `~/Library/Rime/dicts/rime_mint.simple.txt`：

```
# Rime table
# coding: utf-8
#@/db_name rime_mint.simple.txt
#@/db_type tabledb
#
#
# 此行之后不能写注释
/feature-dev:feature-dev	fdev	1
/prp-core:prp-prd	prd	1
/prp-core:prp-plan	pl	1
/prp-core:prp-pr	pr	1
/prp-core:prp-debug	db	1
/prp-core:prp-commit	ct	1
```

**格式说明**：

```
输出文本	输入码	权重
```

- 使用 Tab 分隔（不是空格）
- 权重越高，候选词排序越靠前

#### 重新部署鼠须管

配置完成后，需要重新部署：

1. 点击菜单栏的鼠须管图标
2. 选择"重新部署"（Deploy）
3. 等待部署完成

**使用示例**：

输入 `fdev`，候选词中会出现 `/feature-dev:feature-dev`，选择后即可快速输入完整命令。

## 使用效果

配置完成后，你将获得以下体验：

### 1. Claude Code 自动切换

- **启动时**：自动切换到中文输入法，方便与 AI 对话
- **退出时**：自动恢复英文输入法，回到命令行环境

### 2. Neovim 模式感知

- **Insert 模式**：自动使用中文输入法，方便编写中文内容
- **Normal 模式**：自动切换到英文输入法，避免误触中文输入
- **临时禁用**：使用 `:ImSelectToggle` 命令可临时关闭自动切换

### 3. Tmux Pane 智能切换

在 Tmux 中分屏使用多个应用时：

- 切换到 **Claude Code pane**：自动切换到中文输入法
- 切换到 **Neovim pane**：保持 Neovim 插件管理的输入法状态
- 切换到 **其他 pane**（如 shell）：自动切换到英文输入法

### 4. 快捷输入命令

在 Claude Code 中，通过鼠须管快捷输入：

- 输入 `fdev` → `/feature-dev:feature-dev`
- 输入 `prd` → `/prp-core:prp-prd`
- 输入 `pl` → `/prp-core:prp-plan`

## 故障排查

### 问题 1：输入法没有自动切换

**可能原因**：

1. `macism` 未安装或不在 PATH 中
2. 输入法标识符不正确
3. Tmux/Zsh 配置未生效

**解决方法**：

```bash
# 检查 macism 是否安装
which macism

# 检查当前输入法标识符
macism

# 手动测试切换
macism com.apple.keylayout.ABC
macism im.rime.inputmethod.Squirrel.Hans

# 重新加载 Zsh 配置
source ~/.zshrc

# 重新加载 Tmux 配置
tmux source-file ~/.tmux.conf
```

### 问题 2：Tmux pane 切换时输入法错乱

**可能原因**：

1. `@claude_active` 标志位未正确设置/清除
2. Tmux hook 中的条件判断逻辑错误

**解决方法**：

```bash
# 检查当前 pane 的标志位
tmux show-options -p @claude_active

# 手动清除标志位
tmux set-option -p -u @claude_active

# 检查 pane title
tmux display-message -p '#{pane_title}'

# 检查当前命令
tmux display-message -p '#{pane_current_command}'
```

### 问题 3：Neovim 输入法切换不生效

**可能原因**：

1. `im-select.nvim` 插件未正确安装
2. 插件配置中的输入法标识符错误
3. `macism` 权限问题

**解决方法**：

```vim
" 在 Neovim 中检查插件是否加载
:Lazy

" 检查插件配置
:lua print(vim.inspect(require("im_select").config))

" 手动测试输入法切换
:lua vim.fn.system("macism com.apple.keylayout.ABC")
:lua vim.fn.system("macism im.rime.inputmethod.Squirrel.Hans")

" 临时禁用插件测试
:ImSelectToggle
```

### 问题 4：鼠须管快捷输入不生效

**可能原因**：

1. 配置文件路径错误
2. 词典文件格式错误（使用空格而非 Tab）
3. 未重新部署鼠须管

**解决方法**：

```bash
# 检查配置文件是否存在
ls -la ~/Library/Rime/rime_mint.custom.yaml
ls -la ~/Library/Rime/dicts/rime_mint.simple.txt

# 检查词典文件格式（应该看到 Tab 字符）
cat -A ~/Library/Rime/dicts/rime_mint.simple.txt

# 重新部署鼠须管
# 点击菜单栏鼠须管图标 → 重新部署

# 查看部署日志
tail -f ~/Library/Rime/rime.*.INFO
```

### 问题 5：Claude Code 在后台退出时输入法被意外修改

**原因**：

这是预期行为。如果 Claude Code 在后台退出（你已经切换到其他 pane），Zsh 函数会检测到当前 pane 不是激活状态，因此不会修改输入法。

**验证**：

```bash
# 在 Claude Code 运行时切换到其他 pane
# 然后在原 pane 中退出 Claude Code
# 当前 pane 的输入法应该不会被修改
```

## 进阶定制

### 自定义输入法

如果你使用的不是鼠须管，可以修改配置中的输入法标识符：

```bash
# 查看当前输入法标识符
macism

# 列出所有可用输入法
defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleEnabledInputSources | grep -E '(KeyboardLayout Name|Input Mode|Bundle ID)'

# 常见输入法标识符：
# - 搜狗输入法：com.sogou.inputmethod.sogou
# - 百度输入法：com.baidu.inputmethod.BaiduIM
# - 微信输入法：com.tencent.inputmethod.wetype
# - 系统拼音：com.apple.inputmethod.SCIM.ITABC
```

**获取输入法标识符的简单方法**：
1. 切换到你想要使用的输入法
2. 在终端运行 `macism`
3. 输出的字符串就是该输入法的标识符

然后在配置文件中替换 `im.rime.inputmethod.Squirrel.Hans` 为你的输入法标识符。

### 添加更多应用的输入法规则

在 Tmux 配置中添加更多应用的判断逻辑：

```bash
set-hook -g pane-focus-in 'run-shell " \
    is_claude=\"#{?@claude_active,1,0}\"; \
    if [ \"#{pane_title}\" = \"✳ Claude Code\" ] || [ \"\$is_claude\" = \"1\" ]; then \
        macism im.rime.inputmethod.Squirrel.Hans; \
    elif [ \"#{pane_current_command}\" = \"nvim\" ] || [ \"#{pane_current_command}\" = \"vim\" ]; then \
        :; \
    elif [ \"#{pane_current_command}\" = \"python\" ]; then \
        macism im.rime.inputmethod.Squirrel.Hans; \
    elif [ \"#{pane_current_command}\" = \"node\" ]; then \
        macism com.apple.keylayout.ABC; \
    else \
        macism com.apple.keylayout.ABC; \
    fi \
"'
```

### 为其他 CLI 工具添加输入法切换

参考 `claude()` 函数，为其他工具创建类似的包装函数：

```bash
# 为 Python REPL 添加输入法切换
python() {
    tmux set-option -p @python_active 1
    if [ "$(tmux display-message -p '#{pane_active}')" = "1" ]; then
        macism im.rime.inputmethod.Squirrel.Hans
    fi
    command python "$@"
    tmux set-option -p -u @python_active
    if [ "$(tmux display-message -p '#{pane_active}')" = "1" ]; then
        macism com.apple.keylayout.ABC
    fi
}
```

### 调试技巧

启用 Tmux hook 调试：

```bash
# 在 ~/.tmux.conf 中添加日志输出
set-hook -g pane-focus-in 'run-shell " \
    echo \"[$(date)] Pane: #{pane_id}, Title: #{pane_title}, Command: #{pane_current_command}\" >> /tmp/tmux-im-debug.log; \
    is_claude=\"#{?@claude_active,1,0}\"; \
    echo \"[$(date)] is_claude: \$is_claude\" >> /tmp/tmux-im-debug.log; \
    # ... 原有逻辑 ...
"'

# 实时查看日志
tail -f /tmp/tmux-im-debug.log
```

---

## 参考资料

- [macism - macOS 输入法切换工具](https://github.com/laishulu/macism)
- [im-select.nvim - Neovim 输入法自动切换插件](https://github.com/NanoBoom/im-select.nvim)
- [鼠须管输入法](https://rime.im/)
- [Tmux Hooks 文档](https://github.com/tmux/tmux/wiki/Hooks)
