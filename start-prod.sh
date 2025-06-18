#!/bin/bash

# 八卦运势小程序 - 生产环境启动脚本
# 作者: AI助手
# 日期: 2025-01-17

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_info "🚀 启动八卦运势小程序生产环境..."

# 检查配置文件
if [ ! -f "config/prod.env" ]; then
    log_error "配置文件 config/prod.env 不存在！"
    log_info "请先创建配置文件：cp config/prod.env.template config/prod.env"
    exit 1
fi

# 创建必要的目录
log_info "创建必要的目录..."
mkdir -p logs/{mysql,redis,nginx,app}
mkdir -p uploads
mkdir -p backup/{mysql,redis,app}

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    log_error "Docker未运行，请先启动Docker"
    exit 1
fi

# 停止现有服务
log_info "停止现有服务..."
docker-compose -f docker-compose.prod.2025.yml down > /dev/null 2>&1 || true

# 清理旧网络
log_info "清理网络..."
docker network prune -f > /dev/null 2>&1 || true

# 启动服务
log_info "启动生产环境服务..."
if docker-compose --env-file config/prod.env -f docker-compose.prod.2025.yml up -d mysql-prod redis-prod; then
    log_success "数据库和缓存服务启动成功"
else
    log_error "数据库和缓存服务启动失败"
    exit 1
fi

# 等待数据库启动
log_info "等待数据库启动..."
sleep 30

# 启动后端服务
log_info "启动后端服务..."
if docker-compose --env-file config/prod.env -f docker-compose.prod.2025.yml up -d backend-prod; then
    log_success "后端服务启动成功"
else
    log_error "后端服务启动失败"
    exit 1
fi

# 等待后端启动
log_info "等待后端服务启动..."
sleep 30

# 启动Nginx
log_info "启动Nginx服务..."
if docker-compose --env-file config/prod.env -f docker-compose.prod.2025.yml up -d nginx-prod; then
    log_success "Nginx服务启动成功"
else
    log_warning "Nginx服务启动失败，可能是配置文件缺失"
fi

# 显示服务状态
log_info "检查服务状态..."
docker-compose -f docker-compose.prod.2025.yml ps

log_success "🎉 生产环境启动完成！"
echo ""
echo "📋 服务访问地址:"
echo "- 后端API: http://localhost:8080"
echo "- 数据库: localhost:3306"
echo "- Redis: localhost:6379"
echo ""
echo "🔧 管理命令:"
echo "- 查看日志: docker-compose -f docker-compose.prod.2025.yml logs -f"
echo "- 停止服务: docker-compose -f docker-compose.prod.2025.yml down"
echo "- 重启服务: ./start-prod.sh" 