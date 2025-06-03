# AI八卦运势小程序 - 本地Docker环境部署指南

## 📋 部署概述

本文档专门针对本地开发环境的Docker部署，详细介绍如何在本地Docker环境中部署AI八卦运势小程序，包括网络问题解决、镜像加速配置、离线部署等多种方案。

## ⚠️ 本地环境常见问题

在本地开发环境中，经常遇到以下问题：
- 🚫 **镜像拉取失败** - Docker Hub访问受限
- 🌐 **DNS解析问题** - 镜像源域名无法解析
- 🔒 **公司网络限制** - 防火墙阻止Docker流量
- ⏰ **下载速度慢** - 国外镜像源速度慢

## 🛠️ 解决方案概览

我们提供多种解决方案，请根据您的网络环境选择：

1. **方案一**：配置国内镜像加速（推荐）
2. **方案二**：使用代理服务
3. **方案三**：离线镜像部署
4. **方案四**：本地构建镜像

## 🚀 方案一：配置国内镜像加速

### 1.1 macOS Docker Desktop 配置

#### 步骤1：打开Docker Desktop设置
1. 点击菜单栏的Docker图标
2. 选择 `Preferences...` 或 `Settings`
3. 点击左侧 `Docker Engine`

#### 步骤2：配置镜像加速
在JSON编辑器中输入以下配置：

```json
{
  "builder": {
    "gc": {
      "defaultKeepStorage": "20GB",
      "enabled": true
    }
  },
  "experimental": false,
  "registry-mirrors": [
    "https://dockerhub.azk8s.cn",
    "https://reg-mirror.qiniu.com",
    "https://registry.docker-cn.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ]
}
```

#### 步骤3：应用配置
1. 点击 `Apply & Restart`
2. 等待Docker重启完成

### 1.2 Linux 环境配置

```bash
# 创建Docker配置目录
sudo mkdir -p /etc/docker

# 创建daemon.json配置文件
sudo tee /etc/docker/daemon.json << 'EOF'
{
  "registry-mirrors": [
    "https://dockerhub.azk8s.cn",
    "https://reg-mirror.qiniu.com",
    "https://registry.docker-cn.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
EOF

# 重启Docker服务
sudo systemctl daemon-reload
sudo systemctl restart docker

# 验证配置
docker info | grep -A 10 "Registry Mirrors"
```

### 1.3 Windows Docker Desktop 配置

1. 右键点击系统托盘的Docker图标
2. 选择 `Settings`
3. 点击左侧 `Docker Engine`
4. 在JSON编辑器中添加镜像配置（同macOS配置）
5. 点击 `Apply & Restart`

## 🔧 方案二：使用代理服务

### 2.1 HTTP/HTTPS 代理配置

如果您有可用的代理服务，可以配置Docker使用代理：

#### macOS/Linux 环境变量方式
```bash
# 设置环境变量
export HTTP_PROXY=http://proxy.company.com:8080
export HTTPS_PROXY=http://proxy.company.com:8080
export NO_PROXY=localhost,127.0.0.1

# 重启Docker
sudo systemctl restart docker  # Linux
# 或重启Docker Desktop         # macOS/Windows
```

#### Docker Desktop 代理配置
1. 打开Docker Desktop设置
2. 点击 `Resources` → `Proxies`
3. 启用 `Manual proxy configuration`
4. 输入代理服务器地址和端口
5. 点击 `Apply & Restart`

### 2.2 SOCKS5 代理配置

```bash
# 使用proxychains（Linux/macOS）
sudo apt install proxychains-ng  # Ubuntu
brew install proxychains-ng      # macOS

# 配置proxychains
echo "socks5 127.0.0.1 1080" | sudo tee -a /etc/proxychains.conf

# 通过代理运行Docker命令
proxychains docker pull mysql:8.0
```

## 📦 方案三：离线镜像部署

### 3.1 使用预构建镜像

我们提供预构建的镜像文件，适用于完全离线环境：

```bash
# 创建离线镜像目录
mkdir -p ~/docker-images
cd ~/docker-images

# 下载预构建镜像（需要在有网络的环境下进行）
# 这些命令在有网络的机器上执行，然后传输镜像文件

# 导出镜像到文件
docker save mysql:8.0 -o mysql-8.0.tar
docker save redis:6.2-alpine -o redis-6.2-alpine.tar
docker save nginx:alpine -o nginx-alpine.tar
docker save openjdk:17-jre-slim -o openjdk-17-jre-slim.tar

# 在离线环境导入镜像
docker load -i mysql-8.0.tar
docker load -i redis-6.2-alpine.tar
docker load -i nginx-alpine.tar
docker load -i openjdk-17-jre-slim.tar

# 验证镜像
docker images
```

### 3.2 创建离线部署包

```bash
# 创建完整的离线部署包
mkdir -p offline-deployment
cd offline-deployment

# 复制项目文件
cp -r ../bagua-ai ./

# 创建镜像目录
mkdir docker-images

# 导出所需镜像
docker save mysql:8.0 redis:6.2-alpine nginx:alpine openjdk:17-jre-slim \
  -o docker-images/base-images.tar

# 创建部署脚本
cat > deploy-offline.sh << 'EOF'
#!/bin/bash
echo "开始离线部署..."

# 加载镜像
echo "加载Docker镜像..."
docker load -i docker-images/base-images.tar

# 验证镜像
echo "验证镜像..."
docker images

# 启动服务
echo "启动服务..."
cd bagua-ai
docker-compose up -d

echo "部署完成！"
EOF

chmod +x deploy-offline.sh
```

## 🏗️ 方案四：本地构建镜像

### 4.1 创建本地基础镜像

```bash
# 创建自定义基础镜像目录
mkdir -p docker-base
cd docker-base

# 创建 Alpine 基础镜像 Dockerfile
cat > Dockerfile.alpine << 'EOF'
FROM alpine:latest

# 使用国内镜像源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装基础工具
RUN apk add --no-cache \
    curl \
    wget \
    bash \
    && rm -rf /var/cache/apk/*

# 安装JDK
RUN apk add --no-cache openjdk17-jre

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk
ENV PATH=$PATH:$JAVA_HOME/bin

WORKDIR /app
EOF

# 构建基础镜像
docker build -f Dockerfile.alpine -t local/java:17-alpine .
```

### 4.2 创建应用镜像

```bash
# 进入后端目录
cd ../backend

# 创建优化的 Dockerfile
cat > Dockerfile.local << 'EOF'
# 使用本地构建的基础镜像
FROM local/java:17-alpine

# 安装应用依赖
RUN apk add --no-cache curl

# 设置工作目录
WORKDIR /app

# 复制应用文件
COPY target/*.jar app.jar

# 暴露端口
EXPOSE 8080

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/api/actuator/health || exit 1

# 启动应用
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF

# 构建应用镜像
mvn clean package -DskipTests
docker build -f Dockerfile.local -t bagua-ai/backend:local .
```

## 🐳 本地Docker Compose配置

### 5.1 创建本地开发配置

```bash
# 创建本地开发用的 docker-compose 文件
cat > docker-compose.local.yml << 'EOF'
version: '3.8'

services:
  # MySQL数据库
  mysql:
    image: mysql:8.0
    container_name: bagua-mysql-local
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: root123456
      MYSQL_DATABASE: fortune_db
      MYSQL_USER: fortune_user
      MYSQL_PASSWORD: fortune123456
      MYSQL_CHARSET: utf8mb4
      MYSQL_COLLATION: utf8mb4_unicode_ci
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      - ./backend/src/main/resources/sql/init.sql:/docker-entrypoint-initdb.d/init.sql
    command: --default-authentication-plugin=mysql_native_password
      --character-set-server=utf8mb4
      --collation-server=utf8mb4_unicode_ci
    networks:
      - fortune-local

  # Redis缓存
  redis:
    image: redis:6.2-alpine
    container_name: bagua-redis-local
    restart: unless-stopped
    command: redis-server --requirepass redis123456
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - fortune-local

  # 后端应用
  backend:
    build: 
      context: ./backend
      dockerfile: Dockerfile.local
    container_name: bagua-backend-local
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=local
      - MYSQL_HOST=mysql
      - MYSQL_PORT=3306
      - MYSQL_DATABASE=fortune_db
      - MYSQL_USERNAME=fortune_user
      - MYSQL_PASSWORD=fortune123456
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - REDIS_PASSWORD=redis123456
      - DEEPSEEK_API_KEY=${DEEPSEEK_API_KEY:-your-api-key}
      - WECHAT_APP_ID=${WECHAT_APP_ID:-your-app-id}
      - WECHAT_APP_SECRET=${WECHAT_APP_SECRET:-your-app-secret}
      - JWT_SECRET=local-jwt-secret-key-for-development
    depends_on:
      - mysql
      - redis
    volumes:
      - ./backend/src/main/java:/app/src/main/java
      - ./backend/target:/app/target
    networks:
      - fortune-local
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/api/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 2m

volumes:
  mysql_data:
    driver: local
  redis_data:
    driver: local

networks:
  fortune-local:
    driver: bridge
EOF
```

### 5.2 创建本地环境变量

```bash
# 创建本地环境变量文件
cat > .env.local << 'EOF'
# API密钥配置（请填入真实值）
DEEPSEEK_API_KEY=your-deepseek-api-key
WECHAT_APP_ID=your-wechat-app-id
WECHAT_APP_SECRET=your-wechat-app-secret

# 本地开发配置
ENVIRONMENT=local
DEBUG=true
LOG_LEVEL=DEBUG
EOF
```

## 🚀 本地部署执行

### 6.1 快速启动

```bash
# 使用本地配置启动
docker-compose -f docker-compose.local.yml --env-file .env.local up -d

# 查看服务状态
docker-compose -f docker-compose.local.yml ps

# 查看日志
docker-compose -f docker-compose.local.yml logs -f backend
```

### 6.2 开发模式启动

```bash
# 仅启动数据库服务，应用在IDE中运行
docker-compose -f docker-compose.local.yml up -d mysql redis

# 验证数据库连接
docker exec bagua-mysql-local mysql -ufortune_user -pfortune123456 -e "SHOW DATABASES;"

# 验证Redis连接
docker exec bagua-redis-local redis-cli -a redis123456 ping
```

## 🔍 故障排查

### 7.1 网络诊断

```bash
# 测试基础网络连接
ping baidu.com

# 测试DNS解析
nslookup registry-1.docker.io
nslookup dockerhub.azk8s.cn

# 测试Docker服务
docker version
docker info
```

### 7.2 镜像问题解决

```bash
# 查看Docker镜像加速配置
docker info | grep -A 10 "Registry Mirrors"

# 手动指定镜像源拉取
docker pull dockerhub.azk8s.cn/library/mysql:8.0

# 重新标记镜像
docker tag dockerhub.azk8s.cn/library/mysql:8.0 mysql:8.0

# 清理无用镜像
docker system prune -a
```

### 7.3 容器问题排查

```bash
# 查看容器状态
docker ps -a

# 查看容器日志
docker logs bagua-backend-local

# 进入容器调试
docker exec -it bagua-backend-local /bin/sh

# 检查容器网络
docker network ls
docker network inspect bagua-ai_fortune-local
```

## 📊 本地开发验证

### 8.1 服务验证清单

完成部署后，请验证以下项目：

#### ✅ 基础服务
- [ ] MySQL容器正常运行：`docker ps | grep mysql`
- [ ] Redis容器正常运行：`docker ps | grep redis`
- [ ] Backend容器正常运行：`docker ps | grep backend`

#### ✅ 网络连接
- [ ] 数据库连接：`http://localhost:8080/api/actuator/health`
- [ ] Redis连接：容器间网络通信正常
- [ ] API访问：`curl http://localhost:8080/api/test`

#### ✅ 功能测试
- [ ] 健康检查接口：`GET /api/actuator/health`
- [ ] 用户注册接口：`POST /api/auth/register`
- [ ] 运势查询接口：`POST /api/fortune/query`

### 8.2 性能监控

```bash
# 查看资源使用
docker stats

# 查看磁盘使用
docker system df

# 查看网络状态
docker network ls
```

## 🔧 本地开发优化

### 9.1 开发环境优化

```bash
# 创建开发专用的compose文件
cat > docker-compose.dev.yml << 'EOF'
version: '3.8'

services:
  mysql:
    extends:
      file: docker-compose.local.yml
      service: mysql
    volumes:
      - mysql_data:/var/lib/mysql
      - ./backend/src/main/resources/sql:/docker-entrypoint-initdb.d
      - ./logs/mysql:/var/log/mysql

  redis:
    extends:
      file: docker-compose.local.yml
      service: redis
    volumes:
      - redis_data:/data
      - ./logs/redis:/var/log/redis

volumes:
  mysql_data:
  redis_data:
EOF

# 开发模式启动（只启动数据库）
docker-compose -f docker-compose.dev.yml up -d

# 在IDE中启动Spring Boot应用，连接到容器化的数据库
```

### 9.2 热重载配置

```bash
# 配置Spring Boot开发工具
# 在 application-local.yml 中添加：
cat > backend/src/main/resources/application-local.yml << 'EOF'
spring:
  devtools:
    restart:
      enabled: true
    livereload:
      enabled: true
  datasource:
    url: jdbc:mysql://localhost:3306/fortune_db?useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Shanghai
    username: fortune_user
    password: fortune123456
  redis:
    host: localhost
    port: 6379
    password: redis123456

logging:
  level:
    com.fortune: DEBUG
    org.springframework.web: DEBUG
EOF
```

## 📝 本地部署总结

通过本指南，您可以在本地环境中成功部署AI八卦运势小程序，包括：

- ✅ **多种网络解决方案** - 适应不同网络环境
- ✅ **完整的开发环境** - 支持热重载和调试
- ✅ **离线部署能力** - 适用于受限网络环境
- ✅ **故障排查指南** - 快速解决常见问题

**推荐开发流程**：
1. 首先尝试方案一（镜像加速）
2. 如果网络仍有问题，使用方案三（离线部署）
3. 日常开发使用开发模式（只启动数据库）
4. 集成测试时使用完整容器环境

如有问题，请参考故障排查章节或根据具体错误信息进行调试。 