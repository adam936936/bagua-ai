# 🚀 八卦AI微信小程序 - 部署指南

> 本文档提供完整的部署流程，包括本地开发环境和生产环境的配置说明。

---

## 📋 目录

1. [项目概述](#项目概述)
2. [技术要求](#技术要求)
3. [本地开发环境](#本地开发环境)
4. [生产环境部署](#生产环境部署)
5. [环境变量配置](#环境变量配置)
6. [常见问题](#常见问题)
7. [运维监控](#运维监控)

---

## 🎯 项目概述

八卦AI是基于微信小程序的命理测算应用，采用Spring Boot + MySQL + 微信小程序技术栈。

### 架构组件
- **前端**: 微信小程序原生开发
- **后端**: Spring Boot 2.7.14 + MyBatis-Plus
- **数据库**: MySQL 8.0+
- **缓存**: Redis (生产环境)
- **部署**: Docker + Docker Compose

---

## 💻 技术要求

### 开发环境
- **Java**: 17+
- **Maven**: 3.6+
- **MySQL**: 8.0+
- **Node.js**: 16.0+ (可选)
- **微信开发者工具**: 最新版

### 生产环境
- **服务器**: Ubuntu 20.04+ / CentOS 7+
- **Docker**: 20.10+
- **Docker Compose**: 2.0+
- **内存**: 4GB+ 推荐
- **磁盘**: 20GB+ 可用空间

---

## 🏠 本地开发环境

### 1. 克隆项目
```bash
git clone https://github.com/your-username/bagua-ai.git
cd bagua-ai
```

### 2. 配置MySQL数据库
```bash
# 安装MySQL (macOS)
brew install mysql
brew services start mysql

# 安装MySQL (Ubuntu)
sudo apt update
sudo apt install mysql-server
sudo systemctl start mysql

# 创建数据库
mysql -u root -p
CREATE DATABASE fortune_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 3. 环境变量配置
```bash
# 复制环境变量模板
cp .env.example .env

# 编辑环境变量
export MYSQL_PASSWORD=123456
export DEEPSEEK_API_KEY=your-deepseek-api-key
export WECHAT_APP_ID=your-wechat-app-id
export WECHAT_APP_SECRET=your-wechat-app-secret
```

### 4. 启动本地开发环境
```bash
# 使用提供的启动脚本（推荐）
chmod +x start-local-dev.sh
./start-local-dev.sh

# 手动启动
cd backend
mvn spring-boot:run -Dspring-boot.run.profiles=local-mysql
```

### 5. 验证本地环境
```bash
# 健康检查
curl http://localhost:8080/api/actuator/health

# 简单测试
curl http://localhost:8080/api/simple/hello
```

### 6. 前端开发配置
```bash
# 打开微信开发者工具
# 导入项目: 选择 frontend 目录
# 填入AppID: wxab173e904eb23fca (测试用)
# 设置API基础路径: http://localhost:8080/api
```

---

## 🌐 生产环境部署

### 1. 服务器准备
```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# 安装Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 2. 项目部署
```bash
# 上传项目文件
scp -r bagua-ai user@your-server-ip:/opt/

# 登录服务器
ssh user@your-server-ip
cd /opt/bagua-ai
```

### 3. 配置生产环境变量
```bash
# 创建生产环境配置
cat > .env.prod << EOF
MYSQL_ROOT_PASSWORD=FortuneProd2025!@#
MYSQL_PASSWORD=FortuneProd2025!@#
JWT_SECRET=FortuneJWTSecretKeyForProductionEnvironment2024!@#$%^&*
DEEPSEEK_API_KEY=sk-161f80e197f64439a4a9f0b4e9e30c40
WECHAT_APP_ID=wxab173e904eb23fca
WECHAT_APP_SECRET=75ad9ccb5f2ff072b8cd207d71a07ada
EOF
```

### 4. 启动生产服务
```bash
# 构建和启动所有服务
docker-compose -f docker-compose.prod.yml up -d

# 查看服务状态
docker-compose -f docker-compose.prod.yml ps

# 查看日志
docker-compose -f docker-compose.prod.yml logs -f
```

### 5. 配置SSL证书（可选）
```bash
# 使用Let's Encrypt免费证书
sudo apt install certbot
sudo certbot certonly --standalone -d your-domain.com

# 或者使用自签名证书（开发测试）
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/server.key \
  -out nginx/ssl/server.crt
```

---

## 🔧 环境变量配置

### 必需的环境变量

| 变量名 | 用途 | 示例值 |
|--------|------|--------|
| `MYSQL_PASSWORD` | 数据库密码 | `FortuneProd2025!@#` |
| `JWT_SECRET` | JWT签名密钥 | `FortuneJWTSecretKey...` |
| `DEEPSEEK_API_KEY` | AI服务密钥 | `sk-161f80e197f64439...` |
| `WECHAT_APP_ID` | 微信应用ID | `wxab173e904eb23fca` |
| `WECHAT_APP_SECRET` | 微信应用密钥 | `75ad9ccb5f2ff072...` |

### 可选的环境变量

| 变量名 | 用途 | 默认值 |
|--------|------|--------|
| `SERVER_PORT` | 后端服务端口 | `8080` |
| `MYSQL_PORT` | 数据库端口 | `3306` |
| `REDIS_PORT` | Redis端口 | `6379` |
| `LOG_LEVEL` | 日志级别 | `INFO` |

---

## 📊 配置文件说明

### application-local-mysql.yml
本地开发环境配置，使用本地MySQL数据库：

```yaml
spring:
  datasource:
    driver-class-name: com.mysql.cj.jdbc.Driver
    url: jdbc:mysql://localhost:3306/fortune_db
    username: root
    password: ${MYSQL_PASSWORD:123456}

fortune:
  jwt:
    secret: fortune-mini-app-secret-key-2024-local-dev
  deepseek:
    api-key: ${DEEPSEEK_API_KEY}
  wechat:
    app-id: ${WECHAT_APP_ID}
    app-secret: ${WECHAT_APP_SECRET}
```

### application-prod.yml
生产环境配置，使用Docker容器化服务：

```yaml
spring:
  datasource:
    driver-class-name: com.mysql.cj.jdbc.Driver
    url: jdbc:mysql://mysql:3306/fortune_db
    username: root
    password: ${MYSQL_PASSWORD}
  redis:
    host: redis
    port: 6379

fortune:
  jwt:
    secret: ${JWT_SECRET}
  deepseek:
    api-key: ${DEEPSEEK_API_KEY}
  wechat:
    app-id: ${WECHAT_APP_ID}
    app-secret: ${WECHAT_APP_SECRET}
```

---

## 🔍 常见问题

### Q1: 数据库连接失败
**现象**: 无法连接MySQL数据库
**解决方案**:
```bash
# 检查MySQL服务状态
sudo systemctl status mysql

# 检查端口占用
netstat -an | grep 3306

# 重置MySQL密码
sudo mysql
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '123456';
FLUSH PRIVILEGES;
```

### Q2: Docker容器启动失败
**现象**: 容器无法正常启动
**解决方案**:
```bash
# 查看详细错误信息
docker-compose logs backend

# 检查磁盘空间
df -h

# 清理Docker资源
docker system prune -a
```

### Q3: 微信API调用失败
**现象**: 微信登录功能异常
**解决方案**:
1. 检查微信AppID和AppSecret配置
2. 确认服务器域名已在微信公众平台配置
3. 检查网络连接和防火墙设置

### Q4: API响应缓慢
**现象**: 接口响应时间过长
**解决方案**:
```bash
# 检查数据库连接池配置
# 启用Redis缓存
# 优化SQL查询语句
# 增加服务器资源
```

---

## 📈 运维监控

### 1. 健康检查
```bash
# 后端服务健康检查
curl https://your-domain.com/api/actuator/health

# 数据库连接检查
docker exec -it bagua-mysql-prod mysql -u root -p -e "SELECT 1;"
```

### 2. 日志监控
```bash
# 查看应用日志
docker-compose logs -f backend

# 查看nginx日志
docker-compose logs -f nginx

# 查看数据库日志
docker-compose logs -f mysql
```

### 3. 性能监控
```bash
# 系统资源监控
htop
free -m
df -h

# Docker容器监控
docker stats

# 数据库性能监控
docker exec -it bagua-mysql-prod mysql -u root -p -e "SHOW PROCESSLIST;"
```

### 4. 备份策略
```bash
# 数据库备份脚本
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
docker exec bagua-mysql-prod mysqldump -u root -p$MYSQL_PASSWORD fortune_db > /backup/fortune_db_$DATE.sql

# 定时任务配置
crontab -e
# 每天凌晨2点备份
0 2 * * * /opt/bagua-ai/scripts/backup.sh
```

---

## 🔒 安全建议

### 1. 数据库安全
- 使用强密码
- 限制数据库访问IP
- 定期更新密码
- 启用SQL审计日志

### 2. 应用安全
- 定期更新依赖包
- 配置防火墙规则
- 启用HTTPS
- 实施API访问频率限制

### 3. 服务器安全
- 禁用root远程登录
- 配置SSH密钥认证
- 定期安全更新
- 监控异常登录

---

## 📞 技术支持

### 联系方式
- **技术文档**: [项目README](../README.md)
- **API文档**: `/api/swagger-ui.html`
- **问题反馈**: [GitHub Issues](https://github.com/your-username/bagua-ai/issues)

### 更新记录
- **2024-12**: 删除H2数据库，统一使用MySQL
- **2024-12**: 完善微信小程序集成
- **2024-12**: 优化Docker部署流程

---

*部署指南最后更新: 2024年12月* 