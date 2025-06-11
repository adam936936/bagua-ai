#!/bin/bash

# 🚀 AI八卦运势小程序 - 腾讯云Docker环境一键部署脚本 v2025
# 适用于: 腾讯云Docker环境(轻量应用服务器/容器实例)
# 前提: Docker环境已预装
# 使用方法: ./scripts/deploy-tencent-docker-2025.sh

set -e

# ===================== 配置参数 =====================
PROJECT_NAME="bagua-ai"
PROJECT_DIR="/app/${PROJECT_NAME}"
BACKUP_DIR="/backup"
LOG_DIR="/var/log/${PROJECT_NAME}"
LOG_FILE="${LOG_DIR}/deploy.log"

# 网络配置
APP_PORT="8080"
FRONTEND_PORT="3000"
DB_PORT="3306"
REDIS_PORT="6379"
NGINX_HTTP_PORT="80"
NGINX_HTTPS_PORT="443"

# 版本配置
DOCKER_COMPOSE_VERSION="2.24.1"

# ===================== 颜色输出 =====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# ===================== 日志函数 =====================
setup_logging() {
    if [ "$DRY_RUN" == "true" ]; then
        # 测试模式使用当前目录
        LOG_DIR="./logs"
        mkdir -p $LOG_DIR
        LOG_FILE="${LOG_DIR}/deploy_test.log"
    else
        # 实际部署模式使用系统日志目录
        mkdir -p $LOG_DIR
    fi
    
    exec 1> >(tee -a $LOG_FILE)
    exec 2> >(tee -a $LOG_FILE >&2)
}

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARN:${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS:${NC} $1"
}

step() {
    echo -e "\n${PURPLE}========================${NC}"
    echo -e "${PURPLE} $1${NC}"
    echo -e "${PURPLE}========================${NC}\n"
}

# ===================== 环境检查 =====================
check_docker_environment() {
    step "检查腾讯云Docker环境"
    
    # 检查Docker是否可用
    if ! command -v docker &> /dev/null; then
        error "Docker未找到！请确认您使用的是腾讯云Docker环境"
        exit 1
    fi
    
    # 检查Docker服务状态
    if ! docker info &> /dev/null; then
        error "Docker服务未运行，尝试启动..."
        sudo systemctl start docker || service docker start
        sleep 5
        if ! docker info &> /dev/null; then
            error "Docker服务启动失败"
            exit 1
        fi
    fi
    
    # 检查Docker版本
    DOCKER_VERSION=$(docker --version)
    log "Docker版本: $DOCKER_VERSION"
    
    # 检查Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log "安装Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    else
        log "Docker Compose已安装: $(docker-compose --version)"
    fi
    
    # 检查系统资源
    MEMORY=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
    DISK_AVAIL=$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')
    CPU_CORES=$(nproc)
    
    log "系统资源:"
    log "  - 内存: ${MEMORY}GB"
    log "  - CPU核心: $CPU_CORES"
    log "  - 可用磁盘: ${DISK_AVAIL}GB"
    
    # 资源检查
    if [ "$MEMORY" -lt 2 ]; then
        warn "内存较少(${MEMORY}GB)，建议至少2GB"
    fi
    
    if [ "$DISK_AVAIL" -lt 10 ]; then
        error "磁盘空间不足(${DISK_AVAIL}GB)，需要至少10GB"
        exit 1
    fi
    
    success "腾讯云Docker环境检查通过"
}

# ===================== 获取用户信息 =====================
get_current_user() {
    if [ -n "$SUDO_USER" ]; then
        REAL_USER="$SUDO_USER"
    else
        REAL_USER="$(whoami)"
    fi
    log "当前用户: $REAL_USER"
}

# ===================== 网络配置检查 =====================
check_network() {
    step "检查网络配置"
    
    # 检查端口占用
    check_port() {
        local port=$1
        local service=$2
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            warn "端口 $port 已被占用，可能影响 $service 服务"
            netstat -tuln | grep ":$port "
        else
            log "端口 $port 可用 ($service)"
        fi
    }
    
    check_port $NGINX_HTTP_PORT "HTTP"
    check_port $NGINX_HTTPS_PORT "HTTPS"
    check_port $APP_PORT "后端API"
    check_port $DB_PORT "MySQL"
    check_port $REDIS_PORT "Redis"
    
    # 检查外网连接
    if ping -c 1 8.8.8.8 &> /dev/null; then
        log "外网连接正常"
    else
        warn "外网连接可能有问题，可能影响镜像下载"
    fi
    
    success "网络配置检查完成"
}

# ===================== 项目设置 =====================
setup_project() {
    step "设置项目环境"
    
    # 创建项目目录
    sudo mkdir -p $PROJECT_DIR
    sudo mkdir -p $BACKUP_DIR
    sudo mkdir -p $LOG_DIR
    
    # 如果项目目录已存在，创建备份
    if [ -d "$PROJECT_DIR" ] && [ "$(ls -A $PROJECT_DIR 2>/dev/null)" ]; then
        BACKUP_NAME="backup-$(date +%Y%m%d_%H%M%S)"
        log "备份现有部署到: $BACKUP_DIR/$BACKUP_NAME"
        sudo cp -r $PROJECT_DIR $BACKUP_DIR/$BACKUP_NAME
        sudo rm -rf $PROJECT_DIR/*
    fi
    
    # 复制项目文件到目标目录
    if [ -f "$(pwd)/package.json" ] || [ -f "$(pwd)/pom.xml" ]; then
        log "复制项目文件到 $PROJECT_DIR"
        sudo cp -r $(pwd)/* $PROJECT_DIR/
    else
        log "当前目录非项目根目录，请确保在正确位置运行脚本"
    fi
    
    # 设置目录权限
    sudo chown -R $REAL_USER:$REAL_USER $PROJECT_DIR 2>/dev/null || true
    sudo chown -R $REAL_USER:$REAL_USER $BACKUP_DIR 2>/dev/null || true
    sudo chmod -R 755 $PROJECT_DIR
    
    success "项目目录设置完成: $PROJECT_DIR"
}

# ===================== 环境变量配置 =====================
setup_environment() {
    step "配置环境变量"
    
    # 生成安全密码
    MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)
    MYSQL_PASSWORD=$(openssl rand -base64 32)
    REDIS_PASSWORD=$(openssl rand -base64 32)
    JWT_SECRET=$(openssl rand -hex 64)
    ENCRYPTION_KEY=$(openssl rand -hex 32)
    
    # 创建环境配置文件
    cat > $PROJECT_DIR/.env.production << EOF
# ===================== 应用配置 =====================
NODE_ENV=production
APP_PORT=$APP_PORT
FRONTEND_PORT=$FRONTEND_PORT

# ===================== 数据库配置 =====================
MYSQL_HOST=mysql
MYSQL_PORT=$DB_PORT
MYSQL_DATABASE=bagua_fortune
MYSQL_USERNAME=bagua_user
MYSQL_PASSWORD=$MYSQL_PASSWORD
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD

# ===================== Redis配置 =====================
REDIS_HOST=redis
REDIS_PORT=$REDIS_PORT
REDIS_PASSWORD=$REDIS_PASSWORD

# ===================== 安全配置 =====================
JWT_SECRET=$JWT_SECRET
ENCRYPTION_KEY=$ENCRYPTION_KEY

# ===================== 微信小程序配置（需要手动设置）=====================
WECHAT_APP_ID=请配置您的微信AppID
WECHAT_APP_SECRET=请配置您的微信AppSecret

# ===================== AI配置（需要手动设置）=====================
DEEPSEEK_API_KEY=请配置您的DeepSeek API Key
DEEPSEEK_API_URL=https://api.deepseek.com/v1/chat/completions
DEEPSEEK_MODEL=deepseek-chat

# ===================== 日志配置 =====================
LOG_LEVEL=info
LOG_DIR=$LOG_DIR

# ===================== 腾讯云Docker环境配置 =====================
DOCKER_REGISTRY_MIRROR=mirror.ccs.tencentcloudcr.com
EOF
    
    # 设置文件权限
    chmod 600 $PROJECT_DIR/.env.production
    
    log "环境配置文件已创建: $PROJECT_DIR/.env.production"
    warn "请编辑环境配置文件，设置微信小程序和AI相关配置"
    
    # 创建密码备份文件
    cat > $PROJECT_DIR/.passwords.backup << EOF
# 数据库密码备份 - 请妥善保管
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
MYSQL_PASSWORD=$MYSQL_PASSWORD
REDIS_PASSWORD=$REDIS_PASSWORD
JWT_SECRET=$JWT_SECRET
ENCRYPTION_KEY=$ENCRYPTION_KEY
EOF
    chmod 600 $PROJECT_DIR/.passwords.backup
    log "密码备份文件已创建: $PROJECT_DIR/.passwords.backup"
}

# ===================== Docker配置优化 =====================
optimize_docker() {
    step "优化Docker配置"
    
    # 检查Docker配置目录
    sudo mkdir -p /etc/docker
    
    # 优化Docker配置（针对腾讯云环境）
    cat << 'EOF' | sudo tee /etc/docker/daemon.json > /dev/null
{
    "registry-mirrors": [
        "https://mirror.ccs.tencentcloudcr.com",
        "https://ccr.ccs.tencentcloudcr.com"
    ],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m",
        "max-file": "3"
    },
    "storage-driver": "overlay2",
    "max-concurrent-downloads": 10,
    "max-concurrent-uploads": 5
}
EOF
    
    # 重启Docker服务
    sudo systemctl restart docker 2>/dev/null || sudo service docker restart
    sleep 5
    
    # 验证Docker配置
    if docker info | grep -q "Registry Mirrors"; then
        success "Docker镜像加速配置成功"
    else
        warn "Docker镜像加速配置可能未生效"
    fi
}

# ===================== Docker Compose配置 =====================
create_docker_compose() {
    step "创建Docker Compose配置"
    
    cat > $PROJECT_DIR/docker-compose.yml << 'EOF'
version: '3.8'

services:
  # ===================== 数据库服务 =====================
  mysql:
    image: mysql:8.0
    container_name: bagua-mysql
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USERNAME}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
      TZ: Asia/Shanghai
    ports:
      - "${MYSQL_PORT}:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      - ./sql:/docker-entrypoint-initdb.d:ro
    networks:
      - bagua-network
    command: --default-authentication-plugin=mysql_native_password
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10
      interval: 30s

  # ===================== Redis服务 =====================
  redis:
    image: redis:7-alpine
    container_name: bagua-redis
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD} --appendonly yes
    environment:
      TZ: Asia/Shanghai
    ports:
      - "${REDIS_PORT}:6379"
    volumes:
      - redis_data:/data
    networks:
      - bagua-network
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      timeout: 10s
      retries: 5
      interval: 30s

  # ===================== 后端服务 =====================
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: bagua-backend
    restart: unless-stopped
    environment:
      - NODE_ENV=production
      - TZ=Asia/Shanghai
      - MYSQL_HOST=mysql
      - MYSQL_PORT=${MYSQL_PORT}
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USERNAME=${MYSQL_USERNAME}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - REDIS_HOST=redis
      - REDIS_PORT=${REDIS_PORT}
      - REDIS_PASSWORD=${REDIS_PASSWORD}
      - JWT_SECRET=${JWT_SECRET}
      - ENCRYPTION_KEY=${ENCRYPTION_KEY}
      - WECHAT_APP_ID=${WECHAT_APP_ID}
      - WECHAT_APP_SECRET=${WECHAT_APP_SECRET}
      - DEEPSEEK_API_KEY=${DEEPSEEK_API_KEY}
      - DEEPSEEK_API_URL=${DEEPSEEK_API_URL}
      - DEEPSEEK_MODEL=${DEEPSEEK_MODEL}
    ports:
      - "${APP_PORT}:8080"
    volumes:
      - ./logs:/app/logs
    networks:
      - bagua-network
    depends_on:
      mysql:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  # ===================== 前端服务 =====================
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: bagua-frontend
    restart: unless-stopped
    environment:
      TZ: Asia/Shanghai
    ports:
      - "${FRONTEND_PORT}:80"
    networks:
      - bagua-network
    depends_on:
      - backend

  # ===================== Nginx反向代理 =====================
  nginx:
    image: nginx:alpine
    container_name: bagua-nginx
    restart: unless-stopped
    environment:
      TZ: Asia/Shanghai
    ports:
      - "${NGINX_HTTP_PORT}:80"
      - "${NGINX_HTTPS_PORT}:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      - ./logs/nginx:/var/log/nginx
    networks:
      - bagua-network
    depends_on:
      - backend
      - frontend
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/health"]
      timeout: 10s
      retries: 3
      interval: 30s

# ===================== 数据卷 =====================
volumes:
  mysql_data:
    driver: local
  redis_data:
    driver: local

# ===================== 网络 =====================
networks:
  bagua-network:
    driver: bridge
EOF
    
    success "Docker Compose配置已创建"
}

# ===================== Nginx配置 =====================
create_nginx_config() {
    step "创建Nginx配置"
    
    mkdir -p $PROJECT_DIR/nginx/conf.d
    mkdir -p $PROJECT_DIR/nginx/ssl
    mkdir -p $PROJECT_DIR/logs/nginx
    
    # 主配置文件
    cat > $PROJECT_DIR/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
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
    
    # 基本设置
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 100M;
    server_tokens off;
    
    # Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
    
    # 包含站点配置
    include /etc/nginx/conf.d/*.conf;
}
EOF
    
    # 站点配置文件
    cat > $PROJECT_DIR/nginx/conf.d/bagua-ai.conf << 'EOF'
server {
    listen 80;
    server_name _;
    
    # 安全头部
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    # 后端API代理
    location /api/ {
        proxy_pass http://backend:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # 缓冲设置
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }
    
    # 静态文件代理
    location / {
        proxy_pass http://frontend:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # 健康检查
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    # 阻止访问敏感文件
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF
    
    success "Nginx配置已创建"
}

# ===================== 管理脚本 =====================
create_management_scripts() {
    step "创建管理脚本"
    
    # 启动脚本
    cat > $PROJECT_DIR/start.sh << 'EOF'
#!/bin/bash
echo "🚀 启动AI八卦运势小程序..."
docker-compose --env-file .env.production up -d
echo "✅ 启动完成！访问地址: http://$(curl -s ifconfig.me 2>/dev/null || echo 'localhost')"
EOF
    
    # 停止脚本
    cat > $PROJECT_DIR/stop.sh << 'EOF'
#!/bin/bash
echo "🛑 停止AI八卦运势小程序..."
docker-compose down
echo "✅ 服务已停止"
EOF
    
    # 重启脚本
    cat > $PROJECT_DIR/restart.sh << 'EOF'
#!/bin/bash
echo "🔄 重启AI八卦运势小程序..."
docker-compose down
docker-compose --env-file .env.production up -d
echo "✅ 重启完成！"
EOF
    
    # 日志查看脚本
    cat > $PROJECT_DIR/logs.sh << 'EOF'
#!/bin/bash
if [ -z "$1" ]; then
    echo "📋 查看所有服务日志..."
    docker-compose logs -f --tail=100
else
    echo "📋 查看 $1 服务日志..."
    docker-compose logs -f --tail=100 $1
fi
EOF
    
    # 状态检查脚本
    cat > $PROJECT_DIR/status.sh << 'EOF'
#!/bin/bash
echo "🔍 检查服务状态..."
echo ""
echo "=== 容器状态 ==="
docker-compose ps
echo ""
echo "=== 健康检查 ==="
curl -s http://localhost/health >/dev/null && echo "✅ Nginx: 健康" || echo "❌ Nginx: 异常"
curl -s http://localhost:8080/health >/dev/null && echo "✅ 后端: 健康" || echo "❌ 后端: 异常"
echo ""
echo "=== 资源使用 ==="
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
EOF
    
    # 更新脚本
    cat > $PROJECT_DIR/update.sh << 'EOF'
#!/bin/bash
echo "🔄 更新应用..."
git pull
docker-compose build --no-cache
docker-compose down
docker-compose --env-file .env.production up -d
echo "✅ 更新完成！"
EOF
    
    # 备份脚本
    cat > $PROJECT_DIR/backup.sh << 'EOF'
#!/bin/bash
BACKUP_NAME="backup-$(date +%Y%m%d_%H%M%S)"
echo "💾 创建备份: $BACKUP_NAME"
mkdir -p /backup
docker exec bagua-mysql mysqldump -u root -p${MYSQL_ROOT_PASSWORD} bagua_fortune > /backup/${BACKUP_NAME}_mysql.sql
tar -czf /backup/${BACKUP_NAME}_app.tar.gz /app/bagua-ai --exclude=/app/bagua-ai/logs
echo "✅ 备份完成: /backup/${BACKUP_NAME}"
EOF
    
    # 设置执行权限
    chmod +x $PROJECT_DIR/*.sh
    
    success "管理脚本已创建"
}

# ===================== 预拉取镜像 =====================
pull_images() {
    step "预拉取Docker镜像"
    
    log "拉取基础镜像..."
    docker pull mysql:8.0
    docker pull redis:7-alpine  
    docker pull nginx:alpine
    docker pull node:18-alpine
    docker pull openjdk:17-jdk-slim
    
    success "镜像拉取完成"
}

# ===================== 部署应用 =====================
deploy_application() {
    step "部署应用"
    
    cd $PROJECT_DIR
    
    log "构建并启动服务..."
    docker-compose --env-file .env.production up -d --build
    
    log "等待服务启动..."
    sleep 30
    
    # 健康检查
    local max_attempts=12
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log "健康检查 (${attempt}/${max_attempts})..."
        
        if curl -sf http://localhost/health >/dev/null 2>&1; then
            success "应用部署成功！"
            return 0
        fi
        
        log "等待服务启动... (${attempt}/${max_attempts})"
        sleep 10
        ((attempt++))
    done
    
    error "应用启动超时，请检查日志"
    docker-compose logs
    return 1
}

# ===================== 显示部署信息 =====================
show_deployment_info() {
    step "部署完成"
    
    # 获取外网IP
    PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "localhost")
    
    echo -e "${CYAN}🎉 AI八卦运势小程序部署成功！${NC}\n"
    
    echo -e "${GREEN}📍 访问信息:${NC}"
    echo -e "  🌐 应用地址: http://${PUBLIC_IP}"
    echo -e "  📊 管理地址: http://${PUBLIC_IP}:${APP_PORT}/health"
    
    echo -e "\n${GREEN}📁 项目目录:${NC} $PROJECT_DIR"
    
    echo -e "\n${GREEN}🛠️ 管理命令:${NC}"
    echo -e "  启动服务: cd $PROJECT_DIR && ./start.sh"
    echo -e "  停止服务: cd $PROJECT_DIR && ./stop.sh"
    echo -e "  重启服务: cd $PROJECT_DIR && ./restart.sh"
    echo -e "  查看日志: cd $PROJECT_DIR && ./logs.sh"
    echo -e "  检查状态: cd $PROJECT_DIR && ./status.sh"
    echo -e "  应用更新: cd $PROJECT_DIR && ./update.sh"
    echo -e "  数据备份: cd $PROJECT_DIR && ./backup.sh"
    
    echo -e "\n${YELLOW}⚠️ 重要提醒:${NC}"
    echo -e "  1. 请编辑配置文件: $PROJECT_DIR/.env.production"
    echo -e "  2. 设置微信小程序AppID和AppSecret"
    echo -e "  3. 配置DeepSeek API Key"
    echo -e "  4. 密码备份文件: $PROJECT_DIR/.passwords.backup"
    
    echo -e "\n${GREEN}📋 服务状态:${NC}"
    cd $PROJECT_DIR && ./status.sh
}

# ===================== 数据库初始化脚本 =====================
create_database_init_scripts() {
    step "创建数据库初始化脚本"
    
    # 创建SQL目录
    mkdir -p $PROJECT_DIR/sql
    
    # 复制数据库初始化脚本
    if [ -f "$(pwd)/complete-database-init.sql" ]; then
        log "复制数据库初始化脚本"
        cp $(pwd)/complete-database-init.sql $PROJECT_DIR/sql/01-init-schema.sql
        chmod 644 $PROJECT_DIR/sql/01-init-schema.sql
    else
        warn "未找到数据库初始化脚本，将创建基本结构"
        
        # 创建基本数据库初始化脚本
        cat > $PROJECT_DIR/sql/01-init-schema.sql << 'EOF'
-- 八卦AI项目数据库初始化脚本
-- 执行时间: $(date +%Y-%m-%d)
-- 数据库: MySQL 8.0+

-- 创建数据库
CREATE DATABASE IF NOT EXISTS `fortune_db` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE `fortune_db`;

-- 用户表
CREATE TABLE IF NOT EXISTS `t_users` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '用户ID',
    `openid` VARCHAR(100) UNIQUE NOT NULL COMMENT '微信openid',
    `nickname` VARCHAR(50) COMMENT '昵称',
    `avatar_url` VARCHAR(255) COMMENT '头像URL',
    `phone` VARCHAR(20) COMMENT '手机号',
    `vip_level` INT DEFAULT 0 COMMENT 'VIP等级：0-普通用户，1-月度VIP，2-年度VIP',
    `vip_expire_time` DATETIME COMMENT 'VIP过期时间',
    `created_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted` TINYINT DEFAULT 0 COMMENT '删除标记：0-未删除，1-已删除',
    INDEX idx_openid (openid),
    INDEX idx_created_time (created_time),
    INDEX idx_vip_level (vip_level)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- 命理记录表
CREATE TABLE IF NOT EXISTS `t_fortune_record` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '记录ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `name` VARCHAR(50) NOT NULL COMMENT '姓名',
    `gender` TINYINT NOT NULL COMMENT '性别：1-男，2-女',
    `birth_year` INT NOT NULL COMMENT '出生年',
    `birth_month` INT NOT NULL COMMENT '出生月',
    `birth_day` INT NOT NULL COMMENT '出生日',
    `birth_hour` INT COMMENT '出生时辰',
    `lunar_year` INT COMMENT '农历年',
    `lunar_month` INT COMMENT '农历月',
    `lunar_day` INT COMMENT '农历日',
    `gan_zhi` VARCHAR(20) COMMENT '干支',
    `sheng_xiao` VARCHAR(10) COMMENT '生肖',
    `wu_xing_analysis` TEXT COMMENT '五行分析',
    `ai_analysis` TEXT COMMENT 'AI分析结果',
    `name_analysis` TEXT COMMENT '姓名分析结果',
    `name_recommendations` JSON COMMENT 'AI推荐姓名',
    `created_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted` TINYINT DEFAULT 0 COMMENT '删除标记：0-未删除，1-已删除',
    INDEX idx_user_id (user_id),
    INDEX idx_created_time (created_time),
    INDEX idx_birth_date (birth_year, birth_month, birth_day),
    INDEX idx_user_time (user_id, created_time DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='命理记录表';

-- 插入测试用户
INSERT IGNORE INTO `t_users` (`openid`, `nickname`, `avatar_url`, `vip_level`) VALUES 
('test_openid_001', '测试用户1', 'https://example.com/avatar1.jpg', 0);

-- 检查表是否创建成功
SHOW TABLES;
EOF
    fi
    
    # 创建数据库检查脚本
    cat > $PROJECT_DIR/sql/02-check-schema.sql << 'EOF'
-- 检查数据库表是否存在
SELECT 
    table_name, 
    table_rows,
    CONCAT(ROUND(data_length / (1024 * 1024), 2), ' MB') as data_size,
    CONCAT(ROUND(index_length / (1024 * 1024), 2), ' MB') as index_size
FROM 
    information_schema.TABLES 
WHERE 
    table_schema = 'fortune_db';
EOF
    
    success "数据库初始化脚本已创建"
}

# ===================== 主函数 =====================
main() {
    echo -e "${CYAN}"
    echo -e "   █████╗ ██╗      ██████╗ █████╗  ██████╗ ██╗   ██╗ █████╗     █████╗ ██╗"
    echo -e "  ██╔══██╗██║     ██╔════╝██╔══██╗██╔════╝ ██║   ██║██╔══██╗   ██╔══██╗██║"
    echo -e "  ███████║██║     ██║     ███████║██║  ███╗██║   ██║███████║   ███████║██║"
    echo -e "  ██╔══██║██║     ██║     ██╔══██║██║   ██║██║   ██║██╔══██║   ██╔══██║██║"
    echo -e "  ██║  ██║███████╗╚██████╗██║  ██║╚██████╔╝╚██████╔╝██║  ██║   ██║  ██║██║"
    echo -e "  ╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝   ╚═╝  ╚═╝╚═╝"
    echo -e "${NC}"
    echo -e "  🚀 腾讯云Docker环境一键部署脚本 v2025\n"

    # 参数解析
    DRY_RUN=false
    while getopts "hn" opt; do
        case $opt in
            h)
                show_help
                exit 0
                ;;
            n)
                DRY_RUN=true
                warn "仅执行检查，不进行实际部署"
                ;;
            *)
                error "未知参数: -$OPTARG"
                show_help
                exit 1
                ;;
        esac
    done

    # 设置错误处理
    trap 'error "脚本执行失败，查看日志了解详情: $LOG_FILE"; exit 1' ERR

    # 启动日志
    setup_logging
    log "开始部署AI八卦运势小程序到腾讯云Docker环境..."
    log "当前目录: $(pwd)"
    log "部署模式: $([ "$DRY_RUN" == "true" ] && echo "测试模式" || echo "实际部署")"

    # 获取当前用户
    get_current_user

    # 检查环境
    check_docker_environment
    check_network

    # 如果是测试模式，不进行实际部署
    if [ "$DRY_RUN" == "true" ]; then
        success "测试模式检查完成"
        exit 0
    fi

    # 设置项目环境
    setup_project
    setup_environment
    
    # 创建数据库初始化脚本
    create_database_init_scripts
    
    # 创建配置文件
    optimize_docker
    create_docker_compose
    create_nginx_config
    create_management_scripts

    # 预拉取镜像
    pull_images

    # 部署应用
    deploy_application
    show_deployment_info

    success "部署完成!"
    exit 0
}

# 错误处理
trap 'error "部署过程中发生错误，请检查日志: $LOG_FILE"' ERR

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 