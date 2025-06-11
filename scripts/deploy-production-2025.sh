#!/bin/bash

# 🚀 AI八卦运势小程序 - 腾讯云生产环境一键部署脚本 v2025
# 适用于: 腾讯云 Ubuntu 20.04+ Docker环境
# 使用方法: sudo ./scripts/deploy-production-2025.sh

set -e

# ===================== 配置参数 =====================
PROJECT_NAME="bagua-ai"
PROJECT_DIR="/opt/${PROJECT_NAME}"
BACKUP_DIR="/opt/backup"
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
NODE_VERSION="18"
JAVA_VERSION="17"

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
    mkdir -p $LOG_DIR
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

# ===================== 权限检查 =====================
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "此脚本需要root权限运行"
        echo -e "${YELLOW}请使用: sudo $0${NC}"
        exit 1
    fi
}

get_real_user() {
    if [ -n "$SUDO_USER" ]; then
        REAL_USER="$SUDO_USER"
    else
        REAL_USER="$(whoami)"
    fi
    log "当前操作用户: $REAL_USER"
}

# ===================== 系统检查 =====================
check_system() {
    step "检查系统环境"
    
    # 检查Ubuntu版本
    if ! grep -q "Ubuntu" /etc/os-release; then
        error "此脚本仅支持Ubuntu系统"
        exit 1
    fi
    
    VERSION=$(lsb_release -rs)
    MAJOR_VERSION=$(echo $VERSION | cut -d. -f1)
    if [ "$MAJOR_VERSION" -lt 20 ]; then
        error "需要Ubuntu 20.04或更高版本，当前: $VERSION"
        exit 1
    fi
    
    # 检查系统资源
    MEMORY=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
    DISK_AVAIL=$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')
    CPU_CORES=$(nproc)
    
    log "系统信息:"
    log "  - Ubuntu版本: $VERSION"
    log "  - 内存: ${MEMORY}GB"
    log "  - CPU核心: $CPU_CORES"
    log "  - 可用磁盘: ${DISK_AVAIL}GB"
    
    # 资源要求检查
    if [ "$MEMORY" -lt 4 ]; then
        warn "推荐至少4GB内存，当前只有${MEMORY}GB"
    fi
    
    if [ "$DISK_AVAIL" -lt 20 ]; then
        error "磁盘空间不足，需要至少20GB，当前可用: ${DISK_AVAIL}GB"
        exit 1
    fi
    
    success "系统环境检查通过"
}

# ===================== 环境变量配置 =====================
setup_environment() {
    step "配置环境变量"
    
    # 生成随机密码
    MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)
    MYSQL_PASSWORD=$(openssl rand -base64 32)
    REDIS_PASSWORD=$(openssl rand -base64 32)
    JWT_SECRET=$(openssl rand -hex 64)
    
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
ENCRYPTION_KEY=$(openssl rand -hex 32)

# ===================== 微信小程序配置（需要手动设置）=====================
WECHAT_APP_ID=请配置您的微信AppID
WECHAT_APP_SECRET=请配置您的微信AppSecret

# ===================== AI配置（需要手动设置）=====================
DEEPSEEK_API_KEY=请配置您的DeepSeek API Key
DEEPSEEK_API_URL=https://api.deepseek.com/v1/chat/completions
DEEPSEEK_MODEL=deepseek-chat

# ===================== 日志配置 =====================
LOG_LEVEL=info
LOG_DIR=/var/log/bagua-ai
EOF
    
    # 设置文件权限
    chmod 600 $PROJECT_DIR/.env.production
    chown $REAL_USER:$REAL_USER $PROJECT_DIR/.env.production
    
    log "环境配置文件已创建: $PROJECT_DIR/.env.production"
    warn "请编辑环境配置文件，设置微信小程序和AI相关配置"
}

# ===================== Docker环境设置 =====================
setup_docker() {
    step "设置Docker环境"
    
    # 检查Docker是否已安装
    if ! command -v docker &> /dev/null; then
        log "安装Docker..."
        curl -fsSL https://get.docker.com | sh
        systemctl start docker
        systemctl enable docker
    else
        log "Docker已安装: $(docker --version)"
    fi
    
    # 检查Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log "安装Docker Compose..."
        curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    else
        log "Docker Compose已安装: $(docker-compose --version)"
    fi
    
    # 配置Docker镜像加速器
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json << 'EOF'
{
    "registry-mirrors": [
        "https://mirror.ccs.tencentcloudcr.com",
        "https://docker.mirrors.ustc.edu.cn",
        "https://hub-mirror.c.163.com"
    ],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m",
        "max-file": "3"
    },
    "storage-driver": "overlay2"
}
EOF
    
    systemctl daemon-reload
    systemctl restart docker
    
    # 添加用户到docker组
    if [ -n "$REAL_USER" ] && [ "$REAL_USER" != "root" ]; then
        usermod -aG docker $REAL_USER
        log "用户 $REAL_USER 已添加到docker组"
    fi
    
    success "Docker环境设置完成"
}

# ===================== 项目设置 =====================
setup_project() {
    step "设置项目目录"
    
    # 创建项目目录
    mkdir -p $PROJECT_DIR
    mkdir -p $BACKUP_DIR
    
    # 如果有旧的部署，创建备份
    if [ -d "$PROJECT_DIR" ] && [ "$(ls -A $PROJECT_DIR)" ]; then
        BACKUP_NAME="backup-$(date +%Y%m%d_%H%M%S)"
        log "备份现有部署到: $BACKUP_DIR/$BACKUP_NAME"
        cp -r $PROJECT_DIR $BACKUP_DIR/$BACKUP_NAME
    fi
    
    # 设置目录权限
    chown -R $REAL_USER:$REAL_USER $PROJECT_DIR
    chown -R $REAL_USER:$REAL_USER $BACKUP_DIR
    
    log "项目目录设置完成: $PROJECT_DIR"
}

# ===================== Docker Compose配置 =====================
create_docker_compose() {
    step "创建Docker Compose配置"
    
    cat > $PROJECT_DIR/docker-compose.production.yml << 'EOF'
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
    ports:
      - "${MYSQL_PORT}:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      - ./backend/sql:/docker-entrypoint-initdb.d
    networks:
      - bagua-network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10

  # ===================== Redis服务 =====================
  redis:
    image: redis:7-alpine
    container_name: bagua-redis
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD}
    ports:
      - "${REDIS_PORT}:6379"
    volumes:
      - redis_data:/data
    networks:
      - bagua-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      timeout: 10s
      retries: 5

  # ===================== 后端服务 =====================
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: bagua-backend
    restart: unless-stopped
    environment:
      - NODE_ENV=production
      - MYSQL_HOST=mysql
      - MYSQL_PORT=${MYSQL_PORT}
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USERNAME=${MYSQL_USERNAME}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - REDIS_HOST=redis
      - REDIS_PORT=${REDIS_PORT}
      - REDIS_PASSWORD=${REDIS_PASSWORD}
      - JWT_SECRET=${JWT_SECRET}
      - WECHAT_APP_ID=${WECHAT_APP_ID}
      - WECHAT_APP_SECRET=${WECHAT_APP_SECRET}
      - DEEPSEEK_API_KEY=${DEEPSEEK_API_KEY}
    ports:
      - "${APP_PORT}:8080"
    volumes:
      - ./backend/logs:/app/logs
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

  # ===================== 前端服务 =====================
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: bagua-frontend
    restart: unless-stopped
    ports:
      - "${FRONTEND_PORT}:80"
    volumes:
      - ./frontend/dist:/usr/share/nginx/html
    networks:
      - bagua-network
    depends_on:
      - backend

  # ===================== Nginx反向代理 =====================
  nginx:
    image: nginx:alpine
    container_name: bagua-nginx
    restart: unless-stopped
    ports:
      - "${NGINX_HTTP_PORT}:80"
      - "${NGINX_HTTPS_PORT}:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./ssl:/etc/nginx/ssl
      - ./logs/nginx:/var/log/nginx
    networks:
      - bagua-network
    depends_on:
      - backend
      - frontend

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
    
    cat > $PROJECT_DIR/nginx/conf.d/bagua-ai.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    
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
    }
    
    # 静态文件
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
}
EOF
    
    success "Nginx配置已创建"
}

# ===================== 后端Dockerfile =====================
create_backend_dockerfile() {
    step "创建后端Dockerfile"
    
    mkdir -p $PROJECT_DIR/backend
    
    cat > $PROJECT_DIR/backend/Dockerfile << 'EOF'
FROM openjdk:17-jdk-slim

WORKDIR /app

# 安装必要的工具
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 复制应用文件
COPY target/*.jar app.jar

# 创建日志目录
RUN mkdir -p /app/logs

# 暴露端口
EXPOSE 8080

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# 启动应用
ENTRYPOINT ["java", "-jar", "-Dspring.profiles.active=production", "app.jar"]
EOF
    
    success "后端Dockerfile已创建"
}

# ===================== 前端Dockerfile =====================
create_frontend_dockerfile() {
    step "创建前端Dockerfile"
    
    mkdir -p $PROJECT_DIR/frontend
    
    cat > $PROJECT_DIR/frontend/Dockerfile << 'EOF'
# 构建阶段
FROM node:18-alpine AS builder

WORKDIR /app

# 复制package文件
COPY package*.json ./

# 安装依赖
RUN npm ci --only=production

# 复制源代码
COPY . .

# 构建应用
RUN npm run build

# 生产阶段
FROM nginx:alpine

# 复制构建产物
COPY --from=builder /app/dist /usr/share/nginx/html

# 复制nginx配置
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 暴露端口
EXPOSE 80

# 启动nginx
CMD ["nginx", "-g", "daemon off;"]
EOF
    
    cat > $PROJECT_DIR/frontend/nginx.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF
    
    success "前端Dockerfile已创建"
}

# ===================== 部署脚本 =====================
create_deployment_scripts() {
    step "创建部署管理脚本"
    
    # 启动脚本
    cat > $PROJECT_DIR/start.sh << 'EOF'
#!/bin/bash
docker-compose -f docker-compose.production.yml --env-file .env.production up -d
EOF
    
    # 停止脚本
    cat > $PROJECT_DIR/stop.sh << 'EOF'
#!/bin/bash
docker-compose -f docker-compose.production.yml down
EOF
    
    # 重启脚本
    cat > $PROJECT_DIR/restart.sh << 'EOF'
#!/bin/bash
docker-compose -f docker-compose.production.yml down
docker-compose -f docker-compose.production.yml --env-file .env.production up -d
EOF
    
    # 查看日志脚本
    cat > $PROJECT_DIR/logs.sh << 'EOF'
#!/bin/bash
if [ -z "$1" ]; then
    docker-compose -f docker-compose.production.yml logs -f
else
    docker-compose -f docker-compose.production.yml logs -f $1
fi
EOF
    
    # 状态检查脚本
    cat > $PROJECT_DIR/status.sh << 'EOF'
#!/bin/bash
echo "=== 容器状态 ==="
docker-compose -f docker-compose.production.yml ps

echo -e "\n=== 资源使用情况 ==="
docker stats --no-stream

echo -e "\n=== 健康检查 ==="
curl -s http://localhost/health && echo " - Nginx健康检查通过" || echo " - Nginx健康检查失败"
curl -s http://localhost:8080/health && echo " - 后端健康检查通过" || echo " - 后端健康检查失败"
EOF
    
    # 设置执行权限
    chmod +x $PROJECT_DIR/*.sh
    
    success "部署管理脚本已创建"
}

# ===================== 防火墙配置 =====================
configure_firewall() {
    step "配置防火墙"
    
    # 检查ufw是否安装
    if command -v ufw &> /dev/null; then
        log "配置UFW防火墙..."
        
        # 重置防火墙规则
        ufw --force reset
        
        # 设置默认策略
        ufw default deny incoming
        ufw default allow outgoing
        
        # 允许SSH
        ufw allow ssh
        
        # 允许HTTP和HTTPS
        ufw allow 80/tcp
        ufw allow 443/tcp
        
        # 启用防火墙
        ufw --force enable
        
        success "防火墙配置完成"
    else
        warn "UFW防火墙未安装，请手动配置安全组规则"
    fi
}

# ===================== 系统服务配置 =====================
create_systemd_service() {
    step "创建系统服务"
    
    cat > /etc/systemd/system/bagua-ai.service << EOF
[Unit]
Description=Bagua AI Fortune Mini App
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=true
WorkingDirectory=$PROJECT_DIR
ExecStart=/usr/local/bin/docker-compose -f docker-compose.production.yml --env-file .env.production up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.production.yml down
User=$REAL_USER
Group=docker

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable bagua-ai.service
    
    success "系统服务已创建并启用"
}

# ===================== 部署验证 =====================
verify_deployment() {
    step "验证部署状态"
    
    log "等待服务启动..."
    sleep 30
    
    # 检查容器状态
    if docker-compose -f $PROJECT_DIR/docker-compose.production.yml ps | grep -q "Up"; then
        success "容器启动成功"
    else
        error "容器启动失败"
        docker-compose -f $PROJECT_DIR/docker-compose.production.yml logs
        exit 1
    fi
    
    # 健康检查
    if curl -s http://localhost/health > /dev/null; then
        success "应用健康检查通过"
    else
        warn "应用健康检查失败，请检查配置"
    fi
    
    # 显示部署信息
    echo -e "\n${CYAN}=== 部署完成 ===${NC}"
    echo -e "${GREEN}项目目录:${NC} $PROJECT_DIR"
    echo -e "${GREEN}访问地址:${NC} http://$(curl -s ifconfig.me)"
    echo -e "${GREEN}管理脚本:${NC}"
    echo -e "  启动服务: $PROJECT_DIR/start.sh"
    echo -e "  停止服务: $PROJECT_DIR/stop.sh"
    echo -e "  重启服务: $PROJECT_DIR/restart.sh"
    echo -e "  查看日志: $PROJECT_DIR/logs.sh"
    echo -e "  检查状态: $PROJECT_DIR/status.sh"
    echo -e "\n${YELLOW}请编辑 $PROJECT_DIR/.env.production 配置微信小程序和AI相关参数${NC}"
}

# ===================== 主函数 =====================
main() {
    echo -e "${CYAN}"
    echo "=================================="
    echo "  AI八卦运势小程序 - 生产环境部署"
    echo "  腾讯云 Ubuntu Docker 环境"
    echo "  Version: 2025.1"
    echo "=================================="
    echo -e "${NC}\n"
    
    setup_logging
    check_root
    get_real_user
    check_system
    setup_docker
    setup_project
    setup_environment
    create_docker_compose
    create_nginx_config
    create_backend_dockerfile
    create_frontend_dockerfile
    create_deployment_scripts
    configure_firewall
    create_systemd_service
    
    log "开始部署服务..."
    cd $PROJECT_DIR
    docker-compose -f docker-compose.production.yml --env-file .env.production up -d
    
    verify_deployment
    
    success "🎉 部署完成！"
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 