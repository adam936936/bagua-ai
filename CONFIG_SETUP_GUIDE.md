# 🔐 安全配置指南

## ⚠️ 重要提醒
为了保护您的微信小程序敏感信息，我们已经移除了所有硬编码的AppID。请按照以下步骤安全地配置您的项目。

## 📝 需要配置的文件

### 1. 前端配置文件

#### `frontend/project.config.json`
```json
{
  "appid": "YOUR_WECHAT_APPID_HERE"
}
```

#### `frontend/src/manifest.json`
```json
{
  "appid": "YOUR_WECHAT_APPID_HERE",
  "mp-weixin": {
    "appid": "YOUR_WECHAT_APPID_HERE"
  }
}
```

### 2. 后端配置文件（如果使用）

创建 `backend/src/main/resources/application-local.properties`:
```properties
# 微信小程序配置
wechat.appid=YOUR_WECHAT_APPID_HERE
wechat.secret=YOUR_WECHAT_APP_SECRET_HERE

# 微信支付配置（如需要）
wechat.pay.appid=YOUR_WECHAT_PAY_APPID_HERE
wechat.pay.mchid=YOUR_MERCHANT_ID_HERE
```

## 🔒 安全最佳实践

### 1. 使用环境变量
```bash
# 在您的shell环境中设置
export WECHAT_APPID="your_actual_appid"
export WECHAT_APP_SECRET="your_actual_secret"
```

### 2. 使用本地配置文件
创建 `.env.local` 文件（不会被git追踪）：
```bash
WECHAT_APPID=your_actual_appid
WECHAT_APP_SECRET=your_actual_secret
```

### 3. 配置.gitignore
确保以下文件不会被提交到版本控制：
```
.env.local
.env.production
**/application-local.properties
**/config/local.*
```

## 🚀 配置步骤

### 第1步：获取微信AppID
1. 登录 [微信公众平台](https://mp.weixin.qq.com)
2. 进入"开发" → "开发管理" → "开发设置"
3. 复制AppID和AppSecret

### 第2步：替换占位符
将所有 `YOUR_WECHAT_APPID_HERE` 替换为您的实际AppID

### 第3步：验证配置
运行以下命令检查配置是否正确：
```bash
# 检查前端配置
cd frontend
npm run build:mp-weixin

# 检查后端配置（如果使用）
cd backend
./gradlew build
```

## 🛡️ Git历史清理

如果您需要从Git历史中完全移除敏感信息，请运行：

```bash
# 使用git filter-branch清理历史
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch frontend/project.config.json' \
  --prune-empty --tag-name-filter cat -- --all

# 或者使用更现代的工具
git filter-repo --path frontend/project.config.json --invert-paths
```

⚠️ **注意**: 清理Git历史会改变提交哈希，如果项目已经被其他人clone，需要协调处理。

## 🔄 重新生成AppID（推荐）

如果可能，建议您：
1. 在微信公众平台创建新的测试小程序
2. 获取新的AppID和Secret
3. 更新所有配置文件
4. 废弃泄漏的旧AppID

## 📞 联系支持

如果您在配置过程中遇到问题，请检查：
- 微信公众平台开发者权限
- 网络连接和防火墙设置
- 配置文件语法正确性 