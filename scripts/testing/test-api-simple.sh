#!/bin/bash

# 简单API测试脚本
# 使用curl直接测试接口

BASE_URL="http://localhost:8080/api"

# 颜色配置
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 测试函数
test_endpoint() {
    local endpoint=$1
    local method=${2:-GET}
    local data=$3
    
    echo -e "${YELLOW}测试接口: $method $endpoint${NC}"
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\n%{http_code}" -X $method "$BASE_URL$endpoint")
    else
        response=$(curl -s -w "\n%{http_code}" -X $method "$BASE_URL$endpoint" -H "Content-Type: application/json" -d "$data")
    fi
    
    status_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$status_code" -ge 200 ] && [ "$status_code" -lt 300 ]; then
        echo -e "${GREEN}成功! 状态码: $status_code${NC}"
        echo "$body" | jq . 2>/dev/null || echo "$body"
    else
        echo -e "${RED}失败! 状态码: $status_code${NC}"
        echo "$body"
    fi
    echo "----------------------------------------"
}

echo "===== 开始API测试 ====="

# 健康检查接口
test_endpoint "/health"
test_endpoint "/health/status"

# 运势相关接口
test_endpoint "/fortune/today-fortune"
test_endpoint "/fortune/history/1"
test_endpoint "/fortune/check-tables"
test_endpoint "/fortune/calculate" "POST" '{"userName":"测试用户","birthDate":"1990-01-01","birthTime":"午时"}'
test_endpoint "/fortune/recommend-names" "POST" '{"surname":"张","gender":1,"birthYear":1990,"birthMonth":1,"birthDay":1}'

echo "===== API测试完成 =====" 