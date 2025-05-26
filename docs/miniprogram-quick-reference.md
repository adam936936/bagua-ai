# 微信小程序开发快速参考

## 🚀 快速开始

### 1. 一键检查配置
```bash
./check-miniprogram-config.sh
```

### 2. 一键启动开发环境
```bash
./start-miniprogram-dev.sh
```

### 3. 手动步骤
```bash
# 1. 启动后端
./start.sh prod

# 2. 构建小程序
cd frontend
npm run dev:mp-weixin

# 3. 打开微信开发者工具
# 导入项目: frontend/dist/dev/mp-weixin
```

## 📋 必备信息

### 微信小程序账号
- **注册地址**: https://mp.weixin.qq.com/
- **开发者工具**: https://developers.weixin.qq.com/miniprogram/dev/devtools/
- **AppID获取**: 微信公众平台 → 开发 → 开发管理 → 开发设置

### 项目配置文件
- **小程序配置**: `frontend/src/manifest.json`
- **页面配置**: `frontend/src/pages.json`
- **API配置**: `frontend/src/utils/request.ts`

## 🔧 常用命令

### 前端开发
```bash
cd frontend

# 安装依赖
npm install

# 开发模式 - 微信小程序
npm run dev:mp-weixin

# 生产构建 - 微信小程序
npm run build:mp-weixin

# 开发模式 - H5
npm run dev:h5

# 生产构建 - H5
npm run build:h5
```

### 后端开发
```bash
# 开发环境启动
./start.sh dev

# 生产环境启动
./start.sh prod

# 停止服务
./stop.sh

# API测试
./test-api.sh prod
```

## 📱 微信开发者工具

### 基础设置
```
详情 → 本地设置:
✅ 不校验合法域名
✅ 启用ES6转ES5
✅ 启用样式补全
✅ 启用代码压缩
```

### 网络配置
```
详情 → 项目配置 → 域名信息:
✅ request合法域名: https://your-domain.com
✅ socket合法域名: wss://your-domain.com (如需要)
```

### 调试技巧
```javascript
// 控制台测试API
wx.request({
  url: 'https://your-domain.com/api/fortune/today-fortune',
  method: 'GET',
  success: (res) => console.log('成功:', res.data),
  fail: (err) => console.error('失败:', err)
})

// 查看本地存储
console.log(wx.getStorageSync('key'))

// 查看系统信息
wx.getSystemInfo({
  success: (res) => console.log('系统信息:', res)
})
```

## 🔍 常见问题

### 问题1: 网络请求失败
```
原因: 域名未配置或不是HTTPS
解决: 
1. 配置合法域名
2. 确保使用HTTPS
3. 开发时可关闭域名校验
```

### 问题2: 页面白屏
```
原因: 路由配置错误或组件加载失败
解决:
1. 检查 pages.json 配置
2. 检查页面文件路径
3. 查看控制台错误
```

### 问题3: 样式不生效
```
原因: 单位使用错误或选择器不支持
解决:
1. 使用 rpx 替代 px
2. 避免使用不支持的CSS选择器
3. 检查样式优先级
```

### 问题4: API调用失败
```
原因: 后端服务未启动或跨域问题
解决:
1. 确保后端服务运行: ./start.sh prod
2. 检查API地址配置
3. 查看网络请求日志
```

## 📊 性能优化

### 代码优化
```javascript
// 1. 使用分包加载
// pages.json
{
  "subPackages": [
    {
      "root": "pages/sub",
      "pages": ["page1", "page2"]
    }
  ]
}

// 2. 图片懒加载
<image lazy-load="true" src="{{imageUrl}}" />

// 3. 数据缓存
wx.setStorageSync('key', data)
const data = wx.getStorageSync('key')
```

### 体验优化
```javascript
// 1. 加载状态
wx.showLoading({ title: '加载中...' })
wx.hideLoading()

// 2. 错误提示
wx.showToast({
  title: '操作失败',
  icon: 'error'
})

// 3. 骨架屏
<skeleton wx:if="{{loading}}" />
<content wx:else />
```

## 🎯 审核要点

### 内容合规
```
❌ 避免: 算命、占卜、风水等敏感词
✅ 使用: 个性分析、趋势建议、娱乐参考
✅ 添加: 免责声明、娱乐性质说明
```

### 功能完整
```
✅ 所有页面正常访问
✅ 所有功能正常使用
✅ 异常情况友好提示
✅ 网络异常处理
```

### 用户体验
```
✅ 页面加载速度合理
✅ 交互逻辑清晰
✅ 视觉设计美观
✅ 文字表述准确
```

## 📞 技术支持

- **微信开发者社区**: https://developers.weixin.qq.com/community/
- **官方文档**: https://developers.weixin.qq.com/miniprogram/dev/framework/
- **审核规范**: https://developers.weixin.qq.com/miniprogram/product/
- **UniApp文档**: https://uniapp.dcloud.net.cn/

## 🔗 项目地址

- **项目目录**: `frontend/dist/dev/mp-weixin`
- **后端API**: `http://localhost:8081/api`
- **健康检查**: `http://localhost:8081/actuator/health`
- **测试页面**: `simple-frontend.html`

---

💡 **提示**: 开发过程中遇到问题，优先查看控制台错误信息和网络请求日志。 