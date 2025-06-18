#!/bin/bash

# 八卦运势小程序 - 生产环境部署脚本
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

log_info "🚀 开始部署八卦运势小程序生产环境..."

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    log_error "Docker未运行，请先启动Docker"
    exit 1
fi

# 检查JAR文件
if [ ! -f "backend/target/fortune-mini-app-1.0.0.jar" ]; then
    log_error "JAR文件不存在，请先构建后端应用"
    log_info "运行命令: cd backend && mvn clean package -DskipTests"
    exit 1
fi

# 检查数据库初始化文件
if [ ! -f "backend/complete-init.sql" ]; then
    log_error "数据库初始化文件不存在: backend/complete-init.sql"
    exit 1
fi

# 创建必要目录
log_info "创建必要目录..."
mkdir -p logs uploads

# 停止现有服务
log_info "停止现有服务..."
docker-compose down > /dev/null 2>&1 || true

# 清理旧数据（可选）
read -p "是否清理旧数据？这将删除所有数据库数据 (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_warning "清理旧数据..."
    docker volume rm bagua-ai_mysql_data bagua-ai_redis_data > /dev/null 2>&1 || true
fi

# 启动数据库服务
log_info "启动数据库和缓存服务..."
docker-compose up -d mysql redis

# 等待数据库启动
log_info "等待数据库启动..."
for i in {1..30}; do
    if docker-compose exec -T mysql mysqladmin ping -h localhost -u root -pFortune2025!Root > /dev/null 2>&1; then
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
docker-compose up -d backend

# 等待后端启动
log_info "等待后端服务启动..."
for i in {1..60}; do
    if curl -s http://localhost:8080/api/actuator/health > /dev/null 2>&1; then
        log_success "后端服务启动成功"
        break
    fi
    if [ $i -eq 60 ]; then
        log_error "后端服务启动超时"
        docker-compose logs backend
        exit 1
    fi
    echo -n "."
    sleep 2
done

# 验证服务状态
log_info "验证服务状态..."
docker-compose ps

# 测试API接口
log_info "测试API接口..."
if curl -s http://localhost:8080/api/actuator/health | grep -q "UP"; then
    log_success "✅ 健康检查通过"
else
    log_warning "⚠️ 健康检查可能有问题"
fi

# 显示部署结果
log_success "🎉 生产环境部署完成！"
echo ""
echo "📋 服务信息:"
echo "- 后端API: http://localhost:8080"
echo "- 数据库: localhost:3306"
echo "- Redis: localhost:6379"
echo ""
echo "🔧 管理命令:"
echo "- 查看日志: docker-compose logs -f"
echo "- 停止服务: docker-compose down"
echo "- 重启服务: ./deploy-prod.sh"
echo ""
echo "🧪 测试命令:"
echo "- 健康检查: curl http://localhost:8080/api/actuator/health"
echo "- 测试运势: curl -X POST http://localhost:8080/api/fortune/calculate -H 'Content-Type: application/json' -d '{\"name\":\"测试\",\"birthDate\":\"1990-01-01\",\"birthTime\":\"子时\",\"gender\":\"male\"}'" 