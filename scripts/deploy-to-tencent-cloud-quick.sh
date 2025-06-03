#!/bin/bash

# AI八卦运势小程序 - 腾讯云快速部署脚本
# 简化版本，专注核心功能
# 使用方法: sudo ./scripts/deploy-to-tencent-cloud-quick.sh

set -e

# 基础配置
PROJECT_NAME="fortune-mini-app"
PROJECT_DIR="/opt/fortune-app"
LOG_FILE="/tmp/deploy-quick.log"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1" | tee -a $LOG_FILE; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a $LOG_FILE; }
error() { echo -e "${RED}[ERROR]${NC} $1" | tee -a $LOG_FILE; }
info() { echo -e "${BLUE}[INFO]${NC} $1" | tee -a $LOG_FILE; }

# 检查权限
if [ "$EUID" -ne 0 ]; then
    error "请使用 sudo 运行此脚本"
    exit 1
fi

# 获取真实用户
REAL_USER="${SUDO_USER:-$(whoami)}"

echo "🚀 AI八卦运势小程序 - 腾讯云快速部署"
echo "=========================================="

# 1. 检查系统
log "检查系统环境..."
if ! grep -q "Ubuntu" /etc/os-release; then
    error "仅支持Ubuntu系统"
    exit 1
fi

VERSION=$(lsb_release -rs)
if (( $(echo "$VERSION < 18.04" | bc -l) )); then
    error "需要Ubuntu 18.04+"
    exit 1
fi

MEMORY=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
if [ "$MEMORY" -lt 2 ]; then
    warn "推荐至少4GB内存，当前: ${MEMORY}GB"
fi

log "✅ 系统检查通过 - Ubuntu $VERSION, 内存: ${MEMORY}GB"

# 2. 安装Docker
log "安装Docker..."
if ! command -v docker &> /dev/null; then
    # 更新系统
    apt update
    apt install -y curl wget git vim htop software-properties-common
    
    # 安装Docker
    curl -fsSL https://get.docker.com | sh
    systemctl start docker
    systemctl enable docker
    usermod -aG docker $REAL_USER
    
    log "✅ Docker安装完成"
else
    log "✅ Docker已存在: $(docker --version)"
fi

# 3. 安装Docker Compose
log "安装Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    log "✅ Docker Compose安装完成"
else
    log "✅ Docker Compose已存在: $(docker-compose --version)"
fi

# 4. 设置项目
log "设置项目目录..."
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

if [ -n "$1" ]; then
    log "克隆项目: $1"
    rm -rf ./*
    git clone $1 .
else
    warn "未指定Git仓库，请确保项目文件已存在于 $PROJECT_DIR"
fi

chown -R $REAL_USER:$REAL_USER $PROJECT_DIR

# 5. 创建环境配置
log "创建环境配置..."
cat > .env << EOF
# 数据库配置
MYSQL_ROOT_PASSWORD=$(openssl rand -hex 16)
MYSQL_DATABASE=fortune_db
MYSQL_USER=fortune_user
MYSQL_PASSWORD=$(openssl rand -hex 16)

# Redis配置
REDIS_PASSWORD=$(openssl rand -hex 16)

# API密钥（需要手动配置）
DEEPSEEK_API_KEY=sk-161f80e197f64439a4a9f0b4e9e30c40
WECHAT_APP_ID=wxab173e904eb23fca
WECHAT_APP_SECRET=75ad9ccb5f2ff072b8cd207d71a07ada

# JWT密钥
JWT_SECRET=$(openssl rand -hex 32)

# 服务器配置
SERVER_HOST=$(curl -s http://checkip.amazonaws.com 2>/dev/null || echo "localhost")
EOF

chmod 600 .env
chown $REAL_USER:$REAL_USER .env

log "✅ 环境配置创建完成"

# 6. 创建Docker配置
log "创建Docker配置..."
cat > docker-compose.prod.yml << 'EOF'
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: fortune-mysql-prod
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      - ./backend/src/main/resources/sql/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    command: --default-authentication-plugin=mysql_native_password --character-set-server=utf8mb4
    networks:
      - fortune-network

  redis:
    image: redis:6.2-alpine
    container_name: fortune-redis-prod
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD}
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - fortune-network

  backend:
    build: ./backend
    container_name: fortune-backend-prod
    restart: unless-stopped
    ports:
      - "8081:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=prod
      - MYSQL_HOST=mysql
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USERNAME=${MYSQL_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - REDIS_HOST=redis
      - REDIS_PASSWORD=${REDIS_PASSWORD}
      - DEEPSEEK_API_KEY=${DEEPSEEK_API_KEY}
      - WECHAT_APP_ID=${WECHAT_APP_ID}
      - WECHAT_APP_SECRET=${WECHAT_APP_SECRET}
      - JWT_SECRET=${JWT_SECRET}
    depends_on:
      - mysql
      - redis
    networks:
      - fortune-network

  nginx:
    image: nginx:alpine
    container_name: fortune-nginx-prod
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - ./nginx/nginx.prod.conf:/etc/nginx/nginx.conf:ro
      - ./frontend/dist/build/h5:/usr/share/nginx/html:ro
    depends_on:
      - backend
    networks:
      - fortune-network

volumes:
  mysql_data:
  redis_data:

networks:
  fortune-network:
    driver: bridge
EOF

log "✅ Docker配置创建完成"

# 7. 创建快速管理脚本
log "创建管理脚本..."
cat > manage.sh << 'EOF'
#!/bin/bash
case "$1" in
    start)   docker-compose -f docker-compose.prod.yml up -d ;;
    stop)    docker-compose -f docker-compose.prod.yml down ;;
    restart) docker-compose -f docker-compose.prod.yml restart ;;
    logs)    docker-compose -f docker-compose.prod.yml logs -f ${2:-backend} ;;
    status)  docker-compose -f docker-compose.prod.yml ps ;;
    *) echo "用法: $0 {start|stop|restart|logs|status}" ;;
esac
EOF

chmod +x manage.sh
chown $REAL_USER:$REAL_USER manage.sh

# 8. 配置防火墙
log "配置防火墙..."
ufw --force enable
ufw allow 22,80,443,8081/tcp
ufw deny 3306,6379/tcp

# 9. 部署应用
log "部署应用..."

# 加载环境变量
export $(cat .env | grep -v '^#' | xargs)

# 构建和启动
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d

# 10. 等待并验证
log "等待服务启动..."
sleep 60

log "验证部署..."
RETRIES=10
while [ $RETRIES -gt 0 ]; do
    if curl -f http://localhost:8081/actuator/health &>/dev/null; then
        log "✅ 应用启动成功"
        break
    fi
    warn "等待应用启动... ($RETRIES)"
    sleep 10
    RETRIES=$((RETRIES-1))
done

if [ $RETRIES -eq 0 ]; then
    error "❌ 应用启动失败"
    docker-compose -f docker-compose.prod.yml logs backend
    exit 1
fi

# 11. 显示结果
SERVER_IP=$(curl -s http://checkip.amazonaws.com 2>/dev/null || echo "localhost")

echo ""
echo "🎉 快速部署完成！"
echo "================================"
echo "📁 项目目录: $PROJECT_DIR"
echo "🌐 服务器IP: $SERVER_IP"
echo ""
echo "🔗 访问地址:"
echo "  • 后端API: http://$SERVER_IP:8081/actuator/health"
echo "  • 前端页面: http://$SERVER_IP/"
echo ""
echo "🛠️ 管理命令:"
echo "  cd $PROJECT_DIR"
echo "  ./manage.sh status    # 查看状态"
echo "  ./manage.sh logs      # 查看日志"
echo "  ./manage.sh restart   # 重启服务"
echo ""
echo "⚙️ 配置文件: $PROJECT_DIR/.env"
echo "📋 日志文件: $LOG_FILE"
echo "================================"

log "✅ 快速部署流程完成！" 