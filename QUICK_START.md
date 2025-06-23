# 🚀 Ubuntu快速部署 - 一键启动

## 八卦运势AI小程序生产环境部署

### 📱 一键部署命令

```bash
# 进入项目目录
cd bagua-ai

# 运行一键部署脚本
./deploy.sh
```

### 🎯 部署选项

运行 `./deploy.sh` 后会看到以下菜单：

```
==================================================
    八卦运势AI小程序 - 一键部署
    Ubuntu生产环境 | Docker环境优先
==================================================

请选择操作:
1) 完整部署 (首次部署推荐，包含环境安装和项目构建)
2) 快速启动 (适用于已构建项目)
3) 检查状态 (查看当前部署状态)
4) 停止服务 (停止所有运行的服务)
5) 查看部署指南
6) 退出
```

### 🔧 直接使用脚本

如果你知道要执行什么操作，可以直接运行对应脚本：

```bash
# 完整部署（首次部署）
./ubuntu-quick-deploy.sh

# 快速启动（已构建项目）
./ubuntu-quick-start.sh

# 检查部署状态
./check-status.sh

# 停止所有服务
./stop-all-services.sh
```

### 🌐 访问地址

部署成功后：

- **前端应用**: http://localhost
- **后端API**: http://localhost:8080
- **健康检查**: http://localhost/health

### 🧪 测试命令

```bash
# 前端健康检查
curl http://localhost/health

# 后端健康检查
curl http://localhost:8080/api/actuator/health

# 测试运势API
curl -X POST http://localhost:8080/api/fortune/calculate \
  -H 'Content-Type: application/json' \
  -d '{"name":"测试","birthDate":"1990-01-01","birthTime":"子时","gender":"male"}'
```

### 📋 系统要求

- Ubuntu 18.04+
- 2GB+ 内存
- sudo权限
- 网络连接

### 🆘 需要帮助？

查看详细部署指南：
```bash
./deploy.sh
# 选择 "5) 查看部署指南"
```

或直接查看：
```bash
cat UBUNTU_DEPLOYMENT_GUIDE.md
```

---

**就这么简单！🎉** 