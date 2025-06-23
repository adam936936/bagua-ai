#!/bin/bash

# 八卦运势AI小程序 - 只部署后端脚本
# Ubuntu生产环境
# 作者: AI助手
# 日期: 2025-01-17

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo -e "${CYAN}"
echo "=================================================="
echo "    八卦运势AI小程序 - 后端部署"
echo "    Ubuntu生产环境 | Docker环境"
echo "=================================================="
echo -e "${NC}"

# 检查Docker环境
log_info "🔍 检查Docker环境..."
if ! docker info > /dev/null 2>&1; then
    log_error "❌ Docker未运行，请先启动Docker服务"
    exit 1
fi
log_success "✅ Docker环境检查通过"

# 检查必要文件
log_info "🔍 检查必要文件..."
if [ ! -f "docker-compose.public.yml" ]; then
    log_error "❌ 找不到docker-compose.public.yml文件"
    exit 1
fi

if [ ! -f "config/prod.env" ]; then
    log_error "❌ 找不到config/prod.env配置文件"
    exit 1
fi

if [ ! -f "backend/target/fortune-mini-app-1.0.0.jar" ]; then
    log_error "❌ 找不到后端JAR文件，请先构建后端"
    echo "构建命令: cd backend && mvn clean package -DskipTests"
    exit 1
fi

log_success "✅ 必要文件检查通过"

# 创建必要目录
log_info "📁 创建必要目录..."
mkdir -p logs uploads
sudo chown -R $USER:$USER logs uploads 2>/dev/null || true
chmod 755 logs uploads

# 停止现有后端服务
log_info "🛑 停止现有后端服务..."
docker-compose -f docker-compose.public.yml down --remove-orphans > /dev/null 2>&1 || true

# 启动数据库和缓存服务
log_info "🗄️ 启动数据库和缓存服务..."
docker-compose -f docker-compose.public.yml --env-file config/prod.env up -d mysql redis

# 等待数据库启动
log_info "⏳ 等待数据库启动..."
for i in {1..30}; do
    if docker-compose -f docker-compose.public.yml exec -T mysql mysqladmin ping -h localhost -u root -pFortune2025!Root > /dev/null 2>&1; then
        log_success "✅ 数据库启动成功"
        break
    fi
    if [ $i -eq 30 ]; then
        log_error "❌ 数据库启动超时"
        exit 1
    fi
    echo -n "."
    sleep 2
done

# 启动后端服务
log_info "🚀 启动后端服务..."
docker-compose -f docker-compose.public.yml --env-file config/prod.env up -d backend

# 等待后端启动
log_info "⏳ 等待后端服务启动..."
for i in {1..60}; do
    if curl -s http://localhost:8080/api/actuator/health > /dev/null 2>&1; then
        log_success "✅ 后端服务启动成功"
        break
    fi
    if [ $i -eq 60 ]; then
        log_error "❌ 后端服务启动超时"
        docker-compose -f docker-compose.public.yml logs backend
        exit 1
    fi
    echo -n "."
    sleep 2
done

# 验证后端服务
log_info "🔍 验证后端服务..."
if curl -s http://localhost:8080/api/actuator/health | grep -q "UP"; then
    log_success "✅ 后端服务验证通过"
else
    log_error "❌ 后端服务验证失败"
fi

# 显示服务状态
log_info "📊 服务状态:"
docker-compose -f docker-compose.public.yml ps

# 显示部署结果
log_success "🎉 后端部署完成！"
echo ""
echo -e "${CYAN}📋 服务访问地址:${NC}"
echo "- 后端API接口: http://localhost:8080"
echo "- 健康检查: http://localhost:8080/api/actuator/health"
echo "- 数据库: localhost:3306"
echo "- Redis缓存: localhost:6379"
echo ""
echo -e "${CYAN}🔧 管理命令:${NC}"
echo "- 查看后端日志: docker-compose -f docker-compose.public.yml logs -f backend"
echo "- 查看数据库日志: docker-compose -f docker-compose.public.yml logs -f mysql"
echo "- 停止后端服务: docker-compose -f docker-compose.public.yml down"
echo "- 重新启动: ./deploy-backend-only.sh"
echo ""
echo -e "${CYAN}🧪 测试命令:${NC}"
echo "- 后端健康检查: curl http://localhost:8080/api/actuator/health"
echo "- 测试运势API: curl -X POST http://localhost:8080/api/fortune/calculate -H 'Content-Type: application/json' -d '{\"name\":\"测试\",\"birthDate\":\"1990-01-01\",\"birthTime\":\"子时\",\"gender\":\"male\"}'"
echo ""
echo -e "${YELLOW}⚠️ 注意:${NC}"
echo "- 后端服务已启动，如需前端请运行: ./deploy-frontend-only.sh"
echo "- 或使用完整部署: ./ubuntu-quick-start.sh" 