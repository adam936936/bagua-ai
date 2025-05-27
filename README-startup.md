# AI八卦运势小程序 - 快速启动指南

## 🚀 快速启动

### 1. 检查端口占用
```bash
./scripts/check-ports.sh
```

### 2. 启动后端
```bash
./scripts/start-backend.sh
```

### 3. 启动前端
```bash
./scripts/start-frontend.sh
```

### 4. 快速重启后端
```bash
./scripts/restart-backend.sh
```

### 5. 停止所有服务
```bash
./scripts/stop-all.sh
```

## ⚠️ 常见问题

### 端口8080被占用
```bash
# 查看占用进程
lsof -i:8080

# 强制杀死进程
lsof -ti:8080 | xargs kill -9

# 或使用脚本自动处理
./scripts/check-ports.sh
```

### Maven命令错误
```bash
# 错误：在根目录执行
mvn spring-boot:run

# 正确：在backend目录执行
cd backend && mvn spring-boot:run

# 或使用脚本
./scripts/start-backend.sh
```

### 前端依赖问题
```bash
cd frontend
rm -rf node_modules package-lock.json
npm install
```

## 📝 环境要求

- **后端**: Java 17+, Maven 3.6+, MySQL 8.0+
- **前端**: Node.js 16+, npm, 微信开发者工具

## 🔧 服务地址

- **后端API**: http://localhost:8080
- **前端开发**: 微信开发者工具导入 `frontend/dist/dev/mp-weixin`

## 📋 启动检查清单

- [ ] 端口8080未被占用
- [ ] Java环境正常
- [ ] Maven环境正常  
- [ ] MySQL数据库运行
- [ ] Node.js环境正常
- [ ] 前端依赖已安装

## 📅 开发规划

### 每日规划文档
- [每日开发规划](docs/daily-plan.md) - 记录每天的任务目标、进度和完成情况
- [每日规划模板](docs/daily-plan-template.md) - 用于创建新的每日规划

### 使用方法
1. 每天开始开发前，复制模板创建新的每日规划
2. 设定当天的任务目标和优先级
3. 开发过程中记录进度和遇到的问题
4. 结束时总结完成情况和心得体会

## 🆘 获取帮助

如遇问题，请查看详细文档：
- [完整启动指南](docs/startup-guide.md)
- [错误总结报告](docs/error-summary.md)
- [每日开发规划](docs/daily-plan.md) 