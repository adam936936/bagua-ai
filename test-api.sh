#!/bin/bash
# 八卦AI API接口测试脚本

BASE_URL="http://localhost:8080/api"

echo "🔮 八卦AI API接口测试"
echo "================================================"

# 检查jq是否安装
if ! command -v jq &> /dev/null; then
    echo "⚠️  jq未安装，输出将不会格式化"
    echo "安装命令: brew install jq"
    JQ_CMD="cat"
else
    JQ_CMD="jq ."
fi

# 1. 健康检查
echo "1️⃣  健康检查..."
echo "URL: $BASE_URL/actuator/health"
curl -s "$BASE_URL/actuator/health" | $JQ_CMD
echo ""

# 2. 今日运势测试
echo "2️⃣  今日运势测试..."
echo "URL: $BASE_URL/fortune/today-fortune"
curl -s "$BASE_URL/fortune/today-fortune" | $JQ_CMD
echo ""

# 3. 命理计算测试
echo "3️⃣  命理计算测试..."
echo "URL: $BASE_URL/fortune/calculate"
echo "请求数据: 张三, 男, 1990-05-15 10:00"
curl -X POST "$BASE_URL/fortune/calculate" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "张三",
    "gender": 1,
    "birthYear": 1990,
    "birthMonth": 5,
    "birthDay": 15,
    "birthHour": 10,
    "userId": 1
  }' | $JQ_CMD
echo ""

# 4. 姓名推荐测试
echo "4️⃣  姓名推荐测试..."
echo "URL: $BASE_URL/fortune/recommend-names"
echo "请求数据: 李姓, 女, 1995-08-20"
curl -X POST "$BASE_URL/fortune/recommend-names" \
  -H "Content-Type: application/json" \
  -d '{
    "surname": "李",
    "gender": 2,
    "birthYear": 1995,
    "birthMonth": 8,
    "birthDay": 20,
    "count": 5
  }' | $JQ_CMD
echo ""

# 5. 用户历史记录测试
echo "5️⃣  用户历史记录测试..."
echo "URL: $BASE_URL/fortune/history/1"
curl -s "$BASE_URL/fortune/history/1?page=1&size=10" | $JQ_CMD
echo ""

# 6. 性能测试（简单）
echo "6️⃣  性能测试..."
echo "测试今日运势接口响应时间（10次请求）..."
for i in {1..10}; do
    start_time=$(date +%s%N)
    curl -s "$BASE_URL/fortune/today-fortune" > /dev/null
    end_time=$(date +%s%N)
    duration=$(( (end_time - start_time) / 1000000 ))
    echo "请求 $i: ${duration}ms"
done

echo ""
echo "================================================"
echo "🎉 API测试完成！"
echo ""
echo "💡 提示:"
echo "  - 如果接口返回错误，请检查后端服务是否正常启动"
echo "  - 可以访问 http://localhost:8080/actuator/health 查看服务状态"
echo "  - 查看后端日志: tail -f logs/fortune-app.log" 