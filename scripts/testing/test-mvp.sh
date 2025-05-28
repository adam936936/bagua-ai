#!/bin/bash

echo "=== AI八卦运势小程序 MVP 测试 ==="

# 检查后端编译
echo "1. 检查后端编译..."
cd backend
mvn clean compile
if [ $? -ne 0 ]; then
    echo "❌ 后端编译失败"
    exit 1
fi
echo "✅ 后端编译成功"

# 启动后端服务
echo "2. 启动后端服务..."
nohup mvn spring-boot:run > ../backend.log 2>&1 &
BACKEND_PID=$!
echo "后端服务启动中，PID: $BACKEND_PID"

# 等待后端启动
echo "等待后端服务启动..."
sleep 10

# 检查后端是否启动成功
curl -s http://localhost:8080/api/health > /dev/null
if [ $? -eq 0 ]; then
    echo "✅ 后端服务启动成功"
else
    echo "❌ 后端服务启动失败"
    kill $BACKEND_PID
    exit 1
fi

# 测试VIP接口
echo "3. 测试VIP接口..."
echo "测试获取VIP套餐价格..."
curl -s http://localhost:8080/api/vip/plans | jq .

echo "测试创建VIP订单..."
curl -s -X POST http://localhost:8080/api/vip/create-order \
  -H "Content-Type: application/json" \
  -d '{"userId": 123, "planType": "monthly"}' | jq .

echo "测试获取VIP状态..."
curl -s http://localhost:8080/api/vip/status/123 | jq .

# 检查前端
echo "4. 检查前端..."
cd ../frontend

# 检查前端依赖
if [ ! -d "node_modules" ]; then
    echo "安装前端依赖..."
    npm install
fi

echo "✅ MVP测试完成"
echo "后端服务运行在: http://localhost:8080"
echo "前端可以通过以下命令启动: cd frontend && npm run dev:h5"
echo "停止后端服务: kill $BACKEND_PID"

# 保存PID到文件
echo $BACKEND_PID > ../backend.pid 