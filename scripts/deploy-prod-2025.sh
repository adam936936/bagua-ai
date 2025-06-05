#!/bin/bash

# ==============================================
# 八卦运势小程序 - 2025年生产环境部署脚本
# 支持腾讯云Docker环境一键部署
# 版本: v2.0.0
# 创建时间: 2025-06-05
# ==============================================

set -e

# 脚本配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_FILE="/tmp/fortune-deploy-$(date +%Y%m%d_%H%M%S).log"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# 日志函数
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${PURPLE}[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS:${NC} $1" | tee -a "$LOG_FILE"
}

# 检查root权限
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "请使用 sudo 运行此脚本"
        echo "使用方法: sudo $0 [options]"
        exit 1
    fi
}

# 获取真实用户
get_real_user() {
    if [ -n "$SUDO_USER" ]; then
        REAL_USER="$SUDO_USER"
    else
        REAL_USER="$(whoami)"
    fi
    info "当前用户: $REAL_USER"
}

# 显示帮助信息
show_help() {
    cat << EOF
八卦运势小程序 - 生产环境部署脚本 v2.0.0

使用方法:
    sudo $0 [选项]

选项:
    -h, --help              显示此帮助信息
    -e, --env-file FILE     指定环境变量文件 (默认: .env.prod)
    -d, --domain DOMAIN     设置域名
    -s, --skip-deps         跳过依赖安装
    -r, --rebuild           强制重新构建镜像
    -b, --backup            部署前备份现有数据
    --ssl-email EMAIL       SSL证书邮箱
    --no-ssl               不配置SSL证书
    --monitoring           启用监控组件

示例:
    sudo $0 -d fortune.example.com --ssl-email admin@example.com
    sudo $0 --env-file .env.custom --rebuild
    sudo $0 --skip-deps --no-ssl

EOF
}

# 解析命令行参数
parse_args() {
    ENV_FILE=".env.prod"
    DOMAIN=""
    SKIP_DEPS=false
    REBUILD=false
    BACKUP=false
    SSL_EMAIL=""
    NO_SSL=false
    ENABLE_MONITORING=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -e|--env-file)
                ENV_FILE="$2"
                shift 2
                ;;
            -d|--domain)
                DOMAIN="$2"
                shift 2
                ;;
            -s|--skip-deps)
                SKIP_DEPS=true
                shift
                ;;
            -r|--rebuild)
                REBUILD=true
                shift
                ;;
            -b|--backup)
                BACKUP=true
                shift
                ;;
            --ssl-email)
                SSL_EMAIL="$2"
                shift 2
                ;;
            --no-ssl)
                NO_SSL=true
                shift
                ;;
            --monitoring)
                ENABLE_MONITORING=true
                shift
                ;;
            *)
                error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
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
        error "需要Ubuntu 18.04或更高版本，当前版本: $VERSION"
        exit 1
    fi
    
    # 检查内存
    MEMORY=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
    if [ "$MEMORY" -lt 4 ]; then
        warn "推荐至少4GB内存，当前: ${MEMORY}GB"
    fi
    
    # 检查磁盘空间
    DISK_SPACE=$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')
    if [ "$DISK_SPACE" -lt 20 ]; then
        error "磁盘空间不足，需要至少20GB可用空间，当前可用: ${DISK_SPACE}GB"
        exit 1
    fi
    
    success "系统检查通过 - Ubuntu $VERSION, 内存: ${MEMORY}GB, 可用磁盘: ${DISK_SPACE}GB"
}

# 安装依赖
install_dependencies() {
    if [ "$SKIP_DEPS" = true ]; then
        info "跳过依赖安装"
        return
    fi
    
    log "安装系统依赖..."
    
    # 更新包管理器
    apt update
    apt install -y curl wget git vim htop unzip tree jq bc lsb-release
    
    # 安装Docker
    if ! command -v docker &> /dev/null; then
        log "安装Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        usermod -aG docker "$REAL_USER"
    else
        info "Docker已安装: $(docker --version)"
    fi
    
    # 安装Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log "安装Docker Compose..."
        curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    else
        info "Docker Compose已安装: $(docker-compose --version)"
    fi
    
    # 配置Docker镜像加速
    configure_docker_mirror
    
    # 启动Docker服务
    systemctl enable docker
    systemctl start docker
    
    success "依赖安装完成"
}

# 配置Docker镜像加速
configure_docker_mirror() {
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
    },
    "storage-driver": "overlay2"
}
EOF
    
    systemctl daemon-reload
    systemctl restart docker
    
    success "Docker镜像加速配置完成"
}

# 检查和加载环境变量
load_env() {
    log "加载环境变量..."
    
    if [ ! -f "$ENV_FILE" ]; then
        error "环境变量文件不存在: $ENV_FILE"
        info "请先创建环境变量文件，参考示例:"
        info "cp .env.example $ENV_FILE"
        exit 1
    fi
    
    # 加载环境变量
    set -o allexport
    source "$ENV_FILE"
    set +o allexport
    
    # 验证必需的环境变量
    local required_vars=(
        "MYSQL_ROOT_PASSWORD"
        "MYSQL_PASSWORD"
        "JWT_SECRET"
        "DEEPSEEK_API_KEY"
        "WECHAT_APP_ID"
        "WECHAT_APP_SECRET"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            error "环境变量 $var 未设置"
            exit 1
        fi
    done
    
    # 设置默认值
    MYSQL_DATABASE=${MYSQL_DATABASE:-fortune_db}
    MYSQL_USERNAME=${MYSQL_USERNAME:-fortune_user}
    REDIS_PASSWORD=${REDIS_PASSWORD:-"$(openssl rand -base64 32 | tr -d '=+/')"}
    GRAFANA_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD:-"$(openssl rand -base64 16)"}
    
    # 从命令行参数覆盖设置
    if [ -n "$DOMAIN" ]; then
        DOMAIN_NAME="$DOMAIN"
        export DOMAIN_NAME
    fi
    
    success "环境变量加载完成"
}

# 创建项目目录结构
setup_project_structure() {
    log "创建项目目录结构..."
    
    local dirs=(
        "logs/nginx"
        "logs/mysql"
        "logs/redis"
        "uploads"
        "ssl"
        "backup"
        "monitoring"
        "nginx/conf.d"
        "mysql/conf.d"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$PROJECT_DIR/$dir"
    done
    
    # 设置目录权限
    chown -R "$REAL_USER:$REAL_USER" "$PROJECT_DIR"
    chmod -R 755 "$PROJECT_DIR"
    
    success "项目目录结构创建完成"
}

# 备份现有数据
backup_existing_data() {
    if [ "$BACKUP" != true ]; then
        return
    fi
    
    log "备份现有数据..."
    
    local backup_dir="/backup/fortune-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # 备份Docker卷数据
    if docker volume ls | grep -q "mysql_prod_data"; then
        info "备份MySQL数据..."
        docker run --rm -v mysql_prod_data:/data -v "$backup_dir":/backup alpine tar czf /backup/mysql_data.tar.gz -C /data .
    fi
    
    if docker volume ls | grep -q "redis_prod_data"; then
        info "备份Redis数据..."
        docker run --rm -v redis_prod_data:/data -v "$backup_dir":/backup alpine tar czf /backup/redis_data.tar.gz -C /data .
    fi
    
    # 备份配置文件
    if [ -f "$ENV_FILE" ]; then
        cp "$ENV_FILE" "$backup_dir/"
    fi
    
    success "数据备份完成: $backup_dir"
}

# 构建前端
build_frontend() {
    log "构建前端项目..."
    
    cd "$PROJECT_DIR/frontend"
    
    # 检查Node.js环境
    if ! command -v npm &> /dev/null; then
        log "安装Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt-get install -y nodejs
    fi
    
    # 安装依赖
    npm install --legacy-peer-deps
    
    # 构建H5版本用于Web访问
    npm run build:h5
    
    # 构建微信小程序版本
    npm run build:mp-weixin
    
    success "前端构建完成"
}

# 构建后端
build_backend() {
    log "构建后端项目..."
    
    cd "$PROJECT_DIR/backend"
    
    # 使用Maven构建
    if [ ! -f "target/fortune-mini-app-backend-1.0.0.jar" ] || [ "$REBUILD" = true ]; then
        log "编译Java项目..."
        ./mvnw clean package -DskipTests
    else
        info "使用现有的JAR文件"
    fi
    
    success "后端构建完成"
}

# 生成Nginx配置
generate_nginx_config() {
    log "生成Nginx配置..."
    
    local nginx_conf="$PROJECT_DIR/nginx/nginx.prod.conf"
    
    cat > "$nginx_conf" << EOF
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
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"'
                    ' rt=\$request_time uct="\$upstream_connect_time"'
                    ' uht="\$upstream_header_time" urt="\$upstream_response_time"';
    
    access_log /var/log/nginx/access.log main;
    
    # 基础配置
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
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
    
    # 限流配置
    limit_req_zone \$binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone \$binary_remote_addr zone=login:10m rate=1r/s;
    
    # 上游服务器
    upstream backend {
        server backend-prod:8080 max_fails=3 fail_timeout=30s;
        keepalive 32;
    }
    
    # HTTP服务器（重定向到HTTPS）
    server {
        listen 80;
        server_name ${DOMAIN_NAME:-localhost};
        return 301 https://\$server_name\$request_uri;
    }
    
    # HTTPS服务器
    server {
        listen 443 ssl http2;
        server_name ${DOMAIN_NAME:-localhost};
        
        # SSL配置
        ssl_certificate /etc/nginx/ssl/server.crt;
        ssl_certificate_key /etc/nginx/ssl/server.key;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;
        
        # 安全头
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
        
        # 健康检查
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
        
        # API代理
        location /api/ {
            limit_req zone=api burst=20 nodelay;
            
            proxy_pass http://backend/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_cache_bypass \$http_upgrade;
            
            proxy_connect_timeout 30s;
            proxy_send_timeout 30s;
            proxy_read_timeout 30s;
        }
        
        # 登录接口特殊限流
        location /api/auth/login {
            limit_req zone=login burst=5 nodelay;
            
            proxy_pass http://backend/auth/login;
            proxy_http_version 1.1;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
        
        # 静态文件
        location /static/ {
            alias /usr/share/nginx/html/static/;
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
        
        # 上传文件
        location /uploads/ {
            alias /usr/share/nginx/html/uploads/;
            expires 30d;
            add_header Cache-Control "public";
        }
        
        # 默认页面
        location / {
            root /usr/share/nginx/html/static;
            index index.html;
            try_files \$uri \$uri/ /index.html;
        }
    }
}
EOF
    
    success "Nginx配置生成完成"
}

# 生成SSL证书
generate_ssl_certificate() {
    if [ "$NO_SSL" = true ]; then
        warn "跳过SSL证书配置"
        return
    fi
    
    log "配置SSL证书..."
    
    local ssl_dir="$PROJECT_DIR/ssl"
    
    if [ -n "$SSL_EMAIL" ] && [ -n "$DOMAIN_NAME" ]; then
        # 使用Let's Encrypt
        if command -v certbot &> /dev/null; then
            log "使用Let's Encrypt生成SSL证书..."
            certbot certonly --standalone -d "$DOMAIN_NAME" --email "$SSL_EMAIL" --agree-tos --non-interactive
            
            # 复制证书到项目目录
            cp "/etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem" "$ssl_dir/server.crt"
            cp "/etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem" "$ssl_dir/server.key"
        fi
    else
        # 生成自签名证书
        log "生成自签名SSL证书..."
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$ssl_dir/server.key" \
            -out "$ssl_dir/server.crt" \
            -subj "/C=CN/ST=Beijing/L=Beijing/O=Fortune/OU=IT/CN=${DOMAIN_NAME:-localhost}"
    fi
    
    # 设置权限
    chmod 600 "$ssl_dir/server.key"
    chmod 644 "$ssl_dir/server.crt"
    
    success "SSL证书配置完成"
}

# 生成监控配置
generate_monitoring_config() {
    if [ "$ENABLE_MONITORING" != true ]; then
        return
    fi
    
    log "生成监控配置..."
    
    # Prometheus配置
    cat > "$PROJECT_DIR/monitoring/prometheus.yml" << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'fortune-backend'
    static_configs:
      - targets: ['backend-prod:8081']
    metrics_path: '/actuator/prometheus'
    scrape_interval: 30s

  - job_name: 'fortune-nginx'
    static_configs:
      - targets: ['nginx-prod:80']

  - job_name: 'fortune-mysql'
    static_configs:
      - targets: ['mysql-prod:3306']

  - job_name: 'fortune-redis'
    static_configs:
      - targets: ['redis-prod:6379']
EOF
    
    success "监控配置生成完成"
}

# 部署服务
deploy_services() {
    log "部署Docker服务..."
    
    cd "$PROJECT_DIR"
    
    # 停止现有服务
    if docker-compose -f docker-compose.prod.yml ps -q | grep -q .; then
        log "停止现有服务..."
        docker-compose -f docker-compose.prod.yml down
    fi
    
    # 启动服务
    log "启动新服务..."
    docker-compose -f docker-compose.prod.yml up -d --remove-orphans
    
    # 等待服务启动
    log "等待服务启动..."
    sleep 30
    
    # 检查服务状态
    check_services_health
    
    success "Docker服务部署完成"
}

# 检查服务健康状态
check_services_health() {
    log "检查服务健康状态..."
    
    local services=("mysql-prod" "redis-prod" "backend-prod" "nginx-prod")
    local max_wait=300  # 5分钟超时
    local waited=0
    
    for service in "${services[@]}"; do
        info "检查服务: $service"
        
        while [ $waited -lt $max_wait ]; do
            if docker-compose -f docker-compose.prod.yml ps "$service" | grep -q "healthy\|Up"; then
                success "服务 $service 运行正常"
                break
            fi
            
            sleep 10
            waited=$((waited + 10))
            info "等待服务 $service 启动... (${waited}s)"
        done
        
        if [ $waited -ge $max_wait ]; then
            error "服务 $service 启动超时"
            docker-compose -f docker-compose.prod.yml logs "$service"
            exit 1
        fi
    done
    
    success "所有服务健康检查通过"
}

# 运行部署后测试
run_post_deploy_tests() {
    log "运行部署后测试..."
    
    # 测试API连通性
    local api_url="http://localhost:8080/api"
    
    if curl -f "$api_url/actuator/health" &> /dev/null; then
        success "后端API健康检查通过"
    else
        error "后端API健康检查失败"
        exit 1
    fi
    
    # 测试数据库连接
    if docker exec fortune-mysql-prod mysqladmin ping -h localhost -u root -p"$MYSQL_ROOT_PASSWORD" &> /dev/null; then
        success "数据库连接正常"
    else
        error "数据库连接失败"
        exit 1
    fi
    
    # 测试Redis连接
    if docker exec fortune-redis-prod redis-cli -a "$REDIS_PASSWORD" ping | grep -q "PONG"; then
        success "Redis连接正常"
    else
        error "Redis连接失败"
        exit 1
    fi
    
    success "部署后测试全部通过"
}

# 显示部署结果
show_deploy_result() {
    success "🎉 部署完成!"
    
    echo
    echo "=================="
    echo "   部署信息汇总"
    echo "=================="
    echo "项目目录: $PROJECT_DIR"
    echo "环境文件: $ENV_FILE"
    echo "域名: ${DOMAIN_NAME:-localhost}"
    echo "日志文件: $LOG_FILE"
    echo
    
    echo "=================="
    echo "   服务访问地址"
    echo "=================="
    echo "前端页面: https://${DOMAIN_NAME:-localhost}"
    echo "后端API:  https://${DOMAIN_NAME:-localhost}/api"
    echo "健康检查: https://${DOMAIN_NAME:-localhost}/health"
    
    if [ "$ENABLE_MONITORING" = true ]; then
        echo "Prometheus: http://${DOMAIN_NAME:-localhost}:9090"
        echo "Grafana:    http://${DOMAIN_NAME:-localhost}:3000"
        echo "Grafana管理员密码: $GRAFANA_ADMIN_PASSWORD"
    fi
    
    echo
    echo "=================="
    echo "   管理命令"
    echo "=================="
    echo "查看服务状态: docker-compose -f docker-compose.prod.yml ps"
    echo "查看日志:     docker-compose -f docker-compose.prod.yml logs -f"
    echo "重启服务:     docker-compose -f docker-compose.prod.yml restart"
    echo "停止服务:     docker-compose -f docker-compose.prod.yml down"
    echo
    
    echo "=================="
    echo "   下一步操作"
    echo "=================="
    echo "1. 配置域名DNS解析指向服务器IP"
    echo "2. 在微信公众平台配置服务器域名"
    echo "3. 上传微信小程序代码并提交审核"
    echo "4. 配置监控告警规则"
    echo "5. 设置数据备份计划"
    echo
}

# 主函数
main() {
    echo -e "${PURPLE}"
    cat << 'EOF'
 ╔═══════════════════════════════════════════════════════════════╗
 ║                    八卦运势小程序                             ║
 ║                  生产环境部署脚本 v2.0.0                      ║
 ║                                                               ║
 ║   基于Docker的现代化云原生部署方案                            ║
 ║   支持自动化部署、监控告警、数据备份                         ║
 ╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    # 解析命令行参数
    parse_args "$@"
    
    # 执行部署流程
    check_root
    get_real_user
    check_system
    install_dependencies
    load_env
    setup_project_structure
    backup_existing_data
    build_frontend
    build_backend
    generate_nginx_config
    generate_ssl_certificate
    generate_monitoring_config
    deploy_services
    run_post_deploy_tests
    show_deploy_result
    
    success "部署脚本执行完成！"
}

# 执行主函数
main "$@" 