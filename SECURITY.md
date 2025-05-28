# 🔒 安全配置指南

## ⚠️ 重要安全提醒

**绝对不要将真实的API密钥提交到Git仓库中！**

## 🚨 紧急情况处理

如果您的API密钥已经泄露：

1. **立即撤销泄露的密钥**
   - 登录 [DeepSeek开放平台](https://platform.deepseek.com/)
   - 进入 "API Keys" 管理页面
   - 删除泄露的API密钥
   - 生成新的API密钥

2. **检查可疑活动**
   - 查看API使用记录
   - 检查账单是否有异常消费
   - 监控账户活动日志

## 🔧 正确的配置方法

### 1. 环境变量配置

在您的系统中设置环境变量：

```bash
# Linux/macOS
export DEEPSEEK_API_KEY="your-new-api-key"

# Windows
set DEEPSEEK_API_KEY=your-new-api-key
```

### 2. 本地开发配置

创建 `backend/src/main/resources/application-local.yml`（此文件已在.gitignore中）：

```yaml
fortune:
  deepseek:
    api-key: your-actual-api-key-here
```

### 3. 生产环境配置

使用环境变量或安全的配置管理系统：

```yaml
fortune:
  deepseek:
    api-key: ${DEEPSEEK_API_KEY:default-placeholder}
```

## 📋 安全检查清单

- [ ] 已撤销泄露的API密钥
- [ ] 已生成新的API密钥
- [ ] 已更新所有配置文件，移除硬编码密钥
- [ ] 已配置环境变量
- [ ] 已验证.gitignore包含敏感文件模式
- [ ] 已测试应用程序正常运行

## 🛡️ 最佳实践

1. **使用环境变量**：所有敏感信息都通过环境变量传递
2. **定期轮换密钥**：定期更换API密钥
3. **最小权限原则**：只授予必要的API权限
4. **监控使用情况**：定期检查API使用记录
5. **代码审查**：提交前检查是否包含敏感信息

## 🔍 检测工具

使用以下命令检查代码中是否包含API密钥：

```bash
# 检查sk-开头的密钥
grep -r "sk-[a-zA-Z0-9]" . --exclude-dir=.git

# 检查deepseek相关配置
grep -ri "deepseek.*key" . --exclude-dir=.git
```

## 📞 联系方式

如果发现安全问题，请立即联系：
- 项目维护者
- 安全团队邮箱：security@yourcompany.com

---

**记住：安全是每个人的责任！** 