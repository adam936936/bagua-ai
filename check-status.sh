#!/bin/bash

# 八卦运势AI小程序 - 部署状态检查脚本
# Ubuntu生产环境
# 作者: AI助手
# 日期: 2025-01-17

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo -e "${CYAN}"
echo "=================================================="
echo "    八卦运势AI小程序 - 部署状态检查"
echo "=================================================="
echo -e "${NC}"

# 检查Docker服务
log_info "🐳 检查Docker服务状态..."
if docker info > /dev/null 2>&1; then
    log_success "✅ Docker服务正常运行"
else
    log_error "❌ Docker服务未运行"
    exit 1
fi

# 检查容器状态
log_info "📊 检查容器状态..."
echo ""
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"
echo ""

# 检查前端服务
log_info "🎨 检查前端服务..."
if docker ps | grep -q bagua-frontend-prod; then
    if curl -s http://localhost/health > /dev/null 2>&1; then
        log_success "✅ 前端服务正常运行"
        echo "   访问地址: http://localhost"
    else
        log_warning "⚠️ 前端容器运行但健康检查失败"
    fi
else
    log_info "ℹ️ 前端服务未部署"
fi

# 检查后端服务
log_info "⚙️ 检查后端服务..."
if docker ps | grep -q bagua-backend; then
    if curl -s http://localhost:8080/api/actuator/health > /dev/null 2>&1; then
        log_success "✅ 后端服务正常运行"
        echo "   访问地址: http://localhost:8080"
        
        # 获取健康检查详情
        HEALTH_STATUS=$(curl -s http://localhost:8080/api/actuator/health | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
        echo "   健康状态: $HEALTH_STATUS"
    else
        log_warning "⚠️ 后端容器运行但健康检查失败"
    fi
else
    log_error "❌ 后端服务未运行"
fi

# 检查数据库服务
log_info "🗄️ 检查数据库服务..."
if docker ps | grep -q mysql; then
    log_success "✅ MySQL数据库正常运行"
    echo "   连接地址: localhost:3306"
else
    log_error "❌ MySQL数据库未运行"
fi

# 检查Redis服务
log_info "📦 检查Redis服务..."
if docker ps | grep -q redis; then
    log_success "✅ Redis缓存正常运行"
    echo "   连接地址: localhost:6379"
else
    log_error "❌ Redis缓存未运行"
fi

# 检查端口占用
log_info "🔌 检查端口占用情况..."
echo ""
echo "端口占用情况:"
for port in 80 443 3306 6379 8080 8081; do
    if netstat -tln 2>/dev/null | grep -q ":$port "; then
        echo "  端口 $port: 已占用 ✅"
    else
        echo "  端口 $port: 未占用 ❌"
    fi
done

# 检查磁盘空间
log_info "💾 检查磁盘空间..."
df -h / | tail -1 | awk '{
    if ($5+0 > 80) 
        printf "   磁盘使用率: %s (警告: 超过80%%)\n", $5
    else 
        printf "   磁盘使用率: %s\n", $5
}'

# 检查内存使用
log_info "🧠 检查内存使用..."
free -h | awk 'NR==2{printf "   内存使用: %s/%s (%.2f%%)\n", $3, $2, $3*100/$2}'

# 检查Docker资源使用
log_info "📈 检查Docker资源使用..."
echo ""
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" 2>/dev/null || echo "   无法获取Docker统计信息"

echo ""
log_info "🧪 快速测试命令:"
echo "# 前端健康检查"
echo "curl http://localhost/health"
echo ""
echo "# 后端健康检查"
echo "curl http://localhost:8080/api/actuator/health"
echo ""
echo "# 测试运势API"
echo "curl -X POST http://localhost:8080/api/fortune/calculate -H 'Content-Type: application/json' -d '{\"name\":\"测试\",\"birthDate\":\"1990-01-01\",\"birthTime\":\"子时\",\"gender\":\"male\"}'"

echo ""
log_success "🎉 状态检查完成！" 