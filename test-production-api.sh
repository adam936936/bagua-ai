#!/bin/bash

# 八卦运势小程序 - 生产环境API测试脚本
# 测试地址: http://122.51.104.128:8888 (前端) 和 http://122.51.104.128:8889 (健康检查)
# 作者: AI助手
# 日期: 2025-01-17

set -e

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

# 生产环境配置
FRONTEND_URL="http://122.51.104.128:8888"
HEALTH_URL="http://122.51.104.128:8889"
API_URL="http://122.51.104.128:8888/api"

log_info() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

test_api() {
    local name="$1"
    local url="$2"
    local method="${3:-GET}"
    local data="$4"
    
    log_info "测试 $name..."
    
    if [ "$method" = "POST" ] && [ -n "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X POST \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$url" 2>/dev/null)
    else
        response=$(curl -s -w "\n%{http_code}" "$url" 2>/dev/null)
    fi
    
    # 分离响应体和状态码
    body=$(echo "$response" | head -n -1)
    status_code=$(echo "$response" | tail -n 1)
    
    if [ "$status_code" = "200" ]; then
        log_success "$name - 成功 (200)"
        echo "   响应预览: $(echo "$body" | head -c 150)..."
        
        # 检查是否包含数据保存成功的标志
        if echo "$body" | grep -q "保存成功\|saved successfully\|数据已保存"; then
            log_success "   ✓ 数据保存成功"
        elif echo "$body" | grep -q "未能保存\|save failed\|保存失败"; then
            log_warning "   ⚠ 数据保存可能失败"
        fi
    else
        log_error "$name - 失败 ($status_code)"
        echo "   错误: $(echo "$body" | head -c 200)"
    fi
    echo ""
}

echo -e "${BLUE}"
echo "=================================================="
echo "    八卦运势小程序 - 生产环境API测试"
echo "    服务器: 122.51.104.128"
echo "=================================================="
echo -e "${NC}"

# 1. 测试前端页面
log_info "测试前端页面访问..."
if curl -s -f "$FRONTEND_URL" > /dev/null 2>&1; then
    log_success "前端页面可访问 ($FRONTEND_URL)"
else
    log_error "前端页面无法访问 ($FRONTEND_URL)"
fi
echo ""

# 2. 测试健康检查
log_info "测试应用健康状态..."
health_response=$(curl -s "$HEALTH_URL/actuator/health" 2>/dev/null || echo "")
if echo "$health_response" | grep -q '"status":"UP"'; then
    log_success "应用健康状态正常"
    echo "   状态: $(echo "$health_response" | head -c 100)"
else
    log_error "应用健康状态异常"
    echo "   响应: $health_response"
fi
echo ""

# 3. 测试今日运势接口
test_api "今日运势" "$API_URL/fortune/today-fortune"

# 4. 测试命理计算接口（重点测试数据保存）
test_api "命理计算" "$API_URL/fortune/calculate" "POST" '{
    "name": "测试用户",
    "birthDate": "1990-01-01",
    "birthTime": "08:00",
    "gender": "male"
}'

# 5. 测试八字分析接口
test_api "八字分析" "$API_URL/fortune/bazi" "POST" '{
    "name": "张三",
    "birthDate": "1995-05-15",
    "birthTime": "14:30",
    "gender": "male"
}'

# 6. 测试姓名推荐接口
test_api "姓名推荐" "$API_URL/fortune/names" "POST" '{
    "surname": "李",
    "gender": "female",
    "birthDate": "1992-08-20",
    "birthTime": "10:15"
}'

# 7. 测试简单接口
test_api "简单Hello接口" "$API_URL/simple/hello"

# 8. 数据库连接测试
log_info "检查数据库连接状态..."
db_test_response=$(curl -s "$API_URL/fortune/calculate" \
    -X POST \
    -H "Content-Type: application/json" \
    -d '{
        "name": "数据库测试",
        "birthDate": "1988-12-25",
        "birthTime": "09:30",
        "gender": "female"
    }' 2>/dev/null)

if echo "$db_test_response" | grep -q "计算成功.*但结果未能保存"; then
    log_warning "⚠ 数据库保存可能存在问题"
    echo "   建议检查数据库连接和权限"
elif echo "$db_test_response" | grep -q "保存成功\|已保存"; then
    log_success "✓ 数据库保存功能正常"
else
    log_info "数据库状态: 需要进一步检查"
fi
echo ""

echo -e "${GREEN}"
echo "=================================================="
echo "🎉 生产环境API测试完成！"
echo "=================================================="
echo -e "${NC}"

echo "📊 测试总结："
echo "  - 前端地址: $FRONTEND_URL"
echo "  - 健康检查: $HEALTH_URL/actuator/health"
echo "  - API基地址: $API_URL"
echo ""
echo "💡 如果发现问题："
echo "  - 查看后端日志: docker-compose -f docker-compose.public.yml logs backend"
echo "  - 检查数据库: docker-compose -f docker-compose.public.yml exec mysql mysql -u root -p"
echo "  - 重启服务: docker-compose -f docker-compose.public.yml restart"
echo ""
echo "🔧 维护命令："
echo "  - 查看状态: ./check-status.sh"
echo "  - 停止服务: ./stop-all-services.sh"
echo "  - 重新部署: ./deploy.sh" 