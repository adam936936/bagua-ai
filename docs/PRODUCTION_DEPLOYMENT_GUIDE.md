# 🚀 AI八卦运势小程序 - 生产环境部署指南

## 📋 目录
- [环境要求](#环境要求)
- [部署准备](#部署准备) 
- [一键部署](#一键部署)
- [手动部署](#手动部署)
- [配置说明](#配置说明)
- [运维管理](#运维管理)
- [故障排除](#故障排除)

## 🎯 环境要求

### 服务器配置
- **操作系统**: Ubuntu 20.04+ LTS
- **内存**: 最低4GB，推荐8GB+
- **存储**: 最低20GB可用空间，推荐50GB+
- **CPU**: 最低2核心，推荐4核心+
- **网络**: 具备公网IP，开放80/443端口

### 腾讯云推荐配置
- **实例规格**: 2核4GB (SA2.MEDIUM4)
- **镜像**: Ubuntu Server 20.04 LTS 64位
- **存储**: 50GB SSD云硬盘
- **网络**: 5Mbps带宽

## 🔧 部署准备

### 1. 购买腾讯云服务器
1. 登录腾讯云控制台
2. 购买云服务器CVM实例
3. 配置安全组规则：
   - HTTP(80)：0.0.0.0/0
   - HTTPS(443)：0.0.0.0/0
   - SSH(22)：您的IP地址

### 2. 连接服务器
```bash
# 使用SSH连接服务器
ssh ubuntu@您的服务器IP

# 更新系统
sudo apt update && sudo apt upgrade -y
```

### 3. 下载项目代码
```bash
# 方式一：从GitHub下载
git clone https://github.com/您的用户名/bagua-ai.git
cd bagua-ai

# 方式二：上传代码包
# 将项目代码压缩包上传到服务器并解压
```

## 🚀 一键部署

### 快速部署
```bash
# 进入项目目录
cd bagua-ai

# 赋予脚本执行权限
chmod +x scripts/deploy-production-2025.sh

# 执行一键部署
sudo ./scripts/deploy-production-2025.sh
```

### 部署流程说明
1. **环境检查** - 验证系统环境和资源
2. **Docker安装** - 自动安装Docker和Docker Compose
3. **项目设置** - 创建项目目录和备份
4. **环境配置** - 生成安全的环境变量
5. **容器配置** - 创建Docker Compose文件
6. **服务启动** - 启动所有服务容器
7. **健康检查** - 验证服务运行状态

## 🔨 手动部署

如果需要自定义配置，可以手动执行部署步骤：

### 1. 安装Docker
```bash
# 安装Docker
curl -fsSL https://get.docker.com | sh
sudo systemctl start docker
sudo systemctl enable docker

# 安装Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 将用户添加到docker组
sudo usermod -aG docker $USER
```

### 2. 配置项目
```bash
# 创建项目目录
sudo mkdir -p /opt/bagua-ai
sudo chown $USER:$USER /opt/bagua-ai

# 复制项目文件
cp -r . /opt/bagua-ai/
cd /opt/bagua-ai
```

### 3. 配置环境变量
```bash
# 复制环境变量模板
cp .env.production.template .env.production

# 编辑环境变量
nano .env.production
```

### 4. 启动服务
```bash
# 构建并启动服务
docker-compose -f docker-compose.production.yml --env-file .env.production up -d

# 查看服务状态
docker-compose -f docker-compose.production.yml ps
```

## ⚙️ 配置说明

### 环境变量配置
编辑 `/opt/bagua-ai/.env.production` 文件：

```env
# ===================== 微信小程序配置 =====================
WECHAT_APP_ID=您的微信小程序AppID
WECHAT_APP_SECRET=您的微信小程序AppSecret

# ===================== AI配置 =====================
DEEPSEEK_API_KEY=您的DeepSeek API Key
DEEPSEEK_API_URL=https://api.deepseek.com/v1/chat/completions
DEEPSEEK_MODEL=deepseek-chat

# ===================== 数据库配置（自动生成，无需修改）=====================
MYSQL_HOST=mysql
MYSQL_PORT=3306
MYSQL_DATABASE=bagua_fortune
MYSQL_USERNAME=bagua_user
MYSQL_PASSWORD=自动生成的密码
MYSQL_ROOT_PASSWORD=自动生成的密码

# ===================== Redis配置（自动生成，无需修改）=====================
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=自动生成的密码

# ===================== 安全配置（自动生成，无需修改）=====================
JWT_SECRET=自动生成的密钥
ENCRYPTION_KEY=自动生成的密钥
```

### 域名配置（可选）
如果您有域名，需要修改Nginx配置：

```bash
# 编辑Nginx配置
sudo nano /opt/bagua-ai/nginx/conf.d/bagua-ai.conf

# 修改server_name
server_name 您的域名.com;
```

### SSL证书配置（可选）
```bash
# 创建SSL目录
mkdir -p /opt/bagua-ai/ssl

# 将证书文件放入SSL目录
# cert.pem - 证书文件
# private.key - 私钥文件

# 修改Nginx配置支持HTTPS
# 参考nginx/conf.d/bagua-ai-ssl.conf.example
```

## 🛠️ 运维管理

### 服务管理脚本
```bash
cd /opt/bagua-ai

# 启动服务
./start.sh

# 停止服务
./stop.sh

# 重启服务
./restart.sh

# 查看日志
./logs.sh

# 查看特定服务日志
./logs.sh mysql
./logs.sh backend
./logs.sh frontend
./logs.sh nginx

# 检查服务状态
./status.sh
```

### 系统服务管理
```bash
# 启动应用服务
sudo systemctl start bagua-ai

# 停止应用服务
sudo systemctl stop bagua-ai

# 重启应用服务
sudo systemctl restart bagua-ai

# 查看服务状态
sudo systemctl status bagua-ai

# 开机自启动
sudo systemctl enable bagua-ai
```

### 数据备份
```bash
# 数据库备份
docker exec bagua-mysql mysqldump -u root -p${MYSQL_ROOT_PASSWORD} bagua_fortune > backup_$(date +%Y%m%d_%H%M%S).sql

# Redis备份
docker exec bagua-redis redis-cli --rdb /data/backup_$(date +%Y%m%d_%H%M%S).rdb

# 完整项目备份
tar -czf bagua-ai-backup-$(date +%Y%m%d_%H%M%S).tar.gz /opt/bagua-ai
```

### 性能监控
```bash
# 查看容器资源使用情况
docker stats

# 查看系统资源使用情况
htop

# 查看磁盘使用情况
df -h

# 查看网络连接情况
netstat -tulpn
```

## 🔍 故障排除

### 常见问题

#### 1. Docker服务启动失败
```bash
# 检查Docker状态
sudo systemctl status docker

# 重启Docker服务
sudo systemctl restart docker

# 查看Docker日志
sudo journalctl -u docker.service
```

#### 2. 容器启动失败
```bash
# 查看容器状态
docker-compose -f docker-compose.production.yml ps

# 查看容器日志
docker-compose -f docker-compose.production.yml logs [服务名]

# 重新构建容器
docker-compose -f docker-compose.production.yml build --no-cache
```

#### 3. 数据库连接失败
```bash
# 检查MySQL容器状态
docker exec -it bagua-mysql mysql -u root -p

# 查看数据库日志
docker logs bagua-mysql

# 重启数据库服务
docker-compose -f docker-compose.production.yml restart mysql
```

#### 4. 网络访问问题
```bash
# 检查端口监听
sudo netstat -tulpn | grep :80

# 检查防火墙设置
sudo ufw status

# 检查Nginx配置
docker exec bagua-nginx nginx -t
```

#### 5. 内存不足
```bash
# 查看内存使用情况
free -h

# 查看最占内存的进程
ps aux --sort=-%mem | head

# 清理Docker未使用的资源
docker system prune -a
```

### 日志查看
```bash
# 应用日志
docker-compose -f docker-compose.production.yml logs -f backend

# Nginx访问日志
docker exec bagua-nginx tail -f /var/log/nginx/access.log

# 系统日志
sudo journalctl -f -u bagua-ai
```

### 性能优化
```bash
# 调整Docker内存限制
# 在docker-compose.yml中添加：
deploy:
  resources:
    limits:
      memory: 1G
    reservations:
      memory: 512M

# 优化MySQL配置
# 在docker-compose.yml中添加：
command: --default-authentication-plugin=mysql_native_password --innodb-buffer-pool-size=512M
```

## 📞 技术支持

如果遇到部署问题，请：
1. 查看部署日志：`/var/log/bagua-ai/deploy.log`
2. 运行健康检查：`/opt/bagua-ai/status.sh`
3. 查看容器状态：`docker-compose ps`

## 🔗 相关链接
- [腾讯云官方文档](https://cloud.tencent.com/document)
- [Docker官方文档](https://docs.docker.com/)
- [项目GitHub地址](https://github.com/您的用户名/bagua-ai)

---

**祝您部署顺利！** 🎉 