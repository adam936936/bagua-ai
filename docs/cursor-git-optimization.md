# Cursor IDE Git认证优化指南

## 🎯 目标
消除Cursor中频繁弹出的GitHub账号密码输入框，提升开发体验。

## 🚀 立即生效的解决方案

### 方案1：macOS Keychain集成（推荐）
```bash
# 配置Git使用系统钥匙串
git config --global credential.helper osxkeychain

# 验证配置
git config --global --get credential.helper
```

**优势：** 
- 系统级安全存储
- 自动填充凭据
- 支持多账户

### 方案2：SSH密钥配置（最佳长期方案）
```bash
# 1. 生成SSH密钥
ssh-keygen -t ed25519 -C "your-email@example.com" -f ~/.ssh/id_ed25519 -N ""

# 2. 启动SSH代理
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# 3. 复制公钥到剪贴板
pbcopy < ~/.ssh/id_ed25519.pub

# 4. 更新远程仓库为SSH格式
git remote set-url origin git@github.com:username/repo.git
```

### 方案3：GitHub CLI（现代化方案）
```bash
# 安装GitHub CLI
brew install gh

# 登录认证
gh auth login

# 配置Git集成
gh auth setup-git
```

## ⚙️ Cursor IDE专用设置

### 1. 用户设置配置
打开Cursor → 设置 → 搜索"git"，添加以下配置：

```json
{
  "git.autofetch": true,
  "git.enableSmartCommit": true,
  "git.confirmSync": false,
  "git.terminalAuthentication": false,
  "git.useIntegratedTerminal": true,
  "git.useEditorAsCommitInput": false,
  "terminal.integrated.inheritEnv": false
}
```

### 2. 工作区设置
在项目根目录创建 `.vscode/settings.json`：

```json
{
  "git.autofetch": true,
  "git.confirmSync": false,
  "git.terminalAuthentication": false
}
```

## 🔧 Shell环境优化

### 添加到 ~/.zshrc 或 ~/.bash_profile
```bash
# SSH Agent自动启动
if [ -z "$SSH_AUTH_SOCK" ]; then
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi

# Git别名优化
alias gp="git push"
alias gpl="git pull"
alias gs="git status"
alias gc="git commit -m"
```

## 📋 快速配置检查清单

- [ ] 配置Git凭据助手：`git config --global credential.helper osxkeychain`
- [ ] 生成并配置SSH密钥
- [ ] 更新Cursor用户设置
- [ ] 测试Git操作无密码提示
- [ ] 配置Shell环境自动化

## 🐛 常见问题解决

### 问题1：仍然弹出密码框
**解决：** 检查远程仓库URL格式
```bash
git remote -v
# 确保使用SSH格式：git@github.com:user/repo.git
```

### 问题2：SSH连接失败
**解决：** 测试SSH连接
```bash
ssh -T git@github.com
# 应该显示：Hi username! You've successfully authenticated...
```

### 问题3：Cursor设置不生效
**解决：** 重启Cursor IDE，或检查设置语法

## 🎉 验证配置成功

配置完成后，执行以下测试：

```bash
# 1. 测试Git凭据
git config --global --get credential.helper

# 2. 测试SSH连接
ssh -T git@github.com

# 3. 测试推送（应该无密码提示）
git push
```

## 💡 额外优化建议

1. **使用Git GUI工具：** 如GitKraken、SourceTree等
2. **配置多SSH密钥：** 支持多个GitHub账户
3. **使用Personal Access Token：** 作为HTTPS的替代方案
4. **定期更新凭据：** 保持安全性

---

**配置完成后，您在Cursor中的Git操作将变得丝滑流畅！** 🚀 