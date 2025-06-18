#!/bin/bash

# 八卦运势小程序 - 公网环境部署脚本
# 公网IP: 122.51.104.128
# 作者: AI助手
# 日期: 2025-06-18

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PUBLIC_IP="122.51.104.128"

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

log_info "🌐 开始部署八卦运势小程序到公网环境..."
log_info "公网IP: $PUBLIC_IP"

# 检查是否在服务器上
if ! ip addr show | grep -q "$PUBLIC_IP"; then
    log_warning "当前不在目标服务器上，请确保在 $PUBLIC_IP 服务器上运行此脚本"
fi

# 停止本地服务
log_info "停止本地服务..."
docker-compose down --remove-orphans > /dev/null 2>&1 || true

# 启动公网服务
log_info "启动公网服务..."
docker-compose -f docker-compose.public.yml down --remove-orphans > /dev/null 2>&1 || true

# 启动数据库和缓存
log_info "启动数据库和缓存服务..."
docker-compose -f docker-compose.public.yml up -d mysql redis

# 等待数据库启动
log_info "等待数据库启动..."
for i in {1..30}; do
    if docker-compose -f docker-compose.public.yml exec -T mysql mysqladmin ping -h localhost -u root -pFortune2025!Root > /dev/null 2>&1; then
        log_success "数据库启动成功"
        break
    fi
    if [ $i -eq 30 ]; then
        log_error "数据库启动超时"
        exit 1
    fi
    echo -n "."
    sleep 2
done

# 启动后端服务
log_info "启动后端服务..."
docker-compose -f docker-compose.public.yml up -d backend

# 等待后端启动
log_info "等待后端服务启动..."
for i in {1..60}; do
    if curl -s http://$PUBLIC_IP:8080/api/actuator/health > /dev/null 2>&1; then
        log_success "后端服务启动成功"
        break
    fi
    if [ $i -eq 60 ]; then
        log_error "后端服务启动超时"
        docker-compose -f docker-compose.public.yml logs backend
        exit 1
    fi
    echo -n "."
    sleep 2
done

# 启动Nginx
log_info "启动Nginx反向代理..."
docker-compose -f docker-compose.public.yml up -d nginx

# 验证服务状态
log_info "验证服务状态..."
docker-compose -f docker-compose.public.yml ps

# 测试公网访问
log_info "测试公网访问..."
if curl -s http://$PUBLIC_IP:8080/api/actuator/health | grep -q "UP"; then
    log_success "✅ 公网访问正常"
else
    log_warning "⚠️ 公网访问可能有问题"
fi

# 显示部署结果
log_success "🎉 公网环境部署完成！"
echo ""
echo "📋 公网访问地址:"
echo "- 后端API: http://$PUBLIC_IP:8080"
echo "- Nginx代理: http://$PUBLIC_IP"
echo "- 数据库: $PUBLIC_IP:3306"
echo "- Redis: $PUBLIC_IP:6379"
echo ""
echo "🔧 管理命令:"
echo "- 查看日志: docker-compose -f docker-compose.public.yml logs -f"
echo "- 停止服务: docker-compose -f docker-compose.public.yml down"
echo "- 重启服务: ./deploy-public.sh"
echo ""
echo "🧪 测试命令:"
echo "- 健康检查: curl http://$PUBLIC_IP:8080/api/actuator/health"
echo "- 通过Nginx: curl http://$PUBLIC_IP/api/actuator/health"
echo "- 测试运势: curl -X POST http://$PUBLIC_IP:8080/api/fortune/calculate -H 'Content-Type: application/json' -d '{\"name\":\"测试\",\"birthDate\":\"1990-01-01\",\"birthTime\":\"子时\",\"gender\":\"male\"}'" 