# 微信小程序部署指南 - AI八卦运势小程序

## 📱 项目概述

**项目名称**: AI八卦运势小程序  
**技术栈**: uni-app + Vue 3 + TypeScript  
**目标平台**: 微信小程序  
**AppID**: `wx7fafb8277143634d`  

## 🔧 构建命令对比

### ❌ 错误的命令（之前使用的）
```bash
npm run build:h5        # 这是H5网页版本
npm run build           # 默认是H5版本
```

### ✅ 正确的命令（微信小程序）
```bash
npm run build:mp-weixin  # 微信小程序版本
```

### 📋 所有可用的构建命令
```bash
# 微信小程序相关
npm run dev:mp-weixin     # 开发环境
npm run build:mp-weixin   # 生产环境构建

# 其他平台（参考）
npm run build:h5          # H5网页版
npm run build:mp-alipay   # 支付宝小程序
npm run build:mp-baidu    # 百度小程序
npm run build:mp-qq       # QQ小程序
```

## 🚀 快速部署步骤

### 方法1：使用自动化脚本（推荐）

```bash
# 设置执行权限
chmod +x scripts/deploy-wechat-miniprogram.sh

# 执行微信小程序构建
./scripts/deploy-wechat-miniprogram.sh

# 同时构建H5版本（可选）
./scripts/deploy-wechat-miniprogram.sh --with-h5
```

### 方法2：手动构建步骤

```bash
# 1. 进入前端目录
cd frontend

# 2. 安装依赖（首次或更新后）
npm install

# 3. 构建微信小程序版本
npm run build:mp-weixin

# 4. 检查构建结果
ls -la dist/build/mp-weixin/

# 5. 返回项目根目录
cd ..
```

## 📁 构建产物结构

构建成功后的目录结构：
```
frontend/dist/build/mp-weixin/
├── app.js                  # 应用入口JS
├── app.json                # 应用配置
├── app.wxss                # 全局样式
├── project.config.json     # 项目配置
├── sitemap.json           # 站点地图
├── pages/                 # 页面文件
│   ├── index/             # 首页
│   │   ├── index.wxml     # 页面结构
│   │   ├── index.wxss     # 页面样式
│   │   ├── index.js       # 页面逻辑
│   │   └── index.json     # 页面配置
│   ├── calculate/         # 八字测算页
│   ├── result/            # 结果页
│   ├── vip/               # VIP页
│   ├── history/           # 历史记录页
│   ├── profile/           # 个人中心页
│   └── ...
├── components/            # 组件文件（如有）
└── static/               # 静态资源
```

## 🛠️ 微信开发者工具导入

### 第1步：准备工作
1. 下载并安装微信开发者工具
2. 使用微信账号登录
3. 确保有小程序开发权限

### 第2步：导入项目
1. 打开微信开发者工具
2. 选择"小程序"
3. 点击"导入项目"
4. 填写项目信息：
   - **项目目录**: `你的项目路径/frontend/dist/build/mp-weixin`
   - **AppID**: `wx7fafb8277143634d`
   - **项目名称**: `AI八卦运势小程序`

### 第3步：验证项目
1. 检查项目是否正常加载
2. 在模拟器中预览页面
3. 测试页面跳转功能
4. 检查控制台是否有错误

## 🔗 API接口配置

### 服务器域名配置
在微信公众平台配置服务器域名：

1. 登录 [微信公众平台](https://mp.weixin.qq.com)
2. 进入"开发" → "开发管理" → "开发设置"
3. 配置服务器域名：
   ```
   request合法域名: https://your-domain.com
   socket合法域名: wss://your-domain.com
   uploadFile合法域名: https://your-domain.com
   downloadFile合法域名: https://your-domain.com
   ```

### API基础地址配置
检查前端代码中的API配置：

```javascript
// 在前端代码中确保API地址正确
const apiBaseUrl = 'https://your-domain.com/api'

// 或者根据环境动态配置
const apiBaseUrl = process.env.NODE_ENV === 'production' 
  ? 'https://your-production-domain.com/api'
  : 'https://your-dev-domain.com/api'
```

## 📱 发布流程

### 第1步：本地测试
1. 在微信开发者工具中完整测试功能
2. 检查所有页面和组件
3. 验证API接口调用
4. 测试用户交互流程

### 第2步：上传代码
1. 在微信开发者工具中点击"上传"
2. 填写版本号（如：1.0.0）
3. 填写项目备注
4. 点击"上传"按钮

### 第3步：提交审核
1. 登录微信公众平台
2. 进入"版本管理"
3. 找到刚上传的版本
4. 点击"提交审核"
5. 填写审核信息：
   - 功能页面：首页、八字测算、VIP等
   - 功能描述：AI八卦运势分析
   - 测试账号：提供测试用的微信号

### 第4步：审核发布
1. 等待微信审核（通常1-7个工作日）
2. 审核通过后，点击"发布"
3. 小程序正式上线

## 🔧 常见问题解决

### 问题1：构建失败
```bash
# 清理缓存重新安装
cd frontend
rm -rf node_modules package-lock.json
npm cache clean --force
npm install

# 重新构建
npm run build:mp-weixin
```

### 问题2：页面显示异常
检查以下文件：
- `app.json` - 页面路径配置
- `pages.json` - uni-app页面配置
- 各页面的 `.vue` 文件

### 问题3：API调用失败
1. 检查服务器域名是否在微信公众平台配置
2. 确认API地址是否正确
3. 检查网络请求权限

### 问题4：组件加载错误
1. 检查组件引用路径
2. 确认组件是否正确导出
3. 验证组件兼容性

## 📊 版本对比

| 版本类型 | 构建命令 | 部署方式 | 访问方式 |
|---------|---------|---------|---------|
| **微信小程序** | `npm run build:mp-weixin` | 微信开发者工具上传 | 微信小程序 |
| **H5网页版** | `npm run build:h5` | Nginx服务器部署 | 浏览器访问 |
| **支付宝小程序** | `npm run build:mp-alipay` | 支付宝开发者工具 | 支付宝小程序 |

## 🎯 最佳实践

### 1. 版本管理
- 使用语义化版本号（如：1.0.0, 1.1.0）
- 每次发布前更新版本信息
- 保留构建产物备份

### 2. 测试流程
- 本地开发测试：`npm run dev:mp-weixin`
- 构建前测试：确保所有功能正常
- 上传前测试：在开发者工具中完整测试
- 审核前测试：提供完整的测试用例

### 3. 配置管理
- 区分开发和生产环境配置
- 敏感信息使用环境变量
- API地址统一管理

### 4. 文档维护
- 记录每次发布的功能变更
- 维护API接口文档
- 更新用户使用指南

## 📞 技术支持

### 开发工具
- **微信开发者工具**: [下载地址](https://developers.weixin.qq.com/miniprogram/dev/devtools/download.html)
- **uni-app文档**: [官方文档](https://uniapp.dcloud.net.cn/)
- **微信小程序文档**: [官方文档](https://developers.weixin.qq.com/miniprogram/dev/framework/)

### 常用命令速查
```bash
# 快速构建
./scripts/deploy-wechat-miniprogram.sh

# 检查构建结果
ls -la frontend/dist/build/mp-weixin/

# 查看项目配置
cat frontend/dist/build/mp-weixin/project.config.json

# 清理重新构建
cd frontend && npm run build:mp-weixin && cd ..
```

---

## 🎉 完成！

按照以上步骤，你的AI八卦运势微信小程序就可以成功构建和发布了！

如果遇到问题，请参考常见问题部分或查看生成的部署报告文件。 