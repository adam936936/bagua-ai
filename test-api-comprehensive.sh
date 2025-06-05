#!/bin/bash

# 八卦运势小程序 - 综合接口测试脚本
# 测试日期: 2025-06-05

echo "🎯 八卦运势小程序 - 接口测试开始"
echo "=================================="

BASE_URL="http://localhost:8080/api"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 测试函数
test_api() {
    local name="$1"
    local method="$2"
    local url="$3"
    local data="$4"
    local expected_code="$5"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -e "\n${BLUE}测试: $name${NC}"
    echo "URL: $method $url"
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$url")
    else
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X "$method" -H "Content-Type: application/json" -d "$data" "$url")
    fi
    
    http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    body=$(echo "$response" | sed -e 's/HTTPSTATUS:.*//g')
    
    if [ "$http_code" -eq "$expected_code" ]; then
        echo -e "${GREEN}✅ 通过 (HTTP $http_code)${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        
        # 解析JSON响应（如果是JSON格式）
        if echo "$body" | jq . >/dev/null 2>&1; then
            echo "响应: $(echo "$body" | jq -c .)"
        else
            echo "响应: $body"
        fi
    else
        echo -e "${RED}❌ 失败 (HTTP $http_code, 期望 $expected_code)${NC}"
        echo "响应: $body"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# 测试API错误响应（检查JSON中的错误码）
test_api_error() {
    local name="$1"
    local method="$2"
    local url="$3"
    local data="$4"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -e "\n${BLUE}测试: $name${NC}"
    echo "URL: $method $url"
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$url")
    else
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X "$method" -H "Content-Type: application/json" -d "$data" "$url")
    fi
    
    http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    body=$(echo "$response" | sed -e 's/HTTPSTATUS:.*//g')
    
    # 检查是否返回了错误响应（JSON中code为500）
    if echo "$body" | jq -e '.code == 500' >/dev/null 2>&1; then
        echo -e "${GREEN}✅ 通过 (返回错误响应)${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo "响应: $(echo "$body" | jq -c .)"
    else
        echo -e "${RED}❌ 失败 (未返回预期的错误响应)${NC}"
        echo "响应: $body"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

echo -e "\n${YELLOW}📋 开始接口测试...${NC}"

# 1. 基础连通性测试
echo -e "\n${BLUE}=== 基础连通性测试 ===${NC}"
test_api "Hello接口" "GET" "$BASE_URL/simple/hello" "" 200

# 2. 命理计算模块测试
echo -e "\n${BLUE}=== 命理计算模块 ===${NC}"
test_api "今日运势" "GET" "$BASE_URL/fortune/today-fortune" "" 200

test_api "八字测算" "POST" "$BASE_URL/fortune/calculate" \
    '{"userId": 1, "userName": "测试用户", "birthDate": "1990-01-01", "birthTime": "子时"}' 200

test_api "AI推荐姓名" "POST" "$BASE_URL/fortune/recommend-names" \
    '{"userId": 1, "surname": "李", "gender": 1, "birthYear": 1990, "birthMonth": 1, "birthDay": 1, "birthHour": 0}' 200

test_api "历史记录查询" "GET" "$BASE_URL/fortune/history/1" "" 200

# 3. 用户管理模块测试
echo -e "\n${BLUE}=== 用户管理模块 ===${NC}"
test_api "用户信息查询" "GET" "$BASE_URL/user/profile/1" "" 200
test_api "VIP状态查询" "GET" "$BASE_URL/user/vip-status/1" "" 200
test_api "用户统计" "GET" "$BASE_URL/user/stats" "" 200

# 4. VIP会员模块测试
echo -e "\n${BLUE}=== VIP会员模块 ===${NC}"
test_api "VIP套餐查询" "GET" "$BASE_URL/vip/plans" "" 200

test_api "创建VIP订单" "POST" "$BASE_URL/vip/create-order" \
    '{"userId": 1, "planType": "monthly", "amount": 19.90}' 200

test_api "用户订单列表" "GET" "$BASE_URL/vip/orders/1" "" 200

# 5. 错误处理测试
echo -e "\n${BLUE}=== 错误处理测试 ===${NC}"
test_api_error "无效用户ID" "GET" "$BASE_URL/user/profile/999"

test_api_error "缺少必需参数" "POST" "$BASE_URL/fortune/calculate" \
    '{"userId": 1}'

test_api_error "无效性别参数" "POST" "$BASE_URL/fortune/recommend-names" \
    '{"userId": 1, "surname": "李", "gender": 2, "birthYear": 1990, "birthMonth": 1, "birthDay": 1}'

test_api_error "微信登录(测试code)" "POST" "$BASE_URL/user/login" \
    '{"code": "test_code_123", "nickName": "测试用户", "avatar": "https://example.com/avatar.jpg"}'

# 6. 性能测试
echo -e "\n${BLUE}=== 性能测试 ===${NC}"
echo "并发测试 (5个并发请求)..."
start_time=$(date +%s)
for i in {1..5}; do
    curl -s "$BASE_URL/fortune/today-fortune" > /dev/null &
done
wait
end_time=$(date +%s)
duration=$((end_time - start_time))
echo -e "${GREEN}✅ 并发测试完成，耗时: ${duration}秒${NC}"

# 测试结果统计
echo -e "\n${YELLOW}📊 测试结果统计${NC}"
echo "=================================="
echo "测试时间: $TIMESTAMP"
echo "总测试数: $TOTAL_TESTS"
echo -e "通过测试: ${GREEN}$PASSED_TESTS${NC}"
echo -e "失败测试: ${RED}$FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "\n${GREEN}🎉 所有测试通过！${NC}"
    exit 0
else
    echo -e "\n${RED}⚠️  有 $FAILED_TESTS 个测试失败${NC}"
    exit 1
fi 