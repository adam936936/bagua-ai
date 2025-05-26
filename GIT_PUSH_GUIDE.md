# 🚀 Git推送指南

## 📊 当前状态
- ✅ 代码已提交到本地Git仓库
- ✅ Git用户配置完成 (xiatian / adam936@163.com)
- ✅ 远程仓库已配置
  - GitHub: https://github.com/adam936936/bagua-ai.git
  - Gitee: https://gitee.com/zhangyq93/bagua-ai.git

## ❌ GitHub认证问题
GitHub在2021年8月13日停止支持密码认证，需要使用Personal Access Token。

## 🔧 解决方案

### 方案1：GitHub + Personal Access Token（推荐）

#### 步骤1：生成GitHub Personal Access Token
1. 访问：https://github.com/settings/tokens
2. 点击 "Generate new token" → "Generate new token (classic)"
3. 设置：
   - Token名称：`bagua-ai-project`
   - 过期时间：选择合适的时间（建议90天或更长）
   - 权限：勾选 `repo` (完整仓库访问权限)
4. 点击 "Generate token"
5. **重要**：立即复制生成的token（只显示一次！）

#### 步骤2：使用Token推送
```bash
git push origin main
```
- 用户名：`adam936@163.com`
- 密码：输入刚才生成的Personal Access Token（不是GitHub密码）

### 方案2：使用Gitee（更简单）

Gitee仍然支持用户名+密码认证：

```bash
git push gitee main
```
- 用户名：`zhangyq93`
- 密码：您的Gitee账户密码

### 方案3：SSH密钥（一次配置，永久使用）

#### 生成SSH密钥
```bash
ssh-keygen -t rsa -b 4096 -C "adam936@163.com"
```

#### 添加SSH密钥到GitHub/Gitee
1. 复制公钥：`cat ~/.ssh/id_rsa.pub`
2. 在GitHub/Gitee设置中添加SSH密钥
3. 更改远程仓库URL为SSH格式：
```bash
git remote set-url origin git@github.com:adam936936/bagua-ai.git
git remote set-url gitee git@gitee.com:zhangyq93/bagua-ai.git
```

## 🎯 推荐操作顺序

1. **立即尝试Gitee推送**（最简单）：
   ```bash
   git push gitee main
   ```

2. **如果需要GitHub**，生成Personal Access Token后：
   ```bash
   git push origin main
   ```

## 📝 推送后验证

推送成功后，您可以访问以下地址验证：
- Gitee: https://gitee.com/zhangyq93/bagua-ai
- GitHub: https://github.com/adam936936/bagua-ai

## 🔍 故障排除

如果推送仍然失败：
1. 检查网络连接
2. 确认用户名和密码/token正确
3. 检查仓库权限
4. 尝试使用SSH密钥

## 📦 项目内容

本次推送包含：
- 完整的Spring Boot后端代码
- 前端测试页面和脚本
- 配置文件和文档
- API测试报告
- 部署脚本和指南 