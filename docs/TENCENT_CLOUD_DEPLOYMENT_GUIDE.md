# AI八卦运势小程序 - 腾讯云Docker部署指南

## 📋 部署概述

本文档详细介绍如何将AI八卦运势小程序的Spring Boot后端服务部署到腾讯云的Docker环境中，包括云主机准备、Docker环境搭建、数据库配置、应用部署和监控配置。

## 🏗️ 架构设计

```
腾讯云CVM实例
├── Docker Engine
├── MySQL 8.0 (容器)
├── Redis 6.2 (容器)
├── Spring Boot App (容器)
├── Nginx (容器 - 可选)
└── 监控工具 (Prometheus + Grafana)
```

## 🚀 部署步骤

### 1. 腾讯云环境准备

#### 1.1 购买CVM实例
```bash
# 推荐配置
CPU: 2核
内存: 4GB
硬盘: 40GB云硬盘
操作系统: Ubuntu 20.04 LTS
网络: 5Mbps带宽
地域: 根据用户分布选择（如华南-广州）
```

#### 1.2 安全组配置
```bash
# 入站规则
端口80   - HTTP    - 0.0.0.0/0
端口443  - HTTPS   - 0.0.0.0/0
端口8080 - 应用端口 - 0.0.0.0/0
端口22   - SSH     - 你的IP地址
端口3306 - MySQL   - 内网访问
端口6379 - Redis   - 内网访问
```

#### 1.3 域名配置（可选）
```bash
# 购买域名并配置DNS解析
A记录: api.yourdomain.com -> CVM公网IP
A记录: www.yourdomain.com -> CVM公网IP
```

### 2. 服务器初始化

#### 2.1 连接服务器
```bash
ssh ubuntu@your-server-ip
```

#### 2.2 系统更新
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git vim htop
```

#### 2.3 安装Docker
```bash
# 安装Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# 安装Docker Compose
# 使用腾讯云镜像加速下载
sudo curl -L "https://mirrors.cloud.tencent.com/docker-compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 配置用户权限
sudo usermod -aG docker ubuntu
newgrp docker
```

#### 2.4 验证安装
```bash
docker --version
docker-compose --version
docker run hello-world
```

### 3. 项目部署

#### 3.1 下载项目代码
```bash
# 克隆项目到服务器
git clone https://github.com/yourusername/bagua-ai.git
cd bagua-ai
```

#### 3.2 创建环境变量文件
```bash
# 创建生产环境变量文件
cat > .env << EOF
# MySQL配置
MYSQL_ROOT_PASSWORD=your-secure-root-password
MYSQL_DATABASE=fortune_db
MYSQL_USER=fortune_user
MYSQL_PASSWORD=your-secure-mysql-password

# Redis配置
REDIS_PASSWORD=your-secure-redis-password

# API密钥配置
DEEPSEEK_API_KEY=your-deepseek-api-key
WECHAT_APP_ID=your-wechat-app-id
WECHAT_APP_SECRET=your-wechat-app-secret

# JWT密钥
JWT_SECRET=your-jwt-secret-key-for-production

# 服务器配置
SERVER_HOST=your-domain.com
SSL_ENABLED=true
EOF

# 设置文件权限
chmod 600 .env
```

#### 3.3 创建生产环境Docker配置

##### 3.3.1 更新Dockerfile
```bash
cat > backend/Dockerfile.prod << 'EOF'
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

# 设置JVM参数
ENV JAVA_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC -XX:+PrintGC -XX:+PrintGCDetails"

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/api/actuator/health || exit 1

# 使用dumb-init启动应用
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
EOF
```

##### 3.3.2 创建生产环境Docker Compose
```bash
cat > docker-compose.prod.yml << 'EOF'
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
    command: redis-server --requirepass ${REDIS_PASSWORD} --appendonly yes
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
      start_period: 2m

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

#### 3.4 创建配置文件

##### 3.4.1 MySQL配置
```bash
mkdir -p mysql/conf.d
cat > mysql/conf.d/custom.cnf << 'EOF'
[mysqld]
# 基本配置
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
default-time-zone='+08:00'

# 性能优化
innodb_buffer_pool_size=256M
innodb_log_file_size=64M
max_connections=200
query_cache_size=64M
query_cache_type=1

# 安全配置
sql_mode=STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO
EOF
```

##### 3.4.2 Redis配置
```bash
mkdir -p redis
cat > redis/redis.conf << 'EOF'
# Redis配置文件
bind 0.0.0.0
port 6379
timeout 300
keepalive 60
maxmemory 256mb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000
appendonly yes
appendfsync everysec
EOF
```

##### 3.4.3 Nginx配置
```bash
mkdir -p nginx/logs
cat > nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
pid /var/run/nginx.pid;

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
    error_log /var/log/nginx/error.log warn;

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

        # 静态文件（如果有前端）
        location / {
            root /usr/share/nginx/html;
            index index.html;
            try_files $uri $uri/ /index.html;
        }
    }
}
EOF
```

### 4. 部署执行

#### 4.1 构建和启动服务
```bash
# 构建Docker镜像
docker-compose -f docker-compose.prod.yml build

# 启动所有服务
docker-compose -f docker-compose.prod.yml up -d

# 查看服务状态
docker-compose -f docker-compose.prod.yml ps

# 查看日志
docker-compose -f docker-compose.prod.yml logs -f backend
```

#### 4.2 数据库初始化
```bash
# 等待MySQL启动完成
sleep 30

# 检查数据库连接
docker exec fortune-mysql-prod mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} -e "SHOW DATABASES;"

# 如果需要手动执行SQL
docker exec -i fortune-mysql-prod mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} < backend/src/main/resources/sql/init.sql
```

#### 4.3 验证部署
```bash
# 检查容器状态
docker ps

# 检查健康状态
curl http://localhost:8080/api/actuator/health

# 检查API接口
curl http://localhost:8080/api/test

# 检查Nginx代理
curl http://localhost/api/actuator/health
```

### 5. 监控和日志

#### 5.1 查看应用日志
```bash
# 实时查看应用日志
docker-compose -f docker-compose.prod.yml logs -f backend

# 查看数据库日志
docker-compose -f docker-compose.prod.yml logs mysql

# 查看Nginx日志
docker-compose -f docker-compose.prod.yml logs nginx
```

#### 5.2 系统监控
```bash
# 查看系统资源使用
htop
df -h
docker stats

# 查看Docker容器资源使用
docker stats fortune-backend-prod fortune-mysql-prod fortune-redis-prod
```

#### 5.3 添加监控工具（可选）
```bash
# 添加Prometheus和Grafana
cat >> docker-compose.prod.yml << 'EOF'
  # Prometheus监控
  prometheus:
    image: prom/prometheus:latest
    container_name: fortune-prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
    networks:
      - fortune-network

  # Grafana仪表盘
  grafana:
    image: grafana/grafana:latest
    container_name: fortune-grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana
    networks:
      - fortune-network
EOF
```

### 6. 维护操作

#### 6.1 应用更新
```bash
# 拉取最新代码
git pull

# 重新构建镜像
docker-compose -f docker-compose.prod.yml build backend

# 滚动更新（无停机）
docker-compose -f docker-compose.prod.yml up -d backend
```

#### 6.2 数据备份
```bash
# 创建备份脚本
cat > backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d_%H%M%S)

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份MySQL数据
docker exec fortune-mysql-prod mysqldump -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} > $BACKUP_DIR/mysql_backup_$DATE.sql

# 备份Redis数据
docker exec fortune-redis-prod redis-cli --rdb /data/dump.rdb
docker cp fortune-redis-prod:/data/dump.rdb $BACKUP_DIR/redis_backup_$DATE.rdb

# 压缩备份文件
tar -czf $BACKUP_DIR/fortune_backup_$DATE.tar.gz $BACKUP_DIR/*_backup_$DATE.*

# 删除7天前的备份文件
find $BACKUP_DIR -name "fortune_backup_*.tar.gz" -mtime +7 -delete

echo "备份完成: $BACKUP_DIR/fortune_backup_$DATE.tar.gz"
EOF

chmod +x backup.sh

# 设置定时备份（每天2点）
echo "0 2 * * * /home/ubuntu/bagua-ai/backup.sh" | crontab -
```

#### 6.3 故障排查
```bash
# 检查容器状态
docker-compose -f docker-compose.prod.yml ps

# 查看容器健康状态
docker inspect fortune-backend-prod | grep Health -A 10

# 进入容器调试
docker exec -it fortune-backend-prod /bin/bash

# 重启单个服务
docker-compose -f docker-compose.prod.yml restart backend

# 查看系统资源
free -h
df -h
top
```

### 7. 安全配置

#### 7.1 防火墙配置
```bash
# 启用ufw防火墙
sudo ufw enable

# 允许必要端口
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8080/tcp

# 检查防火墙状态
sudo ufw status
```

#### 7.2 SSL证书配置（可选）
```bash
# 安装Certbot
sudo apt install certbot python3-certbot-nginx

# 获取SSL证书
sudo certbot --nginx -d yourdomain.com

# 自动续期
echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -
```

### 8. 性能优化

#### 8.1 Docker优化
```bash
# 清理无用镜像和容器
docker system prune -a

# 限制容器资源使用
# 在docker-compose.prod.yml中添加：
deploy:
  resources:
    limits:
      cpus: '1.0'
      memory: 1G
    reservations:
      cpus: '0.5'
      memory: 512M
```

#### 8.2 数据库优化
```bash
# 调整MySQL配置
cat >> mysql/conf.d/custom.cnf << 'EOF'
# 性能优化
innodb_buffer_pool_size=512M
innodb_log_file_size=128M
max_connections=500
query_cache_size=128M
tmp_table_size=64M
max_heap_table_size=64M
EOF
```

## 📊 成功验证

部署完成后，通过以下方式验证服务是否正常运行：

```bash
# 1. 检查所有服务状态
docker-compose -f docker-compose.prod.yml ps

# 2. 测试健康检查接口
curl http://your-server-ip:8080/api/actuator/health

# 3. 测试业务接口
curl -X POST http://your-server-ip:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test"}'

# 4. 检查数据库连接
docker exec fortune-mysql-prod mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} -e "SELECT 1"

# 5. 检查Redis连接
docker exec fortune-redis-prod redis-cli ping
```

## 🔧 故障排查

### 常见问题及解决方案

1. **容器启动失败**
   - 检查环境变量是否正确设置
   - 查看容器日志：`docker logs container-name`
   - 确认端口是否被占用

2. **数据库连接失败**
   - 检查MySQL容器是否正常运行
   - 验证数据库用户名密码
   - 确认网络连接正常

3. **应用性能问题**
   - 监控容器资源使用情况
   - 调整JVM参数
   - 优化数据库查询

## 📝 总结

通过本指南，您已经成功将AI八卦运势小程序部署到腾讯云Docker环境中。部署包含了完整的服务栈（MySQL、Redis、Spring Boot、Nginx），具备生产环境的安全性、可靠性和可维护性。

建议定期进行以下维护工作：
- 监控系统资源使用情况
- 定期备份数据库数据
- 更新安全补丁和应用版本
- 优化性能配置
- 检查日志并处理异常

如有问题，请参考故障排查章节或联系技术支持团队。 