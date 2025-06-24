#!/bin/bash

# 微信小程序API测试脚本
# 测试8081端口的API接口

echo "🧪 开始测试微信小程序API接口 (端口8081)..."

BASE_URL="http://localhost:8081/api"

# 测试函数
test_api() {
    local name="$1"
    local url="$2"
    local method="$3"
    local data="$4"
    
    echo "📡 测试 $name..."
    
    if [ "$method" = "POST" ] && [ -n "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X POST \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$BASE_URL$url")
    else
        response=$(curl -s -w "\n%{http_code}" "$BASE_URL$url")
    fi
    
    # 分离响应体和状态码
    body=$(echo "$response" | head -n -1)
    status_code=$(echo "$response" | tail -n 1)
    
    if [ "$status_code" = "200" ]; then
        echo "✅ $name - 成功 (200)"
        echo "   响应: $(echo "$body" | jq -r '.message // .data.fortune // .data[0].name // "成功"' 2>/dev/null || echo "$body" | head -c 100)"
    else
        echo "❌ $name - 失败 ($status_code)"
        echo "   错误: $(echo "$body" | jq -r '.message // .error // .' 2>/dev/null || echo "$body" | head -c 200)"
    fi
    echo ""
}

# 1. 健康检查
test_api "健康检查" "/actuator/health" "GET"

# 2. 简单测试接口
test_api "简单Hello接口" "/simple/hello" "GET"

# 3. 简单运势测试
test_api "简单运势测试" "/simple/fortune-test" "GET"

# 4. 今日运势
test_api "今日运势" "/fortune/today-fortune" "GET"

# 5. 命理计算
test_api "命理计算" "/fortune/calculate" "POST" '{
    "name": "张三",
    "birthDate": "1990-01-01",
    "birthTime": "08:00",
    "gender": "male"
}'

# 6. 姓名推荐（使用正确的端点和参数格式）
test_api "姓名推荐" "/fortune/recommend-names" "POST" '{
    "surname": "李",
    "gender": 0,
    "birthYear": 1995,
    "birthMonth": 5,
    "birthDay": 15,
    "birthHour": 14
}'

# 7. 用户历史记录
test_api "用户历史记录" "/fortune/history/1" "GET"

# 8. 八字分析（使用正确的calculate端点）
test_api "八字分析" "/fortune/calculate" "POST" '{
    "name": "王五",
    "birthDate": "1988-12-25",
    "birthTime": "10:15",
    "gender": "male"
}'

echo "🏁 API测试完成！"
echo ""
echo "💡 提示："
echo "   - 如果测试失败，请检查Docker服务是否正常运行"
echo "   - 确保前端代理服务器已启动在8081端口"
echo "   - 可以使用 ./start-wechat-dev.sh 启动完整环境" 