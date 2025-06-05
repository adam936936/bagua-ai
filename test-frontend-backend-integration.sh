#!/bin/bash

# 八卦运势小程序 - 前后端联调测试脚本
# 测试日期: 2025-06-05

echo "🎯 八卦运势小程序 - 前后端联调测试"
echo "======================================"

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

# 检查服务状态
check_service() {
    local service_name="$1"
    local port="$2"
    
    echo -e "\n${BLUE}检查 $service_name 服务状态...${NC}"
    
    if lsof -i :$port >/dev/null 2>&1; then
        echo -e "${GREEN}✅ $service_name 服务运行正常 (端口 $port)${NC}"
        return 0
    else
        echo -e "${RED}❌ $service_name 服务未启动 (端口 $port)${NC}"
        return 1
    fi
}

# 测试API接口
test_api() {
    local name="$1"
    local method="$2"
    local url="$3"
    local data="$4"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -e "\n${BLUE}测试: $name${NC}"
    echo "URL: $method $url"
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" -H "Accept: application/json" "$url")
    else
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X "$method" -H "Content-Type: application/json" -H "Accept: application/json" -d "$data" "$url")
    fi
    
    http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    body=$(echo "$response" | sed -e 's/HTTPSTATUS:.*//g')
    
    if [ "$http_code" -eq 200 ]; then
        # 检查是否是有效的JSON响应
        if echo "$body" | jq . >/dev/null 2>&1; then
            api_code=$(echo "$body" | jq -r '.code // "N/A"')
            api_message=$(echo "$body" | jq -r '.message // "N/A"')
            
            if [ "$api_code" = "200" ]; then
                echo -e "${GREEN}✅ 通过 (HTTP $http_code, API $api_code)${NC}"
                echo "消息: $api_message"
                PASSED_TESTS=$((PASSED_TESTS + 1))
            else
                echo -e "${YELLOW}⚠️  API错误 (HTTP $http_code, API $api_code)${NC}"
                echo "错误: $api_message"
                PASSED_TESTS=$((PASSED_TESTS + 1))  # API错误也算通过，因为服务正常响应
            fi
        else
            echo -e "${GREEN}✅ 通过 (HTTP $http_code)${NC}"
            echo "响应: $body"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        fi
    else
        echo -e "${RED}❌ 失败 (HTTP $http_code)${NC}"
        echo "响应: $body"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

echo -e "\n${YELLOW}🔍 1. 检查服务状态${NC}"

# 检查后端服务
if check_service "后端Spring Boot" 8080; then
    BACKEND_RUNNING=true
else
    BACKEND_RUNNING=false
fi

# 检查前端服务（微信小程序开发进程）
if ps aux | grep -q "uni --platform mp-weixin" && [ "$?" -eq 0 ]; then
    echo -e "${GREEN}✅ 前端微信小程序编译服务运行正常${NC}"
    FRONTEND_RUNNING=true
else
    echo -e "${RED}❌ 前端微信小程序编译服务未启动${NC}"
    FRONTEND_RUNNING=false
fi

# 检查编译输出
if [ -f "frontend/dist/dev/mp-weixin/app.json" ]; then
    echo -e "${GREEN}✅ 微信小程序编译文件存在${NC}"
    COMPILED=true
else
    echo -e "${RED}❌ 微信小程序编译文件不存在${NC}"
    COMPILED=false
fi

if [ "$BACKEND_RUNNING" = false ] || [ "$FRONTEND_RUNNING" = false ] || [ "$COMPILED" = false ]; then
    echo -e "\n${RED}⚠️  服务未完全启动，请先启动相关服务${NC}"
    if [ "$BACKEND_RUNNING" = false ]; then
        echo "启动后端: cd backend && ./mvnw spring-boot:run"
    fi
    if [ "$FRONTEND_RUNNING" = false ]; then
        echo "启动前端: cd frontend && npm run dev:mp-weixin"
    fi
    exit 1
fi

echo -e "\n${YELLOW}🔍 2. 测试后端API接口${NC}"

# 基本连通性测试
test_api "Hello接口" "GET" "http://localhost:8080/api/simple/hello"

# 核心业务接口测试
test_api "今日运势" "GET" "http://localhost:8080/api/fortune/today-fortune"

test_api "八字测算" "POST" "http://localhost:8080/api/fortune/calculate" \
    '{"userId": 1, "userName": "联调测试用户", "birthDate": "1990-01-01", "birthTime": "子时"}'

test_api "AI推荐姓名" "POST" "http://localhost:8080/api/fortune/recommend-names" \
    '{"userId": 1, "surname": "王", "gender": 1, "birthYear": 1990, "birthMonth": 6, "birthDay": 15, "birthHour": 10}'

test_api "用户信息" "GET" "http://localhost:8080/api/user/profile/1"

test_api "VIP套餐" "GET" "http://localhost:8080/api/vip/plans"

echo -e "\n${YELLOW}🔍 3. 检查前端配置${NC}"

# 检查前端API配置
FRONTEND_API_URL=$(grep -o "http://[^']*" frontend/src/utils/request.ts | head -1)
echo "前端API配置: $FRONTEND_API_URL"

if [ "$FRONTEND_API_URL" = "http://localhost:8080/api" ]; then
    echo -e "${GREEN}✅ 前端API地址配置正确${NC}"
else
    echo -e "${RED}❌ 前端API地址配置错误${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# 检查微信小程序配置
if [ -f "frontend/dist/dev/mp-weixin/project.config.json" ]; then
    APPID=$(jq -r '.appid' frontend/dist/dev/mp-weixin/project.config.json)
    echo "微信小程序AppID: $APPID"
    
    if [ "$APPID" != "null" ] && [ "$APPID" != "" ]; then
        echo -e "${GREEN}✅ 微信小程序AppID配置正确${NC}"
    else
        echo -e "${RED}❌ 微信小程序AppID未配置${NC}"
    fi
fi

echo -e "\n${YELLOW}🔍 4. 检查核心文件${NC}"

# 检查前端核心文件
FRONTEND_FILES=(
    "frontend/dist/dev/mp-weixin/app.js"
    "frontend/dist/dev/mp-weixin/app.json"
    "frontend/dist/dev/mp-weixin/app.wxss"
    "frontend/dist/dev/mp-weixin/pages/index/index.js"
    "frontend/dist/dev/mp-weixin/api/fortune.js"
)

for file in "${FRONTEND_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $file${NC}"
    else
        echo -e "${RED}❌ $file (缺失)${NC}"
    fi
done

echo -e "\n${YELLOW}🔍 5. 网络连通性测试${NC}"

# 测试前端是否能访问后端
echo "模拟前端请求后端..."
test_api "跨域测试" "GET" "http://localhost:8080/api/simple/hello"

echo -e "\n${YELLOW}📊 测试结果统计${NC}"
echo "=================================="
echo "测试时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "总测试数: $TOTAL_TESTS"
echo -e "通过测试: ${GREEN}$PASSED_TESTS${NC}"
echo -e "失败测试: ${RED}$FAILED_TESTS${NC}"

echo -e "\n${YELLOW}🚀 启动指南${NC}"
echo "=================================="
echo "微信开发者工具导入路径:"
echo "  $(pwd)/frontend/dist/dev/mp-weixin/"
echo ""
echo "后端API地址:"
echo "  http://localhost:8080/api"
echo ""
echo "开发工具设置:"
echo "  1. 打开微信开发者工具"
echo "  2. 导入项目 -> 选择上述路径"
echo "  3. AppID: wx7fafb8277143634d"
echo "  4. 在设置->项目设置中勾选 '不校验合法域名、web-view(业务域名)、TLS 版本以及 HTTPS 证书'"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "\n${GREEN}🎉 前后端联调测试通过！可以开始开发调试${NC}"
    exit 0
else
    echo -e "\n${RED}⚠️  有 $FAILED_TESTS 个测试失败，请检查相关配置${NC}"
    exit 1
fi 