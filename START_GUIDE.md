# 🚀 AI八卦运势小程序启动指南

## 📋 启动脚本说明

为了解决端口占用问题和简化启动流程，我们提供了三个启动脚本：

### 1. 🔧 后端服务启动脚本
```bash
./start-backend.sh
```

**功能特性**：
- ✅ 自动检测并清理8080端口占用
- ✅ 自动设置DEEPSEEK_API_KEY环境变量
- ✅ 自动编译和启动Spring Boot应用
- ✅ 彩色输出，清晰显示启动状态

### 2. 📱 前端服务启动脚本
```bash
./start-frontend.sh
```

**功能特性**：
- ✅ 专门启动微信小程序版本 (mp-weixin)
- ✅ 自动检查Node.js和npm环境
- ✅ 自动安装依赖（如果需要）
- ✅ 清理之前的构建文件
- ✅ 构建输出到 `frontend/dist/dev/mp-weixin`

### 3. 🌟 完整服务启动脚本
```bash
./start-all.sh
```

**功能特性**：
- ✅ 同时启动后端和前端服务
- ✅ 后端在后台运行，前端在前台运行
- ✅ 智能进程管理和清理
- ✅ 按Ctrl+C可同时停止所有服务

## 🎯 推荐使用方式

### 开发调试模式
```bash
# 分别启动，便于调试
./start-backend.sh    # 终端1
./start-frontend.sh   # 终端2
```

### 快速启动模式
```bash
# 一键启动所有服务
./start-all.sh
```

## 📍 服务地址

启动成功后，可以通过以下地址访问：

- **后端API**: http://localhost:8080
- **API文档**: http://localhost:8080/swagger-ui.html
- **健康检查**: http://localhost:8080/actuator/health
- **微信小程序**: 在微信开发者工具中导入 `frontend/dist/dev/mp-weixin`

## 🔧 环境要求

### 后端要求
- ✅ Java 17+
- ✅ Maven 3.6+
- ✅ MySQL 8.0+

### 前端要求
- ✅ Node.js 16+
- ✅ npm 8+
- ✅ 微信开发者工具

## 🚨 常见问题解决

### 1. 端口占用问题
脚本会自动处理，如果仍有问题：
```bash
# 手动清理端口
lsof -ti:8080 | xargs kill -9
```

### 2. API密钥问题
脚本会自动设置，也可以手动设置：
```bash
export DEEPSEEK_API_KEY="your-api-key"
```

### 3. 依赖问题
```bash
# 重新安装后端依赖
cd backend && mvn clean install

# 重新安装前端依赖
cd frontend && npm install
```

### 4. 微信开发者工具导入
1. 打开微信开发者工具
2. 选择"导入项目"
3. 选择 `frontend/dist/dev/mp-weixin` 目录
4. 设置AppID（测试号或正式号）

## 📊 启动状态检查

### 后端服务检查
```bash
# 检查服务状态
curl http://localhost:8080/actuator/health

# 检查API接口
curl http://localhost:8080/api/user/profile?userId=123
```

### 前端构建检查
```bash
# 检查构建文件
ls -la frontend/dist/dev/mp-weixin/

# 检查页面文件
ls -la frontend/dist/dev/mp-weixin/pages/
```

## 🎨 脚本特性

- 🌈 **彩色输出**: 不同状态用不同颜色显示
- 🔍 **智能检测**: 自动检测环境和依赖
- 🛡️ **错误处理**: 完善的错误处理和提示
- 🧹 **自动清理**: 自动清理端口和进程
- 📝 **详细日志**: 清晰的启动步骤和状态

## 💡 开发建议

1. **首次启动**: 使用 `./start-all.sh` 确保环境正常
2. **日常开发**: 使用分别启动方式便于调试
3. **生产部署**: 参考脚本逻辑编写部署脚本
4. **问题排查**: 查看脚本输出的详细日志

---

**🎯 目标**: 一键启动，专注开发，提升效率！ 