# Dotfiles

个人开发环境配置文件集合，包含 Zsh、Tmux、herdr、Neovim 等工具的配置。

## 特性

### 🎯 输入法自动切换

在 macOS 开发环境中实现智能输入法切换：

- **Claude Code**：启动时自动切换到中文，退出后恢复英文
- **Neovim**：Insert 模式使用中文，Normal 模式使用英文
- **Tmux Pane 切换**：根据不同应用自动匹配输入法
- **快捷输入**：通过鼠须管快速输入 Claude Code 命令

详细配置说明请查看：[macOS 输入法自动切换解决方案](docs/macos下输入法自动切换解决方案.md)

### 🛠️ 工具配置

- **Shell**：Zsh + [Zim](https://github.com/zimfw/zimfw) 框架
- **终端工作区**：Tmux + [Gruvbox 主题](https://github.com/egel/tmux-gruvbox)，以及 [herdr](https://github.com/herdr-dev/herdr)
- **编辑器**：Neovim + [LazyVim](https://www.lazyvim.org/)
- **输入法**：鼠须管（Squirrel）+ 自定义短语

## 依赖项

### 必需

- **Neovim** - 现代化的 Vim 编辑器
- **Zsh** - Shell 环境
- **Tmux** - 终端复用器
- **herdr** - 终端工作区管理器
- **macism** - macOS 输入法切换工具（仅 macOS）
  ```bash
  brew install macism
  ```

### 可选

- **xdg-open** - 文件打开工具（WSL 环境）
- **鼠须管输入法** - 开源中文输入法

### 相关项目

- [CodeGPT](https://github.com/doodleEsc/CodeGPT.git) - AI 代码助手
- [FastAPI Template](https://github.com/s3rius/FastAPI-template.git) - FastAPI 项目模板

## 配置文件说明

### Shell 配置

- `zshrc` - Zsh 主配置文件
  - 包含 Claude Code 输入法自动切换函数
  - 集成 zoxide、vfox 等工具
  - 自定义别名和快捷键绑定

- `zimrc` - Zim 框架配置

### Tmux 配置

- `tmux/tmux.conf` - Tmux 主配置文件
  - 前缀键：`Ctrl+g`
  - Pane 切换输入法自动管理
  - Gruvbox 主题
  - 智能 Vim 导航集成
- `tmux/scripts/im-switch.sh` - Pane 切换时的输入法管理脚本
- `tmux/init.sh` - 建立主配置与辅助脚本的符号链接

### Neovim 配置

使用 LazyVim 配置框架：

- **Starter**: https://github.com/doodleEsc/starter.git
- **Config**: https://github.com/doodleEsc/LazyVim.git

主要插件：
- `im-select.nvim` - 输入法自动切换
- 其他插件请查看 LazyVim 配置仓库

### 鼠须管配置

- `Rime/rime_mint.custom.yaml` - 自定义短语引擎配置
- `Rime/dicts/rime_mint.simple.txt` - 快捷输入词典

### herdr 配置

[herdr](https://github.com/herdr-dev/herdr) 是面向 AI 编码 agent 的终端工作区管理器，键位整体向 tmux 肌肉记忆对齐（前缀键同样是 `Ctrl+g`）。

- `herdr/config.toml` - 主配置（主题、键位、自定义命令绑定）
- `herdr/scripts/herdr-swap-tab.sh` - 交换 tab 顺序（`Alt+Left/Right`，走 socket API 的 `tab.move`）
- `herdr/init.sh` - 初始化脚本：建立符号链接 + 安装 [herdr-splits](https://github.com/lmilojevicc/herdr-splits.nvim) 插件

```bash
brew install herdr
~/dotfiles/herdr/init.sh
```

插件 `herdr-splits` 提供 `Ctrl+h/j/k/l` 在 herdr pane 与 Neovim 分屏之间无缝跳转，以及 `Alt+h/j/k/l` 直接调整 pane 尺寸。其配置文件由 Neovim 端的 `setup()` 自动生成，无需纳入版本管理。

> 注意：`config.toml` 中 shell 类型的命令绑定使用绝对路径，换用户名或换机器时需同步修改。

### 其他工具

- `gitconfig` - Git 配置
- `clipboard-provider` - 剪贴板工具
- `cert_tools.sh` - 证书管理工具

## 快速开始

### 1. 克隆仓库

```bash
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles
```

### 2. 安装依赖

```bash
# macOS
brew install neovim tmux herdr macism

# 安装 Zim 框架
curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
```

### 3. 创建符号链接

```bash
# Zsh
ln -sf ~/dotfiles/zshrc ~/.zshrc
ln -sf ~/dotfiles/zimrc ~/.zimrc

# Tmux（链接主配置与辅助脚本）
~/dotfiles/tmux/init.sh

# Git
ln -sf ~/dotfiles/gitconfig ~/.gitconfig

# 鼠须管（可选）
ln -sf ~/dotfiles/Rime/rime_mint.custom.yaml ~/Library/Rime/rime_mint.custom.yaml
ln -sf ~/dotfiles/Rime/dicts ~/Library/Rime/dicts

# herdr（链接配置并安装插件）
~/dotfiles/herdr/init.sh
```

### 4. 配置 Neovim

```bash
# 克隆 LazyVim 配置
git clone https://github.com/doodleEsc/starter.git ~/.config/nvim
git clone https://github.com/doodleEsc/LazyVim.git ~/.config/nvim/lua/lazyvim

# 启动 Neovim 安装插件
nvim
```

### 5. 重新加载配置

```bash
# 重新加载 Zsh
source ~/.zshrc

# 重新加载 Tmux（在 Tmux 会话中）
tmux source-file ~/.tmux.conf

# 重新部署鼠须管（可选）
# 点击菜单栏鼠须管图标 → 重新部署
```

## 使用技巧

### Tmux 快捷键

- `Ctrl+g` - 前缀键
- `Ctrl+g -` - 垂直分割
- `Ctrl+g \` - 水平分割
- `Ctrl+h/j/k/l` - 在 pane 间导航（兼容 Vim）
- `Shift+Left/Right` - 切换窗口

### Zsh 别名

- `vim` / `vi` → `nvim`
- `icat` → `kitten icat`（Kitty 终端图片查看）
- `j <path>` → 快速跳转（zoxide）

### 鼠须管快捷输入

在中文输入法下：

- `fdev` → `/feature-dev:feature-dev`
- `prd` → `/prp-core:prp-prd`
- `pl` → `/prp-core:prp-plan`
- `pr` → `/prp-core:prp-pr`

## 故障排查

如果遇到问题，请查看：

- [输入法自动切换故障排查](docs/macos下输入法自动切换解决方案.md#故障排查)
- 检查依赖工具是否正确安装：`which macism nvim tmux herdr`
- 查看配置文件是否正确链接：`ls -la ~/.zshrc ~/.tmux.conf ~/.config/herdr/config.toml`

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License
