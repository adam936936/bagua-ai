# 🚀 AI八卦运势小程序 - 腾讯云Docker环境部署指南

> 专为腾讯云Docker环境设计的一键部署解决方案

## 📋 目录

- [适用场景](#适用场景)
- [环境要求](#环境要求)
- [快速部署](#快速部署)
- [详细配置](#详细配置)
- [服务管理](#服务管理)
- [常见问题](#常见问题)
- [性能优化](#性能优化)

## 🎯 适用场景

本指南适用于以下腾讯云Docker环境：

- **腾讯云轻量应用服务器**（预装Docker镜像）
- **腾讯云容器实例** 
- **腾讯云CVM**（已安装Docker环境）
- **腾讯云容器服务TKE**的节点

## 📋 环境要求

### 系统要求
- **操作系统**: Ubuntu 18.04+ / CentOS 7+ / Debian 9+
- **内存**: 2GB+ （推荐4GB+）
- **存储**: 10GB+ 可用空间
- **CPU**: 1核+ （推荐2核+）
- **Docker**: 20.10+ （预装）
- **Docker Compose**: 2.0+ （脚本会自动安装）

### 网络要求
- 80端口（HTTP）
- 443端口（HTTPS，可选）
- 8080端口（后端API）
- 3306端口（MySQL，内部）
- 6379端口（Redis，内部）

## 🚀 快速部署

### 步骤一：获取代码
```bash
# 克隆项目到服务器
git clone https://github.com/your-username/bagua-ai.git
cd bagua-ai
```

### 步骤二：一键部署
```bash
# 给脚本执行权限
chmod +x scripts/deploy-tencent-docker-2025.sh

# 执行部署（需要sudo权限）
sudo ./scripts/deploy-tencent-docker-2025.sh
```

### 步骤三：配置应用
```bash
# 编辑配置文件
sudo nano /app/bagua-ai/.env.production

# 必须配置的项目：
# WECHAT_APP_ID=你的微信AppID
# WECHAT_APP_SECRET=你的微信AppSecret  
# DEEPSEEK_API_KEY=你的DeepSeek API Key
```

### 步骤四：重启服务
```bash
cd /app/bagua-ai
./restart.sh
```

## ⚙️ 详细配置

### 环境变量配置

部署脚本会自动生成 `/app/bagua-ai/.env.production` 文件，包含以下配置：

```bash
# ===================== 应用配置 =====================
NODE_ENV=production
APP_PORT=8080
FRONTEND_PORT=3000

# ===================== 数据库配置 =====================
MYSQL_HOST=mysql
MYSQL_PORT=3306
MYSQL_DATABASE=bagua_fortune
MYSQL_USERNAME=bagua_user
MYSQL_PASSWORD=自动生成的安全密码
MYSQL_ROOT_PASSWORD=自动生成的安全密码

# ===================== Redis配置 =====================
REDIS_HOST=redis  
REDIS_PORT=6379
REDIS_PASSWORD=自动生成的安全密码

# ===================== 安全配置 =====================
JWT_SECRET=自动生成的64位密钥
ENCRYPTION_KEY=自动生成的32位密钥

# ===================== 微信小程序配置（需要手动设置）=====================
WECHAT_APP_ID=请配置您的微信AppID
WECHAT_APP_SECRET=请配置您的微信AppSecret

# ===================== AI配置（需要手动设置）=====================
DEEPSEEK_API_KEY=请配置您的DeepSeek API Key
DEEPSEEK_API_URL=https://api.deepseek.com/v1/chat/completions
DEEPSEEK_MODEL=deepseek-chat

# ===================== 腾讯云Docker环境配置 =====================
DOCKER_REGISTRY_MIRROR=mirror.ccs.tencentcloudcr.com
```

### Docker Compose架构

部署包含以下服务：

```yaml
services:
  mysql:       # MySQL 8.0 数据库
  redis:       # Redis 7 缓存
  backend:     # Java后端服务
  frontend:    # Vue.js前端服务  
  nginx:       # Nginx反向代理
```

### 网络架构

```
用户请求 → Nginx (80/443) → 前端/后端 → MySQL/Redis
```

## 🛠️ 服务管理

部署完成后，所有管理脚本位于 `/app/bagua-ai/` 目录：

### 基本操作
```bash
cd /app/bagua-ai

# 启动所有服务
./start.sh

# 停止所有服务
./stop.sh

# 重启所有服务
./restart.sh

# 查看服务状态
./status.sh
```

### 日志管理
```bash
# 查看所有服务日志
./logs.sh

# 查看特定服务日志
./logs.sh mysql     # 数据库日志
./logs.sh redis     # Redis日志
./logs.sh backend   # 后端日志
./logs.sh frontend  # 前端日志
./logs.sh nginx     # Nginx日志
```

### 应用更新
```bash
# 更新应用代码
./update.sh
```

### 数据备份
```bash
# 创建完整备份
./backup.sh
```

## 🔍 服务监控

### 健康检查
- **应用健康**: http://your-ip/health
- **后端健康**: http://your-ip:8080/health

### 容器状态
```bash
# 查看容器状态
docker-compose ps

# 查看资源使用
docker stats
```

### 系统日志
- **应用日志**: `/var/log/bagua-ai/deploy.log`
- **Nginx日志**: `/app/bagua-ai/logs/nginx/`
- **应用日志**: `/app/bagua-ai/logs/`

## 🔧 常见问题

### 1. Docker服务启动失败

**症状**: Docker命令无法执行
```bash
# 检查Docker状态
sudo systemctl status docker

# 启动Docker服务
sudo systemctl start docker

# 设置开机自启
sudo systemctl enable docker
```

### 2. 端口被占用

**症状**: 端口占用错误
```bash
# 检查端口占用
netstat -tulpn | grep :80
netstat -tulpn | grep :8080

# 停止占用端口的进程
sudo kill -9 <PID>
```

### 3. 内存不足

**症状**: 容器启动失败，内存相关错误
```bash
# 检查内存使用
free -h

# 清理不必要的容器和镜像
docker system prune -a
```

### 4. 镜像拉取失败

**症状**: 网络超时，镜像下载失败
```bash
# 检查镜像加速器配置
cat /etc/docker/daemon.json

# 手动拉取镜像
docker pull mysql:8.0
docker pull redis:7-alpine
docker pull nginx:alpine
```

### 5. 数据库连接失败

**症状**: 后端无法连接数据库
```bash
# 检查MySQL容器状态
docker logs bagua-mysql

# 检查网络连接
docker exec bagua-backend ping mysql

# 重置数据库密码
docker exec -it bagua-mysql mysql -u root -p
```

### 6. 文件权限问题

**症状**: 权限拒绝错误
```bash
# 修复目录权限
sudo chown -R $(whoami):$(whoami) /app/bagua-ai
sudo chmod -R 755 /app/bagua-ai
```

## 📊 性能优化

### 1. Docker优化

腾讯云镜像加速配置已自动设置：
```json
{
    "registry-mirrors": [
        "https://mirror.ccs.tencentcloudcr.com",
        "https://ccr.ccs.tencentcloudcr.com"
    ]
}
```

### 2. MySQL优化

针对容器环境的MySQL配置：
```sql
# 适当调整缓冲池大小
SET GLOBAL innodb_buffer_pool_size = 512MB;

# 优化连接数
SET GLOBAL max_connections = 200;
```

### 3. Redis优化

Redis内存使用优化：
```bash
# 设置最大内存使用
docker exec bagua-redis redis-cli CONFIG SET maxmemory 256mb
docker exec bagua-redis redis-cli CONFIG SET maxmemory-policy allkeys-lru
```

### 4. Nginx优化

优化Nginx性能：
- 启用Gzip压缩（已配置）
- 设置适当的缓存头
- 调整worker进程数

### 5. 系统监控

设置基本监控：
```bash
# 创建监控脚本
cat > /app/bagua-ai/monitor.sh << 'EOF'
#!/bin/bash
echo "=== 系统状态 $(date) ==="
echo "CPU使用率: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')"
echo "内存使用: $(free | grep Mem | awk '{printf("%.2f%%"), $3/$2 * 100.0}')"
echo "磁盘使用: $(df -h / | awk 'NR==2 {print $5}')"
echo "容器状态:"
docker-compose ps --format "table {{.Name}}\t{{.State}}\t{{.Status}}"
EOF

chmod +x /app/bagua-ai/monitor.sh

# 设置定时监控（可选）
echo "*/5 * * * * /app/bagua-ai/monitor.sh >> /var/log/bagua-ai/monitor.log" | crontab -
```

## 🚦 部署验证

### 完整验证流程

1. **服务状态检查**
```bash
cd /app/bagua-ai
./status.sh
```

2. **网络连通性测试**
```bash
# 测试前端
curl -I http://localhost

# 测试后端API
curl -I http://localhost:8080/health

# 测试数据库连接
docker exec bagua-backend nc -z mysql 3306

# 测试Redis连接  
docker exec bagua-backend nc -z redis 6379
```

3. **应用功能测试**
- 访问前端页面: http://your-ip
- 测试API接口: http://your-ip:8080/health
- 检查日志输出是否正常

## 📞 技术支持

如果遇到问题，请按以下步骤排查：

1. **查看部署日志**: `tail -f /var/log/bagua-ai/deploy.log`
2. **检查服务状态**: `cd /app/bagua-ai && ./status.sh`
3. **查看容器日志**: `cd /app/bagua-ai && ./logs.sh`
4. **验证配置文件**: `cat /app/bagua-ai/.env.production`

---

## 📝 更新日志

### v2025.1
- 优化腾讯云Docker环境适配
- 移除Docker安装步骤，专注于预装环境
- 增强镜像加速配置
- 优化资源分配和性能调优

---

**🎉 现在您的AI八卦运势小程序已成功部署在腾讯云Docker环境中！** 