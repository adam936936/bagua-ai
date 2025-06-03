#!/bin/bash

# AI八卦运势小程序 - 腾讯云Docker环境一键部署脚本
# 适用于腾讯云预装Docker的Ubuntu镜像
# 使用方法: sudo ./scripts/deploy-to-tencent-cloud-docker.sh

set -e

# 配置参数
PROJECT_NAME="fortune-mini-app"
PROJECT_DIR="/opt/fortune-app"
BACKUP_DIR="/backup"
LOG_FILE="/tmp/deploy.log"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a $LOG_FILE
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a $LOG_FILE
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a $LOG_FILE
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1" | tee -a $LOG_FILE
}

# 检查root权限
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "请使用 sudo 运行此脚本"
        echo "正确使用方法: sudo $0"
        exit 1
    fi
}

# 获取当前用户（即使在sudo下）
get_real_user() {
    if [ -n "$SUDO_USER" ]; then
        REAL_USER="$SUDO_USER"
    else
        REAL_USER="$(whoami)"
    fi
    log "当前用户: $REAL_USER"
}

# 检查系统环境
check_system() {
    log "检查系统环境..."
    
    # 检查操作系统
    if ! grep -q "Ubuntu" /etc/os-release; then
        error "此脚本仅支持Ubuntu系统"
        exit 1
    fi
    
    # 检查系统版本
    VERSION=$(lsb_release -rs)
    if (( $(echo "$VERSION < 18.04" | bc -l) )); then
        error "需要Ubuntu 18.04或更高版本，当前版本: $VERSION"
        exit 1
    fi
    
    # 检查内存
    MEMORY=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
    if [ "$MEMORY" -lt 2 ]; then
        warn "推荐至少4GB内存，当前: ${MEMORY}GB"
    fi
    
    # 检查磁盘空间
    DISK=$(df -h / | awk 'NR==2{print $4}' | sed 's/G//')
    if [ "${DISK%.*}" -lt 10 ]; then
        error "磁盘空间不足，需要至少10GB可用空间，当前可用: ${DISK}G"
        exit 1
    fi
    
    log "系统检查通过 - Ubuntu $VERSION, 内存: ${MEMORY}GB, 可用磁盘: ${DISK}G"
}

# 检查Docker状态
check_docker() {
    log "检查Docker环境..."
    
    if ! command -v docker &> /dev/null; then
        error "Docker未安装，请使用腾讯云Docker CE镜像"
        exit 1
    fi
    
    # 检查Docker服务状态
    if ! systemctl is-active --quiet docker; then
        log "启动Docker服务..."
        systemctl start docker
        systemctl enable docker
    fi
    
    # 检查Docker版本
    DOCKER_VERSION=$(docker --version)
    log "Docker版本: $DOCKER_VERSION"
    
    # 配置当前用户Docker权限
    if [ -n "$REAL_USER" ] && [ "$REAL_USER" != "root" ]; then
        usermod -aG docker $REAL_USER
        log "已将用户 $REAL_USER 添加到docker组"
    fi
}

# 安装Docker Compose
install_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        log "Docker Compose已安装，版本: $(docker-compose --version)"
        return
    fi
    
    log "安装Docker Compose..."
    
    # 更新包管理器
    apt update
    apt install -y curl wget git vim htop pwgen openssl
    
    # 使用GitHub官方下载地址（最稳定的方式）
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # 验证安装
    if docker-compose --version; then
        log "Docker Compose安装成功"
    else
        error "Docker Compose安装失败"
        exit 1
    fi
}

# 配置Docker镜像加速
configure_docker_registry() {
    log "配置Docker镜像加速..."
    
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json << 'EOF'
{
    "registry-mirrors": [
        "https://mirror.ccs.tencentcloudcr.com",
        "https://ccr.ccs.tencentcloudcr.com"
    ],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m",
        "max-file": "3"
    }
}
EOF
    
    # 重启Docker服务
    systemctl daemon-reload
    systemctl restart docker
    
    log "Docker镜像加速配置完成"
}

# 创建项目目录和下载代码
setup_project() {
    log "设置项目目录..."
    
    # 创建项目目录
    mkdir -p $PROJECT_DIR
    cd $PROJECT_DIR
    
    # 如果目录不为空，先备份
    if [ "$(ls -A $PROJECT_DIR)" ]; then
        warn "项目目录不为空，创建备份..."
        mv $PROJECT_DIR $PROJECT_DIR.backup.$(date +%Y%m%d_%H%M%S)
        mkdir -p $PROJECT_DIR
        cd $PROJECT_DIR
    fi
    
    # 克隆项目（这里需要替换为实际的仓库地址）
    if [ -n "$1" ]; then
        log "从指定仓库克隆项目: $1"
        git clone $1 .
    else
        warn "未指定Git仓库，请手动将项目文件复制到 $PROJECT_DIR"
        warn "或者重新运行脚本并指定仓库地址: sudo $0 <git-repo-url>"
        read -p "按Enter继续（假设项目文件已存在）或Ctrl+C退出..."
    fi
    
    # 设置目录权限
    if [ -n "$REAL_USER" ] && [ "$REAL_USER" != "root" ]; then
        chown -R $REAL_USER:$REAL_USER $PROJECT_DIR
    fi
    
    log "项目目录设置完成: $PROJECT_DIR"
}

# 创建环境配置
create_env_config() {
    log "创建环境配置文件..."
    
    cd $PROJECT_DIR
    
    if [ -f .env ]; then
        warn ".env文件已存在，将备份为.env.backup"
        cp .env .env.backup
    fi
    
    # 生成随机密码
    MYSQL_ROOT_PASSWORD=$(openssl rand -hex 16)
    MYSQL_PASSWORD=$(openssl rand -hex 16)
    REDIS_PASSWORD=$(openssl rand -hex 16)
    JWT_SECRET=$(openssl rand -hex 32)
    
    # 获取服务器公网IP
    SERVER_IP=$(curl -s http://ip.3322.net || echo "localhost")
    
    cat > .env << EOF
# MySQL配置
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_DATABASE=fortune_db
MYSQL_USER=fortune_user
MYSQL_PASSWORD=${MYSQL_PASSWORD}

# Redis配置
REDIS_PASSWORD=${REDIS_PASSWORD}

# API密钥配置（需要手动填写）
DEEPSEEK_API_KEY=your-deepseek-api-key
WECHAT_APP_ID=your-wechat-app-id
WECHAT_APP_SECRET=your-wechat-app-secret

# JWT密钥
JWT_SECRET=${JWT_SECRET}

# 服务器配置
SERVER_HOST=${SERVER_IP}
SSL_ENABLED=false
EOF
    
    # 设置文件权限
    chmod 600 .env
    if [ -n "$REAL_USER" ] && [ "$REAL_USER" != "root" ]; then
        chown $REAL_USER:$REAL_USER .env
    fi
    
    info "环境配置文件已创建: $PROJECT_DIR/.env"
    warn "请手动配置以下参数:"
    warn "- DEEPSEEK_API_KEY"
    warn "- WECHAT_APP_ID"
    warn "- WECHAT_APP_SECRET"
    
    # 显示生成的密码信息
    info "生成的随机密码已保存到.env文件中"
    info "服务器IP: $SERVER_IP"
}

# 创建目录结构
create_directories() {
    log "创建必要目录..."
    
    cd $PROJECT_DIR
    
    mkdir -p mysql/conf.d
    mkdir -p redis
    mkdir -p nginx/logs
    mkdir -p nginx/ssl
    mkdir -p monitoring
    mkdir -p $BACKUP_DIR
    
    # 设置目录权限
    if [ -n "$REAL_USER" ] && [ "$REAL_USER" != "root" ]; then
        chown -R $REAL_USER:$REAL_USER mysql redis nginx monitoring
    fi
    chmod 755 $BACKUP_DIR
    
    log "目录创建完成"
}

# 创建配置文件
create_configs() {
    log "创建配置文件..."
    
    cd $PROJECT_DIR
    
    # MySQL配置
    cat > mysql/conf.d/custom.cnf << 'EOF'
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
    
    # Redis配置
    cat > redis/redis.conf << 'EOF'
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
    
    # Nginx配置
    cat > nginx/nginx.conf << 'EOF'
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
    
    log "配置文件创建完成"
}

# 创建Docker配置文件
create_docker_configs() {
    log "创建Docker配置文件..."
    
    cd $PROJECT_DIR
    
    # 创建生产环境Dockerfile
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

# 设置JVM参数（根据服务器配置调整）
ENV JAVA_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC -XX:+PrintGC -XX:+PrintGCDetails"

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
  CMD curl -f http://localhost:8080/api/actuator/health || exit 1

# 使用dumb-init启动应用
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
EOF
    
    # 创建生产环境docker-compose文件
    cat > docker-compose.prod.yml << 'EOF'
version: '3.8'

services:
  # MySQL数据库
  mysql:
    image: mysql:8.0
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
    image: redis:6.2-alpine
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
    image: nginx:alpine
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
    
    log "Docker配置文件创建完成"
}

# 创建管理脚本
create_management_scripts() {
    log "创建管理脚本..."
    
    cd $PROJECT_DIR
    
    # 创建应用管理脚本
    cat > manage.sh << 'EOF'
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
        sudo ./backup.sh
        ;;
    *)
        echo "使用方法: $0 {start|stop|restart|logs|status|update|backup}"
        exit 1
        ;;
esac
EOF
    
    # 创建数据备份脚本
    cat > backup.sh << 'EOF'
#!/bin/bash

# 加载环境变量
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d_%H%M%S)

# 创建备份目录
mkdir -p $BACKUP_DIR

echo "开始备份数据..."

# 备份MySQL数据
echo "备份MySQL数据库..."
docker exec fortune-mysql-prod mysqldump -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} > ${BACKUP_DIR}/mysql_backup_${DATE}.sql

# 备份Redis数据
echo "备份Redis数据..."
docker exec fortune-redis-prod redis-cli -a ${REDIS_PASSWORD} --rdb /data/dump.rdb
docker cp fortune-redis-prod:/data/dump.rdb ${BACKUP_DIR}/redis_backup_${DATE}.rdb

# 备份配置文件
echo "备份配置文件..."
tar -czf ${BACKUP_DIR}/config_backup_${DATE}.tar.gz .env docker-compose.prod.yml mysql/ redis/ nginx/

# 压缩所有备份文件
echo "压缩备份文件..."
tar -czf ${BACKUP_DIR}/fortune_backup_${DATE}.tar.gz ${BACKUP_DIR}/*_backup_${DATE}.*

# 清理临时文件
rm -f ${BACKUP_DIR}/*_backup_${DATE}.sql ${BACKUP_DIR}/*_backup_${DATE}.rdb ${BACKUP_DIR}/*_backup_${DATE}.tar.gz

# 删除7天前的备份
find ${BACKUP_DIR} -name "fortune_backup_*.tar.gz" -mtime +7 -delete

echo "备份完成: ${BACKUP_DIR}/fortune_backup_${DATE}.tar.gz"
ls -lh ${BACKUP_DIR}/fortune_backup_${DATE}.tar.gz
EOF
    
    # 设置执行权限
    chmod +x manage.sh backup.sh
    
    # 设置文件权限
    if [ -n "$REAL_USER" ] && [ "$REAL_USER" != "root" ]; then
        chown $REAL_USER:$REAL_USER manage.sh backup.sh
    fi
    
    log "管理脚本创建完成"
}

# 配置防火墙
configure_firewall() {
    log "配置防火墙..."
    
    # 启用UFW防火墙
    ufw --force enable
    
    # 允许必要端口
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow 8080/tcp
    
    # 显示防火墙状态
    ufw status verbose
    
    info "防火墙配置完成"
    info "请确保腾讯云安全组也开放了相应端口"
}

# 拉取Docker镜像
pull_docker_images() {
    log "拉取Docker镜像..."
    
    # 拉取所需的基础镜像
    docker pull ccr.ccs.tencentcloudcr.com/public/mysql:8.0
    docker pull ccr.ccs.tencentcloudcr.com/public/redis:6.2-alpine
    docker pull ccr.ccs.tencentcloudcr.com/public/nginx:alpine
    docker pull ccr.ccs.tencentcloudcr.com/public/maven:3.8.6-openjdk-17
    docker pull ccr.ccs.tencentcloudcr.com/public/openjdk:17-jre-slim
    
    log "Docker镜像拉取完成"
}

# 构建和部署应用
deploy_application() {
    log "构建和部署应用..."
    
    cd $PROJECT_DIR
    
    # 检查环境配置
    if grep -q "your-deepseek-api-key" .env; then
        warn "请先配置 DEEPSEEK_API_KEY"
    fi
    
    if grep -q "your-wechat-app-id" .env; then
        warn "请先配置 WECHAT_APP_ID 和 WECHAT_APP_SECRET"
    fi
    
    # 构建后端应用镜像
    log "构建应用镜像..."
    docker-compose -f docker-compose.prod.yml build --no-cache backend
    
    # 启动所有服务
    log "启动服务..."
    docker-compose -f docker-compose.prod.yml up -d
    
    # 等待服务启动
    log "等待服务启动完成..."
    sleep 120
    
    # 检查服务状态
    log "检查服务状态..."
    docker-compose -f docker-compose.prod.yml ps
}

# 验证部署
verify_deployment() {
    log "验证部署..."
    
    cd $PROJECT_DIR
    
    # 检查容器状态
    CONTAINERS="mysql redis backend nginx"
    for container in $CONTAINERS; do
        if ! docker-compose -f docker-compose.prod.yml ps $container | grep -q "Up"; then
            error "容器 $container 未正常启动"
            docker-compose -f docker-compose.prod.yml logs $container
            return 1
        fi
    done
    
    # 等待应用完全启动
    log "等待应用完全启动..."
    sleep 60
    
    # 检查健康状态
    RETRIES=10
    while [ $RETRIES -gt 0 ]; do
        if curl -f http://localhost:8080/api/actuator/health &>/dev/null; then
            log "应用健康检查通过"
            break
        fi
        warn "等待应用启动... (剩余重试次数: $RETRIES)"
        sleep 10
        RETRIES=$((RETRIES-1))
    done
    
    if [ $RETRIES -eq 0 ]; then
        error "应用健康检查失败"
        docker-compose -f docker-compose.prod.yml logs backend
        return 1
    fi
    
    # 显示访问信息
    SERVER_IP=$(curl -s http://ip.3322.net || echo "localhost")
    info "部署验证成功！"
    info "服务器IP: $SERVER_IP"
    info "应用访问地址: http://${SERVER_IP}:8080/api/actuator/health"
    info "Nginx代理地址: http://${SERVER_IP}/health"
    
    return 0
}

# 设置定时任务
setup_cron() {
    log "设置定时备份任务..."
    
    # 添加定时备份任务（每天2点执行）
    (crontab -l 2>/dev/null; echo "0 2 * * * cd $PROJECT_DIR && $PROJECT_DIR/backup.sh >> /var/log/backup.log 2>&1") | crontab -
    
    log "定时备份任务设置完成"
}

# 显示部署完成信息
show_completion_info() {
    log "🎉 部署完成！"
    
    SERVER_IP=$(curl -s http://ip.3322.net || echo "localhost")
    
    echo "==================== 部署完成信息 ===================="
    echo "📁 项目目录: $PROJECT_DIR"
    echo "🌐 服务器IP: $SERVER_IP"
    echo "🔗 应用地址: http://$SERVER_IP:8080/api/actuator/health"
    echo "🔗 Nginx代理: http://$SERVER_IP/health"
    echo ""
    echo "📋 管理命令:"
    echo "  cd $PROJECT_DIR"
    echo "  ./manage.sh status     # 查看状态"
    echo "  ./manage.sh logs       # 查看日志"
    echo "  ./manage.sh restart    # 重启服务"
    echo "  ./manage.sh backup     # 备份数据"
    echo ""
    echo "📖 详细文档: docs/TENCENT_CLOUD_DOCKER_DEPLOYMENT_GUIDE.md"
    echo "=================================================="
}

# 主函数
main() {
    log "🚀 开始腾讯云Docker环境部署..."
    
    # 检查权限和环境
    check_root
    get_real_user
    check_system
    check_docker
    
    # 安装依赖
    install_docker_compose
    configure_docker_registry
    
    # 设置项目
    setup_project "$1"
    create_env_config
    create_directories
    create_configs
    create_docker_configs
    create_management_scripts
    
    # 配置安全
    configure_firewall
    
    # 提示用户配置API密钥
    echo ""
    warn "⚠️  重要：请配置API密钥"
    warn "编辑文件: $PROJECT_DIR/.env"
    warn "配置以下参数:"
    warn "- DEEPSEEK_API_KEY"
    warn "- WECHAT_APP_ID" 
    warn "- WECHAT_APP_SECRET"
    echo ""
    
    # 询问是否继续部署
    while true; do
        read -p "是否已完成API密钥配置？(y/n): " yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) 
                echo "请配置完成后重新运行脚本"
                exit 0
                ;;
            * ) echo "请输入 y 或 n";;
        esac
    done
    
    # 拉取镜像和部署
    pull_docker_images
    deploy_application
    
    # 验证部署
    if verify_deployment; then
        setup_cron
        show_completion_info
    else
        error "❌ 部署验证失败"
        info "查看日志: $LOG_FILE"
        info "查看容器日志: cd $PROJECT_DIR && docker-compose -f docker-compose.prod.yml logs"
        exit 1
    fi
}

# 显示使用帮助
show_help() {
    echo "AI八卦运势小程序 - 腾讯云Docker环境一键部署脚本"
    echo ""
    echo "使用方法:"
    echo "  sudo $0                           # 不指定Git仓库（需手动复制项目文件）"
    echo "  sudo $0 <git-repo-url>           # 指定Git仓库地址"
    echo ""
    echo "示例:"
    echo "  sudo $0 https://github.com/username/bagua-ai.git"
    echo ""
    echo "注意:"
    echo "  - 必须使用 sudo 权限运行"
    echo "  - 适用于腾讯云Docker CE镜像"
    echo "  - 需要手动配置API密钥"
}

# 脚本入口
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# 执行主函数
main "$@" 