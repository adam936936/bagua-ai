#!/bin/bash
# 八卦AI API接口测试脚本

# 获取环境参数，默认为dev
PROFILE=${1:-dev}

# 根据环境设置端口
if [ "$PROFILE" = "prod" ]; then
    PORT=8081
else
    PORT=8080
fi

BASE_URL="http://localhost:$PORT/api"

echo "🔮 八卦AI API接口测试 - 环境: $PROFILE"
echo "🌐 测试地址: $BASE_URL"
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
echo "URL: http://localhost:$PORT/actuator/health"
curl -s "http://localhost:$PORT/actuator/health" | $JQ_CMD
echo ""

# 2. 今日运势测试
echo "2️⃣  今日运势测试..."
echo "URL: $BASE_URL/fortune/today-fortune"
curl -s "$BASE_URL/fortune/today-fortune" | $JQ_CMD
echo ""

# 3. 命理计算测试
echo "3️⃣  命理计算测试..."
echo "URL: $BASE_URL/fortune/calculate"
echo "请求数据: 张三, 1990-05-15, 午时"
curl -X POST "$BASE_URL/fortune/calculate" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "birthDate": "1990-05-15",
    "birthTime": "午时",
    "userName": "张三"
  }' | $JQ_CMD
echo ""

# 4. 姓名推荐测试
echo "4️⃣  姓名推荐测试..."
echo "URL: $BASE_URL/fortune/recommend-names"
echo "请求数据: 李姓, 缺水, 甲子年"
curl -X POST "$BASE_URL/fortune/recommend-names" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "wuXingLack": "水",
    "ganZhi": "甲子年乙丑月丙寅日丁卯时",
    "surname": "李"
  }' | $JQ_CMD
echo ""

# 5. 用户历史记录测试
echo "5️⃣  用户历史记录测试..."
echo "URL: $BASE_URL/fortune/history/1"
curl -s "$BASE_URL/fortune/history/1?page=1&size=10" | $JQ_CMD
echo ""

# 6. 性能测试（暂时跳过）
echo "6️⃣  性能测试..."
echo "⏭️  跳过性能测试（耗时较长）"
echo "💡 如需性能测试，请运行: curl -s \"$BASE_URL/fortune/today-fortune\" > /dev/null"

echo ""
echo "================================================"
echo "🎉 API测试完成！"
echo ""
echo "💡 提示:"
echo "  - 如果接口返回错误，请检查后端服务是否正常启动"
echo "  - 可以访问 http://localhost:$PORT/actuator/health 查看服务状态"
echo "  - 查看后端日志: tail -f logs/fortune-app.log"
echo ""
echo "📋 使用方法:"
echo "  开发环境测试: ./test-api.sh dev"
echo "  生产环境测试: ./test-api.sh prod" 