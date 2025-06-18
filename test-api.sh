#!/bin/bash

# 八卦运势小程序 - API测试脚本
# 作者: AI助手
# 日期: 2025-06-18

set -e

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

BASE_URL="http://localhost:8080"

log_info() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

log_info "🧪 开始测试八卦运势小程序API..."

# 测试健康检查
log_info "测试健康检查接口..."
if curl -s "$BASE_URL/api/actuator/health" | grep -q "UP"; then
    log_success "健康检查通过"
else
    log_error "健康检查失败"
    exit 1
fi

# 测试八字计算
log_info "测试八字计算接口..."
RESPONSE=$(curl -s -X POST "$BASE_URL/api/fortune/calculate" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "测试用户",
        "birthDate": "1990-01-01",
        "birthTime": "子时",
        "gender": "male"
    }')

if echo "$RESPONSE" | grep -q "八字"; then
    log_success "八字计算接口正常"
    echo "响应: $RESPONSE" | head -c 200
    echo "..."
else
    log_error "八字计算接口异常"
    echo "响应: $RESPONSE"
fi

# 测试今日运势
log_info "测试今日运势接口..."
RESPONSE=$(curl -s "$BASE_URL/api/fortune/today-fortune")

if echo "$RESPONSE" | grep -q "运势"; then
    log_success "今日运势接口正常"
    echo "响应: $RESPONSE" | head -c 200
    echo "..."
else
    log_error "今日运势接口异常"
    echo "响应: $RESPONSE"
fi

log_success "🎉 API测试完成！" 