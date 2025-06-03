#!/bin/bash

# AI八卦运势小程序 - 腾讯云一键部署脚本
# 使用方法: ./scripts/deploy-to-tencent-cloud.sh

set -e

# 配置参数
PROJECT_NAME="fortune-mini-app"
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

# 检查是否为root用户
check_user() {
    if [ "$EUID" -eq 0 ]; then
        error "请不要以root用户运行此脚本"
        exit 1
    fi
}

# 检查系统要求
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
        error "需要Ubuntu 18.04或更高版本"
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
        error "磁盘空间不足，需要至少10GB可用空间"
        exit 1
    fi
    
    log "系统检查通过"
}

# 安装Docker
install_docker() {
    if command -v docker &> /dev/null; then
        log "Docker已安装，版本: $(docker --version)"
        return
    fi
    
    log "安装Docker..."
    
    # 更新系统
    sudo apt update
    sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # 添加Docker GPG密钥
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # 添加Docker仓库
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # 安装Docker
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    
    # 配置用户权限
    sudo usermod -aG docker $USER
    
    log "Docker安装完成"
}

# 安装Docker Compose
install_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        log "Docker Compose已安装，版本: $(docker-compose --version)"
        return
    fi
    
    log "安装Docker Compose..."
    
    # 下载Docker Compose
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4)
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    # 设置执行权限
    sudo chmod +x /usr/local/bin/docker-compose
    
    log "Docker Compose安装完成"
}

# 创建环境配置
create_env_config() {
    log "创建环境配置文件..."
    
    if [ -f .env ]; then
        warn ".env文件已存在，将备份为.env.backup"
        cp .env .env.backup
    fi
    
    # 生成随机密码
    MYSQL_ROOT_PASSWORD=$(openssl rand -hex 16)
    MYSQL_PASSWORD=$(openssl rand -hex 16)
    REDIS_PASSWORD=$(openssl rand -hex 16)
    JWT_SECRET=$(openssl rand -hex 32)
    
    cat > .env << EOF
# MySQL配置
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_DATABASE=fortune_db
MYSQL_USER=fortune_user
MYSQL_PASSWORD=${MYSQL_PASSWORD}

# Redis配置
REDIS_PASSWORD=${REDIS_PASSWORD}

# API密钥配置（需要手动配置）
DEEPSEEK_API_KEY=your-deepseek-api-key
WECHAT_APP_ID=your-wechat-app-id
WECHAT_APP_SECRET=your-wechat-app-secret

# JWT密钥
JWT_SECRET=${JWT_SECRET}

# 服务器配置
SERVER_HOST=$(curl -s http://checkip.amazonaws.com)
SSL_ENABLED=false
EOF
    
    chmod 600 .env
    
    info "环境配置文件已创建: .env"
    warn "请手动配置以下参数:"
    warn "- DEEPSEEK_API_KEY"
    warn "- WECHAT_APP_ID"
    warn "- WECHAT_APP_SECRET"
}

# 创建目录结构
create_directories() {
    log "创建必要目录..."
    
    mkdir -p mysql/conf.d
    mkdir -p redis
    mkdir -p nginx/logs
    mkdir -p nginx/ssl
    mkdir -p monitoring
    mkdir -p $BACKUP_DIR
    
    log "目录创建完成"
}

# 创建配置文件
create_configs() {
    log "创建配置文件..."
    
    # MySQL配置
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
    
    # Redis配置
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
    
    # Nginx配置
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

        # 静态文件
        location / {
            root /usr/share/nginx/html;
            index index.html;
            try_files $uri $uri/ /index.html;
        }
    }
}
EOF
    
    log "配置文件创建完成"
}

# 创建备份脚本
create_backup_script() {
    log "创建备份脚本..."
    
    cat > backup.sh << 'EOF'
#!/bin/bash

# 数据备份脚本
source .env

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

# 删除原始备份文件
rm -f $BACKUP_DIR/*_backup_$DATE.sql $BACKUP_DIR/*_backup_$DATE.rdb

# 删除7天前的备份文件
find $BACKUP_DIR -name "fortune_backup_*.tar.gz" -mtime +7 -delete

echo "备份完成: $BACKUP_DIR/fortune_backup_$DATE.tar.gz"
EOF
    
    chmod +x backup.sh
    
    log "备份脚本创建完成"
}

# 构建和部署应用
deploy_application() {
    log "构建和部署应用..."
    
    # 检查Docker服务
    if ! systemctl is-active --quiet docker; then
        sudo systemctl start docker
        sudo systemctl enable docker
    fi
    
    # 构建镜像
    log "构建Docker镜像..."
    docker-compose -f docker-compose.prod.yml build --no-cache
    
    # 启动服务
    log "启动服务..."
    docker-compose -f docker-compose.prod.yml up -d
    
    # 等待服务启动
    log "等待服务启动..."
    sleep 60
    
    # 检查服务状态
    log "检查服务状态..."
    docker-compose -f docker-compose.prod.yml ps
}

# 验证部署
verify_deployment() {
    log "验证部署..."
    
    # 检查容器状态
    CONTAINERS=$(docker-compose -f docker-compose.prod.yml ps --services)
    for container in $CONTAINERS; do
        if ! docker-compose -f docker-compose.prod.yml ps $container | grep -q "Up"; then
            error "容器 $container 未正常启动"
            return 1
        fi
    done
    
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
        return 1
    fi
    
    # 显示访问信息
    SERVER_IP=$(curl -s http://checkip.amazonaws.com)
    info "部署完成！"
    info "应用访问地址: http://${SERVER_IP}:8080"
    info "健康检查地址: http://${SERVER_IP}:8080/api/actuator/health"
    info "Nginx代理地址: http://${SERVER_IP}/api/actuator/health"
}

# 设置定时任务
setup_cron() {
    log "设置定时备份任务..."
    
    # 添加定时备份任务（每天2点执行）
    (crontab -l 2>/dev/null; echo "0 2 * * * cd $(pwd) && ./backup.sh >> /var/log/backup.log 2>&1") | crontab -
    
    log "定时备份任务设置完成"
}

# 主函数
main() {
    log "开始腾讯云Docker部署..."
    
    # 检查用户权限
    check_user
    
    # 检查系统环境
    check_system
    
    # 安装依赖
    install_docker
    install_docker_compose
    
    # 创建配置
    create_env_config
    create_directories
    create_configs
    create_backup_script
    
    # 提示用户配置API密钥
    warn "请编辑 .env 文件，配置以下必要参数:"
    warn "- DEEPSEEK_API_KEY"
    warn "- WECHAT_APP_ID"
    warn "- WECHAT_APP_SECRET"
    echo
    read -p "配置完成后按Enter继续..."
    
    # 部署应用
    deploy_application
    
    # 验证部署
    if verify_deployment; then
        # 设置定时任务
        setup_cron
        
        log "✅ 部署成功完成！"
        info "📖 详细文档: docs/TENCENT_CLOUD_DEPLOYMENT_GUIDE.md"
        info "🔧 管理命令:"
        info "  查看日志: docker-compose -f docker-compose.prod.yml logs -f"
        info "  重启服务: docker-compose -f docker-compose.prod.yml restart"
        info "  停止服务: docker-compose -f docker-compose.prod.yml down"
        info "  备份数据: ./backup.sh"
    else
        error "❌ 部署验证失败"
        info "查看日志: $LOG_FILE"
        exit 1
    fi
}

# 执行主函数
main "$@" 