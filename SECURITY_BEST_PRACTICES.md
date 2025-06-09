# 🔐 安全最佳实践指南

## 📊 安全问题修复总结

经过全面安全扫描，我们已修复以下敏感信息泄漏：

### ✅ 已修复的泄漏问题

1. **微信AppID泄漏** - `wx[已隐藏16位字符]` 
   - 已从所有配置文件中移除
   - 替换为占位符 `[请配置您的微信AppID]`

2. **微信AppSecret泄漏** - `[已隐藏32位字符]`
   - 已从所有脚本和配置文件中移除
   - 替换为占位符 `[请配置您的微信AppSecret]`

3. **DeepSeek API Key泄漏** - `sk-[已隐藏40位字符]`
   - 已从所有文件中移除
   - 替换为占位符 `[请配置您的API密钥]`

4. **JWT Secret硬编码**
   - 移除了硬编码的JWT密钥
   - 替换为占位符 `[请配置您的JWT密钥]`

## 🛡️ 环境变量管理最佳实践

### 1. 使用环境变量

**创建 `.env.local` 文件**（不会被Git追踪）：
```bash
# 微信小程序配置
WECHAT_APP_ID=your_actual_appid
WECHAT_APP_SECRET=your_actual_secret

# DeepSeek AI配置
DEEPSEEK_API_KEY=your_actual_api_key

# JWT配置
JWT_SECRET=$(openssl rand -hex 32)

# 数据库配置
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)
MYSQL_PASSWORD=$(openssl rand -base64 32)

# Redis配置
REDIS_PASSWORD=$(openssl rand -base64 32)

# 微信支付配置（如需要）
WECHAT_PAY_APP_ID=your_pay_appid
WECHAT_PAY_MCH_ID=your_merchant_id
WECHAT_PAY_API_KEY=your_pay_key
```

### 2. Shell环境变量配置

**在 `.bashrc` 或 `.zshrc` 中添加**：
```bash
# AI八卦运势小程序环境变量
export WECHAT_APP_ID="your_appid"
export WECHAT_APP_SECRET="your_secret"
export DEEPSEEK_API_KEY="your_api_key"
export JWT_SECRET="your_jwt_secret"
```

### 3. Docker环境变量

**在 `docker-compose.yml` 中使用**：
```yaml
services:
  backend:
    environment:
      - WECHAT_APP_ID=${WECHAT_APP_ID}
      - WECHAT_APP_SECRET=${WECHAT_APP_SECRET}
      - DEEPSEEK_API_KEY=${DEEPSEEK_API_KEY}
      - JWT_SECRET=${JWT_SECRET}
```

## 🔄 密钥轮换策略

### 1. 定期轮换周期

| 密钥类型 | 轮换周期 | 紧急轮换条件 |
|---------|---------|-------------|
| JWT Secret | 每3个月 | 疑似泄漏时立即 |
| API Keys | 每6个月 | 发现异常使用时 |
| 微信AppSecret | 每年 | 泄漏或安全事件时 |
| 数据库密码 | 每6个月 | 疑似泄漏时立即 |

### 2. 轮换脚本

```bash
#!/bin/bash
# 密钥轮换脚本

# 生成新的JWT密钥
NEW_JWT_SECRET=$(openssl rand -hex 32)
echo "新JWT密钥: $NEW_JWT_SECRET"

# 生成新的数据库密码
NEW_DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-16)
echo "新数据库密码: $NEW_DB_PASSWORD"

# 更新配置文件
sed -i.bak "s/JWT_SECRET=.*/JWT_SECRET=$NEW_JWT_SECRET/" .env.local
sed -i.bak "s/MYSQL_PASSWORD=.*/MYSQL_PASSWORD=$NEW_DB_PASSWORD/" .env.local
```

## 📋 安全检查清单

### 日常检查
- [ ] 运行安全扫描脚本
- [ ] 检查Git提交中的敏感信息
- [ ] 验证环境变量配置
- [ ] 检查日志文件中的敏感信息

### 部署前检查
- [ ] 所有敏感配置使用环境变量
- [ ] `.env` 文件在 `.gitignore` 中
- [ ] 生产环境使用强密码
- [ ] API密钥有效且权限最小

### 定期审计
- [ ] 审查所有配置文件
- [ ] 检查第三方依赖安全漏洞
- [ ] 审计用户权限和访问控制
- [ ] 备份和恢复流程验证

## 🚨 应急响应流程

### 发现密钥泄漏时

1. **立即响应**（5分钟内）
   ```bash
   # 立即禁用泄漏的密钥
   # 微信平台 - 重新生成AppSecret
   # DeepSeek平台 - 禁用泄漏的API Key
   ```

2. **评估影响**（30分钟内）
   - 检查访问日志
   - 确定泄漏范围
   - 评估数据泄露风险

3. **修复措施**（2小时内）
   ```bash
   # 运行安全扫描
   ./scripts/security/comprehensive-security-scan.sh
   
   # 清理Git历史
   git filter-branch --force --index-filter \
     'git rm --cached --ignore-unmatch path/to/sensitive/file' \
     --prune-empty --tag-name-filter cat -- --all
   
   # 强制推送到远程仓库
   git push origin --force --all
   ```

4. **恢复服务**（4小时内）
   - 更新所有配置
   - 重新部署服务
   - 验证系统功能

## 🔧 安全工具配置

### 1. Git预提交钩子

创建 `.git/hooks/pre-commit`：
```bash
#!/bin/bash
# 检查敏感信息
./scripts/security/comprehensive-security-scan.sh
if [ $? -ne 0 ]; then
    echo "发现敏感信息，提交已阻止"
    exit 1
fi
```

### 2. CI/CD安全检查

在CI流水线中添加：
```yaml
security_scan:
  stage: security
  script:
    - ./scripts/security/comprehensive-security-scan.sh
  only:
    - merge_requests
    - master
```

### 3. 定期安全扫描

设置cron任务：
```bash
# 每天2点执行安全扫描
0 2 * * * /path/to/project/scripts/security/comprehensive-security-scan.sh
```

## 📚 安全培训资源

### 开发团队培训要点

1. **敏感信息识别**
   - 什么是敏感信息
   - 常见泄漏场景
   - 识别方法和工具

2. **安全编码实践**
   - 环境变量使用
   - 配置文件管理
   - 代码审查要点

3. **事件响应流程**
   - 发现泄漏的处理步骤
   - 上报机制
   - 恢复流程

### 推荐工具

- **truffleHog**: Git历史敏感信息扫描
- **git-secrets**: AWS敏感信息检测
- **detect-secrets**: 通用敏感信息检测
- **gitleaks**: Git敏感信息泄漏检测

## 📞 联系方式

如发现安全问题或需要支持：
- 安全团队邮箱: security@company.com
- 紧急响应热线: +86-xxx-xxxx-xxxx
- 内部安全平台: https://security.internal.com

---

**记住：安全是每个人的责任！** 