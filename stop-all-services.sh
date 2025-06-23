#!/bin/bash

# 八卦运势AI小程序 - 停止所有服务脚本
# Ubuntu生产环境
# 作者: AI助手
# 日期: 2025-01-17

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

echo -e "${BLUE}"
echo "=================================================="
echo "    停止八卦运势AI小程序所有服务"
echo "=================================================="
echo -e "${NC}"

# 停止前端服务
log_info "🛑 停止前端服务..."
if docker ps | grep -q bagua-frontend-prod; then
    log_info "停止运行中的前端容器..."
    docker stop bagua-frontend-prod
    log_success "✅ 前端容器已停止"
fi
if docker ps -a | grep -q bagua-frontend-prod; then
    log_info "删除前端容器..."
    docker rm bagua-frontend-prod
    log_success "✅ 前端容器已删除"
fi
if ! docker ps -a | grep -q bagua-frontend-prod; then
    log_info "ℹ️ 前端服务未运行"
fi

# 停止后端服务
log_info "🛑 停止后端服务..."
if [ -f "docker-compose.public.yml" ]; then
    docker-compose -f docker-compose.public.yml down --remove-orphans
    log_success "✅ 后端服务已停止"
elif [ -f "docker-compose.yml" ]; then
    docker-compose down --remove-orphans
    log_success "✅ 后端服务已停止"
else
    log_warning "⚠️ 找不到docker-compose配置文件"
fi

# 清理未使用的Docker资源（可选）
read -p "是否清理未使用的Docker资源？(y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "🧹 清理Docker资源..."
    docker system prune -f
    log_success "✅ Docker资源清理完成"
fi

# 显示剩余的容器
log_info "📊 当前运行的容器:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

log_success "🎉 所有服务已停止！" 