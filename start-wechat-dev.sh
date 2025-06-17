#!/bin/bash

# 微信小程序开发环境启动脚本
# 统一使用8081端口进行前后端通信

echo "🚀 启动微信小程序开发环境..."

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker未运行，请先启动Docker"
    exit 1
fi

# 停止现有容器（如果存在）
echo "🛑 停止现有容器..."
docker-compose down

# 重新构建并启动Docker服务
echo "🔨 构建并启动Docker服务..."
docker-compose up -d --build

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 30

# 检查服务状态
echo "🔍 检查服务状态..."
docker-compose ps

# 检查后端健康状态
echo "🏥 检查后端服务健康状态..."
for i in {1..10}; do
    if curl -f http://localhost:8081/api/actuator/health > /dev/null 2>&1; then
        echo "✅ 后端服务已就绪"
        break
    else
        echo "⏳ 等待后端服务启动... ($i/10)"
        sleep 10
    fi
done

# 启动前端代理服务器
echo "🌐 启动前端代理服务器..."
cd frontend

# 检查是否已安装依赖
if [ ! -d "node_modules" ]; then
    echo "📦 安装前端依赖..."
    npm install
fi

# 启动代理服务器（后台运行）
echo "🚀 启动前端代理服务器在8081端口..."
nohup node proxy-server.js > ../frontend-proxy.log 2>&1 &
PROXY_PID=$!
echo $PROXY_PID > ../frontend-proxy.pid

cd ..

echo "✅ 微信小程序开发环境启动完成！"
echo ""
echo "📋 服务信息："
echo "   - 后端API: http://localhost:8081/api"
echo "   - 前端代理: http://localhost:8081"
echo "   - MySQL: localhost:3306"
echo "   - Redis: localhost:6379"
echo "   - Nginx: http://localhost:80"
echo ""
echo "📱 微信小程序配置："
echo "   - 请在微信开发者工具中设置服务器域名为: localhost:8081"
echo "   - API基础路径: http://localhost:8081/api"
echo ""
echo "🔧 管理命令："
echo "   - 查看日志: docker-compose logs -f"
echo "   - 停止服务: docker-compose down"
echo "   - 停止前端代理: kill \$(cat frontend-proxy.pid)"
echo ""
echo "🧪 测试API："
echo "   curl http://localhost:8081/api/fortune/today" 