#!/bin/bash

# AI八卦运势小程序 - 腾讯云统一部署脚本
# 支持Docker和非Docker环境
# 使用方法: sudo ./scripts/deploy-to-tencent-cloud-unified.sh [options]

set -e

# 版本信息
SCRIPT_VERSION="2.0.0"
PROJECT_NAME="fortune-mini-app"
PROJECT_DIR="/opt/fortune-app"
BACKUP_DIR="/backup"
LOG_FILE="/tmp/deploy.log"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 配置选项（默认值）
USE_DOCKER_PREINSTALL=false
SETUP_SSL=false
SETUP_MONITORING=false
GIT_REPO_URL=""

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

step() {
    echo -e "${PURPLE}[$(date +'%Y-%m-%d %H:%M:%S')] STEP:${NC} $1" | tee -a $LOG_FILE
}

# 显示脚本信息
show_header() {
    echo "=========================================="
    echo "🚀 AI八卦运势小程序 - 腾讯云统一部署脚本"
    echo "📦 版本: $SCRIPT_VERSION"
    echo "🕒 时间: $(date)"
    echo "=========================================="
}

# 显示帮助信息
show_help() {
    cat << EOF
AI八卦运势小程序 - 腾讯云统一部署脚本

使用方法:
  sudo $0 [选项] [Git仓库地址]

选项:
  --docker-preinstall     使用腾讯云预装Docker镜像模式
  --ssl                   启用SSL/HTTPS配置
  --monitoring           启用监控组件
  --project-dir DIR      指定项目目录 (默认: $PROJECT_DIR)
  --help                 显示帮助信息

示例:
  # 基础部署
  sudo $0

  # 使用预装Docker模式
  sudo $0 --docker-preinstall

  # 完整部署（包含SSL和监控）
  sudo $0 --ssl --monitoring

  # 指定Git仓库
  sudo $0 https://github.com/username/bagua-ai.git

  # 自定义项目目录
  sudo $0 --project-dir /var/www/fortune-app

注意:
  - 必须使用 sudo 权限运行
  - 适用于Ubuntu 18.04+系统
  - 需要至少4GB内存和10GB磁盘空间
EOF
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --docker-preinstall)
                USE_DOCKER_PREINSTALL=true
                shift
                ;;
            --ssl)
                SETUP_SSL=true
                shift
                ;;
            --monitoring)
                SETUP_MONITORING=true
                shift
                ;;
            --project-dir)
                PROJECT_DIR="$2"
                shift 2
                ;;
            --help)
                show_help
                exit 0
                ;;
            http*|git*)
                GIT_REPO_URL="$1"
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

# 检查root权限
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "请使用 sudo 运行此脚本"
        echo "正确使用方法: sudo $0"
        exit 1
    fi
}

# 获取当前用户
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
    step "检查系统环境..."
    
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
    
    # 检查网络连接
    if ! ping -c 1 baidu.com &> /dev/null; then
        warn "网络连接可能有问题，请检查网络设置"
    fi
    
    log "系统检查通过 - Ubuntu $VERSION, 内存: ${MEMORY}GB, 可用磁盘: ${DISK}G"
}

# 更新系统包
update_system() {
    step "更新系统包..."
    
    # 更新包列表
    apt update
    
    # 安装基础工具
    apt install -y \
        curl \
        wget \
        git \
        vim \
        htop \
        unzip \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        pwgen \
        openssl \
        bc
        
    log "系统包更新完成"
}

# 安装Docker
install_docker() {
    if $USE_DOCKER_PREINSTALL; then
        check_docker_preinstalled
    else
        install_docker_from_scratch
    fi
}

# 检查预装Docker
check_docker_preinstalled() {
    step "检查预装Docker环境..."
    
    if ! command -v docker &> /dev/null; then
        error "Docker未预装，请使用腾讯云Docker CE镜像或添加--docker-preinstall=false参数"
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
    
    # 配置用户权限
    if [ -n "$REAL_USER" ] && [ "$REAL_USER" != "root" ]; then
        usermod -aG docker $REAL_USER
        log "已将用户 $REAL_USER 添加到docker组"
    fi
}

# 从头安装Docker
install_docker_from_scratch() {
    if command -v docker &> /dev/null; then
        log "Docker已安装，版本: $(docker --version)"
        return
    fi
    
    step "安装Docker..."
    
    # 添加Docker GPG密钥
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # 添加Docker仓库
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # 安装Docker
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io
    
    # 启动服务
    systemctl start docker
    systemctl enable docker
    
    # 配置用户权限
    if [ -n "$REAL_USER" ] && [ "$REAL_USER" != "root" ]; then
        usermod -aG docker $REAL_USER
    fi
    
    log "Docker安装完成"
}

# 安装Docker Compose
install_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        log "Docker Compose已安装，版本: $(docker-compose --version)"
        return
    fi
    
    step "安装Docker Compose..."
    
    # 使用最新版本
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4)
    
    # 下载并安装
    curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
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
    step "配置Docker镜像加速..."
    
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json << 'EOF'
{
    "registry-mirrors": [
        "https://mirror.ccs.tencentcloudcr.com",
        "https://ccr.ccs.tencentcloudcr.com",
        "https://docker.mirrors.ustc.edu.cn"
    ],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m",
        "max-file": "3"
    },
    "storage-driver": "overlay2",
    "storage-opts": [
        "overlay2.override_kernel_check=true"
    ]
}
EOF
    
    # 重启Docker服务
    systemctl daemon-reload
    systemctl restart docker
    
    log "Docker镜像加速配置完成"
}

# 设置项目目录和代码
setup_project() {
    step "设置项目目录..."
    
    # 创建项目目录
    mkdir -p $PROJECT_DIR
    cd $PROJECT_DIR
    
    # 如果目录不为空，先备份
    if [ "$(ls -A $PROJECT_DIR 2>/dev/null)" ]; then
        warn "项目目录不为空，创建备份..."
        BACKUP_NAME="$PROJECT_DIR.backup.$(date +%Y%m%d_%H%M%S)"
        mv $PROJECT_DIR $BACKUP_NAME
        mkdir -p $PROJECT_DIR
        cd $PROJECT_DIR
        log "原目录已备份到: $BACKUP_NAME"
    fi
    
    # 克隆项目
    if [ -n "$GIT_REPO_URL" ]; then
        log "从Git仓库克隆项目: $GIT_REPO_URL"
        git clone $GIT_REPO_URL .
    else
        warn "未指定Git仓库，请手动将项目文件复制到 $PROJECT_DIR"
        warn "或者重新运行脚本并指定仓库地址"
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
    step "创建环境配置文件..."
    
    cd $PROJECT_DIR
    
    if [ -f .env ]; then
        warn ".env文件已存在，将备份为.env.backup"
        cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    # 生成随机密码
    MYSQL_ROOT_PASSWORD=$(openssl rand -hex 16)
    MYSQL_PASSWORD=$(openssl rand -hex 16)
    REDIS_PASSWORD=$(openssl rand -hex 16)
    JWT_SECRET=$(openssl rand -hex 32)
    
    # 获取服务器公网IP
    SERVER_IP=$(curl -s http://checkip.amazonaws.com 2>/dev/null || curl -s http://ip.3322.net 2>/dev/null || echo "localhost")
    
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
SSL_ENABLED=${SETUP_SSL}

# 数据库配置
MYSQL_HOST=mysql
MYSQL_PORT=3306
REDIS_HOST=redis
REDIS_PORT=6379
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

# 创建Docker配置文件
create_docker_configs() {
    step "创建Docker配置文件..."
    
    cd $PROJECT_DIR
    
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
      - ./backend/src/main/resources/sql/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
      - ./mysql/conf.d:/etc/mysql/conf.d:ro
    command: --default-authentication-plugin=mysql_native_password
      --character-set-server=utf8mb4
      --collation-server=utf8mb4_unicode_ci
      --innodb-buffer-pool-size=256M
    networks:
      - fortune-network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10

  # Redis缓存
  redis:
    image: redis:6.2-alpine
    container_name: fortune-redis-prod
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD} --appendonly yes
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - fortune-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3

  # 后端应用
  backend:
    build: 
      context: ./backend
      dockerfile: Dockerfile.prod
    container_name: fortune-backend-prod
    restart: unless-stopped
    ports:
      - "8081:8080"
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
      mysql:
        condition: service_healthy
      redis:
        condition: service_healthy
    volumes:
      - app_logs:/app/logs
    networks:
      - fortune-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 120s

  # Nginx反向代理
  nginx:
    image: nginx:alpine
    container_name: fortune-nginx-prod
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      - ./frontend/dist/build/h5:/usr/share/nginx/html:ro
      - nginx_logs:/var/log/nginx
    depends_on:
      - backend
    networks:
      - fortune-network

volumes:
  mysql_data:
    driver: local
  redis_data:
    driver: local
  app_logs:
    driver: local
  nginx_logs:
    driver: local

networks:
  fortune-network:
    driver: bridge
EOF

    log "Docker配置文件创建完成"
}

# 创建管理脚本
create_management_scripts() {
    step "创建管理脚本..."
    
    cd $PROJECT_DIR
    
    # 创建应用管理脚本
    cat > manage.sh << 'EOF'
#!/bin/bash

# 加载环境变量
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

case "$1" in
    start)
        echo "🚀 启动服务..."
        docker-compose -f docker-compose.prod.yml up -d
        echo "✅ 服务启动完成"
        ;;
    stop)
        echo "🛑 停止服务..."
        docker-compose -f docker-compose.prod.yml down
        echo "✅ 服务已停止"
        ;;
    restart)
        echo "🔄 重启服务..."
        docker-compose -f docker-compose.prod.yml restart
        echo "✅ 服务重启完成"
        ;;
    logs)
        echo "📋 查看日志..."
        docker-compose -f docker-compose.prod.yml logs -f ${2:-backend}
        ;;
    status)
        echo "📊 查看状态..."
        docker-compose -f docker-compose.prod.yml ps
        echo ""
        docker stats --no-stream
        ;;
    update)
        echo "🔄 更新应用..."
        git pull
        docker-compose -f docker-compose.prod.yml build --no-cache backend
        docker-compose -f docker-compose.prod.yml up -d backend
        echo "✅ 应用更新完成"
        ;;
    backup)
        echo "💾 备份数据..."
        ./backup.sh
        ;;
    clean)
        echo "🧹 清理未使用的Docker资源..."
        docker system prune -f
        docker volume prune -f
        echo "✅ 清理完成"
        ;;
    *)
        echo "AI八卦运势小程序 - 管理脚本"
        echo ""
        echo "使用方法: $0 {start|stop|restart|logs|status|update|backup|clean}"
        echo ""
        echo "命令说明:"
        echo "  start   - 启动所有服务"
        echo "  stop    - 停止所有服务"
        echo "  restart - 重启服务"
        echo "  logs    - 查看日志 (可指定服务名)"
        echo "  status  - 查看服务状态"
        echo "  update  - 更新应用代码"
        echo "  backup  - 备份数据"
        echo "  clean   - 清理Docker资源"
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

echo "💾 开始备份数据..."

# 备份MySQL数据
echo "📊 备份MySQL数据库..."
docker exec fortune-mysql-prod mysqldump -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} > ${BACKUP_DIR}/mysql_backup_${DATE}.sql

# 备份Redis数据
echo "🔴 备份Redis数据..."
docker exec fortune-redis-prod redis-cli -a ${REDIS_PASSWORD} --rdb /data/dump.rdb
docker cp fortune-redis-prod:/data/dump.rdb ${BACKUP_DIR}/redis_backup_${DATE}.rdb

# 备份配置文件
echo "⚙️  备份配置文件..."
tar -czf ${BACKUP_DIR}/config_backup_${DATE}.tar.gz .env docker-compose.prod.yml mysql/ redis/ nginx/

# 压缩所有备份文件
echo "📦 压缩备份文件..."
tar -czf ${BACKUP_DIR}/fortune_backup_${DATE}.tar.gz ${BACKUP_DIR}/*_backup_${DATE}.*

# 清理临时文件
rm -f ${BACKUP_DIR}/*_backup_${DATE}.sql ${BACKUP_DIR}/*_backup_${DATE}.rdb ${BACKUP_DIR}/*_backup_${DATE}.tar.gz

# 删除7天前的备份
find ${BACKUP_DIR} -name "fortune_backup_*.tar.gz" -mtime +7 -delete

echo "✅ 备份完成: ${BACKUP_DIR}/fortune_backup_${DATE}.tar.gz"
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
    step "配置防火墙..."
    
    # 启用UFW防火墙
    ufw --force enable
    
    # 允许必要端口
    ufw allow 22/tcp    # SSH
    ufw allow 80/tcp    # HTTP
    ufw allow 443/tcp   # HTTPS
    ufw allow 8081/tcp  # 后端服务
    
    # 限制数据库端口只允许本地访问
    ufw deny 3306/tcp   # MySQL
    ufw deny 6379/tcp   # Redis
    
    # 显示防火墙状态
    ufw status verbose
    
    info "防火墙配置完成"
    info "请确保腾讯云安全组也开放了相应端口"
}

# 部署应用
deploy_application() {
    step "构建和部署应用..."
    
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
    sleep 90
    
    # 检查服务状态
    log "检查服务状态..."
    docker-compose -f docker-compose.prod.yml ps
}

# 验证部署
verify_deployment() {
    step "验证部署..."
    
    cd $PROJECT_DIR
    
    # 检查容器状态
    local failed_containers=()
    
    for container in mysql redis backend nginx; do
        if ! docker-compose -f docker-compose.prod.yml ps $container | grep -q "Up"; then
            failed_containers+=($container)
        fi
    done
    
    if [ ${#failed_containers[@]} -gt 0 ]; then
        error "以下容器未正常启动: ${failed_containers[*]}"
        for container in "${failed_containers[@]}"; do
            echo "--- $container 日志 ---"
            docker-compose -f docker-compose.prod.yml logs --tail=20 $container
        done
        return 1
    fi
    
    # 健康检查
    log "等待应用完全启动..."
    local retries=12
    while [ $retries -gt 0 ]; do
        if curl -f http://localhost:8081/actuator/health &>/dev/null; then
            log "✅ 应用健康检查通过"
            break
        fi
        warn "等待应用启动... (剩余重试次数: $retries)"
        sleep 10
        retries=$((retries-1))
    done
    
    if [ $retries -eq 0 ]; then
        error "❌ 应用健康检查失败"
        docker-compose -f docker-compose.prod.yml logs backend
        return 1
    fi
    
    # 显示访问信息
    SERVER_IP=$(curl -s http://checkip.amazonaws.com 2>/dev/null || curl -s http://ip.3322.net 2>/dev/null || echo "localhost")
    info "🎉 部署验证成功！"
    info "🌐 服务器IP: $SERVER_IP"
    info "🔗 应用地址:"
    info "  - 后端API: http://${SERVER_IP}:8081/actuator/health"
    info "  - 前端页面: http://${SERVER_IP}/"
    info "  - Nginx状态: http://${SERVER_IP}/health"
    
    return 0
}

# 设置定时任务
setup_cron() {
    step "设置定时备份任务..."
    
    # 添加定时备份任务（每天2点执行）
    (crontab -l 2>/dev/null; echo "0 2 * * * cd $PROJECT_DIR && $PROJECT_DIR/backup.sh >> /var/log/backup.log 2>&1") | crontab -
    
    log "定时备份任务设置完成（每天2:00AM执行）"
}

# 显示完成信息
show_completion_info() {
    local SERVER_IP=$(curl -s http://checkip.amazonaws.com 2>/dev/null || curl -s http://ip.3322.net 2>/dev/null || echo "localhost")
    
    echo ""
    echo "🎉🎉🎉 部署完成！ 🎉🎉🎉"
    echo ""
    echo "==================== 部署信息汇总 ===================="
    echo "📁 项目目录: $PROJECT_DIR"
    echo "🌐 服务器IP: $SERVER_IP"
    echo "📦 Docker版本: $(docker --version | cut -d' ' -f3 | sed 's/,//')"
    echo "🐙 Docker Compose版本: $(docker-compose --version | cut -d' ' -f3 | sed 's/,//')"
    echo ""
    echo "🔗 访问地址:"
    echo "  • 后端API健康检查: http://$SERVER_IP:8081/actuator/health"
    echo "  • 前端应用: http://$SERVER_IP/"
    echo "  • API接口示例: http://$SERVER_IP:8081/api/simple/hello"
    echo ""
    echo "🛠️  管理命令:"
    echo "  cd $PROJECT_DIR"
    echo "  ./manage.sh status     # 查看服务状态"
    echo "  ./manage.sh logs       # 查看应用日志"
    echo "  ./manage.sh restart    # 重启服务"
    echo "  ./manage.sh backup     # 备份数据"
    echo "  ./manage.sh update     # 更新应用"
    echo "  ./manage.sh clean      # 清理Docker资源"
    echo ""
    echo "⚙️  配置文件:"
    echo "  • 环境变量: $PROJECT_DIR/.env"
    echo "  • Docker配置: $PROJECT_DIR/docker-compose.prod.yml"
    echo "  • 备份目录: $BACKUP_DIR"
    echo ""
    echo "📚 文档资源:"
    echo "  • 部署指南: docs/TENCENT_CLOUD_DEPLOYMENT_GUIDE.md"
    echo "  • 微信小程序: WECHAT_MINIPROGRAM_DEPLOYMENT_GUIDE.md"
    echo "  • API文档: http://$SERVER_IP:8081/swagger-ui.html"
    echo ""
    echo "⚠️  重要提醒:"
    echo "  • 请配置 .env 文件中的API密钥"
    echo "  • 定时备份已设置（每天2:00AM）"
    echo "  • 防火墙已配置基础规则"
    if $SETUP_SSL; then
        echo "  • SSL证书需要手动配置"
    fi
    echo "=================================================="
}

# 主函数
main() {
    show_header
    
    # 解析命令行参数
    parse_args "$@"
    
    log "🚀 开始AI八卦运势小程序腾讯云部署..."
    log "配置选项: Docker预装=$USE_DOCKER_PREINSTALL, SSL=$SETUP_SSL, 监控=$SETUP_MONITORING"
    
    # 基础检查
    check_root
    get_real_user
    check_system
    
    # 系统准备
    update_system
    install_docker
    install_docker_compose
    configure_docker_registry
    
    # 项目设置
    setup_project
    create_env_config
    create_docker_configs
    create_management_scripts
    
    # 安全配置
    configure_firewall
    
    # 提示用户配置API密钥
    echo ""
    warn "⚠️  重要：请配置API密钥"
    warn "编辑文件: $PROJECT_DIR/.env"
    warn "配置以下参数:"
    warn "- DEEPSEEK_API_KEY=your-actual-api-key"
    warn "- WECHAT_APP_ID=your-actual-app-id" 
    warn "- WECHAT_APP_SECRET=your-actual-app-secret"
    echo ""
    
    # 询问是否继续部署
    while true; do
        read -p "是否已完成API密钥配置？(y/n): " yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) 
                echo "请配置完成后重新运行脚本或手动执行部署："
                echo "cd $PROJECT_DIR && ./manage.sh start"
                exit 0
                ;;
            * ) echo "请输入 y 或 n";;
        esac
    done
    
    # 部署应用
    deploy_application
    
    # 验证部署
    if verify_deployment; then
        setup_cron
        show_completion_info
        log "✅ 部署成功完成！"
    else
        error "❌ 部署验证失败"
        info "查看错误日志: $LOG_FILE"
        info "查看容器日志: cd $PROJECT_DIR && docker-compose -f docker-compose.prod.yml logs"
        info "尝试手动重启: cd $PROJECT_DIR && ./manage.sh restart"
        exit 1
    fi
}

# 错误处理
trap 'error "脚本执行过程中发生错误，请检查日志: $LOG_FILE"; exit 1' ERR

# 脚本入口
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# 执行主函数
main "$@" 