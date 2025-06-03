# AI八卦运势小程序 - 腾讯云Docker环境部署指南

## 📋 部署概述

本文档专门针对腾讯云预装Docker的Ubuntu镜像环境，详细介绍如何部署AI八卦运势小程序的Spring Boot后端服务。适用于腾讯云轻量应用服务器或CVM实例中选择"Docker CE"应用镜像的场景。

## ⚠️ 网络环境说明

**重要提醒**：如果您在本地开发环境遇到Docker镜像拉取问题，这是正常现象。本部署方案专门针对腾讯云服务器环境优化，在腾讯云内网环境下：

- ✅ **镜像拉取速度极快** - 使用内网加速
- ✅ **网络连接稳定** - 无防火墙限制  
- ✅ **DNS解析正常** - 内网DNS服务
- ✅ **一键部署成功率高** - 专门优化

**建议**：直接在腾讯云服务器上执行部署，跳过本地测试。

## 🏗️ 环境说明

```
腾讯云Ubuntu + Docker CE 镜像
├── Ubuntu 20.04/22.04 LTS
├── Docker Engine (预装)
├── Docker Compose (需要安装)
├── MySQL 8.0 (容器部署)
├── Redis 6.2 (容器部署)
├── Spring Boot App (容器部署)
└── Nginx (容器部署 - 可选)
```

## 🚀 快速部署步骤

### 第一步：登录服务器并检查环境

#### 1.1 SSH连接服务器
```bash
# 使用腾讯云提供的公网IP连接
ssh root@your-server-ip

# 或者使用ubuntu用户（根据镜像配置）
ssh ubuntu@your-server-ip
```

#### 1.2 检查Docker状态
```bash
# 检查Docker版本（已预装）
sudo docker --version

# 检查Docker服务状态
sudo systemctl status docker

# 如果Docker服务未启动，启动它
sudo systemctl start docker
sudo systemctl enable docker

# 检查当前用户是否在docker组（重要）
groups

# 如果当前用户不在docker组，添加到docker组
sudo usermod -aG docker $USER

# 重新登录或刷新组权限
newgrp docker
```

#### 1.3 安装Docker Compose
```bash
# 更新包管理器
sudo apt update

# 安装必要工具
sudo apt install -y curl wget git vim htop

# 下载并安装Docker Compose
# 使用GitHub官方下载地址（最稳定的方式）
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# 设置执行权限
sudo chmod +x /usr/local/bin/docker-compose

# 验证安装
sudo docker-compose --version
```

### 第二步：下载项目代码

#### 2.1 克隆项目仓库
```bash
# 创建项目目录
sudo mkdir -p /opt/fortune-app
cd /opt/fortune-app

# 克隆项目（替换为您的仓库地址）
sudo git clone https://github.com/yourusername/bagua-ai.git .

# 设置目录权限
sudo chown -R $USER:$USER /opt/fortune-app
```

#### 2.2 检查项目结构
```bash
# 查看项目结构
ls -la

# 应该看到以下目录和文件：
# backend/
# frontend/
# docker-compose.yml
# docs/
# scripts/
```

### 第三步：创建环境配置

#### 3.1 创建环境变量文件
```bash
# 生成随机密码（安装pwgen工具）
sudo apt install -y pwgen openssl

# 创建.env文件
sudo tee .env << EOF
# MySQL配置
MYSQL_ROOT_PASSWORD=$(openssl rand -hex 16)
MYSQL_DATABASE=fortune_db
MYSQL_USER=fortune_user
MYSQL_PASSWORD=$(openssl rand -hex 16)

# Redis配置
REDIS_PASSWORD=$(openssl rand -hex 16)

# API密钥配置（需要手动填写）
DEEPSEEK_API_KEY=your-deepseek-api-key
WECHAT_APP_ID=your-wechat-app-id
WECHAT_APP_SECRET=your-wechat-app-secret

# JWT密钥
JWT_SECRET=$(openssl rand -hex 32)

# 服务器配置
SERVER_HOST=$(curl -s http://ip.3322.net || echo "localhost")
SSL_ENABLED=false
EOF

# 设置文件权限
sudo chmod 600 .env
sudo chown $USER:$USER .env

# 查看生成的配置
cat .env
```

#### 3.2 编辑API密钥配置
```bash
# 使用vim编辑.env文件，填入真实的API密钥
sudo vim .env

# 或者使用sed命令替换（推荐）
# 替换DeepSeek API Key
sudo sed -i 's/your-deepseek-api-key/实际的API密钥/' .env

# 替换微信小程序配置
sudo sed -i 's/your-wechat-app-id/实际的AppID/' .env
sudo sed -i 's/your-wechat-app-secret/实际的AppSecret/' .env
```

### 第四步：创建配置文件和目录

#### 4.1 创建目录结构
```bash
# 创建必要的目录
sudo mkdir -p mysql/conf.d
sudo mkdir -p redis
sudo mkdir -p nginx/logs
sudo mkdir -p nginx/ssl
sudo mkdir -p monitoring
sudo mkdir -p /backup

# 设置目录权限
sudo chown -R $USER:$USER mysql redis nginx monitoring
sudo chmod 755 /backup
```

#### 4.2 创建MySQL配置文件
```bash
# 创建MySQL配置
sudo tee mysql/conf.d/custom.cnf << 'EOF'
[mysqld]
# 基本配置
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
default-time-zone='+08:00'

# 性能优化（根据服务器配置调整）
innodb_buffer_pool_size=256M
innodb_log_file_size=64M
max_connections=200
query_cache_size=64M
query_cache_type=1

# 安全配置
sql_mode=STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO

# 网络配置
bind-address=0.0.0.0
EOF
```

#### 4.3 创建Redis配置文件
```bash
# 创建Redis配置
sudo tee redis/redis.conf << 'EOF'
# Redis配置文件
bind 0.0.0.0
port 6379
timeout 300
keepalive 60

# 内存配置（根据服务器配置调整）
maxmemory 256mb
maxmemory-policy allkeys-lru

# 持久化配置
save 900 1
save 300 10
save 60 10000
appendonly yes
appendfsync everysec

# 安全配置
protected-mode no
EOF
```

#### 4.4 创建Nginx配置文件
```bash
# 创建Nginx配置
sudo tee nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
pid /var/run/nginx.pid;
error_log /var/log/nginx/error.log warn;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # 日志格式
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    # 基本配置
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 10M;

    # Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/json;

    # 后端服务
    upstream backend {
        server backend:8080;
        keepalive 32;
    }

    # HTTP服务器配置
    server {
        listen 80;
        server_name _;

        # 健康检查
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }

        # API代理
        location /api/ {
            proxy_pass http://backend/api/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
            proxy_buffering off;
        }

        # 默认页面
        location / {
            return 200 "Fortune Mini App API Server";
            add_header Content-Type text/plain;
        }
    }
}
EOF
```

### 第五步：创建生产环境Docker配置

#### 5.1 创建生产环境Dockerfile
```bash
# 创建后端生产环境Dockerfile
sudo tee backend/Dockerfile.prod << 'EOF'
# 多阶段构建 - 构建阶段
FROM ccr.ccs.tencentcloudcr.com/public/maven:3.8.6-openjdk-17 AS builder

# 设置工作目录
WORKDIR /app

# 配置Maven使用腾讯云镜像
RUN mkdir -p /root/.m2 && \
    echo '<?xml version="1.0" encoding="UTF-8"?>' > /root/.m2/settings.xml && \
    echo '<settings>' >> /root/.m2/settings.xml && \
    echo '  <mirrors>' >> /root/.m2/settings.xml && \
    echo '    <mirror>' >> /root/.m2/settings.xml && \
    echo '      <id>tencent</id>' >> /root/.m2/settings.xml && \
    echo '      <mirrorOf>central</mirrorOf>' >> /root/.m2/settings.xml && \
    echo '      <url>https://mirrors.cloud.tencent.com/nexus/repository/maven-public/</url>' >> /root/.m2/settings.xml && \
    echo '    </mirror>' >> /root/.m2/settings.xml && \
    echo '  </mirrors>' >> /root/.m2/settings.xml && \
    echo '</settings>' >> /root/.m2/settings.xml

# 复制Maven配置文件
COPY pom.xml .

# 下载依赖（利用Docker缓存）
RUN mvn dependency:go-offline -B

# 复制源代码
COPY src ./src

# 构建应用（跳过测试）
RUN mvn clean package -DskipTests

# 生产阶段
FROM ccr.ccs.tencentcloudcr.com/public/openjdk:17-jre-slim

# 使用腾讯云镜像源安装必要工具
RUN sed -i 's/deb.debian.org/mirrors.tencentyun.com/g' /etc/apt/sources.list && \
    sed -i 's/security.debian.org/mirrors.tencentyun.com/g' /etc/apt/sources.list && \
    apt-get update && apt-get install -y \
    curl \
    dumb-init \
    && rm -rf /var/lib/apt/lists/*

# 创建应用用户
RUN groupadd -r app && useradd -r -g app app

# 设置工作目录
WORKDIR /app

# 从构建阶段复制jar文件
COPY --from=builder /app/target/*.jar app.jar

# 创建日志目录
RUN mkdir -p /app/logs && chown -R app:app /app

# 切换到应用用户
USER app

# 暴露端口
EXPOSE 8080

# 设置JVM参数（根据服务器配置调整）
ENV JAVA_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC -XX:+PrintGC -XX:+PrintGCDetails"

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
  CMD curl -f http://localhost:8080/api/actuator/health || exit 1

# 使用dumb-init启动应用
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
EOF
```

#### 5.2 创建生产环境Docker Compose文件
```bash
# 创建生产环境docker-compose文件
sudo tee docker-compose.prod.yml << 'EOF'
version: '3.8'

services:
  # MySQL数据库
  mysql:
    image: ccr.ccs.tencentcloudcr.com/public/mysql:8.0
    container_name: fortune-mysql-prod
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
      MYSQL_CHARSET: utf8mb4
      MYSQL_COLLATION: utf8mb4_unicode_ci
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      - ./backend/src/main/resources/sql/init.sql:/docker-entrypoint-initdb.d/init.sql
      - ./mysql/conf.d:/etc/mysql/conf.d
    command: --default-authentication-plugin=mysql_native_password
      --character-set-server=utf8mb4
      --collation-server=utf8mb4_unicode_ci
      --innodb-buffer-pool-size=256M
    networks:
      - fortune-network
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  # Redis缓存
  redis:
    image: ccr.ccs.tencentcloudcr.com/public/redis:6.2-alpine
    container_name: fortune-redis-prod
    restart: unless-stopped
    command: redis-server /usr/local/etc/redis/redis.conf --requirepass ${REDIS_PASSWORD}
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
      - ./redis/redis.conf:/usr/local/etc/redis/redis.conf
    networks:
      - fortune-network
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  # 后端应用
  backend:
    build: 
      context: ./backend
      dockerfile: Dockerfile.prod
    container_name: fortune-backend-prod
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=prod
      - MYSQL_HOST=mysql
      - MYSQL_PORT=3306
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USERNAME=${MYSQL_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - REDIS_PASSWORD=${REDIS_PASSWORD}
      - DEEPSEEK_API_KEY=${DEEPSEEK_API_KEY}
      - WECHAT_APP_ID=${WECHAT_APP_ID}
      - WECHAT_APP_SECRET=${WECHAT_APP_SECRET}
      - JWT_SECRET=${JWT_SECRET}
    depends_on:
      - mysql
      - redis
    volumes:
      - app_logs:/app/logs
    networks:
      - fortune-network
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "5"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/api/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 3m

  # Nginx反向代理
  nginx:
    image: ccr.ccs.tencentcloudcr.com/public/nginx:alpine
    container_name: fortune-nginx-prod
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/ssl:/etc/nginx/ssl
      - ./nginx/logs:/var/log/nginx
    depends_on:
      - backend
    networks:
      - fortune-network
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

volumes:
  mysql_data:
    driver: local
  redis_data:
    driver: local
  app_logs:
    driver: local

networks:
  fortune-network:
    driver: bridge
EOF
```

### 第六步：构建和部署应用

#### 6.1 检查环境配置
```bash
# 验证.env文件配置
echo "检查环境配置："
cat .env

# 确保API密钥已正确配置
if grep -q "your-deepseek-api-key" .env; then
    echo "⚠️  警告：请配置 DEEPSEEK_API_KEY"
fi

if grep -q "your-wechat-app-id" .env; then
    echo "⚠️  警告：请配置 WECHAT_APP_ID 和 WECHAT_APP_SECRET"
fi
```

#### 6.2 拉取基础镜像
```bash
# 拉取所需的基础镜像
echo "拉取Docker镜像..."
sudo docker pull ccr.ccs.tencentcloudcr.com/public/mysql:8.0
sudo docker pull ccr.ccs.tencentcloudcr.com/public/redis:6.2-alpine
sudo docker pull ccr.ccs.tencentcloudcr.com/public/nginx:alpine
sudo docker pull ccr.ccs.tencentcloudcr.com/public/maven:3.8.6-openjdk-17
sudo docker pull ccr.ccs.tencentcloudcr.com/public/openjdk:17-jre-slim
```

#### 6.3 构建应用镜像
```bash
# 构建后端应用镜像
echo "构建应用镜像..."
sudo docker-compose -f docker-compose.prod.yml build --no-cache backend

# 检查镜像是否构建成功
sudo docker images | grep fortune
```

#### 6.4 启动所有服务
```bash
# 启动所有服务
echo "启动服务..."
sudo docker-compose -f docker-compose.prod.yml up -d

# 查看服务状态
echo "检查服务状态..."
sudo docker-compose -f docker-compose.prod.yml ps

# 查看服务日志
echo "查看启动日志..."
sudo docker-compose -f docker-compose.prod.yml logs --tail=50
```

### 第七步：验证部署

#### 7.1 等待服务启动
```bash
# 等待服务完全启动（大约2-3分钟）
echo "等待服务启动完成..."
sleep 180

# 检查容器状态
sudo docker ps -a
```

#### 7.2 验证数据库连接
```bash
# 检查MySQL容器
sudo docker exec fortune-mysql-prod mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} -e "SHOW DATABASES;"

# 检查Redis连接
sudo docker exec fortune-redis-prod redis-cli -a ${REDIS_PASSWORD} ping
```

#### 7.3 验证应用健康状态
```bash
# 检查应用健康状态
curl http://localhost:8080/api/actuator/health

# 检查Nginx代理
curl http://localhost/health

# 获取公网IP并测试外网访问
SERVER_IP=$(curl -s http://ip.3322.net)
echo "公网访问测试："
curl http://$SERVER_IP:8080/api/actuator/health
```

### 第八步：配置防火墙和安全

#### 8.1 配置Ubuntu防火墙
```bash
# 启用UFW防火墙
sudo ufw --force enable

# 允许SSH连接
sudo ufw allow 22/tcp

# 允许HTTP和HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# 允许应用端口
sudo ufw allow 8080/tcp

# 查看防火墙状态
sudo ufw status verbose
```

#### 8.2 配置腾讯云安全组
```bash
echo "请在腾讯云控制台配置安全组规则："
echo "入站规则："
echo "  SSH      22    TCP  0.0.0.0/0"
echo "  HTTP     80    TCP  0.0.0.0/0"
echo "  HTTPS    443   TCP  0.0.0.0/0" 
echo "  Custom   8080  TCP  0.0.0.0/0"
```

### 第九步：创建管理脚本

#### 9.1 创建应用管理脚本
```bash
# 创建应用管理脚本
sudo tee manage.sh << 'EOF'
#!/bin/bash

case "$1" in
    start)
        echo "启动服务..."
        sudo docker-compose -f docker-compose.prod.yml up -d
        ;;
    stop)
        echo "停止服务..."
        sudo docker-compose -f docker-compose.prod.yml down
        ;;
    restart)
        echo "重启服务..."
        sudo docker-compose -f docker-compose.prod.yml restart
        ;;
    logs)
        echo "查看日志..."
        sudo docker-compose -f docker-compose.prod.yml logs -f ${2:-backend}
        ;;
    status)
        echo "查看状态..."
        sudo docker-compose -f docker-compose.prod.yml ps
        sudo docker stats --no-stream
        ;;
    update)
        echo "更新应用..."
        git pull
        sudo docker-compose -f docker-compose.prod.yml build --no-cache backend
        sudo docker-compose -f docker-compose.prod.yml up -d backend
        ;;
    backup)
        echo "备份数据..."
        ./backup.sh
        ;;
    *)
        echo "使用方法: $0 {start|stop|restart|logs|status|update|backup}"
        exit 1
        ;;
esac
EOF

sudo chmod +x manage.sh
```

#### 9.2 创建数据备份脚本
```bash
# 创建数据备份脚本
sudo tee backup.sh << 'EOF'
#!/bin/bash

# 加载环境变量
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d_%H%M%S)

# 创建备份目录
sudo mkdir -p $BACKUP_DIR

echo "开始备份数据..."

# 备份MySQL数据
echo "备份MySQL数据库..."
sudo docker exec fortune-mysql-prod mysqldump -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} > ${BACKUP_DIR}/mysql_backup_${DATE}.sql

# 备份Redis数据
echo "备份Redis数据..."
sudo docker exec fortune-redis-prod redis-cli -a ${REDIS_PASSWORD} --rdb /data/dump.rdb
sudo docker cp fortune-redis-prod:/data/dump.rdb ${BACKUP_DIR}/redis_backup_${DATE}.rdb

# 备份配置文件
echo "备份配置文件..."
sudo tar -czf ${BACKUP_DIR}/config_backup_${DATE}.tar.gz .env docker-compose.prod.yml mysql/ redis/ nginx/

# 压缩所有备份文件
echo "压缩备份文件..."
sudo tar -czf ${BACKUP_DIR}/fortune_backup_${DATE}.tar.gz ${BACKUP_DIR}/*_backup_${DATE}.*

# 清理临时文件
sudo rm -f ${BACKUP_DIR}/*_backup_${DATE}.sql ${BACKUP_DIR}/*_backup_${DATE}.rdb ${BACKUP_DIR}/*_backup_${DATE}.tar.gz

# 删除7天前的备份
sudo find ${BACKUP_DIR} -name "fortune_backup_*.tar.gz" -mtime +7 -delete

echo "备份完成: ${BACKUP_DIR}/fortune_backup_${DATE}.tar.gz"
sudo ls -lh ${BACKUP_DIR}/fortune_backup_${DATE}.tar.gz
EOF

sudo chmod +x backup.sh
```

#### 9.3 设置定时备份
```bash
# 添加定时备份任务
echo "设置定时备份..."
(sudo crontab -l 2>/dev/null; echo "0 2 * * * cd /opt/fortune-app && /opt/fortune-app/backup.sh >> /var/log/backup.log 2>&1") | sudo crontab -

# 验证定时任务
sudo crontab -l
```

### 第十步：测试和验证

#### 10.1 功能测试
```bash
# 测试健康检查接口
echo "测试健康检查接口："
curl -v http://localhost:8080/api/actuator/health

# 获取公网IP并测试外网访问
SERVER_IP=$(curl -s http://ip.3322.net)
echo "公网访问测试："
curl -v http://$SERVER_IP:8080/api/actuator/health

# 测试Nginx代理
echo "测试Nginx代理："
curl -v http://$SERVER_IP/health
```

#### 10.2 性能监控
```bash
# 查看系统资源使用
echo "系统资源使用情况："
free -h
df -h
sudo docker stats --no-stream

# 查看服务状态
echo "服务运行状态："
sudo docker-compose -f docker-compose.prod.yml ps
```

## 📊 部署完成验证清单

完成以上步骤后，请验证以下项目：

### ✅ 服务验证
- [ ] MySQL容器正常运行
- [ ] Redis容器正常运行  
- [ ] Backend容器正常运行
- [ ] Nginx容器正常运行

### ✅ 网络验证
- [ ] 内网健康检查：`http://localhost:8080/api/actuator/health`
- [ ] 外网应用访问：`http://公网IP:8080/api/actuator/health`
- [ ] Nginx代理访问：`http://公网IP/health`

### ✅ 数据库验证
- [ ] MySQL连接正常
- [ ] Redis连接正常
- [ ] 数据表创建成功

### ✅ 安全验证
- [ ] 防火墙规则配置正确
- [ ] 腾讯云安全组配置正确
- [ ] 环境变量文件权限正确

## 🔧 常用管理命令

```bash
# 查看服务状态
./manage.sh status

# 查看应用日志
./manage.sh logs backend

# 重启服务
./manage.sh restart

# 更新应用
./manage.sh update

# 备份数据
./manage.sh backup

# 停止所有服务
./manage.sh stop

# 启动所有服务
./manage.sh start
```

## ❗ 故障排查

### 常见问题解决

1. **权限问题**
```bash
# 如果遇到权限不足的错误
sudo chmod +x scripts/*.sh
sudo chown -R $USER:$USER /opt/fortune-app
```

2. **Docker镜像拉取失败**
```bash
# 使用腾讯云镜像加速
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
    "registry-mirrors": [
        "https://mirror.ccs.tencentcloudcr.com",
        "https://ccr.ccs.tencentcloudcr.com"
    ]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```

3. **容器启动失败**
```bash
# 查看容器日志
sudo docker-compose -f docker-compose.prod.yml logs container-name

# 查看容器详细信息
sudo docker inspect container-name
```

4. **端口占用问题**
```bash
# 检查端口占用
sudo netstat -tulpn | grep :8080

# 杀死占用端口的进程
sudo kill -9 PID
```

## 📝 总结

通过本指南，您已经在腾讯云Docker环境中成功部署了AI八卦运势小程序。部署包含：

- ✅ MySQL 8.0 数据库
- ✅ Redis 6.2 缓存
- ✅ Spring Boot 应用
- ✅ Nginx 反向代理
- ✅ 完整的监控和备份方案

如有问题，请检查各个步骤的执行结果，或参考故障排查章节。 